--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading AsciiBlock.lua")


-- AsciiBlock.lua --
AsciiBlock = class( nil )
AsciiBlock.maxParentCount = -1
AsciiBlock.maxChildCount = -1
AsciiBlock.connectionInput =  sm.interactable.connectionType.power + sm.interactable.connectionType.logic
AsciiBlock.connectionOutput = sm.interactable.connectionType.power
AsciiBlock.colorNormal = sm.color.new( 0xD8D220ff )
AsciiBlock.colorHighlight = sm.color.new( 0xF2EC3Cff )
AsciiBlock.poseWeightCount = 1


AsciiBlock.power = -1
AsciiBlock.buttonwasactive = false
AsciiBlock.bin = {
	["375000ff"] = bit.lshift(1,15),
	["064023ff"] = bit.lshift(1,14),
	["0a4444ff"] = bit.lshift(1,13),
	["0a1d5aff"] = bit.lshift(1,12),
	["35086cff"] = bit.lshift(1,11),
	["520653ff"] = bit.lshift(1,10),
	["560202ff"] = bit.lshift(1,9),
	["472800ff"] = bit.lshift(1,8),
	
	["a0ea00ff"] = 128,
	["19e753ff"] = 64,
	["2ce6e6ff"] = 32,
	["0a3ee2ff"] = 16,
	["7514edff"] = 8,
	["cf11d2ff"] = 4,
	["d02525ff"] = 2,
	["df7f00ff"] = 1,
	["df7f01ff"] = 1, -- orange 2, hecking devs changing vanilla colors ..... smh
}
AsciiBlock.icons = {
	{uv =001, name = "0"},
	{uv =002, name = "1"},
	{uv =003, name = "2"},
	{uv =004, name = "3"},
	{uv =005, name = "4"},
	{uv =006, name = "5"},
	{uv =007, name = "6"},
	{uv =008, name = "7"},
	{uv =009, name = "8"},
	{uv =010, name = "9"},
	{uv =011, name = "a"},
	{uv =012, name = "b"},
	{uv =013, name = "c"},
	{uv =014, name = "d"},
	{uv =015, name = "e"},
	{uv =016, name = "f"},
	{uv =017, name = "g"},
	{uv =018, name = "h"},
	{uv =019, name = "i"},
	{uv =020, name = "j"},
	{uv =021, name = "k"},
	{uv =022, name = "l"},
	{uv =023, name = "m"},
	{uv =024, name = "n"},
	{uv =025, name = "o"},
	{uv =026, name = "p"},
	{uv =027, name = "q"},
	{uv =028, name = "r"},
	{uv =029, name = "s"},
	{uv =030, name = "t"},
	{uv =031, name = "u"},
	{uv =032, name = "v"},
	{uv =033, name = "w"},
	{uv =034, name = "x"},
	{uv =035, name = "y"},
	{uv =036, name = "z"},
	{uv =037, name = "."},
	{uv =038, name = ","},
	{uv =039, name = "?"},
	{uv =040, name = "!"},
	{uv =041, name = "&"},
	{uv =042, name = "@"},
	{uv =043, name = "#"},
	{uv =044, name = "$"},
	{uv =045, name = "%"},
	{uv =046, name = "^"},
	{uv =047, name = "*"},
	{uv =048, name = "_"},
	{uv =049, name = "-"},
	{uv =050, name = "+"},
	{uv =051, name = "="},
	{uv =052, name = "/"},
	{uv =053, name = "<"},
	{uv =054, name = ">"},
	{uv =055, name = ":"},
	{uv =056, name = ";"},
	{uv =057, name = "'"},
	{uv =058, name = "\""},
	{uv =059, name = "["},
	{uv =060, name = "]"},
	{uv =061, name = "{"},
	{uv =062, name = "}"},
	{uv =063, name = "\\"},
	{uv =064, name = "|"},
	{uv =065, name = "`"},
	{uv =066, name = "~"},
	{uv =067, name = "("},
	{uv =068, name = ")"},
	{uv =069, name = "→"},
	{uv =070, name = "←"},
	{uv =071, name = "↑"},
	{uv =072, name = "↓"},
	{uv =073, name = "↔"},
	{uv =074, name = "↨"},
	{uv =075, name = "checked"},
	{uv =076, name = "crossed"},
	{uv =077, name = "unmarked box"},
	{uv =078, name = "checked box"},
	{uv =079, name = "crossed box"},
	{uv =080, name = "timer"},
	{uv =081, name = "clock"},
	{uv =082, name = "money symbol"},
	{uv =083, name = "money 'c'"},
	{uv =084, name = "money pound"},
	{uv =085, name = "money €"},
	{uv =086, name = "money Yen"},
	{uv =087, name = "money bitcoin"},
	{uv =088, name = "heart"},
	{uv =089, name = "angle"},
	{uv =090, name = "infinity"},
	{uv =091, name = "root"},
	{uv =092, name = "Pi"},
	{uv =093, name = "settings gear"},
	{uv =094, name = "male"},
	{uv =095, name = "female"},
	{uv =096, name = "unfilled checkers single"},
	{uv =097, name = "unfilled checkers double"},
	{uv =098, name = "filled checkers single"},
	{uv =099, name = "filled checkers double"},
	{uv =100, name = "filled chess queen "},
	{uv =101, name = "filled chess king  "},
	{uv =102, name = "filled chess rook  "},
	{uv =103, name = "filled chess bishop"},
	{uv =104, name = "filled chess knight"},
	{uv =105, name = "filled chess pawn  "},
	{uv =106, name = "unfilled chess queen "},
	{uv =107, name = "unfilled chess king  "},
	{uv =108, name = "unfilled chess rook  "},
	{uv =109, name = "unfilled chess bishop"},
	{uv =110, name = "unfilled chess knight"},
	{uv =111, name = "unfilled chess pawn  "},
	{uv =112, name = "hand like"},
	{uv =113, name = "hand dislike"},
	{uv =114, name = "dice 1"},
	{uv =115, name = "dice 2"},
	{uv =116, name = "dice 3"},
	{uv =117, name = "dice 4"},
	{uv =118, name = "dice 5"},
	{uv =119, name = "dice 6"},
	{uv =120, name = "filled card spades  "},
	{uv =121, name = "filled card clubs   "},
	{uv =122, name = "filled card hearts  "},
	{uv =123, name = "filled card diamonds"},
	{uv =124, name = "unfilled card spades  "},
	{uv =125, name = "unfilled card clubs   "},
	{uv =126, name = "unfilled card hearts  "},
	{uv =127, name = "unfilled card diamonds"},
	{uv =128, name = "emoji :)"},
	{uv =129, name = "emoji :D"},
	{uv =130, name = "emoji :'D"},
	{uv =131, name = "emoji XD"},
	{uv =132, name = "emoji ;)"},
	{uv =133, name = "emoji :O"},
	{uv =134, name = "emoji :p"},
	{uv =135, name = "emoji eyes-hearts"},
	{uv =136, name = "emoji B)"},
	{uv =137, name = "emoji :("},
	{uv =138, name = "emoji crying"},
	{uv =139, name = "emoji screaming :o"},
	{uv =140, name = "emoji >:("},
	{uv =141, name = "emoji >:)"},
	{uv =142, name = "emoji shrug"},
	{uv =143, name = "emoji thinking"},
	{uv =144, name = "emoji (:"},
	{uv =145, name = "emoji man shrug"},
	{uv =146, name = "skull"},
	{uv =147, name = "high five"},
	{uv =148, name = "poop"},
	{uv =149, name = "sweat drops"},
	{uv =150, name = "wind"},
	{uv =151, name = "star"},
	{uv =152, name = "flame"},
	{uv =153, name = "hammer"},
	{uv =154, name = "tools"},
	{uv =155, name = "camera"},
	{uv =156, name = "battery dead"},
	{uv =157, name = "battery half"},
	{uv =158, name = "battery full"},
	{uv =159, name = "lamp"},
	{uv =160, name = "badly drawn potato"},
	{uv =161, name = "corn"},
	{uv =162, name = "badly drawn cucumber"},
	{uv =163, name = "eggplant"},
	{uv =164, name = "dinosaur skull?"},
	{uv =165, name = "peach"},
	{uv =166, name = "chicken legg"},
	{uv =167, name = "bird"},
	{uv =168, name = "low detail bird"},
	{uv =169, name = "flying bird"},
	{uv =170, name = "turkey bird"},
	{uv =171, name = "fish"},
	{uv =172, name = "coffee"},
	{uv =173, name = "drink with straw"},
	{uv =174, name = "wine glass"},
	{uv =175, name = "drink glass filled"},
	{uv =176, name = "fork and knife"},
	{uv =177, name = "cookie"},
	{uv =178, name = "the cake is a lie!"},
	{uv =179, name = "egg"},
	{uv =180, name = "egg hatching"},
	{uv =181, name = "rabbit"},
	{uv =182, name = "flower"},
	{uv =183, name = "kiss"},
	{uv =184, name = "clover 3"},
	{uv =185, name = "lucky clover 4"},
	{uv =186, name = "canada leaf"},
	{uv =187, name = "leaf"},
	{uv =188, name = "pumpkin carved"},
	{uv =189, name = "santa?"},
	{uv =190, name = "snowman"},
	{uv =191, name = "pine tree with star"},
	{uv =192, name = "pine tree"},
	{uv =193, name = "common tree"},
	{uv =194, name = "coconut tree on island"},
	{uv =195, name = "cloud"},
	{uv =196, name = "lightning"},
	{uv =197, name = "snowstar"},
	{uv =198, name = "thermometer"},
	{uv =199, name = "rainbow"},
	{uv =200, name = "cake"},
	{uv =201, name = "confetti"},
	{uv =202, name = "price cup"},
	{uv =203, name = "first place"},
	{uv =204, name = "second place"},
	{uv =205, name = "third place"},
	{uv =206, name = "finish flag"},
	{uv =207, name = "crown"},
	{uv =208, name = "motorcycle?"},
	{uv =209, name = "common car"},
	{uv =210, name = "jeep car"},
	{uv =211, name = "plane top view"},
	{uv =212, name = "stunt plane"},
	{uv =213, name = "helicopter"},
	{uv =214, name = "big boat"},
	{uv =215, name = "train locomotive"},
	{uv =216, name = "rocket"},
	{uv =217, name = "laser gun"},
	{uv =218, name = "alien face"},
	{uv =219, name = "spexxinvader"},
	{uv =220, name = "pacman ghost"},
	{uv =221, name = "pacman pacman open mouth"},
	{uv =222, name = "pacman pacman closed mouth"},
	{uv =223, name = "xbox controller"},
	{uv =224, name = "dices"},
	{uv =225, name = "money bag"},
	{uv =226, name = "gift"},
	{uv =227, name = "diamond"},
	{uv =228, name = "oil barrel"},
	{uv =229, name = "hourglass"},
	{uv =230, name = "looking glass"},
	{uv =231, name = "save icon"},
	{uv =232, name = "paint draw icon"},
	{uv =233, name = "measurement needles go round"},
	{uv =234, name = "variable switch"},
	{uv =235, name = "door"},
	{uv =236, name = "information icon"},
	{uv =237, name = "! with circle"},
	{uv =238, name = "! with triangle"},
	{uv =239, name = "toxic skull icon"},
	{uv =240, name = "dragon"},
	{uv =241, name = "robot head"},
	{uv =242, name = "axolot robots icon"},
	{uv =243, name = "axolotl"},
	{uv =244, name = "axolotl red"},
	{uv =245, name = "bearing"},
	{uv =246, name = "mod bearing"},
	{uv =247, name = "big square"},
	{uv =248, name = "medium square"},
	{uv =249, name = "small square"},
	{uv =250, name = "big circle"},
	{uv =251, name = "medium circle"},
	{uv =252, name = "small circle"},
	
	{uv =000, name = "{EMPTY SURFACE}"},
}
AsciiBlock.savemodes = {}
for k,v in pairs(AsciiBlock.icons) do
   AsciiBlock.savemodes[v.uv]=k
end


function AsciiBlock.server_onRefresh( self )
	sm.isDev = true
	self:server_onCreate()
end
function AsciiBlock.server_onCreate( self ) 
	local stored = self.storage:load()
	if stored then
		if type(stored) == "number" then
			print('loading old version data')
			self.power = AsciiBlock.savemodes[stored] or 0
			--for k, v in pairs(AsciiBlock001) do
			--	self[k] = v
			--end  -- remove janky old compatibility
		elseif type(stored) == "table" then
			local _storedVal = type(stored[1]) == "number" and stored[1] or 0
			self.power = (AsciiBlock.savemodes[_storedVal] - 1) or 0
			--version = stored[2]
		end
	else
		self.storage:save({0, 1}) --{value, version}
	end
	self.interactable:setPower(self.power%(#self.icons))
end
-- uv 1 is image 0
-- power 0 is uv 1
-- saved is uv

function AsciiBlock.server_changemode(self, crouch)
	self.power = (self.power + (crouch and -1 or 1))%(#self.icons)
	self.interactable:setPower(self.power)
	self.storage:save({self.icons[self.interactable.power + 1].uv, 1})
	self.network:sendToClients("client_playsound", "GUI Item released")
end
function AsciiBlock.client_onInteract(self, character, lookAt)
	if not lookAt or character:getLockingInteractable() then return end
	self.network:sendToServer("server_changemode", character:isCrouching())
end

local default_hypertext = "<p textShadow='false' bg='gui_keybinds_bg_orange' color='#66440C' spacing='9'>%s</p>"
function AsciiBlock.client_canInteract(self)
	local use_key   = sm.gui.getKeyBinding("Use")
	local crawl_key = sm.gui.getKeyBinding("Crawl")

	if mp_deprecated_game_version then
		sm.gui.setInteractionText("Press", use_key, "or", crawl_key.." + "..use_key, "to change")
	else
		local use_hyper = default_hypertext:format(use_key)
		local crawl_and_use_hyper = default_hypertext:format(crawl_key.." + "..use_key)

		sm.gui.setInteractionText("Press", use_hyper, "or", crawl_and_use_hyper, "to change")
	end

	return true
end
function AsciiBlock.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end

function AsciiBlock.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local buttonwasactive = false
	local buttoncycle = -1
	local buttonpower = 0
	local logicpower = 0
	
	for k, v in pairs(parents) do --reset power if there is any input that gives an absolute value
		if v:getType() ~= "button" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then self.power = 0 end
	end
	
	for k, v in pairs(parents) do
		local _sSteering = v:hasSteering()
		local _sUuid = tostring(v:getShape():getShapeUuid())
		local _pType = v:getType()
		if not _sSteering and _pType == "scripted" and _sUuid ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tick button]] then
			-- number input
			self.power = self.power + math.floor(v.power)
		elseif _pType == "button" or _sUuid == "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tick button]] then
			-- button input
			if not self.buttonwasactive then
				buttoncycle = buttoncycle * -1
				if v:isActive() then
					local _sColor = tostring(v:getShape():getColor())
					if _sColor == "eeeeeeff" then 
						buttonpower = buttonpower + 1
					elseif _sColor == "222222ff" then 
						buttonpower = buttonpower - 1
					else
						buttonpower = buttonpower + buttoncycle
					end
				end
			end
			buttonwasactive = v:isActive() or buttonwasactive
			
		else
			-- switch / logic input
			local bin = self.bin[tostring(sm.shape.getColor(v:getShape()))]
			if bin then
				self.power = self.power + (v:isActive() and bin or 0)
			end
			
		end
	end
	self.buttonwasactive = buttonwasactive
	self.power = (self.power + buttonpower)%(#self.icons)
	
	
	if self.power ~= self.interactable.power then
		self.interactable:setPower(self.power)
	end
	
	self.needssave = self.needssave or (self.power ~= self.interactable.power)
	
	if self.needssave and os.time()%5 == 0 and self.risingedge then
		self.storage:save({self.icons[self.interactable.power + 1].uv, 1})
		self.needssave = false
	end
	self.risingedge = os.time()%5 ~= 0

end

function AsciiBlock.client_onFixedUpdate(self, dt)
	self.interactable:setUvFrameIndex(self.icons[self.interactable.power + 1].uv)
end


