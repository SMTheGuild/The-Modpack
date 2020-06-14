--[[
	Copyright (c) 2019 Scrap Essentials Team
]]--

-- Scrap Essentials Loader v1.1

if __SE_Loaded then return end
__SE_Loaded = true
print("Loading Libraries")

se = se or {} -- single mod env
sm.__SE = sm.__SE or {} -- scrapessentials cross mod env

sm.__SE_Version = sm.__SE_Version or {} -- TODO: get rid of this

dofile "Debugger.lua"
dofile "Color.lua"
dofile "MoreMath.lua"
dofile "Other.lua"
dofile "VirtualButtons.lua"
dofile "GameImprovements/interactable.lua"


print('══════════════════════════════════════════')
print('═══   Scrap Essentials By Awesome Modders   ═══')
print('══════════════════════════════════════════')