
-- decoupler.lua --
decoupler = class( nil )
decoupler.maxChildCount = 0
decoupler.maxParentCount = 1
decoupler.connectionInput = sm.interactable.connectionType.logic
decoupler.connectionOutput = sm.interactable.connectionType.none
decoupler.colorNormal = sm.color.new( 0x844040ff )
decoupler.colorHighlight = sm.color.new( 0xb25959ff )

function decoupler.server_onFixedUpdate(self, dt)
	local parent = self.interactable:getSingleParent()
	if parent and parent:isActive() then sm.shape.destroyPart(self.shape) end
end