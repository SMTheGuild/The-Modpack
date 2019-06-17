-- Copyright (c) 2018 Lord Pain --

-- Tacho.lua --
Tacho = class( nil )
Tacho.maxChildCount = -1
Tacho.maxParentCount = -1
Tacho.connectionInput = sm.interactable.connectionType.power
Tacho.connectionOutput = sm.interactable.connectionType.power
Tacho.colorNormal = sm.color.new( 0x76034dff )
Tacho.colorHighlight = sm.color.new( 0x8f2268ff )
Tacho.poseWeightCount = 2


function Tacho.server_onCreate( self ) 
	self:server_init()
	
end

function Tacho.server_init( self ) 
	self.Speed = sm.vec3.new(0,0,0)
	self.oldPos = sm.shape.getWorldPosition(self.shape)
	self.oldSpeed = sm.vec3.new(0,0,0)
	self.mode = 1
	
	self.modetable = {
		{savevalue = 1, texturevalue = 0, name = "speed", description= "speed in any direction (blocks/second)"},
		{savevalue = 7, texturevalue = 18, name = "velocity", description= "speed in a direction (the 'normal' through the meter)"},
		{savevalue = 2, texturevalue = 3, name = "acceleration", description= "acceleration (blocks/second²)"},
		{savevalue = 3, texturevalue = 6, name = "altitude", description= "the current height in blocks"},
		{savevalue = 4, texturevalue = 9, name = "pos x", description= "current x pos in blocks"},
		{savevalue = 5, texturevalue = 12, name = "pos y", description= "current y pos in blocks"},
		{savevalue = 6, texturevalue = 15, name = "compass", description= "rotation relative to north (+Y)"},
		{savevalue = 11, texturevalue = 1, name = "rotation", description= "rotation around placed axis"},
		{savevalue = 8, texturevalue = 21, name = "rpm", description= "angular speed in degrees/second (use it as a 'wheel')"},
		{savevalue = 10, texturevalue = 27, name = "creation mass", description= "current mass in the whole creation"},
		{savevalue = 9, texturevalue = 24, name = "display", description= "can display any input number on the display, white number input defines 'max'(default:100)"},
	}
	
	local savemodes = {}
	for k,v in pairs(self.modetable) do
	   savemodes[v.savevalue]=k
	end
	
	local stored = self.storage:load()
	if stored and type(stored) == "number" then
		self.mode = savemodes[stored]
	end
	self.storage:save(self.modetable[self.mode].savevalue)
	
end

function Tacho.server_onRefresh( self )
	self:server_init()
	
end

function Tacho.server_onFixedUpdate( self, timeStep )
	local position = sm.shape.getWorldPosition(self.shape)
	self.Speed = ( position - self.oldPos ) /timeStep *4
	local value = 0
	self.power = 0
	
	local mode = self.modetable[self.mode].savevalue
	
	if mode == 1 then --speedometer
		--print("Speed = ",tostring(self.Speed))
		value = self.Speed:length()/4
		self.power = self.Speed:length()
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					position = orienters[v:getShape().id].position
					self.Speed = ( position - self.oldPos ) /timeStep *4
					value = self.Speed:length()/4
					self.power = self.Speed:length()
				end
			else
				self.power = 0
				value = 0
			end
		end
	elseif mode == 2 then  --accelerometer
		
		local hasorients = false
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				hasorients = true
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					position = orienters[v:getShape().id].position
					self.Speed = ( position - self.oldPos ) /timeStep *4
					self.power = math.abs((self.Speed - self.oldSpeed):length())/timeStep
					value = runningAverage(self,self.power)/3
				end
			else
				self.power = 0
				value = 0
			end
		end
		if not hasorients then 
			self.power =  math.abs((self.Speed - self.oldSpeed):length())/timeStep
			value = runningAverage(self,self.power)/3
		end
		
	elseif mode == 3 then -- z pos
		self.power = position.z*4 -- *4, from units to blocks
		value = position.z/3
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					self.power = orienters[v:getShape().id].position.z*4
					value = orienters[v:getShape().id].position.z/3
				end
			else
				self.power = 0
				value = 0
			end
		end
	elseif mode == 4 then -- x pos
		self.power = position.x*4
		value = 50 + position.x/14
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					self.power = orienters[v:getShape().id].position.x*4
					value = 50 + orienters[v:getShape().id].position.x/14
				end
			else
				self.power = 0
				value = 50
			end
		end
	elseif mode == 5 then -- y pos
		self.power = position.y*4
		value = 50 + position.y/14
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					self.power = orienters[v:getShape().id].position.y*4
					value = 50 + orienters[v:getShape().id].position.y/14
				end
			else
				self.power = 0
				value = 50
			end
		end
	elseif mode == 6 then -- compass
		value = "compass"
		local localY = sm.shape.getAt(self.shape)
		local localZ = sm.shape.getUp(self.shape)--up
		local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
		localY = rot*localY
		self.power = math.atan2(-localY.x,localY.y)/math.pi * 180
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position and orienters[v:getShape().id].direction then
					self.power = math.atan2(-orienters[v:getShape().id].direction.x,orienters[v:getShape().id].direction.y)/math.pi * 180
					value = 50+self.power/2.7
					if self.shape:getZAxis().z < 0 then
						value = 50-self.power/2.7
					end
				else
					self.power = 0
					value = 50
				end
			end
		end
	elseif mode == 7 then -- velocity
		local speedy = sm.shape.getUp(self.shape):dot(self.Speed)*-1
		value = 50 + speedy/4
		self.power = speedy
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position and orienters[v:getShape().id].direction then
					position = orienters[v:getShape().id].position
					self.Speed = ( position - self.oldPos ) /timeStep *4
					local speedy = orienters[v:getShape().id].direction:dot(self.Speed)
					value = 50 + speedy/4
					self.power = speedy
				else
					self.power = 0
					value = 50
				end
			end
		end
		
		self.oldangle = 0
	elseif mode == 8 then -- rpm
		local rpm = getLocal(self.shape,self.shape.body.angularVelocity)
		--print(math.deg(rpm.z))
		value = 50 - math.deg(rpm.z)
		self.power = -math.deg(rpm.z)
		
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position and orienters[v:getShape().id].direction then
					local angle = math.atan2(-orienters[v:getShape().id].direction.x,orienters[v:getShape().id].direction.y)/math.pi * -180
					if not self.oldangle then self.oldangle = angle end
					self.power = angle - self.oldangle
					value = 50 + self.power/2.7
					self.oldangle = angle
				else
					self.power = 0
					value = 50
				end
			end
		end
		
	elseif mode == 9 then -- gauge
		self.oldangle = 0
		
		local parents = self.interactable:getParents()
		local maxvalue = 100
		local number = 0
		local hasmax = false
		for k, v in pairs(parents) do
			if (tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff") then
				if not hasmax then maxvalue = 0 end
				hasmax = true 
				maxvalue = maxvalue + v.power
			else
				number = number + v.power
			end
		end
		if maxvalue == 0 then maxvalue = 100 end
		maxvalue = maxvalue/100
		value = number/maxvalue
		self.power = value
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				self.power = 0
				value = 0
			end
		end
	elseif mode == 10 then -- mass
		local weight = 0
		for k, v in pairs(self.shape.body:getCreationBodies()) do
			weight = weight + v.mass
		end
		self.power = weight
		value = weight/10
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].mass then
				
					self.power = orienters[v:getShape().id].mass
					value = orienters[v:getShape().id].mass/10
				else
					self.power = 0
					value = 50
				end
			end
		end
	elseif mode == 11 then -- orient
	
		local localX = sm.shape.getRight(self.shape) -- right
		local localY = sm.shape.getAt(self.shape) -- up
		local localZ = sm.shape.getUp(self.shape) -- displayup
		
		local placedZ = self.shape:getZAxis()
		
		local pitch = math.acos(localZ.z)/math.pi *180-90
		
		--print(localX)
		if math.abs(placedZ.z) == 1 then -- placed pointing up
			local rot = sm.vec3.getRotation(localZ, placedZ)
			localY = rot*localY
			self.power = math.atan2(-localY.x,localY.y)/math.pi * 180
			value = 50+self.power/2.7
			if placedZ.z < 0 then
				value = 50-self.power/2.7
			end
		elseif sm.vec3.new(0,0,1):cross(localZ):length()>0.001 then--avoid error
			local fakeX = sm.vec3.new(0,0,1):cross(localZ):normalize()
			local fakeY = localZ:cross(fakeX)
			local relativerot = sm.vec3.new(fakeX:dot(localY), fakeY:dot(localY), localZ:dot(localY))
			self.power = math.atan2(relativerot.x,relativerot.y)/math.pi * 180
			
			value = 50-self.power/2.7
		end
		--elseif math.abs(placedZ.y) == 1 then -- placed pointing towards sun
		--	self.power = math.atan2(-localY.x,localY.z)/math.pi * 180
		--	value = 50+self.power/2.7
		--	if placedZ.y > 0 then
		--		value = 50-self.power/2.7
		--	else
		--		self.power = 0-self.power
		--	end
		--else -- placed sideways
		--	self.power = math.atan2(-localY.y,localY.z)/math.pi * 180
		--	value = 50+self.power/2.7
		--	if placedZ.x < 0 then
		--		value = 50-self.power/2.7
		--	else
		--		self.power = 0-self.power
		--	end
		--end
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				self.power = 0
				value = 50
			end
		end
	end
	
	self.oldPos = position
	self.oldSpeed = self.Speed
	if self.power ~= self.interactable.power then
		self.interactable:setPower(self.power)
	end
	self.network:sendToClients("client_PosenUV", { posevalue = value, uv = self.modetable[self.mode].texturevalue } )
end

function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end

function Tacho.client_setPoseWeight(self, Data)
	self.interactable:setPoseWeight(Data.pose , Data.level)
end
function Tacho.client_PosenUV(self, Data)
	self.interactable:setUvFrameIndex(Data.uv)
	if Data.posevalue == "compass" then
		--local localX = sm.shape.getRight(self.shape)
		local localY = sm.shape.getAt(self.shape)
		local localZ = sm.shape.getUp(self.shape)--up
		local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
		localY = rot*localY*-1
		
		self.interactable:setPoseWeight(0 ,(localY.x+1)/2)
		self.interactable:setPoseWeight(1 ,(localY.y+1)/2)
		
	
	else
		local one = (math.sin(0-2*math.pi*(Data.posevalue+17)/134)+1)/2
		local two = (math.cos(2*math.pi*(Data.posevalue+17)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
	end
end
function Tacho.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
	self.network:sendToServer("server_changemode", crouching)
end
function Tacho.server_changemode(self, crouch)
	if not crouch then
		self.mode = (self.mode)%#self.modetable + 1
	else
		self.mode = (self.mode-2)%#self.modetable + 1
	end
	print("description:",self.modetable[self.mode].description)
	self.storage:save(self.modetable[self.mode].savevalue)
end

function runningAverage(self, num)
  local runningAverageCount = 5
  if self.runningAverageBuffer == nil then self.runningAverageBuffer = {} end
  if self.nextRunningAverage == nil then self.nextRunningAverage = 0 end
  
  self.runningAverageBuffer[self.nextRunningAverage] = num 
  self.nextRunningAverage = self.nextRunningAverage + 1 
  if self.nextRunningAverage >= runningAverageCount then self.nextRunningAverage = 0 end
  
  local runningAverage = 0
  for k, v in pairs(self.runningAverageBuffer) do
    runningAverage = runningAverage + v
  end
  --if num < 1 then return 0 end
  return runningAverage / runningAverageCount;
end

