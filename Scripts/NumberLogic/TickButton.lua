dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if TickButton and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

mpPrint("loading TickButton.lua")


TickButton = class( nil )
TickButton.maxParentCount = -1
TickButton.maxChildCount = -1
TickButton.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.seated
TickButton.connectionOutput = sm.interactable.connectionType.logic
TickButton.colorNormal = sm.color.new( 0xff7f99ff  )
TickButton.colorHighlight = sm.color.new( 0xFFB2C3ff  )
TickButton.poseWeightCount = 1


function TickButton.server_onCreate( self ) 
	self:server_init()
end


function TickButton.server_init( self ) 
	self.timeon = 0
	self.lasttime = 0
	self.logicpress = true
	self.duration = 0
end

function TickButton.server_onRefresh( self )
	self:server_init()
end


function TickButton.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	--typeparent == "logic" or typeparent == "timer" or typeparent == "button" or typeparent == "lever" or typeparent == "sensor" or typeparent == "steering" 
	--typeparent == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"
	local duration = 0
	local logicactive = false
	for k, v in pairs(parents) do
		local typeparent = v:getType()
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" and tostring(v:getShape():getShapeUuid()) ~= "c7a99aa6-c5a4-43ad-84c9-c85f7d842a93" --[[laser]] then
			-- number input
			duration = duration + math.floor(v.power)
		elseif v:getType() == "steering" or v:getType() == "seat" then
			-- nothing, ignore
		else
			-- logic input 
			if v.active then logicactive = true end
			if not self.lastinput and v.active then
				self.timeon = self.duration
				self.logicpress = true
			end
		end
	end
	self.lastinput = logicactive
	self.duration = duration > 0 and duration or 1
	
	if self.timeon > self.duration then self.timeon = self.duration end
	self.wason = self.timeon
	
	--self.network:sendToClients("client_setPose", {pose = 0, level = (self.timeon/self.duration)})
	self.network:sendToClients("client_setPose", {pose = 0, level = (self.timeon/self.duration)*3/4 + (self.timeon > 0 and 0.25 or 0)})
	if self.timeon == 0 then
		self.network:sendToClients("client_setUvframeIndex", 0)
	else
		self.network:sendToClients("client_setUvframeIndex",  (2-self.timeon/self.duration) * 25)
	end
	if self.timeon > 0 then
		self.interactable:setActive(true)
		self.interactable:setPower(1)
		self.timeon = self.timeon - 1
		if self.lasttime == 0 and not self.logicpress then
			self.network:sendToClients("client_playsound", "Button on" )
		end
	else
		self.interactable:setActive(false)
		self.interactable:setPower(0)
		if self.lasttime > 0 and not self.logicpress then 
			--print('test')
			self.network:sendToClients("client_playsound", "Button off" )
		end
	end
	self.lasttime = self.wason
end

function TickButton.client_setUvframeIndex(self, index)
	self.interactable:setUvFrameIndex(index)
end
function TickButton.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end
function TickButton.client_setPose(self, data)
	self.interactable:setPoseWeight(data.pose, data.level)
end

function TickButton.client_onInteract(self)
    self.network:sendToServer("server_settime")
end
function TickButton.server_settime(self)
	self.timeon = self.duration
	self.logicpress = false
end

function TickButton.server_onProjectile(self, X, hits, four)
	self.timeon = self.duration
	self.logicpress = false
end

