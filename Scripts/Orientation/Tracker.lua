dofile "../Libs/Debugger.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if Tracker and not sm.isDev then -- increases performance for non '-dev' users.
	return
end 

mpPrint("loading Tracker.lua")

-- Tracker.lua --
Tracker = class( nil )
Tracker.maxParentCount = 1
Tracker.maxChildCount = 0
Tracker.connectionInput =  sm.interactable.connectionType.power
Tracker.connectionOutput = sm.interactable.connectionType.none
Tracker.colorNormal = sm.color.new( 0xaaaaaaff )
Tracker.colorHighlight = sm.color.new( 0xaaaaaaff )
if not trackertrackers then trackertrackers = {} end

function Tracker.client_onCreate( self )
	self.id = self.shape.id
	table.insert(trackertrackers, self)
end
function Tracker.client_onRefresh( self )
	self:client_onCreate()
end
function Tracker.client_onDestroy(self)
	for k, v in pairs(trackertrackers) do
		if v.id == self.id then
			table.remove(trackertrackers, k)
			return
		end
	end
end

function Tracker.getFrequency(self)
	if not self.interactable then return 0 end
	local parent = self.interactable:getSingleParent()
	return (parent and parent.power) or 0
end