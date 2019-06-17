debuggerLoads = (debuggerLoads or 0) + 1 -- has to be the first line of this file

-- NOTE: Reloading this file in '-dev' mode before sm.isDev is set to true will cause it to false negative. reload the world in this case.
 
if __Debugger_Loaded then return end
__Debugger_Loaded = true


function sm.checkDev(shape)   -- a '-dev' check by Brent Batch
	if sm.isDev ~= nil then return sm.isDev end
	if not worldStart then worldStart = os.clock() end
	if (os.clock() - worldStart) < 1 then debuggerLoadsOnWorldStart = debuggerLoads return false end
	sm.shape.createPart( shape.shapeUuid, sm.vec3.new(705,0,0), sm.quat.identity( ), false, false )
	sm.isDev = debuggerLoads == debuggerLoadsOnWorldStart
	print('set dev mode to: ', sm.isDev)
	return sm.isDev
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
	
function debug(...)  -- print that only works for the team.
	if sm.isMPTeam() then 
		print(...) 
	end 
end

if not printO then
    printO = print
end
function print(...) -- fancy print by TechnologicNick
	if sm.isMPTeam() then
		printO("[" .. sm.game.getCurrentTick() .. "]", sm.isServerMode() and "[Server]" or "[Client]", ...)
	else
		printO(...)
	end
end


debug('Loading Libs/Debugger.lua')