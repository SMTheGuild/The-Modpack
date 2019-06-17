dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if SmartSensor and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

--dofile "../Libs/GameImprovements/interactable.lua"
dofile "../Libs/MoreMath.lua"

mpPrint("loading SmartSensor.lua")

-- TODO : 
--  improve networking (send self.mode to client)
--  better console prints


-- SmartSensor.lua --
SmartSensor = class( nil )
SmartSensor.maxChildCount = -1
SmartSensor.connectionInput = sm.interactable.connectionType.none
SmartSensor.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartSensor.colorNormal = sm.color.new( 0x76034dff )
SmartSensor.colorHighlight = sm.color.new( 0x8f2268ff )
SmartSensor.poseWeightCount = 3


function SmartSensor.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function SmartSensor.server_onCreate( self )
	self.distance = 0
	self.mode = 0
	self.pose = 0
	self.raypoints = {
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
	local stored = self.storage:load()
	--print('ignore errors')
	if stored then 
		self.mode = stored
	else
		self.storage:save(self.mode)
	end
end


function SmartSensor.getGlobal(self, vec)
    return self.shape.right* vec.x + self.shape.at * vec.y + self.shape.up * vec.z
end
function SmartSensor.getLocal(self, vec)
    return sm.vec3.new(self.shape.right:dot(vec), self.shape.at:dot(vec), self.shape.up:dot(vec))
end

-- small , big , c small, c big, type

function SmartSensor.server_onFixedUpdate( self, dt )
	local src = self.shape.worldPosition
	
	local colormode = (self.mode == 2) or (self.mode == 3)
	local bigSize = (self.mode == 1) or (self.mode == 3)
	
	local distance = nil
	local colors = {}
	
	for k, raypoint in pairs( bigSize and self.raypoints or {sm.vec3.new(0,0,0)} ) do
		if colormode then
			local hit, result = sm.physics.raycast(src + self:getLocal(raypoint), src + self:getLocal(raypoint) + self.shape.up*5000)
			if hit and result.type == "body" then
				local d = sm.vec3.length(src-result.pointWorld)*4 - 0.5 -- math.floor
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
		elseif self.mode ~= 4 then
			-- distance mode
			local hit, fraction = sm.physics.distanceRaycast(src + self:getLocal(raypoint), self.shape.up*5000)
			if hit then
				local d = fraction * 5000
				if distance == nil or d < distance then
					distance = d*4 - 0.5
				end
			end
		else 
			-- type mode
			local hit, result = sm.physics.raycast(src + self:getLocal(raypoint), src + self:getLocal(raypoint) + self.shape.up*5000)
			local resulttype = result.type
			self.interactable.power = (resulttype == "terrainSurface" and 1 or 0) + (resulttype == "terrainAsset" and 2 or 0) + (resulttype == "lift" and 3 or 0) +
					(resulttype == "body" and 4 or 0) + (resulttype == "character" and 5 or 0) + (resulttype == "joint" and 6 or 0) + (resulttype == "vision" and 7 or 0)
		end
	end
	
	
	if self.mode ~= 4 then
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
	
	if self.pose > self.mode%2 then
		self.pose = self.pose - 0.04
	end
	if self.pose < self.mode%2 *0.8 then
		self.pose = self.pose + 0.04
	end
	
	self.interactable.active = self.interactable.power > 0
	if self.pose ~= self.lastpose then
		self.network:sendToClients("client_setposeweight", self.pose)
	end
	self.lastpose = self.pose
end

function SmartSensor.client_setposeweight(self, pose)
	self.interactable:setPoseWeight(0,pose)
end

function SmartSensor.server_changemode(self, crouch)
    self.mode = (self.mode+ (crouch and -1 or 1))%5
    self.storage:save(self.mode)
	print( self.mode > 1 and (self.mode == 4 and "type of detected" or "colormode") or "not colormode")
	self.network:sendToClients("client_playsound", "ConnectTool - Rotate")
end
function SmartSensor.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
    self.network:sendToServer("server_changemode", crouching)
	
end
function SmartSensor.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end

function SmartSensor.client_onCreate(self)
	self.network:sendToServer("server_requestpose")
end

function SmartSensor.server_requestpose(self)
	self.network:sendToClients("client_setposeweight", self.pose)
end
