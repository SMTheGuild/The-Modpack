dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if TimeBlock and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

dofile "../Libs/GameImprovements/interactable.lua"
--dofile "../Libs/MoreMath.lua"

mpPrint("loading TimeBlock.lua")

TimeBlock = class( nil )
TimeBlock.maxParentCount = 0
TimeBlock.maxChildCount = -1
TimeBlock.connectionInput = sm.interactable.connectionType.power
TimeBlock.connectionOutput = sm.interactable.connectionType.power
TimeBlock.colorNormal = sm.color.new( 0xccccccff  )
TimeBlock.colorHighlight = sm.color.new( 0xF2F2F2ff  )
TimeBlock.poseWeightCount = 2


function TimeBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function TimeBlock.server_onCreate( self ) 
	self.smode = 0
	
	local stored = self.storage:load()
	if stored then
		self.smode = stored - 1
	end
	sm.interactable.setValue(self.interactable, os.time())
end


function TimeBlock.client_onCreate(self)
	self.clockms = 0
end

function TimeBlock.server_onFixedUpdate(self, dt)
	local clockvalue = os.time()%86400
	if clockvalue ~= self.interactable.power then
		self.interactable:setPower(clockvalue)
		sm.interactable.setValue(self.interactable, os.time())
	end
end

function TimeBlock.client_onFixedUpdate( self, dt )
	
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
