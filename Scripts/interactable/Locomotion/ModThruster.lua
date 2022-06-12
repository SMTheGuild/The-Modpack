dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

ModThruster = class()
ModThruster.maxParentCount = 3
ModThruster.maxChildCount = 0
ModThruster.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power + sm.interactable.connectionType.gasoline
ModThruster.connectionOutput = sm.interactable.connectionType.none
ModThruster.colorNormal = sm.color.new(0x29CCCDff)
ModThruster.colorHighlight = sm.color.new(0x36F3F7ff)
ModThruster.poseWeightCount = 3


local PicoThrusterGears = {
	{ averageForce = 800 },
	{ averageForce = 1250 },
	{ averageForce = 1500 },
	{ averageForce = 2000 },
	{ averageForce = 3000 },
	{ averageForce = 4000 },
	{ averageForce = 5000 },
	{ averageForce = 7000 },
	{ averageForce = 9000 },
	{ averageForce = 11000 },
	{ averageForce = 15000 },
	{ averageForce = 20000 },
	{ averageForce = 25000 }
}

local OneByOneMicroThruster = {
	{ averageForce = 2222.22   },
	{ averageForce = 3333.33   },
	{ averageForce = 5000      },
	{ averageForce = 7500      },
	{ averageForce = 11250     },
	{ averageForce = 16875     },
	{ averageForce = 25312.5   },
	{ averageForce = 37968.5   },
	{ averageForce = 56953.25  },
	{ averageForce = 85429.875 },
	{ averageForce = 128144.31 },
	{ averageForce = 192216.97 },
	{ averageForce = 288325.96 }
}

local thruster_uuid_data = {
	["9235b582-fc25-48a8-a807-68d98755d077"] = {
		gears = PicoThrusterGears,
		gear_count = #PicoThrusterGears,
		effect_offset = sm.vec3.new(0, 0, -0.57)
	},
	["a07a3673-a446-44a3-b16d-abb732c7a525"] = {
		gears = OneByOneMicroThruster,
		gear_count = #OneByOneMicroThruster,
		effect_offset = sm.vec3.new(0, 0, -0.3)
	}
}

function ModThruster:client_onCreate()
	local cur_data = thruster_uuid_data[tostring(self.shape.uuid)]
	self.gears = cur_data.gears
	self.gear_count = cur_data.gear_count

	self.thrust_effect = sm.effect.createEffect("Thruster - Level 1", self.interactable)
	self.thrust_effect:setOffsetPosition(cur_data.effect_offset)
	
	self.cl_thruster_active = false
	self.cl_cur_gear  = 0
	self.cl_time_val  = 0
	self.cl_time_val2 = 0
end

function ModThruster:client_onDestroy()
	if self.thrust_effect:isPlaying() then
		self.thrust_effect:stopImmediate()
	end

	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end

	self.thrust_effect:destroy()
end

function ModThruster:client_onClientDataUpdate(params)
	local is_active = params[2]
	self.cl_thruster_active = is_active
	self.cl_cur_gear = params[1]

	local cur_weight = self.cl_cur_gear / (self.gear_count - 1)
	self.interactable:setPoseWeight(2, cur_weight)

	local th_effect = self.thrust_effect

	if is_active then
		if not th_effect:isPlaying() then
			th_effect:start()
		end
	else
		if th_effect:isPlaying() then
			th_effect:stop()
		end
	end
end

function ModThruster:client_onFixedUpdate()
	if self.cl_thruster_active then
		local vel_length = sm.util.clamp(self.shape.velocity:length2() / 25, 0, 50)
		self.thrust_effect:setParameter("velocity", vel_length)

		self.cl_time_val = self.cl_time_val + 0.2
		self.cl_time_val2 = self.cl_time_val2 + 0.8

		local light_noise = sm.noise.simplexNoise1d(self.cl_time_val) * 0.5
		self.thrust_effect:setParameter("intensity", 2 + light_noise)

		local thruster_noise = math.abs(math.sin(self.cl_time_val2)) * 0.4
		self.interactable:setPoseWeight(1, thruster_noise)
	else
		self.interactable:setPoseWeight(1, 0)
	end
end

function ModThruster:client_onSliderChange(widget, value)
	self.cl_cur_gear = value
	self.network:sendToServer("server_setGear", value)
end

function ModThruster:client_onGuiClose()
	self.gui:destroy()
	self.gui = nil
end

function ModThruster:client_onInteract(character, state)
	if state then
		local s_gui = sm.gui.createEngineGui()

		s_gui:setText("Name", "#{CONTROLLER_THRUSTER_TITLE}")
		s_gui:setText("Interaction", "#{CONTROLLER_THRUSTER_INSTRUCTION}")
		s_gui:setSliderCallback("Setting", "client_onSliderChange")
		s_gui:setOnCloseCallback("client_onGuiClose")
		s_gui:setSliderData("Setting", self.gear_count, self.cl_cur_gear)
		s_gui:setIconImage("Icon", self.shape:getShapeUuid())
		s_gui:setVisible("SubTitle", false)
		
		local fuelContainer = self.interactable:getContainer(0)
		if fuelContainer then
			s_gui:setContainer("Fuel", fuelContainer)
		end

		local externalFuelContainer, _, _ = self:getInputs()
		if externalFuelContainer then
			s_gui:setVisible("FuelContainer", true)
		end

		if not sm.game.getEnableFuelConsumption() then
			s_gui:setVisible("BackgroundGas", false)
			s_gui:setVisible("FuelGrid", false)
		end

		s_gui:open()
		self.gui = s_gui
	end
end

function ModThruster:server_onCreate()
	self.sv_thruster_active = false

	--load the thruster data
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.gearIdx == nil then
		local cur_data = thruster_uuid_data[tostring(self.shape.uuid)]

		self.saved.gearIdx = math.floor(cur_data.gear_count / 2)
	end
	if self.saved.fuelPoints == nil then
		self.saved.fuelPoints = 0
	end

	self.sv_fuel_points = self.saved.fuelPoints
	self:server_setGear(self.saved.gearIdx)
	
	--create the container or reuse the saved one
	local s_container = self.interactable:getContainer(0)
	if not s_container then
		s_container = self.interactable:addContainer(0, 1, 20)
	end

	s_container:setFilters({ obj_consumable_gas })
end

function ModThruster:server_setGear(gear)
	self.saved.gearIdx = gear
	self.sv_data_dirty = true
	self.sv_storage_dirty = true
end

function ModThruster:client_getAvailableParentConnectionCount(connectionType)
	if bit.band( connectionType, sm.interactable.connectionType.logic ) == sm.interactable.connectionType.logic then
		return 1 - #self.interactable:getParents(sm.interactable.connectionType.logic)
	end

	if bit.band( connectionType, sm.interactable.connectionType.power ) == sm.interactable.connectionType.power then
		return 1 - #self.interactable:getParents(sm.interactable.connectionType.power)
	end

	if bit.band( connectionType, sm.interactable.connectionType.gasoline ) == sm.interactable.connectionType.gasoline then
		return 1 - #self.interactable:getParents(sm.interactable.connectionType.gasoline)
	end

	return 0
end

local s_connection_type = sm.interactable.connectionType
function ModThruster:getInputs()
	local s_inter = self.interactable
	local l_container_inter = s_inter:getParents(s_connection_type.gasoline)[1]
	local l_logic           = s_inter:getParents(s_connection_type.logic)[1]
	local l_driver_seat     = s_inter:getParents(s_connection_type.power)[1]

	local l_container = nil
	if l_container_inter then
		l_container = l_container_inter:getContainer(0)
	end

	return l_container, l_logic, l_driver_seat
end

function ModThruster:client_onOutOfGas()
	local l_player = sm.localPlayer.getPlayer()
	local l_character = l_player:getCharacter()

	if l_character then
		if (self.shape.worldPosition - l_character.worldPosition):length2() < 100 then
			sm.gui.displayAlertText("#{INFO_OUT_OF_FUEL}")
		end
	end
end

function ModThruster:server_updateFuelStatus()
	if self.saved.fuelPoints ~= self.sv_fuel_points then
		self.saved.fuelPoints = self.sv_fuel_points
		self.sv_fuel_save_timer = 1

		if self.sv_fuel_points <= 0 then
			self.network:sendToClients("client_onOutOfGas")
		end
	end
end

function ModThruster:server_onFixedUpdate(dt)
	local l_container, l_logic, l_driver_seat = self:getInputs()
	local useCreativeFuel = not sm.game.getEnableFuelConsumption() and l_container == nil

	if not l_container or l_container:isEmpty() then
		l_container = self.interactable:getContainer(0)
	end

	local l_active = false
	if l_driver_seat and l_driver_seat.power > 0 then
		l_active = true
	elseif l_logic and l_logic.active then
		l_active = true
	end

	local canSpend = false
	if self.sv_fuel_points <= 0 then
		canSpend = sm.container.canSpend(l_container, obj_consumable_gas, 1)
	end

	local is_valid_active = l_active and (self.sv_fuel_points > 0 or canSpend or useCreativeFuel)
	if is_valid_active then
		local cur_power = self.gears[self.saved.gearIdx + 1].averageForce
		sm.physics.applyImpulse(self.shape, sm.vec3.new(0, 0, 0 - cur_power * dt))

		if not useCreativeFuel then
			local fuel_cost = cur_power * 0.1
			self.sv_fuel_points = self.sv_fuel_points - (fuel_cost * dt)

			if self.sv_fuel_points <= 0 then
				sm.container.beginTransaction()
				sm.container.spend(l_container, obj_consumable_gas, 1, true)
				if sm.container.endTransaction() then
					self.sv_fuel_points = 10000
				end
			end
		end
	end

	self:server_updateFuelStatus()

	if self.sv_fuel_save_timer ~= nil then
		self.sv_fuel_save_timer = self.sv_fuel_save_timer - dt

		if self.sv_fuel_save_timer < 0 then
			self.sv_fuel_save_timer = nil
			self.sv_storage_dirty = true
		end
	end

	if self.sv_thruster_active ~= is_valid_active then
		self.sv_thruster_active = is_valid_active
		self.sv_data_dirty = true
	end

	if self.sv_storage_dirty then
		self.sv_storage_dirty = false
		self.storage:save(self.saved)
	end

	if self.sv_data_dirty then
		self.sv_data_dirty = false
		self.network:setClientData({ self.saved.gearIdx, is_valid_active })
	end
end