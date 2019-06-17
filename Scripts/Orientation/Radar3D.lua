dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if Radar3D and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

mpPrint("loading Radar3D.lua")


Radar3D = class( nil )
Radar3D.maxChildCount = 0 -- Amount of outputs
Radar3D.maxParentCount = 0 -- Amount of inputs
Radar3D.connectionInput = sm.interactable.connectionType.none -- Type of input
Radar3D.connectionOutput = sm.interactable.connectionType.none -- Type of output
Radar3D.colorNormal = sm.color.new( 0x470067ff ) -- Connection and dot color
Radar3D.colorHighlight = sm.color.new( 0x601980ff ) -- Connection and dot color when you highlight it
Radar3D.poseWeightCount = 3 


function Radar3D.server_onCreate( self )
	self.uvindexserver = 3
	local stored = self.storage:load()
	if stored then
		self.uvindexserver = stored
	end
end
function Radar3D.server_onRefresh( self )
    self:server_onCreate()
end


function Radar3D.server_sendIndexToClients(self, playsound)
	self.network:sendToClients("client_range", {self.uvindexserver, playsound})
end

function Radar3D.server_clientInteract(self, crouch)
	self.uvindexserver = (self.uvindexserver + (crouch and -1 or 1))%7
	self.storage:save(self.uvindexserver)
	self:server_sendIndexToClients(true)
end

--function Radar3D.client_onInteract(self)
--	self.network:sendToServer("server_clientInteract", sm.localPlayer.getPlayer().character:isCrouching())
--end

function Radar3D.client_range(self, data)
	if data[2] then sm.audio.play("Blueprint - Camera", self.shape:getWorldPosition()) end
	self.uvindex = data[1]
	self.range = 2^(5+self.uvindex)
	self.interactable:setUvFrameIndex(self.uvindex)
end



function Radar3D.client_onCreate( self )
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
	self.playermodels = { -- [ name ] = effectname
		["kAN"] = "Radar3dplayer_kAN",
		["Moonbo"] = "Radar3dplayer_Moonbo",
		["ScrapMan"] = "Radar3dplayer_ScrapMan",
		["CamodoGaming"] = "Radar3dplayer_CamodoGaming",
		["S.M.L. Chief Engineer"] = "Radar3dplayer_SML",
		["Brent Batch"] = "Radar3dplayer_BB",
		["Adahop"] = "Radar3dplayer_neebs_gaming",
		["Simon"] = "Radar3dplayer_neebs_gaming",
		["JonnyEthco"] = "Radar3dplayer_neebs_gaming",
		["neebs_gaming"] = "Radar3dplayer_neebs_gaming",
		["doraleous5000"] = "Radar3dplayer_neebs_gaming",
		["AnthonyCSN"] = "Radar3dplayer_neebs_gaming",
		["Thick44"] = "Radar3dplayer_neebs_gaming",
		["Durf"] = "Radar3dplayer_Durf"
	}
end
function Radar3D.client_onRefresh(self)
	self:client_onDestroy()
	self:client_onCreate()
end

function Radar3D.client_onFixedUpdate(self, dt)
	local localX = self.shape.right --right
	local localY = self.shape.at -- top
	local localZ = self.shape.up -- looking at you

	local pos = self.shape.worldPosition

	local radians = math.acos(localZ:dot(sm.vec3.new(0,0,1)))
	local axis = localZ:cross(sm.vec3.new(0,0,1))
	if radians ~= 0 and math.deg(radians) ~= 180 and radians == radians then
		localX = sm.vec3.rotate(localX, radians, axis:normalize())
		localY = sm.vec3.rotate(localY, radians, axis:normalize())
		localZ = sm.vec3.new(0,0,1)
	end
	
	local playeridsdrawn = {}
	local trackeridsdrawn = {}
	
	for targetId , targets in pairs({sm.player.getAllPlayers(),  trackertrackers or {}}) do
		for k, target in pairs(targets) do
			if target ~= nil and (targetId == 1 and sm.exists(target) or (sm.exists(target.shape))) then
				local targetpos = (targetId == 1 and target.character.worldPosition or target.shape.worldPosition)
				local dir = targetpos - pos
				
				local radarloc = sm.vec3.new(dir:dot(localX),targetpos.z,-dir:dot(localY))/ self.range - sm.vec3.new(0,0.6,0)
				if math.abs(radarloc.x) < 1 and math.abs(radarloc.y) < 1.4 and math.abs(radarloc.z) < 1 and nojammercloseby(targetpos) then
					if type(target) == "Player" then
						if not self.playereffects[target.id] then
							local modelname = self.playermodels[target.name]
							if not modelname then modelname = "Radar3Dplayer" end
							local effect = sm.effect.createEffect( modelname, self.interactable)
							effect:start()
							self.playereffects[target.id] = {effect, nil}
						end
						self.playereffects[target.id][1]:setOffsetPosition(radarloc/1.7)
						local direction = target.character:getDirection()
						direction.z = 0
						
						
						local lookquat = sm.vec3.getRotation(sm.vec3.new(0,0,1),sm.vec3.new(0,1,0)) * sm.vec3.getRotation(localY, -direction:normalize()) * sm.vec3.getRotation(sm.vec3.new(0,0,-1),sm.vec3.new(0,1,0))
						
						self.playereffects[target.id][1]:setOffsetRotation(lookquat)
						playeridsdrawn[target.id] = true
					else
						local dot = self.effectnames[tostring(target.shape.color)]
						dot = (dot and dot  or "RadarDot41")
						
						if self.trackereffects[target.shape.id] and self.trackereffects[target.shape.id][2] ~= dot then -- color changed
							self.trackereffects[target.shape.id][1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
							self.trackereffects[target.shape.id][1]:stop()
							self.trackereffects[target.shape.id] = nil
						end
						if not self.trackereffects[target.shape.id] then
							local effect = sm.effect.createEffect( dot, self.interactable)
							effect:start()
							self.trackereffects[target.shape.id] = {effect, dot}
						end
						self.trackereffects[target.shape.id][1]:setOffsetPosition(radarloc/1.7)
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

function Radar3D.client_onDestroy(self)
	for k, effects in pairs({self.playereffects, self.trackereffects}) do
		for k, effect in pairs(effects) do
			effect[1]:setOffsetPosition(sm.vec3.new(1000,1000,0))
			effect[1]:stop()
		end
	end
end
