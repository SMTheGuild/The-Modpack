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

local cur_version = sm.version
if tonumber(sm.version:sub(3, 3)) < 6 then
	print("Old game version found")
	mp_deprecated_game_version = true

	mp_gui_getKeyBinding = function(text)
		return sm.gui.getKeyBinding(text)
	end

	mp_gui_createGuiFromLayout = function(path)
		return sm.gui.createGuiFromLayout(path)
	end
else
	mp_gui_getKeyBinding = function(text, is_hypertext)
		return sm.gui.getKeyBinding(text, is_hypertext)
	end

	mp_gui_createGuiFromLayout = function(path, destroy_on_close, params)
		return sm.gui.createGuiFromLayout(path, destroy_on_close, params)
	end
end

dofile "debugger.lua"
dofile "color.lua"
dofile "math.lua"
dofile "other.lua"
dofile "virtual_buttons.lua"
dofile "fuel_consumption_manager.lua"
dofile "game_improvements/interactable.lua"


print('══════════════════════════════════════════')
print('═══   Scrap Essentials By Awesome Modders   ═══')
print('══════════════════════════════════════════')
