--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading TimeBlock.lua")

TimeBlock = class( nil )
TimeBlock.maxParentCount = 0
TimeBlock.maxChildCount = -1
TimeBlock.connectionInput = sm.interactable.connectionType.none
TimeBlock.connectionOutput = sm.interactable.connectionType.power
TimeBlock.colorNormal = sm.color.new( 0xccccccff  )
TimeBlock.colorHighlight = sm.color.new( 0xF2F2F2ff  )
TimeBlock.poseWeightCount = 2


function TimeBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function TimeBlock.server_onCreate( self ) 
	sm.interactable.setValue(self.interactable, os.time())
end

function TimeBlock.server_onFixedUpdate(self, dt)
	local clockvalue = os.time()
	if clockvalue ~= self.lastClockvalue then
		self.interactable:setPower(clockvalue) -- power overflows, only modpack parts will be able to read using getValue
		sm.interactable.setValue(self.interactable, clockvalue)
	end
	self.lastClockvalue = clockvalue
end

function TimeBlock.client_onFixedUpdate( self, dt )
	local posevalue = (os.time()%60)+30
	self.interactable:setPoseWeight(0, (math.sin(0-2*math.pi*posevalue/60)+1)/2)
	self.interactable:setPoseWeight(1, (math.cos(2*math.pi*posevalue/60)+1)/2)
end
