dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua") --to get the uuids of consumable items

function mp_fuel_updateFuelConsumption(self, obj_uuid, fuel_points)
	if not sm.game.getEnableFuelConsumption() or self.sv_fuel_points > 0 then return end

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