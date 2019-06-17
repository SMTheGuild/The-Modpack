if __InteractableImprovements_Loaded then return end
__InteractableImprovements_Loaded = true
dofile "../Debugger.lua"
mpPrint("loading Libs/GameImprovements/interactable.lua")

local values = {} -- <<not accessible for other scripts
function sm.interactable.setValue(interactable, value)  
    local currenttick = sm.game.getCurrentTick()
    values[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        values[interactable.id] and (    
            values[interactable.id][1] ~= nil and 
            (values[interactable.id][1].tick < currenttick) and 
            values[interactable.id][1].value or 
			values[interactable.id][2]
        ) 
        or nil
    }
end
function sm.interactable.getValue(interactable, NOW)    
	if sm.exists(interactable) and values[interactable.id] then
		if values[interactable.id][1] and (values[interactable.id][1].tick < sm.game.getCurrentTick() or NOW) then
			return values[interactable.id][1].value[1]
		elseif values[interactable.id][2] then
			return values[interactable.id][2][1]
		end
	end
	return nil
end


-- to activate   <interactable>:setValue(somevalue)
-- perform   sm.ImproveUserData(self)   in   scriptclass.(server/client)_onCreate(self)

if not sm.UserDataImprovements then 
	sm.UserDataImprovements = {}
	function sm.ImproveUserData(self)
		for k, improvement in pairs(sm.UserDataImprovements) do
			improvement(self)
		end
		function sm.ImproveUserData(self) end -- 'remove' function to prevent multiple loads
	end
end

table.insert(
	sm.UserDataImprovements, 
	function(self)
		self.interactable.setValue = sm.interactable.setValue
		self.interactable.getValue = sm.interactable.getValue
	end
)