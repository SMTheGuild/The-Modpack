-- SmartTimer.lua --

--print("[SmartTimer] file init")

dofile("globalgui.lua")
dofile("functions.lua")

SmartTimer = class( nil )
SmartTimer.maxChildCount = -1
SmartTimer.maxParentCount = -1
SmartTimer.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartTimer.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartTimer.colorNormal = sm.color.new( 0x404040ff )
SmartTimer.colorHighlight = sm.color.new( 0x606060ff )



function SmartTimer.client_onSetupGui( self )
	do return end -- Currently does not use GUIs. Will be added in a future update
    
    
    if sm.globalgui.wasCreated(self, SmartTimer.gui) then return end
    SmartTimer.gui = sm.globalgui.create(self, "Smart Timer", 1100, 700, nil, nil, nil, nil, nil)
    debug("creatng gui")
	
    local bgx, bgy = SmartTimer.gui.bgPosX, SmartTimer.gui.bgPosY 
    
    --local tbTicks = sm.globalgui.textBox(bgx + 0, bgy + 0, 100, 50, "") 
    local labelTicks = sm.globalgui.label(bgx + 300, bgy + 300, 100, 50, "0", nil, nil, nil, false)
     
    --SmartTimer.gui:addItemWithId("tbTicks", tbTicks)
    SmartTimer.gui:addItemWithId("labelTicks", labelTicks)
    
    
    
    
    
    
    
    local timerGui = sm.gui.load("TimerGui.layout", true)
    local timerBG = timerGui:find("Background")
    --local timerTitle = timerGui:find("Title")
    local timerSliderLeft = timerGui:find("Seconds")
    local timerSliderRight = timerGui:find("Ticks")
    local timerContainer = timerGui:find("Container")
    local timerSecondsDisplay = timerGui:find("SecondsDisplay")
    local timerMillisecondsDisplay = timerGui:find("MillisecondsDisplay")
    local timerTickDisplay = timerGui:find("TickDisplay")
    
    local timerBG_width, timerBG_height = timerBG:getSize()
    local screen_width, screen_height = sm.gui.getScreenSize()
    local scale_width, scale_height = (screen_width/2560), (screen_height/1440) -- I made this script on a 2560x1440 monitor. Scale = 1 when using a monitor with that resolution.
    
    timerGui:setSize(timerBG_width, timerBG_height)
    timerGui:setPosition(screen_width/2 - timerBG_width/2, screen_height/2 - timerBG_height/2)
    timerGui:setVisible(true)
    --timerTitle:setText("DELAY")
    
    --timerContainer:setPosition(
    --    select(1, timerContainer:getPosition()),
    --    select(2, timerSliderLeft:getPosition())
    --)
    local timerContainerIncrement = select(1, timerContainer:getSize())
    
    timerContainer:setPosition(timerSliderLeft:getPosition())
    timerContainer:setSize(
        select(1, timerSliderRight:getPosition()) - select(1, timerSliderLeft:getPosition()) + select(1, timerSliderRight:getSize()),
        select(2, timerContainer:getSize())
    )
    
    timerContainerIncrement = select(1, timerContainer:getSize()) - timerContainerIncrement
    
    timerSliderLeft.visible = false
    timerSliderRight.visible = false
    
    local extraCharWidth = 3 * 54 * scale_width -- Captured on 2560x1440 and measured using Adobe Photoshop
    
    timerSecondsDisplay:setText("00000.")
    timerSecondsDisplay:setSize(
        select(1, timerSecondsDisplay:getSize()) + timerContainerIncrement - (timerContainerIncrement - extraCharWidth)/2,
        select(2, timerSecondsDisplay:getSize())
    )
    
    timerMillisecondsDisplay:setText("000s")
    timerMillisecondsDisplay:setPosition(
        select(1, timerMillisecondsDisplay:getPosition()) + timerContainerIncrement - (timerContainerIncrement - extraCharWidth)/2,
        select(2, timerMillisecondsDisplay:getPosition())
    )
    
    timerTickDisplay:setText("0 Ticks")
    timerTickDisplay:setSize(
        select(1, timerContainer:getSize()),
        select(2, timerTickDisplay:getSize())
    )
    
    
    
    
    SmartTimer.timerGui = timerGui
end



-- Gets called when the tiemr gets created
function SmartTimer.server_onCreate( self )
    self.delay = self.data.defaultDelay
    self:server_clearTimer(self.delay)
    self:server_createRemoteGuiInstance()
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
        if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] and tostring(v:getShape():getShapeUuid()) ~= "c7a99aa6-c5a4-43ad-84c9-c85f7d842a93" --[[laser]] then
            -- number
            if tostring(v:getShape():getColor()) == "eeeeeeff" or -- white
               tostring(v:getShape():getColor()) == "222222ff" then -- black
                delay = (delay or 0) + math.ceil(v.power)
            else
                input = input + (sm.interactable.getValue(v) or v.power)
            end
        else
            --logic input
            if tostring(v:getShape():getColor()) == "eeeeeeff" then -- white 
                clear = clear or v.active
            elseif tostring(v:getShape():getColor()) == "222222ff" then -- black
                tick = tick or v.active
            elseif tostring(v:getShape():getColor()) == "7f7f7fff" or -- light grey
                   tostring(v:getShape():getColor()) == "4a4a4aff" then -- dark grey
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
    self.interactable.power = self.states[#self.states]
    self.interactable.active = self.states[#self.states] ~= 0
    
    sm.interactable.setValue(self.interactable, self.states[#self.states])
end


 

-------------------------------- GUI stuff --------------------------------
function SmartTimer.server_createRemoteGuiInstance( self )
	do return end -- Disabled because GUIs are not implemented for this block yet
	debug("server create")
    sm.globalgui.createRemote(SmartTimer, self)
end

--function SmartTimer.client_onInteract( self )
--	if not SmartTimer.gui then
--        sm.gui.displayAlertText("#ff0000Failed to open gui (it does not exist)")
--        return 
--    end 
--    
--	SmartTimer.gui:show()
--    
--end  

-- GLOBALGUI.LUA requires these function to exist.
function SmartTimer.client_onUpdate( self, dt ) end
function SmartTimer.client_onRefresh( self ) self:client_onCreate() end
function SmartTimer.server_onRefresh( self ) self:server_onCreate() end
-- Optional
function SmartTimer.client_onDestroy(self) if SmartTimer.gui then SmartTimer.gui:setVisible(false, true) end end
-------------------------------- End of GUI stuff --------------------------------




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
        if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] and tostring(v:getShape():getShapeUuid()) ~= "c7a99aa6-c5a4-43ad-84c9-c85f7d842a93" --[[laser]] then
            -- number
            if tostring(v:getShape():getColor()) == "eeeeeeff" or -- white
               tostring(v:getShape():getColor()) == "222222ff" then -- black
                delay = (delay or 0) + math.ceil(v.power)
            else
                input = input + (sm.interactable.getValue(v) or v.power)
            end
        else
            --logic input
            if tostring(v:getShape():getColor()) == "eeeeeeff" then -- white 
                clear = clear or v.active
            elseif tostring(v:getShape():getColor()) == "222222ff" then -- black
                tick = tick or v.active
			elseif tostring(v:getShape():getColor()) == "7f7f7fff" or -- light grey
                   tostring(v:getShape():getColor()) == "4a4a4aff" then -- dark grey
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





















--function printUnsafeTable(t)
--    local ts = "{"
--    for k,v in pairs(t) do
--        ts = ts .. tostring(v) .. ", "
--    end
--    ts = string.sub(ts, 0, -3) .. "}"
--    debug(ts)
--end

function round(x)
    if x%2 ~= 0.5 then
        return math.floor(x+0.5)
    end
    return x-0.5
end