if _loadedModpackDebugger then return end
_loadedModpackDebugger = true

local printO = print
function print(...) -- fancy print by TechnologicNick
	printO(sm.isServerMode() and "[Server]" or "[Client]", ...)
end