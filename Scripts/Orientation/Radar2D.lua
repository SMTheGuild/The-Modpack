dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if Radar2D and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

mpPrint("loading Radar2D.lua")



Radar2D = class( nil )
Radar2D.maxChildCount = 0 -- Amount of outputs
Radar2D.maxParentCount = 1 -- Amount of inputs
Radar2D.connectionInput = sm.interactable.connectionType.logic -- Type of input
Radar2D.connectionOutput = sm.interactable.connectionType.none -- Type of output
Radar2D.colorNormal = sm.color.new( 0x470067ff ) -- Connection and dot color
Radar2D.colorHighlight = sm.color.new( 0x601980ff ) -- Connection and dot color when you highlight it
Radar2D.poseWeightCount = 3 

function Radar2D.server_onCreate( self )
	self.uvindexserver = 3
	local stored = self.storage:load()
	if stored then
		self.uvindexserver = stored
	end
end
function Radar2D.server_onRefresh( self )
    self:server_onCreate()
end


function Radar2D.server_sendIndexToClients(self, playsound)
	self.network:sendToClients("client_range", {self.uvindexserver, playsound})
end

function Radar2D.server_clientInteract(self, crouch)
	self.uvindexserver = (self.uvindexserver + (crouch and -1 or 1))%7
	self.storage:save(self.uvindexserver)
	self:server_sendIndexToClients(true)
end


function Radar2D.client_onInteract(self)
	self.network:sendToServer("server_clientInteract", sm.localPlayer.getPlayer().character:isCrouching())
end

function Radar2D.client_range(self, data)
	if data[2] then sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition()) end
	self.uvindex = data[1]
	self.range = 2^(5+self.uvindex)
	self.interactable:setUvFrameIndex(self.uvindex + (self.interactable.active and 6 or 0))
end



function Radar2D.client_onCreate( self )
	self.uvindex = 3
	self.range = 256
	self.network:sendToServer("server_sendIndexToClients", false)
	self.playereffects = {}
	self.trackereffects = {}
	self.effectnames = {
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
		if radians ~= 0 and math.deg(radians) ~= 180 and radians == radians then
			localX = sm.vec3.rotate(localX, radians, axis:normalize())
			localY = sm.vec3.rotate(localY, radians, axis:normalize())
			localZ = sm.vec3.new(0,0,1)
		end
		if self.parentwasactive then
			sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition())
		end
	elseif not self.parentwasactive then
		sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition())
	end
	self.parentwasactive = parent and parent:isActive()
	
	local playeridsdrawn = {}
	local trackeridsdrawn = {}
	
	for targetId , targets in pairs({sm.player.getAllPlayers(), trackertrackers or {}}) do
		for k, target in pairs(targets) do
			if target ~= nil and (targetId == 1 and sm.exists(target) or (sm.exists(target.shape))) then
				local targetpos = (targetId == 1 and target.character.worldPosition or target.shape.worldPosition)
				local dir = targetpos - pos
				
				local radarloc = sm.vec3.new(dir:dot(localX),dir:dot(localY),0)/ self.range
				if radarloc:length2()<1 and nojammercloseby(targetpos) then					
					if type(target) == "Player" then
						if not self.playereffects[target.id] then
							local effect = sm.effect.createEffect( "RadarDot", self.interactable)
							effect:start()
							self.playereffects[target.id] = {effect, nil}
						end
						self.playereffects[target.id][1]:setOffsetPosition(radarloc/3.2)
						playeridsdrawn[target.id] = true
					else
						local dot = self.effectnames[tostring(target.shape.color)]
						dot = (dot and dot  or "RadarDot41")
						
						if self.trackereffects[target.shape.id] and self.trackereffects[target.shape.id][2] ~= dot then
							self.trackereffects[target.shape.id][1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
							self.trackereffects[target.shape.id][1]:stop()
							self.trackereffects[target.shape.id] = nil
						end
						if not self.trackereffects[target.shape.id] then
							local effect = sm.effect.createEffect( dot, self.interactable)
							effect:start()
							self.trackereffects[target.shape.id] = {effect, dot}
						end
						self.trackereffects[target.shape.id][1]:setOffsetPosition(radarloc/3.2)
						trackeridsdrawn[target.shape.id] = true
					end
				end
			elseif targetId == 2 then
				table.remove(trackertrackers, k)
			end
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
	self.interactable.active = (parent and parent.active or false) 
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
