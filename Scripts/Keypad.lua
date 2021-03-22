--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261 for copy pasta
]]--
dofile "Libs/LoadLibs.lua"


Keypad = class()
Keypad.maxParentCount = -1
Keypad.maxChildCount = -1
Keypad.connectionInput = sm.interactable.connectionType.logic
Keypad.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Keypad.colorNormal = sm.color.new( 0x00971dff )
Keypad.colorHighlight = sm.color.new( 0x00b822ff )


-- Called on creation
function Keypad.server_onCreate( self )
	self.activeTime = 0
	self.strNumber = "0"
	self.enabled = true
end
function Keypad.server_onRefresh( self )
	if not sm.exists(self.interactable) then return end
    self:server_onCreate()
	self.interactable.power = 0
	self.interactable.active = false
end

function Keypad.server_onFixedUpdate( self, dt )
	if not sm.exists(self.interactable) then return end
	if self.interactable.active then
		if self.activeTime <= 1 then -- when active and activeTime is only 1 tick it'll insta go inactive, thus it stayed active for 1 tick
			self.interactable.active = false
		else
			self.activeTime = self.activeTime - 1
		end
	end
	local enabled = true
	for k, v in pairs(self.interactable:getParents()) do 
		local color = tostring(v:getShape().color)
		if color == "222222ff" then
			if v.active then
				self.strNumber = "0"
				self.interactable.power = 0
				sm.interactable.setValue(self.interactable, 0)
			end
		else
			enabled = enabled and v.active
		end
	end
	self.enabled = enabled
	if self.buttonPress then
		self.buttonPress = false
		self.network:sendToClients("client_playSound", "Button off")
	end
end

function Keypad.server_onButtonPress(self, buttonName)
	if not self.enabled then return end
	if self.enter and buttonName ~= "e" then
		-- can press 'enter' multiple times
		self.strNumber = "0"
		self.enter = false
	end
	
	if tonumber(buttonName) then
		self.strNumber = self.strNumber..buttonName
	else
		self[buttonName](self)
	end
	
	local power = tonumber(self.strNumber)
	if math.abs(power) >= 3.3*10^38 then
		if power < 0 then power = -3.3*10^38 else power = 3.3*10^38 end  
	end
	self.interactable.power = power
	sm.interactable.setValue(self.interactable, tonumber(self.strNumber))
	
	self.buttonPress = true
	self.network:sendToClients("client_playSound","Button on")
end

function Keypad.d(self) -- '.'
	self.strNumber = (self.strNumber:find("%.") and self.strNumber or self.strNumber..".")
end
function Keypad.m(self) -- '-'
	self.strNumber = (self.strNumber:sub(1,1) == '-' and self.strNumber:sub(2) or '-'..self.strNumber)
end
function Keypad.c(self) -- 'clear'
	self.strNumber = "0"
end
function Keypad.b(self) -- 'backspace'
	self.strNumber = (self.strNumber:sub(1,(self.strNumber:len()-1)))
	if self.strNumber == "" then self.strNumber = "0" end
end
function Keypad.e(self) -- 'enter'
	self.enter = true
	self.activeTime = 1 --ticks
	self.interactable.active = true
end

--- client ---

function Keypad.client_playSound(self, soundName)
	sm.audio.play(soundName, self.shape.worldPosition)
end

function Keypad.client_onCreate(self)
	function networkCall(self, parentInstance)
		parentInstance.network:sendToServer("server_onButtonPress", self.name)
	end
	local virtualButtons = {
		{ name = "1", x = -0.75, y = -0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "2", x = -0.25, y = -0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "3", x =  0.25, y = -0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "4", x = -0.75, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "5", x = -0.25, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "6", x =  0.25, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "7", x = -0.75, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "8", x = -0.25, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "9", x =  0.25, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "0", x = -0.75, y = -0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "d", x = -0.25, y = -0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "m", x =  0.25, y = -0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "b", x =  0.75, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "c", x =  0.75, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "e", x =  0.75, y = -0.50, width = 0.25, height = 0.50, callback = networkCall}
	}
	sm.virtualButtons.client_configure(self, virtualButtons)
	self.effect = sm.effect.createEffect( "RadarDot", self.interactable)
	self.effect2 = sm.effect.createEffect( "RadarDot", self.interactable)
end

function Keypad.client_onFixedUpdate(self)
	if not sm.exists(self.interactable) then return end
	local hit, hitResult = sm.localPlayer.getRaycast(10)
	if not hit then
		self:client_stopEffect()
		return
	end
	
	local dotX, dotY = self:getLocalXY(hitResult.pointWorld)
	local buttonX, buttonY = sm.virtualButtons.client_getButtonPosition(self, dotX, dotY)
	
	if not buttonX then 
		self:client_stopEffect()
		return 
	end
	
	self.effect:setOffsetPosition(sm.vec3.new(buttonX/4, buttonY/4, -0.065))
	self.effect2:setOffsetPosition(sm.vec3.new(buttonX/4, buttonY/4, -0.065))
	if not self.effect:isPlaying() then
		self.effect:start()
		self.effect2:start()
	end
end

-- Called on pressing [E]
function Keypad.client_onInteract( self, character, lookAt)
	if not lookAt then return end
	local hit, hitResult = sm.localPlayer.getRaycast(10) -- world point the vector hit
	if not hit then return end
	local dotX, dotY = self:getLocalXY(hitResult.pointWorld)
	sm.virtualButtons.client_onInteract(self, dotX, dotY)
end

function Keypad.client_canInteract(self) --sm.localPlayer.getPosition is deprecated now
	local _Player = sm.localPlayer.getPlayer()
	if not (_Player and _Player.character) then return false end
	local _Position = _Player.character.worldPosition
	return (self.shape.worldPosition - _Position):length2() < 4
end

function Keypad.client_onDestroy(self)
	self:client_stopEffect()
end


function Keypad.getLocalXY(self, vec)
	local hitVec = vec - self.shape.worldPosition
	local localX = self.shape.right
	local localY = self.shape.at
	dotX = hitVec:dot(localX) * 4
	dotY = hitVec:dot(localY) * 4
	return dotX, dotY
end


function Keypad.client_stopEffect(self)
	self.effect:setOffsetPosition(sm.vec3.new(100000,0,0))
	self.effect2:setOffsetPosition(sm.vec3.new(100000,0,0))
	if self.effect:isPlaying() then
		self.effect:stop()
		self.effect2:stop()
	end
end
