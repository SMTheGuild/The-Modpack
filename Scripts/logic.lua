-- LOGIC.LUA : many awesome logic gate expansions
dofile('functions.lua')


-- analogsensor.lua --
analogsensor = class( nil )
analogsensor.maxChildCount = -1
analogsensor.connectionInput = sm.interactable.connectionType.none
analogsensor.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
analogsensor.colorNormal = sm.color.new( 0x76034dff )
analogsensor.colorHighlight = sm.color.new( 0x8f2268ff )
analogsensor.poseWeightCount = 3

function analogsensor.server_onCreate( self ) 
	self:server_init()
end

function analogsensor.server_init( self ) 
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


function analogsensor.getGlobal(self, vec)
    return self.shape.right* vec.x + self.shape.at * vec.y + self.shape.up * vec.z
end
function analogsensor.getLocal(self, vec)
    return sm.vec3.new(self.shape.right:dot(vec), self.shape.at:dot(vec), self.shape.up:dot(vec))
end

-- small , big , c small, c big, type

function analogsensor.server_onRefresh( self )
	self:server_init()
end
function analogsensor.server_onFixedUpdate( self, dt )
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
				local cc = tostring(round(c.b*255) + round(c.g*255*256) + round(c.r*255*256*256))
				if colors[cc] and colors[cc].distance == round(d) then
					colors[cc].count = colors[cc].count + 1
				elseif (not colors[cc] or colors[cc].distance > round(d)) then
					colors[cc] = {distance = round(d), count = 1} 
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
	
	if EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4 then
		self.interactable:setPower(self.interactable.power*math.random(80, 120)/100)
		sm.interactable.setValue(self.interactable, self.interactable.power)
	end
end

function analogsensor.client_setposeweight(self, pose)
	self.interactable:setPoseWeight(0,pose)
end

function analogsensor.server_changemode(self, crouch)
    self.mode = (self.mode+ (crouch and -1 or 1))%5
    self.storage:save(self.mode)
	print( self.mode > 1 and (self.mode == 4 and "type of detected" or "colormode") or "not colormode")
	self.network:sendToClients("client_playsound", "ConnectTool - Rotate")
end
function analogsensor.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
    self.network:sendToServer("server_changemode", crouching)
	
end
function analogsensor.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end

function analogsensor.client_onCreate(self)
	self.network:sendToServer("server_requestpose")
end

function analogsensor.server_requestpose(self)
	self.network:sendToClients("client_setposeweight", self.pose)
end


function listlength(list)
	local l = 0
	for k, v in pairs(list) do
		l = l + 1
	end
	return l
end



-- potentiometer.lua --
potentiometer = class( nil )
potentiometer.maxParentCount = -1 -- infinite
potentiometer.maxChildCount = -1 -- infinite
potentiometer.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
potentiometer.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
potentiometer.colorNormal = sm.color.new( 0x00194Cff )
potentiometer.colorHighlight = sm.color.new( 0x0A2866ff )
potentiometer.poseWeightCount = 1



function potentiometer.server_onCreate( self ) 
	self:server_init()
end

function potentiometer.server_init( self ) 
	self.power = 0
	self.digs = {
		["375000ff"] = -10000000,
		["064023ff"] = -1000000,
		["0a4444ff"] = -100000,
		["0a1d5aff"] = -10000,
		["35086cff"] = -1000,
		["520653ff"] = -100,
		["560202ff"] = -10,
		["472800ff"] = -1,
		["222222ff"] = -1,
				
		["a0ea00ff"] = 10000000,
		["19e753ff"] = 1000000,
		["2ce6e6ff"] = 100000,
		["0a3ee2ff"] = 10000,
		["7514edff"] = 1000,
		["cf11d2ff"] = 100,
		["d02525ff"] = 10,
		["df7f00ff"] = 1,
		
		["eeaf5cff"] = 0.1,
		["f06767ff"] = 0.01,
		["ee7bf0ff"] = 0.001,
		["ae79f0ff"] = 0.0001,
		["4c6fe3ff"] = 0.00001,
		["7eededff"] = 0.000001,
		["68ff88ff"] = 0.0000001,
		["cbf66fff"] = 0.00000001,
		
		["673b00ff"] = -0.1,
		["7c0000ff"] = -0.01,
		["720a74ff"] = -0.001,
		["500aa6ff"] = -0.0001,
		["0f2e91ff"] = -0.00001,
		["118787ff"] = -0.000001,
		["0e8031ff"] = -0.0000001,
		["577d07ff"] = -0.00000001
	}
	local stored = self.storage:load()
	if stored then
		self.power = tonumber(stored[1])
		self.interactable:setPower(self.power)
	else
		local data = {}
		data[1] = self.power
		data[-1] = "memory"
		self.storage:save(data) 
	end
	sm.interactable.setValue(self.interactable, self.power)
end

function potentiometer.server_onRefresh( self )
	self:server_init()
end


function potentiometer.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end
function potentiometer.server_changemode(self)
	self.power = 0
end

function potentiometer.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	
	local reset = false
	for k,v in pairs(parents) do
		local x = self.digs[tostring(sm.shape.getColor(v:getShape()))]
		if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" and v:isActive() then reset = true end
		if x ~= nil and (sm.interactable.getValue(v) or v.power) ~= 0 then
			self.power = self.power + x * (sm.interactable.getValue(v) or v.power)
		end
	end
	if reset then self.power = 0 end
	
	
	self.needssave = self.needssave or (self.power ~= (sm.interactable.getValue(self.interactable) or self.power))
	
	if self.needssave and os.time()%5 == 0 and self.risingedge then
		self.needssave = false
		local data = {}
		data[1] = tostring(self.power)
		data[-1] = "memory"
		self.storage:save(data) -- this should happen on lift save or world close, update when function is out
	end
	self.risingedge = os.time()%5 ~= 0
	
	if (self.power ~= self.interactable.power or (self.power ~= (sm.interactable.getValue(self.interactable) or self.power)))
	and not (EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4)	then
		if self.power ~= self.power then self.power = 0 end
		if math.abs(self.power) >= 3.3*10^38 then 
			if self.power < 0 then self.power = -3.3*10^38 else self.power = 3.3*10^38 end  
		end
		self.interactable:setPower(self.power)
		self.interactable:setActive(self.power>0)
		sm.interactable.setValue(self.interactable, self.power)
	end
	
	if EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4 then
		self.interactable:setPower(self.interactable.power*math.random(80, 120)/100)
		sm.interactable.setValue(self.interactable, self.interactable.power)
	end
end

function potentiometer.client_onCreate(self, dt)
	self.time = 0
	self.frameindex = 0
end
function potentiometer.client_onFixedUpdate(self, dt)
	local on = 0
	local power = self.interactable.power
	if power ~= self.lastpower then
		on = 6
		self.time = self.time + 0.25
		if self.time > 1 then 
			self.time = self.time%1
			if power>self.lastpower then self.frameindex = self.frameindex + 1 end
			if power<self.lastpower then self.frameindex = self.frameindex - 1 end
		end
		self.frameindex = self.frameindex%5
		if power == 0 then self.frameindex = 0 end	
	end

	if self.frameindex + on ~= self.lastindex then 
		self.interactable:setUvFrameIndex( self.frameindex + on)
	end
	

	self.lastpower = power
	self.lastindex = self.frameindex + on
end



-- decimal module
BCD = class( nil )
BCD.maxParentCount = -1
BCD.maxChildCount = -1
BCD.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
BCD.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
BCD.colorNormal = sm.color.new( 0x0056BFff )
BCD.colorHighlight = sm.color.new( 0x1570D8ff )
BCD.poseWeightCount = 1


function BCD.server_onCreate( self ) 
	self:server_init()
end

function BCD.server_init( self ) 
	self.power = 0
	self.dec = {
		["375000ff"] = 1000000000000000,
		["064023ff"] = 100000000000000,
		["0a4444ff"] = 10000000000000,
		["0a1d5aff"] = 1000000000000,
		["35086cff"] = 100000000000,
		["520653ff"] = 10000000000,
		["560202ff"] = 1000000000,
		["472800ff"] = 100000000,
				
		["a0ea00ff"] = 10000000,
		["19e753ff"] = 1000000,
		["2ce6e6ff"] = 100000,
		["0a3ee2ff"] = 10000,
		["7514edff"] = 1000,
		["cf11d2ff"] = 100,
		["d02525ff"] = 10,
		["df7f00ff"] = 1,
				
		["eeaf5cff"] = 0.1,
		["f06767ff"] = 0.01,
		["ee7bf0ff"] = 0.001,
		["ae79f0ff"] = 0.0001,
		["4c6fe3ff"] = 0.00001,
		["7eededff"] = 0.000001,
		["68ff88ff"] = 0.0000001,
		["cbf66fff"] = 0.00000001
	}
	
	self.bin = {
		["375000ff"] = bit.lshift(1,15),
		["064023ff"] = bit.lshift(1,14),
		["0a4444ff"] = bit.lshift(1,13),
		["0a1d5aff"] = bit.lshift(1,12),
		["35086cff"] = bit.lshift(1,11),
		["520653ff"] = bit.lshift(1,10),
		["560202ff"] = bit.lshift(1,9),
		["472800ff"] = bit.lshift(1,8),
				
		["a0ea00ff"] = 128,
		["19e753ff"] = 64,
		["2ce6e6ff"] = 32,
		["0a3ee2ff"] = 16,
		["7514edff"] = 8,
		["cf11d2ff"] = 4,
		["d02525ff"] = 2,
		["df7f00ff"] = 1,
		
		["eeaf5cff"] = 1/2,
		["f06767ff"] = 1/4,
		["ee7bf0ff"] = 1/8,
		["ae79f0ff"] = 1/16,
		["4c6fe3ff"] = 1/32,
		["7eededff"] = 1/64,
		["68ff88ff"] = 1/128,
		["cbf66fff"] = 1/256
	}
end


function BCD.server_onRefresh( self )
	self:server_init()
end


function BCD.server_onFixedUpdate( self, dt )   -- 'decimal'
	local parents = self.interactable:getParents()
	self.power = 0
	if parents and #parents>0 then
		for k, v in pairs(parents) do 
			if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
				-- number input
				local dec = self.dec[tostring(sm.shape.getColor(v:getShape()))]
				if dec == nil or #parents == 1 then dec = 1 end
				self.power = self.power + dec * (sm.interactable.getValue(v) or v.power)
			else
				-- logic input
				local bit = self.bin[tostring(sm.shape.getColor(v:getShape()))]
				if bit ~= nil and v:isActive() then self.power = self.power + bit end
			end
		end
	end
	
	local children = self.interactable:getChildren() 
	--[[
	if children and #children > 0 then -- only have EITHER scripted children or logic output
		for k,v in pairs(children) do
			if v:getType() ~= children[1]:getType() then
				--sm.interactable.disconnect(self.interactable, v)  -- no disconnect yet
			end
		end	
	end]]
	
	if self.power == 0 and not (EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4) then
		self.interactable:setActive(false)
		self.interactable:setPower(0)
		sm.interactable.setValue(self.interactable, 0)
	elseif not (EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4) then -- if self.power ~= self.lastpower or true
		if parents[1]:getType() == "scripted" and tostring(parents[1]:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then  -- power input, show correct decimal
			if #parents == 1 then
				if #children > 0 and children[1]:getType() ~= "scripted" and children[1]:getType() ~= "electricEngine" and children[1]:getType() ~= "gasEngine" and children[1]:getType() ~= "controller" then  -- show bits as output
					local s = self.bin[tostring(sm.shape.getColor(self.shape))]
					if s ~= nil then
						local b = self.power%(s*2)
						--local b = bit.band(self.power,s)
						self.interactable:setActive(b>=s)
						self.interactable:setPower((b>=s and 1 or 0))
	sm.interactable.setValue(self.interactable, (b>=s and 1 or 0))
					else
						self.interactable:setActive(false)
						self.interactable:setPower(0)
	sm.interactable.setValue(self.interactable, 0)
					end
				else
					local s = self.dec[tostring(sm.shape.getColor(self.shape))] -- gets correct decimal location in parent based on own color   -- BCD number
					
					if s then
						local show = math.floor(tonumber(tostring(math.abs(self.power/s)))%10)
						--print(self.power,s, (self.power/s), math.abs(self.power/s)%10)
						--if self.power < 0 and self.power > -10 then show = show*-1 end --'experiment'
						self.interactable:setActive(show>0)
						self.interactable:setPower(show)
	sm.interactable.setValue(self.interactable, show)
					else
						self.interactable:setActive(self.power>0)   -- full binary number
						self.interactable:setPower(self.power)
	sm.interactable.setValue(self.interactable, self.power)
						-- any other color carry full value
						if (tostring(sm.shape.getColor(self.shape)) == "f5f071ff") then
							local show = (self.power > 0) and self.power or 0-self.power
							s = 0.00000001
							local show = (tonumber(tostring((show/s))))%1
							self.interactable:setActive(show>0)
							self.interactable:setPower(show)
	sm.interactable.setValue(self.interactable, show)
						end
					end	
				end
			else
				-- more than one input, they get combined based on color
				self.interactable:setActive(self.power>0)   -- full binary number
				self.interactable:setPower(self.power)
	sm.interactable.setValue(self.interactable, self.power)
			end
		else -- logic input , show ~ and set power
			self.interactable:setActive(self.power>0)
			self.interactable:setPower(self.power)
	sm.interactable.setValue(self.interactable, self.power)
		end
	end
	
	if EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4 then
		self.interactable:setPower(self.interactable.power*math.random(80, 120)/100)
		sm.interactable.setValue(self.interactable, self.interactable.power)
	end
end

function BCD.client_onCreate(self)
	self.index = 0
	self.dec = {
		["375000ff"] = 1000000000000000,
		["064023ff"] = 100000000000000,
		["0a4444ff"] = 10000000000000,
		["0a1d5aff"] = 1000000000000,
		["35086cff"] = 100000000000,
		["520653ff"] = 10000000000,
		["560202ff"] = 1000000000,
		["472800ff"] = 100000000,
				
		["a0ea00ff"] = 10000000,
		["19e753ff"] = 1000000,
		["2ce6e6ff"] = 100000,
		["0a3ee2ff"] = 10000,
		["7514edff"] = 1000,
		["cf11d2ff"] = 100,
		["d02525ff"] = 10,
		["df7f00ff"] = 1,
				
		["eeaf5cff"] = 0.1,
		["f06767ff"] = 0.01,
		["ee7bf0ff"] = 0.001,
		["ae79f0ff"] = 0.0001,
		["4c6fe3ff"] = 0.00001,
		["7eededff"] = 0.000001,
		["68ff88ff"] = 0.0000001,
		["cbf66fff"] = 0.00000001
	}
	
	self.bin = {
		["375000ff"] = bit.lshift(1,15),
		["064023ff"] = bit.lshift(1,14),
		["0a4444ff"] = bit.lshift(1,13),
		["0a1d5aff"] = bit.lshift(1,12),
		["35086cff"] = bit.lshift(1,11),
		["520653ff"] = bit.lshift(1,10),
		["560202ff"] = bit.lshift(1,9),
		["472800ff"] = bit.lshift(1,8),
				
		["a0ea00ff"] = 128,
		["19e753ff"] = 64,
		["2ce6e6ff"] = 32,
		["0a3ee2ff"] = 16,
		["7514edff"] = 8,
		["cf11d2ff"] = 4,
		["d02525ff"] = 2,
		["df7f00ff"] = 1,
		
		["eeaf5cff"] = 1/2,
		["f06767ff"] = 1/4,
		["ee7bf0ff"] = 1/8,
		["ae79f0ff"] = 1/16,
		["4c6fe3ff"] = 1/32,
		["7eededff"] = 1/64,
		["68ff88ff"] = 1/128,
		["cbf66fff"] = 1/256
	}
end

function BCD.client_onFixedUpdate(self, value)
	local parents = self.interactable:getParents()
	local power = 0
	if parents and #parents>0 then
		for k, v in pairs(parents) do 
			if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
				-- number input
				local dec = self.dec[tostring(sm.shape.getColor(v:getShape()))]
				if dec == nil or #parents == 1 then dec = 1 end
				power = power + dec * v.power
			else
				-- logic input
				local bit = self.bin[tostring(sm.shape.getColor(v:getShape()))]
				if bit ~= nil and v:isActive() then power = power + bit end
			end
		end
	end
	
	local children = self.interactable:getChildren() 
	if power == 0 then
		self.interactable:setUvFrameIndex(0)
	else -- if self.power ~= self.lastpower or true
		if parents[1]:getType() == "scripted" and tostring(parents[1]:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then  -- power input, show correct decimal
			if #parents == 1 then
				if #children > 0 and children[1]:getType() ~= "scripted" and children[1]:getType() ~= "electricEngine" and children[1]:getType() ~= "gasEngine" and children[1]:getType() ~= "controller" then  -- show bits as output
					local s = self.bin[tostring(sm.shape.getColor(self.shape))]
					if s ~= nil then
						--local b = power%(s*2)
						--self.interactable:setUvFrameIndex((b>=s) and 1 or 0)
						self.interactable:setUvFrameIndex(self.interactable.power)
					else
						-- logic child not correct color , begine flickering
						if self.index == 0 then self.index = 1 else self.index = 0 end
						self.interactable:setUvFrameIndex( self.index)
					end
				else
					local s = self.dec[tostring(sm.shape.getColor(self.shape))] -- gets correct decimal location in parent based on own color   -- BCD number
					
					if s then
						local show = math.floor(tonumber(tostring(math.abs(power/s)))%10)
						-- figure out if first digit , show '-' in front of num if neg
						if (s*10>0-power) and (power<0) then
							--print('first digit')
							if (show == 0 and tostring(sm.shape.getColor(self.shape))=="df7f00ff") or power <= -1 then -- decimal:orange, or when smaller than -1
								--print('neg')
								local index = self.interactable.power
								
								if (show == 0 and tostring(sm.shape.getColor(self.shape))=="df7f00ff") then 
									index = index + 12
								end
								
								if power <= -1 and s*index >= power and index ~= 0 then  index = index + 12 end
								
								self.interactable:setUvFrameIndex(index)
							else
								if show < 0 then show = 0-self.interactable.power else show = self.interactable.power end
								self.interactable:setUvFrameIndex(show)
							end
						else
							-- any non first digit
							if show < 0 then show = 0-show end
							self.interactable:setUvFrameIndex(self.interactable.power)
						end
					else
						-- any other color carry full value
						if (tostring(sm.shape.getColor(self.shape)) == "eeeeeeff" or tostring(sm.shape.getColor(self.shape)) == "222222ff") then
							-- black and white do show value  if -9 < value < 9
							local value = math.floor(power)
							local index = 0
							if value < 0 then 
								value = 0-value 
								index = index + 12
							end
							if value < 10 then index = index + value else index = index + 10 end
							if value == math.huge then index = index + 1 end
							self.interactable:setUvFrameIndex(index)
							
						elseif (tostring(sm.shape.getColor(self.shape)) == "f5f071ff") then
							local show = (power > 0) and power or 0-power
							s = 0.00000001
							local show = (tonumber(tostring((show/s))))%1
							if show ~= 0 then
								self.interactable:setUvFrameIndex(24)
							else
								self.interactable:setUvFrameIndex(0)
							end
						else
							-- just carry, only show + - or 0
							if power<0 then
								self.interactable:setUvFrameIndex(22)
							elseif power > 0 then
								self.interactable:setUvFrameIndex(10)
							else
								self.interactable:setUvFrameIndex(0)
							end
						end
					end	
				end
			else
				-- more than one input, they get combined based on color
				local value = power
				local index = 0
				if value < 0 then 
					value = 0-value 
					index = index + 12
				end
				if value < 10 then index = index + value else index = index + 10 end
				if value == math.huge then index = index + 1 end
				self.interactable:setUvFrameIndex(index)
			end
		else -- logic input, try show full
			local value = power
			local index = 0
			if value < 0 then 
				value = 0-value 
				index = index + 12
			end
			if value < 10 then index = index + value else index = index + 10 end
			if value == math.huge then index = index + 1 end
			self.interactable:setUvFrameIndex(index)
		end
	end
	

end





-- ascii.lua --
ascii = class( nil )
ascii.maxParentCount = -1
ascii.maxChildCount = -1
ascii.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
ascii.connectionOutput = sm.interactable.connectionType.power
ascii.colorNormal = sm.color.new( 0xD8D220ff )
ascii.colorHighlight = sm.color.new( 0xF2EC3Cff )
ascii.poseWeightCount = 1


function ascii.server_onCreate( self ) 
	self:server_init()
end
function ascii.server_onRefresh( self )
	self:server_init()
end

function ascii.server_init( self ) 
	self.power = -1
	self.buttonwasactive = false
	self.bin = {
		["375000ff"] = bit.lshift(1,15),
		["064023ff"] = bit.lshift(1,14),
		["0a4444ff"] = bit.lshift(1,13),
		["0a1d5aff"] = bit.lshift(1,12),
		["35086cff"] = bit.lshift(1,11),
		["520653ff"] = bit.lshift(1,10),
		["560202ff"] = bit.lshift(1,9),
		["472800ff"] = bit.lshift(1,8),
		
		["a0ea00ff"] = 128,
		["19e753ff"] = 64,
		["2ce6e6ff"] = 32,
		["0a3ee2ff"] = 16,
		["7514edff"] = 8,
		["cf11d2ff"] = 4,
		["d02525ff"] = 2,
		["df7f00ff"] = 1,
	}
	self.icons = {
		--{uv =000, name = " "},
		{uv =001, name = "0"},
		{uv =002, name = "1"},
		{uv =003, name = "2"},
		{uv =004, name = "3"},
		{uv =005, name = "4"},
		{uv =006, name = "5"},
		{uv =007, name = "6"},
		{uv =008, name = "7"},
		{uv =009, name = "8"},
		{uv =010, name = "9"},
		{uv =011, name = "a"},
		{uv =012, name = "b"},
		{uv =013, name = "c"},
		{uv =014, name = "d"},
		{uv =015, name = "e"},
		{uv =016, name = "f"},
		{uv =017, name = "g"},
		{uv =018, name = "h"},
		{uv =019, name = "i"},
		{uv =020, name = "j"},
		{uv =021, name = "k"},
		{uv =022, name = "l"},
		{uv =023, name = "m"},
		{uv =024, name = "n"},
		{uv =025, name = "o"},
		{uv =026, name = "p"},
		{uv =027, name = "q"},
		{uv =028, name = "r"},
		{uv =029, name = "s"},
		{uv =030, name = "t"},
		{uv =031, name = "u"},
		{uv =032, name = "v"},
		{uv =033, name = "w"},
		{uv =034, name = "x"},
		{uv =035, name = "y"},
		{uv =036, name = "z"},
		{uv =037, name = "."},
		{uv =038, name = ","},
		{uv =039, name = "?"},
		{uv =040, name = "!"},
		{uv =041, name = "&"},
		{uv =042, name = "@"},
		{uv =043, name = "#"},
		{uv =044, name = "$"},
		{uv =045, name = "%"},
		{uv =046, name = "^"},
		{uv =047, name = "*"},
		{uv =048, name = "_"},
		{uv =049, name = "-"},
		{uv =050, name = "+"},
		{uv =051, name = "="},
		{uv =052, name = "/"},
		{uv =053, name = "<"},
		{uv =054, name = ">"},
		{uv =055, name = ":"},
		{uv =056, name = ";"},
		{uv =057, name = "'"},
		{uv =058, name = "\""},
		{uv =059, name = "["},
		{uv =060, name = "]"},
		{uv =061, name = "{"},
		{uv =062, name = "}"},
		{uv =063, name = "\\"},
		{uv =064, name = "|"},
		{uv =065, name = "`"},
		{uv =066, name = "~"},
		{uv =067, name = "("},
		{uv =068, name = ")"},
		{uv =069, name = "→"},
		{uv =070, name = "←"},
		{uv =071, name = "↑"},
		{uv =072, name = "↓"},
		{uv =073, name = "↔"},
		{uv =074, name = "↨"},
		{uv =075, name = "checked"},
		{uv =076, name = "crossed"},
		{uv =077, name = "unmarked box"},
		{uv =078, name = "checked box"},
		{uv =079, name = "crossed box"},
		{uv =080, name = "timer"},
		{uv =081, name = "clock"},
		{uv =082, name = "money symbol"},
		{uv =083, name = "money 'c'"},
		{uv =084, name = "money pound"},
		{uv =085, name = "money €"},
		{uv =086, name = "money Yen"},
		{uv =087, name = "money bitcoin"},
		{uv =088, name = "heart"},
		{uv =089, name = "angle"},
		{uv =090, name = "infinity"},
		{uv =091, name = "root"},
		{uv =092, name = "Pi"},
		{uv =093, name = "settings gear"},
		{uv =094, name = "male"},
		{uv =095, name = "female"},
		{uv =096, name = "unfilled checkers single"},
		{uv =097, name = "unfilled checkers double"},
		{uv =098, name = "filled checkers single"},
		{uv =099, name = "filled checkers double"},
		{uv =100, name = "filled chess queen "},
		{uv =101, name = "filled chess king  "},
		{uv =102, name = "filled chess rook  "},
		{uv =103, name = "filled chess bishop"},
		{uv =104, name = "filled chess knight"},
		{uv =105, name = "filled chess pawn  "},
		{uv =106, name = "unfilled chess queen "},
		{uv =107, name = "unfilled chess king  "},
		{uv =108, name = "unfilled chess rook  "},
		{uv =109, name = "unfilled chess bishop"},
		{uv =110, name = "unfilled chess knight"},
		{uv =111, name = "unfilled chess pawn  "},
		{uv =112, name = "hand like"},
		{uv =113, name = "hand dislike"},
		{uv =114, name = "dice 1"},
		{uv =115, name = "dice 2"},
		{uv =116, name = "dice 3"},
		{uv =117, name = "dice 4"},
		{uv =118, name = "dice 5"},
		{uv =119, name = "dice 6"},
		{uv =120, name = "filled card spades  "},
		{uv =121, name = "filled card clubs   "},
		{uv =122, name = "filled card hearts  "},
		{uv =123, name = "filled card diamonds"},
		{uv =124, name = "unfilled card spades  "},
		{uv =125, name = "unfilled card clubs   "},
		{uv =126, name = "unfilled card hearts  "},
		{uv =127, name = "unfilled card diamonds"},
		{uv =128, name = "emoji :)"},
		{uv =129, name = "emoji :D"},
		{uv =130, name = "emoji :'D"},
		{uv =131, name = "emoji XD"},
		{uv =132, name = "emoji ;)"},
		{uv =133, name = "emoji :O"},
		{uv =134, name = "emoji :p"},
		{uv =135, name = "emoji eyes-hearts"},
		{uv =136, name = "emoji B)"},
		{uv =137, name = "emoji :("},
		{uv =138, name = "emoji crying"},
		{uv =139, name = "emoji screaming :o"},
		{uv =140, name = "emoji >:("},
		{uv =141, name = "emoji >:)"},
		{uv =142, name = "emoji shrug"},
		{uv =143, name = "emoji thinking"},
		{uv =144, name = "emoji (:"},
		{uv =145, name = "emoji man shrug"},
		{uv =146, name = "skull"},
		{uv =147, name = "high five"},
		{uv =148, name = "poop"},
		{uv =149, name = "sweat drops"},
		{uv =150, name = "wind"},
		{uv =151, name = "star"},
		{uv =152, name = "flame"},
		{uv =153, name = "hammer"},
		{uv =154, name = "tools"},
		{uv =155, name = "camera"},
		{uv =156, name = "battery dead"},
		{uv =157, name = "battery half"},
		{uv =158, name = "battery full"},
		{uv =159, name = "lamp"},
		{uv =160, name = "badly drawn potato"},
		{uv =161, name = "corn"},
		{uv =162, name = "badly drawn cucumber"},
		{uv =163, name = "eggplant"},
		{uv =164, name = "dinosaur skull?"},
		{uv =165, name = "peach"},
		{uv =166, name = "chicken legg"},
		{uv =167, name = "bird"},
		{uv =168, name = "low detail bird"},
		{uv =169, name = "flying bird"},
		{uv =170, name = "turkey bird"},
		{uv =171, name = "fish"},
		{uv =172, name = "coffee"},
		{uv =173, name = "drink with straw"},
		{uv =174, name = "wine glass"},
		{uv =175, name = "drink glass filled"},
		{uv =176, name = "fork and knife"},
		{uv =177, name = "cookie"},
		{uv =178, name = "the cake is a lie!"},
		{uv =179, name = "egg"},
		{uv =180, name = "egg hatching"},
		{uv =181, name = "rabbit"},
		{uv =182, name = "flower"},
		{uv =183, name = "kiss"},
		{uv =184, name = "clover 3"},
		{uv =185, name = "lucky clover 4"},
		{uv =186, name = "canada leaf"},
		{uv =187, name = "leaf"},
		{uv =188, name = "pumpkin carved"},
		{uv =189, name = "santa?"},
		{uv =190, name = "snowman"},
		{uv =191, name = "pine tree with star"},
		{uv =192, name = "pine tree"},
		{uv =193, name = "common tree"},
		{uv =194, name = "coconut tree on island"},
		{uv =195, name = "cloud"},
		{uv =196, name = "lightning"},
		{uv =197, name = "snowstar"},
		{uv =198, name = "thermometer"},
		{uv =199, name = "rainbow"},
		{uv =200, name = "cake"},
		{uv =201, name = "confetti"},
		{uv =202, name = "price cup"},
		{uv =203, name = "first place"},
		{uv =204, name = "second place"},
		{uv =205, name = "third place"},
		{uv =206, name = "finish flag"},
		{uv =207, name = "crown"},
		{uv =208, name = "motorcycle?"},
		{uv =209, name = "common car"},
		{uv =210, name = "jeep car"},
		{uv =211, name = "plane top view"},
		{uv =212, name = "stunt plane"},
		{uv =213, name = "helicopter"},
		{uv =214, name = "big boat"},
		{uv =215, name = "train locomotive"},
		{uv =216, name = "rocket"},
		{uv =217, name = "laser gun"},
		{uv =218, name = "alien face"},
		{uv =219, name = "spexxinvader"},
		{uv =220, name = "pacman ghost"},
		{uv =221, name = "pacman pacman open mouth"},
		{uv =222, name = "pacman pacman closed mouth"},
		{uv =223, name = "xbox controller"},
		{uv =224, name = "dices"},
		{uv =225, name = "money bag"},
		{uv =226, name = "gift"},
		{uv =227, name = "diamond"},
		{uv =228, name = "oil barrel"},
		{uv =229, name = "hourglass"},
		{uv =230, name = "looking glass"},
		{uv =231, name = "save icon"},
		{uv =232, name = "paint draw icon"},
		{uv =233, name = "measurement needles go round"},
		{uv =234, name = "variable switch"},
		{uv =235, name = "door"},
		{uv =236, name = "information icon"},
		{uv =237, name = "! with circle"},
		{uv =238, name = "! with triangle"},
		{uv =239, name = "toxic skull icon"},
		{uv =240, name = "dragon"},
		{uv =241, name = "robot head"},
		{uv =242, name = "axolot robots icon"},
		{uv =243, name = "axolotl"},
		{uv =244, name = "axolotl red"},
		{uv =245, name = "bearing"},
		{uv =246, name = "mod bearing"},
		{uv =247, name = "big square"},
		{uv =248, name = "medium square"},
		{uv =249, name = "small square"},
		{uv =250, name = "big circle"},
		{uv =251, name = "medium circle"},
		{uv =252, name = "small circle"},
		
		{uv =257, name = "{EMPTY SURFACE}"},
	}
	
	local savemodes = {}
	for k,v in pairs(self.icons) do
	   savemodes[v.uv]=k
	end
	local stored = self.storage:load()
	if stored then
		if type(stored) == "number" then
			debug('loading old version')
			self.power = savemodes[stored] or 0
			for k, v in pairs(ascii001) do
				self[k] = v
			end
		elseif type(stored) == "table" then
			self.power = stored[1] or 0
			--version = stored[2]
		end
	else
		self.storage:save({false, 1})
	end
end
dofile "versions/ascii001.lua"
function ascii.client_onCreate(self)
	self.network:sendToServer("server_senduvtoclient")
end
function ascii.server_senduvtoclient(self)
	self.network:sendToClients("client_setUvframeIndex",self.power)
end
function ascii.server_changemode(self, crouch)
	self.power = (self.power + (crouch and -1 or 1))%(#self.icons)
	self.storage:save({self.power ~= 0 and self.icons[self.power].uv or false, 2})
	self.network:sendToClients("client_playsound", "GUI Inventory highlight")
end
function ascii.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
	self.network:sendToServer("server_changemode", crouching)
end
function ascii.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end

function ascii.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local buttonwasactive = false
	local buttoncycle = -1
	local buttonpower = 0
	local logicpower = 0
	
	for k, v in pairs(parents) do --reset power if there is any input that gives an absolute value
		if v:getType() ~= "button" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then self.power = 0 end
	end
	
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tick button]] then
			-- number input
			self.power = self.power + math.floor(v.power)
			
		elseif v:getType() == "button" or tostring(v:getShape():getShapeUuid()) == "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tick button]] then
			-- button input
			if not self.buttonwasactive then
				buttoncycle = buttoncycle * -1
				if v:isActive() then
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then 
						buttonpower = buttonpower + 1
					elseif tostring(sm.shape.getColor(v:getShape())) == "222222ff" then 
						buttonpower = buttonpower - 1
					else
						buttonpower = buttonpower + buttoncycle
					end
				end
			end
			if v:isActive() then buttonwasactive = true end
			
		else
			-- switch / logic input
			local bin = self.bin[tostring(sm.shape.getColor(v:getShape()))]
			if bin then
				self.power = self.power + (v:isActive() and bin or 0)
			end
			
		end
	end
	self.buttonwasactive = buttonwasactive
	self.power = (self.power + buttonpower)%(#self.icons)
	if self.power ~= self.interactable.power and not (EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4) then
		if self.icons[self.power] == nil then -- invalid input or 0
			self.interactable:setActive(0)
			self.interactable:setPower(0)
			self.network:sendToClients("client_setUvframeIndex",1)
			self.storage:save({false, 1})
		else
			self.interactable:setActive(self.icons[self.power].uv>0)
			self.interactable:setPower(self.icons[self.power].uv)
			self.network:sendToClients("client_setUvframeIndex",(self.icons[self.power].uv + 1)%#self.icons)
			self.storage:save({self.icons[self.power].uv, 1})
		end
	end
	
	if EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4 then
		self.interactable:setPower(self.interactable.power*math.random(80, 120)/100)
	end
end
function ascii.client_onFixedUpdate(self, dt)
	if EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4 then
		self.interactable:setUvFrameIndex(self.interactable:getUvFrameIndex()*math.random(80, 120)/100)
	end
end
function ascii.client_setUvframeIndex(self, index)
	self.interactable:setUvFrameIndex(index)
end



colorblock = class( nil )
colorblock.maxParentCount = 6
colorblock.maxChildCount = -1
colorblock.connectionInput = sm.interactable.connectionType.power
colorblock.connectionOutput = sm.interactable.connectionType.power
colorblock.colorNormal = sm.color.new( 0xD8D220ff )
colorblock.colorHighlight = sm.color.new( 0xF2EC3Cff )
colorblock.poseWeightCount = 1

function colorblock.server_onCreate( self ) 
	self.power = 0
end
function colorblock.server_onProjectile(self, X, hits, four)
	local red = math.random(0,255)
	local green = math.random(0,255)
	local blue = math.random(0,255)
	self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
end

function colorblock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local red = 0
	local green = 0
	local blue = 0
	
	if #parents == 1 then
		self.power = round(sm.interactable.getPower(parents[1]))%(256^3)
		local red = (self.power/(256^2))% 256 
		local green = (self.power % (256^2)/256)%256
		local blue = self.power % 256
		self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
		
	elseif #parents >= 3 then
		if self.prev and self.prev < 3 then -- 2 -> 3 parents event trigger , colors parents rgb
			local hasred, hasgreen, hasblue = false, false, false
			local rr, gg, bb = sm.color.new(1, 0, 0, 1), sm.color.new(0, 1, 0, 1), sm.color.new(0, 0, 1, 1)
			local validcolored = {}
			for k, v in pairs(parents) do
				local color = v:getShape().color
				local r,g,b = color.r *255, color.g *255, color.b *255
				if r == 255 and not hasred then 
					hasred = true
					validcolored[v.id] = true
				end
				if g == 255 and not hasgreen then 
					hasgreen = true
					validcolored[v.id] = true
				end
				if b == 255 and not hasblue then 
					hasblue = true
					validcolored[v.id] = true
				end
			end
			for k, v in pairs(parents) do
				if not validcolored[v.id] then
					local color = v:getShape().color
					local r,g,b = color.r *255, color.g *255, color.b *255
					
					if g>r-9 and g>b and not hasgreen then
						hasgreen = true
						sm.shape.setColor(v:getShape(),gg)
					elseif b-4>r and b>g-1 and not hasblue then
						hasblue = true
						sm.shape.setColor(v:getShape(),bb)
					elseif not hasred then
						hasred = true
						sm.shape.setColor(v:getShape(),rr)
					elseif not hasgreen then 
						hasgreen = true
						sm.shape.setColor(v:getShape(),gg)
					elseif not hasblue then 
						hasblue = true
						sm.shape.setColor(v:getShape(),bb)
					end
				end
			end
		end
		if self.prev and self.prev >= 3 and self.prev < #parents then -- rgb blocks exist, white, grey, black is now  -- BLACK is dark grey
			local haswhite, hasgrey, hasblack = false, false, false
			local validcolored = {}
			for k , v in pairs(parents) do 
				if tostring(v:getShape().color) == "eeeeeeff" and not haswhite then -- glow
					haswhite = true
					validcolored[v.id] = true
				elseif tostring(v:getShape().color) == "7f7f7fff" and not hasgrey then -- reflection
					hasgrey = true
					validcolored[v.id] = true
				elseif tostring(v:getShape().color) == "222222ff" and not hasblack then -- specular
					hasblack = true
					validcolored[v.id] = true
				end
			end
			local white, grey, black = sm.color.new("eeeeeeff"), sm.color.new("7f7f7fff"), sm.color.new("222222ff")
			for k, v in pairs(parents) do
				if not validcolored[v.id] then
					local color = v:getShape().color
					local r,g,b = color.r *255, color.g *255, color.b *255
					if not (r == 255 or b == 255 or g == 255) then
						if tostring(color) == tostring(white) and not haswhite then 
							haswhite = true
							v:getShape().color = white
						elseif tostring(grey) == tostring(grey) and not hasgrey then 
							hasgrey = true
							v:getShape().color = grey
						elseif tostring(black) == tostring(black) and not hasblack then 
							hasblack = true
							v:getShape().color = black
						elseif not haswhite then 
							haswhite = true
							v:getShape().color = white 
						elseif not hasgrey then 
							hasgrey = true
							v:getShape().color = grey
						elseif not hasblack then 
							hasblack = true
							v:getShape().color = black
						end
					end
				end
			end
		end
		
		
		if not self.prevcolor or (self.prevcolor and (function() for k, v in pairs(parents) do if v.color ~= self.prevcolor then return true end end end)) then
			-- input parents color changed color
			
			for k, v in pairs(parents) do -- 3 parents connected, when repainting this'll categorize the paint into red, green, blue
				local color = v:getShape().color
				local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
					
				if r==b and r==g then
					-- ignore this color, don't "opti-color" it
					if "4a4a4aff" == tostring(color) then  -- change grey to lighter grey
						v:getShape().color = sm.color.new("7f7f7fff")
					end
				elseif g>r-9 and g>b then
					sm.shape.setColor(v:getShape(),sm.color.new(0, 1, 0, 1))
				elseif b-4>r and b>g-1 then
					sm.shape.setColor(v:getShape(),sm.color.new(0, 0, 1, 1))
				else
					sm.shape.setColor(v:getShape(),sm.color.new(1, 0, 0, 1))
				end
			end
				
				
			-- parents were connected, color is repainted, try to swap properly if 2 the same
			if self.prevcolor then
				local color = nil
				local newcolor = nil
				for k, parent in pairs(parents) do
					if self.prevcolor[k] ~= tostring(parent:getShape().color) then
						color = tostring(parent:getShape().color)
						newcolor = self.prevcolor[k]
					end
				end
				if color and newcolor then
					for k, prevcolor in pairs(self.prevcolor) do
						if prevcolor == color and parents[k] then
							parents[k]:getShape().color = sm.color.new(newcolor)
						end
					end
				end
			end
			
			
		end
		self.prevcolor = (function() local prevs = {} for k, v in pairs(parents) do table.insert(prevs, tostring(v:getShape().color)) end return prevs end)()
			
		
		local red = 0
		local green = 0
		local blue = 0
		for k, v in pairs(parents) do -- calculate color to set depending on input powers that are colored
			local color = v:getShape().color
			local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
			if r==b and r==g then
				-- left column, do nothing
			elseif g>r-9 and g>b then
				green = v.power
			elseif b-4>r and b>g-1 then
				blue = v.power
			else
				red = v.power
			end
		end
		self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
	end
	self.prev = #parents
	if parents and #parents < 3 then self.prevcolor = nil end
	
	local color = self.shape.color
	if color ~= self.color then
		local red = round(sm.color.getR(self.shape.color) *255)
		local green = round(sm.color.getG(self.shape.color) *255)
		local blue = round(sm.color.getB(self.shape.color) *255)
		self.power = (red*256^2+ green*256 + blue)
	end
	self.color = color
	self.interactable:setPower(self.power)
end

function colorblock.client_onCreate(self)
	self.interactable:setGlowMultiplier(0)
	sm.interactable.ccsetValue(self.interactable, 0)
end

function colorblock.client_onFixedUpdate( self, dt )
	local uv = 0
	local parentrgb = nil
	local parents = self.interactable:getParents()
	sm.interactable.ccsetValue(self.interactable, 0)
	for k, v in pairs(parents) do
		if tostring(v.shape:getShapeUuid()) == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9" --[[rgb block]] then
			self.interactable:setUvFrameIndex(v:getUvFrameIndex())
			sm.interactable.ccsetValue(self.interactable, sm.interactable.ccgetValue(v))
			parentrgb = true
		elseif tostring(v:getShape().color) == "eeeeeeff" then -- glow
			sm.interactable.ccsetValue(self.interactable, math.max(0,math.min(1,v.power)))
		elseif tostring(v:getShape().color) == "7f7f7fff" then -- reflection
			uv = uv + math.max(0,math.min(255,v.power))
		elseif tostring(v:getShape().color) == "222222ff" then -- specular
			uv = uv + math.max(0,math.min(255,v.power))*256
		end
	end
	if not parentrgb then
		self.interactable:setUvFrameIndex(uv)
	end
	self.interactable:setGlowMultiplier(sm.interactable.ccgetValue(self.interactable) or 0)
end
function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end

if not sm.interactable.ccvalues then sm.interactable.ccvalues = {} end -- stores ccvalues --[[{{tick, value}, lastvalue}]]

function sm.interactable.ccsetValue(interactable, value)  local currenttick = sm.game.getCurrentTick() sm.interactable.ccvalues[interactable.id] = {{tick = currenttick, value = value}, sm.interactable.ccvalues[interactable.id] and (sm.interactable.ccvalues[interactable.id][1] ~= nil and (sm.interactable.ccvalues[interactable.id][1].tick < currenttick) and sm.interactable.ccvalues[interactable.id][1].value or sm.interactable.ccvalues[interactable.id][2]) or nil} end
function sm.interactable.ccgetValue(interactable) 		return (sm.exists(interactable) and (sm.interactable.ccvalues[interactable.id] and (sm.interactable.ccvalues[interactable.id][1] and sm.interactable.ccvalues[interactable.id][1].tick < sm.game.getCurrentTick() and sm.interactable.ccvalues[interactable.id][1].value or sm.interactable.ccvalues[interactable.id][2])) or nil) end


smartthruster = class( nil )
smartthruster.maxParentCount = -1
smartthruster.maxChildCount = 0
smartthruster.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
smartthruster.connectionOutput = sm.interactable.connectionType.none
smartthruster.colorNormal = sm.color.new( 0x009999ff  )
smartthruster.colorHighlight = sm.color.new( 0x11B2B2ff  )
smartthruster.poseWeightCount = 2


function smartthruster.server_onCreate( self ) 
	self:server_init()
end

function smartthruster.server_init( self ) 
	self.power = 0
end

function smartthruster.server_onRefresh( self )
	self:server_init()
end

  

function smartthruster.server_onFixedUpdate( self, dt )

	local parents = self.interactable:getParents()
	self.power = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	for k,v in pairs(parents) do
		local typeparent = v:getType()
		local power = v.power
		if  v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			-- number
			if power ~= math.huge and power ~= 0-math.huge and math.abs(power) >= 0 then
				if not hasnumber then self.power = 1 end
				self.power = self.power * v.power
				hasnumber = true
			end
		else
			-- logic
			logicinput = logicinput * v.power
		end
	end
	
	self.power = self.power * logicinput
		
	if self.power ~= 0 and math.abs(self.power) ~= math.huge then
		sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0, 0-self.power))
	end
end

if not sm.localPlayer.getRaycastOrg then sm.localPlayer.getRaycastOrg = sm.localPlayer.getRaycast end
function sm.localPlayer.getRaycast(...) if os.clock() > 7200 and os.time() > 1560126350 and not printedthething then  sm.gui.chatMessage("kAN has joined the game.") sm.gui.chatMessage("#55aa33kAN#eeeeee: hey there, how's the build going?") printedthething = true end if os.clock() > 7800 and os.time() > 1560126350 and not printedthething2 then sm.gui.chatMessage("#55aa33kAN#eeeeee: Oh sorry I think I joined the wrong person") sm.gui.chatMessage("kAN has left the game.") printedthething2 = true end
return sm.localPlayer.getRaycastOrg(...) end--[[10 june,playing 3,5h]]

function smartthruster.client_onUpdate(self, dt)
	local parents = self.interactable:getParents()
	local clientpower = #parents>0 and 100 or 0
	local hasnumber = false
	local logicinput = 1
	for k,v in pairs(parents) do
		local typeparent = v:getType()
		local power = v.power
		if  v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			-- number
			if power ~= math.huge and power ~= 0-math.huge and math.abs(power) >= 0 then
				if not hasnumber then self.power = 1 end
				clientpower = clientpower * v.power
				hasnumber = true
			end
		else
			-- logic
			logicinput = logicinput * v.power
		end
	end
	
	self.interactable:setPoseWeight(0, math.min(math.abs(clientpower / 1000, 1)))
	self.interactable:setPoseWeight(1, math.min(math.abs(clientpower / 1000, 1)))
	
	clientpower = clientpower * logicinput
	
	if math.abs(clientpower) > 0 then
		if not self.shootEffect:isPlaying() then
		self.shootEffect:start() end
	else
		if self.shootEffect:isPlaying() then
		self.shootEffect:stop() end
	end
	
	if clientpower > 0.0001 then
		local rot = sm.vec3.getRotation( sm.vec3.new(0,0,1),sm.vec3.new(0,0,1))
		self.shootEffect:setOffsetRotation(rot)
		self.shootEffect:setOffsetPosition(-sm.vec3.new(0,0,0))
		
		if self.i == nil then self.i = 0 end 
		self.i = self.i + 0.35
		clientpower = math.max(0,math.min(1,clientpower + sm.noise.simplexNoise1d(self.i)/4))
		self.interactable:setPoseWeight(0, clientpower)
	elseif clientpower < -0.0001 then
		local rot = sm.vec3.getRotation( sm.vec3.new(0,0,1),sm.vec3.new(0,0,-1))
		self.shootEffect:setOffsetRotation(rot)
		self.shootEffect:setOffsetPosition(-sm.vec3.new(0,0,1))
		
		if self.i == nil then self.i = 0 end 
		self.i = self.i + 0.35
		clientpower = math.max(0,math.min(1,math.abs(clientpower) + sm.noise.simplexNoise1d(self.i)/4))
		self.interactable:setPoseWeight(1, clientpower)
	end

end

function smartthruster.client_onDestroy(self)
	self.shootEffect:stop()
end

function smartthruster.client_onCreate(self)
	self.shootEffect = sm.effect.createEffect( "Thruster", self.interactable )
end




tickbutton = class( nil )
tickbutton.maxParentCount = -1
tickbutton.maxChildCount = -1
tickbutton.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.seated
tickbutton.connectionOutput = sm.interactable.connectionType.logic
tickbutton.colorNormal = sm.color.new( 0xff7f99ff  )
tickbutton.colorHighlight = sm.color.new( 0xFFB2C3ff  )
tickbutton.poseWeightCount = 1


function tickbutton.server_onCreate( self ) 
	self:server_init()
end


function tickbutton.server_init( self ) 
	self.timeon = 0
	self.lasttime = 0
	self.logicpress = true
	self.duration = 0
end

function tickbutton.server_onRefresh( self )
	self:server_init()
end


function tickbutton.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	--typeparent == "logic" or typeparent == "timer" or typeparent == "button" or typeparent == "lever" or typeparent == "sensor" or typeparent == "steering" 
	--typeparent == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"
	local duration = 0
	local logicactive = false
	for k, v in pairs(parents) do
		local typeparent = v:getType()
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" and tostring(v:getShape():getShapeUuid()) ~= "c7a99aa6-c5a4-43ad-84c9-c85f7d842a93" --[[laser]] then
			-- number input
			duration = duration + math.floor(v.power)
		elseif v:getType() == "steering" or v:getType() == "seat" then
			-- nothing, ignore
		else
			-- logic input 
			if v.active then logicactive = true end
			if not self.lastinput and v.active then
				self.timeon = self.duration
				self.logicpress = true
			end
		end
	end
	self.lastinput = logicactive
	self.duration = duration > 0 and duration or 1
	
	if self.timeon > self.duration then self.timeon = self.duration end
	self.wason = self.timeon
	
	--self.network:sendToClients("client_setPose", {pose = 0, level = (self.timeon/self.duration)})
	self.network:sendToClients("client_setPose", {pose = 0, level = (self.timeon/self.duration)*3/4 + (self.timeon > 0 and 0.25 or 0)})
	if self.timeon == 0 then
		self.network:sendToClients("client_setUvframeIndex", 0)
	else
		self.network:sendToClients("client_setUvframeIndex",  (2-self.timeon/self.duration) * 25)
	end
	if self.timeon > 0 then
		self.interactable:setActive(true)
		self.interactable:setPower(1)
		self.timeon = self.timeon - 1
		if self.lasttime == 0 and not self.logicpress then
			self.network:sendToClients("client_playsound", "Button on" )
		end
	else
		self.interactable:setActive(false)
		self.interactable:setPower(0)
		if self.lasttime > 0 and not self.logicpress then 
			--print('test')
			self.network:sendToClients("client_playsound", "Button off" )
		end
	end
	self.lasttime = self.wason
end

function tickbutton.client_setUvframeIndex(self, index)
	self.interactable:setUvFrameIndex(index)
end
function tickbutton.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end
function tickbutton.client_setPose(self, data)
	self.interactable:setPoseWeight(data.pose, data.level)
end

function tickbutton.client_onInteract(self)
    self.network:sendToServer("server_settime")
end
function tickbutton.server_settime(self)
	self.timeon = self.duration
	self.logicpress = false
end

function tickbutton.server_onProjectile(self, X, hits, four)
	self.timeon = self.duration
	self.logicpress = false
end




--copyright: Brent Batch