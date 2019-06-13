--[[ Keypad block ]]--
Keypad = class()
Keypad.maxParentCount = 0 -- Amount of inputs
Keypad.maxChildCount = -1 -- Amount of outputs
Keypad.connectionInput = sm.interactable.connectionType.none -- Type of input
Keypad.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic -- Type of output
Keypad.colorNormal = sm.color.new( 0x00971dff )
Keypad.colorHighlight = sm.color.new( 0x00b822ff )

Keypad.newPower = 0
Keypad.power = 0
Keypad.decimal = false
Keypad.deciPlace = 0.1
Keypad.activate = false
Keypad.prevActive = false
Keypad.pulseDelay = 0
Keypad.lastEnter = false

-- Called on creation
function Keypad.server_onCreate( self ) 
	self.interactable:setPower(self.power)
	self.interactable:setActive(false)
end
function Keypad.server_onRefresh( self )
    self:server_onCreate()
end

-- Called every tick
function Keypad.server_onFixedUpdate( self, deltaTime )
	if self.activate == true then
		self.activate = false
		self.interactable:setActive(true)
		self.prevActive = true
	elseif self.prevActive == true then
		if self.pulseDelay > 0 then
			self.pulseDelay = self.pulseDelay - 1
		else
			self.prevActive = false
			self.interactable:setActive(false)
		end
	end
end

function Keypad.server_changePower( self, num )
	self.power = num
	self.interactable:setPower(num)
end

function Keypad.server_changeActive( self )
	self.activate = true
	self.pulseDelay = 0
end

-- Called on pressing [E]
function Keypad.client_onInteract( self ) 
	local camPos = sm.camera.getPosition()
	local camDir = sm.camera.getDirection()
	local R1,R2 = sm.physics.raycast((camPos + camDir), (camPos + camDir * 10))
	local hitPos = R2.pointWorld -- world point the vector hit
	local worldPos = self.shape:getWorldPosition() -- world point of block center
	local localHitVec = hitPos - worldPos -- vector of hit relative to block
	local localX = self.shape:getRight()
	local localY = self.shape:getAt()
	local localZ = self.shape:getUp()
	dotX = sm.vec3.dot(localHitVec, localX) * 4
	dotY = sm.vec3.dot(localHitVec, localY) * 4
	dotZ = sm.vec3.dot(localHitVec, localZ) * 4
	
	--print(localHitVec)
	--print("Dot X: "..string.format("%.3f",dotX))
	--print("Dot Y: "..string.format("%.3f",dotY))
	--print("Dot Z: "..string.format("%.3f",dotZ))
	
	-- determine row and colum ranges
	local row1 = dotY > 0.5
	local row2 = dotY > 0 and dotY <= 0.5
	local row3 = dotY <= 0 and dotY > -0.5
	local row4 = dotY <= -0.5
	local col1 = dotX < -0.5
	local col2 = dotX >= -0.5 and dotX < 0
	local col3 = dotX >= 0 and dotX < 0.5
	local col4 = dotX >= 0.5
	
	-- determine button pressed
	if row1 and col1 then 
		--print("7")
		self:client_keypress(7)
	elseif row1 and col2 then
		--print("8")
		self:client_keypress(8)
	elseif row1 and col3 then
		--print("9")
		self:client_keypress(9)
	elseif row2 and col1 then
		--print("4")
		self:client_keypress(4)
	elseif row2 and col2 then
		--print("5")
		self:client_keypress(5)
	elseif row2 and col3 then
		--print("6")
		self:client_keypress(6)
	elseif row3 and col1 then
		--print("1")
		self:client_keypress(1)
	elseif row3 and col2 then
		--print("2")
		self:client_keypress(2)
	elseif row3 and col3 then
		--print("3")
		self:client_keypress(3)
	elseif row4 and col1 then
		--print("0")
		self:client_keypress(0)
	elseif row4 and col2 then
		--print(".")
		self.decimal = true
		if self.lastEnter == true then
			self.lastEnter = false
			self.newPower = 0
		self.deciPlace = 0.1
		end
	elseif row4 and col3 then
		--print("-")
		self.newPower = -self.newPower
	elseif (row1 or row2 ) and col4 then
		--print("CLEAR")
		self.newPower = 0
		self.decimal = false
		self.deciPlace = 0.1
	elseif (row3 or row4) and col4 then
		--print("ENTER")
		self.lastEnter = true
		self.network:sendToServer("server_changeActive")
	end
	self.network:sendToServer("server_changePower", self.newPower)
	sm.audio.play("Button on", sm.shape.getWorldPosition(self.shape))
	--print("new power: "..self.newPower)
	--print("-----------------------------------")
end

-- process number buttons
function Keypad.client_keypress(self, num)
	if self.lastEnter == true then
		self.lastEnter = false
		self.newPower = 0
		self.decimal = false
		self.deciPlace = 0.1
	end
	if self.decimal == false then
		if self.newPower == 0 then
			self.newPower = self.newPower + num
		else
			self.newPower = self.newPower * 10 + num
		end
	else
		self.newPower = self.newPower + (num * self.deciPlace)
		self.deciPlace = self.deciPlace * 0.1
	end
end


