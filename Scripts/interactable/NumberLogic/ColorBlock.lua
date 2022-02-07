--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading ColorBlock.lua")


ColorBlock = class( nil )
ColorBlock.maxParentCount = 7
ColorBlock.maxChildCount = -1
ColorBlock.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
ColorBlock.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
ColorBlock.colorNormal = sm.color.new( 0xD8D220ff )
ColorBlock.colorHighlight = sm.color.new( 0xF2EC3Cff )
ColorBlock.poseWeightCount = 1

function ColorBlock.server_onCreate( self ) 
	self.power = 0
	self.glowinput = 0 -- glow of this block , turn connected lamps on/off based on this.
end
function ColorBlock.server_onProjectile(self, X, hits, four)
	local red = math.random(0,255)
	local green = math.random(0,255)
	local blue = math.random(0,255)
	self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
end

function ColorBlock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local red = 0
	local green = 0
	local blue = 0
	local HSVmode = false
	for k, parent in pairs(parents) do
		if not sm.interactable.isNumberType(parent) and 
				parent:getType() ~= "steering" and 
				tostring(parent:getShape():getShapeUuid()) ~= "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orienter]] then
			-- logic: switch, logic gate, ...
			table.remove(parents, k)
			local parentcolor = parent:getShape().color
			if not (parentcolor.r == parentcolor.g) or not (parentcolor.r == parentcolor.b) then
				HSVmode = parent.active
			end
		end
	end
	
	if #parents == 1 then
		self.power = math.round(sm.interactable.getPower(parents[1]))%(256^3)
		local red = (self.power/(256^2))% 256 
		local green = (self.power % (256^2)/256)%256
		local blue = self.power % 256
		self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
		
	elseif #parents >= 3 then
		if self.prev and self.prev < 3 then -- 2 -> 3 parents event trigger , colors parents rgb
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
		if self.prev and self.prev >= 3 and self.prev < #parents then -- rgb blocks exist, white, grey, black is now  -- BLACK is dark grey
			local haswhite, hasgrey, hasblack = false, false, false
			local validcolored = {}
			for k , v in pairs(parents) do 
				local _pColor = tostring(v:getShape():getColor())
				if _pColor == "eeeeeeff" and not haswhite then -- glow
					haswhite = true
					validcolored[v.id] = true
				elseif _pColor == "7f7f7fff" and not hasgrey then -- reflection
					hasgrey = true
					validcolored[v.id] = true
				elseif _pColor == "222222ff" and not hasblack then -- specular
					hasblack = true
					validcolored[v.id] = true
				end
			end
			local white, grey, black = sm.color.new("eeeeeeff"), sm.color.new("7f7f7fff"), sm.color.new("222222ff")
			for k, v in pairs(parents) do
				if not validcolored[v.id] then
					local color = v:getShape().color
					local r,g,b = color.r *255, color.g *255, color.b *255
					if not (r == 255 or b == 255 or g == 255) then
						if tostring(color) == tostring(white) and not haswhite then 
							haswhite = true
							v:getShape().color = white
						elseif tostring(grey) == tostring(grey) and not hasgrey then 
							hasgrey = true
							v:getShape().color = grey
						elseif tostring(black) == tostring(black) and not hasblack then 
							hasblack = true
							v:getShape().color = black
						elseif not haswhite then 
							haswhite = true
							v:getShape().color = white 
						elseif not hasgrey then 
							hasgrey = true
							v:getShape().color = grey
						elseif not hasblack then 
							hasblack = true
							v:getShape().color = black
						end
					end
				end
			end
		end
		
		
		if not self.prevcolor or (self.prevcolor and (function() for k, v in pairs(parents) do if v.color ~= self.prevcolor then return true end end end)) then
			-- input parents color changed color
			
			for k, v in pairs(parents) do -- 3 parents connected, when repainting this'll categorize the paint into red, green, blue
				local color = v:getShape().color
				local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
					
				if r==b and r==g then
					-- ignore this color, don't "opti-color" it
					if "4a4a4aff" == tostring(color) then  -- change grey to lighter grey
						v:getShape().color = sm.color.new("7f7f7fff")
					end
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
				local color = nil
				local newcolor = nil
				for k, parent in pairs(parents) do
					if self.prevcolor[k] ~= tostring(parent:getShape().color) then
						color = tostring(parent:getShape().color)
						newcolor = self.prevcolor[k]
					end
				end
				if color and newcolor then
					for k, prevcolor in pairs(self.prevcolor) do
						if prevcolor == color and parents[k] then
							parents[k]:getShape().color = sm.color.new(newcolor)
						end
					end
				end
			end
			
			
		end
		self.prevcolor = (function() local prevs = {} for k, v in pairs(parents) do table.insert(prevs, tostring(v:getShape().color)) end return prevs end)()
			
		
		local red = 0
		local green = 0
		local blue = 0
		for k, v in pairs(parents) do -- calculate color to set depending on input powers that are colored
			local color = v:getShape().color
			local r,g,b = sm.color.getR(color) *255,sm.color.getG(color) *255, sm.color.getB(color) *255
			if r==b and r==g then
				-- left column, do nothing
			elseif g>r-9 and g>b then
				green  = v.power
			elseif b-4>r and b>g-1 then
				blue = v.power
			else
				red = v.power
			end
		end
		if HSVmode then
			local rgb = sm.color.toRGB({ h = red, s = green, v = blue })
			--print("hsv:", red, green, blue)
			--print("rgb:", rgb, tostring(rgb))
			self.shape.color = rgb
		else
			self.shape.color = sm.color.new(red/255, green/255, blue/255, 1)
		end
	end
	self.prev = #parents
	if parents and #parents < 3 then self.prevcolor = nil end
	
	local color = self.shape.color
	if color ~= self.color then
		local red = math.round(sm.color.getR(self.shape.color) *255)
		local green = math.round(sm.color.getG(self.shape.color) *255)
		local blue = math.round(sm.color.getB(self.shape.color) *255)
		self.power = (red*256^2+ green*256 + blue)
	end
    
    for k,v in pairs(self.interactable:getChildren()) do
        if v.type == "pointLight" or v.type == "spotLight" then
            if v.shape.color ~= color then
                v.shape.color = color
            end
        end
	end
	
	

	-- temp fix to remove glow/spec/refl
	for k, v in pairs(parents) do
		local _pUuid = tostring(v:getShape():getShapeUuid())
		if _pUuid == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9" --[[rgb block]] then break end
		local _pColor = tostring(v:getShape():getColor())
		if _pColor == "eeeeeeff" then -- glow
			v:disconnect(self.interactable)
			self.network:sendToClients("client_giveError", "glow feature currently not supported untill the devs fix this.")
		elseif _pColor == "7f7f7fff" then -- reflection
			v:disconnect(self.interactable)
			self.network:sendToClients("client_giveError", "reflection feature currently not supported untill the devs fix this.")
		elseif _pColor == "222222ff" then -- specular
			v:disconnect(self.interactable)
			self.network:sendToClients("client_giveError", "specular feature currently not supported untill the devs fix this.")
		end
	end


    
	self.color = color
	mp_updateOutputData(self, self.power, self.glowinput > 0)
end

function ColorBlock.client_onCreate(self)
	--self.interactable:setGlowMultiplier(0)
	self.glowinput = 0 -- glow of this block , turn connected lamps on/off based on this.
end


function ColorBlock.client_giveError(self, error)
	sm.gui.displayAlertText(error)
end

--[[
function ColorBlock.client_onFixedUpdate( self, dt )
	local uv = 0
	local parentrgb = nil
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if tostring(v.shape:getShapeUuid()) == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9"  then --rgb block
			self.interactable:setUvFrameIndex(v:getUvFrameIndex())
			self.glowinput = v:getGlowMultiplier()
			parentrgb = true
		elseif tostring(v:getShape().color) == "eeeeeeff" then -- glow
			self.glowinput = math.max(0,math.min(1,v.power))
		elseif tostring(v:getShape().color) == "7f7f7fff" then -- reflection
			uv = uv + math.max(0,math.min(255,v.power))
		elseif tostring(v:getShape().color) == "222222ff" then -- specular
			uv = uv + math.max(0,math.min(255,v.power))*256
		end
	end

	self.interactable:setGlowMultiplier(self.glowinput * math.random()/100) -- why do i have to throw in a random amount in order to get an updated value? why does glow reset to 1 when the color changes???? 
	if not parentrgb then
		self.interactable:setUvFrameIndex(uv)
	end
end]]