--[[
	Copyright (c) 2020 Modpack Team
]]--
dofile "../../libs/load_libs.lua"

print("loading FlappyWing.lua")

dofile("airfoil.lua")

FlappyWing = class( nil )
FlappyWing.maxParentCount = 1
FlappyWing.maxChildCount = -1
FlappyWing.connectionInput = sm.interactable.connectionType.power
FlappyWing.connectionOutput = sm.interactable.connectionType.power
FlappyWing.colorNormal = sm.color.new( 0x009999ff  )
FlappyWing.colorHighlight = sm.color.new( 0x11B2B2ff  )
FlappyWing.poseWeightCount = 1

function FlappyWing.server_onCreate( self ) 
	self:server_init()
end

function FlappyWing.server_onRefresh( self )
	--self:server_init()
end

function FlappyWing.server_init( self )
    if not self.data.animationName   then self.data.animationName   = nil   end
    if not self.data.animationLoop   then self.data.animationLoop   = false end
    if not self.data.animationMin    then self.data.animationMin    = 0     end
    if not self.data.animationMax    then self.data.animationMax    = 0     end
    if not self.data.animationOffset then self.data.animationOffset = 0     end
    if not self.data.angleLoop       then self.data.angleLoop       = false end
    if not self.data.angleMin        then self.data.angleMin        = 0     end
    if not self.data.angleMax        then self.data.angleMax        = 0     end
    
    for id,surface in pairs(self.data.surfaces) do
        if not surface.area or surface.area == 0 then
            sm.log.warning("Modpack wing with UUID=" .. self.shape.shapeUuid .. " has a useless surface with id=" .. id ..".")
            surface = nil
        end
        if not surface.angleModifier     then surface.angleModifier     = 0         end
        if not surface.angleOffset       then surface.angleOffset       = 0         end
        if not surface.offset            then surface.offset            = {0, 0, 0} end
        if not surface.offsetModifierSin then surface.offsetModifierSin = {0, 0, 0} end
        if not surface.offsetModifierCos then surface.offsetModifierCos = {0, 0, 0} end
        if not surface.offsetModifierTan then surface.offsetModifierTan = {0, 0, 0} end
        
        surface.offset            = sm.vec3.new(surface.offset[1],            surface.offset[2],            surface.offset[3]           )
        surface.offsetModifierSin = sm.vec3.new(surface.offsetModifierSin[1], surface.offsetModifierSin[2], surface.offsetModifierSin[3])
        surface.offsetModifierCos = sm.vec3.new(surface.offsetModifierCos[1], surface.offsetModifierCos[2], surface.offsetModifierCos[3])
        surface.offsetModifierTan = sm.vec3.new(surface.offsetModifierTan[1], surface.offsetModifierTan[2], surface.offsetModifierTan[3])
    end
    
	self.interactable.power = 0
    self.area = self.data.area
end

function FlappyWing.server_onFixedUpdate( self, timeStep )
    local parent = self.interactable:getSingleParent()
    
    if parent then
        self.angle = self.data.angleLoop and parent.power or sm.util.clamp(parent.power, self.data.angleMin, self.data.angleMax) -- == 0 and -90 or 90
    else
        self.angle = 0
    end

    mp_setPowerSafe(self, self.angle)
    
    doAirfoilStuff(self, timeStep)
end




function FlappyWing.client_onCreate( self )
	self:client_init()
end

function FlappyWing.client_onRefresh( self )
	self:client_init()
end

function FlappyWing.client_init( self )
    self.interactable:setAnimEnabled(self.data.animationName, true)
    self.animationProgress = 0
    self.prevPower = 0
    self.currentPower = 0
end

function FlappyWing.client_onUpdate( self, dt )
    if self.data.animationName then
        if self.interactable.power ~= self.currentPower then
            self.animationProgress = 0
            self.prevPower = self.currentPower
            self.currentPower = self.interactable.power
        else
            self.animationProgress = math.min(self.animationProgress + dt/0.025, 1)
        end
        
        
        local lerp = sm.util.lerp(self.prevPower, self.currentPower, self.animationProgress)
        
        local progress = map(
            lerp + self.data.animationOffset,
            self.data.angleMin,
            self.data.angleMax,
            0,
            1
        )
        
        if self.data.animationLoop then
            progress = progress % 1
        end
        
        self.interactable:setAnimProgress(self.data.animationName, progress)
    end
end

function FlappyWing.client_createParticle( self, position )
    sm.particle.createParticle( "paint_smoke", position, nil, self.shape.color )
end





function map( value, from1, to1, from2, to2 )
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2
end

function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end