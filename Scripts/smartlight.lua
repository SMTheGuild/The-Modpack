-- smart lights

lightblock = class( nil )
lightblock.maxParentCount = -1
lightblock.maxChildCount = -1
lightblock.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
lightblock.connectionOutput = sm.interactable.connectionType.power
lightblock.colorNormal = sm.color.new( 0xD8D220ff )
lightblock.colorHighlight = sm.color.new( 0xF2EC3Cff )
lightblock.poseWeightCount = 1


function lightblock.client_onCreate(self)
	self:client_init()
end

function lightblock.client_init(self)
    self.effect = sm.effect.createEffect("ModLightCube", self.interactable)
	self.effect:setParameter("intensity", 0)
	self.effect:setParameter("radius", 0)
    self.effect:start()
	self.colorinputs = {}
end


function lightblock.client_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local radius = nil
	local intensity = nil
	local colorinputs = {} -- parents that give color
	local activated = true
	for key, input in pairs(parents) do
		if input:getType() == "scripted" and tostring(input:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if not (tostring(input:getShape():getShapeUuid()) == "7947150d-a21c-4195-a4a8-76aab023ba3c" --[[lightblock]] or
				tostring(input:getShape():getShapeUuid()) == "16345832-ff39-4bba-9b35-8e568c61378b" --[[smartlight]] or
				tostring(input:getShape():getShapeUuid()) == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9" --[[colorblock]]) then
				
				if tostring(sm.shape.getColor(input:getShape())) == "eeeeeeff" then 
					-- intensity
					intensity = (intensity and intensity or 0) + input.power/100
				elseif tostring(sm.shape.getColor(input:getShape())) == "222222ff" then 
					-- radius
					radius = (radius and radius or 0) + input.power
				else
					-- color number input
					table.insert(colorinputs, input)
				end
			else -- lightblock, smartlight, colorblock
				table.insert(colorinputs, input)
			end
		else
			-- logic
			if input.power == 0 then activated = false end
		end
	end
	if not intensity then intensity = 0.3 end -- defaults
	if not radius then radius = 10 end
	self.activated = activated
	
	self.colorinputs = colorinputs
	
	local color = self.shape.color
	if self.activated then 
		if color ~= self.color then 
			self.effect:setParameter("color", self.shape.color)
		end
		if intensity ~= self.intensity then
			self.effect:setParameter("intensity", intensity*100)
		end
		if radius ~= self.radius then
			self.effect:setParameter("radius", radius)
		end
	else
		self.effect:setParameter("intensity", 0)
		self.effect:setParameter("radius", 0)
		self.effect:setParameter("color", sm.color.new(0,0,0))
	end
	self.color = color
	self.intensity = intensity
	self.radius = radius
end


function lightblock.server_onFixedUpdate( self, dt )
	local parents = self.colorinputs
	
	if not parents then return end
	for key, input in pairs(parents) do
		if not sm.exists(input) then return end
		if input:getType() == "scripted" and tostring(input:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			--print(tostring(input:getShape():getShapeUuid()))
				--print('---')
			if tostring(input:getShape():getShapeUuid()) == "7947150d-a21c-4195-a4a8-76aab023ba3c" --[[lightblock]] or
				tostring(input:getShape():getShapeUuid()) == "16345832-ff39-4bba-9b35-8e568c61378b" --[[smartlight]] or
				tostring(input:getShape():getShapeUuid()) == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9" --[[colorblock]] then
				
				local power = round(input.power)%(256^3)
				local red = (power/(256^2))% 256 
				local green = (power % (256^2)/256)%256
				local blue = power % 256
				self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
			end
		end
	end
	if #parents == 1 then
		local power = round(sm.interactable.getPower(parents[1]))%(256^3)
		local red = (power/(256^2))% 256 
		local green = (power % (256^2)/256)%256
		local blue = power % 256
		self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
		
	elseif #parents == 3 then
		if self.prev and self.prev ~= 3 then -- 2 -> 3 parents event trigger 
			local hasred, hasgreen, hasblue = false, false, false
			local rr, gg, bb = sm.color.new(1, 0, 0, 1), sm.color.new(0, 1, 0, 1), sm.color.new(0, 0, 1, 1)
			local validcolored = {}
			for k, v in pairs(parents) do
				local color = v:getShape().color
				local r,g,b = color.r *255, color.g *255, color.b *255
				if r == 255 and not hasred then 
					hasred = true
					validcolored[v.id] = true
				end
				if g == 255 and not hasgreen then 
					hasgreen = true
					validcolored[v.id] = true
				end
				if b == 255 and not hasblue then 
					hasblue = true
					validcolored[v.id] = true
				end
			end
			for k, v in pairs(parents) do
				if not validcolored[v.id] then
					local color = v:getShape().color
					local r,g,b = color.r *255, color.g *255, color.b *255
					
					if g>r-9 and g>b and not hasgreen then
						hasgreen = true
						sm.shape.setColor(v:getShape(),gg)
					elseif b-4>r and b>g-1 and not hasblue then
						hasblue = true
						sm.shape.setColor(v:getShape(),bb)
					elseif not hasred then
						hasred = true
						sm.shape.setColor(v:getShape(),rr)
					elseif not hasgreen then 
						hasgreen = true
						sm.shape.setColor(v:getShape(),gg)
					elseif not hasblue then 
						hasblue = true
						sm.shape.setColor(v:getShape(),bb)
					end
				end
			end
		end
		
		
		
		if not self.prevcolor or ( parents[1]:getShape().color ~= self.prevcolor[1] or parents[2]:getShape().color ~= self.prevcolor[2] or parents[3]:getShape().color ~= self.prevcolor[3]) then
			-- input parents color changed color
			
			for k, v in pairs(parents) do -- 3 parents connected, when repainting this'll categorize the paint into red, green, blue
				local color = v:getShape().color
				local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
				
				if r==b and r==g then
					sm.shape.setColor(v:getShape(),sm.color.new(1, 0, 0, 1))
				elseif g>r-9 and g>b then
					sm.shape.setColor(v:getShape(),sm.color.new(0, 1, 0, 1))
				elseif b-4>r and b>g-1 then
					sm.shape.setColor(v:getShape(),sm.color.new(0, 0, 1, 1))
				else
					sm.shape.setColor(v:getShape(),sm.color.new(1, 0, 0, 1))
				end
			end
				
				
			-- parents were connected, color is repainted, try to swap properly if 2 the same
			if self.prevcolor then
				if parents[1]:getShape().color == parents[2]:getShape().color then
					parents[1]:getShape().color = self.prevcolor[2]
					parents[2]:getShape().color = self.prevcolor[1]
				end
				if parents[2]:getShape().color == parents[3]:getShape().color then
					parents[3]:getShape().color = self.prevcolor[2]
					parents[2]:getShape().color = self.prevcolor[3]
				end
				if parents[1]:getShape().color == parents[3]:getShape().color then
					parents[1]:getShape().color = self.prevcolor[3]
					parents[3]:getShape().color = self.prevcolor[1]
				end
			end
			
			
			
		end
		self.prevcolor = {parents[1]:getShape().color, parents[2]:getShape().color, parents[3]:getShape().color}
		
		local red = 0
		local green = 0
		local blue = 0
		for k, v in pairs(parents) do -- calculate color to set depending on input powers that are colored
			local color = v:getShape().color
			local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
			if g>r-9 and g>b then
				green = v.power
			elseif b-4>r and b>g-1 then
				blue = v.power
			else
				red = v.power
			end
		end
		self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
	end
	self.prev = #parents
	if not #parents == 3 then self.prevcolor = nil end
	
	if self.activated then
		local red = round(sm.color.getR(self.shape.color) *255)
		local green = round(sm.color.getG(self.shape.color) *255)
		local blue = round(sm.color.getB(self.shape.color) *255)
		
		self.interactable:setPower(red*256^2+ green*256 + blue)
	else
		self.interactable:setPower(0)
	end
end

function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end






smartlight = class( nil )
smartlight.maxParentCount = -1
smartlight.maxChildCount = -1
smartlight.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
smartlight.connectionOutput = sm.interactable.connectionType.power
smartlight.colorNormal = sm.color.new( 0xD8D220ff )
smartlight.colorHighlight = sm.color.new( 0xF2EC3Cff )
smartlight.poseWeightCount = 1


function smartlight.client_onCreate(self)
	self:client_init()
end

function smartlight.client_init(self)
    self.effect = sm.effect.createEffect("ModLightCube", self.interactable)
    self.effect:start()
	
	self.power = 0
	self.color = 0
	self.fakecolor = 0 -- uv
end


function smartlight.client_onFixedUpdate( self, dt )
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
				tostring(input:getShape():getShapeUuid()) == "16345832-ff39-4bba-9b35-8e568c61378b" --[[smartlight]] or
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

function smartlight.server_onFixedUpdate( self, dt )
	if self.activated then
		self.interactable:setPower(self.power)
	else
		self.interactable:setPower(0)
	end
end

