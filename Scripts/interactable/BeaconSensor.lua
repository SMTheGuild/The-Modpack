--dofile( "$SURVIVAL_DATA/Scripts/game/managers/BeaconManager.lua" )

BeaconSensor = class()
BeaconSensor.maxParentCount = 0
BeaconSensor.maxChildCount = 0
BeaconSensor.connectionInput = sm.interactable.connectionType.none
BeaconSensor.connectionOutput = sm.interactable.connectionType.logic
BeaconSensor.poseWeightCount = 1

local UVSpeed = 5
local UnfoldSpeed = 15

local BEACON_COLORS = {
	sm.color.new( "4F6CFF" ),
	sm.color.new( "AF7DFF" ),
	sm.color.new( "00FFFF" ),
	sm.color.new( "90FF78" ),
	sm.color.new( "FFD046" ),
	sm.color.new( "FFFFC0" ),
	sm.color.new( "FF6619" ),
	sm.color.new( "FF3737" )
}

function BeaconSensor.server_onCreate( self )
	self.loaded = true

	self.saved = self.storage:load()
	self.saved = self.saved or {}
	self.saved.icon = self.saved.icon or 0
	self.saved.color = self.saved.icon or 1
	self.saved.andor = self.saved.andor or false
	self.saved.range = self.saved.range or 50

	self.storage:save(self.saved)
	self.network:setClientData(self.saved)
end

function BeaconSensor.server_onDestroy( self )
	self.loaded = false
end

function BeaconSensor.server_onUnload( self )
	self.loaded = false
end

function BeaconSensor.sv_updateData( self, params )
	if params.iconIndex then
		self.saved.iconData.iconIndex = params.iconIndex
	end
	if params.colorIndex then
		self.saved.iconData.colorIndex = params.colorIndex
	end
	self.storage:save( self.saved )
	self.network:setClientData( { iconIndex = self.saved.iconData.iconIndex, colorIndex = self.saved.iconData.colorIndex } )
end

function BeaconSensor.client_onCreate( self )
	self.cl = {}
	self.cl.loopingIndex = 0
	self.cl.unfoldWeight = 0

	if self.cl.selectedIconButton == nil then
		self.cl.selectedIconButton = "IconButton0"
	end
	if self.cl.selectedColorButton == nil then
		self.cl.selectedColorButton = "ColorButton0"
	end
end

function BeaconSensor.client_onDestroy( self )
	self.cl.idleSound:stop()
	self.cl.idleSound:destroy()
	self.cl.idleSound = nil

	if self.cl.beaconIconGui then
		self.cl.beaconIconGui:close()
		self.cl.beaconIconGui:destroy()
	end
end

function BeaconSensor.client_onClientDataUpdate( self, clientData )
	if self.cl == nil then
		self.cl = {}
	end
	local selectedIconButton = "IconButton" .. tostring( clientData.iconIndex )
	local selectedColorButton = "ColorButton" .. tostring( clientData.colorIndex - 1 )

	if self.cl.gui then
		self:cl_updateIconButton( selectedIconButton )
		self:cl_updateColorButton( selectedColorButton )
	else
		self.cl.selectedIconButton = selectedIconButton
		self.cl.selectedColorButton = selectedColorButton
	end

	if self.cl.beaconIconGui then
		self.cl.beaconIconGui:close()
	else
		self.cl.beaconIconGui = sm.gui.createBeaconIconGui()
	end
	self.cl.beaconIconGui:setItemIcon( "Icon", "BeaconIconMap", "BeaconIconMap", tostring( clientData.iconIndex ) )
	local beaconColor = BEACON_COLORS[clientData.colorIndex]
	self.cl.beaconIconGui:setColor( "Icon", beaconColor )
	self.cl.beaconIconGui:setHost( self.shape )
	self.cl.beaconIconGui:setRequireLineOfSight( false )
	self.cl.beaconIconGui:setMaxRenderDistance(10000)
	self.cl.beaconIconGui:open()
end

function BeaconSensor.client_onUpdate( self, dt )
	self.cl.loopingIndex = self.cl.loopingIndex + dt * UVSpeed
	if self.cl.loopingIndex >= 4 then
		self.cl.loopingIndex = 0
	end
	self.interactable:setUvFrameIndex( math.floor( self.cl.loopingIndex ) )

	if self.cl.unfoldWeight < 1.0 then
		self.cl.unfoldWeight = math.min( self.cl.unfoldWeight + dt * UnfoldSpeed, 1.0 )
		self.interactable:setPoseWeight( 0, self.cl.unfoldWeight )
	end

	if self.cl.idleSound and not self.cl.idleSound:isPlaying() then
		self.cl.idleSound:start()
	end
end

function BeaconSensor.client_onInteract( self, character, state )
	print( "client_onInteract", state )
	if state == true then
		self.cl.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/BeaconSensor.layout") --Destroy on close
		for i = 0, 23 do
			self.cl.gui:setButtonCallback( "IconButton" .. tostring( i ), "cl_onIconButtonClick" )
		end
		for i = 0, 7 do
			self.cl.gui:setButtonCallback( "ColorButton" .. tostring( i ), "cl_onColorButtonClick" )
		end

		self.cl.gui:setOnCloseCallback( "cl_onClose" )
		self.cl.gui:open()
		self:cl_updateIconButton( self.cl.selectedIconButton )
		self:cl_updateColorButton( self.cl.selectedColorButton )
	end
end

function BeaconSensor.cl_onIconButtonClick( self, name )
	print( "cl_onButtonClick", name )
	local iconIndex = tonumber( name:match( '%d+' ) )
	self.network:sendToServer( "sv_updateData", { iconIndex = iconIndex } )
end

function BeaconSensor.cl_onColorButtonClick( self, name )
	print( "cl_onButtonClick", name )
	local colorIndex = tonumber( name:match( '%d+' ) ) + 1
	self.network:sendToServer( "sv_updateData", { colorIndex = colorIndex } )
end

function BeaconSensor.cl_onClose( self )
	self.cl.gui:destroy()
	self.cl.gui = nil
end

function BeaconSensor.cl_updateIconButton( self, iconButtonName )
	if self.cl.selectedIconButton ~= iconButtonName then
		self.cl.gui:setButtonState( self.cl.selectedIconButton, false )
		self.cl.selectedIconButton = iconButtonName
	end
	self.cl.gui:setButtonState( self.cl.selectedIconButton, true )
	self:cl_updateSelectedIconColor()
end

function BeaconSensor.cl_updateColorButton( self, colorButtonName )
	if self.cl.selectedColorButton ~= colorButtonName then
		self.cl.gui:setButtonState( self.cl.selectedColorButton, false )
		self.cl.selectedColorButton = colorButtonName
	end
	self.cl.gui:setButtonState( self.cl.selectedColorButton, true )
	self:cl_updateSelectedIconColor()
end

function BeaconSensor.cl_updateSelectedIconColor( self )
	local defaultColor = sm.color.new( "FFFFFF4F" )
	for i = 0, 23 do
		self.cl.gui:setColor( "IconImage" .. tostring( i ), defaultColor )
	end
	local colorIndex = tonumber( self.cl.selectedColorButton:match( '%d+' ) ) + 1
	local iconColor = BEACON_COLORS[colorIndex]
	self.cl.gui:setColor( "IconImage" .. self.cl.selectedIconButton:match( '%d+' ), iconColor )
end