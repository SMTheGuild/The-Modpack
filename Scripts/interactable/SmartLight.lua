


SmartLight = class( nil )
SmartLight.maxParentCount = -1
SmartLight.maxChildCount = -1
SmartLight.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
SmartLight.connectionOutput = sm.interactable.connectionType.power
SmartLight.colorNormal = sm.color.new( 0xD8D220ff )
SmartLight.colorHighlight = sm.color.new( 0xF2EC3Cff )
SmartLight.poseWeightCount = 1


function SmartLight.client_onCreate(self)
	self:client_init()
end

function SmartLight.client_init(self)
    self.effect = sm.effect.createEffect("ModLightCube", self.interactable)
    self.effect:start()

	self.power = 0
	self.color = 0
	self.fakecolor = 0 -- uv
end


function SmartLight.client_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local luminance = nil
	local coneAngle = nil
	local coneFade = nil
	local colorinputs = {} -- parents that give color
	local activated = true
	for key, input in pairs(parents) do
		if input:getType() == "scripted" and tostring(input:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if tostring(input:getShape():getShapeUuid()) == "7947150d-a21c-4195-a4a8-76aab023ba3c" --[[lightblock]] or
				tostring(input:getShape():getShapeUuid()) == "16345832-ff39-4bba-9b35-8e568c61378b" --[[SmartLight]] or
				tostring(input:getShape():getShapeUuid()) == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9" --[[colorblock]] then

				self.power = input.power
				local red = math.floor((self.power/(256^2))% 256)
				local green = math.floor((self.power % (256^2)/256)%256)
				local blue = self.power % 256
				self.color = "0x"..string.format("%x", red)..string.format("%x", green)..string.format("%x", blue).."ff"

				red = bit.tobit(math.floor(red* 32 / 64/4) % 64)
				green = bit.tobit(math.floor(green/4) % 64)
				blue = bit.tobit(math.floor(blue* 32 / 64/4) % 64)
				self.fakecolor = tonumber(tostring(bit.lshift(red,11) + bit.lshift(green,5) + blue))
				if self.fakecolor > 65534 then self.fakecolor = 65534 end -- UV setcolor hack
			else
				if tostring(sm.shape.getColor(input:getShape())) == "eeeeeeff" then
					-- luminance
					luminance = (luminance and luminance or 0) + input.power/100
				elseif tostring(sm.shape.getColor(input:getShape())) == "7f7f7fff" or tostring(sm.shape.getColor(input:getShape())) == "4a4a4aff" then
					-- coneAngle
					coneAngle = (coneAngle and coneAngle or 0) + input.power
				elseif tostring(sm.shape.getColor(input:getShape())) == "222222ff" then
					-- coneFade
					coneFade = (coneFade and coneFade or 0) + input.power/100
				else
					-- color number input
					table.insert(colorinputs, input)
				end
			end
		else
			-- logic
			if input.power == 0 then activated = false end
		end
	end
	if not luminance then luminance = 0.5 end -- defaults
	if not coneAngle then coneAngle = 25 end
	if not coneFade then coneFade = 0.5 end
	self.activated = activated

	if #colorinputs == 1 then
		self.power = round(sm.interactable.getPower(colorinputs[1]))%(256^3)
		local red = math.floor((self.power/(256^2))% 256)
		local green = math.floor((self.power % (256^2)/256)%256)
		local blue = self.power % 256
		self.color = "0x"..string.format("%x", red)..string.format("%x", green)..string.format("%x", blue).."ff"

		red = bit.tobit(math.floor(red* 32 / 64/4) % 64)
		green = bit.tobit(math.floor(green/4) % 64)
		blue = bit.tobit(math.floor(blue* 32 / 64/4) % 64)
		self.fakecolor = tonumber(tostring(bit.lshift(red,11) + bit.lshift(green,5) + blue))
		if self.fakecolor > 65534 then self.fakecolor = 65534 end -- UV setcolor hack

	elseif #colorinputs > 1 then
		local red = 0
		local green = 0
		local blue = 0
		for k, v in pairs(parents) do
			local color = sm.shape.getColor(v:getShape())
			local r = sm.color.getR(color) *255
			local g = sm.color.getG(color) *255
			local b = sm.color.getB(color) *255
			if r==b and r==g then
				--print('white column')
			elseif g>r-9 and g>b then
				--print('green!')
				green = round(v.power)
			elseif b-4>r and b>g-1 then
				--print('blue!')
				blue = round(v.power)
			else
				--print('red!')
				red = round(v.power)
			end
		end
		--print(red, green, blue)
		self.color = "0x"..string.format("%x", red)..string.format("%x", green)..string.format("%x", blue).."ff"
		self.power = (red*256^2+ green*256 + blue)

		red = bit.tobit(math.floor(red* 32 / 64/4) % 64)
		green = bit.tobit(math.floor(green/4) % 64)
		blue = bit.tobit(math.floor(blue* 32 / 64/4) % 64)
		self.fakecolor = tonumber(tostring(bit.lshift(red,11) + bit.lshift(green,5) + blue))
		if self.fakecolor > 65534 then self.fakecolor = 65534 end -- UV setcolor hack
	end

	local c = sm.shape.getColor(self.shape)
	if self.lastcolor ~= c then -- paint tool
		local red = round(sm.color.getR(c) *255)
		local green = round(sm.color.getG(c) *255)
		local blue = round(sm.color.getB(c) *255)
		self.power = (red*256^2+ green*256 + blue)
		--print(red, green, blue)
		self.color = "0x"..string.format("%x", red)..string.format("%x", green)..string.format("%x", blue).."ff"
		--print(self.color)

		red = bit.tobit(math.floor(red* 32 / 64/4) % 64)
		green = bit.tobit(math.floor(green/4) % 64)
		blue = bit.tobit(math.floor(blue* 32 / 64/4) % 64)
		self.fakecolor = tonumber(tostring(bit.lshift(red,11) + bit.lshift(green,5) + blue))
		if self.fakecolor > 65534 then self.fakecolor = 65534 end -- UV setcolor hack
	end
	self.lastcolor = c

	if self.power ~= self.power then self.power = 0 end -- NaN check
	if math.abs(self.power) >= 3.3*10^38 then -- scrap error bypass if bigger than 3.3*10^38
		if self.power < 0 then self.power = -3.3*10^38 else self.power = 3.3*10^38 end
	end

	if self.activated then
		self.interactable:setUvFrameIndex(self.fakecolor)
		self.effect:setParameter("luminance", luminance)
		self.effect:setParameter("coneAngle", coneAngle)
		self.effect:setParameter("coneFade", coneFade)
		self.effect:setParameter("color", tonumber(self.color))
	else
		self.interactable:setUvFrameIndex(0)
		self.effect:setParameter("luminance", 0)
		self.effect:setParameter("coneAngle", 0)
		self.effect:setParameter("coneFade", 0)
		self.effect:setParameter("color", 0x00000000)
	end
end

function SmartLight.server_onFixedUpdate( self, dt )
	if self.activated then
		self.interactable:setPower(self.power)
	else
		self.interactable:setPower(0)
	end
end
