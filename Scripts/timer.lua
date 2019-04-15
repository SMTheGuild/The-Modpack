
dofile('functions.lua')

timerblock = class( nil )
timerblock.maxParentCount = 0
timerblock.maxChildCount = -1
timerblock.connectionInput = sm.interactable.connectionType.power
timerblock.connectionOutput = sm.interactable.connectionType.power
timerblock.colorNormal = sm.color.new( 0xccccccff  )
timerblock.colorHighlight = sm.color.new( 0xF2F2F2ff  )
timerblock.poseWeightCount = 2


function timerblock.server_onCreate( self ) 
	self:server_init()
end
 

function timerblock.server_init( self ) 
	self.smode = 0
	
	local stored = self.storage:load()
	if stored then
		self.smode = stored - 1
	end
end

function timerblock.server_onRefresh( self )
	self:server_init()
end

function timerblock.client_onCreate(self)
	self.clockms = 0
end

function timerblock.server_onFixedUpdate(self, dt)
	local clockvalue = os.time()%86400
	if clockvalue ~= self.interactable.power then
		self.interactable:setPower(clockvalue)
	end
	sm.interactable.setValue(self.interactable, os.time())
end

function timerblock.client_onFixedUpdate( self, dt )
	
	if self.mode == 0 then
		self.value = os.time()%86400
		
		if self.value ~= self.interactable.power then
			self.clockms = 0
		end
		self.clockms = self.clockms + dt
		local posevalue = (self.value%60)+30 + self.clockms
		
		self.interactable:setPoseWeight(0, (math.sin(0-2*math.pi*posevalue/60)+1)/2)
		self.interactable:setPoseWeight(1, (math.cos(2*math.pi*posevalue/60)+1)/2)
	else
		local ostime = os.time() - 946684800 --year 2000
		self.value = (ostime-ostime%86400)/86400
		
		local posevalue = (self.value%60)+30
		self.interactable:setPoseWeight(0, (math.sin(0-2*math.pi*posevalue/60)+1)/2)
		self.interactable:setPoseWeight(1, (math.cos(2*math.pi*posevalue/60)+1)/2)
	end
end
