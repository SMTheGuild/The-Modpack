--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261 for copy pasta
]]--
dofile "../libs/load_libs.lua"

print("loading ToneGenerator.lua")


ToneGenerator = class( nil )
ToneGenerator.maxChildCount = 0
ToneGenerator.maxParentCount = -1
ToneGenerator.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
ToneGenerator.connectionOutput = 0
ToneGenerator.colorNormal = sm.color.new(0xaaaaaaff)
ToneGenerator.colorHighlight = sm.color.new(0xccccccff)
ToneGenerator.poseWeightCount = 1
ToneGenerator.notea = 2^(1/12)
ToneGenerator.animationspeed = 200



function ToneGenerator.client_onCreate(self)
	self.effect = sm.effect.createEffect( "tone0", self.interactable )
	self.effect:setParameter( "power", 0.0 )
	self.animation = math.floor(self.animationspeed/2)
	self.effect:start()
end
function ToneGenerator.client_onRefresh(self)
	self:client_onCreate()
end

function ToneGenerator.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local isON = false
	local frequency = 0
	local volume = nil
	local note = nil
	local wavetype = nil
	for k, v in pairs(parents) do
		if not v:hasSteering() and v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
			-- number
			local _pColor = tostring(v:getShape():getColor())
			if _pColor == "eeeeeeff" then
				note = (note and note or 0) + v.power
			elseif _pColor == "7f7f7fff" then
				frequency = frequency + v.power
			elseif _pColor == "4a4a4aff" then
				frequency = frequency + v.power
			elseif _pColor == "222222ff" then
				wavetype = (wavetype and wavetype or 0) + math.floor(v.power)
			else
				volume = (volume and volume or 0) + v.power
			end
		else
			--logic
			isON = isON or (v.power ~= 0)
		end
	end
	volume = (volume and volume or 40.0)
	wavetype = (wavetype and wavetype or 1)
	if note ~= nil and note > 0 then frequency = (27.5*(ToneGenerator.notea^(note -1))) end

	if wavetype ~= self.wavetype then
		self.effect:stop()
		if wavetype > 0 and wavetype < 5 then
			self.effect = sm.effect.createEffect( "tone"..(wavetype-1), self.interactable )
			self.effect:setParameter( "frequency", 0 )
			self.effect:setParameter( "power", 0 )
			self.frequency = 0
			self.volume = 0
			self.effect:start()
		end
		self.wavetype = wavetype
	end
	if self.effect:isPlaying() then
		if frequency ~= self.frequency then
			self.effect:setParameter( "frequency", frequency )
			self.frequency = frequency
			self.animationspeed = 1000/math.max(frequency, 0.1)
		end
		if volume ~= self.volume then
			self.effect:setParameter( "power", volume )
			self.volume = volume
		end
	end

	if isON and volume > 0 then
		self.animation = (self.animation + 1)%self.animationspeed
		self.interactable:setPoseWeight(0, math.min(math.abs(2*self.animation/self.animationspeed-1,1)))
	else
		self.effect:setParameter( "power", 0 )
		self.volume = 0
	end
end