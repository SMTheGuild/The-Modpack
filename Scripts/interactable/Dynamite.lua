--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261 for copy pasta
]]--
dofile "../libs/load_libs.lua"

mpPrint("loading Dynamite.lua")

Dynamite = class( nil )
Dynamite.maxChildCount = -1
Dynamite.maxParentCount = 1
Dynamite.connectionInput = sm.interactable.connectionType.logic + 2048
Dynamite.connectionOutput = 2048
Dynamite.colorNormal = sm.color.new( 0xcb0a00ff )
Dynamite.colorHighlight = sm.color.new( 0xee0a00ff )
Dynamite.poseWeightCount = 1
Dynamite.exploders = {}

function Dynamite.server_onCreate(self, dt)
	self.e = false
end

function Dynamite.server_onFixedUpdate(self, dt)	
	local parent = self.interactable:getSingleParent()
	if ((parent and parent:isActive()) or self.detonate) then
		--position, level, destructionRadius, impulseRadius, magnitude
		local children = self.interactable:getChildren()
		for k, v in pairs(children) do
			Dynamite.exploders[v:getShape().id] = true
		end
		if Dynamite.exploders[self.shape.id] then Dynamite.exploders[self.shape.id] = nil end
		sm.physics.explode( self.shape.worldPosition, 5, 1.5, 10, 10, "PropaneTank - ExplosionSmall", self.shape)
		sm.shape.destroyPart( self.shape )
	end
	if Dynamite.exploders[self.shape.id] then self.detonate = true end
end


function Dynamite.client_onInteract(self, character, lookAt)
	if lookAt then
		self.network:sendToServer("server_changemode")
	end
end

function Dynamite.server_changemode(self)
	self.e = not self.e
	if self.e then self.network:sendToClients( "client_startCountdown", self.time )
	else self.network:sendToClients( "client_stopCountdown" , self.time)
	end
end

function Dynamite.server_onProjectile(self,  position, timee, velocity, typee )
	if self.e then self.detonate = true end
	if not self.e then self:server_changemode() end
end

-- (Event) Called upon getting hit by a sledgehammer.
function Dynamite.server_onSledgehammer( self, hitPos, player )
	if self.e then self.detonate = true end
end

-- (Event) Called upon collision with an explosion nearby
function Dynamite.server_onExplosion( self, center, destructionLevel )
	self.detonate = true
end

function Dynamite.client_onCreate( self )
	self.time = 10
	self.showtext = -1
	self.client_counting = false
	self.interactable:setUvFrameIndex(101)
end

function Dynamite.client_onFixedUpdate(self, dt)
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

function Dynamite.client_startCountdown(self, servertime)
	self.time = servertime
	self.client_counting = true
end
function Dynamite.client_stopCountdown(self, servertime)
	self.time = servertime
	self.client_counting = false
	self.interactable:setUvFrameIndex(102)
	self.showtext = 0.5
end
