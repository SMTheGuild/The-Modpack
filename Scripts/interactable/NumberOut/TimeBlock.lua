--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]
   --
dofile "../../libs/load_libs.lua"

print("Loading TimeBlock.lua")

---@class TimeBlock : ShapeClass
---@field lastClockvalue integer
TimeBlock = class(nil)
TimeBlock.maxParentCount = 0
TimeBlock.maxChildCount = -1
TimeBlock.connectionInput = sm.interactable.connectionType.none
TimeBlock.connectionOutput = sm.interactable.connectionType.power
TimeBlock.colorNormal = sm.color.new(0xccccccff)
TimeBlock.colorHighlight = sm.color.new(0xF2F2F2ff)
TimeBlock.poseWeightCount = 0

function TimeBlock:server_onRefresh()
	sm.isDev = true
	self:server_onCreate()
end

function TimeBlock:server_onCreate()
	sm.interactable.setValue(self.interactable, os.time())
end

function TimeBlock:server_onFixedUpdate(dt)
	local clockvalue = os.time()
	if clockvalue ~= self.lastClockvalue then
		self.interactable:setPower(clockvalue) -- power overflows, only modpack parts will be able to read using getValue
		sm.interactable.setValue(self.interactable, clockvalue)
	end
	self.lastClockvalue = clockvalue
end

function TimeBlock:client_onCreate()
	self.interactable:setAnimEnabled("clock_anim", true)
end

function TimeBlock:client_onFixedUpdate(dt)
	self.interactable:setAnimProgress("clock_anim", (os.time() % 60) / 60)
end
