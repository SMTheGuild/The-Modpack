--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--

dofile "../../libs/load_libs.lua"

print("loading SmartThruster.lua")


SmartThruster = class( nil )
SmartThruster.maxParentCount = -1
SmartThruster.maxChildCount = 0
SmartThruster.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.gasoline
SmartThruster.connectionOutput = sm.interactable.connectionType.none
SmartThruster.colorNormal = sm.color.new( 0x009999ff  )
SmartThruster.colorHighlight = sm.color.new( 0x11B2B2ff  )
SmartThruster.poseWeightCount = 2


function SmartThruster.server_onCreate( self ) 
	mp_fuel_initialize(self, obj_consumable_gas, 0.35)

	local saved_data = self.storage:load()
	if saved_data ~= nil then
		self.sv_fuel_points = saved_data
	end

	self.sv_saved_fuel_points = self.sv_fuel_points
end

function SmartThruster.server_onRefresh( self )
	self:server_onCreate()
end

  
local st_logic_and_power = bit.bor(sm.interactable.connectionType.power, sm.interactable.connectionType.logic)
function SmartThruster.server_onFixedUpdate( self, dt )

	local parents = self.interactable:getParents(st_logic_and_power)
	local power = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	for k,v in pairs(parents) do
		local typeparent = v:getType()
		if typeparent == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			-- number
			if not hasnumber then power = 1 end
			power = power * v.power
			hasnumber = true
		else
			-- logic
			logicinput = logicinput * v.power
		end
	end
	
	
	if power ~= power then power = 0 end --NaN check
	if math.abs(power) >= 3.3*10^38 then -- inf check
		if power < 0 then power = -3.3*10^38 else power = 3.3*10^38 end  
	end

	local l_container = mp_fuel_getValidFuelContainer(self)
	local can_activate, can_consume = mp_fuel_canConsumeFuel(self, l_container)

	if not can_activate then
		power = 0
	end
	
	mp_updateOutputData(self, power * (logicinput or 1), logicinput > 0)
	power = power * logicinput
	
	if can_activate and power ~= 0 and math.abs(power) ~= math.huge then
		sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0, 0 - power))

		if can_consume then
			mp_fuel_consumeFuelPoints(self, l_container, power, dt)
		end
	end

	if self.sv_saved_fuel_points ~= self.sv_fuel_points then
		self.sv_saved_fuel_points = self.sv_fuel_points
		self.sv_fuel_save_timer = 1

		if self.sv_fuel_points <= 0 then
			self.network:sendToClients("client_onOutOfFuel")
		end
	end

	if self.sv_fuel_save_timer ~= nil then
		self.sv_fuel_save_timer = self.sv_fuel_save_timer - dt

		if self.sv_fuel_save_timer < 0 then
			self.sv_fuel_save_timer = nil
			self.storage:save(self.sv_fuel_points)
		end
	end
end

function SmartThruster:client_onOutOfFuel()
	mp_fuel_displayOutOfFuelMessage(self)
end


function SmartThruster.client_onCreate(self)
	self.shootEffect = sm.effect.createEffect( "Thruster - Level 4", self.interactable )
	self.i = 0
end


function SmartThruster.client_onUpdate(self, dt) -- 1 tick delayed vs server but who cares, it's effects anyway
	
	local clientpower = (self.interactable.active and self.interactable.power or 0)
	
	local poseVal0 = sm.util.clamp( math.abs(self.interactable.power/700), 0.2, 0.8 )
	local poseVal1 = poseVal0
	
	if math.abs(clientpower) > 0.0001 then
		if not self.shootEffect:isPlaying() then
		self.shootEffect:start() end
		
		local isFlipped = clientpower < 0
		if isFlipped ~= self.isFlipped then
			local rot = sm.vec3.getRotation( sm.vec3.new(0,0,1),sm.vec3.new(0,0, isFlipped and -1 or 1))
			self.shootEffect:setOffsetRotation(rot)
			---self.shootEffect:setOffsetPosition(sm.vec3.new(0,0, isFlipped and -1 or 0)) --old function
			self.shootEffect:setOffsetPosition(sm.vec3.new(0,0, isFlipped and -0.01 or 0.01))
		end
		self.isFlipped = isFlipped
		
		self.i = self.i + 0.33
		if not isFlipped then
			poseVal0 = poseVal0 + sm.noise.simplexNoise1d(self.i)/5
		else
			poseVal1 = poseVal1 + sm.noise.simplexNoise1d(self.i)/5
		end
		
	else
		if self.shootEffect:isPlaying() then
			self.shootEffect:stop()
		end
	end
	
	self.interactable:setPoseWeight(0, poseVal0)
	self.interactable:setPoseWeight(1, poseVal1)
end


function SmartThruster.client_onDestroy(self)
	self.shootEffect:stop()
end

