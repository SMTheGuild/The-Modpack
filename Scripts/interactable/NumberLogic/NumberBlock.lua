--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading NumberBlock.lua")


-- decimal module
NumberBlock = class( nil )
NumberBlock.maxParentCount = -1
NumberBlock.maxChildCount = -1
NumberBlock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
NumberBlock.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
NumberBlock.colorNormal = sm.color.new( 0x0056BFff )
NumberBlock.colorHighlight = sm.color.new( 0x1570D8ff )

NumberBlock.power = 0
NumberBlock.dec = {
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
	["df7f01ff"] = 1, -- orange 2, smh
			
	["eeaf5cff"] = 0.1,
	["f06767ff"] = 0.01,
	["ee7bf0ff"] = 0.001,
	["ae79f0ff"] = 0.0001,
	["4c6fe3ff"] = 0.00001,
	["7eededff"] = 0.000001,
	["68ff88ff"] = 0.0000001,
	["cbf66fff"] = 0.00000001
}
NumberBlock.bin = {
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
	["df7f01ff"] = 1,
	
	["eeaf5cff"] = 1/2,
	["f06767ff"] = 1/4,
	["ee7bf0ff"] = 1/8,
	["ae79f0ff"] = 1/16,
	["4c6fe3ff"] = 1/32,
	["7eededff"] = 1/64,
	["68ff88ff"] = 1/128,
	["cbf66fff"] = 1/256
}


function NumberBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function NumberBlock.server_onCreate( self )
	self:server_setValue(0)
end

function NumberBlock.server_onFixedUpdate( self, dt )   -- 'decimal'
	local parents = self.interactable:getParents()
	local power = 0
	
	for k, parent in pairs(parents) do
		local color = tostring(parent:getShape().color)
		if sm.interactable.isNumberType(parent) and not parent:hasSteering() then
		
			local dec = self.dec[color]
			if dec == nil or #parents == 1 then dec = 1 end
			power = power + dec * (sm.interactable.getValue(parent) or parent.power)
		else
			-- logic input
			local bit = self.bin[color]
			if bit ~= nil and parent.active then power = power + bit end
		end
	end
	
	if math.abs(power) >= 3.3*10^38 then  -- inf check
		if power < 0 then power= -3.3*10^38 else power = 3.3*10^38 end  
	end
	
	local children = self.interactable:getChildren() 
	
	if power == 0 then
		self:server_setValue(0)
	else
		if sm.interactable.isNumberType(parents[1]) and not parents[1]:hasSteering() then  -- power input, show correct decimal
			if #parents == 1 then
				if #children > 0 and children[1]:getType() ~= "scripted" and children[1]:getType() ~= "electricEngine" and children[1]:getType() ~= "gasEngine" then  -- show bits as output
					local s = self.bin[tostring(self.shape.color)]
					if s ~= nil then
						local b = power%(s*2)
						self:server_setValue((b>=s and 1 or 0))
					else
						self:server_setValue(0)
					end
				else
					-- show digit or full value
					local s = self.dec[tostring(self.shape.color)] -- gets correct decimal location in parent based on own color   -- decimal number
					
					local show = power
					
					if s then
						show = math.floor(tonumber(tostring(math.abs(power/s)))%10)
						
					elseif (tostring(sm.shape.getColor(self.shape)) == "f5f071ff") then
						s = 0.00000001
						show = (tonumber(tostring((math.abs(show)/s))))%1 -- shifts digits after the decimal point 8 places to the left and %1
					end
						-- any other color carry full value
					
					self:server_setValue(show)
				end
			else
				-- more than one input, they get combined based on color
				self:server_setValue(power)
			end
		else -- logic input
			self:server_setValue(power)
		end
	end
	
end

function NumberBlock.server_setValue(self, value)
	if value ~= value then value = 0 end
	if math.abs(value) >= 3.3*10^38 then 
		if value < 0 then value = -3.3*10^38 else value = 3.3*10^38 end  
	end

	mp_updateOutputData(self, value, value > 0)
end


function NumberBlock.client_onCreate(self)
	self.index = 0
end

function NumberBlock.client_onFixedUpdate(self, value)
	local parents = self.interactable:getParents()
	local power = 0
	for k, parent in pairs(parents) do
		local color = tostring(parent:getShape().color)
		if sm.interactable.isNumberType(parent) and not parent:hasSteering() then
		
			local dec = self.dec[color]
			if dec == nil or #parents == 1 then dec = 1 end
			power = power + dec * parent.power
		else
			-- logic input
			local bit = self.bin[color]
			if bit ~= nil and parent.active then power = power + bit end
		end
	end
	
	local children = self.interactable:getChildren() 
	if power == 0 then
		self.interactable:setUvFrameIndex(0)
	else
		if sm.interactable.isNumberType(parents[1]) and not parents[1]:hasSteering() then  -- power input, show correct decimal
			if #parents == 1 then
				if #children > 0 and children[1]:getType() ~= "scripted" and children[1]:getType() ~= "electricEngine" and children[1]:getType() ~= "gasEngine" then  -- show bits as output
					local s = self.bin[tostring(self.shape.color)]
					if s ~= nil then
						self.interactable:setUvFrameIndex(self.interactable.power)
					else
						-- gate not correct color , begine flickering
						if self.index == 0 then self.index = 1 else self.index = 0 end
						self.interactable:setUvFrameIndex( self.index)
					end
				else
					local s = self.dec[tostring(sm.shape.getColor(self.shape))] -- gets correct decimal location in parent based on own color   -- NumberBlock number
					
					local show = power
					
					if s then
						show = self.interactable.power
						
						-- figure out if first digit , show '-' in front of num if neg
						if (s*10>0-power) and (power<0) then
							--print('first digit')
							if power <= -1  or (show == 0 and (tostring(self.shape.color) == "df7f00ff" or tostring(self.shape.color) == "df7f01ff")) then -- give first digit a '-', if orange shows '0' and it's before first digit, give it a '-'
								--print('neg')
								if (show == 0 and (tostring(self.shape.color)=="df7f00ff" or tostring(self.shape.color) == "df7f01ff")) then 
									show = show + 12
								end
								if power <= -1 and s*show >= power and show ~= 0 then  show = show + 12 end
							end
						end
						self.interactable:setUvFrameIndex(show)
						
					elseif (tostring(sm.shape.getColor(self.shape)) == "f5f071ff") then
						s = 0.00000001
						local show = self.interactable.power
						if show ~= 0 then
							self.interactable:setUvFrameIndex(24)
						else
							self.interactable:setUvFrameIndex(0)
						end
					else
						-- color is not a digit, carries full value in server.
						self:client_setUVValue(power)
					end	
				end
			else
				-- more than one input, they get combined based on color
				self:client_setUVValue(power)
			end
		else -- logic input, try show full
			self:client_setUVValue(power)
		end
	end
end


function NumberBlock.client_setUVValue(self, power) 
	local value = power
	local index = 0
	if value < 0 then 
		value = 0-value 
		index = index + 12
	end
	if value < 10 then index = index + value else index = index + 10 end
	self.interactable:setUvFrameIndex(index)
end
