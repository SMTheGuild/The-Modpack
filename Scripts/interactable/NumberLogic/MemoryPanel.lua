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

function formatInput(text)
	-- sanitize allowed characters: digits, colon, comma, period, minus
	text = text:gsub("[^%d:,%.-]", "")
	-- insert spaces after each colon not at the end
	text = text:gsub(":([^$])", ": %1")
	-- insert newlines after each comma not at the end
	text = text:gsub(",([^$])", ",\n%1")
	return text
end

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

function MemoryPanel.server_setData(self, saveData, caller)
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

function MemoryPanel.client_onDestroy(self)
	self:client_onGuiCloseCallback()
end

function MemoryPanel.client_canInteract(self)
	local use_key = sm.gui.getKeyBinding("Use", true)
	sm.gui.setInteractionText("Press", use_key, "to edit contents")
	return true
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

function MemoryPanel.client_displayData(self, data)
	local parts = {}

	local keys = {}
	for k, v in pairs(data) do
		if v ~= 0 or k == 0 then table.insert(keys, k) end
	end

	table.sort(keys)

	for _, k in ipairs(keys) do
		table.insert(parts, k .. ": " .. data[k])
	end

	self.mem_gui_input = table.concat(parts, ",\n")

	self.mem_gui:setText("ValueInput", self.mem_gui_input)
end

function MemoryPanel.client_onInteract(self, character, lookAt)
	if mp_deprecated_game_version or not lookAt or character:getLockingInteractable() then return end
	local mem_gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/MemoryPanelGui.layout", false, { backgroundAlpha = 0.5 })
	mem_gui:setButtonCallback("SaveWrittenVal", "client_gui_saveWrittenValue")
	mem_gui:setTextChangedCallback("ValueInput", "client_onTextChangedCallback")
	mem_gui:setOnCloseCallback("client_onGuiCloseCallback")
	self.mem_gui = mem_gui
	if sm.isHost then
		self:client_displayData(self.data)
	else
		self.network:sendToServer("server_getAndDisplayData")
	end
	mem_gui:open()
end

function MemoryPanel.server_getAndDisplayData(self, _, caller)
	self.network:sendToClient(caller, "client_displayData", self.data)
end

function MemoryPanel.client_onTextChangedCallback(self, widget, text)
	self.mem_gui_input = formatInput(text)
	if text~=self.mem_gui_input then
		self.mem_gui:setText("ValueInput", self.mem_gui_input)
	end
end

function MemoryPanel.client_onGuiCloseCallback(self)
	local mem_gui = self.mem_gui
	if mem_gui and sm.exists(mem_gui) then
		if mem_gui:isActive() then
			mem_gui:close()
		end

		mem_gui:destroy()
	end

	self.mem_gui_input = nil
	self.mem_gui = nil
end


function MemoryPanel.parseData(input)
	local data = {}

	for entry in input:gmatch("([^,]+)") do
		-- trim surrounding whitespace
		entry = entry:match("^%s*(.-)%s*$") or ""
		if entry ~= "" then
			-- require exactly one ':' and non-empty lhs and rhs
			local addrStr, valStr = entry:match("^([^:]+):([^:]+)$")
			if addrStr and valStr then
				addrStr = addrStr:match("^%s*(.-)%s*$") or ""
				valStr = valStr:match("^%s*(.-)%s*$") or ""
				if addrStr ~= "" and valStr ~= "" then
					-- parse address to integer, make positive
					local addr = tonumber(addrStr)
					if addr then
						addr = math.floor(math.abs(addr))

						-- parse value
						local numVal = tonumber(valStr)
						if numVal then
							data[addr] = tostring(numVal)
						end
					end
				end
			end
		end
	end

	-- ensure there's at least a default entry (address 0) if nothing parsed
	if not next(data) then
		data[0] = "0"
	end

	return data
end

function MemoryPanel.client_gui_saveWrittenValue(self)
	local data = self.parseData(self.mem_gui_input)
	self:client_displayData(data)
	self.network:sendToServer("server_setData", data)
	sm.audio.play("GUI Item released", self.shape:getWorldPosition())
end