--[[
	Copyright (c) 2020 Modpack Team
	made by Brent Batch#9261
]]--
dofile "../libs/load_libs.lua"

print("loading ToteGenerator.lua")


ToteGenerator = class( nil )
ToteGenerator.maxChildCount = 0
ToteGenerator.maxParentCount = -1
ToteGenerator.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
ToteGenerator.connectionOutput = 0
ToteGenerator.colorNormal = sm.color.new(0xaaaaaaff)
ToteGenerator.colorHighlight = sm.color.new(0xccccccff)
ToteGenerator.poseWeightCount = 1
ToteGenerator.notea = 2^(1/12)
ToteGenerator.basetone = 27.5*((2^(1/12))^(15)) -- 'C' (low C)
ToteGenerator.logcrap = 1/math.log(2^(1/12)) -- logarithm crap

function ToteGenerator.client_onCreate(self)
	self.effect = sm.effect.createEffect( "tote1", self.interactable )
	self.animation = 0
	--self.effect:setParameter( "Intensity", 40.0 )
end
function ToteGenerator.client_onRefresh(self)
	self:client_onCreate()
end

function ToteGenerator.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local isON = false
	local note = nil
	local volume = nil
	local tote = nil
	local frequency = nil
--white = notes
--greys = frequency
--black = wave type/totebot type
--other = volume
	for k, v in pairs(parents) do
		if not v:hasSteering() and v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
			-- number
			local _pColor = tostring(v:getShape():getColor())
			if _pColor == "eeeeeeff" then
				note = (note and note or 0) + v.power
			elseif _pColor == "7f7f7fff" then
				frequency = (frequency and frequency or 0) + v.power
			elseif _pColor == "4a4a4aff" then
				frequency = (frequency and frequency or 0) + v.power
			elseif _pColor == "222222ff" then
				tote = ((tote and tote or 0) + math.floor(v.power))
			else
				volume = (volume and volume or 0) + v.power
			end
		else
			--logic
			isON = isON or (v.power ~= 0)
		end
	end

	if note == nil then
		if frequency ~= nil and frequency > 0 then
			note = math.min(25.99,math.max(0.01,math.log(frequency / ToteGenerator.basetone) * ToteGenerator.logcrap))
		else
			note = 1
		end
	end


	tote = (tote and tote or 1)
	note = (note and note or 1)
	volume = (volume and volume or 40.0)

	if tote ~= self.tote and tote >0 and tote < 11 then
		self.tote = tote
		self.effect:stop()
		self.effect = sm.effect.createEffect( "tote"..tote, self.interactable )
		self.note = nil
	end
	if note ~= self.note and note > 0 and note < 26 then
		self.note = note
		if tote == 10 then
			self.effect:setParameter( "velocity", note*2 ) -- 1-25  (0->1)
		else
			self.effect:setParameter( "pitch", (note-1)/24 ) -- 1-25  (0->1)
		end
	end
	-- is playing sound and sound is valid and note is valid
	if isON and tote >0 and tote < 11 and note > 0 and note < 26 then
		self.animation = math.min(1,self.animation + dt*6)
	else
		self.animation = math.max(0,self.animation - dt*6)
	end
	self.interactable:setPoseWeight(0, self.animation)

	if isON and tote >0 and tote < 11 and note > 0 and note < 26 then
		if volume ~= self.volume then
			--self.effect:setParameter( "Intensity", volume )
			self.volume = volume
		end
		if not self.effect:isPlaying() then
			self.effect:start()
		end

	else
		if self.effect:isPlaying() then
			self.effect:stop()
		end
	end
end
