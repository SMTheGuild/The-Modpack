dofile "Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if ShipCannon and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

mpPrint("loading ShipCannon.lua")

-- ShipCannon.lua --

ShipCannon = class( nil )
ShipCannon.maxChildCount = 0
ShipCannon.maxParentCount = 1
ShipCannon.connectionInput = sm.interactable.connectionType.logic
ShipCannon.connectionOutput = sm.interactable.connectionType.none
ShipCannon.colorNormal = sm.color.new( 0xcb0a00ff )
ShipCannon.colorHighlight = sm.color.new( 0xee0a00ff )
ShipCannon.poseWeightCount = 1
ShipCannon.fireDelay = 8 --ticks
ShipCannon.minForce = 125
ShipCannon.maxForce = 135
ShipCannon.spreadDeg = 1.0

function ShipCannon.server_onCreate( self ) 
	self:server_init()
end

function ShipCannon.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function ShipCannon.server_onRefresh( self )
	self:server_init()
end

function ShipCannon.server_onFixedUpdate( self, timeStep )
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

function ShipCannon.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
			local fireForce = math.random( self.minForce, self.maxForce ) * 10

			local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), self.spreadDeg )
			
			sm.projectile.shapeFire( self.shape, "potato", firePos, dir * fireForce )
			
			self.network:sendToClients( "client_onShoot" )
			local mass = sm.projectile.getProjectileMass( "potato" )
			local impulse = dir * -fireForce * mass * 0.1
			sm.physics.applyImpulse( self.shape, impulse )
		end
	end
end

-- Client

function ShipCannon.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot" )
end

function ShipCannon.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	local pos = sm.shape.getWorldPosition( self.shape ) + self.shape.up * 0.625
	self.shootEffect:setPosition( pos )
	self.shootEffect:setRotation( rot )
end

function ShipCannon.client_onShoot( self )
	self.boltValue = 1.0
	--local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	self.shootEffect:start()
end

-- CrossBow.lua --

CrossBow = class( nil )
CrossBow.maxChildCount = 0
CrossBow.maxParentCount = 1
CrossBow.connectionInput = sm.interactable.connectionType.logic
CrossBow.connectionOutput = sm.interactable.connectionType.none
CrossBow.colorNormal = sm.color.new( 0xcb0a00ff )
CrossBow.colorHighlight = sm.color.new( 0xee0a00ff )
CrossBow.poseWeightCount = 1
CrossBow.fireDelay = 8 --ticks
CrossBow.minForce = 125
CrossBow.maxForce = 130
CrossBow.spreadDeg = 1.0

function CrossBow.server_onCreate( self ) 
	self:server_init()
end

function CrossBow.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function CrossBow.server_onRefresh( self )
	self:server_init()
end

function CrossBow.server_onFixedUpdate( self, timeStep )
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

function CrossBow.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
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

function CrossBow.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot" )
end

function CrossBow.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 8
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	local pos = sm.shape.getWorldPosition( self.shape ) + self.shape.up * 0.625
	self.shootEffect:setPosition( pos )
	self.shootEffect:setRotation( rot )
end

function CrossBow.client_onShoot( self )
	self.boltValue = 1.0
	--local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 0 ), self.shape.up )
	self.shootEffect:start()
end

-- Launcher.lua --

Launcher = class( nil )
Launcher.maxChildCount = 0
Launcher.maxParentCount = 1
Launcher.connectionInput = sm.interactable.connectionType.logic
Launcher.connectionOutput = sm.interactable.connectionType.none
Launcher.colorNormal = sm.color.new( 0xcb0a00ff )
Launcher.colorHighlight = sm.color.new( 0xee0a00ff )
Launcher.poseWeightCount = 1
Launcher.fireDelay = 16 --ticks
Launcher.minForce = 125
Launcher.maxForce = 130
Launcher.spreadDeg = 2

function Launcher.server_onCreate( self ) 
	self:server_init()
end

function Launcher.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function Launcher.server_onRefresh( self )
	self:server_init()
end

function Launcher.server_onFixedUpdate( self, timeStep )
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

function Launcher.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			self.canFire = false
			firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
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

function Launcher.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot" )
end

function Launcher.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 6
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	local pos = sm.shape.getWorldPosition( self.shape ) + self.shape.up * 0.625
	self.shootEffect:setPosition( pos )
	self.shootEffect:setRotation( rot )
end

function Launcher.client_onShoot( self )
	self.boltValue = 1.0
	--local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 0 ), self.shape.up )
	self.shootEffect:start()
end

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


-- Barrel2 2x --

Barrel2 = class( nil )
Barrel2.maxChildCount = 0
Barrel2.maxParentCount = 1
Barrel2.connectionInput = sm.interactable.connectionType.logic
Barrel2.connectionOutput = sm.interactable.connectionType.none
Barrel2.colorNormal = sm.color.new( 0xcb0a00ff )
Barrel2.colorHighlight = sm.color.new( 0xee0a00ff )
Barrel2.poseWeightCount = 1
Barrel2.fireDelay = 8 --ticks
Barrel2.minForce = 125
Barrel2.maxForce = 130
Barrel2.spreadDeg = 1

function Barrel2.server_onCreate( self ) 
	self:server_init()
end

function Barrel2.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function Barrel2.server_onRefresh( self )
	self:server_init()
end

function Barrel2.server_onFixedUpdate( self, timeStep )
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

function Barrel2.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			self.canFire = false
			firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
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

function Barrel2.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot" )
end

function Barrel2.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 6
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	local pos = sm.shape.getWorldPosition( self.shape ) + self.shape.up * 0.4
	self.shootEffect:setPosition( pos )
	self.shootEffect:setRotation( rot )
end

function Barrel2.client_onShoot( self )
	self.boltValue = 1.0
	--local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 0 ), self.shape.up )
	self.shootEffect:start()
end

-- BarrelFlat --

BarrelFlat = class( nil )
BarrelFlat.maxChildCount = 0
BarrelFlat.maxParentCount = 1
BarrelFlat.connectionInput = sm.interactable.connectionType.logic
BarrelFlat.connectionOutput = sm.interactable.connectionType.none
BarrelFlat.colorNormal = sm.color.new( 0xcb0a00ff )
BarrelFlat.colorHighlight = sm.color.new( 0xee0a00ff )
BarrelFlat.poseWeightCount = 1
BarrelFlat.fireDelay = 8 --ticks
BarrelFlat.minForce = 125
BarrelFlat.maxForce = 130
BarrelFlat.spreadDeg = 1

function BarrelFlat.server_onCreate( self ) 
	self:server_init()
end

function BarrelFlat.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function BarrelFlat.server_onRefresh( self )
	self:server_init()
end

function BarrelFlat.server_onFixedUpdate( self, timeStep )
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

function BarrelFlat.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			self.canFire = false
			firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
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

function BarrelFlat.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot" )
end

function BarrelFlat.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 6
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	local pos = sm.shape.getWorldPosition( self.shape ) + self.shape.up * 0.05
	self.shootEffect:setPosition( pos )
	self.shootEffect:setRotation( rot )
end

function BarrelFlat.client_onShoot( self )
	self.boltValue = 1.0
	--local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 0 ), self.shape.up )
	self.shootEffect:start()
end