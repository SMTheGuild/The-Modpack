
laser = class( nil )
laser.maxChildCount = -1
laser.maxParentCount = -1
laser.connectionInput = sm.interactable.connectionType.logic
laser.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
laser.colorNormal = sm.color.new(0x222222ff)
laser.colorHighlight = sm.color.new(0x333333ff)
laser.poseWeightCount = 1


function laser.server_onFixedUpdate(self, dt)

	local parents = self.interactable:getParents()
	local active = false
	for k, v in pairs(parents) do active = active or v.active end
	
    if active then
        local hit, fraction = sm.physics.distanceRaycast(self.shape.worldPosition - self.shape.right/50, self.shape.up * 2500)
        if hit then
			self.interactable.power = fraction * 2500 * 4 + 0.5
		end
	else
		self.interactable.power = 0
    end
	if not self.lastpower then self.lastpower = self.interactable.power end
	local deltapower = self.interactable.power - self.lastpower
	self.interactable.active = self.lastdeltapower and self.lastdeltapower - deltapower < -1.5 or false
	self.lastdeltapower = deltapower
	self.lastpower = self.interactable.power
end


function laser.client_onFixedUpdate(self)
	if not sm.exists(self.interactable) then return end
	local parents = self.interactable:getParents()
	local active = false
	for k, v in pairs(parents) do active = active or v.active end
	
    if active then
        local hit, fraction = sm.physics.distanceRaycast(self.shape.worldPosition - self.shape.right/50, self.shape.up * 2500)
        if hit then
		
            self.interactable:setPoseWeight(0, 0.000055 + fraction*1.00002)
        end
    else
		self.interactable:setPoseWeight(0, 0)
	end
end