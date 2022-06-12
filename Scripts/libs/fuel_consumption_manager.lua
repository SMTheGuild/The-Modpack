dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua") --to get the uuids of consumable items

local _sm_getEnableFuelConsumption = sm.game.getEnableFuelConsumption

function mp_fuel_initialize(self, fuel_uuid, fuel_multiplier, connection_type)
	self.sv_fuel_points = 0
	self.sv_fuel_multiplier = fuel_multiplier
	self.sv_fuel_uuid = fuel_uuid
	self.sv_fuel_connect_type = connection_type or sm.interactable.connectionType.gasoline
end

function mp_fuel_consumeFuelPoints(self, container, power, dt)
	local abs_power = math.abs(power) * self.sv_fuel_multiplier
	self.sv_fuel_points = self.sv_fuel_points - (abs_power * dt) --calculate fuel consumption

	if self.sv_fuel_points <= 0 then
		sm.container.beginTransaction()
		sm.container.spend(container, self.sv_fuel_uuid, 1, true)
		if sm.container.endTransaction() then
			self.sv_fuel_points = 10000
		end
	end
end

function mp_fuel_getValidFuelContainer(self)
	local parents = self.interactable:getParents(self.sv_fuel_connect_type)
	for k, v in pairs(parents) do
		local gas_container = v:getContainer()

		if gas_container ~= nil then
			return gas_container
		end
	end

	return nil
end

function mp_fuel_canConsumeFuel(self, container)
	local useCreativeFuel = not _sm_getEnableFuelConsumption() and container == nil
	local canSpend = false
	if self.sv_fuel_points <= 0 and container then
		canSpend = sm.container.canSpend(container, self.sv_fuel_uuid, 1)
	end

	local is_valid_active = (self.sv_fuel_points > 0 or canSpend or useCreativeFuel)
	return is_valid_active, not useCreativeFuel
end

function mp_fuel_displayOutOfFuelMessage(self, custom_message)
	local l_player = sm.localPlayer.getPlayer()
	local l_character = l_player:getCharacter()

	if l_character then
		if (self.shape.worldPosition - l_character.worldPosition):length2() < 100 then
			sm.gui.displayAlertText(custom_message or "#{INFO_OUT_OF_FUEL}")
		end
	end
end