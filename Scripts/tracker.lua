-- tracker.lua --
tracker = class( nil )
tracker.maxParentCount = 1
tracker.maxChildCount = 0
tracker.connectionInput =  sm.interactable.connectionType.power
tracker.connectionOutput = sm.interactable.connectionType.none
tracker.colorNormal = sm.color.new( 0xaaaaaaff )
tracker.colorHighlight = sm.color.new( 0xaaaaaaff )
if not trackertrackers then trackertrackers = {} end

function tracker.client_onCreate( self )
	self.id = self.shape.id
	table.insert(trackertrackers, self)
end
function tracker.client_onRefresh( self )
	self:client_onCreate()
end
function tracker.client_onDestroy(self)
	for k, v in pairs(trackertrackers) do
		if v.id == self.id then
			table.remove(trackertrackers, k)
			return
		end
	end
end

function tracker.getFrequency(self)
	if not self.interactable then return 0 end
	local parent = self.interactable:getSingleParent()
	return (parent and parent.power) or 0
end

	
	
	
-- jammer.lua --
jammer = class( nil )
jammer.maxParentCount = 1
jammer.maxChildCount = 0
jammer.connectionInput =  sm.interactable.connectionType.logic
jammer.connectionOutput = sm.interactable.connectionType.none
jammer.colorNormal = sm.color.new( 0x470067ff )
jammer.colorHighlight = sm.color.new( 0x601980ff )
jammer.poseWeightCount = 1
if not jammerjammers then jammerjammers = {} end

function jammer.client_onCreate( self )
	self.uvindex = 0
	self.isON = 1
	self.interference = 0 -- time
	table.insert(jammerjammers, self.interactable)
	self.network:sendToServer("server_modeToClient")
end
function jammer.client_onRefresh( self )
	self:client_onCreate()
end


function jammer.client_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then
		self.isON = parent:isActive()
	end
	
	if self.isON and self.interference == 0 then
		if not self.prevmode then --turned on
			sm.audio.play("Blueprint - Delete", self.shape:getWorldPosition())
			self.interactable:setPoseWeight(0,0)
		end
		
		self.interactable:setUvFrameIndex(self.uvindex + 50)
		self.uvindex = (self.uvindex + 1)%50
	else
		if self.prevmode then -- turned off
			sm.audio.play("Blueprint - Delete", self.shape:getWorldPosition())
			self.interactable:setPoseWeight(0,1)
			self.interactable:setUvFrameIndex(0) 
		end
	end
	if self.interference > 0 then self.interference = self.interference - 1 end
	self.prevmode = self.isON
end

function jammer.client_onProjectile(self, X, hits, four)
	self.interference = 80
end

function jammer.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end

function jammer.client_setmode(self, newmode)
	self.isON = newmode
end

function jammer.server_onCreate(self)
	local storage = self.storage:load()
	self.isONserver = (storage == nil) or storage
end

function jammer.server_onFixedUpdate(self, dt)
	local parent = self.interactable:getSingleParent()
	if parent then
		if self.isONserver ~= parent.active then
			self.isONserver = parent.active
			self.storage:save( parent.active)
		end
	end
	self.interactable.active = (self.isONserver and self.interference == 0)
end

function jammer.server_changemode(self)
	self.isONserver = not self.isONserver
	self.storage:save(self.isONserver)
	self:server_modeToClient()
end
function jammer.server_modeToClient(self)
	self.network:sendToClients("client_setmode", self.isONserver)
end
