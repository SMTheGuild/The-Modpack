tonegenerator = class( nil )
tonegenerator.maxChildCount = 0
tonegenerator.maxParentCount = -1
tonegenerator.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
tonegenerator.connectionOutput = 0
tonegenerator.colorNormal = sm.color.new(0xe54500ff)
tonegenerator.colorHighlight = sm.color.new(0xff7033ff)
tonegenerator.poseWeightCount = 1
tonegenerator.notea = 2^(1/12)
tonegenerator.animationspeed = 200



function tonegenerator.client_onCreate(self)
	self.effect = sm.effect.createEffect( "tone0", self.interactable )
	self.effect:setParameter( "power", 0.0 )
	self.animation = math.floor(self.animationspeed/2)
	self.effect:start()
end
function tonegenerator.client_onRefresh(self)
	self:client_onCreate()
end

function tonegenerator.client_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local isON = false
	local frequency = 0
	local volume = nil
	local note = nil
	local wavetype = nil
	for k, v in pairs(parents) do 
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
			-- number
			if tostring(v:getShape().color) == "eeeeeeff" then
				note = (note and note or 0) + v.power
			elseif tostring(v:getShape().color) == "7f7f7fff" then
				frequency = frequency + v.power
			elseif tostring(v:getShape().color) == "4a4a4aff" then
				frequency = frequency + v.power
			elseif tostring(v:getShape().color) == "222222ff" then
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
	if note ~= nil and note > 0 then frequency = (27.5*(tonegenerator.notea^(note -1))) end
	
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



totegenerator = class( nil )
totegenerator.maxChildCount = 0
totegenerator.maxParentCount = -1
totegenerator.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
totegenerator.connectionOutput = 0
totegenerator.colorNormal = sm.color.new(0xe54500ff)
totegenerator.colorHighlight = sm.color.new(0xff7033ff)
totegenerator.poseWeightCount = 1
totegenerator.notea = 2^(1/12)
totegenerator.basetone = 27.5*((2^(1/12))^(15)) -- 'C' (low C)
totegenerator.logcrap = 1/math.log(2^(1/12)) -- logarithm crap

function totegenerator.client_onCreate(self)
	self.effect = sm.effect.createEffect( "tote1", self.interactable )
	self.animation = 0
	--self.effect:setParameter( "Intensity", 40.0 )
end
function totegenerator.client_onRefresh(self)
	self:client_onCreate()
end

function totegenerator.client_onFixedUpdate(self, dt)
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
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
			-- number
			if tostring(v:getShape().color) == "eeeeeeff" then
				note = (note and note or 0) + v.power
			elseif tostring(v:getShape().color) == "7f7f7fff" then
				frequency = (frequency and frequency or 0) + v.power
			elseif tostring(v:getShape().color) == "4a4a4aff" then
				frequency = (frequency and frequency or 0) + v.power
			elseif tostring(v:getShape().color) == "222222ff" then
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
			note = math.min(25.99,math.max(0.01,math.log(frequency / totegenerator.basetone) * totegenerator.logcrap))
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