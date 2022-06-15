--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

-- MathBlock.lua --
MathBlock = class( nil )
MathBlock.maxParentCount = -1
MathBlock.maxChildCount = -1
MathBlock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic + sm.interactable.connectionType.seated
MathBlock.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
MathBlock.colorNormal = sm.color.new( 0x0E388Cff )
MathBlock.colorHighlight = sm.color.new( 0x214DA5ff )
MathBlock.poseWeightCount = 1

MathBlock.mode = 1
MathBlock.modetable = {--"value" aka "savevalue", gets saved, gets loaded.
--change order of following array to change cycle order:
	{value = 00, icon = "+",       name = "Sum"                   ,description = "Outputs the sum all number inputs."},
	{value = 01, icon = "-",       name = "Subtraction"           ,description = "Subtracts the sum of white inputs from the sum of black inputs and outputs the number.\nIf the inputs are not colored correctly, the output will be the subtraction of 1st connected - 2nd connected."},
	{value = 02, icon = "x",       name = "Multiplication"        ,description = "Outputs the multiplication of all inputs."},
	{value = 03, icon = "/",       name = "Division"              ,description = "Outputs the division of sum of white inputs by the sum of non-white input."},
	{value = 04, icon = "%",       name = "Remainder"             ,description = "Outputs the remainder after dividing the sum of white inputs by the sum of non-white inputs."},
	{value = 05, icon = "aⁿ",      name = "Power"                 ,description = "1 input: Outputs the input squared.\n\nMultiple inputs: Outputs the sum of the white inputs to the power of the sum of the non-white inputs."},
	{value = 06, icon = "√a",      name = "Root"                  ,description = "1 input: Outputs the square root of the input.\n\nMultiple inputs: Outputs the sum of white inputs to the root of the sum of non-white inputs."},
	{value = 17, icon = "|a|",     name = "Absolute value"        ,description = "Outputs the sum of the absolute values of the inputs. (E.g.: -5 → 5, 3 and -1 → 4)"},
	{value = 28, icon = "◿",       name = "Hypotenuse"            ,description = "Outputs the hypotenuse of the 2 inputs."},
	{value = 23, icon = "log",     name = "Logarithm"             ,description = "1 input: Outputs the natural logarithm (ln) of the input.\nMultiple inputs: Outputs the logarithm of the sum of the non-white input with base sum of the white inputs"},
	{value = 33, icon = "a!",      name = "Factorial"             ,description = "Takes the factorial of the floored sum of the inputs\n('floor' in case there are inputs like 1.5)"},
    {value = 24, icon = "exp",     name = "Exponential"           ,description = "No inputs: Outputs e.\n\n1 or more inputs: Outputs value of e to the power of the sum of the inputs."},
	{value = 32, icon = "bit",     name = "Memory bit"            ,description = "White input defines action: 0: flip, 1: set, 2: reset, no white: flip\nwhen all non-white inputs are active (not 0 for numbers), the action will be taken. The action will happen every tick the inputs are on."},
	{value = 18, icon = "floor",   name = "Floor"                 ,description = "Floors the input(0.9999 → 0)\nmore than one input: floors inputs , then adds together\nwhite input: round by value"},
	{value = 19, icon = "round",   name = "Round"                 ,description = "Rounds the input(0.499 → 0, 0.5 → 1)\nmore than one input: rounds inputs, then adds together\nwhite input: round by value"},
	{value = 20, icon = "ceil",    name = "Ceil"                  ,description = "Rounds the inputs up(0.01 → 1)\nmore than one input: floors inputs up, then adds together\nwhite input: round by value"},
	{value = 21, icon = "min",     name = "Lower value"           ,description = "Outputs the lowest input value"},
	{value = 22, icon = "max",     name = "Highest value"         ,description = "Outputs the higest input value"},
	{value = 34, icon = "PID",     name = "PID"                   ,description = "Proportional Integral Derivative \nblack: process value \nwhite: set value \norange: P multiplier\nred: I multiplier \npurple: D multiplier \n3rd row orange: limit output(default: 4096) \n3rd row red: i time(between 10-1200 ticks)(default value:400) \n3rd row purple: d time(between 1-20 ticks)"},
	{value = 12, icon = "sin",     name = "Sinus"                 ,description = "Outputs the sinus of the input, input in degrees\nmultiple inputs: sinus(sum of inputs)"},
	{value = 13, icon = "cos",     name = "Cosinus"               ,description = "Outputs the cosinus of the input, input in degrees\nmultiple inputs: cosinus(sum of inputs)"},
	{value = 14, icon = "tan",     name = "Tangent"               ,description = "Outputs the tangens of the input, input in degrees\nmultiple inputs: tangens(sum of inputs)"},
	{value = 25, icon = "arcsin",  name = "Arcsinus"              ,description = "Outputs the inverse sinus of the input in degrees, input between -1 and 1\nmultiple inputs: arcsinus(sum of inputs)"},
	{value = 26, icon = "arccos",  name = "Arccosinus"            ,description = "Outputs the inverse cosinus of the input in degrees, input between -1 and 1\nmultiple inputs: arccosinus(sum of inputs)"},
	{value = 27, icon = "arctan",  name = "Arctangent"            ,description = "Outputs the inverse tangens of the input in degrees\nmultiple inputs: arctangens(sum of inputs)"},
	{value = 35, icon = "arctan2", name = "2-argument arctangent" ,description = "Outputs the inverse tangens of the inputs (white & black) in degrees\nmultiple inputs: arctangens2(whites, blacks)\narctan*2* because it works for all 4 quadrants → 2 inputs!(black&white)"},
	{value = 15, icon = "π",       name = "Pi"                    ,description = "Outputs PI \n(3.14159265...)"},
	{value = 16, icon = "rand",    name = "Random"                ,description = "Inputs: logic, number\nno inputs: outputs random value between 0 and 1,\nlogic input will let it generate a new random number\nnumber input(s) define the range within to generate an integer value\n(input: 5 → output 1/2/3/4/5, input: -2, 3 → output: -2/-1/0/1/2/3)"},
	{value = 36, icon = "sgn",     name = "Sign"                  ,description = "Outputs 1 if the inputs > 0\noutputs -1 if the inputs < 0\noutputs 0 if the inputs are 0"},
	{value = 10, icon = "≥",       name = "Greater than or equals",description = "Outputs 1 when the sum of the white input is greater or equal than the sum of the non-white input"},
	{value = 11, icon = "≤",       name = "Less than or euqals"   ,description = "Outputs 1 when the sum of the white input is less or equal than the sum of the non-white input"},
	{value = 07, icon = ">",       name = "Greater than"          ,description = "Outputs 1 when the sum of the white input is greater than the sum of the non-white input"},
	{value = 08, icon = "<",       name = "Less than"             ,description = "Outputs 1 when the sum of the white input is less than the sum of the non-white input"},
	{value = 09, icon = "=",       name = "Equals"                ,description = "Outputs 1 when all inputs are equal"},
	{value = 37, icon = "≠",       name = "Does not equal"        ,description = "Outputs 1 when inputs are not equal"},
	{value = 38, icon = "X{Y}?",   name = "X{Y}?"                 ,description = "Outputs 1 when any of the black inputs is equal any of the white inputs"},
	{value = 29, icon = "seated",  name = "Seated"                ,description = "Becomes active and outputs the value of input seats occupied"},
	{value = 30, icon = "A/D",     name = "A/D"                   ,description = "Outputs the A/D value, range: -1 to 1\nMultiple driverseat inputs: average of A/D output of inputs,\nExcellent for teamwork!"},
	{value = 31, icon = "W/S",     name = "W/S"                   ,description = "Outputs the W/S value, range: -1 to 1\nMultiple driverseat inputs: average of W/S output of inputs,\nExcellent for teamwork!"},
}
MathBlock.savemodes = {}
for k,v in pairs(MathBlock.modetable) do
   MathBlock.savemodes[v.value]=k
end

MathBlock.modeFunctions = {
	[0] = function(self, parents) -- add
			local power = 0
			for k,v in pairs(parents) do
				power = power + (sm.interactable.getValue(v) or v.power)
			end
			self:sv_setValue(power)
		end,

	[1] = function(self, parents) -- subtr
			local power = 0
			if #parents == 1 then
				power = 0 - (sm.interactable.getValue(parents[1]) or parents[1].power)
			elseif #parents == 2 then
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					power = (sm.interactable.getValue(parents[2]) or parents[2].power) - (sm.interactable.getValue(parents[1]) or parents[1].power)
				else
					power = (sm.interactable.getValue(parents[1]) or parents[1].power) - (sm.interactable.getValue(parents[2]) or parents[2].power)
				end
			elseif #parents > 2 then
				local whiteinput = 0
				local nonwhiteinput = 0
				local haswhite = false
				local hasnonwhite = false
				for k, v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whiteinput = whiteinput + (sm.interactable.getValue(v) or v.power)
						haswhite = true
					else
						nonwhiteinput = nonwhiteinput + (sm.interactable.getValue(v) or v.power)
						hasnonwhite = true
					end
				end
				if haswhite and hasnonwhite then
					power = whiteinput - nonwhiteinput
				else
					power = -1*(whiteinput + nonwhiteinput)
				end
			end
			self:sv_setValue(power)
		end,

	[2] = function(self, parents)-- mult
			local power = 1
			for k,v in pairs(parents) do
				power = power * (sm.interactable.getValue(v) or v.power)
			end
			self:sv_setValue(power)
		end,

	[3] = function(self, parents)  -- divide
			local power = 1

			if #parents == 2 then
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					power = (sm.interactable.getValue(parents[2]) or parents[2].power) / (sm.interactable.getValue(parents[1]) or parents[1].power)
				else
					power = (sm.interactable.getValue(parents[1]) or parents[1].power) / (sm.interactable.getValue(parents[2]) or parents[2].power)
				end
				if ((sm.interactable.getValue(parents[1]) or parents[1].power) == 0 and (sm.interactable.getValue(parents[2]) or parents[2].power) == 0) then power = 1 end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = whitevalue/othervalue
			end
			self:sv_setValue(power)
		end,

	[4] = function(self, parents) -- modulus
			local power = 0

			if #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[2]:getShape().color) == "222222ff" or tostring(parents[1]:getShape().color) == "eeeeeeff" then
					power = pow1%pow2
				else
					power = pow2%pow1
				end

			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = whitevalue%othervalue
			end
			self:sv_setValue(power)
		end,

	[5] = function(self, parents) -- square
			local power = 0

			if #parents == 1 then
				power = (sm.interactable.getValue(parents[1]) or parents[1].power) ^ 2
			elseif #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- switch p1 p2
					power = pow2 ^ pow1
				else
					power = pow1 ^ pow2
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = whitevalue^othervalue
			end
			self:sv_setValue(power)
		end,

	[6] = function(self, parents)  -- sqrt
			local power = 0

			if #parents == 1 then
				power = (sm.interactable.getValue(parents[1]) or parents[1].power) ^ (1/2)
			elseif #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- switch p1 p2
					power = pow2 ^ (1/pow1)
				else
					power = pow1 ^ (1/pow2)
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = whitevalue ^ (1/othervalue)
			end
			self:sv_setValue(power)
		end,

	[7] = function(self, parents)  -- gtr
			local power = 0
			if #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 > pow1 then power = 1 end
				else
					if pow1 > pow2 then power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = (whitevalue>othervalue and 1 or 0)
			end
			self:sv_setValue(power)
		end,

	[8] = function(self, parents)  -- smlr
			local power = 0
			if #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 < pow1 then power = 1 end
				else
					if pow1 < pow2 then power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = (whitevalue<othervalue and 1 or 0)
			end
			self:sv_setValue(power)
		end,

	[9] = function(self, parents)  -- eq
			local power = 1
			local amount = (#parents>0 and (sm.interactable.getValue(parents[1]) or parents[1].power))
			for k,v in pairs(parents) do
				if (sm.interactable.getValue(v) or v.power) ~= amount then
					power = 0
					break
				end
			end
			self:sv_setValue(power)
		end,

	[10] = function(self, parents)  -- bigger than or eq
			local power = 0
			if #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 >= pow1 then power = 1 end
				else
					if pow1 >= pow2 then power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = (whitevalue>=othervalue and 1 or 0)
			end
			self:sv_setValue(power)
		end,

	[11] = function(self, parents)  -- smaller than or eq
			local power = 0
			if #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- parent 1 = black
					if pow2 <= pow1 then power = 1 end
				else
					if pow1 <= pow2 then power = 1 end
				end
			elseif #parents> 2 then
				local whitevalue = 0
				local othervalue = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						whitevalue = whitevalue + (sm.interactable.getValue(v) or v.power)
					else
						othervalue = othervalue + (sm.interactable.getValue(v) or v.power)
					end
				end
				power = (whitevalue<=othervalue and 1 or 0)
			end
			self:sv_setValue(power)
		end,

	[12] = function(self, parents)  -- sin
			local power = 0
			if #parents > 0 then
				for k, v in pairs(parents) do
					power = power + (sm.interactable.getValue(v) or v.power)
				end
				power = math.sin(math.rad(power))
			end
			self:sv_setValue(power)
		end,

	[13] = function(self, parents)  -- cos
			local power = 0
			if #parents >0 then
				for k, v in pairs(parents) do
					power = power + (sm.interactable.getValue(v) or v.power)
				end
				power = math.cos(math.rad(power))
			end
			self:sv_setValue(power)
		end,

	[14] = function(self, parents)  -- tan
			local power = 0
			if #parents >0 then
				for k, v in pairs(parents) do
					power = power + (sm.interactable.getValue(v) or v.power)
				end
				power = math.tan(math.rad(power))
			end
			self:sv_setValue(power)
		end,

	[15] = function(self, parents)  -- pi
			local power = #parents>0 and 0 or 1
			for k, v in pairs(parents) do
				power = power + (sm.interactable.getValue(v) or v.power)
			end
			power = power * math.pi
			self:sv_setValue(power)
		end,

	[16] = function(self, parents)  -- random
			local power = self.power or 0
			if self.lastmode ~= self.mode then
				power = math.random() -- generate new number upon cycling to this and no parents connected
			end
			if #parents == 1 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				if parents[1]:getType() == "scripted" and tostring(parents[1]:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
					if ( self.lastparentvalue ~= pow1) then
						power = math.random(pow1)
					end
					self.lastparentvalue = pow1
				elseif pow1 ~= 0 or self.lastmode ~= self.mode then
					power = math.random() -- button, logic, whatever, when on, generate new number
				end
			elseif #parents == 2 then
				local inputvalues = {}
				local generate = false
				for k,v in pairs(parents) do
					if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
						table.insert(inputvalues, (sm.interactable.getValue(v) or v.power) )
					else
						generate = generate or ((sm.interactable.getValue(v) or v.power) ~= 0)
					end
				end
				if generate or (self.lastparentvalues == nil or not tablevaluesequal(self.lastparentvalues, inputvalues)) then
					if #inputvalues == 0 then
						power = math.random()
					elseif #inputvalues == 1 then
						power = math.random(inputvalues[1])
					else
						if inputvalues[1] > inputvalues[2] then
							power = math.random(inputvalues[2], inputvalues[1])
						elseif #inputvalues == 2 then
							power = math.random(inputvalues[1], inputvalues[2])
						end
					end
				end
				self.lastparentvalues = inputvalues
			elseif #parents == 3 then
				local inputvalues = {}
				local generate = false
				for k,v in pairs(parents) do
					if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
						table.insert(inputvalues, (sm.interactable.getValue(v) or v.power) )
					else
						generate = generate or ((sm.interactable.getValue(v) or v.power) ~= 0)
					end
				end
				if generate or (self.lastparentvalues == nil or  not tablevaluesequal(self.lastparentvalues, inputvalues)) then
					if #inputvalues == 0 then
						power = math.random()
					elseif #inputvalues == 1 then
						power = math.random(inputvalues[1])
					elseif #inputvalues == 2 then
						if inputvalues[1] > inputvalues[2] then
							power = math.random(inputvalues[2], inputvalues[1])
						else
							power = math.random(inputvalues[1], inputvalues[2])
						end
					end
				end
				self.lastparentvalues = inputvalues
			end
			self:sv_setValue(power)
		end,

	[17] = function(self, parents)  -- abs
			local power = 0
			if #parents == 1 then
				power = math.abs((sm.interactable.getValue(parents[1]) or parents[1].power))
			elseif #parents > 1 then
				power = 0
				for k, v in pairs(parents) do
					power = power + math.abs((sm.interactable.getValue(v) or v.power))
				end
			end
			self:sv_setValue(power)
		end,

	[18] = function(self, parents)  -- floor
			local power = 0
			if #parents > 0 then
				local floorby = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						floorby = floorby + (sm.interactable.getValue(v) or v.power)
					else
						power = power + (sm.interactable.getValue(v) or v.power)
					end
				end
				if not floorby or floorby == 0 then floorby = 1 end
				power = math.floor(power/floorby)*floorby
			end
			self:sv_setValue(power)
		end,

	[19] = function(self, parents)  -- round
			local power = 0
			if #parents>0 then
				local roundby = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						roundby = roundby + (sm.interactable.getValue(v) or v.power)
					else
						power = power + (sm.interactable.getValue(v) or v.power)
					end
				end
				if not roundby or roundby == 0 then roundby = 1 end
				power = math.round(power/roundby)*roundby
			end
			self:sv_setValue(power)
		end,

	[20] = function(self, parents)  -- ceil
			local power = 0
			if #parents > 0 then
				local roundby = 0
				for k,v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then
						roundby = roundby + (sm.interactable.getValue(v) or v.power)
					else
						power = power + (sm.interactable.getValue(v) or v.power)
					end
				end
				if not roundby or roundby == 0 then roundby = 1 end
				power = math.floor(power/roundby + (power/roundby%1 > 0 and 1 or 0) )*roundby
			end
			self:sv_setValue(power)
		end,

	[21] = function(self, parents)  -- min
			local power = math.huge
			for k, v in pairs(parents) do
				if v.power < power then power = (sm.interactable.getValue(v) or v.power) end
			end
			if power == math.huge then power = 0 end

			self:sv_setValue(power)
		end,

	[22] = function(self, parents)  -- max
			local power = 0-math.huge
			for k, v in pairs(parents) do
				if v.power > power then power = (sm.interactable.getValue(v) or v.power) end
			end
			if power == 0-math.huge then power = 0 end
			self:sv_setValue(power)
		end,

	[23] = function(self, parents)  -- log
			local power = 0
			if #parents == 1 then
				power = math.log((sm.interactable.getValue(parents[1]) or parents[1].power))
			elseif #parents == 2 then
				local pow1 = (sm.interactable.getValue(parents[1]) or parents[1].power)
				local pow2 = (sm.interactable.getValue(parents[2]) or parents[2].power)
				if tostring(parents[1]:getShape().color) == "222222ff" or tostring(parents[2]:getShape().color) == "eeeeeeff" then
					-- parent 2 = white
					power = math.log(pow1)/ math.log(pow2)
				else
					power = math.log(pow2)/ math.log(pow1)
				end
			end

			self:sv_setValue(power)
		end,

	[24] = function(self, parents)  -- exp
			local power = math.exp(1)
			if #parents > 0 then
				power = 0
				for k,v in pairs(parents) do
					power = power + math.exp((sm.interactable.getValue(v) or v.power))
				end
			end
			self:sv_setValue(power)
		end,

	[25] = function(self, parents)  -- arcsin
			local power = 0
			if #parents >0 then
				for k, v in pairs(parents) do
					power = power + (sm.interactable.getValue(v) or v.power)
				end
				power = math.asin(power)/math.pi*180.0
			end
			self:sv_setValue(power)
		end,

	[26] = function(self, parents)  -- arccos
			local power = 0
			if #parents >0 then
				for k, v in pairs(parents) do
					power = power + (sm.interactable.getValue(v) or v.power)
				end
				power = math.acos(power)/math.pi*180.0
			end
			self:sv_setValue(power)
		end,

	[27] = function(self, parents)  -- arctan
			local power = 0
			if #parents >0 then
				for k, v in pairs(parents) do
					power = power + (sm.interactable.getValue(v) or v.power)
				end
				power = math.atan(power)/math.pi*180.0
			end
			self:sv_setValue(power)
		end,

	[28] = function(self, parents)  -- hypotenuse
			local power = 0
			for k, v in pairs(parents) do
				power = power + math.pow((sm.interactable.getValue(v) or v.power),2)
			end
			if #parents > 0 then
				power = math.pow(power, 1/2)
			end
			self:sv_setValue(power)
		end,

	[29] = function(self, parents)  -- seated
			local power = 0
			for k, v in pairs(parents) do
				if (v:getType() == "seat" or v:getType() == "steering" or v:hasSeat()) then
					power = power + (v:isActive() and 1 or 0)
				end
			end
			self:sv_setValue(power)
		end,

	[30] = function(self, parents) -- AD

			self:sv_setValue(self.ADValue or 0)
		end,

	[31] = function(self, parents)  -- WS
			local power = 0
			local amountofparents = 0
			for k, v in pairs(parents) do
				amountofparents = amountofparents + 1
				power = power + v.power
			end
			if amountofparents>0 then
				power = math.min(1,math.max(-1,power/amountofparents))
			end
			self:sv_setValue(power)
		end,

	[32] = function(self, parents)  -- bitmem
			local power = self.power or 0
			local value = 0
			local logicon = 1
			local haslogic = false
			for k, v in pairs(parents) do
				if tostring(v:getShape().color) == "eeeeeeff" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
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
					power = (power == 0 and 1 or 0)
				elseif value == 1 then
					power = 1
				else
					power = 0
				end
			end
			self:sv_setValue(power)
		end,

	[33] = function(self, parents)  -- factorial function
			local power = 0
			local value = 0
			for k,v in pairs(parents) do
				value = value + v.power
			end
			value = math.floor(value)
			if value > 0 then
				power = 1
				while value >1 do
					power = power * value
					value = value - 1
				end
			end
			self:sv_setValue(power)
		end,

	[34] = function(self, parents)  -- pid
			local power = 0
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
				if sm.interactable.isNumberType(v) then
					local _shape_col = tostring(v:getShape():getColor())
					if _shape_col == "720a74ff" then  -- 3rd purple
						if deltatime_d == nil then deltatime_d = 0 end
						deltatime_d = deltatime_d + v.power
					elseif _shape_col == "7c0000ff" then  --3rd red
						if deltatime_i == nil then deltatime_i = 0 end
						deltatime_i = deltatime_i + v.power
					elseif _shape_col == "cf11d2ff" then  --purple
						d = d + v.power
					elseif _shape_col == "d02525ff"  then -- red
						i = i + v.power
					elseif _shape_col == "df7f00ff" then -- orange
						p = p + v.power
					elseif _shape_col == "df7f01ff" then -- orange 2
						p = p + v.power
					elseif _shape_col == "eeeeeeff" then --white
						setvalue = setvalue + v.power
					elseif _shape_col == "222222ff" then --black
						processvalue = processvalue + v.power
					elseif _shape_col == "673b00ff" then --black
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


				local lasterror = (self.buffer_d[(self.bufferindex - deltatime_d)%20] == nil) and _error or self.buffer_d[(self.bufferindex - deltatime_d)%20]


				power = _error * p  +  self:runningAverage({num = _error, count = deltatime_i}) * i  + (_error - lasterror) * d

				power = math.max(-limit, math.min(limit, power))

				self.bufferindex = (self.bufferindex + 1)%20
			end


			self:sv_setValue(power)
		end,

	[35] = function(self, parents)  -- atan2

			-- add all white inputs, add all blackinputs, atan2( white, black), output in angles (at least one input needs to be black or white)
			local power = 0
			if #parents >1 then
				local whiteinput = nil
				local blackinput = nil
				local otherinput = nil
				for k, v in pairs(parents) do
					if tostring(v:getShape().color) == "eeeeeeff" then --white
						whiteinput = (whiteinput and whiteinput or 0) + (sm.interactable.getValue(v) or v.power)
					elseif tostring(v:getShape().color) == "222222ff" then --black
						blackinput = (blackinput and blackinput or 0) + (sm.interactable.getValue(v) or v.power)
					else
						otherinput = (otherinput and otherinput or 0) + (sm.interactable.getValue(v) or v.power)
					end
					if not whiteinput then
						whiteinput = otherinput
					elseif not blackinput then
						blackinput = otherinput
					end
				end
				if whiteinput and blackinput then
					power = math.atan2(whiteinput, blackinput)/math.pi*180.0
				else
					power = 0
				end
			elseif #parents == 1 then
				local quadrant24 = (tostring(parents[1]:getShape().color) == "222222ff")
				power = math.atan((sm.interactable.getValue(parents[1]) or parents[1].power))/math.pi*180.0 + (quadrant24 and 90 or 0)
			else
				power = 0
			end
			self:sv_setValue(power)
		end,

	[36] = function(self, parents)  -- sign

			local sum = 0
			for k, parent in pairs(parents) do
				sum = sum + (sm.interactable.getValue(parent) or parent.power)
			end
			local power = (sum > 0 and 1) or (sum < 0 and -1) or 0
			self:sv_setValue(power)
		end,

	[37] = function(self, parents) -- Neq

			local power = 0
			local firstvalue = (#parents > 0) and (sm.interactable.getValue(parents[1]) or parents[1].power)
			for k, parent in pairs(parents) do
				if (sm.interactable.getValue(parent) or parent.power) ~= firstvalue then
					power = 1
				end
			end
			self:sv_setValue(power)
		end,

	[38] = function(self, parents)  -- if x{} has any of y{}
			local power = 0
			local whitevalues = {}
			local blackvalues = {}
			for k, parent in pairs(parents) do
				if tostring(parent:getShape().color) == "eeeeeeff" then
					table.insert(whitevalues, (sm.interactable.getValue(parent) or parent.power))
				elseif tostring(parent:getShape().color) == "222222ff" then
					table.insert(blackvalues, (sm.interactable.getValue(parent) or parent.power))
				end
			end
			for k,v in pairs(whitevalues) do
				for k2,v2 in pairs(blackvalues) do
					if v == v2 then
						power = 1
					end
				end
			end
			self:sv_setValue(power)
		end
}



function MathBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end

function MathBlock.server_onCreate( self )
	local stored = self.storage:load()
	if stored then
		if type(stored) == "number" then
			self.mode = self.savemodes[stored]
		elseif type(stored) == "table" then
			self.mode = self.savemodes[stored.mode] -- backwards compatibility
		end
	else
		self.storage:save(self.modetable[self.mode].value)
	end
	sm.interactable.setValue(self.interactable, 0)
end



function MathBlock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()

	local mode = self.modetable[self.mode].value
	self.modeFunctions[mode](self, parents)

	self.lastmode = self.mode
end


function MathBlock.sv_setValue(self, value)
	self.power = value

	if value ~= value then value = 0 end
	if math.abs(value) >= 3.3*10^38 then
		if value < 0 then value = -3.3*10^38 else value = 3.3*10^38 end
	end

	mp_updateOutputData(self, value, value ~= 0)
end

function MathBlock.sv_senduvtoclient(self, msg)
	self.network:sendToClients("cl_setMode", {self.mode, msg})
end

function MathBlock.client_onCreate(self)
	self.uv = 0
	self.network:sendToServer("sv_senduvtoclient")
end

function MathBlock.client_onDestroy(self)
	self:client_onGuiDestroyCallback()
end

function MathBlock.client_onGuiDestroyCallback(self)
	local s_gui = self.gui
	if s_gui and sm.exists(s_gui) then
		if s_gui:isActive() then
			s_gui:close()
		end

		s_gui:destroy()
	end

	self.gui = nil
end

function MathBlock.client_onInteract(self, character, lookAt)
    if lookAt == true then
		self.gui = mp_gui_createGuiFromLayout("$MOD_DATA/Gui/Layouts/MathBlock.layout", false, { backgroundAlpha = 0.5 })
		self.gui:setOnCloseCallback("client_onGuiDestroyCallback")

		for i = 0, 23 do
			self.gui:setButtonCallback( "Operation" .. tostring( i ), "cl_onModeButtonClick" )
		end
		
		for i = 1, 3 do
			self.gui:setButtonCallback( "Page" .. tostring( i ), "cl_onPageButtonClick" )
		end

        local currentPage = self:cl_getModePage()
        self:cl_paginate(currentPage)
		self.gui:open()
	end
end

function MathBlock.cl_onPageButtonClick(self, buttonName)
    local pageNumber = string.sub(buttonName, 5, -1)
	local pageIdx = tonumber(pageNumber)

	if self.guiPage == pageIdx then return end

	sm.audio.play("Handbook - Turn page")

    self:cl_paginate(pageIdx)
end

function MathBlock.cl_getModePage(self)
    for page = 1, 3 do
        local startIndex = (page - 1) * 18
        for i = 0, 17 do
            local modeIndex = i + startIndex + 1
            if modeIndex == self.mode then
                return page
            end
        end
    end
end

function MathBlock.cl_paginate(self, page)
    self.guiPage = page
    self:cl_drawButtons()
    for i = 1, 3 do
        self.gui:setButtonState('Page'.. i, i == page)
    end
end

function MathBlock.cl_drawButtons(self)
    local startIndex = (self.guiPage - 1) * 18
    for i = 0, 17 do
        local modeIndex = i + startIndex + 1
        local buttonOperation = self.modetable[modeIndex]
        if buttonOperation then
            self.gui:setText('ButtonText'.. i, buttonOperation.icon)
            self.gui:setButtonState('Operation' .. i, self.mode == modeIndex)
            self.gui:setVisible('Operation'.. i, true)
        else
            self.gui:setVisible('Operation'.. i, false)
        end
    end
    local selectedOperation = self.modetable[self.mode]
    self.gui:setText('FunctionNameText', selectedOperation.name)
    self.gui:setText('FunctionDescriptionText', selectedOperation.description)
end

function MathBlock.cl_onModeButtonClick(self, button)
    local startIndex = (self.guiPage - 1) * 18
	local buttonString = string.sub(button, 10)
	local modeIdx = tonumber(buttonString) + startIndex + 1

	if self.mode == modeIdx then return end

	self.mode = modeIdx
	self:cl_drawButtons()
	self.network:sendToServer("sv_setMode", { mode = modeIdx })
end

function MathBlock.sv_setMode(self, params)
    self.mode = params.mode
    self.storage:save(self.modetable[self.mode].value)
	self:sv_senduvtoclient(true)
end

function MathBlock.cl_setMode(self, data)
	local mode = data[1]
	self.uv = self.modetable[mode].value
	self.interactable:setUvFrameIndex(self.uv + (self.interactable.power > 0 and 128 or 0))
	if data[2] then
		sm.audio.play("GUI Item drag", self.shape:getWorldPosition())
	end
end

function MathBlock.client_canInteract(self)
	local use_key = mp_gui_getKeyBinding("Use", true)
	sm.gui.setInteractionText("Press", use_key, "to select a function")

	return true
end

function MathBlock.client_onFixedUpdate(self, dt)
	if sm.isHost then
		local parents = self.interactable:getParents()
		-- host only ('self.mode')
		if self.modetable[self.mode].value == 30 then  -- AD
			local power =  0
			local amountofparents = 0
			for k, v in pairs(parents) do
				local _s_uuid = tostring(v:getShape():getShapeUuid())
				if v:getType() == "steering" or _s_uuid == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" or _s_uuid == "e627986c-b7dd-4365-8fd8-a0f8707af63d" then
					amountofparents = amountofparents + 1
					power = power + (v:getPoseWeight(0)-0.5)*2
				elseif v:hasSteering() then
					amountofparents = amountofparents + 1
					power = power + v:getSteeringAngle()
				else
					amountofparents = amountofparents + 1
					power = power + v.power
				end
			end
			if amountofparents>0 then
				power = math.min(1,math.max(-1,power/amountofparents))
			end
			self.interactable:setPoseWeight(0,power/2+0.5)
			self.ADValue = power
		end
	end
	if (self.interactable.power > 0 and not self.waspos) or (self.interactable.power <= 0 and self.waspos) then
		self.interactable:setUvFrameIndex(self.uv + (self.interactable.power > 0 and 128 or 0))
		self.waspos = self.interactable.power>0
	end
end







function MathBlock.runningAverage(self, data)
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


function tablevaluesequal(sometable, table2) -- used by 'random function in mathblock'
	if #sometable ~= #table2 then return false end
	for k, v in pairs(sometable) do
		if v ~= table2[k] then return false end
	end
	return true
end
