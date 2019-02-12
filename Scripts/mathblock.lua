
-- mathblock.lua --
mathblock = class( nil )
mathblock.maxParentCount = -1
mathblock.maxChildCount = -1
mathblock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.seated
mathblock.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
mathblock.colorNormal = sm.color.new( 0x0E388Cff )
mathblock.colorHighlight = sm.color.new( 0x214DA5ff )
mathblock.poseWeightCount = 1


function mathblock.server_onCreate( self ) 
	self:server_init()
end

function mathblock.server_init( self ) 
	self.lastmode = 0
	self.mode = 1
	self.power = 0
	self.forceprint = false
	self.showdescriptions = true
	self.modetable = {--"value" aka "savevalue", gets saved, gets loaded.
	--change order of following array to change cycle order:
		{value = 00, name = "+"         ,description = "\nadds all number inputs together and outputs the sum of them"},
		{value = 01, name = "-"         ,description = "\nsubtracts white input from black input and outputs the number, \neither of the 2 can be colored white or black to work, \nnot coloring either the appropriate color will cause subtraction of first connected - 2nd connected"},
		{value = 02, name = "x"         ,description = "\noutputs the multiplication of all inputs"},
		{value = 03, name = "/"         ,description = "\noutputs the division of white input by non-white input, \nwhen more than 2 inputs be sure to color appropriate inputs white!"},
		{value = 04, name = "modulus"   ,description = "\noutputs the rest after dividing white input by non-white input, \nwhen more than 2 inputs: adds together whites and gets rest after dividing by non-whites"},
		{value = 05, name = "squared"   ,description = "\noutputs white to the power of non-white\n1 input: input squared\n2+inputs: whites added together to the power of (sum of non-whites)"},
		{value = 06, name = "root"      ,description = "\noutputs white to the root of non-white\n1 input: input square-root\n2+inputs: whites added together to the root of (sum of non-whites)"},
		{value = 17, name = "absolute"  ,description = "\noutputs the positive value of the input (-5 -> 5, 5-> 5)\nmoreinputs: sums all positive values of the inputs (-3,-2,1->output=6)"},
		{value = 28, name = "hypotenuse",description = "\noutputs the hypotenuse of the 2 inputs\noutput=(a^2+b^2)^(1/2)"},
		{value = 23, name = "log"       ,description = "\noutputs the logarithm of the non-white input with base white input\n1 input: base defaults to 'e'"},
		{value = 24, name = "exp"       ,description = "\noutputs value of 'e' to the power of input(s)\nno inputs: output will be e^1 aka 'e'"},
		{value = 33, name = "factorial" ,description = "\ntakes the factorial of the floored sum of the inputs\n('floor' in case there are inputs like 1.5)"},
		{value = 32, name = "bitmem"    ,description = "\ninputs: white / non-white\nwhite input defines the action: 0=flip, 1=set, 2=reset, no white= flip\nwhen all non-white inputs are active(not 0 for numbers), the action will be taken,\nin case of flip it'll flip every tick all inputs are on, set will turn it on, reset will turn it off.\n\nnifty replacedment for selfwired xor/other memorory's"},
		{value = 18, name = "floor"     ,description = "\nfloors the input(0.9999->0)\nmore than one input: floors inputs , then adds together"},
		{value = 19, name = "round"     ,description = "\nrounds the input(0.499->0, 0.5->1)\nmore than one input: rounds inputs, then adds together"},
		{value = 20, name = "ceil"      ,description = "\nrounds the inputs up(0.01->1)\nmore than one input: floors inputs up, then adds together"},
		{value = 21, name = "min"       ,description = "\noutputs the lowest input value"},
		{value = 22, name = "max"       ,description = "\noutputs the higest input value"},
		{value = 34, name = "PID"       ,description = "proportional integral derivative \nblack: process value \nwhite: set value \norange: P multiplier\nred: I multiplier \npurple: D multiplier \n3rd row orange: limit output(default: 4096) \n3rd row red: i time(between 10-1200 ticks)(default value:400) \n3rd row purple: d time(between 1-20 ticks)"},
		{value = 12, name = "sinus"     ,description = "\noutputs the sinus of the input, input in degrees\nmultiple inputs: sinus(sum of inputs)"},
		{value = 13, name = "cosinus"   ,description = "\noutputs the cosinus of the input, input in degrees\nmultiple inputs: cosinus(sum of inputs)"},
		{value = 14, name = "tan"       ,description = "\noutputs the tangens of the input, input in degrees\nmultiple inputs: tangens(sum of inputs)"},
		{value = 25, name = "arcsin"    ,description = "\noutputs the inverse sinus of the input in degrees, input between -1 and 1\nmultiple inputs: arcsinus(sum of inputs)"},
		{value = 26, name = "arccos"    ,description = "\noutputs the inverse cosinus of the input in degrees, input between -1 and 1\nmultiple inputs: arccosinus(sum of inputs)"},
		{value = 27, name = "arctan"    ,description = "\noutputs the inverse tangens of the input in degrees\nmultiple inputs: arctangens(sum of inputs)"},
		{value = 35, name = "arctan2"    ,description = "\noutputs the inverse tangens of the inputs (white & black) in degrees\nmultiple inputs: arctangens2(whites, blacks)\narctan*2* because it works for all 4 quadrants -> 2 inputs!(black&white)"},
		{value = 15, name = "pi"        ,description = "\nno inputs, outputs PI \n(3.141592653589793238462643383279502884197169399375\n10582097494459230781640628620899862803482534211706\n79821480865132823066470938446095505822317253594081\n28481117450284102701938521105559644622948954930381\n9644288109756659334461284756482337867831652712019)"},
		{value = 16, name = "random"    ,description = "\ninputs: logic, number\nno inputs: outputs random value between 0 and 1,\nlogic input will let it generate a new random number\nnumber input(s) define the range within to generate an integer value\n(input: 5 -> output 1/2/3/4/5, input: -2, 3 -> output: -2/-1/0/1/2/3)"},
		{value = 10, name = ">="        ,description = "\nbecomes active(1) when the white input is bigger or equal than the non-white input\nmore parents: active when sum of whites is bigger or equal sum of non-whites"},
		{value = 11, name = "<="        ,description = "\nbecomes active(1) when the white input is smaller or equal than the non-white input\nmore parents: active when sum of whites is smaller or equal sum of non-whites"},
		{value = 07, name = ">"         ,description = "\nbecomes active(1) when the white input is bigger than the non-white input\nmore parents: active when sum of whites is bigger than sum of non-whites"},
		{value = 08, name = "<"         ,description = "\nbecomes active(1) when the white input is smaller than the non-white input\nmore parents: active when sum of whites is smaller than sum of non-whites"},
		{value = 09, name = "="         ,description = "\nbecomes active(1) when all inputs are equal"},
		{value = 29, name = "seated"    ,description = "\nbecomes active and outputs the value of input seats occupied"},
		{value = 30, name = "A/D"       ,description = "\noutputs the A/D value, range: -1 to 1\nmultiple driverseat inputs: average of A/D output of inputs,\nexcellent for teamwork"},
		{value = 31, name = "W/S"       ,description = "\noutputs the W/S value, range: -1 to 1\nmultiple driverseat inputs: average of W/S output of inputs,\nexcellent for teamwork"},
	}
	local savemodes ={}
	for k,v in pairs(self.modetable) do
	   savemodes[v.value]=k
	end
	local stored = self.storage:load()
	if stored then
		if type(stored) == "number" then
			self.mode = savemodes[stored]	
		elseif type(stored) == "table" then
			self.mode = savemodes[stored.mode]
			self.power = stored.power
		end
	else
		self.storage:save( {mode = self.modetable[self.mode].value, power = self.power})
	end
	if not Gnumbers then Gnumbers = {} end
	self.id = self.shape.id
	Gnumbers[self.shape.id] = self.power
end
function mathblock.server_onDestroy(self)
	Gnumbers[self.id] = nil
end

function mathblock.client_onCreate(self)
	self.clientmode = 0
	self.network:sendToServer("server_senduvtoclient")
end
function mathblock.server_senduvtoclient(self)
	self.network:sendToClients("client_setMode", self.modetable[self.mode].value)
	--[[
	if self.power == 0 then
		self.network:sendToClients("client_setUvframeIndex", self.modetable[self.mode].value + 0)
		self.interactable:setActive(false)
	else
		self.network:sendToClients("client_setUvframeIndex", self.modetable[self.mode].value + 128)
		self.interactable:setActive(true)
	end]]
end
function mathblock.server_onRefresh( self )
	self.clientmode = 0
	self:server_init()
end
function mathblock.client_onInteract(self)
	local crouching = sm.localPlayer.getPlayer().character:isCrouching()
	self.network:sendToServer("server_changemode", crouching)
end

function mathblock.server_changemode(self, crouch)
	local parents = self.interactable:getParents()
	for k,v in pairs(parents) do
		if (v:getType() == "seat" or v:getType() == "steering") and v:isActive() then
			
			return 0
		end
	end
	if self.seatconnected then return 0 end
	self.mode = self.mode + (crouch and -1 or 1)
	if self.mode > #self.modetable then self.mode = 1 end
	if self.mode < 1 then self.mode = #self.modetable end
	
	self.storage:save( {mode = self.modetable[self.mode].value, power = self.power})-- +1 is workaround for storage bug
	self.network:sendToClients("client_playsound", "GUI Inventory highlight")
	self.doprint = true
	if self.forceprint then dofile("C:/test") end--assert(false, "forcedprint") end
end
function mathblock.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end

function mathblock.server_onFixedUpdate( self, dt )
	if self.doprint then
		if self.forceprint then print('\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n') end --clear error from screen
		print('mode:', self.modetable[self.mode].name)
		if self.showdescriptions then print('description:', self.modetable[self.mode].description,'\n') end
		self.doprint = false
	end
	local mode = self.modetable[self.mode].value
	
	local parents = self.interactable:getParents()
	self.seatconnected = false
	--if parents then
		if not(mode == 29 or mode == 30 or mode == 31) then
			for k,v in pairs(parents) do
				if v:getType() == "seat" then 
					--sm.interactable.disconnect(v, self.interactable) 
					--print('please remove seat')
				end
			end
		end
		if mode ~= 16 and not(mode == 29 or mode == 30 or mode == 31 or mode == 32 or mode == 2) then
			for k,v in pairs(parents) do
				if v:getType() ~= "scripted" then 
					--sm.interactable.disconnect(v, self.interactable)
					--print('please remove non number input')
				end
			end
		end
	
		if mode == 0 then -- add
			self.power = 0
			for k,v in pairs(parents) do
				self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
			--print(Gnumbers[v:getShape().id], v:getShape().id)
			end
		elseif mode == 1 then -- subtr
			self.power = 0
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents == 1 then
				self.power = 0 - (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or sm.interactable.getPower(parents[1]))
			elseif #parents == 2 then
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					self.power = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or sm.interactable.getPower(parents[2])) - (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or sm.interactable.getPower(parents[1]))
				else
					self.power = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or sm.interactable.getPower(parents[1])) - (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or sm.interactable.getPower(parents[2]))
				end
			elseif #parents > 2 then
				local whiteinput = 0
				local nonwhiteinput = 0
				local haswhite = false
				local hasnonwhite = false
				for k, v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whiteinput = whiteinput + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
						haswhite = true
					else
						nonwhiteinput = nonwhiteinput + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
						hasnonwhite = true
					end
				end
				if haswhite and hasnonwhite then
					self.power = whiteinput - nonwhiteinput
				else
					self.power = -1*(whiteinput + nonwhiteinput)
				end
			end
			
		elseif mode == 2 then -- mult
			self.power = 1
			--print('----')
			for k,v in pairs(parents) do
				--print(sm.interactable.getPower(v))
				self.power = self.power * (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
			end
		elseif mode == 3 then  -- divide
			self.power = 1
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				--parents = self.interactable:getParents()
			--end
			if #parents == 2 then
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					self.power = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or sm.interactable.getPower(parents[2])) / (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or sm.interactable.getPower(parents[1]))
				else
					self.power = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or sm.interactable.getPower(parents[1])) / (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or sm.interactable.getPower(parents[2]))
				end
				if ((Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or sm.interactable.getPower(parents[1])) == 0 and (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or sm.interactable.getPower(parents[2])) == 0) then self.power = 1 end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = whitevalue/othervalue
			end
		
		elseif mode == 4 then  -- modulus
			self.power = 0
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents == 2 then
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[2]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[1]:getShape())) == "eeeeeeff" then
					self.power = pow1%pow2
				else
					self.power = pow2%pow1
				end
				
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = whitevalue%othervalue
			end
			
		elseif mode == 5 then  -- square
			self.power = 0
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents == 1 then 
				self.power = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power) ^ 2
			elseif #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- switch p1 p2
					self.power = pow2 ^ pow1
				else
					self.power = pow1 ^ pow2
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = whitevalue^othervalue
			end
			
		elseif mode == 6 then  -- sqrt
			self.power = 0
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents == 1 then 
				self.power = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power) ^ (1/2)
			elseif #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- switch p1 p2
					self.power = pow2 ^ (1/pow1)
				else
					self.power = pow1 ^ (1/pow2)
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = whitevalue ^ (1/othervalue)
			end
		
		elseif mode == 7 then  -- gtr
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 > pow1 then self.power = 1 end
				else
					if pow1 > pow2 then self.power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = (whitevalue>othervalue and 1 or 0)
			end
		
		elseif mode == 8 then  -- smlr
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 < pow1 then self.power = 1 end
				else
					if pow1 < pow2 then self.power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = (whitevalue<othervalue and 1 or 0)
			end
		
		elseif mode == 9 then  -- eq
			self.power = 1
			local amount = nil
			for k,v in pairs(parents) do
				if amount == nil then amount = (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) end
				if (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) ~= amount then
					self.power = 0
				end
			end
		
		elseif mode == 10 then  -- bigger than or eq
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 >= pow1 then self.power = 1 end
				else
					if pow1 >= pow2 then self.power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = (whitevalue>=othervalue and 1 or 0)
			end
		elseif mode == 11 then  -- smaller than or eq
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 <= pow1 then self.power = 1 end
				else
					if pow1 <= pow2 then self.power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						whitevalue = whitevalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						othervalue = othervalue + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				self.power = (whitevalue<=othervalue and 1 or 0)
			end
		
		elseif mode == 12 then  -- sin
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents > 0 then 
				for k, v in pairs(parents) do
					self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
				end
				self.power = math.sin(math.rad(self.power))
			end
		elseif mode == 13 then  -- cos
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents >0 then 
				for k, v in pairs(parents) do
					self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
				end
				self.power = math.cos(math.rad(self.power))
			end
		elseif mode == 14 then  -- tan
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents >0 then 
				for k, v in pairs(parents) do
					self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
				end
				self.power = math.tan(math.rad(self.power))
			end
		elseif mode == 15 then  -- pi
			for k, v in pairs(parents) do
				--sm.interactable.disconnect(v, self.interactable)
			end
			self.power = #parents>0 and 0 or 1
			for k, v in pairs(parents) do
				self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
			end
			self.power = self.power * math.pi
			
		elseif mode == 16 then  -- random
			--while(#parents > 3) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				--parents = self.interactable:getParents()
			--end
			
			if self.lastmode ~= mode then 
				self.power = math.random() -- generate new number upon cycling to this and no parents connected
			end
			if #parents == 1 then
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				if parents[1]:getType() == "scripted" and tostring(parents[1]:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
					if (self.lastparentvalue == nil or self.lastparentvalue ~= pow1) then
						self.power = math.random(pow1)
					end
					self.lastparentvalue = pow1
				elseif pow1 ~= 0 or self.lastmode ~= mode then 
					self.power = math.random() -- button, logic, whatever, when on, generate new number
				end
			elseif #parents == 2 then
				local inputvalues = {}
				local generate = false
				for k,v in pairs(parents) do
					if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
						table.insert(inputvalues, (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) )
					else
						generate = generate or ((Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) ~= 0)
					end
				end
				if generate or (self.lastparentvalues == nil or not tablevaluesequal(self.lastparentvalues, inputvalues)) then
					if #inputvalues == 0 then
						self.power = math.random()
					elseif #inputvalues == 1 then
						self.power = math.random(inputvalues[1])
					else
						if inputvalues[1] > inputvalues[2] then
							self.power = math.random(inputvalues[2], inputvalues[1])
						elseif #inputvalues == 2 then
							self.power = math.random(inputvalues[1], inputvalues[2])
						end
					end
				end
				self.lastparentvalues = inputvalues
			elseif #parents == 3 then
				local inputvalues = {}
				local generate = false
				for k,v in pairs(parents) do
					if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
						table.insert(inputvalues, (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) )
						if #inputvalues > 2 then 
							--sm.interactable.disconnect(v, self.interactable)
						end
					else
						generate = generate or ((Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) ~= 0)
					end
				end
				if generate or (self.lastparentvalues == nil or  not tablevaluesequal(self.lastparentvalues, inputvalues)) then
					if #inputvalues == 0 then
						self.power = math.random()
					elseif #inputvalues == 1 then
						self.power = math.random(inputvalues[1])
					elseif #inputvalues == 2 then
						if inputvalues[1] > inputvalues[2] then
							self.power = math.random(inputvalues[2], inputvalues[1])
						else
							self.power = math.random(inputvalues[1], inputvalues[2])
						end
					end
				end
				self.lastparentvalues = inputvalues
			end
		elseif mode == 17 then  -- abs
			self.power = 0
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				--parents = self.interactable:getParents()
			--end
			if #parents == 1 then 
				self.power = math.abs((Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power))
			elseif #parents > 1 then
				self.power = 0 
				for k, v in pairs(parents) do
					self.power = self.power + math.abs((Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power))
				end
			end
			
		elseif mode == 18 then  -- floor
			self.power = 0
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents > 0 then 
				local floorby = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						floorby = floorby + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				if not floorby or floorby == 0 then floorby = 1 end
				self.power = math.floor(self.power/floorby)*floorby
			end
			
			
		elseif mode == 19 then  -- round
			self.power = 0
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents>0 then 
				local roundby = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						roundby = roundby + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				if not roundby or roundby == 0 then roundby = 1 end
				self.power = round(self.power/roundby)*roundby
			end
			
		elseif mode == 20 then  -- ceil
			self.power = 0
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents > 0 then 
				local roundby = 0
				for k,v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
						roundby = roundby + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
				end
				if not roundby or roundby == 0 then roundby = 1 end
				self.power = math.floor(self.power/roundby + (self.power/roundby%1 > 0 and 1 or 0) )*roundby
			end
			
		elseif mode == 21 then  -- min
			self.power = math.huge
			for k, v in pairs(parents) do
				if v.power < self.power then self.power = (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) end
			end
			if self.power == math.huge then self.power = 0 end
			
		elseif mode == 22 then  -- max
			self.power = 0-math.huge
			for k, v in pairs(parents) do
				if v.power > self.power then self.power = (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power) end
			end
			if self.power == 0-math.huge then self.power = 0 end
			
		elseif mode == 23 then  -- log
			self.power = 0
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents == 1 then 
				self.power = math.log((Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power))
			elseif #parents == 2 then 
				local pow1 = (Gnumbers[parents[1]:getShape().id] ~= nil and Gnumbers[parents[1]:getShape().id] or parents[1].power)
				local pow2 = (Gnumbers[parents[2]:getShape().id] ~= nil and Gnumbers[parents[2]:getShape().id] or parents[2].power)
				if tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff" or tostring(sm.shape.getColor(parents[2]:getShape())) == "eeeeeeff" then
					-- parent 2 = white
					self.power = math.log(pow1)/ math.log(pow2)
				else
					self.power = math.log(pow2)/ math.log(pow1)
				end
			end
			
		elseif mode == 24 then  -- exp
			self.power = math.exp(1)
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			if #parents > 0 then 
				self.power = 0
				for k,v in pairs(parents) do
					self.power = self.power + math.exp((Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power))
				end
			end
			
		elseif mode == 25 then  -- arcsin
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents >0 then 
				for k, v in pairs(parents) do
					self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
				end
				self.power = math.asin(self.power)/math.pi*180.0
			end
		elseif mode == 26 then  -- arccos
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents >0 then
				for k, v in pairs(parents) do
					self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
				end
				self.power = math.acos(self.power)/math.pi*180.0
			end
		elseif mode == 27 then  -- arctan
			--while(#parents > 1) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			if #parents >0 then 
				for k, v in pairs(parents) do
					self.power = self.power + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
				end
				self.power = math.atan(self.power)/math.pi*180.0
			end
		elseif mode == 28 then  -- hypotenuse
			--while(#parents > 2) do
				--sm.interactable.disconnect(parents[1], self.interactable)
				parents = self.interactable:getParents()
			--end
			self.power = 0
			for k, v in pairs(parents) do
				self.power = self.power + math.pow((Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power),2)
			end
			if #parents > 0 then
				self.power = math.pow(self.power, 1/2)
			end
		elseif mode == 29 then  -- seated
			for k, v in pairs(parents) do
				if not(v:getType() == "seat" or v:getType() == "steering") then
					--sm.interactable.disconnect(v, self.interactable)
					print('disconnect non seats!')
				end
			end
			parents = self.interactable:getParents()
			self.power = 0
			for k, v in pairs(parents) do
				if (v:getType() == "seat" or v:getType() == "steering") then
					self.seatconnected = true
					self.power = self.power + (v:isActive() and 1 or 0)
				end
			end
			
			
		elseif mode == 31 then  -- WS
			for k, v in pairs(parents) do
				if not(v:getType() == "steering" or tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e") then
					--sm.interactable.disconnect(v, self.interactable)
					--print('disconnect non driverseats')
				end
			end
			parents = self.interactable:getParents()
			self.power = 0
			local amountofparents = 0
			for k, v in pairs(parents) do
				--if v:getType() == "steering" or tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" or tostring(v:getShape():getShapeUuid()) == "e627986c-b7dd-4365-8fd8-a0f8707af63d" then
					amountofparents = amountofparents + 1
					self.power = self.power + v.power
				--end
			end
			if amountofparents>0 then
				self.power = math.min(1,math.max(-1,self.power/amountofparents))
			end
			
		elseif mode == 32 then  -- bitmem
			local value = 0
			local logicon = 1
			local haslogic = false
			for k, v in pairs(parents) do
				local typeparent = v:getType()
				if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
				--if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
					-- number input
					value = value + math.floor(v.power)
				else
					haslogic = true
					-- logic input 
					logicon = logicon * v.power --'ands'
				end
			end
			if logicon ~= 0 and haslogic then
				if value == 0 then
					self.power = (self.power == 0 and 1 or 0)
				elseif value == 1 then
					self.power = 1
				else 
					self.power = 0
				end
				-- save causes crash when using part for longer than 1 minute (crash happens when exiting the world)
				-- wait for patch to fix this
				--self.storage:save( {mode = self.modetable[self.mode].value +1, power = self.power + 1})
			end
			
		elseif mode == 33 then  -- factorial function
			local value = 0
			for k,v in pairs(parents) do
				value = value + v.power
			end
			self.power = 0
			value = math.floor(value)
			if value > 0 then
				self.power = 1
				while value >1 do
					self.power = self.power * value
					value = value - 1
				end
				--self.power = ((value/math.exp(1))^value)*((math.pi*(2*value+1/3))^(1/2)) + 0.01
			end
		elseif mode == 34 then  -- pid
			self.power = 0
			local processvalue = 0
			local setvalue = 0
			local p = 0
			local i = 0
			local d = 0
			local deltatime_i = nil
			local deltatime_d = nil
			local limit = nil
			
			local on = true
			for k,v in pairs(parents) do
				if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
					if tostring(sm.shape.getColor(v:getShape())) == "720a74ff" then  -- 3rd purple
						if deltatime_d == nil then deltatime_d = 0 end
						deltatime_d = deltatime_d + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "7c0000ff" then  --3rd red
						if deltatime_i == nil then deltatime_i = 0 end
						deltatime_i = deltatime_i + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "cf11d2ff" then  --purple
						d = d + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "d02525ff"  then -- red
						i = i + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "df7f00ff" then -- orange
						p = p + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then --white
						setvalue = setvalue + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "222222ff" then --black
						processvalue = processvalue + v.power
					elseif tostring(sm.shape.getColor(v:getShape())) == "673b00ff" then --black
						if limit == nil then limit = 0 end
						limit = limit + math.abs(v.power)
					end
				else 
					on = (v.power ~= 0 and on)
				end
			end
			if limit == nil then limit = 4096 end
			if deltatime_d == nil then deltatime_d = 1 end  --default value
			if deltatime_i == nil then deltatime_i = 10*40 end  --default value
			
			deltatime_d = math.max(math.min(math.floor(math.abs(deltatime_d)), 20), 1)
			deltatime_i = math.max(math.min(math.floor(math.abs(deltatime_i)), 40*30), 10)
			
			if on then
				local _error = setvalue - processvalue
				
				if self.bufferindex == nil then self.bufferindex = 0 end
				if self.buffer_d == nil then self.buffer_d = {} end
				self.buffer_d[self.bufferindex] = _error
				
				--print('----')
				--for k, v in pairs(self.buffer_d) do print(k,v) end
				
				local lasterror = (self.buffer_d[(self.bufferindex - deltatime_d)%20] == nil) and _error or self.buffer_d[(self.bufferindex - deltatime_d)%20]
				
				--print((_error - lasterror))
				
				self.power = _error * p  +  self:runningAverage({num = _error, count = deltatime_i}) * i  + (_error - lasterror) * d
				
				self.power = math.max(-limit, math.min(limit, self.power))
				
				self.bufferindex = (self.bufferindex + 1)%20
			end
			
			
		elseif mode == 35 then  -- atan2
		
			-- add all white inputs, add all blackinputs, atan2( white, black), output in angles (at least one input needs to be black or white)
			if #parents >1 then 
				local whiteinput = nil
				local blackinput = nil
				local otherinput = nil
				for k, v in pairs(parents) do
					if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then --white
						whiteinput = (whiteinput and whiteinput or 0) + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					elseif tostring(sm.shape.getColor(v:getShape())) == "222222ff" then --black
						blackinput = (blackinput and blackinput or 0) + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					else
						otherinput = (otherinput and otherinput or 0) + (Gnumbers[v:getShape().id] ~= nil and Gnumbers[v:getShape().id] or v.power)
					end
					if not whiteinput then
						whiteinput = otherinput
					elseif not blackinput then 
						blackinput = otherinput
					end
				end
				if whiteinput and blackinput then
					self.power = math.atan2(whiteinput, blackinput)/math.pi*180.0
				else
					self.power = 0
				end
			elseif #parents == 1 then
				local parentid = parents[1]:getShape().id
				local quadrant24 = (tostring(sm.shape.getColor(parents[1]:getShape())) == "222222ff")
				self.power = math.atan((Gnumbers[parentid] ~= nil and Gnumbers[parentid] or parents[1].power))/math.pi*180.0 + (quadrant24 and 90 or 0)
			else
				self.power = 0
			end
		end
	--end
	
	if self.power ~= self.power then self.power = 0 end
	if math.abs(self.power) >= 3.3*10^38 then 
		if self.power < 0 then self.power = -3.3*10^38 else self.power = 3.3*10^38 end  
	end
	if self.power ~= self.interactable.power or self.power ~= (Gnumbers[self.shape.id] ~= nil and Gnumbers[self.shape.id] or self.power) then
		self.interactable:setPower(self.power)
		self.interactable:setActive(self.power > 0)
		Gnumbers[self.shape.id] = self.power
		self.id = self.shape.id
	end
	if mode ~= self.lastmode then --or self.power ~= self.interactable.power then
		self.network:sendToClients("client_setMode", mode)
		--[[
		if self.power > 0 then
			self.network:sendToClients("client_setUvframeIndex", mode + 128)
		else
			self.network:sendToClients("client_setUvframeIndex", mode + 0)
		end]]
	end
	self.lastmode = mode
end

function mathblock.runningAverage(self, data)
  local runningAverageCount = data.count
  if self.runningAverageBuffer == nil then self.runningAverageBuffer = {} end
  if self.nextRunningAverage == nil then self.nextRunningAverage = 0 end
  
  self.runningAverageBuffer[self.nextRunningAverage] = data.num;
  self.nextRunningAverage = (self.nextRunningAverage + 1)%runningAverageCount
  
  local runningAverage = 0
  for k, v in pairs(self.runningAverageBuffer) do
	if k>=runningAverageCount then 
		v = 0
	else
		runningAverage = runningAverage + v
	end
  end
  return runningAverage / runningAverageCount;
end


function mathblock.client_onFixedUpdate(self, dt)
	if sm.isHost then
		local parents = self.interactable:getParents()
		-- host only ('self.mode')
		if self.modetable[self.mode].value == 30 then  -- AD
			for k, v in pairs(parents) do
				if not(v:getType() == "steering" or tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" or tostring(v:getShape():getShapeUuid()) == "e627986c-b7dd-4365-8fd8-a0f8707af63d") then
					--sm.interactable.disconnect(v, self.interactable)
					--print('disconnect non driverseats')
				end
			end
			parents = self.interactable:getParents()
			self.power = 0
			local amountofparents = 0
			for k, v in pairs(parents) do
				if v:getType() == "steering" or tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" or tostring(v:getShape():getShapeUuid()) == "e627986c-b7dd-4365-8fd8-a0f8707af63d" then
					amountofparents = amountofparents + 1
					self.power = self.power + (v:getPoseWeight(0)-0.5)*2
				else
					amountofparents = amountofparents + 1
					self.power = self.power + v.power
				end
			end
			if amountofparents>0 then
				self.power = math.min(1,math.max(-1,self.power/amountofparents))
			end
		end
	end
	if (self.interactable.power > 0 and not self.waspos) or (self.interactable.power <= 0 and self.waspos) then
		self.interactable:setUvFrameIndex(self.clientmode + (self.interactable.power > 0 and 128 or 0))
		self.waspos = self.interactable.power>0
	end
end

function mathblock.client_setMode(self, mode)
	self.clientmode = mode
	self.interactable:setUvFrameIndex(mode)
end


function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end

function getGlobal(shape, vec)
    return sm.shape.getRight(shape) * vec.x + sm.shape.getAt(shape) * vec.y + sm.shape.getUp(shape) * vec.z
end

function tablevaluesequal(sometable, table2)
	if #sometable ~= #table2 then return false end
	for k, v in pairs(sometable) do
		if v ~= table2[k] then return false end
	end
	return true
end



function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end
