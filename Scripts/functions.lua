

if sm.interactable.SEversion and (sm.interactable.SEversion <= 1.0) then return end
sm.interactable.SEversion = 1.0

-- interactable: setValue getValue
if not sm.interactable.values then sm.interactable.values = {} end -- stores values --[[{{tick, value}, lastvalue}]]

function sm.interactable.setValue(interactable, value)  local currenttick = sm.game.getCurrentTick() sm.interactable.values[interactable.id] = {{tick = currenttick, value = value}, sm.interactable.values[interactable.id] and (sm.interactable.values[interactable.id][1] ~= nil and (sm.interactable.values[interactable.id][1].tick < currenttick) and sm.interactable.values[interactable.id][1].value or sm.interactable.values[interactable.id][2]) or nil} end
function sm.interactable.getValue(interactable)	    	return (sm.exists(interactable) and (sm.interactable.values[interactable.id] and (sm.interactable.values[interactable.id][1] and sm.interactable.values[interactable.id][1].tick < sm.game.getCurrentTick() and sm.interactable.values[interactable.id][1].value or sm.interactable.values[interactable.id][2])) or nil) end

function instantiateValueHack(interactable)
	interactable.setValue = sm.interactable.setValue
	interactable.getValue = sm.interactable.getValue
end
-- sm.interactable.getValue(parents[1]) or parents[1].power