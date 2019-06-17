dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if NumberBlock and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 
dofile "../Libs/GameImprovements/interactable.lua"
dofile "../Libs/MoreMath.lua"

mpPrint("loading NumberBlock.lua")


-- decimal module
NumberBlock = class( nil )
NumberBlock.maxParentCount = -1
NumberBlock.maxChildCount = -1
NumberBlock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
NumberBlock.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
NumberBlock.colorNormal = sm.color.new( 0x0056BFff )
NumberBlock.colorHighlight = sm.color.new( 0x1570D8ff )
NumberBlock.poseWeightCount = 1


function NumberBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function NumberBlock.server_onCreate( self ) 
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




function NumberBlock.server_onFixedUpdate( self, dt )   -- 'decimal'
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
					local s = self.dec[tostring(sm.shape.getColor(self.shape))] -- gets correct decimal location in parent based on own color   -- NumberBlock number
					
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

function NumberBlock.client_onCreate(self)
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

function NumberBlock.client_onFixedUpdate(self, value)
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
					local s = self.dec[tostring(sm.shape.getColor(self.shape))] -- gets correct decimal location in parent based on own color   -- NumberBlock number
					
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
