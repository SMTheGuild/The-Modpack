--[[ description:
		adds together all number inputs,
		gravity creation = worldgravity*number input,
		if (all input logic is on) or ( no logic and 'e') then do gravity
	]]
-- grav creation: normal gravity = 1
--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]
   --
dofile "../../libs/load_libs.lua"

print("Loading GravityModulator.lua")

gravcreation = class(nil)
gravcreation.maxChildCount = 0
gravcreation.maxParentCount = -1
gravcreation.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
gravcreation.connectionOutput = sm.interactable.connectionType.none
gravcreation.colorNormal = sm.color.new(0x000000ff)
gravcreation.colorHighlight = sm.color.new(0x000000ff)
gravcreation.poseWeightCount = 2
gravcreation.creations = {}

function gravcreation.server_onRefresh(self)
	sm.isDev = true
	--self:server_onCreate()
end

function gravcreation.server_onCreate(self)
	self.shapes = {}
	self.e = false
	self.gravwork = 0
end

function gravcreation.server_onDestroy(self)

end

function gravcreation.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local power = 0
	local logic = 1
	local haslogic = self.e -- [[ pressing e can activate the thing as well if there's no logic input ]]
	if parents then
		for k, v in pairs(parents) do
			if v:hasSteering() or v:getType() ~= "scripted" or tostring(v:getShape():getShapeUuid()) == "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
				-- logic [[vanilla or tickbutton]]
				haslogic = true
				if v.power == 0 then logic = 0 end
				self.e = false
			else
				-- number
				power = power + v.power
			end
		end
	end

	local worldgravity = sm.physics.getGravity()
	if power ~= 1 --[[normal world grav]] and haslogic and logic == 1 then
		local gravity = sm.vec3.new(0, 0, (worldgravity * (1.047494 - power)) * dt) -- 80: 1.005594 20:1.047494   10: 1.047494  5:1.089395   10/8: 1.2151   10/16:1.2151    1/32:1.7178
		-- FAKING GRAVITY IS FKN FPS RELATED
		local id = self.shape:getBody():getCreationBodies()[1].id
		if gravcreation.creations[id] == nil or os.clock() - gravcreation.creations[id] > 0.01 then
			for k, body in pairs(self.shape:getBody():getCreationBodies()) do
				local drag = sm.vec3.new(0, 0, 0)
				if self.shapes and self.shapes[k] then
					--print("vel:",(self.shapes[k] - shape.worldPosition):length())
					if (self.shapes[k] - body.worldPosition):length() < 0.0025 then
						drag = (self.shapes[k] - body.worldPosition) *
						2                            -- drag needs to be higher when rly slowly going up/down
					else
						drag = (self.shapes[k] - body.worldPosition) / 2
					end
					drag.x = 0
					drag.y = 0
				end
				sm.physics.applyImpulse(body, (gravity + drag) * body.mass, true)
				self.shapes[k] = body.worldPosition
			end
			gravcreation.creations[id] = os.clock()
		end
		self.gravwork = 1 - power
	else
		-- when logic off or normal world gravity, reset self.shapes to preserve RAM usage
		self.shapes = {}
		self.gravwork = 0
	end
	if self.gravwork ~= self.clientgravity then self.network:sendToClients("client_grav", self.gravwork) end
end

function gravcreation.client_onInteract(self, character, lookAt)
	if not lookAt then return end
	self.network:sendToServer("server_changemode")
end

function gravcreation.server_changemode(self)
	self.e = not self.e
end

function gravcreation.client_onCreate(self)
	self.clientgravity = 1
	self.pose = 0
	self.network:sendToServer("server_requestgrav")
end

function gravcreation.client_onFixedUpdate(self, dt)
	local animationspeed = (self.clientgravity) * dt
	self.pose = (self.pose + animationspeed) % 2
	self.interactable:setPoseWeight(1, math.abs(self.pose - 1))
	if self.clientgravity ~= 1 then
		self.interactable:setPoseWeight(0, 1)
	else
		self.interactable:setPoseWeight(0, 0)
	end
end

function gravcreation.server_requestgrav(self)
	self.network:sendToClients("client_grav", self.gravwork)
end

function gravcreation.client_grav(self, grav)
	self.clientgravity = grav
end

gravworld = class(nil)
gravworld.maxChildCount = 0
gravworld.maxParentCount = -1
gravworld.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
gravworld.connectionOutput = 0
gravworld.colorNormal = sm.color.new(0x000000ff)
gravworld.colorHighlight = sm.color.new(0x000000ff)
gravworld.poseWeightCount = 2
gravworld.on = false
gravworld.playerfly = 1

function gravworld.server_onDestroy(self)
	--sm.physics.setGravity( 10 )
	gravworld_playerspulsed = {}
end

function gravworld.server_onRefresh(self)
	self:server_onCreate()
end

function gravworld.server_onCreate(self)
	self.e = false
	self.gravity = 0
	gravworld_playerspulsed = {}
	local grav = sm.physics.getGravity()
	if grav == 10 then self.e = false else self.e = true end
	if sm.player.getAllPlayers()[1].name == "disableGravMods" then
		sm.gui.displayAlertText("Gravity Modulators are now disabled")
		self.server_onFixedUpdate = function() end
	end
end

function gravworld.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local power = 0
	local logic = 1
	local flyspeed = 1
	local defaultflyspeed = true
	local haslogic = false
	if parents then
		for k, v in pairs(parents) do
			if v:hasSteering() or v:getType() ~= "scripted" or tostring(v:getShape():getShapeUuid()) == "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
				-- logic [[vanilla or tickbutton]]
				haslogic = true
				if v.power == 0 then logic = 0 end
			else
				-- number
				if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" then
					if defaultflyspeed then flyspeed = 0 end
					defaultflyspeed = false
					flyspeed = flyspeed + v.power
				else
					power = power + v.power
				end
			end
		end
	end
	if math.abs(power) >= 3.3 * 10 ^ 30 then
		if power < 0 then power = -3.3 * 10 ^ 30 else power = 3.3 * 10 ^ 30 end
	end
	if self.gravity ~= power and gravworld.on then
		sm.physics.setGravity(power * 10)
	end
	self.gravity = power
	if self.playerspeed ~= flyspeed then
		gravworld.playerfly = flyspeed
	end
	self.playerspeed = flyspeed

	if haslogic and logic == 1 then
		if self.gravity ~= self.lastgravity then -- doing this to prevent setting gravity every tick
			sm.physics.setGravity(power * 10)
			gravworld.on = true
			gravworld.playerfly = self.playerspeed
		end
		self.lastgravity = self.gravity
	elseif self.hadparent then
		--reset to default
		if self.lastgravity ~= 1 then
			sm.physics.setGravity(10)
			gravworld.on = false
			gravworld.playerfly = self.playerspeed
		end
		self.lastgravity = 1
	end
	self.hadparent = haslogic

	local grav = sm.physics.getGravity()
	if grav ~= 10 then
		for k, player in pairs(sm.player.getAllPlayers()) do
			local pulse = sm.vec3.new(0, 0, (10 - grav) / 0.5 * dt)
			if player.character ~= nil then
				local drag = player.character.velocity * -dt / 2

				if grav <= 0.1 and player.character:isCrouching() then
					pulse = pulse + player.character:getDirection() / 4
				end
				if grav <= 0.1 and player.character:isSprinting() then
					pulse = pulse + player.character:getDirection() * 3 * gravworld.playerfly
				end

				local id = player.id
				if gravworld_playerspulsed and (gravworld_playerspulsed[id] == nil or (os.clock() - gravworld_playerspulsed[id]) > 0.01) then
					gravworld_playerspulsed[id] = os.clock()
					sm.physics.applyImpulse(player.character, (pulse + drag) * player.character.mass)
				end
			end
		end
	end
	if grav ~= self.lastgrav then
		self.network:sendToClients("client_grav", grav / 10)
	end
	self.lastgrav = grav
end

function gravworld.client_onInteract(self, character, lookAt)
	if not lookAt then return end
	self.network:sendToServer("server_changemode")
end

function gravworld.server_changemode(self)
	if gravworld.on == true then
		sm.physics.setGravity(10)
		gravworld.on = false
	else
		sm.physics.setGravity(self.gravity * 10)
		gravworld.on = true
	end
	gravworld.playerfly = self.playerspeed
end

function gravworld.client_onCreate(self)
	self.clientgravity = 1
	self.pose = 0
	self.network:sendToServer("server_requestgrav")
end

function gravworld.client_onRefresh(self)
	self.clientgravity = 1
	self.pose = 0
	self.network:sendToServer("server_requestgrav")
end

function gravworld.client_onFixedUpdate(self, dt)
	local animationspeed = (self.clientgravity - 1) * dt
	self.pose = (self.pose + animationspeed) % 2
	self.interactable:setPoseWeight(1, math.abs(self.pose - 1))
	if self.clientgravity ~= 1 then
		self.interactable:setPoseWeight(0, 1)
	else
		self.interactable:setPoseWeight(0, 0)
	end
end

function gravworld.server_requestgrav(self)
	self.network:sendToClients("client_grav", sm.physics.getGravity() / 10)
end

function gravworld.client_grav(self, grav)
	self.clientgravity = grav
end
