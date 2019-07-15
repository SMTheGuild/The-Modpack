if __InteractableImprovements_Loaded then return end
__InteractableImprovements_Loaded = true

-- server: 

local values = {} -- <<not directly accessible for other scripts
function sm.interactable.setValue(interactable, value)  
    local currenttick = sm.game.getCurrentTick()
    values[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        values[interactable.id] and (    
            values[interactable.id][1] ~= nil and 
            (values[interactable.id][1].tick < currenttick) and 
            values[interactable.id][1].value or 
			values[interactable.id][2]
        ) 
        or nil
    }
end
function sm.interactable.getValue(interactable, NOW)    
	if sm.exists(interactable) and values[interactable.id] then
		if values[interactable.id][1] and (values[interactable.id][1].tick < sm.game.getCurrentTick() or NOW) then
			return values[interactable.id][1].value[1]
		elseif values[interactable.id][2] then
			return values[interactable.id][2][1]
		end
	end
	return nil
end

function sm.interactable.isNumberType(interactable)
	return (interactable:getType() == "scripted" and tostring(interactable:getShape().shapeUuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"  --[[tickbutton]])
end


-- to have the following working   <interactable>:setValue(somevalue) <interactable>:getValue()
-- perform   sm.ImproveUserData(self)   in   scriptclass.server_onCreate(self)

if not sm.UserDataImprovements then 
	sm.UserDataImprovements = {}
	function sm.ImproveUserData(self)
		for k, improvement in pairs(sm.UserDataImprovements) do
			improvement(self)
		end
		function sm.ImproveUserData(self) end -- 'remove' function to prevent multiple loads
	end
end

table.insert(
	sm.UserDataImprovements, 
	function(self)
		self.interactable.setValue = sm.interactable.setValue
		self.interactable.getValue = sm.interactable.getValue
		
		self.interactable.isNumberType = sm.interactable.isNumberType
	end
)




-- client:

---[[
local uvs = {} -- <<not directly accessible for other scripts
local __OLD_setUvFrameIndex = sm.interactable.setUvFrameIndex
function sm.interactable.setUvFrameIndex(interactable, value)  
    local currenttick = sm.game.getCurrentTick()
	__OLD_setUvFrameIndex(interactable, value)
    uvs[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        uvs[interactable.id] and (    
            uvs[interactable.id][1] ~= nil and 
            (uvs[interactable.id][1].tick < currenttick) and 
            uvs[interactable.id][1].value or 
			uvs[interactable.id][2]
        ) 
        or nil
    }
end

local __OLD_getUvFrameIndex = sm.interactable.getUvFrameIndex
function sm.interactable.getUvFrameIndex(interactable)
	if sm.exists(interactable) and uvs[interactable.id] then
		if uvs[interactable.id][1] and uvs[interactable.id][1].tick < sm.game.getCurrentTick() then
			return uvs[interactable.id][1].value[1]
		elseif uvs[interactable.id][2] then
			return uvs[interactable.id][2][1]
		end
	end
	return __OLD_getUvFrameIndex(interactable)
end


local glows = {} -- <<not directly accessible for other scripts
local __OLD_setGlowMultiplier = sm.interactable.setGlowMultiplier
function sm.interactable.setGlowMultiplier(interactable, value)  
    local currenttick = sm.game.getCurrentTick()
	__OLD_setGlowMultiplier(interactable, value)
    glows[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        glows[interactable.id] and (    
            glows[interactable.id][1] ~= nil and 
            (glows[interactable.id][1].tick < currenttick) and 
            glows[interactable.id][1].value or 
			glows[interactable.id][2]
        ) 
        or nil
    }
end

local __OLD_getGlowMultiplier = sm.interactable.getGlowMultiplier
function sm.interactable.getGlowMultiplier(interactable)
	if sm.exists(interactable) and glows[interactable.id] then
		if glows[interactable.id][1] and glows[interactable.id][1].tick < sm.game.getCurrentTick() then
			return glows[interactable.id][1].value[1]
		elseif glows[interactable.id][2] then
			return glows[interactable.id][2][1]
		end
	end
	return __OLD_getGlowMultiplier(interactable)
end

-- perform  sm.ImproveUserDataClient(self)  in  client_onCreate to have  <interactable>:getUvFrameIndex()  working
if not sm.UserDataImprovementsClient then 
	sm.UserDataImprovementsClient = {}
	function sm.ImproveUserDataClient(self)
		for k, improvement in pairs(sm.UserDataImprovementsClient) do
			improvement(self)
		end
		function sm.ImproveUserDataClient(self) end -- 'remove' function to prevent multiple loads
	end
end
table.insert(
	sm.UserDataImprovementsClient, 
	function(self)
		self.interactable.setUvFrameIndex = sm.interactable.setUvFrameIndex
		self.interactable.getUvFrameIndex = sm.interactable.getUvFrameIndex
		self.interactable.setGlowMultiplier = sm.interactable.setGlowMultiplier
		self.interactable.getGlowMultiplier = sm.interactable.getGlowMultiplier
	end
)
--]]