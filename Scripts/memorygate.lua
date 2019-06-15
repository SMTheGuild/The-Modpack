
-- memoryblock.lua --
memoryblock = class( nil )
memoryblock.maxParentCount = -1
memoryblock.maxChildCount = -1
memoryblock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
memoryblock.connectionOutput = sm.interactable.connectionType.power 
memoryblock.colorNormal = sm.color.new( 0x7F567Dff )
memoryblock.colorHighlight = sm.color.new( 0x9f7fa5ff )
memoryblock.poseWeightCount = 1

dofile('functions.lua')

function memoryblock.server_onCreate( self ) 
	self:server_init()
end

function memoryblock.server_init( self )
	self.data = {}
	self.data[0] = 0
	self.data["key"] = 1
	--self.data[1] = 1
	self.power = 0
	self.mode = 0
	self.time = 0
	local stored = self.storage:load() 
	--print(stored)
	if stored then
		if type(stored) == "number" then 
			self.data[0] = stored
		elseif type(stored) == "table" then
			self.data = stored
		end
		self.power = tonumber(self.data[0])
		if not self.power then self.power = 0 end
		self.interactable:setPower(self.power)
	else
		self.storage:save(self.data)
	end
	sm.interactable.setValue(self.interactable, self.power)
end

function memoryblock.server_onRefresh( self )
	self:server_init()
end


function memoryblock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local saves = false
	local address = 0
	local value = 0
	local writevalue = false
	local hasvalueparent = false
	local reset = false
	for k,v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape().shapeUuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
			-- number input
			if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
				-- address
				address = address + (sm.interactable.getValue(v) or v.power)
			else
				-- value
				value = value + (sm.interactable.getValue(v) or v.power)
				hasvalueparent = true
			end
			if tostring(v:getShape().shapeUuid) == "d3eda549-778f-432b-bf21-65a32ae53378" and v.active then
				writevalue = true
			end
		else
			-- logic input
			if v.active then writevalue = true end
			if tostring(sm.shape.getColor(v:getShape())) == "222222ff" and (sm.interactable.getValue(v) or v.power) ~= 0 then
				reset = true
			end
		end
	end
	if writevalue and hasvalueparent then
		saves = self.data[address] ~= value
		self.data[address] = tostring(value)
	end
	self.power = tonumber(self.data[address])
	if reset then
		self.power = 0
		self.data = {}
		self.data[0] = 0
		self.data["key"] = 1
		self.time = 60
		self.mode = 1
		saves = false
		self.storage:save(self.data)
		address = 0
	end
	if self.power == nil then self.power = 0 end
	if self.power ~= self.interactable.power or self.power ~= (sm.interactable.getValue(self.interactable) or self.interactable.power) then
		self.time = 20
		self.mode = 2
	end
	if self.interactable.power ~= self.power and type(self.power) == "number" and math.abs(self.power) >= 0 then
		self.interactable:setActive(self.power>0)
		self.interactable:setPower(self.power)
		sm.interactable.setValue(self.interactable, self.power)
	end
	if saves then 
		self.time = 20
		self.mode = 1
		self.data["key"] = 1
		self.storage:save(self.data)
	end
	if address ~= self.lastaddress then self.network:sendToClients("client_setUvValue", address) end
	if self.mode == 1 then
		self.network:sendToClients("client_setPose", (self.time%4)>2 and 1 or 0)
	elseif self.mode == 2 then	
		self.network:sendToClients("client_setPose", self.time>0 and 1 or 0)
	else
		self.network:sendToClients("client_setPose", 0)
	end
	self.time = self.time > 0 and self.time - 1 or 0
	self.mode = self.time > 0 and self.mode or 0
	self.lastaddress = address
end

function memoryblock.client_setUvframeIndex(self, index)
	self.interactable:setUvFrameIndex(index)
end
function memoryblock.client_setPose(self, level)
	self.interactable:setPoseWeight(0, level)
end
function memoryblock.client_setUvValue(self, value) 
	if value < 0 then 
		value = 0-value 
	end
	if value > 255 then value = 255 end
	if value == math.huge then value = 0 end
	self.interactable:setUvFrameIndex(value)
end