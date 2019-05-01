
----------------------------------
--Copyright (c) 2019 Brent Batch--
----------------------------------

-- API DOC:    -- all functions are *ClientMethod* 
--
-- gui = sm.globalgui.create(parentClass, title, width, height, on_hide, on_update, protectionlayers, autoscale)
-- 		 will create a new gui. 
-- 		
--			Arguments: 
--					* parentClass (table) - the scriptclass Instance
--					* Title (string) - the title on the top of the gui background
-- 		            * width (number) - the width of the background window
-- 		            * height (number) - the height of the background window
-- 		            * on_hide (nil/function) - a function that will be called every time the gui is hidden
-- 		            * on_update (nil/function) - a function that will be called every frame
-- 					* protectionlayers (nil/int) - the amount of protection against the gui breaking, goes to default when nil: 50
--					* autoscale (nil/boolean)
		
--	*functions*
-- 		gui.show(self) -- shows the gui
-- 		gui.hide(self) -- hides the gui
-- 		gui.setVisible(self, visible, nomessage) -- will set the gui (in)visible, show warning message or not, not by default
--			Arguments: * self (table) - The gui Instance
-- 		            * visible (boolean) 
-- 		            * nomessage (nil/boolean) - only shows no message if true
		
-- 		gui.addItem(self, item)
-- 		 adds an item to the gui
--			Arguments: * self (table) - The gui Instance
-- 		            * item (Item) - an item
		
-- 		gui.addItemWithId(self, itemid, item)
-- 		 adds an item to the gui
--			Arguments: * self (table) - The gui Instance
-- 		            * itemid (string) - the item id, makes it easy to call inside your script oninteract to do stuff to the item
-- 		            * item (Item) - an item
		
-- *UserData*
-- 		items (table) -- all items in the gui
-- 		bgPosX (number) -- the x pos of the top left corner of the background
-- 		bgPosY (number) -- the y pos of the top left corner of the background
--		visible (boolean) -- is the gui visible ?
--		on_update (function) -- a callback you can fill in that will be called every update frame.
-- 		on_hide (function) -- the callback that will be called on hiding the gui
--		on_click (function) -- this callback will be called when clicking on any clickable button in the gui
-- 					onClick extra argument: (widget)  , contains: (id, func(getText)(setText)(getPosition)(setVisible), visible)
--						> rarely has any use.




-->>>>>>>>>> all BASIC ITEMS: 

-- sm.globalgui.button, sm.globalgui.buttonSmall, sm.globalgui.label, sm.globalgui.labelSmall, sm.globalgui.textBox, sm.globalgui.invisibleBox
--
-- sm.globalgui.button(posX, posY, width, height, value, onclick_callback, play_sound, border)
--  	 creates a new item, you can add these items to the guiBuilder instance or to a 'special item'
--  		Arguments: 
--					* posX (number) - the x position on the screen, add bgposx if you want relative from the background
--  	            * posY (number) - the y position on the screen
--  	            * widht (number) - width
--  	            * height (number) - height
--  	            * value (string) - the item text value
--  	            * onclick_callback (nil/function) - the function to be called when clicking on the item, not nil > onClick userdata works
--  	            * play_sound (nil/string) - the sound to play when clicking on the item, not nil > onClick userdata works
--  			    * border (nil/boolean) - show a border around the item, default true
--  	
--  	Item.setVisible(self, visible) 
--  	Item.setText(self, text) -- text (string)
--  	Item.getText(self) -- returns text (string)
--  	Item.onClick(self, widget) -- this function gets called when the item is clicked upon. by default it will play the sound and the function defined in the constructor above
--  
--  *UserData*
--		on_click (nil/function) when clicking on the button this callback will be called
--		visible (boolean) will be true/false 
--		lastclick (number) 
-- 		 
--  NOTE: textBox has no border option, never has a border
--  NOTE: textBox does not have a working getText() function yet, blame the devs for this.
--  NOTE: invisibleBox has no value or border, usage: invisibleBox(posX, posY, width, height, onclick_callback = nil , play_sound = nil)



-->>>>>>>>>>>> SPECIAL ITEMS:

-- sm.globalgui.collection(items)
--   creates a collection of items inside this item, can be used for the tabControll subitems or to nest stuff
--  Arguments: * items (table) - a list of items
--   
--   collection.addItem(self, newitem) -- add new item to the collection, it'll be referencable by default using collection.items[1] , '1' incrementing up with every item added.
--   collection.addItemWithId(self, itemid, newitem) -- add item with custom id, easy to reference (collection.items.your_item_id:setText("lolol") )
--   collection.setVisible(self, visible) -- this function does this function to all items in the collection
--
-- *UserData* collection: items (table) 



-- sm.globalgui.tabControl(headers, items)
--    creates a new tabcontrol , clicking the headers will show the appropriate item
--   Arguments: * headers (table) - a table of items that will act as headers when clicking on them (use items for these , line them up next to each other or sth)
--              * items (table) - a table of items  (header with index 1 will show the item with index 1) (item 1 can be an item of the type 'collection')
--   
--   tabControl.addItem(self, header, item) -- add new tab with header and item in it
--   tabControl.addItemWithId(self, itemid, header, item) -- add new tab with header and item in it, with custom id's
--   tabControl.setVisible(self, visible) -- visible (boolean)
-- 
-- *UserData* tabControll:
-- 		headers (table) - a list of items that acts as header to the subitems
-- 		items (table) - a list of items , each item belongs to 1 header (an item can be a collection of items, check *collection*)
-- 		visible (boolean)



-- sm.globalgui.optionMenu(posX, posY, width, height)
--   creates a new optionsMenu (arrowbuttons and stuff) , better performance than adding several buttonSmall
--  Arguments: * posX (number) - the x position of the options menu on screen (add bgPosX to line up inside the background)
--			   * posY (number) - the y position of the options menu on screen (add bgPosY to line up inside the background)
--			   * width (number) - width
--			   * height (number) - height
--
-- optionMenu.addItem(self, posX, posY, width, height)
--   adds a new optionitem inside the optionmenu with this pos and size, relative to the optionmenu
--	  Returns: that item (optionItem)
--
-- optionMenu.addItemWithId(self, itemid, posX, posY, width, height)
--   adds a new optionitem with the custom id inside the optionmenu with this pos and size, relative to the optionmenu
--	  Returns: that item (optionItem)
--
-- optionMenu.setVisible(self, visible) -- set visibility
--	
-- *UserData* optionMenu: items (table) contains all the (option)items

-- optionItem    --(created by optionMenu, referencable: optionMenu.items[n] or by saving the return value of optionMenu.addItem)
--  NOTE: NOT MANUALLY INSTANTIATABLE, MUST BE CREATED BY optionMenu
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
-- NOTE: for setText() and getText(), reference the widget: optionMenu.items[1].label.widget:setText("lolol")


if not debugmode then debugmode = function() return false end end
if not debug then debug = function(...) end end

if sm.globalguiVersion and (sm.globalguiVersion <= 2.0) and not debugmode() then return end
sm.globalguiVersion = 2.0

--  == GLOBALGUI ==
sm.globalgui = {}
sm.globalgui.scaleX = 1
sm.globalgui.scaleY = 1

function sm.globalgui.wasCreated(self, gui)
	-- only the remote shape can initialize a global gui:
	if (self.shape.worldPosition - sm.vec3.new(0,0,2000)):length()>100 then
		debug("not remote shape")
		return true-- too far from remoteguiposition, this block cannot initialize gui
	elseif (gui and gui.instantiated) then -- kill duplicate remote gui blocks
		debug("duped remote ") 
		function self.server_onFixedUpdate(self, dt) self.shape:destroyShape(0) debug("destroyed dupe", self.shape.id) self.server_onFixedUpdate = nil end 
		return true
	end
	return false
end

function sm.globalgui.createRemote(scriptclass, self)
    if not scriptclass.createdgui and (self.shape.worldPosition - sm.vec3.new(0,0,2000)):length()>100 then
		scriptclass.createdgui = true 
		local uuid = self.shape:getShapeUuid() 
		sm.shape.createPart( uuid, sm.vec3.new(0,0,2000), sm.quat.identity(), false, true )
	end
end

function sm.globalgui.create(parentClass, title, width, height, on_hide, on_update, on_show, protectionlayers, autoscale)  -- create new GLOBALGUI
	assert(type(parentClass) == "table", "parentClass: class expected! got: "..type(parentClass))
	assert(type(title) == "string" or title == nil, "globalgui.create:Title: string expected! got: "..type(title))
	assert(type(width) == "number" or width == nil, "globalgui.create:width: number expected! got: "..type(width))
	assert(type(height) == "number" or height == nil, "globalgui.create:height: number expected! got: "..type(height))
	assert(type(on_hide) == "function" or on_hide == nil, "globalgui.create:on_hide: function expected! got: "..type(on_hide))
	assert(type(protectionlayers) == "number" or protectionlayers == nil, "globalgui.create:protectionlayers: number expected! got: "..type(protectionlayers))
	
	local guiBuilder = {}
	
	guiBuilder.on_hide = on_hide or (function() end)
	guiBuilder.on_update = on_update
	guiBuilder.on_show = on_show
	--guiBuilder.on_click = () -- can be set by user
	guiBuilder.title = title or ""
	guiBuilder.width = width or 600
	guiBuilder.height = height or 300
	guiBuilder.protectionlayers = protectionlayers or 10
	guiBuilder.killedlayers = 0
	guiBuilder.visible = false
	guiBuilder.instantiated = true
	
	guiBuilder.items = {}
	guiBuilder.onClickRouteTable = {}
	
	-- setup: 
	local screenWidth, screenHeight = sm.gui.getScreenSize()
	if (autoscale ~= nil) or autoscale then -- 'native' res = 1080p
		sm.globalgui.scaleX = screenWidth/1920
		sm.globalgui.scaleY = screenHeight/1080
	end
	guiBuilder.width, guiBuilder.height = guiBuilder.width*sm.globalgui.scaleX, guiBuilder.height*sm.globalgui.scaleY
	guiBuilder.bgPosX = (screenWidth - guiBuilder.width)/2
	guiBuilder.bgPosY = (screenHeight - guiBuilder.height)/2
		
	do
		local layer = sm.gui.load("ChallengeMessage.layout", true) -- add 1 invisible layer to create better gui loading /unloading
		sm.gui.widget.destroy(layer:find("MainPanel"))
		layer:setPosition(guiBuilder.bgPosX, guiBuilder.bgPosY)
		layer:setSize(guiBuilder.width, guiBuilder.height)
		table.insert(guiBuilder.items, layer)
		guiBuilder.onClickRouteTable[layer.id] = #guiBuilder.items --1
	end
	do
        local layer = sm.gui.load("ChallengeMessage.layout", true) -- background
        layer:setPosition(guiBuilder.bgPosX, guiBuilder.bgPosY)
		layer:setSize(guiBuilder.width, guiBuilder.height)
		layer:bindOnClick("killview")
		
        local bgMainPanel = layer:find("MainPanel")
			sm.gui.widget.destroy(bgMainPanel:find("Next"))
			sm.gui.widget.destroy(bgMainPanel:find("Reset"))
        bgMainPanel:setSize(guiBuilder.width, guiBuilder.height)
        bgMainPanel:setPosition(0, 0)
		bgMainPanel:bindOnClick("killview")
		
        local title = bgMainPanel:find("Title")
        title:setPosition(0, 0)
        title:setSize(guiBuilder.width, 90)
        title:setText(guiBuilder.title)
		title:bindOnClick("killview")
		table.insert(guiBuilder.items, layer)
		guiBuilder.onClickRouteTable[bgMainPanel.id] = #guiBuilder.items --2
		guiBuilder.onClickRouteTable[title.id] = #guiBuilder.items --2
	end
	for i=1,guiBuilder.protectionlayers do
		local layer = sm.gui.load("ChallengeMessage.layout", true)
		layer:bindOnClick("killview")
		sm.gui.widget.destroy(layer:find("MainPanel"))
		layer:setPosition(guiBuilder.bgPosX, guiBuilder.bgPosY)
		layer:setSize(guiBuilder.width, guiBuilder.height)
		table.insert(guiBuilder.items, layer)
		guiBuilder.onClickRouteTable[layer.id] = #guiBuilder.items --i+1
	end
	
	-- idiot fix for autoscale, as long as it works i guess....
	guiBuilder.bgPosX, guiBuilder.bgPosY = guiBuilder.bgPosX/sm.globalgui.scaleX, guiBuilder.bgPosY/sm.globalgui.scaleY
	guiBuilder.width, guiBuilder.height = guiBuilder.width/sm.globalgui.scaleX, guiBuilder.height/sm.globalgui.scaleY
	
	
	
	function parentClass.client_onclick(self, widget)
		debug("gui click")
		local currentTick = sm.game.getCurrentTick();
		local itemids = guiBuilder.onClickRouteTable[widget.id]
		for _, id in pairs(itemids) do
			if guiBuilder.on_click then guiBuilder.on_click(widget) end
			if guiBuilder.items[id].onClick then guiBuilder.items[id]:onClick(widget.id, currentTick) end
		end
		--Copyright (c) 2019 Brent Batch--
	end
	function parentClass.killview(self, widget) -- only bg items
		debug("gui killview")
		local itemid = guiBuilder.onClickRouteTable[widget.id]
		guiBuilder.items[itemid]:setVisible(false)
		guiBuilder.items[itemid] = nil
		guiBuilder.killedlayers = guiBuilder.killedlayers + 1
		if guiBuilder.protectionlayers - guiBuilder.killedlayers < 11 then
			if itemid == 3 then -- background broke
				print('killed gui completely')
				sm.gui.displayAlertText("GREAT, you killed the GUI.... bad boy!", 2)
				guiBuilder:setVisible(false, true)
				parentClass.client_onUpdate = nil
				guiBuilder.instantiated = false
				self.network:sendToServer("server_refreshgui")
			else
				sm.gui.displayAlertText("WARNING: Spamming the background will break the gui!", 2)
			end
		end
	end
	function parentClass.server_refreshgui(self)
		debug("refreshgui")
		sm.shape.destroyShape( self.shape, 0 )
		sm.shape.createPart( self.shape:getShapeUuid(), sm.vec3.new(0,0,2000), sm.quat.identity(), false, true ) 
	end
	
	function parentClass.client_onUpdate(self, dt)
		guiBuilder:update(dt)
		if guiBuilder.on_update then guiBuilder:on_update(dt) end
	end
	function parentClass.client_onRefresh(self)
		debug("gui onrefresh")
		parentClass.client_onUpdate = nil
		if guiBuilder.visible then sm.gui.displayAlertText("gui reloaded, press 'e' again for interacts to work",6) end
		guiBuilder:setVisible(false, true)
		guiBuilder.instantiated = false
	end
	function parentClass.server_onRefresh(self)
		self:server_refreshgui()
	end
	function parentClass.server_onFixedUpdate(self, dt) end
	
	local killedNowUselessFunctions = false
	function guiBuilder.show(self) 
		self:setVisible(true) 
		if self.on_show then self.on_show() end 
		if not killedNowUselessFunctions then 
			killedNowUselessFunctions = true
			print("gui cleaned up!")
			for k, item in pairs(self.items) do 
				if item.killNowUselessFunctions then item:killNowUselessFunctions() end 
			end 
		end 
	end
	function guiBuilder.hide(self) self:setVisible(false) end
    function guiBuilder.setVisible(self, visible, nomessage)
		assert(type(visible) == "boolean", "setVisible:visible: boolean expected! got: "..type(visible))
		self.visible = visible
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
		if self.items[1].visible ~= self.items[2].visible then
			self:setVisible(self.items[1].visible, true)
		end
    end

	function guiBuilder.addItem(self, item)
		assert(type(item) == "table", "addItem: table expected! got: "..type(item))
		assert(item.getClickRoutes ~= nil, "addItem: item expected! Not an item!")
		for k, widgetid in pairs(item.getClickRoutes and item:getClickRoutes() or {}) do
			AddToOnClickRouteTable(self.onClickRouteTable, widgetid, item.id)
		end
		self.items[item.id] = item -- add item.clickRoutes to self.onClickRouteTable:
	end
	
	function guiBuilder.addItemWithId(self, id, item) -- easy access to items in global gui by custom id
		assert(type(id) == "string" or type(id) == "number", "addItemWithId: number or string expected! got: "..type(id))
		assert(type(item) == "table", "addItemWithId: table expected! got: "..type(item))
		assert(item.getClickRoutes ~= nil, "addItemWithId: item expected! Not an item!")
		-- add item.clickRoutes to self.onClickRouteTable:
		for k, widgetid in pairs(item.getClickRoutes and item:getClickRoutes() or {}) do
			AddToOnClickRouteTable(self.onClickRouteTable, widgetid, id)
		end
		self.items[id] = item
	end
	return guiBuilder
end

function AddToOnClickRouteTable(clickRouteTable, widgetId, itemId)
	if clickRouteTable[widgetId] then
		table.insert(clickRouteTable[widgetId], itemId)
	else
		clickRouteTable[widgetId] = {itemId}
	end
end

function sm.globalgui.button( posX, posY, width, height, value, onclick_callback, on_show, play_sound, border )
	assert(type(posX) == "number", "button: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "button: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "button: width, number expected! got: "..type(width))
	assert(type(height) == "number", "button: height, number expected! got: "..type(height))
	assert(type(value) == "string", "button: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "button: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "button: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "button: border, boolean or nil expected! got: "..type(border))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.on_show = on_show
	item.on_click = onclick_callback
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
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
	end
	function item.getClickRoutes(self)
		return {self.widget.id}
	end
	item.lastclick = 0
	function item.onClick(self, widgetid, currentTick)
		if self.lastclick == currentTick then return end self.lastclick = currentTick -- protection
		
		if play_sound then sm.audio.play(play_sound) end
		if self.on_click then self.on_click() end
	end
	item.widget:bindOnClick("client_onclick")
	
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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





function sm.globalgui.buttonSmall(posX, posY, width, height, value, onclick_callback, on_show, play_sound, border )
	assert(type(posX) == "number", "buttonSmall: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "buttonSmall: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "buttonSmall: width, number expected! got: "..type(width))
	assert(type(height) == "number", "buttonSmall: height, number expected! got: "..type(height))
	assert(type(value) == "string", "buttonSmall: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "buttonSmall: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "buttonSmall: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "buttonSmall: border, boolean or nil expected! got: "..type(border))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.on_show = on_show
	item.on_click = onclick_callback
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
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
	end
	function item.getClickRoutes(self)
		return {self.widget.id}
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		if play_sound then sm.audio.play(play_sound) end
		if self.on_click then self.on_click() end
	end
	item.widget:bindOnClick("client_onclick")
		
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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


function sm.globalgui.label(posX, posY, width, height, value, onclick_callback, on_show, play_sound, border )	
	assert(type(posX) == "number", "label: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "label: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "label: width, number expected! got: "..type(width))
	assert(type(height) == "number", "label: height, number expected! got: "..type(height))
	assert(type(value) == "string", "label: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "label: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "label: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "label: border, boolean or nil expected! got: "..type(border))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	--Copyright (c) 2019 Brent Batch--
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.on_show = on_show
	item.on_click = onclick_callback
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
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
	end
	function item.getClickRoutes(self)
		return {self.widget.id}
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		if play_sound then sm.audio.play(play_sound) end
		if self.on_click then self.on_click() end
	end
	item.widget:bindOnClick("client_onclick")
		
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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

function sm.globalgui.labelSmall( posX, posY, width, height, value, onclick_callback, on_show, play_sound, border )
	assert(type(posX) == "number", "labelSmall: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "labelSmall: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "labelSmall: width, number expected! got: "..type(width))
	assert(type(height) == "number", "labelSmall: height, number expected! got: "..type(height))
	assert(type(value) == "string", "labelSmall: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "labelSmall: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "labelSmall: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "labelSmall: border, boolean or nil expected! got: "..type(border))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.on_show = on_show
	item.on_click = onclick_callback
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
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
	end
	function item.getClickRoutes(self)
		return {self.widget.id}
	end 
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		if play_sound then sm.audio.play(play_sound) end
		if self.on_click then self.on_click() end
	end
	item.widget:bindOnClick("client_onclick")
	
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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

function sm.globalgui.textBox( posX, posY, width, height, value, onclick_callback, on_show, play_sound ) -- no border here
	assert(type(posX) == "number", "textBox: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "textBox: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "textBox: width, number expected! got: "..type(width))
	assert(type(height) == "number", "textBox: height, number expected! got: "..type(height))
	assert(type(value) == "string", "textBox: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "textBox: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "textBox: play_sound, string or nil expected! got: "..type(play_sound))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local item = {}
	item.visible = true
	item.on_show = on_show
	item.on_click = onclick_callback
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
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
	end
	function item.getClickRoutes(self)
		return {self.widget.id}
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		if play_sound then sm.audio.play(play_sound) end
		if self.on_click then self.on_click() end
	end
	item.widget:bindOnClick("client_onclick")
	
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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


function sm.globalgui.invisibleBox( posX, posY, width, height, onclick_callback, on_show, play_sound ) -- no border, also no value
	assert(type(posX) == "number", "invisibleBox: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "invisibleBox: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "invisibleBox: width, number expected! got: "..type(width))
	assert(type(height) == "number", "invisibleBox: height, number expected! got: "..type(height))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "invisibleBox: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "invisibleBox: play_sound, string or nil expected! got: "..type(play_sound))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local item = {}
	item.visible = true
	item.on_show = on_show
	item.on_click = onclick_callback
	item.widget = sm.gui.load("ParticlePreview.layout", true)

	sm.gui.widget.destroy(item.widget:find("Background"))
	item.widget:setPosition(posX , posY )
	item.widget:setSize(width, height)
	
	item.id = item.widget.id
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
	end
	function item.getClickRoutes(self)
		return {self.widget.id}
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		if play_sound then sm.audio.play(play_sound) end
		if self.on_click then self.on_click() end
	end
	item.widget:bindOnClick("client_onclick")
	
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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


function sm.globalgui.tabControl(headers, items)
	assert(type(headers) == "table", "tabControl: headers, table expected! got: "..type(headers))
	assert(type(items) == "table", "tabControl: items, table expected! got: "..type(items))
	for k, v in pairs(headers) do assert(type(v) == "table", "tabControl: header, table expected! got: "..type(v)) end
	for k, v in pairs(items) do assert(type(v) == "table", "tabControl: item, table expected! got: "..type(v)) end
	for k, v in pairs(headers) do assert(v.getClickRoutes ~= nil, "tabControl: header, item expected! Not an item!") end
	for k, v in pairs(items) do assert(v.getClickRoutes ~= nil, "tabControl: item, item expected! Not an item!") end
	
	local item = {}
	item.id = headers and headers[1] and headers[1].id or nil
	item.headers = headers -- { [1] = item, [2] = item, ... }
	item.items = items -- { [1] = collection/item, [2] = collection/item, ... } NOW ALSO WITH CUSTOM IDS thanks to addItemWithId
	item.visible = true
	item.onClickRouteTable = {} 
	item.currenttab = 1
	for k, v in pairs(item.headers) do
		v.ItemType = "header"
	end
	
	function item.addItem(self, newheader, newitem)
		newheader.ItemType = "header"
		table.insert(item.headers, newheader)
		table.insert(item.items, newitem)
		self.id = self.id or newheader.id
	end
	function item.addItemWithId(self, headerid, newheader, newitem)
		newheader.ItemType = "header"
		item.headers[headerid] = newheader
		item.items[headerid] = newitem
		self.id = self.id or newheader.id
	end
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
		self.addItem = nil
		self.addItemWithId = nil
		for _, items in pairs({self.items, self.headers}) do
			for k, item in pairs(items) do 
				if item.killNowUselessFunctions then item:killNowUselessFunctions() end 
			end
		end
	end
	function item.getClickRoutes(self)
		local widgetids = {}
		for contenttype , items in pairs({header = self.headers, item = self.items}) do -- loop over ALL items
			for itemid, someitem in pairs(items) do
				if contenttype == "header" and not someitem.onClick then someitem.widget:bindOnClick("client_onclick") end -- stupid lil extra
				
				for _, widgetid in pairs(someitem:getClickRoutes()) do
					AddToOnClickRouteTable(self.onClickRouteTable, widgetid, {itemid = itemid, contenttype = contenttype})
					table.insert(widgetids, widgetid)
				end
				someitem:setVisible(false)
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		local itemdatas = self.onClickRouteTable[widgetid]
		for _, itemdata in pairs(itemdatas) do 
			if itemdata.contenttype == "header" then
				--sm.audio.play("GUI Inventory highlight") -- make this customizable ?
				if self.headers[itemdata.itemid].onClick then self.headers[itemdata.itemid]:onClick(widgetid, currentTick) end
				self.currenttab = itemdata.itemid
				self:setVisibleTab(true)
			else
				if self.items[itemdata.itemid].onClick then self.items[itemdata.itemid]:onClick(widgetid, currentTick) end
			end
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


function sm.globalgui.collection(items)
	assert(type(items) == "table", "collection: items, table expected! got: "..type(items))
	for k, v in pairs(items) do assert(type(v) == "table", "collection: items, table expected! got: "..type(v)) end
	for k, v in pairs(items) do assert(v.getClickRoutes ~= nil, "collection: item, item expected! Not an item!") end
	
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
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
		self.addItem = nil
		self.addItemWithId = nil
		for k, item in pairs(self.items) do 
			if item.killNowUselessFunctions then item:killNowUselessFunctions() end 
		end
	end
	function item.getClickRoutes(self)
		local widgetids = {}
		for itemid, subitem in pairs(self.items) do
			for _, widgetid in pairs(subitem:getClickRoutes()) do
				AddToOnClickRouteTable(self.onClickRouteTable, widgetid, itemid)
				table.insert(widgetids, widgetid)
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		local itemids = self.onClickRouteTable[widgetid]
		for _, itemid in pairs(itemids) do
			if self.items[itemid].onClick then self.items[itemid]:onClick(widgetid, currentTick) end
			if self.items[itemid].playSound then self.items[itemid]:playSound() end
		end
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

function sm.globalgui.optionMenu(posX, posY, width, height, on_show)
	assert(type(posX) == "number", "optionMenu: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "optionMenu: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "optionMenu: width, number expected! got: "..type(width))
	assert(type(height) == "number", "optionMenu: height, number expected! got: "..type(height))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local item = {}
	item.visible = true
	item.on_show = on_show
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
		assert(type(posX) == "number", "optionMenu.addItem: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenu.addItem: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenu.addItem: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenu.addItem: height, number expected! got: "..type(height))
		
		posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
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
		assert(type(posX) == "number", "optionMenu.addItemWithId: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenu.addItemWithId: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenu.addItemWithId: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenu.addItemWithId: height, number expected! got: "..type(height))
		
		posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
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
	
	
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil
		self.addItem = nil
		self.addItemWithId = nil
		for k, item in pairs(self.items) do 
			if item.killNowUselessFunctions then item:killNowUselessFunctions() end 
		end
	end
	function item.getClickRoutes(self)
		local widgetids = {}
		for itemid, optionItem in pairs(self.items) do
			for _, widgetid in pairs(optionItem:getClickRoutes()) do
				self.onClickRouteTable[widgetid] = itemid
				table.insert(widgetids, widgetid)
			end
		end
		return widgetids
	end
	function item.onClick(self, widgetid, currentTick)
		if item.lastclick == currentTick then return end item.lastclick = currentTick -- protection
		
		local itemid = self.onClickRouteTable[widgetid]
		self.items[itemid]:onClick(widgetid, currentTick)
	end
	function item.setVisible(self, visible)
		if visible and self.on_show then self.on_show() end
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
		assert(type(posX) == "number", "optionMenu.item.addLabel: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenu.item.addLabel: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenu.item.addLabel: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenu.item.addLabel: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenu.item.addLabel: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenu.item.addLabel: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		
		posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
		local widget = self.gui:find("Label")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name)
		widget.visible = true
		widget:bindOnClick("client_onclick")
		self.label = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.addDecreaseButton(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenu.item.addDecreaseButton: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenu.item.addDecreaseButton: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenu.item.addDecreaseButton: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenu.item.addDecreaseButton: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenu.item.addDecreaseButton: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenu.item.addDecreaseButton: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		
		posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
		local widget = self.gui:find("Decrease")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name) -- can't really set text but whatever
		widget.visible = true
		widget:bindOnClick("client_onclick")
		self.decreaseButton = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.addValueBox(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenu.item.addValueBox: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenu.item.addValueBox: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenu.item.addValueBox: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenu.item.addValueBox: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenu.item.addValueBox: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenu.item.addValueBox: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		
		posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
		local widget = self.gui:find("Value")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name)
		widget.visible = true
		widget:bindOnClick("client_onclick")
		self.valueBox = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.addIncreaseButton(self, posX, posY, width, height, name, onclick_callback)
		assert(type(posX) == "number", "optionMenu.item.addIncreaseButton: posX, number expected! got: "..type(posX))
		assert(type(posY) == "number", "optionMenu.item.addIncreaseButton: posY, number expected! got: "..type(posY))
		assert(type(width) == "number", "optionMenu.item.addIncreaseButton: width, number expected! got: "..type(width))
		assert(type(height) == "number", "optionMenu.item.addIncreaseButton: height, number expected! got: "..type(height))
		assert(type(name) == "string", "optionMenu.item.addIncreaseButton: name, string expected! got: "..type(name))
		assert(type(onclick_callback) == "function" or onclick_callback == nil, "optionMenu.item.addIncreaseButton: onclick_callback, function or nil expected! got: "..type(onclick_callback))
		
		posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
		local widget = self.gui:find("Increase")
		widget:setPosition(posX, posY)
		widget:setSize(width, height)
		widget:setText(name)
		widget.visible = true
		widget:bindOnClick("client_onclick")
		self.increaseButton = {
			widget = widget,
			onClick = onclick_callback
		}
		return widget
	end
	function item.killNowUselessFunctions(self)
		self.killNowUselessFunctions = nil
		self.getClickRoutes = nil -- destroy now useless functions, only called once added to guibuilder
		self.addLabel = nil
		self.addDecreaseButton = nil
		self.addIncreaseButton = nil
		self.addValueBox = nil
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

print("GUI library", sm.globalguiVersion, "successfully loaded.")