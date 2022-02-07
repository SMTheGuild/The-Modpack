--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading WirelessBlock.lua")

-- WirelessBlock.lua --
WirelessBlock = class( nil )
WirelessBlock.maxParentCount = -1
WirelessBlock.maxChildCount = -1
WirelessBlock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
WirelessBlock.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.bearing
WirelessBlock.colorNormal = sm.color.new( 0xaaaaaaff )
WirelessBlock.colorHighlight = sm.color.new( 0xaaaaaaff )
WirelessBlock.poseWeightCount = 3

if not wirelessdata then wirelessdata = {} end


function WirelessBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function WirelessBlock.server_onCreate( self )
	self.IsSender = true
	local stored = self.storage:load()
	if stored ~= nil then
		if type(stored) == "number" then
			self.IsSender = (stored == 1) -- backwards compatibility with workaround artifacts
		else -- boolean
			self.IsSender = stored 
		end
	end
	self.storage:save(self.IsSender)
end

function WirelessBlock.server_onFixedUpdate( self, dt )

	if self.IsSender then 
		-- client side handles getting values and making them global so that the server receiver can read them.
		mp_updateOutputData(self, 0, false) -- make sure nothing attached to a sender can get a value
	else -- receiver
	
		-- only really needs to handle receiving part (power, bearings & whatever)

		local parents = self.interactable:getParents()
		local color = tostring(sm.shape.getColor(self.shape))
		local frequency = 0 -- white number input
		
		for k, v in pairs(parents) do
			if sm.interactable.isNumberType(v) and v:getType() ~= "steering" and tostring(v:getShape():getShapeUuid()) ~= "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] and
					tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
				-- number, frequency
				frequency = frequency + (sm.interactable.getValue(v) or v.power)
			end
		end
		
		
		
		local senderPose = 0 -- between -1 and 1
		local pose_values = {}
		
		local power = 0
		local power_values = {}
		
		
		if wirelessdata[frequency] and wirelessdata[frequency][color] then
			for k, v in pairs(wirelessdata[frequency][color]) do
				if sm.exists(v) and sm.interactable.getValue_shadow(v) then
					table.insert(power_values, sm.interactable.getValue_shadow(v)[1])
					table.insert(pose_values, sm.interactable.getValue_shadow(v)[2]) -- shadow val should always exist.
				end
			end
		end
		
		if #pose_values == 1 then
			senderPose = pose_values[1]
		elseif #pose_values > 1 then
			local lowestValue = math.huge
			local highestValue = math.huge*-1
			
			for k, val in pairs(pose_values) do
				if val < lowestValue then lowestValue = val end
				if val > highestValue then highestValue = val end
			end
			
			senderPose = math.random() * (highestValue - lowestValue) + lowestValue
		end
		
		-- because for some fkn reason this is needed:
		if senderPose ~= senderPose then senderPose = 0 end --NaN check
		if math.abs(senderPose) >= 3.3*10^38 then -- inf check
			if senderPose < 0 then senderPose = -3.3*10^38 else senderPose = 3.3*10^38 end  
		end
		
		
		for k, joint in pairs(sm.interactable.getBearings(self.interactable)) do
			sm.joint.setTargetAngle(joint, math.rad(senderPose*27), 10, 1000)
		end
		
		
		
		
		if #power_values == 1 then
			power = power_values[1]
		elseif #power_values > 1 then
			local lowestValue = math.huge
			local highestValue = math.huge*-1
			
			for k, val in pairs(power_values) do
				if val < lowestValue then lowestValue = val end
				if val > highestValue then highestValue = val end
			end
			
			power = math.random() * (highestValue - lowestValue) + lowestValue
		end
		
		if power ~= power then power = 0 end --NaN check
		if math.abs(power) >= 3.3*10^38 then -- inf check
			if power < 0 then power = -3.3*10^38 else power = 3.3*10^38 end  
		end
		
		mp_updateOutputData(self, power, power ~= 0)
	end
end


function WirelessBlock.server_clientInteract(self)
	self.IsSender = (not self.IsSender)
	self.storage:save(self.IsSender)
	self:server_sendModeToClient(true)
end

function WirelessBlock.server_sendModeToClient(self, snd)
	self.network:sendToClients("client_changeMode", {self.IsSender, snd})
end


--------------------
local values_shadow = {} -- <<not accessible for other scripts
function sm.interactable.setValue_shadow(interactable, value)  -- same as getValue, only this one is used just for the wirelessBlock as a way to work on a different channel than the setValue/getValue
    local currenttick = sm.game.getCurrentTick()
    values_shadow[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        values_shadow[interactable.id] and (    
            values_shadow[interactable.id][1] ~= nil and 
            (values_shadow[interactable.id][1].tick < currenttick) and 
            values_shadow[interactable.id][1].value or 
			values_shadow[interactable.id][2]
        ) 
        or nil
    }
end
function sm.interactable.getValue_shadow(interactable, NOW)    
	if sm.exists(interactable) and values_shadow[interactable.id] then
		if values_shadow[interactable.id][1] and (values_shadow[interactable.id][1].tick < sm.game.getCurrentTick() or NOW) then
			return values_shadow[interactable.id][1].value[1]
		elseif values_shadow[interactable.id][2] then
			return values_shadow[interactable.id][2][1]
		end
	end
	return nil
end
-------------------


function WirelessBlock.client_onCreate(self)
	self.IsSender_client = true
	self.network:sendToServer("server_sendModeToClient")
	self.interactableID = self.interactable.id
end

function WirelessBlock.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local color = tostring(sm.shape.getColor(self.shape))
	local sendsstuff = false -- boolean, if inputs detected
	local frequency = 0 -- white number input
	local power = 0 -- any number input
	local pose = 0 -- input pose (seats or whatever)
	local usableinputs = 0 -- pose inputs (takes average)
	
	
	for k, v in pairs(parents) do
		local _isOldSeat = (v:getType() == "steering")
		if v:hasSteering() or _isOldSeat or tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
			-- pose
			if _isOldSeat then
				local success, result = pcall(sm.interactable.getPoseWeight, v, 0)
				pose = pose + ((success and result or 0)*2 -1) -- convert 0-1 to -1 ~ +1
			elseif v:hasSteering() then
				pose = pose + v:getSteeringAngle()
			end
			power = power + (sm.interactable.getValue(v) or v.power)
		
			sendsstuff = true
			usableinputs = usableinputs + 1
			
		else
			-- value
			if sm.interactable.isNumberType(v) and tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
				-- number, frequency
				frequency = frequency + (sm.interactable.getValue(v) or v.power)
			else
				-- everything else is value
				power = power + (sm.interactable.getValue(v) or v.power) -- getValue will return values on the host but this doesn't matter, other clients don't need to know the value.
				sendsstuff = true
			end
		end
	end
	pose = pose/usableinputs
	

	-- something changed:
	if self.lastfrequency ~= frequency or self.lastcolor ~= color then
		-- remove reference:
		if self.lastfrequency and self.lastcolor and wirelessdata[self.lastfrequency] and wirelessdata[self.lastfrequency][self.lastcolor] then 
			wirelessdata[self.lastfrequency][self.lastcolor][self.interactable.id] = nil
		end
		
		-- make room for new reference:
		if not wirelessdata[frequency] then wirelessdata[frequency] = {} end
		if not wirelessdata[frequency][color] then wirelessdata[frequency][color] = {} end
	end
	
	
	if self.IsSender_client then
		-- sender
		sm.interactable.setValue_shadow(self.interactable, {power, pose}) -- <-- MAGIC HAPPENS HERE!
		
		if sendsstuff then -- < are receivers allowed to 'find' me ?
			wirelessdata[frequency][color][self.interactable.id] = self.interactable
		else
			wirelessdata[frequency][color][self.interactable.id] = nil
		end
		
		self.interactable:setPoseWeight(0, 0.5) -- reset pose to center
		self.interactable:setPoseWeight(1, 0) -- the sending/receiving sign
		
	else
		-- receiver
		sm.interactable.setValue_shadow(self.interactable, {0, 0.5}) -- reset value
		wirelessdata[frequency][color][self.interactable.id] = nil -- remove myself from global senders table
		
		local senderPose = 0 -- between -1 and 1
		local pose_values = {}
		
		for k, v in pairs(wirelessdata[frequency][color]) do
			if sm.exists(v) and sm.interactable.getValue_shadow(v) then
				table.insert(pose_values, sm.interactable.getValue_shadow(v)[2]) -- shadow val should always exist.
			end
		end
		
		if #pose_values == 1 then
			senderPose = pose_values[1]
			
		elseif #pose_values > 1 then
			local lowestValue = math.huge
			local highestValue = math.huge*-1
			
			for k, val in pairs(pose_values) do
				if val < lowestValue then lowestValue = val end
				if val > highestValue then highestValue = val end
			end
			
			senderPose = math.random() * (highestValue - lowestValue) + lowestValue
		end
		
		-- because for some fkn reason this is needed:
		if senderPose ~= senderPose then senderPose = 0 end --NaN check
		if math.abs(senderPose) >= 3.3*10^38 then -- inf check
			if senderPose < 0 then senderPose = -3.3*10^38 else senderPose = 3.3*10^38 end  
		end
		
		self.interactable:setPoseWeight(0, (senderPose and (senderPose + 1)/2 or 0.5))
		self.interactable:setPoseWeight(1, 1) -- the sending/receiving sign
		
	end
	
	
	local UV = math.abs(frequency)
	self.interactable:setUvFrameIndex(UV<255 and (UV>=0 and UV or 255) or 255)
	
	
	self.lastcolor = color
	self.lastfrequency = frequency
end

function WirelessBlock.client_onDestroy(self)
	wirelessdata[self.lastfrequency][self.lastcolor][self.interactableID] = nil
end

function WirelessBlock.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	self.network:sendToServer("server_clientInteract")
end


function WirelessBlock.client_changeMode(self, mode)
	self.IsSender_client = mode[1]
	if mode[2] then
		sm.audio.play("Button on", self.shape:getWorldPosition())
	end
end


