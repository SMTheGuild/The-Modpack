
-- tracker.lua --
tracker = class( nil )
tracker.maxParentCount = 1
tracker.maxChildCount = 0
tracker.connectionInput =  sm.interactable.connectionType.power
tracker.connectionOutput = sm.interactable.connectionType.none
tracker.colorNormal = sm.color.new( 0xaaaaaaff )
tracker.colorHighlight = sm.color.new( 0xaaaaaaff )
tracker.poseWeightCount = 1

function tracker.server_onCreate( self ) 
	self:server_init()
end

function tracker.server_init( self ) 
	--sm.storage.save(123, {})
	trackers = {}
	self.id = self.shape.id
end	

function tracker.server_onRefresh( self )
	self:server_init()
end


function tracker.server_onFixedUpdate( self, dt )
	local position = self.shape:getWorldPosition()
	local parent = self.interactable:getSingleParent()
	local specialid = 0
	if parent then specialid = parent.power end
	local tracker1 = {
		id = self.shape.id,
		special = specialid,
		pos = position,
		timeout = 0,
		player = false,
		color = tostring(sm.shape.getColor(self.shape))
	}
	if orienters and self:tablesize(orienters)>0 then
		local weight = 0
		for k, v in pairs(self.shape.body:getCreationBodies()) do
			weight = weight + v.mass
		end
		tracker1.mass = weight
	end
	
	if trackers then
		trackers[self.shape.id] = tracker1
	end
end

function tracker.server_onDestroy( self )
	trackers[self.id] = nil
end


function tracker.tablesize(self, tabl)
	local x = 0
	for k, v in pairs(tabl) do
		x = x + 1
	end
	return x
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

function jammer.server_onCreate( self ) 
	self:server_init()
end

function jammer.server_init( self ) 
	self.id = self.shape.id
	jammers = {}
	self.uvindex = 50
	self.mode = 1
	self.interference = 0
end	

function jammer.server_onRefresh( self )
	self:server_init()
end


function jammer.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if jammers and parent then
		if parent:isActive() then
			self.mode = 1
		else
			self.mode = 0
		end
	end
	
	if self.mode == 1 and self.interference == 0 then
		if self.prevmode == 0 then --turned on
			self.storage:save(self.mode)
			self.network:sendToClients("client_playsound", "Blueprint - Close")
			self.network:sendToClients("client_setposeweight", 0)
		end
		-- on:
		local position = self.shape:getWorldPosition()
		local jammer1 = {
			id = self.id,
			pos = position,
			timeout = 0
		}
		if jammers then jammers[self.id] = jammer1 else jammers = {} end
		self.network:sendToClients("client_setUvframeIndex", self.uvindex)
		self.uvindex = self.uvindex + 1
		if self.uvindex >= 100 then self.uvindex = 50 end
	else
		if self.prevmode == 1 then -- turned off
			jammers[self.id] = nil
			self.storage:save(self.mode)
			self.network:sendToClients("client_playsound", "Blueprint - Delete")
			self.network:sendToClients("client_setposeweight", 1)
			self.network:sendToClients("client_setUvframeIndex", 0)
		end
	end
	if self.interference > 0 then self.interference = self.interference - 1 end
	self.prevmode = self.mode
end

function jammer.client_setposeweight(self, pose)
	self.interactable:setPoseWeight(0,pose)
end
function jammer.client_setUvframeIndex(self, index)
	self.interactable:setUvFrameIndex(index)
end
function jammer.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end


function jammer.server_changemode(self)
	self.mode = self.mode == 0 and 1 or 0
end

function jammer.server_onProjectile(self, X, hits, four)
	self.interference = 80
end

function jammer.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end
function jammer.server_onDestroy( self )
	jammers[self.id] = nil
end