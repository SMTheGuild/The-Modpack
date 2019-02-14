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
debugMode = false

function sign(num)
	if num < 0 then
		return -1
	elseif num > 0 then
		return 1
	else
		return 0
	end
end

function doAirfoilStuff( self, timeStep )
	if self.sleepTimer == nil then self.sleepTimer = 0 end
	if self.acceleration == nil then self.acceleration = 0 end
    if self.sleep == nil then self.sleep = movementSleep end
    
    
    self.globalVel = self.shape.velocity
	local globalVelL = self.globalVel:length()
    
    if globalVelL < sleepVel then
		if self.sleepTimer < sleepTime then
			self.sleepTimer = self.sleepTimer + 1
		end
	else
		self.sleepTimer = 0
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
	
	if self.sleep == 0 or debugMode then
		if math.abs(self.acceleration) < maxAcceleration and globalVelL < 600 then
            for _,surface in pairs(self.data.surfaces) do
                applyAirfoilImpulse(
                    self,
                    timeStep,
                    surface.area,
                    self.angle * surface.angleModifier + surface.angleOffset,
                    surface.offset +
                        surface.offsetModifierSin * -math.sin(math.rad(self.angle)) +
                        surface.offsetModifierCos * math.cos(math.rad(self.angle)) +
                        surface.offsetModifierTan * math.tan(math.rad(self.angle))
                )
            end
        end
	end
    
    if self.shape.body:hasChanged(sm.game.getCurrentTick() - 1) then
		self.sleepTimer = sleepTime
	end
end

function applyAirfoilImpulse( self, timeStep, area, angle, offset )
    --[[
        dunno if this is even right but I'll keep it here
        
        Flappywing:
            Front = -self.shape.up
            Side  = self.shape.right
        Wings:
            Front = self.shape.right
            Side  = self.shape.up
    ]]
    
    local localX = self.shape.up --Front up
	local localY = self.shape.right --Side right
	local localZ = -self.shape.at --Top/Bottom --localX:cross(localY)
	local aSin = -math.sin(math.rad(angle))
	local aCos = math.cos(math.rad(angle))
	local localUp = localZ * aCos + localX * aSin
	
	local normalVel = self.globalVel:dot(localUp)
	local lift = airDensity * normalVel * normalVel * 0.5 * area * sign(normalVel)
    
    local toImpulse = sm.vec3.new(0, lift * timeStep * 40 * aCos, -lift * timeStep * 40 * aSin)
	if debugMode then
        self.network:sendToClients("client_createParticle", self.shape.worldPosition + self.shape.worldRotation * offset)
    end
	sm.physics.applyImpulse(self.shape, toImpulse, false, offset)
end

-- end of file --