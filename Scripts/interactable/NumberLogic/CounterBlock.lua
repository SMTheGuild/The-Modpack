--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading CounterBlock.lua")


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
	
	mp_updateOutputData(self, self.power, self.power > 0)
end

function CounterBlock.server_setNewValue(self, value, caller)
	self.power = value

	self.network:sendToClient(caller, "client_playSound", 2)
end

function CounterBlock.server_receiveValue(self, value, caller)
	self.power = self.power + value

	self.network:sendToClient(caller, "client_playSound", 2)
end

function CounterBlock.server_reset(self)
	if self.power > 0 then
		self.network:sendToClients("client_playSound", 1)
	end
	self.power = 0
end

local sound_id_table = 
{
	[1] = "GUI Item drag",
	[2] = "GUI Item released"
}

function CounterBlock.client_playSound(self, sound_id)
	local sound_id_table = sound_id_table[sound_id]

	sm.audio.play(sound_id_table, self.shape:getWorldPosition())
end

function CounterBlock.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	
	self.network:sendToServer("server_reset")
end

function CounterBlock.client_onTextChangedCallback(self, widget, text)
	local converted_text = tonumber(text) --will be nill if the input is invalid
	local is_valid = (converted_text ~= nil)

	self.counter_gui_input = text

	local count_gui = self.counter_gui
	count_gui:setVisible("ValueError", not is_valid)

	count_gui:setVisible("IncrementWith", is_valid)
	count_gui:setVisible("DecrementWith", is_valid)
	count_gui:setVisible("SaveWrittenVal", is_valid)
end

function CounterBlock.client_onGuiCloseCallback(self)
	local count_gui = self.counter_gui
	if count_gui and sm.exists(count_gui) then
		if count_gui:isActive() then
			count_gui:close()
		end

		count_gui:destroy()
	end

	self.counter_gui_input = nil
	self.counter_gui = nil
end

function CounterBlock.client_gui_updateSavedValueText(self)
	self.counter_gui:setText("SavedValue", "Saved Value: #ffff00"..tostring(self.interactable.power).."#ffffff")
end

function CounterBlock.client_gui_changeSavedValue(self, widget)
	local is_decrement = (widget:sub(0, 1) == "D")

	local cur_changer = tonumber(self.counter_gui_input)
	if cur_changer ~= nil then
		if is_decrement then
			cur_changer = -cur_changer
		end

		self.network:sendToServer("server_receiveValue", cur_changer)
	end
end

function CounterBlock.client_gui_saveWrittenValue(self)
	local cur_value = tonumber(self.counter_gui_input)
	if cur_value ~= nil then
		self.network:sendToServer("server_setNewValue", cur_value)
	end
end

function CounterBlock.client_onTinker(self, character, lookAt)
	if mp_deprecated_game_version or not lookAt or character:getLockingInteractable() then return end

	local count_gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/CounterBlockGui.layout", false, { backgroundAlpha = 0.5 })

	self.counter_gui_input = tostring(self.interactable.power)

	count_gui:setText("SavedValue", "Saved Value: #ffff00"..tostring(self.interactable.power).."#ffffff")
	count_gui:setText("ValueInput", self.counter_gui_input)

	count_gui:setButtonCallback("IncrementWith", "client_gui_changeSavedValue")
	count_gui:setButtonCallback("DecrementWith", "client_gui_changeSavedValue")
	count_gui:setButtonCallback("SaveWrittenVal", "client_gui_saveWrittenValue")

	count_gui:setTextChangedCallback("ValueInput", "client_onTextChangedCallback")
	count_gui:setOnCloseCallback("client_onGuiCloseCallback")

	count_gui:open()

	self.counter_gui = count_gui
end

function CounterBlock.client_onCreate(self, dt)
	self.frameindex = 0
	self.lastpower = 0
end

function CounterBlock.client_onDestroy(self)
	self:client_onGuiCloseCallback()
end

function CounterBlock.client_canInteract(self)
	local use_key = mp_gui_getKeyBinding("Use", true)
	sm.gui.setInteractionText("Press", use_key, "to reset counter")

	if mp_deprecated_game_version then
		sm.gui.setInteractionText("")
	else
		local tinker_key = mp_gui_getKeyBinding("Tinker", true)
		sm.gui.setInteractionText("Press", tinker_key, "to open gui")
	end

	return true
end

function CounterBlock.client_onFixedUpdate(self, dt)
	local count_gui = self.counter_gui
	if count_gui then
		self:client_gui_updateSavedValueText()
	end

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
