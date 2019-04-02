----------------------------------
--Copyright (c) 2019 Brent Batch--
----------------------------------

--Usage of this gui API is permitted to {insert name} by Brent Batch -- 
--         To request usage of your own, contact Brent Batch         --

print("guibuilder reloaded")

-- API DOC:    -- all functions are *ClientMethod* 
--
-- gui = guiBuilder(Title, width, height, on_hide = nil, protectionlayers = 50
--  will create a new guibuilder. 
--  it is required to instantiate the guibuilder using gui:setupGui(self) where self is the part scriptclass 
-- 
--	Arguments: * Title (string) - the title on the top of the gui background
--             * width (number) - the width of the background window
--             * height (number) - the height of the background window
--             * on_hide (function) - a function that will be called every time the gui is hidden
-- 			   * protectionlayers (int) - the amount of protection against the gui breaking, default: 50

-- guiBuilder.setupGui(self, parentClass)
--  will set up the gui, should be called in your scriptclass inside scriptclass.client_onSetupGui( self )
--  Arguments: * self (table) - The guibuilder Instance
--             * parentClass (table) - the scriptclass Instance

-- guiBuilder.show(self) -- shows the gui
-- guiBuilder.hide(self) -- hides the gui
-- guiBuilder.setVisible(self, visible, nomessage) -- will set the gui (in)visible, show warning message or not, not by default
--	Arguments: * self (table) - The guibuilder Instance
--             * visible (boolean) 
--             * nomessage (nillable boolean) - only shows no message if true

-- guiBuilder.addItem(self, item)
--  adds an item to the gui
--	Arguments: * self (table) - The guibuilder Instance
--             * item (Item) - an item

-- guiBuilder.addItemWithId(self, itemid, item)
--  adds an item to the gui
--	Arguments: * self (table) - The guibuilder Instance
--             * itemid (string) - the item id, makes it easy to call inside your script oninteract to do stuff to the item
--             * item (Item) - an item

-- *UserData* guiBuilder: 
-- 		items (table) -- all items in the gui
-- 		bgPosX (number) -- the x pos of the top left corner of the background
-- 		bgPosY (number) -- the y pos of the top left corner of the background
--		visible (boolean) -- is the gui visible ?
-- 		on_hide (function) -- the onhide callback that will be called on hiding the gui
--		onClick (function (+ arg: widget{id, func(getText)(setText), getPosition, visible)) -- this onClick function will be called when clicking on any clickable button in the gui



-- all ITEMS: 
-- buttonItem, buttonSmallItem, labelItem, labelSmallItem, textBoxItem, invisibleBoxItem
--
-- buttonItem(posX, posY, width, height, value, onclick_callback = nil , play_sound = nil, border = true )
--   creates a new item, you can add these items to the guiBuilder instance
--  	Arguments: * posX (number) - the x position on the screen, add bgposx if you want relative from the background
--              * posY (number) - the y position on the screen
--              * widht (number) - width
--              * height (number) - height
--              * value (string) - the item text value
--              * onclick_callback (function) - the function to be called when clicking on the item
--              * play_sound (string) - the sound to play when clicking on the item
--  		    * border (boolean) - show a border around the item
-- 
--  Item.setVisible(self, visible) 
--  Item.setText(self, text) -- text (string)
--  Item.getText(self) -- returns text (string)
--  
--  *UserData* Item: onClick (function) 
--  
--  NOTE: textBoxItem has no border option, never has a border
--  NOTE: invisibleBoxItem has no value or border, usage: invisibleBoxItem(posX, posY, width, height, onclick_callback = nil , play_sound = nil)


-- SPECIAL ITEMS:

-- tabControllItem(headers, items)
--    creates a new tabcontroll , clicking the headers will show the appropriate collections
--   Arguments: * headers (table) - a table of items that will act as headers when clicking on them
--              * items (table) - a table of items  (header with id 1 will show the item with id 1)
--   
--   tabControllItem.addItem(self, header, item) -- add new tab with header and item in it
--   tabControllItem.addItemWithId(self, itemid, header, item) -- add new tab with header and item in it, with custom id's
--   tabControllItem.setVisible(self, visible) -- visible (boolean)
-- 
-- *UserData* tabControllItem:
-- 		headers (table) - a list of items that acts as header to the subitems
-- 		items (table) - a list of items , each item belongs to 1 header (an item can be a collection of items, check *collectionItems*)
-- 		visible (boolean)


-- collectionItems(items)
--   creates a collection of items inside this item, can be used for the tabControllItem subitems or to nest stuff
--  Arguments: * items (table) - a list of items
--   
--   collectionItems.addItem(self, item) -- add item
--   collectionItems.addItemWithId(self, itemid, item) -- add item with custom id, easy to reference then (collection.itemid:setText("lolol") )
--   collectionItems.setVisible(self, visible) 
--
-- *UserData* collectionItems: items (table)


-- optionMenuItem(posX, posY, width, height)
--   creates a new optionsMenu (arrowbuttons and stuff) , better performance than adding several buttonSmallItem
--  Arguments: * posX (number) - the x position of the options menu on screen (add bgPosX to line up inside the background)
--			   * posY (number) - the y position of the options menu on screen (add bgPosY to line up inside the background)
--			   * width (number) - width
--			   * height (number) - height
--
-- optionMenuItem.addItem(self, posX, posY, width, height)
--   adds a new optionitem inside the optionmenu with this pos and size, relative to the optionmenu
--	  Returns: that item (optionItem)
--
-- optionMenuItem.addItemWithId(self, itemid, posX, posY, width, height)
--   adds a new optionitem with the custom id inside the optionmenu with this pos and size, relative to the optionmenu
--	  Returns: that item (optionItem)
--
-- optionMenuItem.setVisible(self, visible) -- set visibility
--	
-- *UserData* optionMenuItem: items (table) contains all the (option)items

-- optionItem  (created by optionMenuItem, referencable: optionMenuItem.items[n] or by saving the return value of optionMenuItem.addItem)
--  NOTE: NOT MANUALLY INSTANTIATABLE, MUST BE CREATED BY optionMenuItem
-- 
--   optionItem.addLabel(self, posX, posY, width, height, value, onclick_callback = nil)
--   optionItem.addDecreaseButton(self, posX, posY, width, height, value, onclick_callback = nil)
--   optionItem.addIncreaseButton(self, posX, posY, width, height, value, onclick_callback = nil)
--   optionItem.addValueBox(self, posX, posY, width, height, value, onclick_callback = nil)
--    Arguments: * posX, posY, width, height (numbers) - position and size, relative to the optionItem
--               * value (string) - the text value of this item
--               * onclick_callback (function)
-- *UserData* optionItem: 
--		label			(table) {widget = widget, onclick_callback}
--		decreaseButton  (table) {widget = widget, onclick_callback}
--		valueBox        (table) {widget = widget, onclick_callback}
--		increaseButton  (table) {widget = widget, onclick_callback}
-- NOTE: for setText() and getText(), reference the widget: optionMenuItem.items[1].label.widget:setText("lolol")



guiBuilderScaleX = 1
guiBuilderScaleY = 1
function guiBuilder(title, width, height, on_hide, protectionlayers, autoscale)
	assert(type(title) == "string" or title == nil, "guiBuilder:Title: string expected! got: "..type(title))
	assert(type(width) == "number" or width == nil, "guiBuilder:width: number expected! got: "..type(width))
	assert(type(height) == "number" or height == nil, "guiBuilder:height: number expected! got: "..type(height))
	assert(type(on_hide) == "function" or on_hide == nil, "guiBuilder:on_hide: function expected! got: "..type(on_hide))
	assert(type(protectionlayers) == "number" or protectionlayers == nil, "guiBuilder:protectionlayers: number expected! got: "..type(protectionlayers))
	local guiBuilder = {}
	
	guiBuilder.on_hide = on_hide
	guiBuilder.autoscale = (autoscale == true or autoscale == nil)
	guiBuilder.scaleX = 1
	guiBuilder.scaleY = 1
	guiBuilder.width = width or 600
	guiBuilder.height = height or 300
	guiBuilder.title = title or ""
	guiBuilder.protectionlayers = protectionlayers or 50
	guiBuilder.killedlayers = 0
	guiBuilder.visible = false
	
	guiBuilder.onVisibleDetect_1 = nil
	guiBuilder.onVisibleDetect_2 = nil
	guiBuilder.items = {}
	guiBuilder.onClickRouteTable = {}
	
    function guiBuilder.setupGui(self, parentClass)
		assert(type(self) == "table", "setupGui:self: class expected! got: "..type(self))
		assert(type(parentClass) == "table", "setupGui:self: class expected! got: "..type(parentClass))
		
        local screenWidth, screenHeight = sm.gui.getScreenSize()
		if self.autoscale then -- 'native' res = 1080p
			self.scaleX = screenHeight/1080
			self.scaleY = screenWidth/1920
			guiBuilderScaleY = self.scaleX
			guiBuilderScaleX = self.scaleY -- global for other item elements
		end
		self.width, self.height = self.width*self.scaleX, self.height*self.scaleY
		
        self.bgPosX = (screenWidth - self.width)/2
        self.bgPosY = (screenHeight - self.height)/2
		
        self.guiBg = sm.gui.load("ChallengeMessage.layout", true)
        self.guiBg:setPosition(self.bgPosX, self.bgPosY)
		self.guiBg:setSize(self.width, self.height)
		self.guiBg:bindOnClick("killbg")
		
		self.onVisibleDetect_2 = self.guiBg
		
        local bgMainPanel = self.guiBg:find("MainPanel")
        sm.gui.widget.destroy(bgMainPanel:find("Next"))
        sm.gui.widget.destroy(bgMainPanel:find("Reset"))
        bgMainPanel:setSize(self.width, self.height)
        bgMainPanel:setPosition(0, 0)
		bgMainPanel:bindOnClick("killbg")
		
        local title = bgMainPanel:find("Title")
        title:setPosition(0, 0)
        title:setSize(self.width, 90)
        title:setText(self.title)
		title:bindOnClick("killbg")
		
		for i=1,self.protectionlayers do
			local layer = sm.gui.load("ChallengeMessage.layout", true)
			layer:bindOnClick("killview")
			sm.gui.widget.destroy(layer:find("MainPanel"))
			layer:setPosition(self.bgPosX, self.bgPosY)
			layer:setSize(self.width, self.height)
			self.items[layer.id] = layer
		end
		self:assignto(parentClass)
	end
	
	function guiBuilder.assignto(guibuilder, parentClass)
		function parentClass.client_onclick(self, widget)
			-- use onClickRouteTable to get item id
			local itemid = guibuilder.onClickRouteTable[widget.id]
			if guibuilder.items[itemid].onClick then guibuilder.items[itemid]:onClick(widget.id) end
			--Copyright (c) 2019 Brent Batch--
			if guibuilder.onClick then guibuilder.onClick(widget) end
		end
		function parentClass.killview(self, widget) -- only bg items
			guibuilder.items[widget.id]:setVisible(false)
			guibuilder.items[widget.id] = nil
			guibuilder.killedlayers = guibuilder.killedlayers + 1
			if guibuilder.protectionlayers - guibuilder.killedlayers < 11 then
				sm.gui.displayAlertText("WARNING: Spamming the background will break the gui!", 2)
			end
		end
		function parentClass.killbg(self, widget)
			sm.gui.displayAlertText("GREAT, you killed the GUI.... bad boy!", 2)
			if guibuilder.guiBg then
				guibuilder.guiBg:setVisible(false)
				guibuilder.guiBg = nil
			end
			parentClass.client_onUpdate = nil
			guibuilder.instantiated = false
			self.network:sendToServer("server_refreshgui")
		end
		function parentClass.server_refreshgui(self)
			sm.shape.destroyShape( self.shape, 0 )
			sm.shape.createPart( self.shape:getShapeUuid(), self.remoteguiposition, sm.quat.identity(), false, true ) 
		end
		function parentClass.client_onUpdate(self, dt)
			guibuilder:update(dt)
		end
		function parentClass.client_onRefresh(self)
			parentClass.client_onUpdate = nil
			if guibuilder.visible then sm.gui.displayAlertText("gui reloaded, press 'e' again for interacts to work",6) end
			guibuilder.instantiated = false
		end
		function parentClass.server_onRefresh(self)
			self:server_refreshgui()
		end
	end
	
	function guiBuilder.show(self) self:setVisible(true) end
	function guiBuilder.hide(self) self:setVisible(false) end
    function guiBuilder.setVisible(self, visible, nomessage)
		assert(type(visible) == "boolean", "setVisible:visible: boolean expected! got: "..type(visible))
		self.visible = visible
		if self.guiBg then 
			self.guiBg:setVisible(visible)
		end
		for _,item in pairs(self.items) do
			item:setVisible(visible)
		end
		if not visible then
			if self.on_hide then self.on_hide() end
			if not nomessage then
				sm.gui.displayAlertText("Press 'e' again, use 'e' to exit next time", 5)
			end
		end
	end
	
    function guiBuilder.update(self, dt)
		if self.onVisibleDetect_1 and self.onVisibleDetect_2 then
			if self.onVisibleDetect_1.visible ~= self.onVisibleDetect_2.visible then
				self:setVisible(self.onVisibleDetect_2.visible, true)
			end
		end
    end

	function guiBuilder.setVisibleDetection(self, newbutton)
		self.onVisibleDetect_1 = self.onVisibleDetect_1 or newbutton
	end
	
	
	function guiBuilder.addItem(self, item)
		assert(type(item) == "table", "addItem: table expected! got: "..type(item))
		assert(item.getClickRoutes ~= nil, "addItem: item expected! Not an item!")
		-- add item.clickRoutes to self.onClickRouteTable:
		for k, widgetid in pairs(item.getClickRoutes and item:getClickRoutes() or {}) do
			self.onClickRouteTable[widgetid] = item.id
		end
		self.items[item.id] = item
		self:setVisibleDetection(self.items[item.id])
	end
	
	function guiBuilder.addItemWithId(self, id, item) -- easy access to items in global gui by custom id
		assert(type(id) == "string" or type(id) == "number", "addItemWithId: number or string expected! got: "..type(id))
		assert(type(item) == "table", "addItemWithId: table expected! got: "..type(item))
		assert(item.getClickRoutes ~= nil, "addItemWithId: item expected! Not an item!")
		-- add item.clickRoutes to self.onClickRouteTable:
		for k, widgetid in pairs(item.getClickRoutes and item:getClickRoutes() or {}) do
			self.onClickRouteTable[widgetid] = id
		end
		self.items[id] = item
		self:setVisibleDetection(self.items[id])
	end
	
	
	
	return guiBuilder
end


function buttonItem( posX, posY, width, height, value, onclick_callback, play_sound, border )
	assert(type(posX) == "number", "buttonItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "buttonItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "buttonItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "buttonItem: height, number expected! got: "..type(height))
	assert(type(value) == "string", "buttonItem: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "buttonItem: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "buttonItem: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "buttonItem: border, boolean or nil expected! got: "..type(border))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("ChallengeMessage.layout", true)
	item.gui:setPosition(posX , posY )
	item.gui:setSize(width, height)
	

	local MainPanel = item.gui:find("MainPanel")
	sm.gui.widget.destroy(MainPanel:find("Title"))
	sm.gui.widget.destroy(MainPanel:find("Reset"))
	MainPanel:setSize(width, height)
	
	item.widget = MainPanel:find("Next")
	item.widget:setPosition(extra/-2,extra/-2)
	item.widget:setSize(width + extra, height+ extra)
	item.widget:setText(value)
	
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
	function item.setVisible(self, visible)
		self.visible = visible
		self.gui.visible = visible
	end
	
	function item.setText(self, text)
		self.widget:setText(text)
	end
	function item.getText(self)
		return self.widget:getText()
	end
	return item
end

function buttonSmallItem(posX, posY, width, height, value, onclick_callback, play_sound, border )
	assert(type(posX) == "number", "buttonSmallItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "buttonSmallItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "buttonSmallItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "buttonSmallItem: height, number expected! got: "..type(height))
	assert(type(value) == "string", "buttonSmallItem: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "buttonSmallItem: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "buttonSmallItem: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "buttonSmallItem: border, boolean or nil expected! got: "..type(border))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("AudioOptions.layout", true)
	item.gui:setPosition(posX, posY )
	item.gui:setSize(width, height)
	local buttonoffset = 300

	local MainPanel = item.gui:find("AudioMainPanel")
	sm.gui.widget.destroy(MainPanel:find("MasterVolume"))
	sm.gui.widget.destroy(MainPanel:find("AudioGroups"))
	MainPanel:setSize(width + buttonoffset, height)
	MainPanel:setPosition(0 - buttonoffset, 0)
	
	item.widget = MainPanel:find("Default")
	item.widget:setPosition(extra/-2 + buttonoffset,extra/-2)
	item.widget:setSize(width+extra, height+extra)
	item.widget:setText(value)
	
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
	
		
	function item.setVisible(self, visible)
		self.visible = visible
		self.gui.visible = visible
	end
	
	function item.setText(self, text)
		self.widget:setText(text)
	end
	function item.getText(self)
		return self.widget:getText()
	end
	return item
end


function labelItem(posX, posY, width, height, value, onclick_callback, play_sound, border )	
	assert(type(posX) == "number", "labelItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "labelItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "labelItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "labelItem: height, number expected! got: "..type(height))
	assert(type(value) == "string", "labelItem: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "labelItem: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "labelItem: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "labelItem: border, boolean or nil expected! got: "..type(border))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	--Copyright (c) 2019 Brent Batch--
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("ChallengeMessage.layout", true)
	item.gui:setPosition(posX , posY )
	item.gui:setSize(width, height)

	local MainPanel = item.gui:find("MainPanel")
	sm.gui.widget.destroy(MainPanel:find("Next"))
	sm.gui.widget.destroy(MainPanel:find("Reset"))
	
	MainPanel:setSize(width+extra, height+extra)
	MainPanel:setPosition(extra/-2, extra/-2)
	
	item.widget = MainPanel:find("Title")
	item.widget:setPosition(extra/2,extra/2)
	item.widget:setSize(width, height)
	item.widget:setText(value)
	
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
		
	function item.setVisible(self, visible)
		self.visible = visible
		self.gui.visible = visible
	end
	
	function item.setText(self, text)
		self.widget:setText(text)
	end
	function item.getText(self)
		return self.widget:getText()
	end
	return item
end

function labelSmallItem( posX, posY, width, height, value, onclick_callback, play_sound, border )
	assert(type(posX) == "number", "labelSmallItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "labelSmallItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "labelSmallItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "labelSmallItem: height, number expected! got: "..type(height))
	assert(type(value) == "string", "labelSmallItem: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "labelSmallItem: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "labelSmallItem: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "labelSmallItem: border, boolean or nil expected! got: "..type(border))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("MessageGuiLoadingBar.layout", true)
	item.gui:setPosition(posX , posY )
	item.gui:setSize(width, height)

	local MainPanel = item.gui:find("MessageLoadingBarMainPanel")
	sm.gui.widget.destroy(MainPanel:find("Title"))
	sm.gui.widget.destroy(MainPanel:find("LoadingBar"))
	
	MainPanel:setSize(width+extra, height+extra)
	MainPanel:setPosition(extra/-2, extra/-2)
	
	item.widget = MainPanel:find("Message")
	item.widget:setPosition(extra/2,extra/2)
	item.widget:setSize(width, height)
	item.widget:setText(value)
	
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
	
	function item.setVisible(self, visible)
		self.visible = visible
		self.gui.visible = visible
	end
	
	function item.setText(self, text)
		self.widget:setText(text)
	end
	function item.getText(self)
		return self.widget:getText()
	end
	return item
end

function textBoxItem( posX, posY, width, height, value, onclick_callback, play_sound ) -- no border here
	assert(type(posX) == "number", "textBoxItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "textBoxItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "textBoxItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "textBoxItem: height, number expected! got: "..type(height))
	assert(type(value) == "string", "textBoxItem: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "textBoxItem: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "textBoxItem: play_sound, string or nil expected! got: "..type(play_sound))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("NewGameMenu.layout", true)
	item.gui:find("NewMainPanel"):setPosition(0,-100)
	item.gui:setPosition(posX , posY )
	item.gui:setSize(width, height)

	local MainPanel = item.gui:find("NewMainPanel"):find("GamePanel")
	sm.gui.widget.destroy(MainPanel:find("Create"))
	sm.gui.widget.destroy(MainPanel:find("Worlds"))
		
	item.widget = MainPanel:find("Name")
	item.widget:setPosition(0,100)
	item.widget:setSize(width, height)
	item.widget:setText(value)
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
	
	function item.setVisible(self, visible)
		self.visible = visible
		self.gui.visible = visible
	end
	
	function item.setText(self, text)
		self.widget:setText(text)
	end
	function item.getText(self)
		return self.widget:getText()
	end
	return item
end


function invisibleBoxItem( posX, posY, width, height, onclick_callback, play_sound ) -- no border, also no value
	assert(type(posX) == "number", "invisibleBoxItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "invisibleBoxItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "invisibleBoxItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "invisibleBoxItem: height, number expected! got: "..type(height))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "invisibleBoxItem: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "invisibleBoxItem: play_sound, string or nil expected! got: "..type(play_sound))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	local item = {}
	item.visible = true
	item.widget = sm.gui.load("ParticlePreview.layout", true)

	sm.gui.widget.destroy(item.widget:find("Background"))
	item.widget:setPosition(posX , posY )
	item.widget:setSize(width, height)
	
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
	function item.setVisible(self, visible)
		self.visible = visible
		self.widget.visible = visible
	end
	function item.setText(self, text)
		--self.widget:setText(text)
		print("CANNOT SET TEXT ON THIS WIDGET")
	end
	function item.getText(self)
		return ""--self.widget:getText()
	end
	return item
end


function tabControllItem(headers, items)
	assert(type(headers) == "table", "tabControllItem: headers, table expected! got: "..type(headers))
	assert(type(items) == "table", "tabControllItem: items, table expected! got: "..type(items))
	for k, v in pairs(headers) do assert(type(v) == "table", "tabControllItem: header, table expected! got: "..type(v)) end
	for k, v in pairs(items) do assert(type(v) == "table", "tabControllItem: item, table expected! got: "..type(v)) end
	for k, v in pairs(headers) do assert(v.getClickRoutes ~= nil, "tabControllItem: header, item expected! Not an item!") end
	for k, v in pairs(items) do assert(v.getClickRoutes ~= nil, "tabControllItem: item, item expected! Not an item!") end
	
	local item = {}
	item.id = headers and headers[1] and headers[1].id or nil
	item.headers = headers -- { [1] = item, [2] = item, ... }
	item.items = items -- { [1] = collection/item, [2] = collection/item, ... } NOW ALSO WITH CUSTOM IDS thanks to addItemWithId
	item.visible = true
	item.onClickRouteTable = {} 
	item.currenttab = 1
	
	function item.addItem(self, newheader, newcollection)
		table.insert(item.headers, newheader)
		table.insert(item.items, newcollection)
		self.id = self.id or newheader.id
	end
	function item.addItemWithId(self, headerid, newheader, newcollection)
		item.headers[headerid] = newheader
		item.items[headerid] = newcollection
		self.id = self.id or newheader.id
	end
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy now useless functions, only called once added to guibuilder
		self.addItem = nil
		self.addItemWithId = nil
		local widgetids = {}
		for contenttype , items in pairs({header = self.headers, item = self.items}) do -- loop over ALL items
			for itemid, header in pairs(items) do
				if contenttype == "header" and not header.onClick then header.widget:bindOnClick("client_onclick") end -- stupid lil extra
				for _, widgetid in pairs(header:getClickRoutes()) do
					self.onClickRouteTable[widgetid] = {itemid = itemid, contenttype = contenttype}
					table.insert(widgetids, widgetid)
				end
				header:setVisible(false)
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid)
		local itemdata = self.onClickRouteTable[widgetid]
		if itemdata.contenttype == "header" then
			--sm.audio.play("GUI Inventory highlight") -- make this customizable ?
			if self.headers[itemdata.itemid].onClick then self.headers[itemdata.itemid]:onClick(widgetid) end
			self.currenttab = itemdata.itemid
			self:setVisibleTab(true)
		else
			if self.items[itemdata.itemid].onClick then self.items[itemdata.itemid]:onClick(widgetid) end
		end
	end
	function item.setVisible(self, visible)
		self.visible = visible
		for k, item in pairs(self.headers) do
			item:setVisible(visible)
		end
		self:setVisibleTab(visible)
	end
	
	function item.setVisibleTab(self, visible, tab)
		--self.currenttab = (tab and tab or self.currenttab) -- change tab if defined
		for itemindex, item in pairs(self.items) do
			item:setVisible(itemindex == self.currenttab and visible)
		end
	end
	return item
end


function collectionItems(items)
	assert(type(items) == "table", "collectionItems: items, table expected! got: "..type(items))
	for k, v in pairs(items) do assert(type(v) == "table", "collectionItems: items, table expected! got: "..type(v)) end
	for k, v in pairs(items) do assert(v.getClickRoutes ~= nil, "collectionItems: item, item expected! Not an item!") end
	
	local item = {}
	item.visible = true
	item.items = items
	item.onClickRouteTable = {}
	item.id = items[1] and items[1].id or nil

	function item.addItem(self, newitem)
		table.insert(self.items, newitem)
		self.id = self.id or newitem.id
	end
	function item.addItemWithId(self, itemid, newitem)
		self.items[itemid] = newitem
		self.id = self.id or newitem.id
	end
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy now useless functions, only called once added to guibuilder
		self.addItem = nil
		local widgetids = {}
		for itemid, optionItem in pairs(self.items) do
			for _, widgetid in pairs(optionItem:getClickRoutes()) do
				self.onClickRouteTable[widgetid] = itemid
				table.insert(widgetids, widgetid)
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid)
		local itemid = self.onClickRouteTable[widgetid]
		if self.items[itemid].onClick then self.items[itemid]:onClick(widgetid) end
		if self.items[itemid].playSound then self.items[itemid]:playSound() end
	end
	function item.setVisible(self, visible)
		self.visible = visible
		for k, item in pairs(self.items) do
			item:setVisible(visible)
		end
	end
	return item
end

function itemTableSize(sometable)
	local i = 0
	for k,v in pairs(sometable) do
		i = i + 1
	end
	return i 
end

function optionMenuItem(posX, posY, width, height)
	assert(type(posX) == "number", "optionMenuItem: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "optionMenuItem: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "optionMenuItem: width, number expected! got: "..type(width))
	assert(type(height) == "number", "optionMenuItem: height, number expected! got: "..type(height))
	if guiBuilderScaleX and guiBuilderScaleY then
		posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
	end
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("OptionsMenuPage.layout", true)
	item.gui:setSize(width, height)
	item.gui:setPosition(posX, posY)
	local mainPanel = item.gui:find("OptionsMenuPageMainPanel")
	mainPanel:setSize(width, height)
	for i= 0,17 do mainPanel:find("ITEM_" .. i).visible = false end
	
	item.id = item.gui.id
	item.items = {}
	item.onClickRouteTable = {} -- which item should i call if widgetid x is clicked on ?
	
	function item.addItem(self, posX, posY, width, height)
		assert(type(posX) == "number", "optionMenuItem.addItem: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenuItem.addItem: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenuItem.addItem: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenuItem.addItem: height, number expected! got: "..type(height))
		if guiBuilderScaleX and guiBuilderScaleY then
			posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
		end
		local id = itemTableSize(self.items) + 1
		local widgetItem = mainPanel:find("ITEM_" .. id)
		widgetItem:setPosition(posX, posY)
		widgetItem:setSize(width, height)
		widgetItem.visible = true
		for k, widget in pairs({widgetItem:find("Label"), widgetItem:find("Decrease"), widgetItem:find("Value"), widgetItem:find("Increase")}) do
			widget.visible = false
		end
		item.items[id] = optionItem(widgetItem)
		return item.items[id]
	end
	function item.addItemWithId(self, customid, posX, posY, width, height)
		assert(type(posX) == "number", "optionMenuItem.addItemWithId: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenuItem.addItemWithId: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenuItem.addItemWithId: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenuItem.addItemWithId: height, number expected! got: "..type(height))
		if guiBuilderScaleX and guiBuilderScaleY then
			posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
		end
		local id = itemTableSize(self.items) + 1
		local widgetItem = mainPanel:find("ITEM_" .. id)
		widgetItem:setPosition(posX, posY)
		widgetItem:setSize(width, height)
		widgetItem.visible = true
		for k, widget in pairs({widgetItem:find("Label"), widgetItem:find("Decrease"), widgetItem:find("Value"), widgetItem:find("Increase")}) do
			widget.visible = false
		end
		item.items[customid] = optionItem(widgetItem)
		return item.items[customid]
	end
	
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy now useless functions, only called once added to guibuilder
		self.addItem = nil
		self.addItemWithId = nil
		local widgetids = {}
		for itemid, optionItem in pairs(self.items) do
			for _, widgetid in pairs(optionItem:getClickRoutes()) do
				self.onClickRouteTable[widgetid] = itemid
				table.insert(widgetids, widgetid)
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid)
		local itemid = self.onClickRouteTable[widgetid]
		self.items[itemid]:onClick(widgetid)
	end
	function item.setVisible(self, visible)
		self.gui.visible = visible
		self.visible = visible
	end
	return item
end

function optionItem(widgetItem)
	local item = {}
	item.gui = widgetItem
	item.label = {}
	item.decreaseButton = {}
	item.valueBox = {}
	item.increaseButton = {}
	function item.addLabel(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenuItem.item.addLabel: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenuItem.item.addLabel: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenuItem.item.addLabel: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenuItem.item.addLabel: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenuItem.item.addLabel: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenuItem.item.addLabel: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		if guiBuilderScaleX and guiBuilderScaleY then
			posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
		end
		local widget = self.gui:find("Label")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name)
		widget.visible = true
		if onclick_callback then widget:bindOnClick("client_onclick") end
		self.label = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.addDecreaseButton(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenuItem.item.addDecreaseButton: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenuItem.item.addDecreaseButton: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenuItem.item.addDecreaseButton: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenuItem.item.addDecreaseButton: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenuItem.item.addDecreaseButton: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenuItem.item.addDecreaseButton: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		if guiBuilderScaleX and guiBuilderScaleY then
			posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
		end
		local widget = self.gui:find("Decrease")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name) -- can't really set text but whatever
		widget.visible = true
		if onclick_callback then widget:bindOnClick("client_onclick") end
		self.decreaseButton = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.addValueBox(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenuItem.item.addValueBox: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenuItem.item.addValueBox: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenuItem.item.addValueBox: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenuItem.item.addValueBox: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenuItem.item.addValueBox: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenuItem.item.addValueBox: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		if guiBuilderScaleX and guiBuilderScaleY then
			posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
		end
		local widget = self.gui:find("Value")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name)
		widget.visible = true
		if onclick_callback then widget:bindOnClick("client_onclick") end
		self.valueBox = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.addIncreaseButton(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenuItem.item.addIncreaseButton: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenuItem.item.addIncreaseButton: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenuItem.item.addIncreaseButton: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenuItem.item.addIncreaseButton: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenuItem.item.addIncreaseButton: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenuItem.item.addIncreaseButton: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		if guiBuilderScaleX and guiBuilderScaleY then
			posX, posY, width, height = posX*guiBuilderScaleX, posY*guiBuilderScaleY, width*guiBuilderScaleX, height*guiBuilderScaleY
		end
		local widget = self.gui:find("Increase")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name)
		widget.visible = true
		if onclick_callback then widget:bindOnClick("client_onclick") end
		self.increaseButton = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy now useless functions, only called once added to guibuilder
		self.addLabel = nil
		self.addDecreaseButton = nil
		self.addIncreaseButton = nil
		self.addValueBox = nil
		local widgetids = {}
		for _,button in pairs({self.label, self.decreaseButton, self.valueBox, self.increaseButton}) do
			if button.widget then 
				table.insert(widgetids, button.widget.id) 
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid)
		for _,button in pairs({self.label, self.decreaseButton, self.valueBox, self.increaseButton}) do
			if button and button.widget.id == widgetid then 
				sm.audio.play("GUI Inventory highlight", position)
				button:onClick()
			end
		end
	end
	function item.setVisible(self, visible)
		self.gui.visible = visible
		self.visible = visible
	end
	return item
end