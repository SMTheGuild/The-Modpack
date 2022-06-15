--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

-- SmartSensor.lua --
SmartSensor = class( nil )
SmartSensor.maxParentCount = -1 -- infinite
SmartSensor.maxChildCount = -1
SmartSensor.connectionInput = sm.interactable.connectionType.power
SmartSensor.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartSensor.colorNormal = sm.color.new( 0x76034dff )
SmartSensor.colorHighlight = sm.color.new( 0x8f2268ff )
SmartSensor.poseWeightCount = 3

SmartSensor.mode = 1
SmartSensor.mode_client = 1
SmartSensor.pose = 0
SmartSensor.raypoints = {
	sm.vec3.new(0,0,0),
	sm.vec3.new(0.118,0,0),
	sm.vec3.new(-0.118,0,0),
	sm.vec3.new(0.0839,0.0839,0),
	sm.vec3.new(0.0839,-0.0839,0),
	sm.vec3.new(-0.0839,0.0839,0),
	sm.vec3.new(-0.0839,-0.0839,0),
	sm.vec3.new(0,0.118,0),
	sm.vec3.new(0,-0.118,0)
}
SmartSensor.modes = {
	{ value = 0, targetPose = 0, 	icon = '1\ndist',     description = "1 raycast, distance mode" },
    { value = 1, targetPose = 0.8, 	icon = 'wide\ndist',  description = "Wide raycast, distance mode" },
	{ value = 2, targetPose = 0, 	icon = '1\ncolor',    description = "1 raycast, color mode" },
	{ value = 3, targetPose = 0.8, 	icon = 'wide\ncolor', description = "Wide raycast, color mode" },
	{ value = 4, targetPose = 0, 	icon = 'type',        description = "Nothing: 0                        Body: 4\nTerrain surface: 1          Character: 5\nTerrain asset: 2              Joint: 6\nLift: 3                                 Vision: 7" },
	{ value = 5, targetPose = 0,	icon = 'item\ncount', description = "container mode, get the amount of items in a container" }
}
SmartSensor.modeCount = #SmartSensor.modes
SmartSensor.savemodes = {}
for k,v in pairs(SmartSensor.modes) do
   SmartSensor.savemodes[v.value] = k
end


function SmartSensor.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function SmartSensor.server_onCreate( self )
	local stored = self.storage:load()
	if stored then
		self.mode = self.savemodes[stored]
	else
		self.storage:save(self.modes[self.mode].value)
	end
end

function SmartSensor.server_onFixedUpdate( self, dt )
	local mode = self.modes[self.mode].value

	local parents = self.interactable:getParents()
	local newmode = nil
	local offset = 0

	for k, v in pairs(parents) do
		if sm.interactable.isNumberType(v) then
			local color = tostring(v:getShape().color)
			if color == "eeeeeeff" then
				newmode = (newmode or 0) + v.power
			else
				offset = offset + v.power
			end
		end
	end

	newmode = (newmode and newmode % self.modeCount or nil)

	self.needssave = self.needssave or newmode and newmode ~= mode

	if newmode and newmode ~= mode then
		mode = newmode
		self.mode = self.savemodes[newmode]
		self.network:sendToClients("cl_newMode", {self.mode, false})
	end

	local isTime = os.time()%5 == 0
	if self.needssave and isTime and self.risingedge then
		self.storage:save(mode)
	end
	self.risingedge = not isTime

	local src = self.shape.worldPosition + self.shape.up * offset/4

	local colormode = (mode == 2) or (mode == 3)
	local distancemode = (mode == 0) or (mode == 1)
	local bigSize = (mode == 1) or (mode == 3)

	local distance = nil
	local colors = {}

	for k, raypoint in pairs( bigSize and self.raypoints or {sm.vec3.new(0,0,0)} ) do
		if colormode then
			local startPos = src + getLocal(self.shape, raypoint)
			local hit, result = sm.physics.raycast(startPos, startPos + self.shape.up*3000)
			if hit and result.type == "body" then
				local d = sm.vec3.length(src - result.pointWorld) * 4 - 0.5
				if distance == nil or d < distance then
					distance = d*4 - 0.5
				end
				local c = result:getShape().color
				local cc = tostring(math.round(c.b*255) + math.round(c.g*255*256) + math.round(c.r*255*256*256))
				if colors[cc] and colors[cc].distance == math.round(d) then
					colors[cc].count = colors[cc].count + 1
				elseif (not colors[cc] or colors[cc].distance > math.round(d)) then
					colors[cc] = {distance = math.round(d), count = 1}
				end
			end

		elseif distancemode then
			local hit, fraction = sm.physics.distanceRaycast(src + getGlobal(self.shape, raypoint), self.shape.up*3000)
			if hit then
				local d = fraction * 3000
				if distance == nil or d*4 - 0.5 < distance then
					distance = d*4 - 0.5
				end
			end
		elseif mode == 4 then	-- type mode
			local startPos = src + getLocal(self.shape, raypoint)
			local hit, result = sm.physics.raycast(startPos, startPos + self.shape.up*3000)
			local resulttype = result.type
			local power_value = (resulttype == "terrainSurface" and 1 or 0) + (resulttype == "terrainAsset" and 2 or 0) + (resulttype == "lift" and 3 or 0) +
					(resulttype == "body" and 4 or 0) + (resulttype == "character" and 5 or 0) + (resulttype == "joint" and 6 or 0) + (resulttype == "vision" and 7 or 0)

			mp_setPowerSafe(self, power_value)

		elseif mode == 5 then	-- container mode
			local power_value = 0
			local startPos = src + getLocal(self.shape, raypoint)
			local hit, result = sm.physics.raycast(startPos, startPos + self.shape.up*3000)
			if hit and result.type == "body" and result:getShape().interactable then
				local container = result:getShape().interactable:getContainer()
				if container then
					local items = 0
					for i = 0, container:getSize(), 1 do
						stackSize = container:getItem(i)["quantity"]
						if stackSize then
							items = items + stackSize
						end
					end
					power_value = items
				end
			end

			mp_setPowerSafe(self, power_value)
		end
	end


	if colormode then
		local bestmatch = nil
		local color = 0
		for k, v in pairs(colors) do
			if bestmatch == nil then
				bestmatch = v
				color = tonumber(k)
			end
			if (v.distance < bestmatch.distance) or (v.distance == bestmatch.distance and v.count > bestmatch.count) then
				bestmatch = v
				color = tonumber(k)
			end
		end

		mp_setPowerSafe(self, color)
	elseif distancemode then
		mp_setPowerSafe(self, distance or 0)
	end

	mp_setActiveSafe(self, self.interactable.power > 0)
end

function SmartSensor.sv_setMode(self, params)
    self.mode = params.mode
    self.storage:save(self.modes[self.mode].value)
	self.network:sendToClients("cl_newMode", {self.mode, true})
end

function SmartSensor.sv_requestMode(self)
	self.network:sendToClients("cl_newMode", {self.mode, false})
end

-- Client --

function SmartSensor.client_onCreate(self)
	-- client joins world, requests mode from server
	self.network:sendToServer("sv_requestMode")
end

function SmartSensor.client_onDestroy(self)
	self:client_onGuiDestroyCallback()
end

function SmartSensor.client_onGuiDestroyCallback(self)
	local s_gui = self.gui
	if s_gui and sm.exists(s_gui) then
		if s_gui:isActive() then
			s_gui:close()
		end

		s_gui:destroy()
	end

	self.gui = nil
end

function SmartSensor.client_onInteract(self, character, lookAt)
    if lookAt == true then
        self.gui = mp_gui_createGuiFromLayout("$MOD_DATA/Gui/Layouts/SmartSensor.layout", false, { backgroundAlpha = 0.5 })
		self.gui:setOnCloseCallback("client_onGuiDestroyCallback")

		for i = 0, 5 do
			self.gui:setButtonCallback( "Operation" .. tostring( i ), "cl_onModeButtonClick" )
		end
		
        self:cl_drawButtons()
		self.gui:open()
	end
end

function SmartSensor.cl_onModeButtonClick(self, buttonName)
	local newIndex = tonumber(string.sub(buttonName, 10, -1)) + 1

	if self.mode_client == newIndex then return end

	self.mode_client = newIndex
	self.network:sendToServer('sv_setMode', { mode = self.mode_client })
	self:cl_drawButtons()
end

function SmartSensor.cl_drawButtons(self)
    for i = 0, 5 do
        self.gui:setButtonState('Operation'.. i, i + 1 == self.mode_client)
        self.gui:setText('ButtonText'.. i, SmartSensor.modes[i + 1].icon)
    end
    self.gui:setText('FunctionDescriptionText', SmartSensor.modes[self.mode_client].description)
end

function SmartSensor.client_canInteract(self, character, lookAt)
	local use_key = mp_gui_getKeyBinding("Use", true)
	sm.gui.setInteractionText("Press", use_key, "to select a sensor mode")
	
	return true
end

function SmartSensor.cl_newMode(self, data)
	self.mode_client = data[1]
	if data[2] then
		sm.audio.play("ConnectTool - Rotate", self.shape:getWorldPosition())
	end
end

function SmartSensor.client_onFixedUpdate(self, dt)
	local targetPose = self.modes[self.mode_client].targetPose
	if self.pose == targetPose then return end
	if self.pose > targetPose + 0.01 then
		self.pose = self.pose - 0.04
	elseif self.pose < targetPose - 0.01 then
		self.pose = self.pose + 0.04
	end
	self.interactable:setPoseWeight(0, self.pose)
end
