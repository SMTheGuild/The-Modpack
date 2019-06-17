dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if SmartThruster and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

mpPrint("loading SmartThruster.lua")


SmartThruster = class( nil )
SmartThruster.maxParentCount = -1
SmartThruster.maxChildCount = 0
SmartThruster.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
SmartThruster.connectionOutput = sm.interactable.connectionType.none
SmartThruster.colorNormal = sm.color.new( 0x009999ff  )
SmartThruster.colorHighlight = sm.color.new( 0x11B2B2ff  )
SmartThruster.poseWeightCount = 2


function SmartThruster.server_onCreate( self ) 
	self:server_init()
end

function SmartThruster.server_init( self ) 
	self.power = 0
end

function SmartThruster.server_onRefresh( self )
	self:server_init()
end

  

function SmartThruster.server_onFixedUpdate( self, dt )

	local parents = self.interactable:getParents()
	self.power = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	for k,v in pairs(parents) do
		local typeparent = v:getType()
		local power = v.power
		if  v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			-- number
			if power ~= math.huge and power ~= 0-math.huge and math.abs(power) >= 0 then
				if not hasnumber then self.power = 1 end
				self.power = self.power * v.power
				hasnumber = true
			end
		else
			-- logic
			logicinput = logicinput * v.power
		end
	end
	
	self.power = self.power * logicinput
		
	if self.power ~= 0 and math.abs(self.power) ~= math.huge then
		sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0, 0-self.power))
	end
end


function SmartThruster.client_onUpdate(self, dt)
	local parents = self.interactable:getParents()
	local clientpower = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	for k,v in pairs(parents) do
		local typeparent = v:getType()
		local power = v.power
		if  v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			-- number
			if power ~= math.huge and power ~= 0-math.huge and math.abs(power) >= 0 then
				if not hasnumber then self.power = 1 end
				clientpower = clientpower * v.power
				hasnumber = true
			end
		else
			-- logic
			logicinput = logicinput * v.power
		end
	end
	
	self.interactable:setPoseWeight(0, math.min(math.abs(clientpower / 1000, 1)))
	self.interactable:setPoseWeight(1, math.min(math.abs(clientpower / 1000, 1)))
	
	clientpower = clientpower * logicinput
	
	if math.abs(clientpower) > 0 then
		if not self.shootEffect:isPlaying() then
		self.shootEffect:start() end
	else
		if self.shootEffect:isPlaying() then
		self.shootEffect:stop() end
	end
	
	if clientpower > 0.0001 then
		local rot = sm.vec3.getRotation( sm.vec3.new(0,0,1),sm.vec3.new(0,0,1))
		self.shootEffect:setOffsetRotation(rot)
		self.shootEffect:setOffsetPosition(-sm.vec3.new(0,0,0))
		
		if self.i == nil then self.i = 0 end 
		self.i = self.i + 0.35
		clientpower = math.max(0,math.min(1,clientpower + sm.noise.simplexNoise1d(self.i)/4))
		self.interactable:setPoseWeight(0, clientpower)
	elseif clientpower < -0.0001 then
		local rot = sm.vec3.getRotation( sm.vec3.new(0,0,1),sm.vec3.new(0,0,-1))
		self.shootEffect:setOffsetRotation(rot)
		self.shootEffect:setOffsetPosition(-sm.vec3.new(0,0,1))
		
		if self.i == nil then self.i = 0 end 
		self.i = self.i + 0.35
		clientpower = math.max(0,math.min(1,math.abs(clientpower) + sm.noise.simplexNoise1d(self.i)/4))
		self.interactable:setPoseWeight(1, clientpower)
	end

end

function SmartThruster.client_onDestroy(self)
	self.shootEffect:stop()
end

function SmartThruster.client_onCreate(self)
	self.shootEffect = sm.effect.createEffect( "Thruster", self.interactable )
end

