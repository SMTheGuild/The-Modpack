if __Other_Loaded then return end
__Other_Loaded = true

function getGlobal(shape, vec)
    return shape.right* vec.x + shape.at * vec.y + shape.up * vec.z
end
function getLocal(shape, vec)
    return sm.vec3.new(shape.right:dot(vec), shape.at:dot(vec), shape.up:dot(vec))
end

-- server

function mp_setActiveSafe(self, new_active)
    local sInteractable = self.interactable

    if (new_active ~= self.sv_saved_active) then
        self.sv_saved_active = new_active
        sInteractable:setActive(new_active)
    end
end

function mp_setPowerSafe(self, new_power)
    local sInteractable = self.interactable

    local should_reset = (sInteractable.power == 0 and new_power ~= 0)
    if (new_power ~= self.sv_saved_power) or should_reset then
        self.sv_saved_power = new_power

        sInteractable:setPower(new_power)
    end
end

function mp_updateOutputData(self, power, active)
    local sInteractable = self.interactable

    local should_reset = (sInteractable.power == 0 and power ~= 0)
    if (power ~= self.sv_saved_power) or should_reset then
        self.sv_saved_power = power
        sInteractable:setPower(power)

        if (active ~= self.sv_saved_active) or should_reset then
            self.sv_saved_active = active
            sInteractable:setActive(active)
        end

        sm.interactable.setValue(sInteractable, power)
    end
end