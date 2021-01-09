--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../Libs/LoadLibs.lua"

mpPrint("loading CounterBlock.lua")


-- CounterBlock.lua --
CounterBlock = class( nil )
CounterBlock.maxParentCount = -1 -- infinite
CounterBlock.maxChildCount = -1 -- infinite
CounterBlock.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
CounterBlock.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
CounterBlock.colorNormal = sm.color.new( 0x00194Cff )
CounterBlock.colorHighlight = sm.color.new( 0x0A2866ff )

CounterBlock.power = 0
CounterBlock.digs = {
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
	["df7f01ff"] = 1, -- yay the devs made all vanilla stuff color have an offset compared to old vanilla stuff  >:-(
	
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


function CounterBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function CounterBlock.server_onCreate( self )
	local stored = self.storage:load()
	if stored then
		if type(stored) == "table" then -- compatible with old versions (they used a jank workaround for a bug back then)
			self.power = tonumber(stored[1])
		else
			self.power = tonumber(stored)
		end
		self.interactable:setPower(self.power)
	end
	sm.interactable.setValue(self.interactable, self.power)
end

function CounterBlock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	
	local reset = false
	for k,v in pairs(parents) do
		local x = self.digs[tostring(v:getShape().color)]
		if x ~= nil and (sm.interactable.getValue(v) or v.power) ~= 0 then
			self.power = self.power + x * (sm.interactable.getValue(v) or v.power)
		end
		if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" and v:isActive() then reset = true end
	end
	if reset then self.power = 0 end
	
	self.needssave = self.needssave or (self.power ~= sm.interactable.getValue(self.interactable))
	
	local isTime = os.time()%5 == 0
	if self.needssave and isTime and self.risingedge then
		self.needssave = false
		self.storage:save(tostring(self.power)) -- 64 bit precision (storage.save only goes up to 32 bit numbers)
	end
	self.risingedge = not isTime
	
	if self.power ~= self.power then self.power = 0 end -- NaN check
	if math.abs(self.power) >= 3.3*10^38 then  -- inf check
		if self.power < 0 then self.power = -3.3*10^38 else self.power = 3.3*10^38 end  
	end
	if self.power ~= self.interactable.power then -- self.interactable.power changes on the lift!  sm.interactable.getValue(self.interactable) does not!
		self.interactable:setPower(self.power)
		self.interactable:setActive(self.power>0)
		sm.interactable.setValue(self.interactable, self.power)
	end
end


function CounterBlock.server_reset(self)
	if self.power > 0 then
		self.network:sendToClients("client_resetSound")
	end
	self.power = 0
end

function CounterBlock.client_resetSound(self)
	sm.audio.play("GUI Item drag", self.shape:getWorldPosition())
end

function CounterBlock.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	self.network:sendToServer("server_reset")
end


function CounterBlock.client_onCreate(self, dt)
	self.frameindex = 0
	self.lastpower = 0
end

function CounterBlock.client_canInteract(self)
	local _useKey = sm.gui.getKeyBinding("Use")
	sm.gui.setInteractionText("Press", _useKey, "to reset counter")
	return true
end

function CounterBlock.client_onFixedUpdate(self, dt)
	local power = self.interactable.power
	if self.powerSkip == power then return end -- more performance (only update uv if power changes)
	
	local on = 0
	if power ~= self.lastpower then
		on = 6
		self.frameindex = (self.frameindex + (power > self.lastpower and 0.25 or -0.25)) % 5
		
		if power == 0 then self.frameindex = 0 end	
	end
	
	local index = math.floor(self.frameindex + on)
	if index ~= self.lastindex then 
		self.interactable:setUvFrameIndex(index)
	end
	
	self.powerSkip = (power == self.lastpower and power or false)
	self.lastpower = power
	self.lastindex = index
end
