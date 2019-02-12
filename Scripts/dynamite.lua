dynamite = class( nil )
dynamite.maxChildCount = -1
dynamite.maxParentCount = 1
dynamite.connectionInput = sm.interactable.connectionType.logic + 2048
dynamite.connectionOutput = 2048
dynamite.colorNormal = sm.color.new( 0xcb0a00ff )
dynamite.colorHighlight = sm.color.new( 0xee0a00ff )
dynamite.poseWeightCount = 1
dynamite.exploders = {}

function dynamite.server_onCreate(self, dt)
	self.e = false
end

function dynamite.server_onFixedUpdate(self, dt)	
	local parent = self.interactable:getSingleParent()
	if ((parent and parent:isActive()) or self.detonate) then
		--position, level, destructionRadius, impulseRadius, magnitude
		local children = self.interactable:getChildren()
		for k, v in pairs(children) do
			dynamite.exploders[v:getShape().id] = true
		end
		if dynamite.exploders[self.shape.id] then dynamite.exploders[self.shape.id] = nil end
		sm.physics.explode( self.shape.worldPosition, 5, 1.5, 10, 10, "PropaneTank - ExplosionSmall", self.shape)
		sm.shape.destroyPart( self.shape )
	end	
	if dynamite.exploders[self.shape.id] then self.detonate = true end
end


function dynamite.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end

function dynamite.server_changemode(self)
	self.e = not self.e
	if self.e then self.network:sendToClients( "client_startCountdown", self.time )
	else self.network:sendToClients( "client_stopCountdown" , self.time)
	end
end

function dynamite.server_onProjectile(self,  position, timee, velocity, typee )
	if self.e then self.detonate = true end
	if not self.e then self:server_changemode() end
end

-- (Event) Called upon getting hit by a sledgehammer.
function dynamite.server_onSledgehammer( self, hitPos, player )
	if self.e then self.detonate = true end
end

-- (Event) Called upon collision with an explosion nearby
function dynamite.server_onExplosion( self, center, destructionLevel )
	self.detonate = true
end

function dynamite.client_onCreate( self )
	self.time = 10
	self.showtext = -1
	self.client_counting = false
	self.interactable:setUvFrameIndex(101)
end

function dynamite.client_onFixedUpdate(self, dt)
	if self.client_counting then 
		self.time = self.time - dt
		if self.showtext < 0 then self.interactable:setUvFrameIndex(100 - self.time * 10)
			else self.showtext = self.showtext - dt end
		self.interactable:setPoseWeight( 0, 1 )
		if self.time <= dt then self.detonate = true end
	else
		self.interactable:setPoseWeight( 0, 0 )
	end
	if self.showtext < 0 and self.showtext > -1 then
		self.interactable:setUvFrameIndex(100 - self.time * 10)
		self.showtext = -1
	else
		self.showtext = self.showtext - dt
	end
end

function dynamite.client_startCountdown(self, servertime)
	self.time = servertime
	self.client_counting = true
end
function dynamite.client_stopCountdown(self, servertime)
	self.time = servertime
	self.client_counting = false
	self.interactable:setUvFrameIndex(102)
	self.showtext = 0.5
end
