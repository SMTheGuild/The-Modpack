--[[
Made by DasEtwas
All rights reserved
Donated to The Modpack Team! Thanks DasEtwas!
]]--

airDensity = 2.75
maxAcceleration = 180 -- m/(s^2) max acceleration
movementSleep = 10 -- how many ticks it takes for previously completely still wings to activate when velocity:length() > sleepVel
sleepVel = 0.3 -- m/s
sleepTime = 5 -- how long it takes for a wing to fall asleep

function vecString(vec)
	if not vec then return "[nil vector]" end
	return "["..tostring(math.floor((sm.vec3.getX(vec) * 1000) + 0.5) / 1000)..",".. tostring(math.floor((sm.vec3.getY(vec) * 1000) + 0.5) / 1000)..",".. tostring(math.floor((sm.vec3.getZ(vec) * 1000) + 0.5) / 1000).."]"
end

function form(num)
	return math.floor((num * 100000) + 0.5) / 100000
end

function sign(num)
	if num < 0 then
		return -1
	elseif num > 0 then
		return 1
	else
		return 0
	end
end

function equals(vec1, vec2)
	return sm.vec3.getX(vec1) == sm.vec3.getX(vec2) and sm.vec3.getY(vec1) == sm.vec3.getY(vec2) and sm.vec3.getZ(vec1) == sm.vec3.getZ(vec2)
end

function doAirfoilStuff( self, timeStep )
	if form(timeStep) ~= 0.025 then
		print("[Wings] irregular timestep! " .. tostring(timeStep))
	end
	
	if self.sleepTimer == nil then self.sleepTimer = 0 end
	
	if self.lastPosition then
		local currentPos = sm.shape.getWorldPosition(self.shape)

		local globalVel = (currentPos - self.lastPosition) / timeStep
		local globalVelL = globalVel:length()
		
		if globalVelL < sleepVel then
			if self.sleepTimer < sleepTime then
				self.sleepTimer = self.sleepTimer + 1
			end
		else
			self.sleepTimer = 0
		end

		if self.parentBodyMass ~= sm.body.getMass(self.shape:getBody()) then
			self.sleepTimer = sleepTime
		end
		
		if self.sleepTimer >= sleepTime then -- fall asleep
			self.sleep = movementSleep
		elseif self.sleep > 0 then
			self.sleep = self.sleep - 1
		end
		
		if self.sleepTimer == 0 then
			self.acceleration = globalVelL
			
			if self.lastVelocity then
				self.acceleration = (globalVelL - self.lastVelocity) / timeStep
			end
			
			self.lastVelocity = globalVelL
		end
	
		if self.sleep == 0 then
			if math.abs(self.acceleration) < maxAcceleration then
				local localX = sm.shape.getRight(self.shape)
				local localY = sm.shape.getUp(self.shape)
				local localZ = localX:cross(localY) -- normal vector
				local aSin = -math.sin(math.rad(self.angle))
				local aCos = math.cos(math.rad(self.angle))
				local localUp = localZ * aCos + localX * aSin
				
				self.normalVel = globalVel:dot(localUp)
				self.lift = airDensity * self.normalVel * self.normalVel * 0.5 * self.area * sign(self.normalVel)
				
				if globalVelL < 50 then
					sm.physics.applyImpulse(self.shape, sm.vec3.new(-self.lift * timeStep * 40 * aSin, self.lift * timeStep * 40 * aCos, 0))
				end
			end
		end
		
	end
	
	self.lastPosition = sm.shape.getWorldPosition(self.shape)
	self.parentBodyMass = sm.body.getMass(self.shape:getBody())
end

DefaultBig = class( nil )
DefaultBig.area = 1
DefaultBig.sleep = movementSleep
DefaultBig.angle = 0

function DefaultBig.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end

DefaultSmall = class( nil )
DefaultSmall.area = 0.25
DefaultSmall.sleep = movementSleep
DefaultSmall.angle = 0

function DefaultSmall.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end

SmallAngled00 = class( nil )
SmallAngled00.area = 0.0625
SmallAngled00.sleep = movementSleep
SmallAngled00.angle = 0

function SmallAngled00.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end
--[[
SmallAngled15 = class( nil )
SmallAngled15.area = 0.0625
SmallAngled15.sleep = movementSleep
SmallAngled15.angle = 15

function SmallAngled15.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end

SmallAngled30 = class( nil )
SmallAngled30.area = 0.0625
SmallAngled30.sleep = movementSleep
SmallAngled30.angle = 30

function SmallAngled30.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end

SmallAngled45 = class( nil )
SmallAngled45.area = 0.0625
SmallAngled45.sleep = movementSleep
SmallAngled45.angle = 45

function SmallAngled45.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end

DefaultBigConnector = class( nil )
DefaultBigConnector.area = 2.3
DefaultBigConnector.sleep = movementSleep
DefaultBigConnector.angle = 0

function DefaultBigConnector.server_onFixedUpdate( self, timeStep )
	doAirfoilStuff(self, timeStep)
end
]]--
-- end of file --