--[[ BrewAPI
An API made for use with CubeBrew.
This loads games in an instant from the API's
file without using any nasty shell.runs.
It also adds other useful functions.
So shell.run-free game loading.
That's very nice indeed.
]]--

function solitaire()
--The layout on each card (except aces, which vary from suit to suit)
--Numbered values are the front, named styles are backs
--Values: 2-10 as read, 1 == ace, 11 = jack, 12 = queen, 13 = king
local styles = {
	[0]  = { "|   "; "|   "; "|   "; "|___" };
	[2]  = { "2  ;"; "  ; "; "    "; "  ; " };
	[3]  = { "3  ;"; " ; ;"; "    "; "  ; " };
	[4]  = { "4  ;"; " ; ;"; "    "; " ; ;" };
	[5]  = { "5  ;"; " ; ;"; "  ; "; " ; ;" };
	[6]  = { "6  ;"; " ; ;"; " ; ;"; " ; ;" };
	[7]  = { "7  ;"; " ; ;"; " ;;;"; " ; ;" };
	[8]  = { "8  ;"; " ; ;"; " ;;;"; " ;;;" };
	[9]  = { "9  ;"; " ;;;"; " ;;;"; " ;;;" };
	[10] = { "10 ;"; " ;;;"; ";;;;"; " ;;;" };
	[11] = { "J  ;"; " (>|"; " ** "; "|<) " };
	[12] = { "Q  ;"; " (>|"; " -- "; "|<) " };
	[13] = { "K  ;"; " (>|"; " ## "; "|<) " };
	
	--Styles of the back of the card
	backs = {
		alligator = { ">##<"; ">##<"; ">##<"; ">##<" };
		rounded = { "/  \\"; " || "; " || "; "\\  /" };
		royal = { " oo "; "-/\\-"; "-\\/-"; " oo " };
		frame = { "/--\\"; "|  |"; "|  |"; "\\--/" };
		spooky = { "\\  /"; "-()-"; "-()-"; "/  \\" };
	};
	--The style regex. Replace this character with the suit.char
	--Don't use this as part of card styling (change if necessary)
	styleregex = ";";
	--Width and height of the cards
	width = 4; height = 4;
}
--The style the back of the card uses
local backStyle = styles.backs.rounded
--The colours the card back uses
local backbg = colours.blue
local backfg = colours.white

--The colour of the table
local tablebg = colours.green
--The colour of the face of the cards (should probably be white)
local facecol = colours.white
--The colour the face changes when a card is selected
local selcol = colours.yellow
--The colour of the outline of a 'space' where cards can be placed
local emptycol = colours.grey
--The X and Y offset of the screen. You can change this to allow
--more cards than would otherwise appear (use wisely)
local xoff, yoff = 0,0

--The suits a card can have and how they look
local suits = {
	spades = {
		colour = colours.black;
		char = "^";
		ace = { "A  ".."^"; " /\\ "; "(__)"; " /\\ " }
	};
	diamonds = {
		colour = colours.red;
		char = "*";
		ace = { "A  *"; " /\\ "; "<  >"; " \\/ " }
	};
	clubs = {
		colour = colours.black;
		char = "+";
		ace = { "A  +"; " () "; "()()"; " /\\ " }
	};
	hearts = {
		colour = colours.red;
		char = "v";
		ace = { "A  v"; "/\\/\\"; "\\  /"; " \\/ " }
	};
}

--Changes the numerical code of the card value to a printable string
local function valToDisplay(_val)
	if _val == 1 then return "A "
	elseif _val == 10 then return "10"
	elseif _val == 11 then return "J "
	elseif _val == 12 then return "Q "
	elseif _val == 13 then return "K "
	else return _val.." " end
end

--A singly linked list prototype for containing collections of cards
--Card games often layer cards on one another so this is a good way to
--keep track of them and make moving lots of cards around easier.
local linkedCardP = {
	--Head of the list
	head = nil,
	--Tail of the list
	tail = nil,
	
	display = function(self)
		if self.head then self.head:display() end
	end;
	
	reverse = function(self)
		if not self.head and self.head.tail then return end
		local _head = self.head
		local function recRev(_head)
			local _rest = _head.tail
			if _rest then
				recRev(_rest)
				_rest.tail = _head
			else
				self.head = _head
			end
		end
		recRev(_head)
		_head.tail = nil
	end;
}

--Constructs a 
function linkedCardP:new(o)
	o = o or { }
	setmetatable(o, self)
	self.__index = self
	return o
end;

--The card prototype
local cardP = {
	--The value on the face of the card (2-A)
	val = 0,
	--The suit of the card, from the suits table
	suit = suits.spades,
	--Whether or not the card is turned face-up
	visible = false,
	--Whether or not the card is selected
	selected = false,
	--The card directly on top of this card, if any
	tail = nil,
	--Whether or not the card runs a display call at all. This is used
	--when the cards would otherwise clutter the display area
	hidden = false,
	
	--Used for the coordinates of the card, as X-Y
	x = 0, y = 0,
	
	--Displays an outline of the card painted as the table
	--A method to decrease the number of necessary draw calls
	displayTable = function(self)
		for _y = self.y, self.y + styles.height do
			term.setBackgroundColour(tablebg)
			term.setCursorPos(self.x + xoff, _y + yoff)
			term.write(string.rep(" ", styles.width))
		end
	end;
	
	--Displays the face or back of a card, and its children if they
	--are not being overlapped
	display = function(self)
		if self.tail and not (self.tail.x == self.x 
				and self.tail.y == self.y) then 
			self.tail:display() 
		end
		
		if self.hidden then return end
		local _style = nil
		if self.val == 0 then
			_style = styles[self.val]
			term.setBackgroundColour(tablebg)
			term.setTextColour(emptycol)
		elseif not self.visible then 
			_style = backStyle
			term.setBackgroundColour(backbg)
			term.setTextColour(backfg)
		else
			if self.selected then
				term.setBackgroundColour(selcol)
			else
				term.setBackgroundColour(facecol)
			end
			term.setTextColour(self.suit.colour)
			if self.val == 1 then _style = self.suit.ace
			else _style = styles[self.val] end
		end
		for i = 1, #_style do
			term.setCursorPos(self.x + xoff, self.y + i - 1 + yoff)
			term.write(string.gsub(_style[i], ";", self.suit.char))
		end
	end;
	
	--Move this card (and all cards on top of it) to a new position
	--ChildMove will move all cards in the tail
	move = function(self, newx, newy, childMove)
		local _xdiff,_ydiff = newx - self.x, newy - self.y
		if childMove and self.tail then self.tail:move(
			self.tail.x + _xdiff, self.tail.y + _ydiff, true) end
		self.x = newx
		self.y = newy
	end;
	
	--Determine whether or not an xy point lies on the body of the card
	clicked = function(self, mousex, mousey)
		return mousex >= self.x + xoff and mousex < self.x + styles.width + xoff and
				mousey >= self.y + yoff and mousey < self.y + styles.height + yoff and not self.hidden
	end;
	
	--Determines whether or not two cards are overlapping
	overlapping = function(self, ocard)
		return self.x >= ocard.x - styles.width and
			self.x <= ocard.x + styles.width  and
			self.y >= ocard.y - styles.height and
			self.y <= ocard.y + styles.height  and not ocard.hidden and not self.hidden
	end;
	
	__tostring = function(self)
		return self.val.." of "..self.suit.char
	end
}

--Constructs a new card
function cardP:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end;

--The main deck, from which you should draw all cards
local deck = {}

--Creates a fresh deck of 52 cards in suit and number order
--Count is the number of decks you wish to include
local function createDeck(_count)
	deck = {}
	for i = 1, _count do
		for _,suitval in pairs(suits) do
			for _val = 1,13 do
				table.insert(deck, cardP:new({ 
					val = _val; 
					suit = suitval; 
				}))
			end
		end
	end
end

--Shuffles the deck. A close-to-optimal shuffle
local function shuffleDeck()
	for i=#deck,2,-1 do
		local _card = table.remove(deck, math.random(1, i))
		table.insert(deck, i, _card)
	end
end
	--[[ Overmenu Facilities
		 The glue that ties each of the games together
	]]--

--Screen Size
local w,h = term.getSize()
--The function to call to draw the entire game again as needed
local currOverDraw = nil
--Whether or not the user has just quit
local quit = false
--The next game to be played
local nextGame = nil

--The options displayed in the menu
local menuOptions = { name = "Games", x = 3, y = 1 }
--The title at the top of the screen
local title = "Card Games"

--Draws the menu bar. Should be the last thing in every overdraw call
local function displayOverMenuBar()
	term.setCursorPos(3,1)
	term.setBackgroundColour(colours.lightGrey)
	term.clearLine()
	term.setTextColour(colours.black)
	term.write("Games")
	term.setTextColour(colours.grey)
	term.setCursorPos(w/2 - #title/2, 1)
	term.write(title)
end

--[[Produces a nice dropdown menu based on a table of strings. Depending on the position, this will auto-adjust the position
        of the menu drawn, and allows nesting of menus and sub menus. Clicking anywhere outside the menu will cancel and return nothing
        Params: x:int = the x position the menu should be displayed at
                y:int = the y position the menu should be displayed at
                options:table = the list of options available to the user, as strings or submenus (tables of strings, with a name parameter)
        Returns:string the selected menu option.
]]--
local function displayDropDown(x, y, options, noTitle)
	inDropDown = true
	if noTitle then y = y - 1 end
	--Figures out the dimensions of our thing
	local longestX = #options.name
	for i=1,#options do
		local currVal = options[i]
		if type(currVal) == "table" then currVal = currVal.name end
		longestX = math.max(longestX, #currVal)
	end
	local xOffset = math.max(0, longestX - ((w-2) - x) + 1)
	local yOffset = math.max(0, #options - ((h-1) - y))
   
	local clickTimes = 0
	local tid = nil
	local selection = nil
	while clickTimes < 4 do
		if not noTitle then
			term.setCursorPos(x-xOffset,y-yOffset)
			term.setBackgroundColour(colours.blue)
			term.setTextColour(colours.white)
			term.write(options.name.." ")
		end

		for i=1,#options do
			term.setCursorPos(x-xOffset, y-yOffset+i)
			local currVal = options[i]
			if type(currVal.value) == "table" then
				currVal.enabled = #currVal.value > 0 
			end
			
			if i==selection and clickTimes % 2 == 0 then
				term.setBackgroundColour(colours.blue)
				if options[selection].enabled then term.setTextColour(colours.white)
				else term.setTextColour(colours.grey) end
			else
				term.setBackgroundColour(colours.lightGrey)
				local _tcol = colours.black
				if not currVal.enabled then _tcol = colours.grey end 
				term.setTextColour(_tcol)
			end
			if type(currVal.value) == "table" then
				term.write(currVal.name..string.rep(" ", longestX-#currVal.name))
				term.setBackgroundColour(colours.blue)
				term.setTextColour(colours.white)
				term.write(">")
			else
				term.write(currVal.name..string.rep(" ", longestX-#currVal.name + 1))
			end
			
			if (i~= selection or clickTimes %2 == 1) and currVal.key and currVal.enabled then
				term.setTextColour(colours.blue)
				term.setBackgroundColour(colours.lightGrey)
				local co = currVal.name:find(currVal.key) 
				if not co then co = longestX else co = co - 1 end
				term.setCursorPos(x-xOffset+co, y-yOffset + i)
				term.write(currVal.key)
			end
		end
	   
		local id, p1, p2, p3 = os.pullEvent()
		if id == "timer" then
			if p1 == tid then
				clickTimes = clickTimes + 1
				if clickTimes > 2 then
					break
				else
					tid = os.startTimer(0.1)
				end
			elseif p1 == bTimer then saveDocument(bPath) end
		elseif id == "key" and not tid then
			if p1 == keys.leftCtrl then
				selection = ""
				break
			elseif p1 == keys.down and (not selection or selection < #options) then
				selection = selection or 0
				_os = selection
				repeat selection = selection + 1
				until selection == #options + 1 or options[selection].enabled
				--if selection == #options + 1 then selection = _os end
			elseif p1 == keys.up and (not selection or selection > 1) then
				selection = selection or #options + 1
				_os = selection
				repeat selection = selection - 1
				until selection == 0 or options[selection].enabled
				if selection == 0 then selection = _os end
			elseif p1 == keys.enter and selection and options[selection].enabled then
				tid = os.startTimer(0.1)
				clickTimes = clickTimes - 1
			end
		elseif id == "mouse_click" and not tid then
			local _xp, _yp = x - xOffset, y - yOffset
			if p2 >= _xp and p2 <= _xp + longestX + 1 and 
			p3 >= _yp+1 and p3 <= _yp+#options then
				if options[p3 - _yp].enabled then
					selection = p3-(_yp)
					tid = os.startTimer(0.1)
				end
			else
				selection = ""
				break
			end
		elseif id == "char" and not tid then
			for k,v in ipairs(options) do
				if v.key and v.key:lower() == p1:lower() and options[k].enabled then
					selection = k
					tid = os.startTimer(0.1)
					break
				end
			end
		end
	end
	
	local _val = selection
	if type(selection) == "number" then
		selection = options[selection].value
	end
   
	if type(selection) == "string" then
		inDropDown = false
		return selection
	elseif type(selection) == "table" then
		return displayDropDown(x + longestX + 1, y + _val, selection, true)
	elseif type(selection) == "function" then
		local _rval = selection()
		if not _rval then return "" else return _rval end
	end
end

--Handles mouse events for the menu, returns true or false if something happens
local function manageMenuMouseEvents(_id, _x, _y)
	if _id == "mouse_click" and _y == menuOptions.y and _x >= menuOptions.x and 
			_x < menuOptions.x + #menuOptions.name then
		local _rval = displayDropDown(menuOptions.x, menuOptions.y, menuOptions)
		if currOverDraw then currOverDraw()
		else
			term.setBackgroundColour(tablebg)
			term.clear()
			displayOverMenuBar()
		end
	end
	return nextGame ~= nil or quit
end


	--[[ Game Variant: Klondike
		The classic game of solitare. Seven columns of cards, try to
		sort your deck by suit and number.
	]]--
	
--The selected card, and the pile it belongs to
local selCard, selDeck, selSpace = nil, nil, nil
--The space, waste and tableau decks
local spaces, waste, tableaus = {}, linkedCardP:new(), {}
--The deck's default position
local deckX,deckY = 0,0
--An empty card representing where the deck should be
local deckSpace = nil
--The last position of a mouse click not intercepting a card
local lmX,lmY = 0,0
--And a temporary offset value so we don't keep reapplying
local txoff, tyoff = 0,0
--The player's score at Klondike
local klondikeScore = 0

--Shows the score at the bottom of the screen
local function displayScore()
	term.setCursorPos(1,h)
	term.setBackgroundColour(tablebg)
	term.setTextColour(colours.black)
	term.write(" Score: "..klondikeScore)
end

--Draws every element in Klondike. There's not much redraw in this game
--so I haven't bothered to optimize too heavily.
local function drawKlondike()
	term.setBackgroundColour(tablebg)
	term.clear()

	for i=1,7 do
		if spaces[i] then spaces[i]:display() end
	end
	waste:display()
	for i=1,4 do
		if tableaus[i] then tableaus[i]:display() end
	end
	if deckSpace then deckSpace:display() end
	displayScore()
	displayOverMenuBar()
end

--Sets up a new game of Klondike, organizing the deck.
local function makeKlondikeSetup()
	createDeck(1)
	shuffleDeck()
	spaces = {}
	
	--Cleanup from last game
	if deckSpace then deckSpace.val = 1 end
	if waste then waste.head = nil end
	for i=1,4 do
		if tableaus[i] then tableaus[i].head = cardP:new({
			x = tableaus[i].head.x;
			y = tableaus[i].head.y;
			val = 0;
		})
		end
	end	
	for i=1,7 do spaces[i] = nil end
	
	--The main play area
	for i=1,7 do
		for j=i,7 do
			--Our (silly) little card animation :D
			drawKlondike()
			sleep(0.1)
			
			if i == 1 then spaces[j] = linkedCardP:new() end
			
			local _card = table.remove(deck, 1)
			_card.x = 1 + 1 * j + styles.width * (j - 1)
			_card.y = i + 2
			if spaces[j].head then _card.tail = spaces[j].head
			else spaces[j].tail = _card end
			spaces[j].head = _card
			if i == j then spaces[j].head.visible = true end
		end
	end
	
	--The waste pile and remaining deck
	deckX = spaces[#spaces].head.x + 2 + styles.width
	deckY = 2
	for i=1,#deck do
		deck[i].x = deckX
		deck[i].y = deckY
	end
	deckSpace = cardP:new({ x = deckX; y = deckY; val = 1})
	
	--The tableau piles
	for i=1,4 do
		local _ecard = cardP:new()
		_ecard.val = 0
		if i % 2 == 0 then _ecard.x = deckX
		else _ecard.x = deckX + styles.width + 2 end
		if i <= 2 then _ecard.y = deckY + styles.height * 2
		else _ecard.y = deckY + styles.height * 3 + 1 end
		tableaus[i] = linkedCardP:new()
		tableaus[i].head = _ecard
	end
end

--Determines whether or not the game is won
local function checkWinState()
	local _won = true
	for i=1,#tableaus do
		_won = tableaus[i].head and tableaus[i].head.val == 13
		if not _won then break end
	end
	return _won
end

--Selects a given card
local function select(_card, _deck, _space)
	if selCard then selCard.selected = false end
	selCard = _card
	selDeck = _deck
	selSpace = _space
	if selCard then selCard.selected = true end
end

--Determines how many points were scored (or lost) for making a specific move. Uses Windows Solitare conventions
local function evaluateScore(initDeck, finalDeck)
	if finalDeck == tableaus then
		klondikeScore = klondikeScore + 10
	elseif initDeck == waste then
		klondikeScore = klondikeScore + 5
	elseif initDeck == tableaus then
		klondikeScore = klondikeScore - 15
	end
	displayScore()
end

--Adds a card to the selected tableau. Returns true if the check was successful
local function addKlondikeTableau(_card, _deck)
	if selCard == selDeck.head and selCard.val == _card.val + 1 and 
			(_card.val == 0 or _card.suit == selCard.suit) then
		selDeck.head = selCard.tail
		if selSpace == spaces and selDeck.head == nil then
			selDeck.head = cardP:new( { x = selCard.x; y = selCard.y; val = 0; } )
		end
		selCard.x = _deck.head.x
		selCard.y = _deck.head.y
		if _deck.head.val == 0 then _deck.head = nil end
		selCard.tail = _deck.head
		_deck.head = selCard
		evaluateScore(_deck, tableaus)
	else
		return false
	end
	select()
	return true
end

--Moves one card and it's peers to be on top of another card in the play area. Implements
--rules associated with this kind of move
local function shiftKlondikeCard(_card, _deck)
	--Ensuring the move is legal. If it isn't we just select the new card
	local isLegal = (_card.suit.colour ~= selCard.suit.colour and _card.val == selCard.val + 1 and
			_card == _deck.head) or (_card.val == 0 and selCard.val == 13)
	if not isLegal then 
		local _cDeck = selDeck
		select(_card, _deck, spaces) 
		_cDeck:display()
		_deck:display()
		return 
	end
	
	--Moving a card from the waste pile into the play area
	if selSpace == waste then
		selCard:displayTable()
		selCard:move(_card.x, _card.y + 1)
		_deck.head = selCard
		selDeck.head = selCard.tail
		selDeck:display()
	--Moving a card from one part of the play field to the other
	elseif selSpace == spaces then
		local _top = selDeck.head
		_deck.head = _top
		local _ydiff = 1
		_top:displayTable()
		while _top ~= selCard do
			_top = _top.tail
			_ydiff = _ydiff + 1
			_top:displayTable()
		end
		selDeck.head = selCard.tail
		if selDeck.head == nil then
			selDeck.head = cardP:new({ val = 0, x = selCard.x, y = selCard.y })
		end
		selDeck:display()
		selCard.tail = nil
		_deck.head:move(_card.x, _card.y + _ydiff, true)
	--Moving a card from the tableau onto the play area
	elseif selSpace == tableaus then
		selDeck.head = selCard.tail
		if selDeck.head == nil then
			selDeck.head = cardP:new({ val = 0, x = selCard.x, y = selCard.y })
		end
		selDeck:display()
		selCard:move(_card.x, _card.y + 1)
		_deck.head = selCard
	end
	selCard.tail = _card
	evaluateScore(selSpace, spaces)
	
	if _card.val == 0 then
		selCard.tail = nil
		_deck.head:move(_deck.head.x, _deck.head.y - 1, true)
	end
	select()
	_deck:display()
end

--Completes the game for us, when all cards are revealed and in the play area
local function autoCompleteKlondike()
	local _lowestVal = nil
	repeat
		_lowestVal = math.huge
		for i = 1, #spaces do
			if spaces[i].head.val > 0 then
				_lowestVal = math.min(_lowestVal, spaces[i].head.val)
			end
		end
		for i = 1, #spaces do
			if spaces[i].head.val == _lowestVal then
				select(spaces[i].head, spaces[i], spaces)
				for j = 1, #tableaus do
					if addKlondikeTableau(tableaus[j].head, tableaus[j]) then break end
				end
			end
		end
		drawKlondike()
		sleep(0.2)
	until _lowestVal >= 13
end

--Handles all input for Klondike
local function handleKlondikeInput()
	gameOver, gameWon = false, false
	while not gameOver do
		local id,p1,p2,p3 = os.pullEvent()
		if manageMenuMouseEvents(id,p2,p3) then return end
	
		if id == "mouse_click" then
			local complete = false
			lmX, lmY = 0,0
			
			for i=1,#spaces do
				local _c = spaces[i].head
				while _c do
					--We've clicked a card in the main hand
					if _c:clicked(p2,p3) then
						--Performing a doubleclick
						if selCard == _c then 
							local _cDeck = selDeck
							select()
							_cDeck:display()
							complete = true
							break
						--Revealing a newly freed card
						elseif _c == spaces[i].head and _c.visible == false and _c.val > 0 then
							_c.visible = true
							local _cDeck = selDeck
							select()
							if _cDeck then _cDeck:display() end
							klondikeScore = klondikeScore + 5
							displayScore()
							_c:display()
							complete = true
							break
						--Selecing a card with no other selection
						elseif selCard == nil and _c.visible == true and _c.val > 0 then
							select(_c, spaces[i], spaces)
							spaces[i]:display()
							complete = true
							break
						--Attempting to move a previously selected card onto this one
						elseif selCard then
							shiftKlondikeCard(_c, spaces[i])
							drawKlondike()
							complete = true
							break
						end
					end
					_c = _c.tail
				end
				if complete then break end
			end
			
			for i=1,#tableaus do
				local _c = tableaus[i].head
				if _c:clicked(p2,p3) then
					--Attempting to add a card to the tableau
					if selCard and addKlondikeTableau(_c, tableaus[i]) then
						gameWon = checkWinState()
						gameOver = gameWon
						drawKlondike()
					--Selecting a card already on the tableau
					elseif _c.val > 0 then 
						local _cDeck = selDeck
						select(_c, tableaus[i], tableaus)
						tableaus[i]:display()
						if _cDeck then _cDeck:display() end
					end
					complete = true
					break
				end
			end
			
			if deckSpace:clicked(p2,p3) then
				if waste.head and waste.head.selected then select() end
				--Refreshing the deck
				if deckSpace.val == 0 then
					while waste.head do
						if not waste.head.hidden then waste.head:displayTable() end
						table.insert(deck, 1, waste.head)
						waste.head = deck[1].tail
						deck[1].visible = false
						deck[1].hidden = false
						deck[1].tail = nil
					end
					deckSpace.val = #deck
					deckSpace:display()
				--Dealing another 3 cards to the waste deck
				else
					local _h = waste.head
					while _h and not _h.hidden do
						_h.hidden = true
						_h:displayTable()
						_h = _h.tail
					end
					
					for i = 1, math.min(#deck, 3) do
						local _c = table.remove(deck,1)
						_c.tail = waste.head
						_c:move(deckSpace.x + styles.width + 2, deckSpace.y + i - 1)
						_c.visible = true
						waste.head = _c
						deckSpace.val = #deck
						--More animations!
						waste:display()
						displayOverMenuBar()
						sleep(0.1)
					end
					deckSpace:display()
				end
			end
			
			if waste.head and waste.head:clicked(p2,p3) then
				--Selecting a card in the waste deck
				if waste.head.selected then 
					select()
				else
					local _d = selDeck
					select(waste.head, waste, waste)
					if _d then _d:display() end
				end
				waste.head:display()
				complete = true
			end
			
			--Deselecting a card by clicking in empty space
			if selCard ~= nil and not complete then
				local _cDeck = selDeck 
				select()
				if _cDeck then _cDeck:display() end
			end 
			lmX, lmY = p2, p3
			txoff, tyoff = xoff, yoff
			displayOverMenuBar()
			
			--Determining if the player can autocomplete the game
			if complete and deckSpace.val == 0 and waste.head == nil and not checkWinState() then
				local _autoComplete = true
				
				for i=#spaces,1,-1 do
					local _h = spaces[i].head
					while _h do
						if _h.val > 0 then
							_autoComplete = _h.visible
							if not _autoComplete then break end
						end
						_h = _h.tail
					end
					if not _autoComplete then break end
				end
				
				if _autoComplete then 
					autoCompleteKlondike()
					gameWon = true
					gameOver = true
				end
			end
		elseif id == "mouse_drag" then
			if lmX > 0 and lmY > 0 then
				local yDiff = p3 - lmY
				--Mouse drag events seem to be pretty overzealous. Or is that a version issue...
				if tyoff + yDiff ~= yoff then
					yoff = math.min(tyoff + yDiff, 0)
					--h-21 is the maximum unrevealed column (6) plus the max revealed column (13)
					--plus 3 to reveal the face of the card and 4 more for whitespace
					yoff = math.max(yoff, h - 26)
					drawKlondike()
				end
			end
		elseif id == "mouse_scroll" then
			yoff = math.min(yoff - p1, 0)
			yoff = math.max(yoff, h - 26)
			drawKlondike()
		elseif id == "key" then
			if p1 == keys.down then
				yoff = math.min(yoff + 1, 0)
				drawKlondike()
			elseif p1 == keys.up then
				yoff = math.max(yoff - 1, h - 26)
				drawKlondike()
			end
		end
	end
	if gameWon then
		--One last silly win animation
		local _spread = {}
		for i=1,#tableaus do
			tableaus[i]:reverse()
			tableaus[i].head:move(w/4 + styles.width/2 + 13, 2 + styles.height * (i - 1), true)
			local _c = tableaus[i].head.tail
			_spread[i] = _c
			while _c do
				_c:move(_c.x - 2 + xoff, _c.y + yoff, true)
				_c.hidden = true
				_c = _c.tail
			end
		end
		
		while _spread[1] do
			drawKlondike()
			sleep(0.1)
			for i=1,#_spread do
				_spread[i].hidden = false
				_spread[i] = _spread[i].tail
			end
		end
		drawKlondike()
	end
end

--Runs a game of Klondike
local function playKlondike()
	backStyle = styles.backs.rounded
	backbg = colours.blue
	backfg = colours.white
	title = "Klondike Solitaire"
	xoff = 0
	yoff = 0

	makeKlondikeSetup()
	drawKlondike()
	handleKlondikeInput()
end

	--[[ Game Variant: Blackjack
		Play against a dealer, bet on your dealout and try to have a
		greater score than the dealer without going over 21
	]]--
	
--The player's funds
local bank = 200
--The table minimum and maximum
local tableMin, tableMax = 20, math.huge
--The current bet, the split bet and any insurance the player has bought
local currBet,splitBet,insurance = 0,0,0 
--The player's hand
local hand = linkedCardP:new()
local splitHand = nil
--The dealer's hand
local dealerHand = linkedCardP:new()
--The position of the betting squares
local _bx1, _bx2, _by = 14, w - 21, 10
--The empty 'deck' card, symbolizing the deck to click for a deal
local _bjDeck = cardP:new( { val = 1; visible = false; x = w - 8; y = 3; } )
--The footer message and colour
local _footermsg, _footercolor = "",colours.white

--Prepares a new game of blackjack
local function startBlackjack()
	createDeck(1)
	bank = 200
	hand = linkedCardP:new()
	dealerHand = linkedCardP:new()
	currBet = 0
	insurance = 0
	splitBet = 0
	_footermsg, _footercolor = "",colours.white
end

--Displays the bets and bank at the bottom of the screen
local function displayBlackjackBets()
	term.setCursorPos(1,h-1)
	term.setBackgroundColour(tablebg)
	term.setTextColour(colours.black)
	term.clearLine()
	term.write("  Bank: $"..bank)
	term.setCursorPos(20, h-1)
	term.setTextColour(_footercolor)
	term.write(_footermsg)
	
	term.setCursorPos(_bx1 + 1, _by + 1)
	term.write(string.rep(" ", 5))
	if currBet > 0 then
		term.setCursorPos(_bx1 + 1, _by + 1)
		term.write("$"..currBet.." ")
	end
	
	term.setCursorPos(_bx2 + 1, _by + 1)
	term.write(string.rep(" ", 5))
	if splitBet > 0 then
		term.setCursorPos(_bx2 + 1, _by + 1)
		term.write("$"..splitBet.." ")
	end
end

--Displays all elements in a game of blackjack
local function displayBlackjack()
	term.setBackgroundColour(tablebg)
	term.clear()
	--The table
	term.setTextColour(colours.orange)
	local _tableMsg = "Blackjack pays 3 to 2"
	term.setCursorPos(w/2-#_tableMsg/2, 8)
	term.write(_tableMsg)
	term.setTextColour(colours.white)
	_tableMsg = "Insurance pays 2 to 1"
	term.setCursorPos(w/2-#_tableMsg/2, 9)
	term.write(_tableMsg)
	
	term.setTextColour(colours.white)
	for i=1,3,2 do
		term.setCursorPos(_bx1 + 1, _by - 1 + i)
		term.write(string.rep("-", 5))
		term.setCursorPos(_bx2 + 1, _by - 1+ i)
		term.write(string.rep("-", 5))
	end
	term.setCursorPos(_bx1, _by + 1)
	term.write("|"..string.rep(" ",5).."|")
	term.setCursorPos(_bx2, _by + 1)
	term.write("|"..string.rep(" ",5).."|")
	
	--Hands
	hand:display()
	if splitHand then splitHand:display() end
	dealerHand:display()
	displayBlackjackBets()
	_bjDeck:display()
	displayOverMenuBar()
end

--Prompts the user to put in how much money they will bet before the next draw
local function placeBlackjackBet()
	_footermsg = ""
	displayBlackjack()
	term.setBackgroundColour(tablebg)
	term.setTextColour(colours.black)
	local _x = 20
	local _prompt = "Place bet: "
	while currBet == nil or currBet < tableMin or currBet > tableMax or currBet > bank do
		term.setCursorPos(_x,h-1)
		term.write(_prompt)
		term.setTextColour(colours.black)
		currBet = read()
		term.setCursorPos(_x + #_prompt, h-1)
		term.write(string.rep(" ", #currBet))
		currBet = tonumber(currBet)
		term.setTextColour(colours.red)
	end
	bank = bank - currBet
	displayBlackjackBets()
end

--Deal a hand of blackjack
local function dealBlackjack()
	createDeck(1)
	local _c = hand.head
	while _c do
		_c:displayTable()
		_c = _c.tail
	end
	local _c = dealerHand.head
	while _c do
		_c:displayTable()
		_c = _c.tail
	end
	hand.head = nil
	dealerHand.head = nil
	splitHand = nil
	shuffleDeck()
	displayBlackjackBets()
	placeBlackjackBet()
	
	--Deal the cards
	for i=1,4 do
		local _c = table.remove(deck,1)
		if i % 2 == 1 then
			if hand.head then _c.x = hand.head.x + styles.width + 1
			else _c.x = _bx1 - 4  end
			_c.y = h - styles.height - 2
			_c.tail = hand.head
			_c.visible = true
			hand.head = _c
		else
			if dealerHand.head then _c.x = dealerHand.head.x + styles.width + 1
			else _c.x = _bx1 + 4  end
			_c.y = 3
			_c.tail = dealerHand.head
			_c.visible = dealerHand.head ~= nil
			dealerHand.head = _c
		end
		_c:display()
		sleep(0.2)
	end
end

--Returns a point value for how much the hand is worth
local function calculateHandValue(_hand)
	local _score, _c = 0, _hand.head
	local _firstAce = false
	while _c do
		if _c.val == 1 and not _firstAce then
			_score = _score + 11
			_firstAce = true
		elseif _c.val > 10 then
			_score = _score + 10
		else
			_score = _score + _c.val
		end
		_c = _c.tail
	end
	if _score > 21 and _firstAce then 
		_firstAce = false
		_score = _score - 10 
	end
	return _score, _firstAce
end

local function drawHandValue(_x,_y,_value,_soft)
	term.setBackgroundColour(colours.blue)
	term.setTextColour(colours.white)
	term.setCursorPos(_x,_y)
	term.write(" ".._value..string.rep(" ", 2 - math.floor(math.log10(_value))))
	term.setCursorPos(_x,_y+1)
	if _soft then term.write("soft") else term.write("hard") end
end

--Handles events for insurace
local function handleBlackjackInsurance()
	if dealerHand.head.val == 1 then
		local _insuranceCost = math.floor(currBet / 2)
		_footermsg, _footercolor = "Buy insurance? Y/N", colours.white
		displayBlackjackBets()
		
		local id,_c,p2,p3 = os.pullEvent()
		while string.lower(_c) ~= 'y' and string.lower(_c) ~= 'n' do
			if manageMenuMouseEvents(id,p2,p3) then return end
			id,_c,p2,p3 = os.pullEvent("char")
		end
		if string.lower(_c) == 'y' then
			insurance = currBet / 2
		end
	end
end

--Displays a little message in the betting box
local function displayBetMessage(_msg, _col)
	term.setCursorPos(_bx1 + 1, _by + 1)
	term.setBackgroundColour(tablebg)
	term.setTextColour(_col)
	term.write(_msg)
end

--Handles the input for the basic game of blackjack
local function handleBlackjackInput()
	handleBlackjackInsurance()
	local _takings = 0
	if calculateHandValue(dealerHand) == 21 then
		sleep(0.2)
		_c = dealerHand.head
		while _c do
			_c.visible = true
			_c = _c.tail
		end
		dealerHand:display()
		_takings = _takings - currBet + (insurance * 2)
		bank = bank + math.max(_takings, 0)
		currBet = 0
		_footermsg, _footercolor = "Dealer wins! Takings: ".._takings, colours.black
		displayBlackjackBets()
		displayBetMessage("LOSE!", colours.red)
	elseif calculateHandValue(hand) == 21 then
		_takings = _takings + math.floor(currBet * 2.5) - insurance
		bank = bank + _takings
		currBet = 0
		_footermsg, _footercolor = "Blackjack! Takings: ".._takings, colours.blue
		displayBlackjackBets()
		displayBetMessage(" BJ! ", colours.blue)
	else
		--The insurance bet, if taken, was lost
		_takings = _takings - insurance
		local _handValue, _handSoft = calculateHandValue(hand)
		drawHandValue(_bx1 - 9, _by + 4, _handValue, _handSoft)
		local _doubledDown = false
		
		--Double down
		if hand.head.val == hand.head.tail.val then
			_footermsg, _footercolor = "Double Down? Y/N", colours.white
			displayBlackjackBets()
			while true do
				local id,p1,p2,p3 = os.pullEvent()
				if manageMenuMouseEvents(id,p2,p3) then return end
				if id == "key" and p1 == keys.y then
					_doubledDown = true
					bank = bank - currBet
					currBet = currBet + currBet
					displayBlackjackBets()
					local _c = table.remove(deck, 1)
					_c.x = hand.head.x + styles.width + 1
					_c.y = hand.head.y
					_c.visible = true
					_c. tail = hand.head
					hand.head = _c
					hand:display()
					sleep(0.2)
					break
				elseif id == "key" and p1 == keys.n then
					break
				end
			end
		end
		
		if not _doubledDown then
			--The player chooses to hit or stay
			local _hitCount = 0
			local _spaceDiff = styles.width + 1
			while true do
				_footermsg, _footercolor = "(H)it or (S)tand? H/S", colours.white
				displayBlackjackBets()
				
				local id,p1,p2,p3 = os.pullEvent()
				if manageMenuMouseEvents(id,p2,p3) then return end
				if id == "key" and p1 == keys.h then
					local _c = table.remove(deck, 1)
					_c.x = hand.head.x + _spaceDiff
					_c.y = hand.head.y
					_c.tail = hand.head
					_c.visible = true
					hand.head = _c
					_hitCount = _hitCount + 1
					if _hitCount > 1 and _hitCount < 5 then
						_c = hand.head
						local _shift = _hitCount + 1
						while _c.tail do
							_c:displayTable()
							_c:move(_c.x - _shift, _c.y)
							_shift = _shift - 1
							_c = _c.tail
						end
						_spaceDiff = _spaceDiff - 1
					end
					
					hand:display()
					_handValue, _handSoft = calculateHandValue(hand)
					drawHandValue(_bx1 - 9, _by + 4, _handValue, _handSoft)
					if _handValue >= 21 then
						sleep(0.2)
						break 
					end
				elseif id == "key" and p1 == keys.s then
					sleep(0.2)
					break
				end
			end
		end
		_footermsg = ""
		
		local _hitCount = 0
		local _spaceDiff = styles.width + 1
		if _handValue <= 21 then
			--The dealer takes his turn to hit or stay
			local _dhandValue, _dhandSoft = calculateHandValue(dealerHand)
			local _c = dealerHand.head
			while _c do _c.visible = true _c = _c.tail end
			dealerHand:display()
			drawHandValue(13, 4, _dhandValue, _dhandSoft)
			sleep(0.2)
			
			while _dhandValue < 17 and _dhandValue < _handValue do
				local _c = table.remove(deck, 1)
				_c.x = dealerHand.head.x + _spaceDiff
				_c.y = dealerHand.head.y
				_c.visible = true
				_c.tail = dealerHand.head
				dealerHand.head = _c
				
				_hitCount = _hitCount + 1
				if _hitCount > 1 and _hitCount < 5 then
					_c = dealerHand.head
					local _shift = _hitCount + 1
					while _c.tail do
						_c:displayTable()
						_c:move(_c.x - _shift, _c.y)
						_shift = _shift - 1
						_c = _c.tail
					end
					_spaceDiff = _spaceDiff - 1
				end
				
				_dhandValue = calculateHandValue(dealerHand)
				dealerHand:display()
				drawHandValue(13, 4, _dhandValue, _dhandSoft)
				sleep(0.4)
			end
			
			local _betmsg, _betcol = nil, nil
			term.setBackgroundColour(tablebg)
			if _dhandValue > 21 then
				term.setCursorPos(_bx1 + 1, _by + 1)
				_betmsg, _betcol = " WIN!", colours.blue
				_takings = _takings + currBet + currBet - insurance
				_footermsg, _footercolor =  "Dealer Bust! Takings: ".._takings, colours.white
			elseif _dhandValue > _handValue then
				term.setCursorPos(_bx1 + 1, _by + 1)
				_betmsg, _betcol = "LOSE!", colours.red
				_takings = _takings - currBet
				_footermsg, _footercolor =  "Dealer Wins! Takings: ".._takings, colours.red
			elseif _dhandValue == _handValue then
				term.setCursorPos(_bx1 + 1, _by + 1)
				_takings = currBet
				_betmsg, _betcol = "PUSH!", colours.orange
				_footermsg, _footercolor =  "Push! Takings: ".._takings, colours.orange
			else
				term.setCursorPos(_bx1 + 1, _by + 1)
				_takings = _takings + currBet * 2 
				_betmsg, _betcol = " WIN!", colours.blue
				_footermsg, _footercolor =  "Player Wins! Takings: ".._takings, colours.white
			end
			currBet = 0
			bank = bank + math.max(_takings, 0)
			displayBlackjackBets()
			displayBetMessage(_betmsg,_betcol)
		else
			_takings = _takings - currBet
			currBet = 0
			displayBetMessage("BUST!", colours.red)
			_footermsg, _footercolor =  "Player Bust! Takings: ".._takings, colours.red
			displayBlackjackBets()
		end
	end
	--Cleanup
	currBet = 0
	insurance = 0
	splitBet = 0
end

--Plays blackjack
local function playBlackjack()
	xoff = 0
	yoff = 0
	backStyle = styles.backs.alligator
	backbg = colours.red
	backfg = colours.white
	title = "Casino Blackjack"
	
	startBlackjack()
	local playing = true
	displayBlackjack()
	while playing do
		local id,p1,p2,p3 = os.pullEvent()
		if manageMenuMouseEvents(id,p2,p3) then return end
		if (id == 'key' and p1 == keys.enter) or 
				(id == 'mouse_click' and _bjDeck:clicked(p2,p3)) then
			if bank < tableMin then
				_footermsg, _footercolor = "No money left...", colours.red
				displayBlackjack()
			else
				dealBlackjack()
				handleBlackjackInput()
			end
		end
		playing = not quit and nextGame == nil
	end
end

	--[[
		Spider Solitaire
		The windows vista classic. Think freecel but more random and harder
	]]--

--We use 'spaces' from Klondike in the same fashion
--The decks of cards that have been completed
local finishedDecks = {}
--Difficulty, and the (one or two) suits allowed for use in the game.
local spiderLevel = 1
local _suit1, _suit2  = nil, nil
local _settings = {
	{ name = "Easy", decks = "one"; colour = colours.lime; val = 1, y = 4 };
	{ name = "Medium", decks = "two"; colour = colours.orange; val = 2, y = 6};
	{ name = "Hard", decks = "four", colour = colours.red; val = 3, y = 8};
}
--The spider draw deck
local _spdeck = cardP:new( { x = w - styles.width, y = 2, val = #deck } )

--Displays the game board for spider
local function displaySpider()
	term.setBackgroundColour(tablebg)
	term.clear()
	for i=1,#spaces do spaces[i]:display() end
	for i=1,#finishedDecks do finishedDecks[i]:display() end
	_spdeck:display()
	displayOverMenuBar()
end

--Performs the initial deal (animated as is now the standard)
local function dealSpider()
	createDeck(2)
	shuffleDeck()
	_spdeck.val = #deck
	_spdeck:display()
	_suit1, _suit2 = nil, nil
	displaySpider()
	--Changing the suits per difficulty. Standard spider is all/reds/suits but this is a computer!
	if spiderLevel < 3 then
		for i=1,#deck do
			local _c = deck[i]
			if not _suit1 then _suit1 = deck[i].suit
			elseif not _suit2 and spiderLevel == 2 and deck[i].suit.colour ~= _suit1.colour then
				_suit2 = deck[i].suit
			elseif spiderLevel == 1 and deck[i].suit ~= _suit1 then
				deck[i].suit = _suit1
			elseif spiderLevel == 2 and (deck[i].suit ~= _suit1 or deck[i].suit ~= _suit2) then
				if deck[i].suit.colour == _suit1.colour then deck[i].suit = _suit1
				else deck[i].suit = _suit2 end
			end
		end
	end
	--Constructing the 10 spaces
	local _cspace = 1
	for i=1,54 do
		local _c = table.remove(deck, 1)
		_c.x = _cspace + styles.width * (_cspace - 1) + 1
		_c.y = math.ceil(i * 0.1) + 6
		_c.visible = i > 44
		
		if not spaces[_cspace] then
			spaces[_cspace] = linkedCardP:new()
			spaces[_cspace].head = _c
		else
			_c.tail = spaces[_cspace].head
			spaces[_cspace].head = _c
		end
		_cspace = (_cspace % 10) + 1
		_c:display()
		sleep(0.05)
	end
end

--Check to see if a set was made
local function checkForSet(_deck)
	--We can assume a set can ONLY be made from the head of the deck
	local _val,_topSuit = 1, _deck.head.suit
	local _c = _deck.head
	while _c and _c.val == _val and _c.suit == _topSuit do
		_val = _val + 1
		_c = _c.tail
	end
	
	--All 13 cards are accounted for
	if _val == 14 then
		table.insert(finishedDecks,linkedCardP:new())
		_c = _deck.head
		_val = 1
		while _c and _c.val == _val and _c.suit == _topSuit do
			_deck.head = _c.tail
			_c.tail = finishedDecks[#finishedDecks].head
			finishedDecks[#finishedDecks].head = _c
			
			if not _deck.head then 
				_deck.head = cardP:new( { x = _c.x, y = _c.y, visible = true, val = 0 } )
				_c:displayTable()
				_c:move(#finishedDecks * 2 + 2, 2)
				_c:display()
				displayOverMenuBar()
				_deck.head:display()
				break
			end
			_c:displayTable()
			_c:move(#finishedDecks * 2 + 2, 2)
			_c = _deck.head 
			finishedDecks[#finishedDecks]:display()
			_c:display()
			displayOverMenuBar()
			_val = _val + 1
			sleep(0.2)
		end
		assert(_deck.head ~= nil)
	end
end

--Attempts to move one list of cards onto another list of cards
local function performSpiderMove(_card, _deck)
	--We assume a selection is impossible if wrong-suited cards lie above this one
	if ((selCard.val == _card.val - 1 and _deck.head == _card) or _card.val == 0) 
			and selDeck ~= _deck then
		local _top = selDeck.head
		_deck.head = _top
		local _ydiff = 1
		_top:displayTable()
		while _top ~= selCard do
			_top = _top.tail
			_ydiff = _ydiff + 1
			_top:displayTable()
		end
	
		selDeck.head = selCard.tail
		if selDeck.head == nil then 
			selDeck.head = cardP:new( { val = 0; x = selCard.x; y = selCard.y; } )
		end
		selDeck:display()
		if _card.val == 0 then
			selCard.tail = nil
			_deck.head:move(_card.x, _card.y + _ydiff - 1, true)
		else
			selCard.tail = nil
			_deck.head:move(_card.x, _card.y + _ydiff, true)
			selCard.tail = _card
		end
	
		select()
		_deck:display()
		checkForSet(_deck)
	else
		local _c = selDeck
		select(_card, _deck)
		_c:display()
		_deck:display()
	end
end

--Draws 10 more cards from the deck
local function dealSpiderDeck()
	local _canSkip, _shouldSkip = false, false
	for i=1,#spaces do 
		if spaces[i].head.tail then _canSkip = true end
		if spaces[i].head.val == 0 then _shouldSkip = true end
	end
	if _canSkip and _shouldSkip then return end
	
	for i=1,#spaces do
		local _c = table.remove(deck, 1)
		_spdeck.val = #deck
		_c.visible = true
		_c.tail = spaces[i].head
		_c.x = spaces[i].head.x
		_c.y = spaces[i].head.y + 1
		spaces[i].head = _c
		spaces[i]:display()
		_spdeck:display()
		displayOverMenuBar()
		sleep(0.1)
	end
	
	for i=1,#spaces do checkForSet(spaces[i]) end
end

--Handles basic spider input and events
local function handleSpiderInput()
	local gameWon = false
	while not gameWon do
		local id,p1,p2,p3 = os.pullEvent()
		if manageMenuMouseEvents(id,p2,p3) then
			return 
		end
		if id == "mouse_click" then
			--Check if the deck was clicked
			if _spdeck:clicked(p2,p3) and _spdeck.val > 0 then
				dealSpiderDeck()
			else
				local _complete = false
				for i=1,#spaces do
					local _c = spaces[i].head
					local _topSuit = _c.suit
					while _c do
						if _c:clicked(p2,p3) then
							if _c.val == 0 and selCard then
								performSpiderMove(_c, spaces[i])
							elseif _c.visible then
								if not selCard or selDeck == spaces[i] then
									local _d = selDeck
									select(_c, spaces[i])
									if _d then _d:display() end
									selDeck:display()
								elseif _c == selCard then
									break;
								elseif _c == spaces[i].head then
									performSpiderMove(_c, spaces[i])
								end
							elseif not _c.visible and _c == spaces[i].head then
								_c.visible = true
								_c:display()
								local _d = selDeck
								select()
								if _d then _d:display() end
							else
								local _d = selDeck
								select()
								if _d then _d:display() end
							end
							_complete = true
							break
						end
						if not _c.tail or _c.tail.suit ~= _topSuit or _c.tail.val ~= _c.val + 1 then
							break
						end
						_c = _c.tail
					end
					if _complete then break end
				end
				
				if not _complete then
					local _d = selDeck
					select()
					if _d then _d:display() end
				end
				
				lmX, lmY = p2, p3
				txoff, tyoff = xoff, yoff
				displayOverMenuBar()
				
				gameWon = #finishedDecks == 8
			end
		elseif id == "mouse_drag" then
			if lmX > 0 and lmY > 0 then
				local yDiff = p3 - lmY
				--Mouse drag events seem to be pretty overzealous. Or is that a version issue...
				if tyoff + yDiff ~= yoff then
					yoff = math.min(tyoff + yDiff, 0)
					--h-21 is the maximum unrevealed column (6) plus the max revealed column (13)
					--plus 3 to reveal the face of the card and 4 more for whitespace
					yoff = math.max(yoff, h - 30)
					displaySpider()
				end
			end
		elseif id == "mouse_scroll" then
			yoff = math.min(yoff - p1, 0)
			yoff = math.max(yoff, h - 30)
			displaySpider()
			--Check each space on the board
		elseif id == "key" then
			if p1 == keys.down then
				yoff = math.min(yoff + 1, 0)
				displaySpider()
			elseif p1 == keys.up then
				yoff = math.max(yoff - 1, h - 30)
				displaySpider()
			end
		end
	end
	
	--A final win animation
	local _t = {
		{ x = math.floor(w/2); y = math.floor(h/2); xdir = -1; ydir = -1; };
		{ x = math.floor(w/2) + 1; y = math.floor(h/2); xdir = 1; ydir = -1; };
		{ x = math.floor(w/2); y = math.floor(h/2) + 1; xdir = -1; ydir = -0.25; };
		{ x = math.floor(w/2) + 1; y = math.floor(h/2) + 1; xdir = 1; ydir = -0.25; };
		{ x = math.floor(w/2); y = math.floor(h/2) + 2;  xdir = -1; ydir = 0.25; };
		{ x = math.floor(w/2) + 1; y = math.floor(h/2) + 2; xdir = 1; ydir = 0.25; };
		{ x = math.floor(w/2); y = math.floor(h/2) + 3; xdir = -1; ydir = 1; };
		{ x = math.floor(w/2) + 1; y = math.floor(h/2) + 3; xdir = 1; ydir = 1; };
	}
	for i = 1, #finishedDecks do
		for j = 1, #_t do
			term.setCursorPos(_t[j].x, _t[j].y)
			term.setBackgroundColour(tablebg)
			term.setTextColour(finishedDecks[i].head.suit.colour)
			term.write(finishedDecks[i].head.suit.char)
			_t[j].x = _t[j].x + _t[j].xdir
			_t[j].y = _t[j].y + _t[j].ydir
		end
		displayOverMenuBar()
		sleep(0.2)
	end
end

--Chooses easy medium or hard
local function chooseDifficuly()
	for i=1,#_settings do
		local _s = _settings[i]
		term.setCursorPos(10, _s.y)
		term.setBackgroundColour(colours.grey)
		term.setTextColour(_s.colour)
		term.write(" ".._s.name.." ")
		term.setBackgroundColour(tablebg)
		term.setTextColour(colours.white)
		term.setCursorPos(20, _s.y)
		term.write(_s.decks.." suit(s)")
	end
	
	while true do
		local id,p1,p2,p3 = os.pullEvent()
		if manageMenuMouseEvents(id,p2,p3) then return false end
		if id == "mouse_click" then
			for i=1,#_settings do
				if p2 >= 10 and p2 <= 25 and _settings[i].y == p3 then
					spiderLevel = _settings[i].val
					return true
				end
			end
		end
	end
end

--Deals up a good old fashion game of spider
local function playSpider()
	xoff = 0
	yoff = 0
	backbg = colours.purple
	backfg = colours.black
	backStyle = styles.backs.spooky
	title = "Spider Solitaire"
	spaces = {}
	finishedDecks = {}
	_spdeck.val = 1
	
	displaySpider()
	if not chooseDifficuly() then return end
	displaySpider()
	dealSpider()
	handleSpiderInput()
end
	
	--[[
		Golf
		Because apparently I'm enjoying making these card games
	]]--

--Like spider and klondike, this uses the spaces deck (7 slots like klondike

--The card clicked to draw another card to the tableau
local _gfcard = cardP:new( { 
	x = w/2 - styles.width / 2 - styles.width + 1; 
	y = h - styles.height - 1; 
	visible = false; 
	val = 1;
} )
--The foundation
local foundation = linkedCardP:new()

--Makes sure golf is ready for the next game
local function setupGolf()
	createDeck(1)
	shuffleDeck()
	_gfcard.val = #deck
	foundaction = linkedCardP:new()
	foundation.head = cardP:new({
		x = _gfcard.x + 2 + styles.width;
		y = _gfcard.y;
		visible = false;
		val = 0;
	})
	local _extraSpace = (w - (styles.width * 7)) / 8
	for i=1,7 do 
		spaces[i] = linkedCardP:new()
		spaces[i].head = cardP:new({
			x = _extraSpace * i + styles.width * (i - 1) + 1;
			y = 3;
			visible = false;
			val = 0;
		})
	end
end

--Gets the score of a game of golf
local function getGolfScore()
	local _score = 0
	for i=1,#spaces do
		local _c = spaces[i].head
		while _c and _c.val ~= 0 do
			_c = _c.tail
			_score = _score + 1
		end
	end
	if _score == 0 then _score = -#deck end
	return _score
end

--Displays golf
local function displayGolf()
	term.setBackgroundColour(tablebg)
	term.clear()
	for i=1,#spaces do if spaces[i] then spaces[i]:display() else break end end
	_gfcard:display()
	foundation:display()
	displayOverMenuBar()
	term.setCursorPos(3,h)
	term.setBackgroundColour(tablebg)
	term.setTextColour(colours.black)
	local _score = getGolfScore()
	if _score < -15 then _score = 0 end
	term.write("Score: ".._score.."  ")
end

--Deals up a hand of golf
local function dealGolf()
	local _index = 1
	for i=1,35 do
		local _c = table.remove(deck, 1)
		_c.visible = true
		_c.x = spaces[_index].head.x
		
		if spaces[_index].head.val == 0 then
			_c.y = spaces[_index].head.y
		else 
			_c.y = spaces[_index].head.y + 1
		end
		_c.tail = spaces[_index].head
		spaces[_index].head = _c
		_c:display()
		sleep(0.1)
		
		_index = _index % 7 + 1
	end
	
	displayGolf()
end

--Attempts to move a card from the tabluea to the foundation
local function tryGolfMove(_deck)
	if foundation.head.val == 13 or _deck.head.val == 0 or foundation.head.val == 0 then 
		return false 
	end
	local scoreDiff = foundation.head.val - _deck.head.val
	if math.abs(scoreDiff) == 1 then
		local _c = _deck.head
		_deck.head = _c.tail
		_c:displayTable()
		_c:move(foundation.head.x, foundation.head.y)
		_c.tail = foundation.head
		foundation.head = _c
		_deck:display()
		foundation:display()
		return true
	else return false end
end

--Handles all that golfing you'll be doing
local function handleGolfInput()
	local _currScore = getGolfScore()
	while _currScore > 0 do
		local id,p1,p2,p3 = os.pullEvent()
		if manageMenuMouseEvents(id,p2,p3) then return end
		
		if id == "mouse_click" then
			if _gfcard.val > 0 and _gfcard:clicked(p2,p3) then
				_c = table.remove(deck, 1)
				_c.x = foundation.head.x
				_c.y = foundation.head.y
				_c.visible = true
				_c.tail = foundation.head
				foundation.head = _c
				_gfcard.val = #deck
				foundation:display()
				_gfcard:display()
			else
				for i=1,#spaces do
					local _c = spaces[i].head
					--Moving from space to the foundation
					if _c:clicked(p2,p3) then 
						if tryGolfMove(spaces[i]) then 
							_currScore = getGolfScore()
							term.setCursorPos(3,h)
							term.setBackgroundColour(tablebg)
							term.setTextColour(colours.black)
							term.write("Score: "..getGolfScore().."  ")
						end
					end
				end
			end
		end
	end
	displayGolf()
	term.setBackgroundColour(tablebg)
	term.setTextColour(colours.black)
	term.setCursorPos(_gfcard.x + 2, _gfcard.y - 3)
	term.write("/'")
	term.setCursorPos(_gfcard.x, _gfcard.y - 2)
	term.write("o/")
end
	

local function playGolf()
	xoff = 0
	yoff = 0
	backbg = colours.yellow
	backfg = colours.blue
	backStyle = styles.backs.royal
	title = "Golf"
	
	setupGolf()
	displayGolf()
	dealGolf()
	handleGolfInput()
end	

	--[[
		Game Management Stuff
	]]--
	
table.insert(menuOptions, { name = "Klondike", key = "K", enabled = true, value = function()
	currOverDraw = drawKlondike
	nextGame = playKlondike
end })
table.insert(menuOptions, { name = "Blackjack", key = "B", enabled = true, value = function()
	currOverDraw = displayBlackjack
	nextGame = playBlackjack
end })
table.insert(menuOptions, { name = "Spider", key = "S", enabled = true, value = function()
	currOverDraw = displaySpider
	nextGame = playSpider
end })
table.insert(menuOptions, { name = "Golf", key = "G", enabled = true, value = function()
	currOverDraw = displayGolf
	nextGame = playGolf
end })
table.insert(menuOptions, { name = "--------", enabled = false, value = nil })
table.insert(menuOptions, { name = "Quit", key = "Q", enabled = true, value = function()
	currOverDraw = nil
	nextGame = nil
	quit = true
end }) 

if not term.isColor() then print("For advanced computers only") return end

local function displayNitrosoftTitle()
term.clear()
	local _w,_h = term.getSize()
	local _t1,_t2 = "nitrosoft", "games"
	term.setCursorPos(math.floor(_w/2-#_t1), math.floor(_h/2))
	if term.isColour() then term.setTextColour(colours.blue) end
	term.write(_t1)
	term.setCursorPos(math.floor(_w/2-#_t2/2),math.floor(_h/2)+1)
	term.setTextColour(colours.white)
	term.write(_t2)
	term.setCursorPos(math.floor(_w/2-#_t1), math.floor(_h/2)+2)
	if term.isColour() then term.setTextColour(colours.red) end
	term.write(string.rep("-",#_t1*2))
	if term.isColour() then
		term.setBackgroundColour(colours.green)
		term.setCursorPos(_w/2+#_t1-4, math.floor(_h/2)-2)
		term.write("  ")
		term.setCursorPos(_w/2+#_t1-4, math.floor(_h/2)-1)
		term.write("  ")
		term.setBackgroundColour(colours.white)
		term.setTextColour(colours.red)
		term.setCursorPos(_w/2+#_t1-3, math.floor(_h/2)-1)
		term.write("4 ")
		term.setCursorPos(_w/2+#_t1-3, math.floor(_h/2))
		term.write(" v")
	end
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.setCursorPos(1,_h)
	os.pullEvent("key")
end
displayNitrosoftTitle()

--The over menu game fnction
local function overMenuInput()
	term.setBackgroundColour(tablebg)
	term.clear()
	displayOverMenuBar()
	while not quit do
		if nextGame then
			local _game = nextGame
			nextGame = nil
			_game()
		else
			local id,p1,p2,p3 = os.pullEvent()
			manageMenuMouseEvents(id,p2,p3)
		end
	end
end

overMenuInput()
end

function center(y,string)
	local w,h = term.getSize()
	local x = (w/2)-(#string/2)
	term.setCursorPos(x,y)
	print(string)
end

function centerSlow(y,string)
	local w,h = term.getSize()
	local x = (w/2)-(#string/2)
	term.setCursorPos(x,y)
	textutils.slowPrint(string)
end
