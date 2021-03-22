-- Copyright (c) 2018 Lord Pain & Brent Batch --

--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261 / Lord Pain
]]--
dofile "../Libs/LoadLibs.lua"


mpPrint("loading speedometer.lua")


-- Tacho.lua --
Tacho = class( nil )
Tacho.maxChildCount = -1
Tacho.maxParentCount = -1
Tacho.connectionInput = sm.interactable.connectionType.power
Tacho.connectionOutput = sm.interactable.connectionType.power
Tacho.colorNormal = sm.color.new( 0x76034dff )
Tacho.colorHighlight = sm.color.new( 0x8f2268ff )
Tacho.poseWeightCount = 2

Tacho.modetable = {
	{savevalue = 1,  texturevalue = 0,  name = "speed", 		description= "speed in any direction (blocks/second)"},
	{savevalue = 7,  texturevalue = 12, name = "velocity", 		description= "speed in a direction (the 'normal' through the meter)"},
	{savevalue = 2,  texturevalue = 2,  name = "acceleration",	description= "acceleration (blocks/second²)"},
	{savevalue = 3,  texturevalue = 4,  name = "altitude", 		description= "the current height in blocks"},
	{savevalue = 4,  texturevalue = 6,  name = "pos x", 		description= "current x pos in blocks"},
	{savevalue = 5,  texturevalue = 8, name = "pos y", 		description= "current y pos in blocks"},
	{savevalue = 6,  texturevalue = 10, name = "compass", 		description= "rotation relative to north (+Y)"},
	{savevalue = 11, texturevalue = 1,  name = "rotation", 		description= "rotation around placed axis"},
	{savevalue = 8,  texturevalue = 14, name = "rpm", 			description= "angular speed in degrees/second (use it as a 'wheel')"},
	{savevalue = 10, texturevalue = 18, name = "creation mass", description= "current mass in the whole creation"},
	{savevalue = 9,  texturevalue = 16, name = "display", 		description= "can display any input number on the display, white number input defines 'max'(default:100)"},
}
Tacho.savemodes = {}
for k,v in pairs(Tacho.modetable) do
   Tacho.savemodes[v.savevalue]=k
end

Tacho.mode = 1


function Tacho.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function Tacho.server_onCreate( self ) 
	self.oldSpeed = sm.vec3.new(0,0,0)
	
	local stored = self.storage:load()
	if stored and type(stored) == "number" then
		self.mode = Tacho.savemodes[stored]
	end
	self.storage:save(self.modetable[self.mode].savevalue)
	
end


function Tacho.server_onFixedUpdate( self, timeStep )
	local power = 0
	
	local mode = self.modetable[self.mode].savevalue
	
	if mode == 1 then --speedometer
		power = self.shape.velocity:length()*4
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					local orienter = orienters[v:getShape().id]
					power = ( orienter.position - (orienter.oldPos or orienter.position) ):length() /timeStep *4
					orienters[v:getShape().id].oldPos = sm.vec3.new(0,0,0) + orienter.position -- (anti reference)
				else
					power = 0
				end
			end
		end
		
	elseif mode == 2 then  --accelerometer
		
		local hasorients = false
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				hasorients = true
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					local orienter = orienters[v:getShape().id]
					
					local speed = orienter.position - (orienter.oldPos or orienter.position)
					
					power = runningAverage( self,  math.abs((speed - orienter.oldSpeed):length() /timeStep)*4 )
					
					orienters[v:getShape().id].oldPos = sm.vec3.new(0,0,0) + orienter.position -- (anti reference)
					orienters[v:getShape().id].oldSpeed = sm.vec3.new(0,0,0) + speed-- (anti reference)
				else
					power = 0
				end
			end
		end
		if not hasorients then 
			power = runningAverage(self, math.abs((self.shape.velocity - self.oldSpeed):length())/timeStep*4)
		end
		
	elseif mode == 3 then -- z pos
		power = self.shape.worldPosition.z*4 -- *4, from units to blocks
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					power = orienters[v:getShape().id].position.z*4
				else
					power = 0
				end
			end
		end
	elseif mode == 4 then -- x pos
		power = self.shape.worldPosition.x*4
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					power = orienters[v:getShape().id].position.x*4
				else
					power = 0
				end
			end
		end
	elseif mode == 5 then -- y pos
		power = self.shape.worldPosition.y*4
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position then
					power = orienters[v:getShape().id].position.y*4
				else
					power = 0
				end
			end
		end
	elseif mode == 6 then -- compass
		local localY = sm.shape.getAt(self.shape)
		local localZ = sm.shape.getUp(self.shape)--up
		local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
		localY = rot*localY
		power = math.atan2(-localY.x,localY.y)/math.pi * 180
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position and orienters[v:getShape().id].direction then
					power = math.atan2(-orienters[v:getShape().id].direction.x,orienters[v:getShape().id].direction.y)/math.pi * 180
					--value = 50+self.power/2.7
					--if self.shape:getZAxis().z < 0 then
					--	value = 50-self.power/2.7
					--end
				else
					power = 0
				end
			end
		end
	elseif mode == 7 then -- velocity
		power = sm.shape.getUp(self.shape):dot(self.shape.velocity)*-4
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position and orienters[v:getShape().id].direction then
					local orienter = orienters[v:getShape().id]
					
					power = orienter.direction:dot(( orienter.position - (orienter.oldPos or orienter.position) ) /timeStep *4)
					
					orienters[v:getShape().id].oldPos = sm.vec3.new(0,0,0) + orienter.position -- (anti reference)
				else
					power = 0
				end
			end
		end
		
	elseif mode == 8 then -- degrees per sec
		local dps = getLocal(self.shape,self.shape.body.angularVelocity)
		power = -math.deg(dps.z)
		
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].position and orienters[v:getShape().id].direction then
					local orienter = orienters[v:getShape().id]
					
					local angle = math.atan2(-orienter.direction.x, orienter.direction.y)/math.pi * -180
					power = angle - (orienter.oldAngle or orienter.angle)
					orienters[v:getShape().id].oldAngle = angle
					--value = 50 + self.power/2.7
				else
					power = 0
				end
			end
		end
		
	elseif mode == 9 then -- gauge
		
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
		power = number/maxvalue
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				power = 0
			end
		end
	elseif mode == 10 then -- mass
		local weight = 0
		for k, v in pairs(self.shape.body:getCreationBodies()) do
			weight = weight + v.mass
		end
		power = weight
		
		for k, v in pairs(self.interactable:getParents()) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
				if orienters and orienters[v:getShape().id] and orienters[v:getShape().id].mass then
				
					power = orienters[v:getShape().id].mass or 0
					--value = orienters[v:getShape().id].mass/10
				else
					power = 0
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
			power = math.atan2(-localY.x,localY.y)/math.pi * 180
			--value = 50+power/2.7
			--if placedZ.z < 0 then
			--	value = 50-self.power/2.7
			--end
		elseif sm.vec3.new(0,0,1):cross(localZ):length()>0.001 then--avoid error
			local fakeX = sm.vec3.new(0,0,1):cross(localZ):normalize()
			local fakeY = localZ:cross(fakeX)
			local relativerot = sm.vec3.new(fakeX:dot(localY), fakeY:dot(localY), localZ:dot(localY))
			power = math.atan2(relativerot.x,relativerot.y)/math.pi * 180
			
			--value = 50-self.power/2.7
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
				power = 0
			end
		end
	end
	
	self.oldSpeed = self.shape.velocity
	if power ~= self.interactable.power then
		self.interactable:setPower(power)
	end
	--self.network:sendToClients("client_PosenUV", { posevalue = value, uv = self.modetable[self.mode].texturevalue } )
end

function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end


function Tacho.server_changemode(self, crouch)
	if not crouch then
		self.mode = (self.mode)%#self.modetable + 1
	else
		self.mode = (self.mode-2)%#self.modetable + 1
	end
	self.storage:save(self.modetable[self.mode].savevalue)
	self:server_sendModeToClient(true)
end

function Tacho.server_sendModeToClient(self, snd)
	self.network:sendToClients("client_newMode", {mode = self.mode, sound = snd})
end


function Tacho.client_canInteract(self)
	local _useKey = sm.gui.getKeyBinding("Use")
	local _tinkerKey = sm.gui.getKeyBinding("Tinker")
	local _crawlKey = sm.gui.getKeyBinding("Crawl")
	sm.gui.setInteractionText("Press", _useKey, " / ", _crawlKey.." + ".._useKey, "to cycle forwards / backwards")
	sm.gui.setInteractionText("Press", _tinkerKey, "to print the description of the selected function")
	return true
end

function Tacho.client_onTinker(self, character, lookAt)
	if lookAt then
		local _curMode = self.modetable[self.mode_client]
		if _curMode and _curMode.name and _curMode.description then
			sm.audio.play("GUI Item released")
			sm.gui.chatMessage(("[#ffff00X-O-Meter#ffffff] Description of \"#ffff00%s#ffffff\": %s"):format(_curMode.name, _curMode.description))
		else
			sm.gui.chatMessage("[#ffff00X-O-Meter#ffffff] #ff0000ERROR#ffffff: Couldn't get the name or description of the selected function")
		end
	end
end

function Tacho.client_newMode(self, data)
	self.mode_client = data.mode
	if data.sound then
		sm.audio.play("GUI Item drag", self.shape:getWorldPosition())
	end
end

function Tacho.client_onCreate(self)
	self.mode_client = 1
	self.network:sendToServer("server_sendModeToClient")
end

function Tacho.client_onFixedUpdate(self, dt)

	local mode = self.modetable[self.mode_client]
	
	self.interactable:setUvFrameIndex(mode.texturevalue)
	
	if mode.savevalue == 3 then --z pos
		
		local one = (math.sin(0-2*math.pi*(self.interactable.power/3+17)/134)+1)/2
		local two = (math.cos(2*math.pi*(self.interactable.power/3+17)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
	
	elseif mode.savevalue == 4 or mode.savevalue == 5 then -- x pos , y pos
		
		local one = (math.sin(0-2*math.pi*(self.interactable.power/14+67)/134)+1)/2
		local two = (math.cos(2*math.pi*(self.interactable.power/14+67)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
		
	elseif mode.savevalue == 6 then -- compass thingy 
		--local localX = sm.shape.getRight(self.shape)
		local localY = sm.shape.getAt(self.shape)
		local localZ = sm.shape.getUp(self.shape)--up
		local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
		localY = rot*localY*-1
		
		self.interactable:setPoseWeight(0 ,(localY.x+1)/2)
		self.interactable:setPoseWeight(1 ,(localY.y+1)/2)
		
		
	elseif mode.savevalue == 7 then -- velocity
		
		local one = (math.sin(0-2*math.pi*(self.interactable.power/4+67)/134)+1)/2
		local two = (math.cos(2*math.pi*(self.interactable.power/4+67)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
		
	elseif mode.savevalue == 8 then --rpm
		
		local one = (math.sin(0-2*math.pi*(self.interactable.power+67)/134)+1)/2
		local two = (math.cos(2*math.pi*(self.interactable.power+67)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
		
	elseif mode.savevalue == 10 then --mass
		
		local one = (math.sin(0-2*math.pi*(self.interactable.power/10+7)/134)+1)/2
		local two = (math.cos(2*math.pi*(self.interactable.power/10+7)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
		
	elseif mode.savevalue == 11 then -- orient
		
		local value = 50+self.interactable.power/2.7
		if self.shape:getZAxis().z < 0 then
			value = 50-self.interactable.power/2.7
		end
		
		local one = (math.sin(0-2*math.pi*(value+17)/134)+1)/2
		local two = (math.cos(2*math.pi*(value+17)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
	
	else
		local one = (math.sin(0-2*math.pi*(self.interactable.power+17)/134)+1)/2
		local two = (math.cos(2*math.pi*(self.interactable.power+17)/134)+1)/2  
		--print(self.posevalue, one, two)
		self.interactable:setPoseWeight(0 ,one)
		self.interactable:setPoseWeight(1 ,two)
	end
end

function Tacho.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	self.network:sendToServer("server_changemode", character:isCrouching())
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

