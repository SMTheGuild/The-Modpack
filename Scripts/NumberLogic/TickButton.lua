dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.   
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
	self.killAtTick = 0
	self.ticksToLive = 1
end

function TickButton.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end


function TickButton.server_onFixedUpdate( self, dt )
	
	local numberinput = 0
	local logicactive = false
	for k, v in pairs(self.interactable:getParents()) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number input
			numberinput = numberinput + math.floor(v.power)
		elseif v:getType() == "steering" or v:getType() == "seat" then
			-- nothing, ignore, onInteract handles this.
		else
			-- logic input 
			logicactive = logicactive or v.active
		end
	end
	
	
	numberinput = numberinput > 0 and numberinput or 1
	
	if numberinput ~= self.ticksToLive then
		self.ticksToLive = numberinput
		if not logicactive or self.wasActive then
			-- notify clients of new ticksToLive
			if self.killAtTick - sm.game.getCurrentTick() > self.ticksToLive then -- TimeToGo is smaller than total ticksToLive
				self.killAtTick = sm.game.getCurrentTick() + self.ticksToLive -- new killAtTick
			end
			self.network:sendToClients("client_buttonPress",{self.killAtTick - sm.game.getCurrentTick(), self.ticksToLive, false})
		end
	end
	
	if not self.wasActive and logicactive then
		self:server_onInteract(true)
	end
	self.wasActive = logicactive
	
	if self.interactable.active and self.killAtTick <= sm.game.getCurrentTick() then
		self.interactable.active = false
		self.interactable.power = 0
	end
	
end

function TickButton.server_onProjectile(self, X, hits, four)
	self:server_onInteract()
end

function TickButton.server_onInteract(self, nosound)
	self.killAtTick = sm.game.getCurrentTick() + self.ticksToLive
	self.network:sendToClients("client_buttonPress",{self.ticksToLive, self.ticksToLive, not nosound})
	self.interactable.active = true
	self.interactable.power = 1
end

function TickButton.server_clientRequest(self) -- sends data to newly joined clients
	local ticksToLive = self.killAtTick - sm.game.getCurrentTick()
	if ticksToLive > 0 then
		self.network:sendToClients("client_buttonPress",{ticksToLive, self.ticksToLive, false})
	end
end



function TickButton.client_onCreate(self)
	self.c_lifetime = 0
	self.c_ticksToLive = 1
	self.network:sendToServer("server_clientRequest")
end

function TickButton.client_onFixedUpdate(self)
	if self.animation_active then
	
		if self.c_ticksToLive <= 0 then -- powers down
			self.animation_active = false
			self.interactable:setUvFrameIndex(0)
			self.interactable:setPoseWeight(0, 0)
			sm.audio.play("Button off", self.shape:getWorldPosition())
			return
		end
		
		self.interactable:setUvFrameIndex((2 - self.c_ticksToLive / self.c_lifetime) * 25) -- artifact calculation
		self.interactable:setPoseWeight(0, 0.25 + (self.c_ticksToLive / self.c_lifetime) * 3/4) -- last 25% quickly pops down in a single tick
		
		self.c_ticksToLive = self.c_ticksToLive - 1
	end
end


function TickButton.client_buttonPress(self, data)
	self.c_ticksToLive = data[1]
	self.c_lifetime = data[2]
	
	if data[3] then
		sm.audio.play("Button on", self.shape:getWorldPosition())
	end
	self.animation_active = self.c_ticksToLive > 0
end


function TickButton.client_onInteract(self)
    self.network:sendToServer("server_onInteract")
end

