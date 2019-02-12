--[[
    radar.lua
  ]]--

radar = class( nil )
radar.maxChildCount = 0 -- Amount of outputs
radar.maxParentCount = 1 -- Amount of inputs
radar.connectionInput = sm.interactable.connectionType.logic -- Type of input
radar.connectionOutput = sm.interactable.connectionType.none -- Type of output
radar.colorNormal = sm.color.new( 0x470067ff ) -- Connection and dot color
radar.colorHighlight = sm.color.new( 0x601980ff ) -- Connection and dot color when you highlight it
radar.poseWeightCount = 3 

function radar.server_onCreate( self )
    self:server_init()
end
function radar.server_onRefresh( self )
    self:server_init()
end

function radar.client_onCreate( self ) 
	self:client_init()--someone joins
	self.network:sendToServer("server_gimmeindex")
end
function radar.server_gimmeindex(self)
	self.network:sendToClients("client_range",{range = self.range, uvindex = self.uvindex})
end
function radar.server_init( self )
	self.range = 256
	self.uvindex = 3
	players = {}
	
	local stored = self.storage:load()
	if stored then
		self.uvindex = stored - 1 
	end
	self.range = 2^(5+self.uvindex)
	--self.network:sendToClients("client_range",{range = self.range, uvindex = self.uvindex})
	self.storage:save(self.uvindex + 1)
end
function radar.client_init( self )
	--self.range = 256
	--self.uvindex = 3
	self.players = {}
end	


function radar.server_addplayer(self, player)
	if players then
		players[player.id] = player
	end
end

function radar.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
	self.network:sendToServer("server_clientInteract", crouching)
end

function radar.server_clientInteract(self, crouch)
	if not crouch then
		self.range = self.range * 2
		self.uvindex = self.uvindex + 1
		if self.range > 4096 then
			self.range = 32
			self.uvindex = 0
		end
	else
		self.range = self.range / 2
		self.uvindex = self.uvindex - 1
		if self.range < 32 then
			self.range = 4096
			self.uvindex = 7
		end
	end
	self.storage:save(self.uvindex + 1)
	self.network:sendToClients("client_playsound", "Blueprint - Open")
	self.network:sendToClients("client_range",{range = self.range, uvindex = self.uvindex})
end

function radar.client_range(self, data)
	self.range = data.range
	self.uvindex = data.uvindex
end


function radar.server_onFixedUpdate( self, dt )

	local localX = sm.shape.getRight(self.shape)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local pos = self.shape:getWorldPosition()
	local parent = self.interactable:getSingleParent()
	--print(parents)
	if not (parent and parent:isActive()) then -- mode where it doesn't take current rotation of thing in account, just tries to have a top view of map
		local radians = math.acos(localZ:dot(sm.vec3.new(0,0,1)))
		local axis = localZ:cross(sm.vec3.new(0,0,1)):normalize()
		if radians == 0 or math.deg(radians) == 180 then
		else
			localX = sm.vec3.rotate(localX, radians, axis)
			localY = sm.vec3.rotate(localY, radians, axis)
			localZ = sm.vec3.new(0,0,1)
		end
		if self.parentwasactive then
			self.network:sendToClients("client_playsound", "Blueprint - Camera")
		end
	end
	if (parent and parent:isActive()) and not self.parentwasactive then
		self.network:sendToClients("client_playsound", "Blueprint - Camera")
	end
	self.parentwasactive = parent and parent:isActive()
	
	local useableplayers = {}
	
	if players then
		for k,v in pairs(players) do -- get useable targets
			if v then
				local dir = v.pos - pos
				local radarloc = sm.vec3.new(dir:dot(localX),-dir:dot(localY),dir:dot(localZ))
				
				local x = radarloc.x / self.range + 0.5
				local y = radarloc.y / self.range + 0.5
				if x>0 and x<1 and y>0 and y<1 and v.timeout < 40 and nojammercloseby(v) then
					useableplayers[k] = v
				end
				if v.timeout < 40 then
					--v.timeout = v.timeout + 1
				else
					players = {} -- skrew it, clear all
				end
			end
		end
	end
	if trackers then
		for k,v in pairs(trackers) do -- get useable tracker targets
			if v then
				local dir = v.pos - pos
				local radarloc = sm.vec3.new(dir:dot(localX),-dir:dot(localY),dir:dot(localZ))
				
				local x = radarloc.x / self.range + 0.5
				local y = radarloc.y / self.range + 0.5
				if x>0 and x<1 and y>0 and y<1 and v.timeout < 40 and nojammercloseby(v) then
					useableplayers[k] = v
				end
				if v.timeout < 40 then
					--v.timeout = v.timeout + 1
				else
					trackers = {} -- skrew it, clear all
				end
			end
		end
	end
	self.network:sendToClients("client_getplayers", useableplayers)
end


function radar.client_getplayers(self, players)
	self.players = players
end

function radar.client_onFixedUpdate( self, dt ) --render
	if self.range == nil then return end
	local playerPosition = sm.localPlayer.getPosition()
	local Id = sm.localPlayer.getId()
	local player = {
		id = Id,
		pos = playerPosition,
		timeout = 0,
		player = true
	}
	self.network:sendToServer("server_addplayer", player)
	
	local localX = sm.shape.getRight(self.shape)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local pos = self.shape:getWorldPosition()
	--print(players)
	local parents = self.interactable:getParents()
	local on = 0
	if not (#parents >0 and parents[1]:isActive()) then -- mode where it doesn't take current rotation of thing in account, just tries to have a top view of map
		local radians = math.acos(localZ:dot(sm.vec3.new(0,0,1)))
		local axis = localZ:cross(sm.vec3.new(0,0,1)):normalize()
		if radians == 0 or math.deg(radians) == 180 then
		else
			localX = sm.vec3.rotate(localX, radians, axis)
			localY = sm.vec3.rotate(localY, radians, axis)
			localZ = sm.vec3.new(0,0,1)
		end
		on = 8
	end
	
	local i = 1
	self.interactable:setPoseWeight( 2, 0) -- right
	self.interactable:setPoseWeight( 1, 0) -- bottom
	if self.index == nil then self.index = 0 end
	for k,v in pairs(self.players) do -- draw useable targets
		local dir = v.pos - pos
		local radarloc = sm.vec3.new(dir:dot(localX),-dir:dot(localY),dir:dot(localZ))
		
		local x = radarloc.x / self.range + 0.5
		local y = radarloc.y / self.range + 0.5
		--print(x)
		--print(y)
		if x>0 and x<1 and y>0 and y<1 and self.index == i then
			-- draw on radar
			--print('test')
			self.interactable:setPoseWeight( 2, x) -- right
			self.interactable:setPoseWeight( 1, y) -- bottom
			if v.player then
				self.interactable:setPoseWeight( 0, 1 )
			else
				self.interactable:setPoseWeight( 0, 0 )
			end
		end
		i = i + 1
	end
	self.interactable:setUvFrameIndex(self.uvindex + on)
	
	self.index = self.index + 1
	if self.index > i-1 then 
		self.index = 1
	end

	-- self.interactable:setPoseWeight( 2, self.posV ) -- horizontal
	-- self.interactable:setPoseWeight( 1, self.posH ) -- vert
	-- self.interactable:setPoseWeight( 0, 1 )  -- color

end

function radar.client_playsound(self, sound) -- don't touch
	sm.audio.play(sound, self.shape:getWorldPosition())
end


function nojammercloseby(player)
	if jammers then
		for k,v in pairs(jammers) do
			if v then
				--v.timeout = v.timeout + 1
				if v.timeout < 40 and sm.vec3.length(player.pos - v.pos) < 5 then --5 units = 20 blocks
				return false end
				if v.timeout > 40 then jammers = {} end
			end
		end
	end
	return true
end



radar3d = class( nil )
radar3d.maxChildCount = 10 -- Amount of outputs
radar3d.maxParentCount = 0 -- Amount of inputs
radar3d.connectionInput = sm.interactable.connectionType.none -- Type of input
radar3d.connectionOutput = 512 -- Type of output
radar3d.colorNormal = sm.color.new( 0x470067ff ) -- Connection and dot color
radar3d.colorHighlight = sm.color.new( 0x601980ff ) -- Connection and dot color when you highlight it
radar3d.poseWeightCount = 3 
radar3d.dwarfs = {}
radar3d.players = {}

function radar3d.server_onCreate( self )
    self:server_init()
end
function radar3d.server_onRefresh( self )
    self:server_init()
end

function radar3d.server_init( self )
	--sm.storage.save(123, {})
	players = {}
end


function radar3d.client_onCreate( self ) 
	self:server_init()
end

function radar3d.server_onFixedUpdate( self, dt )

	local localX = sm.shape.getRight(self.shape)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local pos = self.shape:getWorldPosition()
	local radians = math.acos(localZ:dot(sm.vec3.new(0,0,1)))
	local axis = localZ:cross(sm.vec3.new(0,0,1)):normalize()
	localX = sm.vec3.rotate(localX, radians, axis)
	localY = sm.vec3.rotate(localY, radians, axis)
	localZ = sm.vec3.new(0,0,1)
	
	local range = 250 -- 1 range = 4 blocks
	local usableplayers = {} -- self.players within range & not timed out
	for k,v in pairs(players) do -- get useable targets
		if v then
			local dir = v.pos - pos
			local radar3dloc = sm.vec3.new(dir:dot(localX),dir:dot(localY),dir:dot(localZ))
			local x = radar3dloc.x / range + 0.5
			local y = radar3dloc.y / range + 0.5
			local z = v.pos.z / range
			if x>0 and x<1 and y>0 and y<1 and z>0 and z<1 and v.timeout < 40 and nojammercloseby(v) and v.player == true then -- and v.player == true
				usableplayers[k] = v
			end
			if v.timeout < 40 then
				--v.timeout = v.timeout + 1
			else
				players = {}
			end
		end
	end
	--print(usableplayers)
	self.network:sendToClients("client_getplayers",  usableplayers)
end

function radar3d.client_getplayers(self, players)
	self.players = players
end

function radar3d.server_addplayer(self, player)
	--local players = sm.storage.load(123)
	if players then
		players[player.id] = player
		--sm.storage.save(123, players)
	end
end


function radar3d.client_onFixedUpdate( self, dt )
	if self.index == nil then self.index = 0 end
	
	local playerPosition = sm.localPlayer.getPosition()
	local Id = sm.localPlayer.getId()
	local player = {
		id = Id,
		pos = playerPosition,
		timeout = 0,
		player = true
	}
	self.network:sendToServer("server_addplayer", player)
	
	local localX = sm.shape.getRight(self.shape)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local pos = self.shape:getWorldPosition()
	
	local radians = math.acos(localZ:dot(sm.vec3.new(0,0,1)))
	local axis = localZ:cross(sm.vec3.new(0,0,1)):normalize()
	localX = sm.vec3.rotate(localX, radians, axis)
	localY = sm.vec3.rotate(localY, radians, axis)
	localZ = sm.vec3.new(0,0,1)
	
	local range = 250 -- 1 range = 4 blocks
	
	
	-- protection so it only connects to dwarfs=
	
	-- disconnect(...)
	--
	
	--radar3d.dwarfs = {}
	local myplayers = shallowcopy(self.players)
	for k, v in pairs(self.interactable:getChildren()) do
		--print(v.id)
		if size(myplayers) > 1 then
			local firstplayer = tableFindFirstNotNil(myplayers)
			radar3d.dwarfs[v:getShape().id] = firstplayer
			
			for k, v in pairs(myplayers) do -- remove player from list of radar3d self.players
				if v == firstplayer then myplayers[k] = nil end
				
				if v.timeout > 40 then
					radar3d.dwarfs = {}
				end
			end
		else
			radar3d.dwarfs[v:getShape().id] = nil
		end
	end
	myplayers = tablewithoutnil(myplayers)
	
	local i = 1
	if size(myplayers) == 0 then
		--print(size(self.players))
		self.interactable:setPoseWeight( 0, 0.5)
		self.interactable:setPoseWeight( 1, 0)
		self.interactable:setPoseWeight( 2, 0)
	end
	for k,v in pairs(myplayers) do -- draw useable targets
		local dir = v.pos - pos
		local radar3dloc = sm.vec3.new(dir:dot(localX),dir:dot(localY),dir:dot(localZ))
		
		local x = radar3dloc.x / range + 0.5 
		local y = radar3dloc.y / range + 0.5
		local z = v.pos.z / range
		--print(x)
		--print(y)
		if self.index == i then
			-- draw on radar3d
			-- 0x 1y 2z
			self.interactable:setPoseWeight( 0, x)
			self.interactable:setPoseWeight( 1, y)
			self.interactable:setPoseWeight( 2, z)
		end
		i = i + 1
	end
	
	self.index = self.index + 1
	if self.index > i-1 then 
		self.index = 1
	end

	-- self.interactable:setPoseWeight( 2, self.posV ) -- horizontal
	-- self.interactable:setPoseWeight( 1, self.posH ) -- vert
	-- self.interactable:setPoseWeight( 0, 1 )  -- color

end




function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function tableFindFirstNotNil( sometable )
	for k, v in pairs(sometable) do
		if v~=nil then
			return v
		end
	end
end

function tablewithoutnil (sometable)
	local newtable = {}
	for k, v in pairs(sometable) do
		if v~=nil then
			newtable[k] = v
		end
	end
	return newtable
end

function size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i +1
	end
	return i
end








dwarf = class( nil )
dwarf.maxChildCount = 0 -- Amount of outputs
dwarf.maxParentCount = 1 -- Amount of inputs
dwarf.connectionInput = 512 -- Type of input
dwarf.connectionOutput = sm.interactable.connectionType.none -- Type of output
dwarf.colorNormal = sm.color.new( 0x470067ff ) -- Connection and dot color
dwarf.colorHighlight = sm.color.new( 0x601980ff ) -- Connection and dot color when you highlight it
dwarf.poseWeightCount = 3 


function dwarf.server_onCreate( self )
    self:server_init()
	
end
function dwarf.server_onRefresh( self )
    self:server_init()
end

function dwarf.server_init( self )
	print(sm.player.getAllPlayers()[1].character.worldPosition)
end


function dwarf.client_onCreate( self )
	sm.audio.play("Retrowildblip", self.shape:getWorldPosition())
	--self:server_init()
end


function dwarf.client_onFixedUpdate( self, dt )
	
	local parentradar = self.interactable:getSingleParent()
	
	
	--draw dwarf in holder
	local mydwarf = nil
	if parentradar then 
		for k, v in pairs(radar3d.dwarfs) do
			if k == self.shape.id then
				mydwarf = v
			end
			if v == nil then break end
		end
		if not self.hadparent then
			sm.audio.play("Blueprint - Share", self.shape:getWorldPosition())
		end
	end
	self.hadparent = parentradar
	--print(radar3d.dwarfs)
	--print(mydwarf)
	if parentradar and mydwarf ~= nil then -- connected to a radar and radar gave me a valid dwarf to play with
			
		local localX = sm.shape.getRight(self.shape)
		local localY = sm.shape.getAt(self.shape)
		local localZ = sm.shape.getUp(self.shape)
		local pos = self.shape:getWorldPosition()
		
		local parentX = sm.shape.getRight(parentradar:getShape())
		local parentY = sm.shape.getAt(parentradar:getShape())
		local parentZ = sm.shape.getUp(parentradar:getShape())
		local radarpos = parentradar:getShape():getWorldPosition()
		local helplocalZ = parentZ
		
		--print(pos)
		local rx = (radarpos-pos):dot(localX)
		local rz = (radarpos-pos):dot(localY)
		
		-- mode where it doesn't take current rotation of thing in account, just tries to have a top view of map
		local radians = math.acos(parentZ:dot(sm.vec3.new(0,0,1)))
		local axis = parentZ:cross(sm.vec3.new(0,0,1)):normalize()
		parentX = sm.vec3.rotate(parentX, radians, axis)
		parentY = sm.vec3.rotate(parentY, radians, axis)
		parentZ = sm.vec3.new(0,0,1)
	
		
		local range = 250 -- 1 range = 4 blocks
		
		local dir = mydwarf.pos - pos
		local radar3dloc = sm.vec3.new(dir:dot(parentX),dir:dot(parentY),dir:dot(parentZ))
		
		local x = 0.5 + (radar3dloc.x / range )*5/9 - (0.382643/12)*(radar3dloc.x / range ) - (rx*4/(8.45))
		local y = radar3dloc.y / range + 0.5 + 0.187097/40
		local z = (mydwarf.pos.z / range)*5/7  - (0.538989/17)*(mydwarf.pos.z / range)+ ((rz)/1.75 - 1/7 + rz*0.538989/17) + (tostring(parentradar:getShape():getShapeUuid()) == "cda6ec74-0940-4821-a60f-b57320fa11f6" and 2.5/7 or 0)--(rz-0.25-0.538989/2)*8/(7)
		
		if x>0 and x<1 and y>0 and y<1 and z>0 and z<1 and mydwarf.timeout < 40 then
			--print('okay')
			self.interactable:setPoseWeight( 0, x)
			self.interactable:setPoseWeight( 1, y)
			self.interactable:setPoseWeight( 2, z)
		else
			self.interactable:setPoseWeight( 0, 0.5)
			self.interactable:setPoseWeight( 1, 1)
			self.interactable:setPoseWeight( 2, 0)
		end
	else
		self.interactable:setPoseWeight( 0, 0.5)
		self.interactable:setPoseWeight( 1, 1)
		self.interactable:setPoseWeight( 2, 0)
	end
	
end
