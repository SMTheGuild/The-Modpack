--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261 for copy pasta
]]--
dofile "../libs/load_libs.lua"

mpPrint("loading Decoupler.lua")

-- Decoupler.lua --
Decoupler = class( nil )
Decoupler.maxChildCount = 0
Decoupler.maxParentCount = 1
Decoupler.connectionInput = sm.interactable.connectionType.logic
Decoupler.connectionOutput = sm.interactable.connectionType.none
Decoupler.colorNormal = sm.color.new( 0x844040ff )
Decoupler.colorHighlight = sm.color.new( 0xb25959ff )

function Decoupler.server_onFixedUpdate(self, dt)
	local parent = self.interactable:getSingleParent()
	if parent and parent:isActive() then sm.shape.destroyPart(self.shape) end
end
