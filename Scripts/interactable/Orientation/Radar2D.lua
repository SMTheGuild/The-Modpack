--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading Radar2D.lua")



Radar2D = class( nil )
Radar2D.maxChildCount = 0 -- Amount of outputs
Radar2D.maxParentCount = 1 -- Amount of inputs
Radar2D.connectionInput = sm.interactable.connectionType.logic -- Type of input
Radar2D.connectionOutput = sm.interactable.connectionType.none -- Type of output
Radar2D.colorNormal = sm.color.new( 0x470067ff ) -- Connection and dot color
Radar2D.colorHighlight = sm.color.new( 0x601980ff ) -- Connection and dot color when you highlight it
Radar2D.poseWeightCount = 3 

Radar2D.effectnames = {
	["eeeeeeff"] = "RadarDot1",
	["f5f071ff"] = "RadarDot2",
	["cbf66fff"] = "RadarDot3",
	["68ff88ff"] = "RadarDot4",
	["7eededff"] = "RadarDot5",
	["4c6fe3ff"] = "RadarDot6",
	["ae79f0ff"] = "RadarDot7",
	["ee7bf0ff"] = "RadarDot8",
	["f06767ff"] = "RadarDot9",
	["eeaf5cff"] = "RadarDot10",
	["7f7f7fff"] = "RadarDot11",
	["e2db13ff"] = "RadarDot12",
	["a0ea00ff"] = "RadarDot13",
	["19e753ff"] = "RadarDot14",
	["2ce6e6ff"] = "RadarDot15",
	["0a3ee2ff"] = "RadarDot16",
	["7514edff"] = "RadarDot17",
	["cf11d2ff"] = "RadarDot18",
	["d02525ff"] = "RadarDot19",
	["df7f00ff"] = "RadarDot20",
	["df7f01ff"] = "RadarDot20",
	["4a4a4aff"] = "RadarDot21",
	["817c00ff"] = "RadarDot22",
	["577d07ff"] = "RadarDot23",
	["0e8031ff"] = "RadarDot24",
	["118787ff"] = "RadarDot25",
	["0f2e91ff"] = "RadarDot26",
	["500aa6ff"] = "RadarDot27",
	["720a74ff"] = "RadarDot28",
	["7c0000ff"] = "RadarDot29",
	["673b00ff"] = "RadarDot30",
	["222222ff"] = "RadarDot31",
	["323000ff"] = "RadarDot32",
	["375000ff"] = "RadarDot33",
	["064023ff"] = "RadarDot34",
	["0a4444ff"] = "RadarDot35",
	["0a1d5aff"] = "RadarDot36",
	["35086cff"] = "RadarDot37",
	["520653ff"] = "RadarDot38",
	["560202ff"] = "RadarDot39",
	["472800ff"] = "RadarDot40"
}
	
Radar2D.uvindex = 3
Radar2D.range = 256

function Radar2D.server_onCreate( self )
	self.uvindexserver = 3
	local stored = self.storage:load()
	if stored then
		self.uvindexserver = stored
	end
end
function Radar2D.server_onRefresh( self )
	sm.isDev = true
    self:server_onCreate()
end


function Radar2D.server_sendIndexToClients(self, playsound)
	self.network:sendToClients("client_range", {self.uvindexserver, playsound})
end

function Radar2D.server_clientInteract(self, crouch)
	self.uvindexserver = (self.uvindexserver + (crouch and -1 or 1))%8
	self.storage:save(self.uvindexserver)
	self:server_sendIndexToClients(true)
end


function Radar2D.client_onInteract(self, character, lookAt)
	if not lookAt then return end
	self.network:sendToServer("server_clientInteract", sm.localPlayer.getPlayer().character:isCrouching())
end

function Radar2D.client_range(self, data)
	if data[2] then sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition()) end
	self.uvindex = data[1]
	self.range = 2^(5+self.uvindex)
	self.interactable:setUvFrameIndex(self.uvindex + (self.interactable.active and 8 or 0))
end



function Radar2D.client_onCreate( self )
	self.network:sendToServer("server_sendIndexToClients", false)
	self.playereffects = {}
	self.trackereffects = {}
end
function Radar2D.client_onRefresh(self)
	self:client_onDestroy()
	self:client_onCreate()
end

function Radar2D.client_onFixedUpdate(self, dt)
	local localX = self.shape.right --right
	local localY = self.shape.at -- top
	local localZ = self.shape.up -- looking at you

	local pos = self.shape.worldPosition
	local parent = self.interactable:getSingleParent()
	
	if not (parent and parent.active) then
		local radians = math.acos(localZ:dot(sm.vec3.new(0,0,1)))
		local axis = localZ:cross(sm.vec3.new(0,0,1))
		if radians ~= 0 and math.deg(radians) ~= 180 and radians == radians and axis:length() > 0.0001 then
			localX = sm.vec3.rotate(localX, radians, axis:normalize())
			localY = sm.vec3.rotate(localY, radians, axis:normalize())
			localZ = sm.vec3.new(0,0,1)
		end
		if self.parentwasactive then
			self.interactable:setUvFrameIndex(self.uvindex)
			sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition())
		end
	elseif not self.parentwasactive then
		self.interactable:setUvFrameIndex(self.uvindex + 8)
		sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition())
	end
	self.parentwasactive = parent and parent.active
	
	local playeridsdrawn = {}
	local trackeridsdrawn = {}
	
	for k, player in pairs(sm.player.getAllPlayers()) do
		if player and player.character and sm.exists(player) then
			local targetpos = player.character.worldPosition
			local dir = targetpos - pos
			
			local radarloc = sm.vec3.new(dir:dot(localX),dir:dot(localY),0)/ self.range
			if radarloc:length2()<1 and nojammercloseby(targetpos) then		
				if not self.playereffects[player.id] then
					local effect = sm.effect.createEffect( "RadarDot", self.interactable)
					effect:start()
					self.playereffects[player.id] = {effect, nil}
				end
				self.playereffects[player.id][1]:setOffsetPosition(radarloc/3.2)
				playeridsdrawn[player.id] = true
			end
		end
	end

	for k, target in pairs(trackertrackers or {}) do
		local targetShape = (target ~= nil and sm.exists(target.shape) and target:getTrackerShape() or nil)
		
		if targetShape then
			local targetpos = targetShape.worldPosition
			local dir = targetpos - pos
			
			local radarloc = sm.vec3.new(dir:dot(localX),dir:dot(localY),0)/ self.range
			
			if radarloc:length2()<1 and nojammercloseby(targetpos) then
				local dot = self.effectnames[tostring(targetShape.color)]
				dot = (dot and dot  or "RadarDot41")
				
				if  self.trackereffects[targetShape.id] and self.trackereffects[targetShape.id][2] ~= dot then
					self.trackereffects[targetShape.id][1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
					self.trackereffects[targetShape.id][1]:stop()
					self.trackereffects[targetShape.id] = nil
				end
				if not self.trackereffects[targetShape.id] then
					local effect = sm.effect.createEffect( dot, self.interactable)
					effect:start()
					self.trackereffects[targetShape.id] = {effect, dot}
				end
				self.trackereffects[targetShape.id][1]:setOffsetPosition(radarloc/3.2)
				trackeridsdrawn[targetShape.id] = true
			end
		else
			table.remove(trackertrackers, k)
		end
	end
	
	for id, eff in pairs(self.playereffects) do
		if not playeridsdrawn[id] then
			self.playereffects[id][1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
			self.playereffects[id][1]:stop()
			self.playereffects[id] = nil
		end
	end
	for id, eff in pairs(self.trackereffects) do
		if not trackeridsdrawn[id] then
			self.trackereffects[id][1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
			self.trackereffects[id][1]:stop()
			self.trackereffects[id] = nil
		end
	end
end

function Radar2D.server_onFixedUpdate(self, dt)
	local parent = self.interactable:getSingleParent()
	mp_setActiveSafe(self, parent and parent.active or false)
end

function Radar2D.client_onDestroy(self)
	for k, effects in pairs({self.playereffects, self.trackereffects}) do
		for k, effect in pairs(effects) do
			effect[1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
			effect[1]:stop()
		end
	end
end

function nojammercloseby(pos)
	for k,v in pairs(jammerjammers or {}) do
		if v and sm.exists(v) then
			-- the following will do an error upon loading the world, 
			if v.active and sm.vec3.length(pos - v.shape.worldPosition) < 5 then --5 units = 20 blocks
				return false 
			end
		else
			table.remove(jammerjammers, k)
		end
	end
	return true
end
