--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../Libs/LoadLibs.lua"


mpPrint("loading Gimball.lua")

Gimball = class()
Gimball.maxParentCount = -1
Gimball.maxChildCount = 0
Gimball.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Gimball.connectionOutput = sm.interactable.connectionType.none
Gimball.colorNormal = sm.color.new( 0x009999ff  )--sm.color.new( 0x844040ff )
Gimball.colorHighlight = sm.color.new( 0x11B2B2ff  )-- = sm.color.new( 0xb25959ff )
Gimball.poseWeightCount = 2
--Gimball.maxtilt = 90

function Gimball.server_onCreate( self ) 
	self:server_init()
end

function Gimball.server_init( self ) 
	self.power = 0
	self.smode = 0
	self.direction = sm.vec3.new(0,0,1)
	
	local stored = self.storage:load()
	if stored then
		self.smode = stored - 1
	end
end

function Gimball.server_onRefresh( self )
	self:server_init()
end

function Gimball.server_onFixedUpdate( self )
	if self.power ~= 0 and math.abs(self.power) ~= math.huge then
		sm.physics.applyImpulse(self.shape, self.direction*math.abs(self.power), true)
		--print(self.direction)
	end
end
function Gimball.client_onCreate(self)
	self.shootEffect = sm.effect.createEffect( "Thruster - Level 2", self.interactable )
	self.shootEffect:setOffsetPosition(sm.vec3.zero())
	self.parentHPose = 0.5
	self.prevparentHPose = 0.5
	self.parentVPose = 0.5
	
	self.angleX = 0
	self.angleZ = 0
	self.mode = 0
	self.network:sendToServer("server_requestmode")
	self.modes = {"WASD, Default", "WS Inverted", "Swap WS/AD Default", "Swap with AD inverted"}
	self.interactable:setAnimEnabled( "animZ", true )
	self.interactable:setAnimEnabled( "animX", true )
end

function Gimball.client_onDestroy(self)
	self.shootEffect:stop()
end
function Gimball.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	self.network:sendToServer("server_changemode", character:isCrouching())
end
function Gimball.server_changemode(self, crouch)
	self.smode = (self.smode + (crouch and -1 or 1)) % 4
	self.storage:save(self.smode+1)
	self.network:sendToClients("client_mode", {mode = self.smode, sound = true})
end
function Gimball.server_requestmode(self)
	self.network:sendToClients("client_mode", {mode = self.smode, sound = false})
end
function Gimball.client_mode(self, data)
	if data.sound then
		sm.audio.play("ConnectTool - Rotate", self.shape:getWorldPosition())
	end
	self.mode = data.mode
end
function Gimball.client_canInteract(self)
	sm.gui.setInteractionText("Press", sm.gui.getKeyBinding("Use"), "to change mode")
	sm.gui.setInteractionText("Current mode: "..self.modes[self.mode+1])
	return true
end

function Gimball.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local power = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	local canfire = 0
	
	local ws = nil
	local ad = nil
	for k,v in pairs(parents) do
		local _pType = v:getType()
		local _pUuid = tostring(v:getShape():getShapeUuid())
		if _pUuid == "289e08ef-e3d8-4f1b-bc10-a0bcf36fa0ce" and v:getUvFrameIndex()%128 == 30 then
			ad = v.power
		elseif _pUuid == "289e08ef-e3d8-4f1b-bc10-a0bcf36fa0ce" and v:getUvFrameIndex()%128 == 31 then
			ws = v.power
		elseif not v:hasSteering() and _pType == "scripted" and _pUuid ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]]
			and _pUuid ~= "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orient block]] then
			-- number
			if v.power ~= math.huge and v.power ~= 0-math.huge and math.abs(v.power) >= 0 then
				if not hasnumber then power = 1 end
				power = power * v.power
				hasnumber = true
			end
			canfire = 1
		elseif _pUuid == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orient block]] then
			
			if self.mode == 0 then
				self.parentVPose = (v.power/2)+0.5
				self.parentHPose = 1-v:getPoseWeight(0) -- AD reverse
			elseif self.mode == 1 then
				self.parentVPose = 1- ((v.power/2)+0.5) --WS reverse
				self.parentHPose = 1- v:getPoseWeight(0) -- AD reverse
				
			--swap WS and AD modes:
			elseif self.mode == 2 then
				self.parentVPose = 1- v:getPoseWeight(0) --WS reverse
				self.parentHPose = 1- ((v.power/2)+0.5)  --AD reverse 
			elseif self.mode == 3 then
				self.parentVPose = v:getPoseWeight(0)
				self.parentHPose = 1- ((v.power/2)+0.5)  --AD reverse
			
			end
			
			self.angleZ = self.parentHPose * 90
			self.angleX = self.parentVPose * 90
			
		elseif v:hasSteering() or _pType == "steering" then
			local _isOldSeat = (_pType == "steering")
			if self.mode == 0 then
				self.parentVPose = (v.power/2)+0.5
				self.parentHPose = _isOldSeat and 1 - v:getPoseWeight(0) or 0.5 - v:getSteeringAngle()
				--self.parentHPose = 1-v:getPoseWeight(0) -- AD reverse
			elseif self.mode == 1 then
				self.parentVPose = 1- ((v.power/2)+0.5) --WS reverse
				self.parentHPose = _isOldSeat and 1 - v:getPoseWeight(0) or 0.5 - v:getSteeringAngle()
				--self.parentHPose = 1- v:getPoseWeight(0) -- AD reverse
			--swap WS and AD modes:
			elseif self.mode == 2 then
				self.parentVPose = _isOldSeat and 1 - v:getPoseWeight(0) or 0.5 - v:getSteeringAngle()
				--self.parentVPose = 1- v:getPoseWeight(0) --WS reverse
				self.parentHPose = 1- ((v.power/2)+0.5)  --AD reverse 
			elseif self.mode == 3 then
				self.parentVPose = _isOldSeat and v:getPoseWeight(0) or 0.5 + v:getSteeringAngle()
				--self.parentVPose = v:getPoseWeight(0)
				self.parentHPose = 1- ((v.power/2)+0.5)  --AD reverse
			end
	
			-- wasd input to angle conversion:
			if self.parentHPose > 0.5 and not (self.parentHPose < self.prevparentHPose) and self.angleZ<90 then -- D
				self.angleZ = self.angleZ + 5
			elseif self.parentHPose < 0.5  and not (self.parentHPose > self.prevparentHPose) and self.angleZ>-90 then -- A
				self.angleZ = self.angleZ - 5
			elseif self.parentHPose > 0 and self.parentHPose < 1 then -- revert to middle
				if self.angleZ > 1 then self.angleZ = self.angleZ - 5 end
				if self.angleZ < -1 then self.angleZ = self.angleZ + 5 end
			end
			if self.parentVPose > 0.5 and not (self.parentVPose < self.prevparentVPose) and self.angleX<90 then -- W
				self.angleX = self.angleX + 5
			elseif self.parentVPose < 0.5 and not (self.parentVPose > self.prevparentVPose) and self.angleX>-90 then -- S
				self.angleX = self.angleX - 5
			elseif self.parentVPose > 0 and self.parentVPose < 1 then -- revert to middle
				if self.angleX > 0 then self.angleX = self.angleX - 5 end
				if self.angleX < 0 then self.angleX = self.angleX + 5 end
			end
		
		else
			-- logic
			logicinput = logicinput * v.power
			canfire = 1
		end
	end
	
	self.power = power * logicinput * canfire
	if math.abs(self.power) == math.huge or self.power ~= self.power then self.power = 0 end
	
	
	if self.mode == 0 then
		if ws then self.angleX = ws*90 end
		if ad then self.angleZ = -ad*90 end
	elseif self.mode == 1 then
		if ws then self.angleX = -ws*90 end
		if ad then self.angleZ = -ad*90 end
	--swap WS and AD modes:
	elseif self.mode == 2 then
		if ws then self.angleZ = -ws*90 end
		if ad then self.angleX = -ad*90 end
	elseif self.mode == 3 then
		if ws then self.angleZ = ws*90 end
		if ad then self.angleX = -ad*90 end
	end
	
	
	self.direction = sm.vec3.new(0,0,1)
	--wasd input make rotate:
	
	--way 1: (90° but non intuitive rotation)
	--self.direction = sm.vec3.rotateY(self.direction, math.rad(self.angleZ))
	--self.direction = sm.vec3.rotateX(self.direction, math.rad(self.angleX))
	--way 2: (more intuitive rotation for user)
	
	
	
	--[[
	local localX = sm.shape.getRight(self.shape)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local directionx = sm.vec3.rotate( self.direction, math.rad(self.angleX), localX)
	local directiony = sm.vec3.rotate( self.direction, math.rad(self.angleZ), localZ)
	self.direction = (self.direction + directionx*3 + directiony*3):normalize()
	]]
	
	
	local localX = sm.shape.getRight(self.shape)
    local localY = sm.shape.getAt(self.shape)
    local localZ = sm.shape.getUp(self.shape)
	
	local quat = sm.vec3.getRotation(localY, sm.vec3.new(0,0,1))
	local radians = math.acos(localY:dot(sm.vec3.new(0,0,1)))
	if math.deg(radians) < 90 then
		localX = quat*localX
		localZ = quat*localZ
	else
		quat = sm.vec3.getRotation(localY, sm.vec3.new(0,0,-1))
		localX = quat*localX --* -1
		localZ = quat*localZ
	end
    self.direction = (self.direction + localX*math.rad(self.angleZ) + localZ*math.rad(self.angleX)):normalize()*(self.power >=0 and 1 or -1)
	--[[
	local radians = math.acos(localY:dot(sm.vec3.new(0,0,1)))
	local axis = localY:cross(sm.vec3.new(0,0,1)):normalize()
	local reverses = 1
	if radians == 0 or math.deg(radians) == 180 then
	else
		if math.deg(radians) < 90 then
			localX = sm.vec3.rotate(localX, radians, axis)
			localZ = sm.vec3.rotate(localZ, radians, axis)
		else
			reverses = 1
			localX = sm.vec3.rotate(localX, math.pi - radians, axis)
			localZ = sm.vec3.rotate(localZ, math.pi - radians, axis)
		end
	end
    self.direction = (self.direction + localX*math.rad(self.angleZ*reverses) + localZ*math.rad(self.angleX)):normalize()
	]]
	
	
	--[[ SELF STABILIZATION???!!!!
	local localX = sm.shape.getRight(self.shape)
    local localY = sm.shape.getAt(self.shape)
    local localZ = sm.shape.getUp(self.shape)
	local radians = math.acos(localY:dot(sm.vec3.new(0,0,1)))
	local axis = localY:cross(sm.vec3.new(0,0,1)):normalize()
	if radians == 0 or math.deg(radians) == 180 then
	else
		localX = sm.vec3.rotate(localX, radians, axis)
		localY = sm.vec3.new(0,0,1)
		localZ = sm.vec3.rotate(localZ, radians, axis)
	end
    self.direction = (self.direction + localX*math.rad(self.angleZ) + localZ*math.rad(self.angleX)):normalize()
	]]
	
	
	if false then --visualise x and z
		sm.particle.createParticle("construct_welding", self.shape.worldPosition + localX)
		sm.particle.createParticle("construct_welding", self.shape.worldPosition + localZ)
	end
	
	-- direction to pose translation:
	local localvec = getLocal(self.shape, self.direction*-1)
	local euler = VecToEuler2(localvec)
	self.interactable:setAnimProgress( "animZ", euler.yx/360)
	self.interactable:setAnimProgress( "animX", euler.yz/360)
	
	-- effects:
	
	--rotation particle:
	local worldDown = sm.vec3.new( 0, 0, -1 )
	local worldRot = sm.vec3.getRotation( getLocal(self.shape,sm.shape.getUp(self.shape)),-self.direction)
	local localRot = self.shape:transformRotation( worldRot )
	self.shootEffect:setOffsetRotation(localRot)
	
	--self.shootEffect:setOffsetPosition(-sm.vec3.new(0,0,0.5)) old calculations
	if self.power ~= 0 then
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



function VecToEuler2( direction )
    local euler = {}
    euler.yx = 180 + math.atan2(direction.x,direction.y)/math.pi * 180  -- 0-360
	--rotate
	local rads = math.rad(euler.yx)
	direction = sm.vec3.rotateZ(direction, rads)
	
    euler.yz =  180 + math.atan2(-direction.z,direction.y)/math.pi * 180 -- 0-180
	if euler.yz >= 90 and euler.yz<=270 then
		euler.yz =  180 + math.atan2(-direction.z,-direction.y)/math.pi * 180 -- 0-180
	end
    return euler
end

function getGlobal(shape, vec)
    return shape.right* vec.x + shape.at * vec.y + shape.up * vec.z
end
function getLocal(shape, vec)
    return sm.vec3.new(shape.right:dot(vec), shape.at:dot(vec), shape.up:dot(vec))
end
