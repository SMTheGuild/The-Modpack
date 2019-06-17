dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if CounterBlock and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 
dofile "../Libs/GameImprovements/interactable.lua"
--dofile "../Libs/MoreMath.lua"

-- TODO: 
--   fix mess with storage
--	 use improved userdata 
--	 remove EMP crap

mpPrint("loading CounterBlock.lua")


-- CounterBlock.lua --
CounterBlock = class( nil )
CounterBlock.maxParentCount = -1 -- infinite
CounterBlock.maxChildCount = -1 -- infinite
CounterBlock.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
CounterBlock.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
CounterBlock.colorNormal = sm.color.new( 0x00194Cff )
CounterBlock.colorHighlight = sm.color.new( 0x0A2866ff )
CounterBlock.poseWeightCount = 1


function CounterBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function CounterBlock.server_onCreate( self ) 
	self.power = 0
	self.digs = {
		["375000ff"] = -10000000,
		["064023ff"] = -1000000,
		["0a4444ff"] = -100000,
		["0a1d5aff"] = -10000,
		["35086cff"] = -1000,
		["520653ff"] = -100,
		["560202ff"] = -10,
		["472800ff"] = -1,
		["222222ff"] = -1,
				
		["a0ea00ff"] = 10000000,
		["19e753ff"] = 1000000,
		["2ce6e6ff"] = 100000,
		["0a3ee2ff"] = 10000,
		["7514edff"] = 1000,
		["cf11d2ff"] = 100,
		["d02525ff"] = 10,
		["df7f00ff"] = 1,
		
		["eeaf5cff"] = 0.1,
		["f06767ff"] = 0.01,
		["ee7bf0ff"] = 0.001,
		["ae79f0ff"] = 0.0001,
		["4c6fe3ff"] = 0.00001,
		["7eededff"] = 0.000001,
		["68ff88ff"] = 0.0000001,
		["cbf66fff"] = 0.00000001,
		
		["673b00ff"] = -0.1,
		["7c0000ff"] = -0.01,
		["720a74ff"] = -0.001,
		["500aa6ff"] = -0.0001,
		["0f2e91ff"] = -0.00001,
		["118787ff"] = -0.000001,
		["0e8031ff"] = -0.0000001,
		["577d07ff"] = -0.00000001
	}
	local stored = self.storage:load()
	if stored then
		self.power = tonumber(stored[1])
		self.interactable:setPower(self.power)
	else
		local data = {}
		data[1] = self.power
		data[-1] = "memory"
		self.storage:save(data) 
	end
	sm.interactable.setValue(self.interactable, self.power)
end



function CounterBlock.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end
function CounterBlock.server_changemode(self)
	self.power = 0
end

function CounterBlock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	
	local reset = false
	for k,v in pairs(parents) do
		local x = self.digs[tostring(sm.shape.getColor(v:getShape()))]
		if tostring(sm.shape.getColor(v:getShape())) == "eeeeeeff" and v:isActive() then reset = true end
		if x ~= nil and (sm.interactable.getValue(v) or v.power) ~= 0 then
			self.power = self.power + x * (sm.interactable.getValue(v) or v.power)
		end
	end
	if reset then self.power = 0 end
	
	
	self.needssave = self.needssave or (self.power ~= (sm.interactable.getValue(self.interactable) or self.power))
	
	if self.needssave and os.time()%5 == 0 and self.risingedge then
		self.needssave = false
		local data = {}
		data[1] = tostring(self.power)
		data[-1] = "memory"
		self.storage:save(data) -- this should happen on lift save or world close, update when function is out
	end
	self.risingedge = os.time()%5 ~= 0
	
	if (self.power ~= self.interactable.power or (self.power ~= (sm.interactable.getValue(self.interactable) or self.power)))
	and not (EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4)	then
		if self.power ~= self.power then self.power = 0 end
		if math.abs(self.power) >= 3.3*10^38 then 
			if self.power < 0 then self.power = -3.3*10^38 else self.power = 3.3*10^38 end  
		end
		self.interactable:setPower(self.power)
		self.interactable:setActive(self.power>0)
		sm.interactable.setValue(self.interactable, self.power)
	end
	
	if EMP and EMP.active and (self.shape.worldPosition - EMP.position):length() < 60/4 then
		self.interactable:setPower(self.interactable.power*math.random(80, 120)/100)
		sm.interactable.setValue(self.interactable, self.interactable.power)
	end
end

function CounterBlock.client_onCreate(self, dt)
	self.time = 0
	self.frameindex = 0
end
function CounterBlock.client_onFixedUpdate(self, dt)
	local on = 0
	local power = self.interactable.power
	if power ~= self.lastpower then
		on = 6
		self.time = self.time + 0.25
		if self.time > 1 then 
			self.time = self.time%1
			if power>self.lastpower then self.frameindex = self.frameindex + 1 end
			if power<self.lastpower then self.frameindex = self.frameindex - 1 end
		end
		self.frameindex = self.frameindex%5
		if power == 0 then self.frameindex = 0 end	
	end

	if self.frameindex + on ~= self.lastindex then 
		self.interactable:setUvFrameIndex( self.frameindex + on)
	end
	

	self.lastpower = power
	self.lastindex = self.frameindex + on
end
