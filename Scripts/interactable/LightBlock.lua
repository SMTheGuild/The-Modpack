LightBlock = class( nil )
LightBlock.maxParentCount = -1
LightBlock.maxChildCount = -1
LightBlock.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
LightBlock.connectionOutput = sm.interactable.connectionType.power
LightBlock.colorNormal = sm.color.new( 0xD8D220ff )
LightBlock.colorHighlight = sm.color.new( 0xF2EC3Cff )
LightBlock.poseWeightCount = 1


function LightBlock.client_onCreate(self)
	self:client_init()
end

function LightBlock.client_init(self)
    self.effect = sm.effect.createEffect("ModLightCube", self.interactable)
	self.effect:setParameter("intensity", 0)
	self.effect:setParameter("radius", 0)
    self.effect:start()
	self.colorinputs = {}
end


function LightBlock.client_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local radius = nil
	local intensity = nil
	local colorinputs = {} -- parents that give color
	local activated = true
	for key, input in pairs(parents) do
		if input:getType() == "scripted" and tostring(input:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if not (tostring(input:getShape():getShapeUuid()) == "7947150d-a21c-4195-a4a8-76aab023ba3c" --[[LightBlock]] or
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
			else -- LightBlock, smartlight, colorblock
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


function LightBlock.server_onFixedUpdate( self, dt )
	local parents = self.colorinputs

	if not parents then return end
	for key, input in pairs(parents) do
		if not sm.exists(input) then return end
		if input:getType() == "scripted" and tostring(input:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			if tostring(input:getShape():getShapeUuid()) == "7947150d-a21c-4195-a4a8-76aab023ba3c" --[[LightBlock]] or
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
