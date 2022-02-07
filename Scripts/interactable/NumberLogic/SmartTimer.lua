--[[
	Copyright (c) 2020 Modpack Team
	TechnologicNick#4045 / Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading SmartTimer.lua")

-- SmartTimer.lua --
SmartTimer = class( nil )
SmartTimer.maxChildCount = -1
SmartTimer.maxParentCount = -1
SmartTimer.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartTimer.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartTimer.colorNormal = sm.color.new( 0x404040ff )
SmartTimer.colorHighlight = sm.color.new( 0x606060ff )


-- Gets called when the tiemr gets created
function SmartTimer.server_onCreate( self )
    self.delay = self.data.defaultDelay
    self:server_clearTimer(self.delay)
end

-- Gets called every tick
function SmartTimer.server_onFixedUpdate( self, timeStep )
    -- Sets the default values of the parameters
    local clear = false
    local tick = nil
    local delay = nil
    local input = 0
    
    
    -- Reads the outputs of the parents to use as parameters for the timer
    local parents = self.interactable:getParents()
    for k,v in pairs(parents) do
        local _pColor = tostring(v:getShape():getColor())
        if not v:hasSteering() and v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
            -- number
            if _pColor == "eeeeeeff" or -- white
            _pColor == "222222ff" then -- black
                delay = (delay or 0) + math.ceil(v.power)
            else
                input = input + (sm.interactable.getValue(v) or v.power)
            end
        else
            --logic input
            if _pColor == "eeeeeeff" then -- white 
                clear = clear or v.active
            elseif _pColor == "222222ff" then -- black
                tick = tick or v.active
            elseif _pColor == "7f7f7fff" or -- light grey
            _pColor == "4a4a4aff" then -- dark grey
                -- Reserved for future use
			else
				input = input + (v.active and 1 or 0)
            end
        end
    end
    
    if tick == nil then
        tick = true
    end
    
    if delay == nil then
        delay = self.data.defaultDelay
    end
    delay = math.min(72000, math.max(1, delay))
    
    -- Modifies the array length to match the new delay. Removes or inserts values at the end of the array.
    if delay ~= self.delay then
        self:server_changeTimerDelay(delay)
    end
    
    -- Clears the array if the clear flag is active
    if clear then
        self:server_clearTimer(delay)
    end
    
    if not clear and tick then
        -- Updates the timer
        local output = self:server_updateTimer(input)
    end
    
    --print(tick)
    --printUnsafeTable(self.states)
    
    -- Sets the outputs
    local current_state = self.states[#self.states]
    mp_updateOutputData(self, current_state, current_state ~= 0)
end


-- Clears the timer and creates an empty array
function SmartTimer.server_clearTimer( self, delay )
    self.states = {}
    
    for i = 1, delay do
        self.states[i] = 0
    end
end

-- Updates the timer and shifts all the values to the next key. Returns the last value of the array.
function SmartTimer.server_updateTimer( self, input )
    
    table.remove(self.states, #self.states)
    table.insert(self.states, 1, input)
    
    --printUnsafeTable(self.states)
    
    return self.states[#self.states]
end

-- Modifies the array length to match the new delay. Removes or inserts values at the end of the array.
function SmartTimer.server_changeTimerDelay( self, newDelay )
    while #self.states < newDelay do
        table.insert(self.states, 0)
        --print("Increased delay by 1")
    end
    while #self.states > newDelay do
        local removed = table.remove(self.states, 1)
        --print("Removed", removed, "from the table")
    end
    self.delay = newDelay
end




-------------------------------- Client calculations --------------------------------

-- Resets default variables
function SmartTimer:client_onCreate()
    self.statesClient = {}
    self.delayClient = nil
	self.writing = false
end

function SmartTimer.client_onFixedUpdate( self, timeStep )
    -- Sets the default values of the parameters
    local clear = false
    local tick = nil
    local delay = nil
    local input = 0
    
    
    -- Reads the outputs of the parents to use as parameters for the timer
    local parents = self.interactable:getParents()
    for k,v in pairs(parents) do
        local _pColor = tostring(v:getShape():getColor())
        if not v:hasSteering() and v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
            -- number
            if _pColor == "eeeeeeff" or -- white
            _pColor == "222222ff" then -- black
                delay = (delay or 0) + math.ceil(v.power)
            else
                input = input + (sm.interactable.getValue(v) or v.power)
            end
        else
            --logic input
            if _pColor == "eeeeeeff" then -- white 
                clear = clear or v.active
            elseif _pColor == "222222ff" then -- black
                tick = tick or v.active
			elseif _pColor == "7f7f7fff" or -- light grey
            _pColor == "4a4a4aff" then -- dark grey
                -- Reserved for future use
			else
				input = input + (v.active and 1 or 0)
            end
        end
    end
    
    if tick == nil then
        tick = true
    end
    
    if delay == nil then
        delay = self.data.defaultDelay
    end
    delay = math.min(72000, math.max(1, delay))
    
    -- Modifies the array length to match the new delay. Removes or inserts values at the end of the array.
    if delay ~= self.delayClient then
        self:client_changeTimerDelay(delay)
    end
    
    -- Clears the array if the clear flag is active
    if clear then
        self:client_clearTimer(delay)
    end
    
    if not clear and tick then
		-- update writing mode if value different from previous value
		if input ~= self.lastinput and self.lastinput then self.writing = not self.writing end
        local output = self:client_updateTimer(self.writing)
		self.lastinput = input
    end
    
    self:client_updateUv()
end

-- Clears the timer and creates an empty array
function SmartTimer.client_clearTimer( self, delay )
    self.statesClient = {}
    
    for i = 1, delay do
        self.statesClient[i] = false
    end
end

-- Updates the timer and shifts all the values to the next key. Returns the last value of the array.
function SmartTimer.client_updateTimer( self, input )
    
    table.remove(self.statesClient, #self.statesClient)
    table.insert(self.statesClient, 1, input)
    
    --printUnsafeTable(self.states)
    
    return self.statesClient[#self.statesClient]
end

-- Modifies the array length to match the new delay. Removes or inserts values at the end of the array.
function SmartTimer.client_changeTimerDelay( self, newDelay )
    while #self.statesClient < newDelay do
        table.insert(self.statesClient, false)
        --print("Increased delay by 1")
    end
    while #self.statesClient > newDelay do
        local removed = table.remove(self.statesClient, 1)
        --print("Removed", removed, "from the table")
    end
    self.delayClient = newDelay
end

-- Calculates the UvFrameIndex
function SmartTimer.client_updateUv( self )
    local length = #self.statesClient
    local step = 10/length
    
    local output = {}
    
    for x = 1, 10, math.min(1, step) do
        output[math.ceil(x)] = output[math.ceil(x)] or self.statesClient[math.ceil(x/step)]
    end
    
    local index = 0
    for k, v in pairs(output) do
        index = index + (v and 2^(k-1) or 0)
    end
    self.interactable:setUvFrameIndex(index)
end

