
dofile('functions.lua')
-- sender.lua --
sender = class( nil )
sender.maxParentCount = 2
sender.maxChildCount = -1
sender.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
sender.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.bearing
sender.colorNormal = sm.color.new( 0xaaaaaaff )
sender.colorHighlight = sm.color.new( 0xaaaaaaff )
sender.poseWeightCount = 3

function sender.server_onCreate( self )
	self:server_init()
end

function sender.server_init( self )
	self.sender = true
	self.pose = 0.5
	if not wirelessdata then
		wirelessdata = {}
	end
	local stored = self.storage:load()
	if stored ~= nil and type(stored)=="number" then
		self.sender = (stored==1)
	end
	self.storage:save(self.sender and 1 or 2)
end

function sender.server_onDestroy(self)
	wirelessdata[self.lastfrequency] = nil
end

function sender.server_onRefresh( self )
	self:server_init()
end


function sender.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local color = tostring(sm.shape.getColor(self.shape))
	local data = {}
	local frequency = 0
	local power = 0
	local pose = 0
	local sendsstuff = false
	local usableinputs = 0
	for k, v in pairs(parents) do
		if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" and v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			--number input, frequency
			frequency = frequency + (sm.interactable.getValue(v) or v.power)
		else
			power = power + (sm.interactable.getValue(v) or v.power)
			sendsstuff = true
			usableinputs = usableinputs + 1
		end
	end
	if usableinputs > 0 then pose = self.pose/usableinputs end
	data[color] = {}
	data[color].value = power
	data[color].AD = pose
	data[color].senderid = self.shape.id
	data[color].interference = false
	
	if wirelessdata then
		if self.lastmode ~= self.sender and self.lastmode then
			self.interactable:setActive(false)
			self.interactable:setPower(0)
			
			if wirelessdata[self.lastfrequency] and wirelessdata[self.lastfrequency][color] then
				wirelessdata[self.lastfrequency][color] = nil
			end
			if wirelessdata[self.lastfrequency] and #wirelessdata[self.lastfrequency] == 0 then
				wirelessdata[self.lastfrequency] = nil
			end
		end
		
		if self.sender then -- sending
			if self.lastfrequency ~= frequency and self.lastfrequency ~= nil or self.lastcolor ~= color and self.lastcolor then --or if color changes
				if wirelessdata[self.lastfrequency] and wirelessdata[self.lastfrequency][self.lastcolor] then
					wirelessdata[self.lastfrequency][self.lastcolor] = nil
				end
				if wirelessdata[self.lastfrequency] and #wirelessdata[self.lastfrequency] == 0 then
					wirelessdata[self.lastfrequency] = nil
				end
			end
			
			
			if wirelessdata[frequency] and wirelessdata[frequency][color] and wirelessdata[frequency][color].senderid ~= self.shape.id and wirelessdata[frequency][color].value ~= power then
				data[color].interference = true
			end
			--print(data, usableinputs)
			--print(data)
			self.network:sendToClients("client_setUvframeIndex", frequency<255 and (frequency>=0 and frequency or 255) or 255)
			if sendsstuff then
				if wirelessdata[frequency] then
					for c, moredata in pairs(wirelessdata[frequency]) do
						if c ~= color then
							data[c] = moredata
						end
					end
				end
				wirelessdata[frequency] = data
			end
			if self.interactable.power ~= 0 or (sm.interactable.getValue(self.interactable) or self.interactable.power) ~= 0 then
				self.interactable:setActive(false)
				self.interactable:setPower(0)
	sm.interactable.setValue(self.interactable, 0)
				self.network:sendToClients("client_setPose", {pose0 = 0.5, pose1 = 0})
			end
		else --receiving
			power = 0
			pose = 0
			--print(wirelessdata) 
			self.network:sendToClients("client_setUvframeIndex", frequency<255 and (frequency>=0 and frequency or 255) or 255)
			if wirelessdata[frequency] then
				local data = wirelessdata[frequency]
				if data[color] then
					--print(data[color] )
					if data[color].interference then 
						power = math.random(-10,10)
						pose = math.random()
						--print('random')
					else
						power = data[color].value
						pose = data[color].AD
					end
					for k, joint in pairs(sm.interactable.getBearings(self.interactable)) do
						sm.joint.setTargetAngle(joint, math.rad(pose*27), 10, 1000)
					end
				end
			end
		if self.power ~= self.interactable.power or self.power ~= (sm.interactable.getValue(self.interactable) or self.power) then
				self.interactable:setActive(power~=0)
				self.interactable:setPower(power)
	sm.interactable.setValue(self.interactable,  power)
			end
			self.network:sendToClients("client_setPose", {pose0 = pose, pose1 = 1})
		end
	end
	self.lastfrequency = frequency
	self.lastcolor = color
	self.lastmode = self.sender
end
function sender.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local pose = 0
	for k, v in pairs(parents) do
		if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" and v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			--number input, frequency
		else
			pose = pose + (v:getPoseWeight(0)*2 -1)
		end
	end
	self.pose = pose
end

function sender.client_setUvframeIndex(self, index)
	self.interactable:setUvFrameIndex(index)
end
function sender.client_setPose(self, data)
	self.interactable:setPoseWeight(0, data.pose0)
	self.interactable:setPoseWeight(1, data.pose1)
end

function sender.client_onCreate(self)
	self.network:sendToServer("server_requestmode")
end

function sender.server_requestmode(self)
	self.network:sendToClients("client_setPose", {pose0 = 0.5, pose1 = self.sender and 0 or 1})
end

function sender.client_onInteract(self)
	self.network:sendToServer("server_clientInteract")
end

function sender.server_clientInteract(self)
	self.sender = (not self.sender)
	self.storage:save(self.sender and 1 or 2)
	self.network:sendToClients("client_setPose", {pose0 = 0.5, pose1 = self.sender and 0 or 1})
	--print('saved: ', (self.sender and 'sender' or 'receiver') )
	--self.network:sendToClients("client_playsound", "Blueprint - Open")
	--self.network:sendToClients("client_range",{range = self.range, uvindex = self.uvindex})
end