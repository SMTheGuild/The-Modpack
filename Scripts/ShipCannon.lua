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

function Barrel1.server_onCreate( self ) 
	self:server_init()
end

function Barrel1.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function Barrel1.server_onRefresh( self )
	self:server_init()
end

function Barrel1.server_onFixedUpdate( self, timeStep )
	if not self.canFire then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self.fireDelayProgress = 0
			self.canFire = true	
		end
	end
	self:server_tryFire()
	local parent = self.interactable:getSingleParent()
	if parent then
		self.parentActive = parent:isActive()
	end
end

function Barrel1.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			self.canFire = false
			firePos = sm.vec3.new( 0.0, 0.0, 0.0 )
			fireForce = math.random( self.minForce, self.maxForce )

			local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), self.spreadDeg )
			
			sm.projectile.shapeFire( self.shape, "potato", firePos, dir * fireForce )
						
			self.network:sendToClients( "client_onShoot" )
			local mass = sm.projectile.getProjectileMass( "potato" )
			local impulse = dir * -fireForce * mass * 0.8
			
			sm.physics.applyImpulse( self.shape, impulse )
			
		end
	end
end

-- Client

function Barrel1.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot" )
end

function Barrel1.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 6
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	local pos = sm.shape.getWorldPosition( self.shape ) - self.shape.up * 0.35
	self.shootEffect:setPosition( pos )
	self.shootEffect:setRotation( rot )
end

function Barrel1.client_onShoot( self )
	self.boltValue = 1.0
	--local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 0 ), self.shape.up )
	self.shootEffect:start()
end
