dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua") --to get the uuids of consumable items

local _sm_getEnableFuelConsumption = sm.game.getEnableFuelConsumption

function mp_fuel_consumeFuelPoints(self, power, multiplier, dt)
	if _sm_getEnableFuelConsumption() then
		local abs_power = math.abs(power) * multiplier
		self.sv_fuel_points = self.sv_fuel_points - (abs_power * dt) --calculate fuel consumption
	end
end

function mp_fuel_updateFuelConsumption(self, obj_uuid, fuel_points)
	if not _sm_getEnableFuelConsumption() or self.sv_fuel_points > 0 then return end

	local parents = self.interactable:getParents(sm.interactable.connectionType.gasoline)
	for k, v in pairs(parents) do
		local gas_container = v:getContainer()

		if sm.container.canSpend(gas_container, obj_uuid, 1) then
			sm.container.beginTransaction()
			sm.container.spend(gas_container, obj_uuid, 1, true)

			if sm.container.endTransaction() then
				self.sv_fuel_points = fuel_points
				break
			end
		end
	end
end

function mp_fuel_displayOutOfFuelMessage(self)
	local l_player = sm.localPlayer.getPlayer()
	local l_character = l_player:getCharacter()

	if l_character then
		if (self.shape.worldPosition - l_character.worldPosition):length2() < 100 then
			sm.gui.displayAlertText("#{INFO_OUT_OF_FUEL}")
		end
	end
end