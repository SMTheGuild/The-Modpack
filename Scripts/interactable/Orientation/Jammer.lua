--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading Jammer.lua")

-- Jammer.lua --
Jammer = class( nil )
Jammer.maxParentCount = 1
Jammer.maxChildCount = 0
Jammer.connectionInput =  sm.interactable.connectionType.logic
Jammer.connectionOutput = sm.interactable.connectionType.none
Jammer.colorNormal = sm.color.new( 0x470067ff )
Jammer.colorHighlight = sm.color.new( 0x601980ff )
Jammer.poseWeightCount = 1
if not jammerjammers then jammerjammers = {} end

function Jammer.client_onCreate( self )
	self.uvindex = 0
	self.isON = 1
	self.interference = 0 -- time
	table.insert(jammerjammers, self.interactable)
	self.network:sendToServer("server_modeToClient")
end
function Jammer.client_onRefresh( self )
	self:client_onCreate()
end


function Jammer.client_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then
		self.isON = parent:isActive()
	end
	
	if self.isON and self.interference == 0 then
		if not self.prevmode then --turned on
			sm.audio.play("Blueprint - Delete", self.shape:getWorldPosition())
			self.interactable:setPoseWeight(0,0)
		end
		
		self.interactable:setUvFrameIndex(self.uvindex + 50)
		self.uvindex = (self.uvindex + 1)%50
	else
		if self.prevmode then -- turned off
			sm.audio.play("Blueprint - Delete", self.shape:getWorldPosition())
			self.interactable:setPoseWeight(0,1)
			self.interactable:setUvFrameIndex(0) 
		end
	end
	if self.interference > 0 then self.interference = self.interference - 1 end
	self.prevmode = self.isON
end

function Jammer.client_onProjectile(self, X, hits, four)
	self.interference = 80
end

function Jammer.client_onInteract(self, character, lookAt)
	if not lookAt then return end
	self.network:sendToServer("server_changemode")
end

function Jammer.client_setmode(self, newmode)
	self.isON = newmode
end

function Jammer.server_onCreate(self)
	local storage = self.storage:load()
	self.isONserver = (storage == nil) or storage
end

function Jammer.server_onFixedUpdate(self, dt)
	local parent = self.interactable:getSingleParent()
	if parent then
		if self.isONserver ~= parent.active then
			self.isONserver = parent.active
			self.storage:save( parent.active)
		end
	end

	mp_setActiveSafe(self, (self.isONserver and self.interference == 0))
end

function Jammer.server_changemode(self)
	self.isONserver = not self.isONserver
	self.storage:save(self.isONserver)
	self:server_modeToClient()
end
function Jammer.server_modeToClient(self)
	self.network:sendToClients("client_setmode", self.isONserver)
end