--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"


print("loading MemoryPanel.lua")

local memorypanels = {}

sm.modpack = {
	memorypanelWrite = function(interactableid, saveValue)
		local panel = memorypanels[interactableid]
		if panel then
			panel:server_setData(saveValue)
		end
	end
}

-- MemoryPanel.lua --
MemoryPanel = class( nil )
MemoryPanel.maxParentCount = -1
MemoryPanel.maxChildCount = -1
MemoryPanel.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
MemoryPanel.connectionOutput = sm.interactable.connectionType.power 
MemoryPanel.colorNormal = sm.color.new( 0x7F567Dff )
MemoryPanel.colorHighlight = sm.color.new( 0x9f7fa5ff )
MemoryPanel.poseWeightCount = 1


function MemoryPanel.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function MemoryPanel.server_onCreate( self )
	local value = 0
	self.data = {[0] = 0}
	local stored = self.storage:load()
	if stored then
		if type(stored) == "number" then --very old compatibility support
			self.data[0] = stored
		elseif type(stored) == "table" then
			self.data = stored
		end
		value = tonumber(self.data[0]) or 0
	else
		self.storage:save(self.data)
	end
	sm.interactable.setValue(self.interactable, value)
	if value ~= value then value = 0 end
	if math.abs(value) >= 3.3*10^38 then 
		if value < 0 then value = -3.3*10^38 else value = 3.3*10^38 end  
	end
	self.interactable:setPower(value)

	memorypanels[self.interactable.id] = self
end

function MemoryPanel.server_setData(self, saveData)
	self.data = saveData
	self.storage:save(saveData)
end


function MemoryPanel.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local address = 0
	local value = 0
	local writevalue = false
	local hasvalueparent = false
	local reset = false
	for k,v in pairs(parents) do
		local _isSeat = v:hasSteering()
		if not _isSeat then
			if sm.interactable.isNumberType(v) then
				-- number input
				if tostring(v:getShape().shapeUuid) == "d3eda549-778f-432b-bf21-65a32ae53378" then
					writevalue = writevalue or v.active
					value = value + (sm.interactable.getValue(v) or v.power)
					hasvalueparent = true
				elseif tostring(v:getShape().color) == "eeeeeeff" then
					-- address
					address = address + (sm.interactable.getValue(v) or v.power)
				else
					-- value
					value = value + (sm.interactable.getValue(v) or v.power)
					hasvalueparent = true
				end
			else
				-- logic input
				if v.active then 
					writevalue = true
					if tostring(v:getShape().color) == "222222ff" then
						reset = true
					end
				end
			end
		end
	end
	
	local saves = false
	if writevalue and hasvalueparent then
		self.data[address] = tostring(value)
		saves = self.data[address] ~= value
	end
	local power = tonumber(self.data[address]) or 0 
	if reset then
		power = 0
		self.data = {[0] = 0}
		saves = true
	end
	
	if saves then
		self.storage:save(self.data)
	end
	
	if power ~= power then power = 0 end
	if math.abs(power) >= 3.3*10^38 then 
		if power < 0 then power = -3.3*10^38 else power = 3.3*10^38 end  
	end

	mp_updateOutputData(self, power, power > 0)
end

function MemoryPanel.client_onCreate(self)
	self.mode = 0
	self.time = 0
end

function MemoryPanel.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local address = 0
	local writevalue = false
	local reset = false
	local hasvalueparent = false
	for k,v in pairs(parents) do
		local _isSeat = v:hasSteering()
		if not _isSeat then
			if sm.interactable.isNumberType(v) then
				-- number input
				if tostring(v:getShape().shapeUuid) == "d3eda549-778f-432b-bf21-65a32ae53378" then
					writevalue = writevalue or v.active
					hasvalueparent = true
				elseif tostring(v:getShape().color) == "eeeeeeff" then
					-- address
					address = address + v.power
				else
					hasvalueparent = true
				end
			else
				-- logic input
				if v.active then 
					writevalue = true
					if tostring(v:getShape().color) == "222222ff" then
						reset = true
					end
				end
			end
		end
	end
	
	if writevalue and hasvalueparent then
		self.time = 20
		self.mode = 1
	end
	
	if reset then
		self.time = 60
		self.mode = 1
	end
	
	if self.lastPower ~= self.interactable.power and self.mode == 0 then
		self.time = 20
		self.mode = 2
	end
	
	
	if address ~= self.lastaddress then self:client_setUvValue(address) end
	
	if self.mode == 1 then
		self.interactable:setPoseWeight(0,(self.time%4)>2 and 1 or 0)
	elseif self.mode == 2 then	
		self.interactable:setPoseWeight(0, self.time>0 and 1 or 0)
	else
		self.interactable:setPoseWeight(0, 0)
	end
	self.time = self.time > 0 and self.time - 1 or 0
	self.mode = self.time > 0 and self.mode or 0
	
	self.lastPower = self.interactable.power
	self.lastaddress = address
end

function MemoryPanel.client_setUvValue(self, value) 
	if value < 0 then 
		value = 0-value 
	end
	if value > 255 then value = 255 end
	if value == math.huge then value = 0 end
	self.interactable:setUvFrameIndex(value)
end