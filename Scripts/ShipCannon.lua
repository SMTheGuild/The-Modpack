--[[
	Copyright (c) 2020 Modpack Team
]]--
dofile "Libs/LoadLibs.lua"


mpPrint("loading ShipCannon.lua")


-- Barrel1 1x --

Barrel1 = class( nil )
Barrel1.maxChildCount = 0
Barrel1.maxParentCount = 1
Barrel1.connectionInput = sm.interactable.connectionType.logic
Barrel1.connectionOutput = sm.interactable.connectionType.none
Barrel1.colorNormal = sm.color.new( 0xcb0a00ff )
Barrel1.colorHighlight = sm.color.new( 0xee0a00ff )
Barrel1.poseWeightCount = 1
Barrel1.fireDelay = 8 --ticks
Barrel1.minForce = 125
Barrel1.maxForce = 130
Barrel1.spreadDeg = 1

function Barrel1.server_onFixedUpdate( self, timeStep )
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active
	if active and not self.reload then
		self.reload = self.fireDelay
		self:server_shoot()
	end

	if self.reload then
		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end
end

function Barrel1.server_shoot( self )
	firePos = sm.vec3.new( 0.0, 0.0, 0.0 )
	fireForce = math.random( self.minForce, self.maxForce )

	local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), self.spreadDeg )
	
	sm.projectile.shapeFire( self.shape, "potato", firePos, dir * fireForce )
				
	self.network:sendToClients( "client_onShoot" )
	local mass = sm.projectile.getProjectileMass( "potato" )
	local impulse = dir * -fireForce * mass * 0.8
	
	sm.physics.applyImpulse( self.shape, impulse )
end

-- Client

function Barrel1.client_onCreate( self )
	self.shootEffect = sm.effect.createEffect("MountedPotatoRifle - Shoot", self.interactable)
end

function Barrel1.client_onShoot( self )
	self.shootEffect:start()
end
