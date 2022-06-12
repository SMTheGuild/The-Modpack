-- GasEngine.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

dofile("$SURVIVAL_DATA/Scripts/util.lua")

GasEngine = class()
GasEngine.maxParentCount = 2
GasEngine.maxChildCount = 255
GasEngine.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power + sm.interactable.connectionType.gasoline
GasEngine.connectionOutput = sm.interactable.connectionType.bearing
GasEngine.colorNormal = sm.color.new( 0xff8000ff )
GasEngine.colorHighlight = sm.color.new( 0xff9f3aff )
GasEngine.poseWeightCount = 1

local Gears = {
	{ power = 0 },
	{ power = 30 },
	{ power = 60 },
	{ power = 90 },
	{ power = 150 }, -- 1
	{ power = 240 },
	{ power = 390 }, -- 2
	{ power = 630 },
	{ power = 1020 }, -- 3
	{ power = 1650 },
	{ power = 2670 }, -- 4
	{ power = 4320 },
	{ power = 6990 }, -- 5
}

local GasEngine3WideGears = {
	{ power = 0    },
	{ power = 8    },
	{ power = 16   },
	{ power = 32   },
	{ power = 64   },
	{ power = 128  },
	{ power = 256  },
	{ power = 512  },
	{ power = 1024 }
}

local EngineSuspensionGears = {
	{ power = 0      },
	{ power = 8      },
	{ power = 16     },
	{ power = 32     },
	{ power = 64     },
	{ power = 128    },
	{ power = 256    },
	{ power = 512    },
	{ power = 1024   },
	{ power = 2048   },
	{ power = 4096   },
	{ power = 8192   },
	{ power = 16384  },
	{ power = 32768  },
	{ power = 65536  },
	{ power = 131072 },
	{ power = 262144 }
}

local EngineLevels = {
	["70cbacf2-ec5a-471f-9896-0ee944c581d1"] = { --Gas Engine 3-Wide
		gears = GasEngine3WideGears,
		gearCount = #GasEngine3WideGears,
		title = "Modpack Continuation",
		bearingCount = 5,
		pointsPerFuel = 15000,
		effect = "GasEngine - Level 1"
	},
	["b69bf080-2467-4360-9677-72cfd48806c9"] = { --Engine Suspension
		gears = EngineSuspensionGears,
		gearCount = #EngineSuspensionGears,
		title = "Modpack Continuation",
		bearingCount = 5,
		pointsPerFuel = 11000,
		effect = "GasEngine - Level 1"
	}
}

local RadPerSecond_100KmPerHourOn3BlockDiameterTyres = 74.074074
local RadPerSecond_1MeterPerSecondOn3BlockDiameterTyres = 2.6666667

--[[ Server ]]

function GasEngine.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, 1, 10 )
	end
	container:setFilters( { obj_consumable_gas } )

	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	assert(level)
	if level.fn then
		level.fn( self )
	end

	self.scrapOffset = 0
	self.pointsPerFuel = level.pointsPerFuel
	self.gears = level.gears
	self:server_init()
end

function GasEngine.server_onRefresh( self )
	self:server_init()
end

function GasEngine.server_init( self )

	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.gearIdx == nil then
		self.saved.gearIdx = 1
	end
	if self.saved.fuelPoints == nil then
		self.saved.fuelPoints = 0
	end

	self.power = 0
	self.motorVelocity = 0
	self.motorImpulse = 0
	self.fuelPoints = self.saved.fuelPoints
	self.hasFuel = false
	self.dirtyStorageTable = false
	self.dirtyClientTable = false

	self:sv_setGear( self.saved.gearIdx )
end

function GasEngine.sv_setGear( self, gearIdx )
	self.saved.gearIdx = gearIdx
	self.dirtyStorageTable = true
	self.dirtyClientTable = true
end

function GasEngine.sv_updateFuelStatus( self, fuelContainer )

	if self.saved.fuelPoints ~= self.fuelPoints then
		self.saved.fuelPoints = self.fuelPoints
		self.sv_fuel_save_timer = 1
	end

	local hasFuel = ( self.fuelPoints > 0 ) or sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 )
	if self.hasFuel ~= hasFuel then
		self.hasFuel = hasFuel
		self.dirtyClientTable = true
	end

end

function GasEngine.controlEngine( self, direction, active, timeStep, gearIdx )
	direction = clamp( direction, -1, 1 )
	if ( math.abs( direction ) > 0 or not active ) then
		self.power = self.power + timeStep
	else
		self.power = self.power - timeStep
	end
	self.power = clamp( self.power, 0, 1 )

	if direction == 0 and active then
		self.power = 0
	end

	self.motorVelocity = ( active and direction or 0 ) * RadPerSecond_100KmPerHourOn3BlockDiameterTyres
	self.motorImpulse = ( active and self.power or 2 ) * self.gears[gearIdx].power
end

function GasEngine.getInputs( self )

	local parents = self.interactable:getParents()
	local active = true
	local direction = 1
	local fuelContainer = nil
	local hasInput = false
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
			hasInput = true
		end
		if parents[2]:hasOutputType( sm.interactable.connectionType.power ) then
			active = parents[2]:isActive()
			direction = parents[2]:getPower()
			hasInput = true
		end
		if parents[2]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
			hasInput = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.power ) then
			active = parents[1]:isActive()
			direction = parents[1]:getPower()
			hasInput = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[1]:getContainer( 0 )
		end
	end

	return active, direction, fuelContainer, hasInput

end

function GasEngine.server_onFixedUpdate( self, timeStep )

	-- Check engine connections
	local hadInput = self.hasInput == nil and true or self.hasInput --Pretend to have had input if nil to avoid starting engines at load
	local active, direction, fuelContainer, hasInput = self:getInputs()
	self.hasInput = hasInput
	local useCreativeFuel = not sm.game.getEnableFuelConsumption() and fuelContainer == nil

	-- Check fuel container
	if not fuelContainer or fuelContainer:isEmpty() then
		fuelContainer = self.shape.interactable:getContainer( 0 )
	end

	-- Check bearings
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	-- Update motor gear when a steering is added
	if not hadInput and hasInput then
		if self.saved.gearIdx == 1 then
			self:sv_setGear( 2 )
		end
	end

	-- Consume fuel for fuel points
	local canSpend = false
	if self.fuelPoints <= 0 then
		canSpend = sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 )
	end

	-- Control engine
	if self.fuelPoints > 0 or canSpend or useCreativeFuel then

		if hasInput == false then
			self.power = 1
			self:controlEngine( 1, true, timeStep, self.saved.gearIdx )
		else
			self:controlEngine( direction, active, timeStep, self.saved.gearIdx )
		end

		if not useCreativeFuel then
			-- Consume fuel points
			local appliedImpulseCost = 0.015625
			local fuelCost = 0
			for _, bearing in ipairs( bearings ) do
				if bearing.appliedImpulse * bearing.angularVelocity < 0 then -- No added fuel cost if the bearing is decelerating
					fuelCost = fuelCost + math.abs( bearing.appliedImpulse ) * appliedImpulseCost
				end
			end
			fuelCost = math.min( fuelCost, math.sqrt( fuelCost / 7.5 ) * 7.5 )

			self.fuelPoints = self.fuelPoints - fuelCost

			if self.fuelPoints <= 0 and fuelCost > 0 then
				sm.container.beginTransaction()
				sm.container.spend( fuelContainer, obj_consumable_gas, 1, true )
				if sm.container.endTransaction() then
					self.fuelPoints = self.fuelPoints + self.pointsPerFuel
				end
			end
		end

	else
		self:controlEngine( 0, false, timeStep, self.saved.gearIdx )
	end

	-- Update rotational joints
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
	end

	self:sv_updateFuelStatus( fuelContainer )

	if self.sv_fuel_save_timer ~= nil then
		self.sv_fuel_save_timer = self.sv_fuel_save_timer - timeStep

		if self.sv_fuel_save_timer < 0 then
			self.sv_fuel_save_timer = nil
			self.dirtyStorageTable = true
		end
	end

	-- Storage table dirty
	if self.dirtyStorageTable then
		self.storage:save( self.saved )
		self.dirtyStorageTable = false
	end

	-- Client table dirty
	if self.dirtyClientTable then
		self.network:setClientData( { gearIdx = self.saved.gearIdx, engineHasFuel = self.hasFuel or useCreativeFuel, scrapOffset = self.scrapOffset } )
		self.dirtyClientTable = false
	end
end

--[[ Client ]]

function GasEngine.client_onCreate( self )
	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	self.gears = level.gears
	self.client_gearIdx = 1
	self.effect = sm.effect.createEffect( level.effect, self.interactable )
	self.engineHasFuel = false
	self.scrapOffset = self.scrapOffset or 0
	self.power = 0
end

function GasEngine.client_onClientDataUpdate( self, params )

	if self.gui then
		if self.gui:isActive() and params.gearIdx ~= self.client_gearIdx then
			self.gui:setSliderPosition("Setting", params.gearIdx - 1 )
		end
	end

	self.client_gearIdx = params.gearIdx
	self.interactable:setPoseWeight( 0, params.gearIdx / #self.gears )

	if self.engineHasFuel and not params.engineHasFuel then
		local character = sm.localPlayer.getPlayer().character
		if character then
			if ( self.shape.worldPosition - character.worldPosition ):length2() < 100 then
				sm.gui.displayAlertText( "#{INFO_OUT_OF_FUEL}" )
			end
		end
	end

	if params.engineHasFuel then
		self.effect:setParameter("gas", 0.0 )
	else
		self.effect:setParameter("gas", 1.0 )
	end

	self.engineHasFuel = params.engineHasFuel
	self.scrapOffset = params.scrapOffset
end

function GasEngine.client_onDestroy( self )
	self.effect:destroy()

	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function GasEngine.client_onFixedUpdate( self, timeStep )

	local active, direction, externalFuelTank, hasInput = self:getInputs()


	if self.gui then
		self.gui:setVisible( "FuelContainer", externalFuelTank ~= nil )
	end

	if sm.isHost then
		return
	end

	-- Check bearings
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	-- Control engine
	if self.engineHasFuel then
		if hasInput == false then
			self.power = 1

			self:controlEngine( 1, true, timeStep, self.client_gearIdx )
		else
		
			self:controlEngine( direction, active, timeStep, self.client_gearIdx )
		end
	else
		self:controlEngine( 0, false, timeStep, self.client_gearIdx )
	end

	-- Update rotational joints
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
	end
end

function GasEngine.client_onUpdate( self, dt )

	local active, direction = self:getInputs()

	self:cl_updateEffect( direction, active )
end

function GasEngine.client_onInteract( self, character, state )
	if state == true then
		self.gui = sm.gui.createEngineGui()

		self.gui:setText( "Name", "#{CONTROLLER_ENGINE_GAS_TITLE}" )
		self.gui:setText( "Interaction", "#{CONTROLLER_ENGINE_INSTRUCTION}" )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setSliderData( "Setting", #self.gears, self.client_gearIdx - 1 )
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setButtonCallback( "Upgrade", "cl_onUpgradeClicked" )

		local fuelContainer = self.shape.interactable:getContainer( 0 )

		if fuelContainer then
			self.gui:setContainer( "Fuel", fuelContainer )
		end

		local _, _, externalFuelContainer, _ = self:getInputs()
		if externalFuelContainer then
			self.gui:setVisible( "FuelContainer", true )
		end

		if not sm.game.getEnableFuelConsumption() then
			self.gui:setVisible( "BackgroundGas", false )
			self.gui:setVisible( "FuelGrid", false )
		end

		self.gui:open()

		local level = EngineLevels[ tostring( self.shape:getShapeUuid() ) ]
		if level then
			if level.upgrade then
				local nextLevel = EngineLevels[ level.upgrade ]
				self.gui:setData( "UpgradeInfo", { Gears = nextLevel.gearCount - level.gearCount, Bearings = nextLevel.bearingCount - level.bearingCount, Efficiency = 1 } )
				self.gui:setIconImage( "UpgradeIcon", sm.uuid.new( level.upgrade ) )
			else
				self.gui:setVisible( "UpgradeIcon", false )
				self.gui:setData( "UpgradeInfo", nil )
			end

			self.gui:setVisible("SubTitle", false)
			self.gui:setSliderRangeLimit( "Setting", level.gearCount )

			if sm.game.getEnableUpgrade() and level.cost then
				local inventory = sm.localPlayer.getPlayer():getInventory()
				local availableKits = sm.container.totalQuantity( inventory, obj_consumable_component )
				local upgradeData = { cost = level.cost, available = availableKits }
				self.gui:setData( "Upgrade", upgradeData )
			else
				self.gui:setVisible( "Upgrade", false )
			end
		end
	end
end

function GasEngine.client_getAvailableParentConnectionCount( self, connectionType )
	if bit.band( connectionType, bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.power ) ) ~= 0 then
		return 1 - #self.interactable:getParents( bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.power ) )
	end
	if bit.band( connectionType, sm.interactable.connectionType.gasoline ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.gasoline )
	end
	return 0
end

function GasEngine.client_getAvailableChildConnectionCount( self, connectionType )
	if connectionType ~= sm.interactable.connectionType.bearing then
		return 0
	end
	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	assert(level)
	local maxBearingCount = level.bearingCount or 255
	return maxBearingCount - #self.interactable:getChildren( sm.interactable.connectionType.bearing )
end

function GasEngine.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function GasEngine.cl_onSliderChange( self, sliderName, sliderPos )
	self.network:sendToServer( "sv_setGear", sliderPos + 1 )
	self.client_gearIdx = sliderPos + 1
end

function GasEngine.cl_onUpgradeClicked( self, buttonName )
	print( "upgrade clicked" )
	self.network:sendToServer("sv_n_tryUpgrade", sm.localPlayer.getPlayer() )
end

function GasEngine.cl_updateEffect( self, direction, active )
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	local RadPerSecond_100KmPerHourOn3BlockDiameterTyres = 74.074074
	local avgImpulse = 0
	local avgVelocity = 0

	if #bearings > 0 then
		for _, currentBearing in ipairs( bearings ) do
			avgImpulse = avgImpulse + math.abs( currentBearing.appliedImpulse )
			avgVelocity = avgVelocity + math.abs( currentBearing.angularVelocity )
		end

		avgImpulse = avgImpulse / #bearings
		avgVelocity = avgVelocity / #bearings

		avgVelocity = math.min( avgVelocity, RadPerSecond_100KmPerHourOn3BlockDiameterTyres )
	end

	local impulseFraction = 0
	local velocityFraction = avgVelocity / ( RadPerSecond_100KmPerHourOn3BlockDiameterTyres / 1.2 )

	if direction ~= 0 and self.gears[self.client_gearIdx].power > 0 then
		impulseFraction = math.abs( avgImpulse ) / self.gears[self.client_gearIdx].power
	end

	local maxRPM = 0.9 * (self.client_gearIdx / #self.gears)
	local rpm = 0.1

	if avgVelocity > 0 then
		rpm = rpm + math.min( velocityFraction * maxRPM, maxRPM )
	end

	local engineLoad = 0

	if direction ~= 0 then
		engineLoad = impulseFraction - math.min( velocityFraction, 1.0 )
	end

	local onLift = self.shape:getBody():isOnLift()
	if #self.interactable:getParents() == 0 then
		if self.effect:isPlaying() == false and #bearings > 0 and not onLift and self.gears[self.client_gearIdx].power > 0 then
			self.effect:start()
		elseif self.effect:isPlaying() and ( #bearings == 0 or onLift or self.gears[self.client_gearIdx].power == 0 ) then
			self.effect:setParameter( "load", 0.5 )
			self.effect:setParameter( "rpm", 0 )
			self.effect:stop()
		end
	else
		if self.effect:isPlaying() and ( #bearings == 0 or onLift or active == false or self.gears[self.client_gearIdx].power == 0 ) then
			self.effect:setParameter( "load", 0.5 )
			self.effect:setParameter( "rpm", 0 )
			self.effect:stop()
		elseif self.effect:isPlaying() == false and #bearings > 0 and not onLift and active == true and self.gears[self.client_gearIdx].power > 0 then
			self.effect:start()
		end
	end

	if self.effect:isPlaying() then
		self.effect:setParameter( "rpm", rpm )
		self.effect:setParameter( "load", engineLoad * 0.5 + 0.5 )
	end
end

function GasEngine.sv_n_tryUpgrade( self, player )

	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	if level and level.upgrade then
		local function fnUpgrade()
			local nextLevel = EngineLevels[level.upgrade]
			assert( nextLevel )
			self.gears = nextLevel.gears
			self.network:sendToClients( "cl_n_onUpgrade", level.upgrade )

			if nextLevel.fn then
				nextLevel.fn( self )
			end

			self.shape:replaceShape( sm.uuid.new( level.upgrade ) )
		end

		if sm.game.getEnableUpgrade() then
			local inventory = player:getInventory()

			if sm.container.totalQuantity( inventory, obj_consumable_component ) >= level.cost then

				if sm.container.beginTransaction() then
					sm.container.spend( inventory, obj_consumable_component, level.cost, true )

					if sm.container.endTransaction() then
						fnUpgrade()
					end
				end
			else
				print( "Cannot afford upgrade" )
			end
		end
	else
		print( "Can't be upgraded" )
	end

end

function GasEngine.cl_n_onUpgrade( self, upgrade )
	local level = EngineLevels[upgrade]
	self.gears = level.gears
	self.pointsPerFuel = level.pointsPerFuel

	if self.gui and self.gui:isActive() then
		self.gui:setIconImage( "Icon", sm.uuid.new( upgrade ) )

		if sm.game.getEnableUpgrade() and level.cost then
			local inventory = sm.localPlayer.getPlayer():getInventory()
			local availableKits = sm.container.totalQuantity( inventory, obj_consumable_component )
			local upgradeData = { cost = level.cost, available = availableKits }
			self.gui:setData( "Upgrade", upgradeData )
		else
			self.gui:setVisible( "Upgrade", false )
		end

		self.gui:setText( "SubTitle", level.title )
		self.gui:setSliderRangeLimit( "Setting", level.gearCount )
		if level.upgrade then
			local nextLevel = EngineLevels[ level.upgrade ]
			self.gui:setData( "UpgradeInfo", { Gears = nextLevel.gearCount - level.gearCount, Bearings = nextLevel.bearingCount - level.bearingCount, Efficiency = 1 } )
			self.gui:setIconImage( "UpgradeIcon", sm.uuid.new( level.upgrade ) )
		else
			self.gui:setVisible( "UpgradeIcon", false )
			self.gui:setData( "UpgradeInfo", nil )
		end
	end

	if self.effect then
		--self.effect:destroy()
	end
	self.effect = sm.effect.createEffect( level.effect, self.interactable )
	sm.effect.playHostedEffect( "Part - Upgrade", self.interactable )
end