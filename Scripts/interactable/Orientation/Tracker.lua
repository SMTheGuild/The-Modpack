--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading Tracker.lua")

-- Tracker.lua --
Tracker = class( nil )
Tracker.maxParentCount = -1
Tracker.maxChildCount = 0
Tracker.connectionInput =  sm.interactable.connectionType.power
Tracker.connectionOutput = sm.interactable.connectionType.none
Tracker.colorNormal = sm.color.new( 0xaaaaaaff )
Tracker.colorHighlight = sm.color.new( 0xaaaaaaff )
if not trackertrackers then trackertrackers = {} end

function Tracker.client_onRefresh( self )
	self:client_onCreate()
end
function Tracker.client_onCreate( self )
	self.id = self.shape.id
	table.insert(trackertrackers, self)
end

function Tracker.client_onDestroy(self)
	for k, v in pairs(trackertrackers) do
		if v.id == self.id then
			table.remove(trackertrackers, k)
			return
		end
	end
end

function Tracker.getTrackerShape(self)
	if not self.interactable then return self.shape end -- can't try and spoof if interactable fails
	local freq, shape = self:computeInputValues()
	return shape
end

function Tracker.getFrequency(self)
	if not self.interactable then return 0 end
	local freq, shape = self:computeInputValues()
	return freq
end

function Tracker.computeInputValues(self)
	if self.lastCompute == sm.game.getCurrentTick() then return self.currentFreq, self.currentShape end
	self.lastCompute = sm.game.getCurrentTick()
	
	self.currentFreq = 0
	local spoofed = false
	local x, y, z
	
	for k, v in pairs(self.interactable:getParents()) do
		if sm.interactable.isNumberType(v) then
			local color = v:getShape().color
			local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
			
			if r==b and r==g then -- frequency
				self.currentFreq = self.currentFreq + v.power
			elseif g>r-9 and g>b then -- g -- y
				y = (y or 0) + v.power/4
				spoofed = true
			elseif b-4>r and b>g-1 then -- b -- z
				z = (z or 0) + v.power/4
				spoofed = true
			else -- r -- x
				x = (x or 0) + v.power/4
				spoofed = true
			end
		end
	end
	
	if spoofed then
		self.currentShape = {
			worldPosition = sm.vec3.new(x or self.shape.worldPosition.x, y or self.shape.worldPosition.y, z or self.shape.worldPosition.z),
			color = self.shape.color,
			mass = self.shape.mass,
			id = self.shape.id,
			spoofed = true
		}
	else
		self.currentShape = self.shape
	end
	return self.currentFreq, self.currentShape
end