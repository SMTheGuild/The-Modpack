if __Debugger_Loaded then return end
__Debugger_Loaded = true


function sm.checkDev(shape)   -- a '-dev' check by Brent Batch
	return false
	--[[
	if sm.isDev ~= nil then return sm.isDev end
	if lastLoaded == 1 then -- on world init dev check
		sm.isDev = true
		print('set dev mode to: ', sm.isDev)
		return true
	end
	sm.shape.createPart( shape.shapeUuid, sm.vec3.new(705,0,0), sm.quat.identity( ), false, false )
	sm.isDev = DebuggerLoads == 1
	print('set dev mode to: ', sm.isDev)
	return sm.isDev]]
end 

function sm.isMPTeam()  -- an 'is in ModpackTeam' check by Brent Batch
	if sm.game.getCurrentTick() > 0 then 
		local modders = {["Brent Batch"] = true, ["TechnologicNick"] = true, ["MJM"] = true} 
		local name = sm.player.getAllPlayers()[1].name 
		if modders[name] then 
			function sm.isMPTeam() return true end 
			return true 
		else 
			function sm.isMPTeam() return false end 
			return false 
		end 
	end
end
	
function mpPrint(...)  -- print that only works for the team.
	if sm.isMPTeam() then 
		print(...) 
	end 
end

function devPrint(...) -- can't check for dev any more :/
	if sm.isMPTeam() then 
		print(...) 
	end 
end

local printO = print
function print(...) -- fancy print by TechnologicNick
	if sm.isMPTeam() then
		printO("[" .. sm.game.getCurrentTick() .. "]", sm.isServerMode() and "[Server]" or "[Client]", ...)
	else
		printO(...)
	end
end


mpPrint('Loading Libs/Debugger.lua')