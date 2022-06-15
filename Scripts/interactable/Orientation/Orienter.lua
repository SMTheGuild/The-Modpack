--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading Orienter.lua")

local known_mobs = {
	hostile = {
		tapebot = {
			["04761b4a-a83e-4736-b565-120bc776edb2"] = true,
			["9dbbd2fb-7726-4e8f-8eb4-0dab228a561d"] = true,
			["fcb2e8ce-ca94-45e4-a54b-b5acc156170b"] = true,
			["68d3b2f3-ed4b-4967-9d22-8ee6f555df63"] = true,
			["c3d31c47-0c9b-4b07-9bd4-8f022dc4333e"] = true
		},
		totebot = {["8984bdbf-521e-4eed-b3c4-2b5e287eb879"] = true},
		haybot = {["c8bfb8f3-7efc-49ac-875a-eb85ac0614db"] = true},
		farmbot = {["9f4fde94-312f-4417-b13b-84029c5d6b52"] = true}
	},
	friendly = {
		glorp = {["48c03f69-3ec8-454c-8d1a-fa09083363b1"] = true},
		woc = {["264a563a-e304-430f-a462-9963c77624e9"] = true}
	}
}

local FarmbotDetectorModes = {
	[20] = {hostile = true},
	[21] = {hostile = true, specific = "farmbot"},
	[22] = {hostile = true, specific = "tapebot"},
	[23] = {hostile = true, specific = "haybot"},
	[24] = {hostile = true, specific = "totebot"},
	[25] = {hostile = true, friendly = true},
	[26] = {friendly = true},
	[27] = {specific = "woc"},
	[28] = {specific = "glorp"}
}

--[[
	that's how you can add your own units into the list
	function class:server_onCreate()
		if sm.MODPACK_ORIENT_ADD_UNIT then
			local name = "test_unit_name"
			local unit_uuid = "8984bdbf-521e-4eed-b3c4-2b5e287eb879"
			local is_friendly = true
			sm.MODPACK_ORIENT_ADD_UNIT(name, unit_uuid, is_friendly)
		end
	end
	WARNING: this function can't be used when the script of Orientation Block hasn't been initialized yet
]]
--this function allows adding unit uuids into The Modpack from any mod since that function is in global table
sm.MODPACK_ORIENT_ADD_UNIT = function(name, unit_uuid, is_friendly)
	local list = (is_friendly and "friendly" or "hostile")
	if known_mobs[list][name] == nil then
		known_mobs[list][name] = {}
	end
	if known_mobs[list][name][unit_uuid] == nil then
		known_mobs[list][name][unit_uuid] = true
		print("[Modpack] Unit \""..unit_uuid.."\" named \""..name.."\" has been successfully added into "..list.." units list!")
	end
end

local _GETALLUNITS = function()
	return {}
end
if sm.unit then --for some reason clients don't have sm.unit
	if sm.unit.getAllUnits and type(sm.unit.getAllUnits) == "function" then --better than having a function that checks the same stuff but 40 times per second
		_GETALLUNITS = sm.unit.getAllUnits
	elseif sm.unit.HACK_getAllUnits_HACK and type(sm.unit.HACK_getAllUnits_HACK) == "function" then
		_GETALLUNITS = sm.unit.HACK_getAllUnits_HACK
	end
end

Orienter = class( nil )
Orienter.maxParentCount = -1
Orienter.maxChildCount = -1
Orienter.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Orienter.connectionOutput = sm.interactable.connectionType.power
Orienter.colorNormal = sm.color.new( 0x0000ffff )
Orienter.colorHighlight = sm.color.new( 0x3333ffff )
Orienter.poseWeightCount = 2

local usage = "\nWhite logic input press: toggle closest player on exceptionlist"..
    "\nOther logic input: turn on/off"..
    "\nWhite number input: player id / tracker frequency"..
    "\nBlack number input: closest/furthest (2=2nd closest, -2=2nd furthest)"..
    "\nOther columns color input: range (1 input=maxrange, 2inputs=range in between inputs)"

local predictiveusage = "\nLightGrey input: damping (%)"..
    "\nDarkGrey input: lead (%)"

Orienter.modetable = {
	{savevalue = 1, target = "world", loc = false, name = "World", description ="will point towards the ground, use wasd/gimball or math block for wasd output", predictive = false },
	{savevalue = 2, target = "world", loc = false, name = "World (predictive)", description = "will point towards the ground, use wasd/gimball or math block for wasd output", predictive = true },
	{savevalue = 3, target = "player", loc = false, name = "Player", predictive = false },
	{savevalue = 4, target = "player", loc = false, name = "Player (predictive)", predictive = true },
	{savevalue = 5, target = "tracker", loc = false, name = "Tracker", predictive = false },
	{savevalue = 6, target = "tracker", loc = false, name = "Tracker (predictive)", predictive = true },
	{savevalue = 9, target = "playertracker", loc = false, name = "Tracker + player", predictive = false },
	{savevalue = 10, target = "playertracker", loc = false, name = "Tracker + player (predictive)", predictive = true },
	{savevalue = 7, target = "camera", loc = false, name = "Player camera", predictive = false, description = "An connected occupied seat will overwrite ANY filter settings"},
	{savevalue = 11, target = "camera", loc = false, name = "Player camera (predictive)", predictive = true, description = "An connected occupied seat will overwrite ANY filter settings"},
	{savevalue = 8, target = "distance", loc = false, predictive = false, name = "Orienter Distance Reader", description = "Read distance to target from other orient blocks"},

	{savevalue = 12, target = "player", loc = true, name = "Player (local)", description = "Locla mode is used for missiles!", predictive = false },
	{savevalue = 13, target = "player", loc = true, name = "Player (local, predictive)", predictive = true },
	{savevalue = 14, target = "tracker", loc = true, name = "Tracker (local)", predictive = false },
	{savevalue = 15, target = "tracker", loc = true, name = "Tracker (local, predictive)", predictive = true },
	{savevalue = 17, target = "playertracker", loc = true, name = "Tracker + player (local)", predictive = false },
	{savevalue = 18, target = "playertracker", loc = true, name = "Tracker + player (local, predictive)", predictive = true },
	{savevalue = 16, target = "camera", loc = true, name = "Player camera (local)", predictive = false, extra = "A connected occupied seat will overwrite ANY filter settings"},--
	{savevalue = 19, target = "camera", loc = true, name = "Player camera (local, predictive)", predictive = true, extra = "A connected occupied seat will overwrite ANY filter settings"},

	{savevalue = 25, target = "units", unit = "all", loc = false, predictive = false, name = "All units" },
	{savevalue = 20, target = "units", unit = "hostile", loc = false, predictive = false, name = "Hostile units" },
	{savevalue = 21, target = "units", unit = "farmbot", loc = false, predictive = false, name = "Hostile farmbot" },
	{savevalue = 22, target = "units", unit = "tapebot", loc = false, predictive = false, name = "Hostile tapebot" },
	{savevalue = 23, target = "units", unit = "haybot", loc = false, predictive = false, name = "Hostile haybot" },
	{savevalue = 24, target = "units", unit = "totebot", loc = false, predictive = false, name = "Hostile totebot" },
	{savevalue = 26, target = "units", unit = "friendly", loc = false, predictive = false, name = "Friendly units" },
	{savevalue = 27, target = "units", unit = "woc", loc = false, predictive = false, name = "Woc" },
	{savevalue = 28, target = "units", unit = "glowworm", loc = false, predictive = false, name = "Glow worm" }
}
Orienter.modeIndexBySaveValue = {}
for k, v in pairs(Orienter.modetable) do
    Orienter.modeIndexBySaveValue[v.savevalue] = k
end

Orienter.modeCount = #Orienter.modetable

function Orienter.server_onCreate( self )
	self:server_init()
end

function Orienter.server_init( self )
	self.mode = 1
	self.power = 0
	self.pitch = 0
	self.yaw = 0
	self.pose1 = 0
	self.playerexceptions = {}
	--more code here:

	local savemodes = {}
	for k,v in pairs(self.modetable) do
	   savemodes[v.savevalue]=k
	end

	local stored = self.storage:load()
	if stored and type(stored) == "number" then
		self.mode = savemodes[stored]
	end
	self.storage:save(self.modetable[self.mode].savevalue)

	if not orienters then orienters = {} end
	self.id = self.shape.id
end

function Orienter.client_onCreate(self)
	self.network:sendToServer("sv_sendModeToClient")
end

function Orienter.client_onDestroy(self)
	self:client_onGuiDestroyCallback()
end

function Orienter.sv_sendModeToClient(self)
	local _UvIndex = self.modetable[self.mode].savevalue - 1
	self.network:sendToClients("cl_setMode", { uvIndex = _UvIndex, mode = self.mode })
end

function Orienter.server_onRefresh( self )
	self:server_init()
end

local targetTable = {
	'TargetWorld', 'TargetPlayer', 'TargetCamera',
	'TargetTracker', 'TargetPlayerTracker', 'TargetUnits',
	'TargetDistance'
}

local _UnitTable = {
	'UnitsAll', 'UnitsHostile', 'UnitsFriendly',
	'UnitsFarmbot', 'UnitsTapebot', 'UnitsHaybot',
	'UnitsTotebot', 'UnitsWoc', 'UnitsGlowworm'
}

function Orienter.client_onGuiDestroyCallback(self)
	local s_gui = self.gui
	if s_gui and sm.exists(s_gui) then
		if s_gui:isActive() then
			s_gui:close()
		end

		s_gui:destroy()
	end

	self.gui = nil
end

function Orienter.client_onInteract(self, character, lookAt)
    if lookAt == true then
        self.gui = mp_gui_createGuiFromLayout("$MOD_DATA/Gui/Layouts/Orienter.layout", false, { backgroundAlpha = 0.5 })
		self.gui:setOnCloseCallback("client_onGuiDestroyCallback")

        for _, buttonName in pairs(targetTable) do
            self.gui:setButtonCallback(buttonName, "cl_onTargetButtonClick")
        end

        for _, buttonName in pairs(_UnitTable) do
            self.gui:setButtonCallback(buttonName, 'cl_onUnitButtonClick')
        end

        self.gui:setButtonCallback('OptionPredictive', "cl_onPredictiveToggle")
        self.gui:setButtonCallback('OptionLocal', "cl_onLocalToggle")

        self:cl_drawButtons()
		self.gui:open()
	end
end

function Orienter.cl_onUnitButtonClick(self, buttonName)
    local saveValues = {
        UnitsAll = 25,
    	UnitsHostile = 20,
    	UnitsFarmbot = 21,
    	UnitsTapebot = 22,
    	UnitsHaybot = 23,
    	UnitsTotebot = 24,
    	UnitsFriendly = 26,
    	UnitsWoc = 27,
    	UnitsGlowworm = 28
    }
    self:cl_handleChageModeFromGui(Orienter.modeIndexBySaveValue[saveValues[buttonName]])
end

function Orienter.cl_handleChageModeFromGui(self, newMode)
	if self.mode_client == newMode then return end

    self.network:sendToServer('sv_changeMode', { mode = newMode })
    self.mode_client = newMode
    self:cl_drawButtons()
end

function Orienter.cl_onPredictiveToggle(self, button)
    local currentMode = Orienter.modetable[self.mode_client]
    local inverse = {
        [2] = 1,
        [1] = 2,
        [3] = 4,
        [4] = 3,
        [5] = 6,
        [6] = 5,
        [9] = 10,
        [10] = 9,
        [7] = 11,
        [11] = 7,
        [12] = 13,
        [13] = 12,
        [14] = 15,
        [15] = 14,
        [17] = 18,
        [18] = 17,
        [19] = 16,
        [16] = 19
    }
    self:cl_handleChageModeFromGui(Orienter.modeIndexBySaveValue[inverse[currentMode.savevalue]])
end

function Orienter.cl_onLocalToggle(self, button)
    local currentMode = Orienter.modetable[self.mode_client]
    local inverse = {
        [3] = 12,
        [4] = 13,
        [5] = 14,
        [6] = 15,
        [7] = 16,
        [9] = 17,
        [10] = 18,
        [11] = 19,
        [12] = 3,
        [13] = 4,
        [14] = 5,
        [15] = 6,
        [16] = 7,
        [17] = 9,
        [18] = 10,
        [19] = 11
    }
    self:cl_handleChageModeFromGui(Orienter.modeIndexBySaveValue[inverse[currentMode.savevalue]])
end

function Orienter.cl_onTargetButtonClick(self, buttonName)
    local currentMode = Orienter.modetable[self.mode_client]

    local pred = currentMode.predictive
    local loc = currentMode.loc

    local newModeValue = nil
    if buttonName == 'TargetWorld' then
        if currentMode.target ~= 'world' then
            newModeValue = currentMode.predictive and 2 or 1
        end
    elseif buttonName == 'TargetPlayer' then
        if currentMode.target ~= 'player' then
            newModeValue = pred and (loc and 13 or 4) or (loc and 12 or 3)
        end
    elseif buttonName == 'TargetTracker' then
        if currentMode.target ~= 'tracker' then
            newModeValue = pred and (loc and 15 or 6) or (loc and 14 or 5)
        end
    elseif buttonName == 'TargetPlayerTracker' then
        if currentMode.target ~= 'playertracker' then
            newModeValue = pred and (loc and 18 or 10) or (loc and 17 or 9)
        end
    elseif buttonName == 'TargetCamera' then
        if currentMode.target ~= 'camera' then
            newModeValue = pred and (loc and 19 or 11) or (loc and 18 or 7)
        end
    elseif buttonName == 'TargetDistance' then
        if currentMode.target ~= 'distance' then
            newModeValue = 8
        end
    elseif buttonName == 'TargetUnits' then
        if currentMode.target ~= 'units' then
            newModeValue = 25
        end
    end

    --print(newModeValue)

    if newModeValue ~= nil then
        self:cl_handleChageModeFromGui(Orienter.modeIndexBySaveValue[newModeValue])
    end
end

local _buttonData = {
	world = {pred = true, mode = 'TargetWorld'},
	player = {pred = true, loc = true, mode = 'TargetPlayer'},
	camera = {pred = true, loc = true, mode = 'TargetCamera'},
	tracker = {pred = true, loc = true, mode = 'TargetTracker'},
	playertracker = {pred = true, loc = true, mode = 'TargetPlayerTracker'},
	units = {unit = true, mode = 'TargetUnits'},
	distance = {mode = 'TargetDistance'}
}

function Orienter.cl_drawButtons(self)
    local mode = Orienter.modetable[self.mode_client]
	local btnData = _buttonData[mode.target]

	local _Pred = (btnData.pred == true)
	local _Local = (btnData.loc == true)
	local _Unit = (btnData.unit == true)
	local _CurTarget = btnData.mode

	self.gui:setVisible('HeadingOptions', _Pred or _Local)
	self.gui:setVisible('OptionPredictive', _Pred)
	self.gui:setVisible('OptionPredictiveLabel', _Pred)
	self.gui:setVisible('OptionLocal', _Local)
	self.gui:setVisible('OptionLocalLabel', _Local)
	self.gui:setVisible('Units', _Unit)

	self.gui:setVisible('OptionPredictiveCheck', mode.predictive)
	self.gui:setVisible('OptionLocalCheck', mode.loc)

	for k, v in pairs(targetTable) do
		self.gui:setButtonState(v, v == _CurTarget)
	end

	if _Unit then
		for _, btnName in pairs(_UnitTable) do
			self.gui:setButtonState(btnName, btnName:lower() == 'units' .. mode.unit)
		end
	end

	self.gui:setText('FunctionNameText', mode.name)
    self.gui:setText('FunctionDescriptionText', (mode.description or '') .. (mode.extra or ''))
end

function Orienter.sv_changeMode(self, params)
    self.mode = params.mode
	self.storage:save(self.modetable[self.mode].savevalue)
	self.network:sendToClients("client_playsound", "GUI Item drag")
    self.network:sendToClients('cl_setMode', { mode = params.mode, uvIndex = Orienter.modetable[params.mode].savevalue - 1 })
end

function Orienter.client_canInteract(self)
	local use_key = mp_gui_getKeyBinding("Use", true)
	sm.gui.setInteractionText("Press", use_key, "to select an orient mode")

	return true
end

function Orienter.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end

function Orienter.server_onDestroy(self)
	orienters[self.id] = nil
end

function Orienter.getplayer(self, data)  --self:getplayer({useexceptionlist = false, minrange = nil, maxrange = nil, offset = 1, tryid = nil, ignorejammers = false})
	local centerpos = data.centerpos or self.shape:getWorldPosition()
	local enabled = data.useexceptionlist or false
	local minrange = data.minrange or 0
	local maxrange = data.maxrange or 10000000
	local offset = data.offset or 1
	local tryid = data.tryid
	local ignorejammers = data.ignorejammers


	local validplayers = {}
	local closestvalidid = nil
	local closestvaliddistance = nil
	for key, player in pairs(sm.player.getAllPlayers()) do
		if playerexists(player) and (not self.playerexceptions[player.id] or not enabled) and (nojammercloseby(player.character.worldPosition) or ignorejammers) then
			local distance = (centerpos - player.character.worldPosition):length()
			if distance >= minrange and distance < maxrange then
				if player.id == tryid then return data.tryid end
				if not closestvalidid or closestvaliddistance > distance then
					closestvalidid = player.id
					closestvaliddistance = distance
				end
				table.insert(validplayers, player)
			end
		end
	end


	if closestvalidid == nil then return 0 end
	if offset == 1 or #validplayers == 1 then return closestvalidid end

	--sort players : ({[1] = closestplayer, [2]= 2ndclosest, ...})
	local sortedplayers = validplayers
	for i = 1,#sortedplayers do
		for j = i,#sortedplayers do
			local player = sortedplayers[i]
			local player2 = sortedplayers[j]
			if (centerpos - player.character.worldPosition):length() > (centerpos - player2.character.worldPosition):length() then
				sortedplayers[i] = player
				sortedplayers[j] = player2
			end
		end
	end
	offset = math.max(math.min(offset, #sortedplayers), -#sortedplayers)
	-- closest/furthest thing ('black input')
	if offset and offset ~= 0 and offset <= #sortedplayers and offset >= -#sortedplayers then
		if offset < 0 then offset = offset + 1 + #sortedplayers end
		return sortedplayers[offset].id
	end
	return sortedplayers[1].id
end

function Orienter.TestFarmbotUuid(uuid, data)
	if data.hostile and data.friendly then
		for list, val in pairs(known_mobs) do
			for k, v in pairs(known_mobs[list]) do
				if v[uuid] then return true end
			end
		end
	else
		local list = (data.hostile and "hostile" or "friendly")
		local c_tab = known_mobs[list]
		if data.specific then
			if c_tab[data.specific] then
				c_tab = c_tab[data.specific]
			end
			return (c_tab[uuid] ~= nil)
		else
			for k, v in pairs(c_tab) do
				if v[uuid] then return true end
			end
		end
	end

	return false
end

function Orienter.getFarmbot(self, data)
	local centerpos = data.centerpos or self.shape:getWorldPosition()
	local minrange = data.minrange or 0
	local maxrange = data.maxrange or 10000000
	local offset = data.offset or 1
	local tryid = data.tryid
	local ignorejammers = data.ignorejammers
	local fbot_data = data.fbot_data


	local validfarmbots = {}
	local closestvalidid = nil
	local closestvaliddistance = nil

	for key, farmbot in pairs(_GETALLUNITS()) do
		if playerexists(farmbot) and (nojammercloseby(farmbot.character.worldPosition) or ignorejammers) then
			local _fbotUuid = tostring(farmbot.character:getCharacterType())
			if self.TestFarmbotUuid(_fbotUuid, fbot_data) then
				local distance = (centerpos - farmbot.character.worldPosition):length()
				if distance >= minrange and distance < maxrange then
					if farmbot.id == tryid then return data.tryid end
					if not closestvalidid or closestvaliddistance > distance then
						closestvalidid = farmbot.id
						closestvaliddistance = distance
					end
					table.insert(validfarmbots, farmbot)
				end
			end
		end
	end

	if closestvalidid == nil then return 0 end
	if offset == 1 or #validfarmbots == 1 then return closestvalidid end

	local sortedfarmbots = validfarmbots
	for i = 1, #sortedfarmbots do
		for j = i, #sortedfarmbots do
			local farmbot = sortedfarmbots[i]
			local farmbot2 = sortedfarmbots[j]
			if (centerpos - farmbot.character.worldPosition):length() > (centerpos - farmbot2.character.worldPosition):length() then
				sortedfarmbots[i] = farmbot
				sortedfarmbots[j] = farmbot2
			end
		end
	end

	offset = math.max(math.min(offset, #sortedfarmbots), -#sortedfarmbots)
	if offset and offset ~= 0 and offset <= #sortedfarmbots and offset >= -#sortedfarmbots then
		if offset < 0 then offset = offset + 1 + #sortedfarmbots end
		return sortedfarmbots[offset].id
	end
	return sortedfarmbots[1].id
end

function Orienter.gettracker(self, data)  --self:gettracker({minrange = nil, maxrange = nil, offset = 1, frequency = 0, ignorejammers = false})
	local centerpos = self.shape:getWorldPosition()
	local color = tostring(sm.shape.getColor(self.shape))
	local filtercolor = not data.colorignore
	local minrange = data.minrange or 0
	local maxrange = data.maxrange or 10000000
	local offset = data.offset or 0
	local frequency = data.frequency
	local ignorejammers = data.ignorejammers

	if not trackertrackers then return 0 end

	local validtrackers = {}
	local closestvalidid = nil
	local closestvaliddistance = nil
	local closestvalididmatchingcolor = nil
	local closestvaliddistancematchingcolor = nil
	for key, tracker in pairs(trackertrackers) do
		local trackerShape = (tracker ~= nil and sm.exists(tracker.shape) and tracker:getTrackerShape() or nil)

		if trackerShape then
			local trackerpos = trackerShape.worldPosition
			local distance = (centerpos - trackerpos):length()
			if (nojammercloseby(trackerpos) or ignorejammers) and
			distance >= minrange and distance < maxrange and (tracker:getFrequency() == frequency or frequency == nil)  and (trackerShape.color == color or not filtercolor) then
				if tostring(trackerShape.color) == color then
					if not closestvalididmatchingcolor or closestvaliddistancematchingcolor > distance then
						closestvalididmatchingcolor = key
						closestvaliddistancematchingcolor = distance
					end
				end
				if not closestvalidid or closestvaliddistance > distance then
					closestvalidid = key
					closestvaliddistance = distance
				end
				table.insert(validtrackers, {trackerShape, key})
				--validtrackers[tracker.id] = tracker
			end
		end
	end

	--print('-----', self.shape.id)
	--for key, tracker in pairs(validtrackers) do print('validtracker',key, tracker) end

	if closestvalidid == nil then return 0 end -- nothing found in range with same frequency which is not jammed
	if closestvalididmatchingcolor and offset == 0 then return closestvalididmatchingcolor end -- if no offset defined, use closest matching color
	if offset == 1 or size(validtrackers) == 1 then return closestvalidid end


	--sort trackers : ({[1] = closestplayer, [2]= 2ndclosest, ...})
	local sortedtrackers = {validtrackers[1]}

	for k, v in pairs(validtrackers) do
		local inserted = false
		for i = 1, #sortedtrackers do
			if (centerpos - v[1].worldPosition):length() < (centerpos - sortedtrackers[i][1].worldPosition):length() then
				table.insert(sortedtrackers, i, v)
				inserted = true
				break
			end
		end
		if not inserted and k ~= 1 then
			table.insert(sortedtrackers, v)
		end
	end

	--print('\n\n\n-----')
	--for key, tracker in pairs(validtrackers) do print('validtracker',key, tracker) end
	--for key, tracker in pairs(sortedtrackers) do print('sortedtracker',tracker,(centerpos - tracker.pos):length()) end

	offset = math.max(math.min(offset, #sortedtrackers), -#sortedtrackers)
	-- closest/furthest thing ('black input')
	if offset and offset ~= 0 and offset <= #sortedtrackers and offset >= -#sortedtrackers then
		if offset < 0 then offset = offset + 1 + #sortedtrackers end
		return sortedtrackers[offset][2]
	end
	return sortedtrackers[1][2]
end

function size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i +1
	end
	return i
end


function Orienter.calcpitchandyawlocal(self, data)
	--targetdirection
	--local eye = data.direction
	local targetpos = data.targetdirection
	local vec = targetpos
	local localdir = sm.vec3.new(self.shape.right:dot(vec), self.shape.at:dot(vec), self.shape.up:dot(vec))

	local right = self.shape.right
	local at = self.shape.at
	local up = self.shape.up

	-- x up/down , y= left/right
	if self.shape:getXAxis().z == 1 then
		localdir.y, localdir.x = -localdir.y, - localdir.x
		--right, at, up = -up, -at, right
	elseif self.shape:getXAxis().z == -1 then -- tested
		localdir.y,localdir.x = -localdir.y,-localdir.x
		--right, at, up = -up, at, -right
	elseif self.shape:getYAxis().z == 1 then -- tested
		localdir.x, localdir.y = -localdir.y, localdir.x
		--right, at, up = -right, -up, at
	elseif self.shape:getYAxis().z == -1 then
		localdir.x, localdir.y = localdir.y, -localdir.x
		--right, at, up = -up, -right, -at
	else -- lens is to top, assume the display side as up (pitch)
		localdir.x, localdir.y = localdir.y, -localdir.x
	end

	local pitch = math.atan2(localdir.x,localdir.z)/math.pi * 180
	local yaw = math.atan2(localdir.y,localdir.z)/math.pi * 180
	if pitch ~= pitch then pitch = 0 end -- nan check
	if yaw ~= yaw then yaw = 0 end

	return pitch, yaw
end


function Orienter.VecToEuler(self,  direction )
    local euler = {}
    euler.yaw = 180 + math.atan2(direction.y,direction.x)/math.pi * 180
    euler.pitch = math.acos(direction.z)/math.pi *180
    return euler --math.cos( direction.z * 0.5 * math.pi ) * 180 --
end

function Orienter.calcpitchandyaw(self, data)
	--targetdirection
	--local eye = data.direction
	local targetdirection = data.targetdirection:normalize()
	local direction = sm.shape.getUp(self.shape)
	local euler1 = VecToEuler(direction)
	local euler2 = VecToEuler(targetdirection)
	local yaw = euler2.yaw - euler1.yaw
	local pitch = euler2.pitch - euler1.pitch

	yaw = (yaw>180) and yaw-360 or (yaw<-180 and yaw+360 or yaw)
	if pitch ~= pitch then pitch = 0 end -- nan check
	if yaw ~= yaw then yaw = 0 end
	pitch, yaw = self:tiltadjust({pitch = pitch, yaw = yaw})
	return pitch, yaw
end

function Orienter.tiltadjust(self, data)
	local pitch = data.pitch
	local yaw = data.yaw
	local localX = sm.shape.getRight(self.shape) -- left side
	local localY = sm.shape.getAt(self.shape)-- up
	local localZ = sm.shape.getUp(self.shape)-- lens
	if math.abs(self.shape:getXAxis().z) == 1 then -- left side is on top/bottom  (aka lens forward, display sideways)
		-- get roll angle
		local roll = 90 - math.deg(math.acos(localY.z,-1,1))
		if localX.z < 0 then
			if localY.z < 0 then
				roll = -180 - roll
			else
				roll = 180 - roll
			end
		end
		if roll == roll then
			local vec = sm.vec3.rotateX(sm.vec3.new(0, pitch, yaw), math.rad(roll))
			pitch = vec.y
			yaw = vec.z
		end
	else --display/lens is on top/bottom   -- works for lens top, screen in ws direction, works for lens in ws, screen top.
			-- DOES NOT WORK FOR DISPLAY sideways and lens top!!!!!!
		-- get roll angle
		local roll = 90 - math.deg(math.acos(localX.z,-1,1))
		if localY.z < 0 then

			if localX.z < 0 then
				roll = -180 - roll
			else
				roll = 180 - roll
			end
		end
		if roll == roll then
			local vec = sm.vec3.rotateX(sm.vec3.new(0, pitch, yaw), math.rad(-roll))
			pitch = vec.y
			yaw = vec.z
		end
	end
	if pitch ~= pitch then pitch = 0 end -- nan check
	if yaw ~= yaw then yaw = 0 end
	return pitch, yaw
end


function predictmove(self, mypos, direction, targetpos, localcalc)--MINE --FINAL

	if self.mylastpos == nil then self.mylastpos = mypos end
	local myposcopy = mypos

	mypos = mypos + (mypos - self.mylastpos)/10
	local distance = (targetpos - mypos):length()
	if self.lasttargetposition == nil then self.lasttargetposition = targetpos end
	local v = (targetpos - self.lasttargetposition) * 40
	if self.lasttargetvelocity == nil then self.lasttargetvelocity = v end
	local a = (v - self.lasttargetvelocity) --* 25
	local spuddrop = sm.vec3.new(0,0,-5)
	local spudspeed = 130
	local targetrelativepos = targetpos - mypos
	local t = distance/spudspeed

	self.mylastpos = myposcopy

	if self.lastdistance == nil then self.lastdistance = distance end
	local deltadistance = distance-self.lastdistance

	local t = t + deltadistance/2
	targetrelativepos = targetrelativepos + v*(5/40) + a*(5/40)^2 -- targetrelativepos:normalize()*deltadistance*350
	if deltadistance < 0 then --going towards
		--targetrelativepos = targetrelativepos + v*(4/40) + a*(4/40)^2 -- - targetrelativepos:normalize()*deltadistance*(0.4002933*distance - 14.61877)
	else
		--targetrelativepos = targetrelativepos + v*(4/40) + a*(4/40)^2 -- - targetrelativepos:normalize()*deltadistance*(0.3109541*distance + 1.35159)
	end -- distance speed fix

	--distance reach fix:
	local supermagicmultiplier = math.min(100, -6.181747 + (140773.3 - -6.181747)/(1 + (distance/0.005479015)^0.7706603))
	local futuretarget = targetrelativepos + (v*t + (a-spuddrop)*t^2*sm.vec3.new(1,1,(1 + distance/(supermagicmultiplier*1666*self.lead/1))))

	self.lasttargetposition = targetpos
	self.lasttargetvelocity = v
	self.lastdistance = distance


	local pitch, yaw = self:calcpitchandyaw({direction = direction, targetdirection = futuretarget})
	if localcalc then
		pitch, yaw = self:calcpitchandyawlocal({direction = direction, targetdirection = futuretarget})
	end

	local massmultiplier = self.shape.body.mass/300

	if not self.lastyaw then self.lastyaw = yaw end
	self.yaw = yaw + (yaw - self.lastyaw)*self.damping/100
	self.lastyaw = yaw

	if not self.lastpitch then self.lastpitch = pitch end
	self.pitch = pitch + (pitch - self.lastpitch)*self.damping/100
	self.lastpitch = pitch



	self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
end




function Orienter.server_onFixedUpdate( self, dt )
	local allplayers = {}
	for k, player in pairs(sm.player.getAllPlayers()) do
		allplayers[player.id] = player
	end
	local allunits = {}
	for k, unit in pairs(_GETALLUNITS()) do
		allunits[unit.id] = unit
	end
	local parents = self.interactable:getParents()
	local eye = self
	local targetposition = nil
	local targetdir = nil
	local targetmass = nil
	if self.modetable[self.mode].savevalue ~= 8 then self.pitch = 0 end
	self.pose0 = 0.5
	self.pose1 = 1
	local whiteinput = nil
	local blackinput = nil
	local maxrange = math.huge
	local minrange = math.huge*-1
	local damping = nil
	local lead = nil
	local numberinputs = 0
	local isON = nil
	local occupied = nil
	for k,v in pairs(parents) do
		local _pType = v:getType()
		local _pUuid = tostring(v:getShape():getShapeUuid())
		local _pColor = tostring(v:getShape():getColor())
		local _pSteering = v:hasSteering()
		if not _pSteering and _pColor == "eeeeeeff" and _pType == "scripted" and _pUuid ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			if whiteinput == nil then whiteinput = 0 end
			whiteinput = whiteinput + v.power
		elseif _pColor == "222222ff" and _pType == "scripted" then
			if blackinput == nil then blackinput = 0 end
			blackinput = blackinput + v.power
		elseif _pColor == "7f7f7fff" and _pType == "scripted" then
			damping = (damping and damping or 0) + v.power
		elseif _pColor == "4a4a4aff" and _pType == "scripted" then
			lead = (lead and lead or 0) + v.power

		elseif not _pSteering and _pType == "scripted" and _pUuid ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
		--number input, not tickbutton
			if maxrange == math.huge then maxrange = 0 end
			if minrange == math.huge*-1 and numberinputs > 0 then minrange = 10000000 end

			if math.abs(v.power)/4 < minrange then minrange = math.abs(v.power)/4 end
			if maxrange<minrange then
				local h = minrange
				minrange = maxrange
				maxrange = h
			end
			if math.abs(v.power)/4 > maxrange then maxrange = math.abs(v.power)/4 end
			numberinputs = numberinputs + 1

		elseif _pSteering or _pType == "seat" or _pType == "steering" then
			--seat
			occupied = ( (occupied == nil or occupied) and v.active)

		elseif _pColor == "eeeeeeff" and (_pType ~= "scripted" or _pUuid == "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07") then
			-- exceptionlist input
			if v:isActive() then
				if not self.pressed then
					local id = self:getplayer({useexceptionlist = false, minrange = nil, maxrange = nil, offset = 1, tryid = nil, ignorejammers = true})
					if self.playerexceptions[id] == nil then
						self.playerexceptions[id] = true
					else
						self.playerexceptions[id] = nil
					end
				end
				self.pressed = true
			else
				self.pressed = false
			end

		elseif _pType ~= "scripted" then
			-- logic input
			if not (_pUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _pUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
				-- do not turn on/off when sensor input, sensor input can be used as new 'eye'
				isON = ( (isON == nil or isON) and v.power ~= 0)
			end
		end
	end
	if isON == nil then -- no logic, only active when no unoccupied seat
		isON = (occupied ~= false)
	end

	if occupied == nil then
		isON = (isON ~= false)
	elseif occupied == true then
		isON = occupied and (isON ~= false)
	elseif occupied == false then
		isON = (isON ~= false)
	end

	self.damping = (damping or 80)  -- default damping
	self.lead = (lead or 100)  -- default lead

	if not isON then
		self.pitch = 0
		self.yaw = 0
	end

	local mode = self.modetable[self.mode].savevalue

	local localmode = false
	if mode > 11 and mode < 20 then -- not future proof, when modes added this number needs to grow
		localmode = true
		if mode > 16 then mode = mode +1 end -- distance doens't have a localmode, skip it
		mode = mode - 9 -- 2 first modes do not have a 'local' mode, they're already local
		-- mode '12' -> 11-7 = 3--> player orient local
	end

	if (mode >= 20 and mode <= 28) then
		local id = self:getFarmbot({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput, fbot_data = FarmbotDetectorModes[mode]})
		if id ~= 0 and isON then
			for k, v in pairs(parents) do
				local _sUuid = tostring(v:getShape():getShapeUuid())
				if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
					eye = v -- sensor or smartsensor
				end
			end
			targetposition = allunits[id].character.worldPosition
			targetmass = allunits[id].character.mass
			targetdir = allunits[id].character.direction

			local targetdirection = (allunits[id].character.worldPosition - self.shape.worldPosition):normalize()
			local distance = (allunits[id].character.worldPosition - self.shape.worldPosition):length()

			local pitch, yaw = 0, 0
			pitch, yaw = self:calcpitchandyaw({direction = eye, targetdirection = targetdirection})

			self.pitch = pitch
			self.yaw = yaw
			self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
		else
			self.pitch = 0
			self.yaw = 0
			self.pose1 = 1
		end
	elseif mode == 1 then  -- orient world aka gyro aka tilt sensor
		--local pitch, yaw = self:calcpitchandyawlocal(sm.vec3.new(0,0,-1))
		local localX = -sm.shape.getRight(self.shape) -- right side
		local localY = -sm.shape.getAt(self.shape)-- up
		local localZ = -sm.shape.getUp(self.shape)-- _ underside

		-- get pitch angle
		local pitch = 90 - math.deg(math.acos(localY.z,-1,1))
		if localZ.z < 0 then
			if localY.z < 0 then
				pitch = -180 - pitch
			else
				pitch = 180 - pitch
			end
		end
		local roll = 90 - math.deg(math.acos(localX.z,-1,1))
		if localZ.z < 0 then
			if localX.z < 0 then
				roll = -180 - roll
			else
				roll = 180 - roll
			end
		end
		local pitch, yaw = -roll,-pitch
		if isON then
			self.pitch = pitch
			self.yaw = yaw
			local distance = (self.shape.worldPosition):length()
			self.pose1 = (1/(4*distance))<1 and 1/(4*distance) or 1
		else
			self.pitch = 0
			self.yaw = 0
			self.pose1 = 1
		end
		targetposition = sm.vec3.new(0,0,0)
		targetmass = 0
		targetdir = getLocal(self.shape, sm.vec3.new(0,0,-1))


	elseif mode == 2 then  -- orient world aka gyro aka tilt sensor  PREDICTIVE
		--local pitch, yaw = self:calcpitchandyawlocal(sm.vec3.new(0,0,-1))
		local localX = -sm.shape.getRight(self.shape) -- right side
		local localY = -sm.shape.getAt(self.shape)-- up
		local localZ = -sm.shape.getUp(self.shape)-- _ underside

		-- get pitch angle
		local pitch = 90 - math.deg(math.acos(localY.z,-1,1))
		if localZ.z < 0 then
			if localY.z < 0 then
				pitch = -180 - pitch
			else
				pitch = 180 - pitch
			end
		end
		local roll = 90 - math.deg(math.acos(localX.z,-1,1))
		if localZ.z < 0 then
			if localX.z < 0 then
				roll = -180 - roll
			else
				roll = 180 - roll
			end
		end
		local pitch, yaw = -roll,-pitch
		if isON then

			if not self.lastyaw then self.lastyaw = yaw end
			self.yaw = (self.lead/100)*yaw + (yaw - self.lastyaw)*self.damping*self.shape.body.mass/112
			self.lastyaw = yaw

			if not self.lastpitch then self.lastpitch = pitch end
			self.pitch = (self.lead/100)*pitch + (pitch - self.lastpitch)*self.damping*self.shape.body.mass/112
			self.lastpitch = pitch
			local distance = (self.shape.worldPosition):length()
			self.pose1 = (1/(4*distance))<1 and 1/(4*distance) or 1
		else
			self.pitch = 0
			self.yaw = 0
			self.pose1 = 1
		end
		targetposition = sm.vec3.new(0,0,0)
		targetmass = 0
		targetdir = getLocal(self.shape, sm.vec3.new(0,0,-1))

	elseif mode == 3 then  -- orient player
		--print('x:',self.shape:getXAxis())--left side
		--print('y:',self.shape:getYAxis())--display
		--print('z:',self.shape:getZAxis())--lens

		local id = self:getplayer({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput})
		if id ~= 0 and isON then
			for k, v in pairs(parents) do
				local _sUuid = tostring(v:getShape():getShapeUuid())
				if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
					eye = v -- sensor or smartsensor
				end
			end
			targetposition = allplayers[id].character.worldPosition
			targetmass = allplayers[id].character.mass
			targetdir = allplayers[id].character.direction

			local targetdirection = (allplayers[id].character.worldPosition - self.shape.worldPosition):normalize()
			local distance = (allplayers[id].character.worldPosition - self.shape.worldPosition):length()

			local pitch, yaw = 0,0
			if localmode then
				pitch, yaw = self:calcpitchandyawlocal({direction = eye, targetdirection = targetdirection})
			else
				pitch, yaw = self:calcpitchandyaw({direction = eye, targetdirection = targetdirection})
			end

			self.pitch = pitch
			self.yaw = yaw
			self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
		end

	elseif mode == 4 then  -- orient player  PREDICTIVE
		local id = self:getplayer({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput})
		if id ~= 0 and isON then
			for k, v in pairs(parents) do
				local _sUuid = tostring(v:getShape():getShapeUuid())
				if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
					eye = v -- sensor or smartsensor
				end
			end
			targetposition = allplayers[id].character.worldPosition
			targetdir = allplayers[id].character.direction
			targetmass = allplayers[id].character.mass
			predictmove(self, self.shape.worldPosition, eye, allplayers[id].character.worldPosition, localmode)
		end


	elseif mode == 5 and trackertrackers then  -- orient block
		--direction = sm.shape.getUp(self.shape)

		local id = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false})
		if id == 0 then
			id = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false, colorignore = true})
		end
		if id ~= 0 and isON then
			if #parents>0 then
				for k, v in pairs(parents) do
					local _sUuid = tostring(v:getShape():getShapeUuid())
					if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
						eye = v -- sensor or smartsensor
					end
				end
			end
			local targetShape = trackertrackers[id]:getTrackerShape()

			targetposition = targetShape.worldPosition
			targetmass = targetShape.mass
			-- targetdir = ... -- needs to be implemented still, needs rework of the tracker

			local targetdirection = (targetShape.worldPosition - self.shape.worldPosition):normalize()
			local distance = (targetShape.worldPosition - self.shape.worldPosition):length()
			local pitch, yaw = 0,0
			if localmode then
				pitch, yaw = self:calcpitchandyawlocal({direction = eye, targetdirection = targetdirection})
			else
				pitch, yaw = self:calcpitchandyaw({direction = eye, targetdirection = targetdirection})
			end
			self.yaw = yaw
			self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
			self.pitch = pitch
		end


	elseif mode == 6 and trackertrackers then  -- orient block PREDICTIVE

		local id = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false})
		if id == 0 then
			id = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false, colorignore = true})
		end
		if id ~= 0 and isON then
			if #parents>0 then
				for k, v in pairs(parents) do
					local _sUuid = tostring(v:getShape():getShapeUuid())
					if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
						eye = v -- sensor or smartsensor
					end
				end
			end
			local targetShape = trackertrackers[id]:getTrackerShape()

			targetposition = targetShape.worldPosition
			targetmass =targetShape.mass

			predictmove(self, self.shape.worldPosition, eye, targetShape.worldPosition, localmode)

		end


	elseif mode == 7 then  -- orient camera

		local id = self:getplayer({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput})

		for k, v in pairs(parents) do
			local _pType = v:getType()
			local _sUuid = tostring(v:getShape():getShapeUuid())
			if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
				eye = v -- sensor or smartsensor
			end
			--find input seats:
			if (_pType == "seat" or _pType == "steering") and v:isActive() then -- someone is inside the seat that is an input
				id = self:getplayer({centerpos = v:getShape().worldPosition, useexceptionlist = false, minrange = 0, maxrange = 1000000, ignorejammers = true})
			end
		end

		if id ~= 0 and isON then
			local hit , result = sm.physics.raycast(allplayers[id].character.worldPosition, allplayers[id].character.worldPosition + allplayers[id].character.direction*2000)

			targetposition = (hit and result.pointWorld or allplayers[id].character.worldPosition)
			if result.type == "character" then
				targetmass = result:getCharacter().mass
			elseif result.type == "body" then
				local weight = 0
				for k, v in pairs(result:getShape().body:getCreationBodies()) do
					weight = weight + v.mass
				end
				targetmass = weight
			end
			targetdir = allplayers[id].character.direction

			local targetdirection = allplayers[id].character.direction
			local pitch, yaw = 0,0
			if localmode then
				pitch, yaw = self:calcpitchandyawlocal({direction = eye, targetdirection = targetdirection})
			else
				pitch, yaw = self:calcpitchandyaw({direction = eye, targetdirection = targetdirection})
			end
			local distance = (targetposition - allplayers[id].character.worldPosition):length()

			self.yaw = yaw
			self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
			self.pitch = pitch

		end


	elseif mode == 9 then  -- orient player + tracker
		local closestplayer = self:getplayer({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput})
		local closesttracker = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false, colorignore = true})
		local closestmatchingtracker = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false})

		local closestdistance_player = (closestplayer ~= 0) and (self.shape:getWorldPosition() - allplayers[closestplayer].character.worldPosition):length() or math.huge
		local closestdistance_tracker = (closesttracker ~= 0) and  (self.shape:getWorldPosition() - trackertrackers[closesttracker]:getTrackerShape().worldPosition):length() or math.huge
		local closestdistance_matchingtracker = (closestmatchingtracker ~= 0) and  (self.shape:getWorldPosition() - trackertrackers[closestmatchingtracker]:getTrackerShape().worldPosition):length() or math.huge


		local distance = 0
		local tracking = nil
		local direction = nil

		if ((closestplayer ~= 0) or (closesttracker ~= 0) or (closestmatchingtracker ~= 0)) and isON then
			if closestmatchingtracker ~= 0 then
				tracking = trackertrackers[closestmatchingtracker]:getTrackerShape().worldPosition
				distance = closestdistance_matchingtracker
				targetmass = trackertrackers[closestmatchingtracker]:getTrackerShape().mass
				if closestplayer and closestdistance_player < closestdistance_matchingtracker then
					tracking = allplayers[closestplayer].character.worldPosition
					direction = allplayers[closestplayer].character.direction
					distance = closestdistance_player
					targetmass = allplayers[closestplayer].character.mass
				end
			elseif closesttracker ~= 0 and not closestmatchingtracker ~= 0 then
				tracking = trackertrackers[closesttracker]:getTrackerShape().worldPosition
				targetmass = trackertrackers[closesttracker]:getTrackerShape().mass
				distance = closestdistance_tracker
				if closestplayer ~= 0 and closestdistance_player < closestdistance_tracker then
					tracking = allplayers[closestplayer].character.worldPosition
					direction = allplayers[closestplayer].character.direction
					distance = closestdistance_player
					targetmass = allplayers[closestplayer].character.mass
				end
			else
				targetmass = allplayers[closestplayer].character.mass
				tracking = allplayers[closestplayer].character.worldPosition
				direction = allplayers[closestplayer].character.direction
				distance = closestdistance_player
			end

		--[[
			for k, v in pairs(parents) do
				if (tostring(v:getShape():getShapeUuid()) == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or tostring(v:getShape():getShapeUuid()) == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
					direction = sm.shape.getUp(v:getShape()) -- sensor or smartsensor
				end
			end]]

			if tracking ~= nil then
				targetposition = tracking
				targetdir = direction
				local targetdirection = (tracking - self.shape.worldPosition):normalize()
				local pitch, yaw = 0,0
				if localmode then
					pitch, yaw = self:calcpitchandyawlocal({direction = eye, targetdirection = targetdirection})
				else
					pitch, yaw = self:calcpitchandyaw({direction = eye, targetdirection = targetdirection})
				end

				self.yaw = yaw
				self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
				self.pitch = pitch
			end
		end

	elseif mode == 10 then  -- orient player + tracker predictive
		local closestplayer = self:getplayer({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput})
		local closesttracker = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false})
		local closestmatchingtracker = self:gettracker({minrange = minrange, maxrange = maxrange, frequency = whiteinput, offset = blackinput, ignorejammers = false})

		--print(closestplayer, closesttracker, closestmatchingtracker)
		local closestdistance_player = (closestplayer ~= 0) and (self.shape:getWorldPosition() - allplayers[closestplayer].character.worldPosition):length() or math.huge
		local closestdistance_tracker = (closesttracker ~= 0) and  (self.shape:getWorldPosition() - trackertrackers[closesttracker]:getTrackerShape().worldPosition):length() or math.huge
		local closestdistance_matchingtracker = (closestmatchingtracker ~= 0) and  (self.shape:getWorldPosition() - trackertrackers[closestmatchingtracker]:getTrackerShape().worldPosition):length() or math.huge


		local distance = 0
		local tracking = nil
		local direction = nil

		if ((closestplayer ~= 0) or (closesttracker ~= 0) or (closestmatchingtracker ~= 0)) and isON then
			if closestmatchingtracker ~= 0 then
				tracking = trackertrackers[closestmatchingtracker]:getTrackerShape().worldPosition
				distance = closestdistance_matchingtracker
				targetmass = trackertrackers[closestmatchingtracker]:getTrackerShape().mass
				if closestplayer and closestdistance_player < closestdistance_matchingtracker then
					tracking = allplayers[closestplayer].character.worldPosition
					direction = allplayers[closestplayer].character.direction
					distance = closestdistance_player
					targetmass = allplayers[closestplayer].character.mass
				end
			elseif closesttracker ~= 0 and not closestmatchingtracker ~= 0 then
				tracking = trackertrackers[closesttracker]:getTrackerShape().worldPosition
				distance = closestdistance_tracker
				targetmass = trackertrackers[closesttracker]:getTrackerShape().mass
				if closestplayer ~= 0 and closestdistance_player < closestdistance_tracker then
					tracking = allplayers[closestplayer].character.worldPosition
					direction = allplayers[closestplayer].character.direction
					distance = closestdistance_player
					targetmass = allplayers[closestplayer].character.mass
				end
			else
				tracking = allplayers[closestplayer].character.worldPosition
				direction = allplayers[closestplayer].character.direction
				distance = closestdistance_player
				targetmass = allplayers[closestplayer].character.mass
			end

			for k, v in pairs(parents) do
				if (tostring(v:getShape():getShapeUuid()) == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or tostring(v:getShape():getShapeUuid()) == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
					direction = sm.shape.getUp(v:getShape()) -- sensor or smartsensor
				end
			end

			if tracking ~= nil then
				targetposition = tracking
				targetdir = direction
				predictmove(self, self.shape.worldPosition, eye, tracking, localmode)
			end
		end
	elseif mode == 11 then  -- orient camera predictive

		local id = self:getplayer({useexceptionlist = true, minrange = minrange, maxrange = maxrange, offset = blackinput, tryid = whiteinput})

		for k, v in pairs(parents) do
			local _sUuid = tostring(v:getShape():getShapeUuid())
			local _pType = v:getType()
			if (_sUuid == "add3acc6-a6fd-44e8-a384-a7a16ce13c81" or _sUuid == "4081ca6f-6b80-4c39-9e79-e1f747039bec") then
				eye = v -- sensor or smartsensor
			end
			--find input seats:
			if (_pType == "seat" or _pType == "steering") and v:isActive() then -- someone is inside the seat that is an input
				id = self:getplayer({centerpos = v:getShape().worldPosition, useexceptionlist = false, minrange = 0, maxrange = 1000000, ignorejammers = true})

			end
		end

		if id ~= 0 and isON then
			local hit , result = sm.physics.raycast(allplayers[id].character.worldPosition, allplayers[id].character.worldPosition + allplayers[id].character.direction*2000)

			targetposition = (hit and result.pointWorld or allplayers[id].character.worldPosition)
			if result.type == "character" then
				targetmass = result:getCharacter().mass
			elseif result.type == "body" then
				local weight = 0
				for k, v in pairs(result:getShape().body:getCreationBodies()) do
					weight = weight + v.mass
				end
				targetmass = weight
			end
			targetdir = allplayers[id].character.direction

			local targetdirection = allplayers[id].character.direction
			local pitch, yaw = 0,0
			if localmode then
				pitch, yaw = self:calcpitchandyawlocal({direction = eye, targetdirection = targetdirection})
			else
				pitch, yaw = self:calcpitchandyaw({direction = eye, targetdirection = targetdirection})
			end
			local distance = (targetposition - allplayers[id].character.worldPosition):length()


			if not self.lastyaw then self.lastyaw = yaw end
			self.yaw = (self.lead/100)*yaw + (yaw - self.lastyaw)*self.damping*self.shape.body.mass/112
			self.lastyaw = yaw

			if not self.lastpitch then self.lastpitch = pitch end
			self.pitch = (self.lead/100)*pitch + (pitch - self.lastpitch)*self.damping*self.shape.body.mass/112
			self.lastpitch = pitch
			local distance = (self.shape.worldPosition):length()
			self.pose1 = (1/(4*distance))<1 and 1/(4*distance) or 1

		end


	end

	if self.power ~= 0 then
		if self.power ~= self.power then self.power = 0 end
		if math.abs(self.power) >= 3.3*10^38 then
			if self.power < 0 then self.power = -3.3*10^38 else self.power = 3.3*10^38 end
		end

		mp_setPowerSafe(self, self.power) -- when in distance mode
	else
		if self.pitch ~= self.pitch then self.pitch = 0 end
		if math.abs(self.pitch) >= 3.3*10^38 then
			if self.pitch < 0 then self.pitch = -3.3*10^38 else self.pitch = 3.3*10^38 end
		end

		mp_setPowerSafe(self, self.pitch / 180)
	end

	if self.yaw ~= self.lastpose0 then
		self.network:sendToClients("client_setPose", {pose = 0, level = 1-(self.yaw/360+0.5)})
	end
	if self.pose1 ~= self.lastpose1 then
		self.network:sendToClients("client_setPose", {pose = 1, level = self.pose1})
	end
	self.lastpose0 = self.yaw
	self.lastpose1 = self.pose1
	self.lastpos_tracked = direction
	if not orienters[self.id] then orienters[self.id] = {} end
	orienters[self.id].position = targetposition
	orienters[self.id].direction = targetdir
	orienters[self.id].mass = targetmass
end

function playerexists(player)
	return (player and player.character and player.character.worldPosition)
end

function Orienter.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	self.power = 0
	if sm.isHost and self.modetable[self.mode].savevalue == 8 then  -- orient distance
		local amountofparents = 0
		for k, v in pairs(parents) do
			if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[AI]] then
				amountofparents = amountofparents + 1
				self.power = self.power + (1/v:getPoseWeight(1))
			end
		end
		if amountofparents>0 then
			self.power = self.power/amountofparents
		end

	end
end

function Orienter.client_setServerDirection(self, id)
	if id == sm.localPlayer.getId() then
		self.network:sendToServer("server_setDirection", sm.localPlayer.getDirection())
	end
end
function Orienter.server_setDirection(self, direction)
	self.direction = direction
end

function Orienter.client_onUpdatee(self, dt)
	if not sm.isServer then return end

	self.interactable:setUvFrameIndex(self.modetable[self.mode].savevalue-1)
	self.interactable:setPoseWeight(0, self.pose0)
	self.interactable:setPoseWeight(1, self.pose1)
end


function predictmove_super(self, mypos, direction, targetpos) -- weird shit by mathematicial guy

	--v is the velocity of the target
	--a is the acceleration of the target
	--5 units/s^2 is the gravitational accel
	--130 units/s vb is the velocity of teh bullet
	--p is initial position of the target
	--relative to the viewpoint (assumed 0,0,0)
	local distance = (targetpos - mypos):length()
	--print(distance)
	if self.lasttargetposition == nil then self.lasttargetposition = targetpos end

	--local magicmultiplier =  1.056032 + (3.758452 - 1.056032)/(1 + (distance/9.677873)^1.425672)

	local v = (targetpos - self.lasttargetposition) * 40-- * magicmultiplier-- (a-b) = per tick, *40 = per sec

	if self.lasttargetvelocity == nil then self.lasttargetvelocity = v end
	local a = (v - self.lasttargetvelocity) * 1
	local ag = -5
	local vb = 130
	local p = targetpos - mypos

	local aa = 0.25 * (a.x^2 + a.y^2 + a.z^2 + ag^2) - 0.5*a.z*ag
	local bb = v.x*a.x + v.y*a.y + v.z*a.z - v.z*ag
	local cc = v.x^2 + v.y^2 + v.z^2 - vb^2 + p.x*a.x + p.y*a.y + p.z*a.z - p.z*ag
	local dd = p.x*v.x + p.y*v.y + p.z*v.z
	local ee = p.x^2 + p.y^2 + p.z^2

	local testSQRT = -1*(-4*(cc^2 - 3*bb*dd + 12*aa*ee)^3 + (2*cc^3 -
        9*cc*(bb*dd + 8*aa*ee) + 27*(aa*dd^2 + bb^2*ee))^2)

	local insideSQRT = testSQRT^(1/2)
	local outsideSQRT = 2*cc^3 - 9*bb*cc*dd + 27*aa*dd^2 + 27*bb^2*ee - 72*aa*cc*ee
	local magROOT = (insideSQRT^2 + outsideSQRT^2)^(1/2)
	local angleROOT = math.atan2(insideSQRT, outsideSQRT)
	local cubeROOT = magROOT^(1/3)*math.cos(angleROOT/3)
	local t = (-3*bb + 3^(1/2)*aa*((3*bb^2 - 8*aa*cc + 4*2^(2/3)*aa*cubeROOT)/
	aa^2)^(1/2) - (6)^(1/2)*
	aa*(-1*((-3*aa*bb^2 + 8*aa^2*cc + 2*2^(2/3)*aa^2*cubeROOT + (
    3*3^(1/2)*(bb^3 - 4*aa*bb*cc + 8*aa^2*dd))/((
    3*bb^2 - 8*aa*cc + 4*2^(2/3)*aa*cubeROOT)/aa^2)^(1/2))/aa^3))^(1/2))/(12*aa)
	local Vb = sm.vec3.new(0,0,0)

	if self.lastdistance == nil then self.lastdistance = distance end
	local deltadistance = distance-self.lastdistance


	--print(t)
	--print(distance/130, 'dist')
	--towards: 290:*100  360:*130    430:*160   540:*200
	--away: 320:*100  410:*130   510:*160    640:*200
	if deltadistance < 0 then --going towards
		p = p + v*(4/40) + a*0.5*(4/40)^2 - p:normalize()*deltadistance*(0.4002933*distance - 14.61877)
	else
		p = p + v*(4/40) + a*0.5*(4/40)^2 - p:normalize()*deltadistance*(0.3109541*distance + 1.35159)
	end
	--print(deltadistance*135)

	Vb.x = (p.x + v.x*t + 0.5*a.x*t^2)/t
	Vb.y = (p.y + v.y*t + 0.5*a.y*t^2)/t

	local supermagicmultiplier = math.min(100, -6.181747 + (140773.3 - -6.181747)/(1 + (distance/0.005479015)^0.7706603))
	--fix for angling up a bit more when far away
	Vb.z = (p.z + v.z*t + (2 + distance/(supermagicmultiplier*1000))*0.5*(a.z - ag)*t^2)/t
	--Vb.z = (p.z + v.z*t + 0.5*(a.z - ag)*t^2)/t



	self.lasttargetposition = targetpos
	self.lasttargetvelocity = v

	local euler1 = VecToEuler(direction)
	local euler2 = VecToEuler(Vb:normalize())

	local pitch = euler2.pitch - euler1.pitch
	local yaw = euler2.yaw - euler1.yaw

	yaw = (yaw>180) and yaw-360 or (yaw<-180 and yaw+360 or yaw)

	self.power = pitch/180
	self.pose0 = 1-(yaw/360+0.5)
	self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
	self.lastdistance = distance
	--self.power = 0
	--self.pose0 = 0.5
	--self.pose1 = 1
end

function predictmove_test(self, mypos, direction, targetpos) -- crap
	-- spud speed: 130 U / sec
	-- spud drop: 5 U / sec²
	if self.lasttargetposition == nil then self.lasttargetposition = targetpos end

	--local distance = (targetpos - mypos):length()

	-- 40: *7, 110: *9, 400: *35

	local target_walking_direction = (targetpos - self.lasttargetposition) * 40*1.2 --:normalize()
	--local target_walking_speed = target_walking_direction:length() / 40
	local target_future_position = targetpos + target_walking_direction/40
	local distance_future_position = (target_future_position - mypos):length()
	local spud_time = distance_future_position / 130
	local final_future_position = target_future_position + target_walking_direction * spud_time


	local target_direction = (final_future_position - mypos):normalize()

	local euler1 = VecToEuler(direction)
	local euler2 = VecToEuler(target_direction)

	local pitch = euler2.pitch - euler1.pitch
	local yaw = euler2.yaw - euler1.yaw

	yaw = (yaw>180) and yaw-360 or (yaw<-180 and yaw+360 or yaw)

	self.power = pitch/180
	self.pose0 = (yaw/360+0.5)
	self.pose1 = ((1/(4*distance_future_position)) and 1/(4*distance_future_position) or 1)

	self.lasttargetposition = targetpos
end

function predictmove_old(self, mypos, direction, targetpos, lastdirection)


	local distance = (targetpos - mypos):length()
	local targetdirection = (targetpos - mypos)
	targetdirection.z = targetdirection.z + (distance*distance) / 3060 -- account for potatodrop
	targetdirection = targetdirection:normalize()

	local euler1 = VecToEuler(direction)
	local euler2 = VecToEuler(targetdirection)
	if self.lasttargetdirection == nil then self.lasttargetdirection = targetdirection end
	local euler3 = VecToEuler(self.lasttargetdirection)
	self.lasttargetdirection = targetdirection
	local pitch = euler2.pitch - euler1.pitch + (euler2.pitch - euler3.pitch)*(distance^(5/9))*2.65
	local yaw = euler2.yaw - euler1.yaw + (euler2.yaw - euler3.yaw)*(distance^(5/9))*2.65
	--(distance^(5/9))*2.55
	while yaw> 180 do yaw = yaw - 360 end
	while yaw< -180 do yaw = yaw + 360 end
	--yaw = (yaw>180) and yaw-360 or (yaw<-180 and yaw+360 or yaw)

	self.power = pitch/180
	self.pose0 = (yaw/360+0.5)
	self.pose1 = ((1/(4*distance)) and 1/(4*distance) or 1)
end


function Orienter.cl_setMode(self, params)
	if sm.isServer then return end
    self.mode_client = params.mode
	self.interactable:setUvFrameIndex(params.uvIndex)
end

function Orienter.client_setPose(self, data)
	if sm.isServer then return end

	--dealing with NaN and Inf
	local _normVal = math.min(1, math.max(data.level, 0))
	self.interactable:setPoseWeight(data.pose, _normVal)
end

function nojammercloseby(pos)
	for k,v in pairs(jammerjammers or {}) do
		if v and sm.exists(v) then
			-- the following will do an error upon loading the world:
			if v.active and sm.vec3.length(pos - v.shape.worldPosition) < 5 then --5 units = 20 blocks
				-- hide error:
				return false
			end
		else
			table.remove(jammerjammers, k)
		end
	end
	return true
end

function VecToEuler( direction )
    local euler = {}
    euler.yaw = 180 + math.atan2(direction.y,direction.x)/math.pi * 180
    euler.pitch = math.acos(direction.z)/math.pi *180
    return euler --math.cos( direction.z * 0.5 * math.pi ) * 180 --
end
