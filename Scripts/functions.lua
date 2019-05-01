function debugmode() if sm.game.getCurrentTick() > 1 and not sm.isServerMode() then local modders = {["Mini"] = true, ["Brent Batch"] = true, ["TechnologicNick"] = true} local name = sm.localPlayer.getPlayer().name if modders[name] then function debugmode() return true end return true else function debugmode() return false end return false end end end

function debug(...) if debugmode() then print(...) end end

if sm.interactable.SEversion and (sm.interactable.SEversion <= 1.0) then return end
sm.interactable.SEversion = 1.0

-- interactable: setValue getValue
if not sm.interactable.values then sm.interactable.values = {} end -- stores values --[[{{tick, value}, lastvalue}]]

function sm.interactable.setValue(interactable, value)  
    local currenttick = sm.game.getCurrentTick()
    sm.interactable.values[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        sm.interactable.values[interactable.id] and (    
            sm.interactable.values[interactable.id][1] ~= nil and 
            (sm.interactable.values[interactable.id][1].tick < currenttick) and 
            sm.interactable.values[interactable.id][1].value or 
			sm.interactable.values[interactable.id][2]
        ) 
        or nil
    }
end
if not printO then
    printO = print
end
function print(...)
    printO("[" .. sm.game.getCurrentTick() .. "]", sm.isServerMode() and "[Server]" or "[Client]", ...)
end
function sm.interactable.getValue(interactable, NOW)    
	if sm.exists(interactable) and sm.interactable.values[interactable.id] then
		if sm.interactable.values[interactable.id][1] and (sm.interactable.values[interactable.id][1].tick < sm.game.getCurrentTick() or NOW) then
			return sm.interactable.values[interactable.id][1].value[1]
		elseif sm.interactable.values[interactable.id][2] then
			return sm.interactable.values[interactable.id][2][1]
		end
	end
	return nil
end
function instantiateValueHack(interactable)
	interactable.setValue = sm.interactable.setValue
	interactable.getValue = sm.interactable.getValue
end
-- sm.interactable.getValue(parents[1]) or parents[1].power