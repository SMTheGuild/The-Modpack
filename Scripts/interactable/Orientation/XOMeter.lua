-- Copyright (c) 2018 Lord Pain & Brent Batch --

--[[
    Copyright (c) 2020 Modpack Team
    Brent Batch#9261 / Lord Pain
]]--
dofile "../../libs/load_libs.lua"

XOMeter = class( nil )
XOMeter.maxChildCount = -1
XOMeter.maxParentCount = -1
XOMeter.connectionInput = sm.interactable.connectionType.power
XOMeter.connectionOutput = sm.interactable.connectionType.power
XOMeter.colorNormal = sm.color.new( 0x76034dff )
XOMeter.colorHighlight = sm.color.new( 0x8f2268ff )
XOMeter.poseWeightCount = 2

XOMeter.modetable = {
    {savevalue = 1,  texturevalue = 0,  icon = "speed",    name = "speed",          description= "Speed in any direction (blocks/second)"},
    {savevalue = 7,  texturevalue = 12, icon = "velocity", name = "velocity",       description= "Speed in a direction (the 'normal' through the meter)"},
    {savevalue = 2,  texturevalue = 2,  icon = "accel-\neration", name="acceleration", description= "Acceleration (blocks/second²)"},
    {savevalue = 3,  texturevalue = 4,  icon = "altitude", name = "altitude",       description= "The current height in blocks"},
    {savevalue = 4,  texturevalue = 6,  icon = "pos x", name = "pos x",                 description= "Current X position in blocks"},
    {savevalue = 5,  texturevalue = 8,  icon = "pos y", name = "pos y",                 description= "Current Y position in blocks"},
    {savevalue = 6,  texturevalue = 10, icon = "compass", name = "compass",         description= "Rotation relative to north (+Y)"},
    {savevalue = 11, texturevalue = 1,  icon = "rotation", name = "rotation",       description= "Rotation around placed axis"},
    {savevalue = 8,  texturevalue = 14, icon = "degree/s", name = "degree/s",       description= "Angular speed in degrees per second (use it as a 'wheel')"},
    {savevalue = 10, texturevalue = 18, icon = "mass", name = "creation mass",      description= "Current mass in the whole creation"},
    {savevalue = 9,  texturevalue = 16, icon = "display", name = "display",         description= "Can display any input number on the display, white number input defines 'max' (default: 100)"},
}
XOMeter.savemodes = {}
for k,v in pairs(XOMeter.modetable) do
   XOMeter.savemodes[v.savevalue]=k
end

XOMeter.mode = 1


function XOMeter.server_onRefresh( self )
    sm.isDev = true
    self:server_onCreate()
end
function XOMeter.server_onCreate( self )
    self.oldSpeed = sm.vec3.new(0,0,0)

    local stored = self.storage:load()
    if stored and type(stored) == "number" then
        self.mode = XOMeter.savemodes[stored]
    end
    self.storage:save(self.modetable[self.mode].savevalue)

end


function XOMeter.server_onFixedUpdate( self, timeStep )
    local power = 0

    local mode = self.modetable[self.mode].savevalue

    if mode == 1 then --speedometer
        power = self.shape.velocity:length()*4

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local v_shape_id = v.shape.id
                    local orienter = orienters[v_shape_id]
                    if orienter and orienter.position then
                        power = ( orienter.position - (orienter.oldPos or orienter.position) ):length() / timeStep * 4

                        orienters[v_shape_id].oldPos = sm.vec3.new(0,0,0) + orienter.position -- (anti reference)
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 2 then  --accelerometer

        local hasorients = false
        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    hasorients = true

                    local v_shape_id = v.shape.id
                    local orienter = orienters[v_shape_id]
                    if orienter and orienter.position then
                        local speed = orienter.position - (orienter.oldPos or orienter.position)
                        local old_speed = speed - (orienter.oldSpeed or sm.vec3.zero())

                        power = runningAverage( self,  math.abs(old_speed:length() / timeStep) * 4 )

                        orienters[v_shape_id].oldPos   = sm.vec3.new(0,0,0) + orienter.position -- (anti reference)
                        orienters[v_shape_id].oldSpeed = sm.vec3.new(0,0,0) + speed -- (anti reference)
                    else
                        power = 0
                    end
                end
            end
        end

        if not hasorients then
            power = runningAverage(self, math.abs((self.shape.velocity - self.oldSpeed):length())/timeStep*4)
        end

    elseif mode == 3 then -- z pos
        power = self.shape.worldPosition.z*4 -- *4, from units to blocks

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local orienter = orienters[v.shape.id]
                    if orienter and orienter.position then
                        power = orienter.position.z * 4
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 4 then -- x pos
        power = self.shape.worldPosition.x*4

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local orienter = orienters[v.shape.id]
                    if orienter and orienter.position then
                        power = orienter.position.x * 4
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 5 then -- y pos
        power = self.shape.worldPosition.y*4

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local orienter = orienters[v.shape.id]
                    if orienter and orienter.position then
                        power = orienter.position.y * 4
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 6 then -- compass
        local localY = sm.shape.getAt(self.shape)
        local localZ = sm.shape.getUp(self.shape)--up
        local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
        localY = rot*localY
        power = math.atan2(-localY.x,localY.y)/math.pi * 180

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local orienter = orienters[v.shape.id]
                    if orienter and orienter.position and orienter.direction then
                        power = math.atan2(-orienter.direction.x, orienter.direction.y) / math.pi * 180
                        --value = 50+self.power/2.7
                        --if self.shape:getZAxis().z < 0 then
                        --    value = 50-self.power/2.7
                        --end
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 7 then -- velocity
        power = sm.shape.getUp(self.shape):dot(self.shape.velocity)*-4

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local v_shape_id = v.shape.id
                    local orienter = orienters[v_shape_id]
                    if orienter and orienter.position and orienter.direction then
                        power = orienter.direction:dot(( orienter.position - (orienter.oldPos or orienter.position) ) /timeStep *4)

                        orienters[v_shape_id].oldPos = sm.vec3.new(0,0,0) + orienter.position -- (anti reference)
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 8 then -- degrees per sec
        local dps = getLocal(self.shape, self.shape.body.angularVelocity)
        power = -math.deg(dps.z)

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local v_shape_id = v.shape.id
                    local orienter = orienters[v_shape_id]
                    if orienter and orienter.position and orienter.direction then
                        local angle = math.atan2(-orienter.direction.x, orienter.direction.y) / math.pi * -180
                        
                        power = angle - (orienter.oldAngle or angle)

                        orienters[v_shape_id].oldAngle = angle
                        --value = 50 + self.power/2.7
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 9 then -- gauge

        local parents = self.interactable:getParents()
        local maxvalue = 100
        local number = 0
        local hasmax = false
        for k, v in pairs(parents) do
            if tostring(v.shape.color) == "eeeeeeff" then
                if not hasmax then maxvalue = 0 end
                hasmax = true
                maxvalue = maxvalue + v.power
            else
                number = number + v.power
            end
        end

        if maxvalue == 0 then maxvalue = 100 end
        maxvalue = maxvalue/100
        power = number/maxvalue

        if orienters ~= nil then
            for k, v in pairs(parents) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    power = 0
                end
            end
        end

    elseif mode == 10 then -- mass
        local weight = 0
        for k, v in pairs(self.shape.body:getCreationBodies()) do
            weight = weight + v.mass
        end
        power = weight

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    local orienter = orienters[v.shape.id]
                    if orienter then
                        power = orienter.mass or 0
                        --value = orienters[v:getShape().id].mass/10
                    else
                        power = 0
                    end
                end
            end
        end

    elseif mode == 11 then -- orient

        local localX = self.shape.right -- right
        local localY = self.shape.at -- up
        local localZ = self.shape.up -- displayup

        local placedZ = self.shape:getZAxis()
        local pitch = math.acos(localZ.z) / math.pi * 180 - 90

        --print(localX)
        if math.abs(placedZ.z) == 1 then -- placed pointing up
            local rot = sm.vec3.getRotation(localZ, placedZ)
            localY = rot*localY
            power = math.atan2(-localY.x,localY.y)/math.pi * 180
            --value = 50+power/2.7
            --if placedZ.z < 0 then
            --    value = 50-self.power/2.7
            --end
        elseif sm.vec3.new(0,0,1):cross(localZ):length()>0.001 then--avoid error
            local fakeX = sm.vec3.new(0,0,1):cross(localZ):normalize()
            local fakeY = localZ:cross(fakeX)
            local relativerot = sm.vec3.new(fakeX:dot(localY), fakeY:dot(localY), localZ:dot(localY))
            power = math.atan2(relativerot.x,relativerot.y)/math.pi * 180

            --value = 50-self.power/2.7
        end
        --elseif math.abs(placedZ.y) == 1 then -- placed pointing towards sun
        --    self.power = math.atan2(-localY.x,localY.z)/math.pi * 180
        --    value = 50+self.power/2.7
        --    if placedZ.y > 0 then
        --        value = 50-self.power/2.7
        --    else
        --        self.power = 0-self.power
        --    end
        --else -- placed sideways
        --    self.power = math.atan2(-localY.y,localY.z)/math.pi * 180
        --    value = 50+self.power/2.7
        --    if placedZ.x < 0 then
        --        value = 50-self.power/2.7
        --    else
        --        self.power = 0-self.power
        --    end
        --end

        if orienters ~= nil then
            for k, v in pairs(self.interactable:getParents()) do
                if tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
                    power = 0
                end
            end
        end
    end

    self.oldSpeed = self.shape.velocity
    
    mp_setPowerSafe(self, power)
    --self.network:sendToClients("client_PosenUV", { posevalue = value, uv = self.modetable[self.mode].texturevalue } )
end


function XOMeter.sv_setMode(self, params)
    self.mode = params.mode
    self.storage:save(self.modetable[self.mode].savevalue)
    self:server_sendModeToClient(true)
end

function XOMeter.server_sendModeToClient(self, snd)
    self.network:sendToClients("client_newMode", {mode = self.mode, sound = snd})
end


function XOMeter.client_canInteract(self)
    local use_key = mp_gui_getKeyBinding("Use", true)
    sm.gui.setInteractionText("Press", use_key, "to select the meter mode")

    return true
end

function XOMeter.client_newMode(self, data)
    self.mode_client = data.mode
    if data.sound then
        sm.audio.play("GUI Item drag", self.shape:getWorldPosition())
    end
end

function XOMeter.client_onCreate(self)
    self.mode_client = 1
    self.network:sendToServer("server_sendModeToClient")
end

function XOMeter.client_onDestroy(self)
    self:client_onGuiDestroyCallback()
end

function XOMeter.client_onFixedUpdate(self, dt)

    local mode = self.modetable[self.mode_client]
    local sInteractable = self.interactable

    sInteractable:setUvFrameIndex(mode.texturevalue)

    if mode.savevalue == 3 then --z pos

        local one = (math.sin(0-2*math.pi*(sInteractable.power/3+17)/134)+1)/2
        local two = (math.cos(2*math.pi*(sInteractable.power/3+17)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)

    elseif mode.savevalue == 4 or mode.savevalue == 5 then -- x pos , y pos

        local one = (math.sin(0-2*math.pi*(sInteractable.power/14+67)/134)+1)/2
        local two = (math.cos(2*math.pi*(sInteractable.power/14+67)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)

    elseif mode.savevalue == 6 then -- compass thingy
        --local localX = sm.shape.getRight(self.shape)
        local localY = sm.shape.getAt(self.shape)
        local localZ = sm.shape.getUp(self.shape)--up
        local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
        localY = rot*localY*-1

        sInteractable:setPoseWeight(0 ,(localY.x+1)/2)
        sInteractable:setPoseWeight(1 ,(localY.y+1)/2)


    elseif mode.savevalue == 7 then -- velocity

        local one = (math.sin(0-2*math.pi*(sInteractable.power/4+67)/134)+1)/2
        local two = (math.cos(2*math.pi*(sInteractable.power/4+67)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)

    elseif mode.savevalue == 8 then --rpm

        local one = (math.sin(0-2*math.pi*(sInteractable.power+67)/134)+1)/2
        local two = (math.cos(2*math.pi*(sInteractable.power+67)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)

    elseif mode.savevalue == 10 then --mass

        local one = (math.sin(0-2*math.pi*(sInteractable.power/10+7)/134)+1)/2
        local two = (math.cos(2*math.pi*(sInteractable.power/10+7)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)

    elseif mode.savevalue == 11 then -- orient

        local value = 50-sInteractable.power/2.7
        
        if self.shape:getZAxis().z < 0 then
            value = 50+sInteractable.power/2.7
        end

        local one = (math.sin(0-2*math.pi*(value+17)/134)+1)/2
        local two = (math.cos(2*math.pi*(value+17)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)

    else
        local one = (math.sin(0-2*math.pi*(sInteractable.power+17)/134)+1)/2
        local two = (math.cos(2*math.pi*(sInteractable.power+17)/134)+1)/2
        --print(self.posevalue, one, two)
        sInteractable:setPoseWeight(0 ,one)
        sInteractable:setPoseWeight(1 ,two)
    end
end

function XOMeter.client_onGuiDestroyCallback(self)
    local s_gui = self.gui
    if s_gui and sm.exists(s_gui) then
        if s_gui:isActive() then
            s_gui:close()
        end

        s_gui:destroy()
    end

    self.gui = nil
end

function XOMeter.client_onInteract(self, character, lookAt)
    if lookAt == true then
        self.gui = mp_gui_createGuiFromLayout("$MOD_DATA/Gui/Layouts/XOMeter.layout", false, { backgroundAlpha = 0.5 })
        self.gui:setOnCloseCallback("client_onGuiDestroyCallback")

		for i = 0, 10 do
			self.gui:setButtonCallback( "Operation" .. tostring( i ), "cl_onModeButtonClick" )
		end

        self:cl_drawButtons()
		self.gui:open()
	end
end

function XOMeter.cl_onModeButtonClick(self, buttonName)
	local newIndex = tonumber(string.sub(buttonName, 10, -1)) + 1

	if self.mode_client == newIndex then return end

	self.mode_client = newIndex
	self.network:sendToServer('sv_setMode', { mode = self.mode_client })
	self:cl_drawButtons()
end

function XOMeter.cl_drawButtons(self)
    for i = 0, 10 do
        self.gui:setButtonState('Operation'.. i, i + 1 == self.mode_client)
        self.gui:setText('ButtonText'.. i, XOMeter.modetable[i + 1].icon)
    end
    self.gui:setText('FunctionDescriptionText', XOMeter.modetable[self.mode_client].description)
end

function runningAverage(self, num)
  local runningAverageCount = 5
  if self.runningAverageBuffer == nil then self.runningAverageBuffer = {} end
  if self.nextRunningAverage == nil then self.nextRunningAverage = 0 end

  self.runningAverageBuffer[self.nextRunningAverage] = num
  self.nextRunningAverage = self.nextRunningAverage + 1
  if self.nextRunningAverage >= runningAverageCount then self.nextRunningAverage = 0 end

  local runningAverage = 0
  for k, v in pairs(self.runningAverageBuffer) do
    runningAverage = runningAverage + v
  end
  --if num < 1 then return 0 end
  return runningAverage / runningAverageCount;
end
