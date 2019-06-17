dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if SmartSensor and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

--dofile "../Libs/GameImprovements/interactable.lua"
dofile "../Libs/MoreMath.lua"
dofile "../Libs/Other.lua" -- getGlobal getLocal

mpPrint("loading SmartSensor.lua")


-- SmartSensor.lua --
SmartSensor = class( nil )
SmartSensor.maxChildCount = -1
SmartSensor.connectionInput = sm.interactable.connectionType.none
SmartSensor.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartSensor.colorNormal = sm.color.new( 0x76034dff )
SmartSensor.colorHighlight = sm.color.new( 0x8f2268ff )
SmartSensor.poseWeightCount = 3

SmartSensor.mode = 1
SmartSensor.mode_client = 1
SmartSensor.pose = 0
SmartSensor.raypoints = {
	sm.vec3.new(0,0,0),
	sm.vec3.new(0.118,0,0),
	sm.vec3.new(-0.118,0,0),
	sm.vec3.new(0.0839,0.0839,0),
	sm.vec3.new(0.0839,-0.0839,0),
	sm.vec3.new(-0.0839,0.0839,0),
	sm.vec3.new(-0.0839,-0.0839,0),
	sm.vec3.new(0,0.118,0),
	sm.vec3.new(0,-0.118,0)
}
SmartSensor.modes = {
	{ value = 0, targetPose = 0, 	description = "1 raycast, distance mode" },
	{ value = 1, targetPose = 0.8, 	description = "wide raycast, distance mode" },
	{ value = 2, targetPose = 0, 	description = "1 raycast, color mode" },
	{ value = 3, targetPose = 0.8, 	description = "wide raycast, color mode" },
	{ value = 4, targetPose = 0, 	description = "type mode: nothing = 0" }
}
SmartSensor.savemodes = {}
for k,v in pairs(SmartSensor.modes) do
   SmartSensor.savemodes[v.value] = k
end


function SmartSensor.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function SmartSensor.server_onCreate( self )
	local stored = self.storage:load()
	if stored then
		self.mode = self.savemodes[stored]
	else
		self.storage:save(self.modes[self.mode].value)
	end
end

function SmartSensor.server_onFixedUpdate( self, dt )
	local src = self.shape.worldPosition
	
	local mode = self.modes[self.mode].value
	
	local colormode = (mode == 2) or (mode == 3)
	local bigSize = (mode == 1) or (mode == 3)
	
	local distance = nil
	local colors = {}
	
	for k, raypoint in pairs( bigSize and self.raypoints or {sm.vec3.new(0,0,0)} ) do
		if colormode then
			local startPos = src + getLocal(self.shape, raypoint)
			local hit, result = sm.physics.raycast(startPos, startPos + self.shape.up*3000)
			if hit and result.type == "body" then
				local d = sm.vec3.length(src - result.pointWorld) * 4 - 0.5
				if distance == nil or d < distance then
					distance = d*4 - 0.5
				end
				local c = result:getShape().color
				local cc = tostring(math.round(c.b*255) + math.round(c.g*255*256) + math.round(c.r*255*256*256))
				if colors[cc] and colors[cc].distance == math.round(d) then
					colors[cc].count = colors[cc].count + 1
				elseif (not colors[cc] or colors[cc].distance > math.round(d)) then
					colors[cc] = {distance = math.round(d), count = 1} 
				end
			end
			
		elseif mode ~= 4 then -- not type mode
			-- distance mode
			local hit, fraction = sm.physics.distanceRaycast(src + getLocal(self.shape, raypoint), self.shape.up*3000)
			if hit then
				local d = fraction * 3000
				if distance == nil or d < distance then
					distance = d*4 - 0.5
				end
			end
		else 
			-- type mode
			local startPos = src + getLocal(self.shape, raypoint)
			local hit, result = sm.physics.raycast(startPos, startPos + self.shape.up*3000)
			local resulttype = result.type
			self.interactable.power = (resulttype == "terrainSurface" and 1 or 0) + (resulttype == "terrainAsset" and 2 or 0) + (resulttype == "lift" and 3 or 0) +
					(resulttype == "body" and 4 or 0) + (resulttype == "character" and 5 or 0) + (resulttype == "joint" and 6 or 0) + (resulttype == "vision" and 7 or 0)
					
		end
	end
	
	
	if mode ~= 4 then
		if colormode then
			local bestmatch = nil
			local color = 0
			for k, v in pairs(colors) do
				if bestmatch == nil then 
					bestmatch = v 
					color = tonumber(k)
				end
				if (v.distance < bestmatch.distance) or (v.distance == bestmatch.distance and v.count > bestmatch.count) then
					bestmatch = v
					color = tonumber(k)
				end
			end
			self.interactable.power = color
		else
			self.interactable.power = distance or 0
		end
	end
	
	self.interactable.active = self.interactable.power > 0
end

function SmartSensor.server_changemode(self, crouch)
    self.mode = (self.mode + (crouch and -1 or 1) - 1 )%5 + 1
    self.storage:save(self.modes[self.mode].value)
	self.network:sendToClients("client_newMode", {self.mode, true})
end

function SmartSensor.server_requestMode(self)
	self.network:sendToClients("client_newMode", {self.mode, false})
end


-- Client --

function SmartSensor.client_onCreate(self)
	-- client joins world, requests mode from server
	self.network:sendToServer("server_requestMode")
end

function SmartSensor.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
    self.network:sendToServer("server_changemode", crouching)
end

function SmartSensor.client_newMode(self, data)
	self.mode_client = data[1]
	if data[2] then
		print(self.modes[self.mode_client].description)
		sm.audio.play("ConnectTool - Rotate", self.shape:getWorldPosition())
	end
end

function SmartSensor.client_onFixedUpdate(self, dt)
	local targetPose = self.modes[self.mode_client].targetPose
	if self.pose == targetPose then return end
	if self.pose > targetPose then
		self.pose = self.pose - 0.04
	elseif self.pose < targetPose then
		self.pose = self.pose + 0.04
	end
	self.interactable:setPoseWeight(0, self.pose)
end


