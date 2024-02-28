if __virtualButtons_Loaded then return end
__virtualButtons_Loaded = true


if not sm.virtualButtons then sm.virtualButtons = {} end
function sm.virtualButtons.client_configure(parentInstance, virtualButtons)
	parentInstance.__virtualButtons = virtualButtons
end

function sm.virtualButtons.client_onInteract(parentInstance, x, y) -- x, y in blocks
	for _, virtualButton in pairs(parentInstance.__virtualButtons or {}) do
		if math.abs(x - virtualButton.x) < virtualButton.width and
			math.abs(y - virtualButton.y) < virtualButton.height then
			virtualButton:callback(parentInstance)
		end
	end
end

function sm.virtualButtons.client_getButtonPosition(parentInstance, x, y)
	for _, virtualButton in pairs(parentInstance.__virtualButtons or {}) do
		if math.abs(x - virtualButton.x) < virtualButton.width and
			math.abs(y - virtualButton.y) < virtualButton.height then
			return virtualButton.x, virtualButton.y
		end
	end
	return nil, nil
end
