--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading WASDThruster.lua")

WASDThruster = class( nil )
WASDThruster.maxParentCount = -1
WASDThruster.maxChildCount = 0
WASDThruster.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.gasoline
WASDThruster.connectionOutput = sm.interactable.connectionType.none
WASDThruster.colorNormal = sm.color.new( 0x009999ff  )
WASDThruster.colorHighlight = sm.color.new( 0x11B2B2ff  )
WASDThruster.poseWeightCount = 2

WASDThruster.stepSize = 0.05


function WASDThruster.server_onCreate( self ) 
	self:server_init()
end

function WASDThruster.server_init( self ) 
	self.power = 0
	self.direction = sm.vec3.new(0,0,1)
	self.smode = 0

	mp_fuel_initialize(self, obj_consumable_gas, 0.35)
	
	local stored = self.storage:load()
	if stored then
		local stored_type = type(stored)
		if stored_type == "number" then
			self.smode = stored - 1
		elseif stored_type == "table" then
			self.smode = stored[1] - 1
			self.sv_fuel_points = stored[2]
		end
	end

	self.sv_saved_fuel_points = self.sv_fuel_points
end

function WASDThruster.server_onRefresh( self )
	self:server_init()
end

function WASDThruster.server_onFixedUpdate( self, dt )
	local l_container = mp_fuel_getValidFuelContainer(self)
	local can_activate, can_consume = mp_fuel_canConsumeFuel(self, l_container)

	if self.interactable.power ~= self.power then 
		self.interactable:setPower(self.power)
	end

	if can_activate and self.power > 0 and math.abs(self.power) ~= math.huge then
		sm.physics.applyImpulse(self.shape, self.direction*self.power*-1)

		if can_consume then
			mp_fuel_consumeFuelPoints(self, l_container, self.power, dt)
		end
	end

	if self.sv_saved_can_activate ~= can_activate then
		self.sv_saved_can_activate = can_activate
		self.network:setClientData(can_activate)
	end

	if self.sv_saved_fuel_points ~= self.sv_fuel_points then --update fuel status
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
			self.storage:save({ self.smode+1, self.sv_fuel_points })
		end
	end
end


function WASDThruster:client_onClientDataUpdate(params)
	self.cl_can_activate = params
end


function WASDThruster:client_onOutOfFuel()
	mp_fuel_displayOutOfFuelMessage(self)
end


function WASDThruster.client_onCreate(self)
	self.shootEffect = sm.effect.createEffect( "Thruster - Level 2", self.interactable )
	self.shootEffect:setOffsetPosition(sm.vec3.zero())
	self.parentHPose = 0.5
	self.prevparentHPose = 0.5
	self.parentVPose = 0.5
	
	self.currentHPose = 0.5
	self.currentVPose = 0.5
	self.mode = 0
	self.network:sendToServer("server_requestmode")
	self.modes = {"WASD", "WS Reversed", "Only WS", "Only AD"}
	
	self.interactable:setAnimEnabled( "animY", true )
	self.interactable:setAnimEnabled( "animX", true )
end


function WASDThruster.client_onDestroy(self)
	self.shootEffect:stopImmediate()
end

function WASDThruster.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	self.network:sendToServer("server_changemode", character:isCrouching())
end

function WASDThruster.server_changemode(self, crouch)
	self.smode = (self.smode + (crouch and -1 or 1))%4
	self.storage:save({ self.smode+1, self.sv_saved_fuel_points })
	self.network:sendToClients("client_mode", {self.smode, true})
end

function WASDThruster.server_requestmode(self)
	self.network:sendToClients("client_mode", {self.smode})
end

function WASDThruster.client_mode(self, mode)
	if mode[2] then
		sm.audio.play("ConnectTool - Rotate", self.shape:getWorldPosition())
	end
	self.mode = mode[1]
end

local default_hypertext = "<p textShadow='false' bg='gui_keybinds_bg_orange' color='#66440C' spacing='9'>%s</p>"
function WASDThruster.client_canInteract(self)
	local use_key = sm.gui.getKeyBinding("Use")
	local crawl_key = sm.gui.getKeyBinding("Crawl")

	if mp_deprecated_game_version then
		sm.gui.setInteractionText("Press", use_key, "or", crawl_key.." + "..use_key, "to change mode")
		sm.gui.setInteractionText("", "Mode: "..self.modes[self.mode+1])
	else
		local use_hyper = default_hypertext:format(use_key)
		local use_and_crawl_hyper = default_hypertext:format(crawl_key.." + "..use_key)

		sm.gui.setInteractionText("Press", use_hyper, "or", use_and_crawl_hyper, "to change mode")

		local cur_mode_hyper = default_hypertext:format("Mode: "..self.modes[self.mode+1])
		sm.gui.setInteractionText("", cur_mode_hyper)
	end

	return true
end


local wasdt_logic_and_power = bit.bor(sm.interactable.connectionType.logic, sm.interactable.connectionType.power)
function WASDThruster.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents(wasdt_logic_and_power)
	local power = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	local canfire = 0
	
	local ad = nil
	local ws = nil
	for k,v in pairs(parents) do
		local _pType = v:getType()
		local _pUuid = tostring(v:getShape():getShapeUuid())
		if _pUuid == "289e08ef-e3d8-4f1b-bc10-a0bcf36fa0ce" and v:getUvFrameIndex()%128 == 30 then
			ad = v.power
		elseif _pUuid == "289e08ef-e3d8-4f1b-bc10-a0bcf36fa0ce" and v:getUvFrameIndex()%128 == 31 then
			ws = v.power
		elseif not v:hasSteering() and  _pType == "scripted" and _pUuid ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] 
			and _pUuid ~= "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orient block]] then
			-- number
			if v.power ~= math.huge and v.power ~= 0-math.huge and math.abs(v.power) >= 0 then
				if not hasnumber then power = 1 end
				power = power * v.power
				hasnumber = true
			end
			canfire = 1
		elseif _pType == "steering" or v:hasSteering() then
			local _isOldSeat = (_pType == "steering")
			if self.mode == 0 then
				self.parentVPose = (v.power * -1/2)+0.5
				self.parentHPose = _isOldSeat and v:getPoseWeight(0) or v:getSteeringAngle() + 0.5
			elseif self.mode == 1 then
				self.parentVPose = (v.power * 1/2)+0.5
				self.parentHPose = _isOldSeat and v:getPoseWeight(0) or v:getSteeringAngle() + 0.5
			elseif self.mode == 2 then
				self.parentVPose = (v.power * 1/2)+0.5
				self.parentHPose = 0.5
			elseif self.mode == 3 then
				self.parentVPose = 0.5
				self.parentHPose = _isOldSeat and v:getPoseWeight(0) or v:getSteeringAngle() + 0.5
			end
			
			if self.parentHPose > 0.5 and not (self.parentHPose < self.prevparentHPose) and self.currentHPose < 1 then -- D
				self.currentHPose = self.currentHPose + self.stepSize
			elseif self.parentHPose < 0.5 and not (self.parentHPose > self.prevparentHPose) and self.currentHPose > 0 then -- A
				self.currentHPose = self.currentHPose - self.stepSize
			elseif self.parentHPose > 0 and self.parentHPose < 1 then 
				if self.currentHPose < 0.4999 then self.currentHPose = self.currentHPose + self.stepSize end
				if self.currentHPose > 0.5001 then self.currentHPose = self.currentHPose - self.stepSize end
			end
			
			if self.parentVPose > 0.5 and self.currentVPose < 1 then -- W
				self.currentVPose = self.currentVPose + self.stepSize
			elseif self.parentVPose < 0.5 and self.currentVPose > 0 then -- S
				self.currentVPose = self.currentVPose - self.stepSize
			elseif self.parentVPose > 0 and self.parentVPose < 1 then
				if self.currentVPose < 0.4999 then self.currentVPose = self.currentVPose + self.stepSize end
				if self.currentVPose > 0.5001 then self.currentVPose = self.currentVPose - self.stepSize end
			end
	
		elseif _pUuid == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" then
			if self.mode == 0 then
				self.parentVPose = (v.power *6 * -1/2)+0.5
				self.parentHPose = (v:getPoseWeight(0)-0.5)*6+0.5
			elseif self.mode == 1 then
				self.parentVPose = (v.power *6 * 1/2)+0.5
				self.parentHPose = (v:getPoseWeight(0)-0.5)*6+0.5
			elseif self.mode == 2 then
				self.parentVPose = (v.power *6 * 1/2)+0.5
				self.parentHPose = 0.5
			elseif self.mode == 3 then
				self.parentVPose = 0.5
				self.parentHPose = (v:getPoseWeight(0)-0.5)*6+0.5
			end
			
			self.currentHPose = math.min(1,math.max(0,self.parentHPose))
			self.currentVPose = math.min(1,math.max(0,self.parentVPose))
			--print(self.currentHPose, self.currentVPose)
		else
			-- logic
			logicinput = logicinput * v.power
			canfire = 1
		end
	end
	
	if self.mode == 0 then
		if ws then self.currentVPose = (ws+1)/2 end -- -1 to 1 => 0 to 1
		if ad then self.currentHPose = (ad+1)/2 end -- -1 to 1 => 0 to 1
	elseif self.mode == 1 then
		if ws then self.currentVPose = (ws+1)/2 end -- -1 to 1 => 0 to 1
		if ad then self.currentHPose = (ad+1)/2 end -- -1 to 1 => 0 to 1
	elseif self.mode == 2 then
		if ws then self.currentVPose = (ws+1)/2 end -- -1 to 1 => 0 to 1
		if ad or ws then self.currentHPose = 0.5 end
	elseif self.mode == 3 then
		if ws or ad then self.currentVPose = 0.5 end -- -1 to 1 => 0 to 1
		if ad then self.currentHPose = (ad+1)/2 end -- -1 to 1 => 0 to 1
	end

	--check if the thruster is allowed to have any power
	if self.cl_can_activate then
		self.power = power * logicinput * canfire
	else
		self.power = 0
	end

	if math.abs(self.power) == math.huge or self.power ~= self.power then
		self.power = 0
	end
	
	
	self.interactable:setUvFrameIndex(self.mode)
    self.interactable:setAnimProgress( "animY", self.currentVPose )
    self.interactable:setAnimProgress( "animX", self.currentHPose )
	local localX = sm.vec3.new(1,0,0)
	local localY = sm.vec3.new(0,-1,0)
	local localZ = sm.vec3.new(0,0,1)
	self.direction = localZ + (localY * ((self.currentVPose - 0.5)))
	self.direction = self.direction + (localX * ((self.currentHPose - 0.5)))
	self.direction = self.direction:normalize()
	--print(self.direction)
	
	--rotation particle(next patch):
	local worldRot = sm.vec3.getRotation( getLocal(self.shape,sm.shape.getUp(self.shape)),self.direction)
	self.shootEffect:setOffsetRotation(worldRot)
	--self.shootEffect:setOffsetPosition((-sm.vec3.new(0,0,1.25)+self.direction)*0.36) --old calculations

	if self.power > 0 then
		if not self.shootEffect:isPlaying() then
			self.shootEffect:start()
		end
	else
		if self.shootEffect:isPlaying() then
			self.shootEffect:stop()
		end
	end
	
	
	self.prevparentHPose = self.parentHPose
	self.prevparentVPose = self.parentVPose
end