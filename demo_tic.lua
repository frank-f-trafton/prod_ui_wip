require("lib.test.strict")


love.window.setMode(640, 480, {
	resizable=true,
	minwidth=640,
	minheight=480
})
love.window.setTitle("ProdUI: Tic-tac-toe")
-- AKA Noughts and Crosses, AKA Xs and Os, etc.


love.graphics.setDefaultFilter("nearest", "nearest")
love.keyboard.setKeyRepeat(true)
love.keyboard.setTextInput(false)


local prodUi = require("prod_ui")


local default_settings = prodUi.res.loadLuaTable("prod_ui/data/default_settings.lua")


local context, wid_root, workspace
do
	context = prodUi.context.newContext("prod_ui", default_settings)
	context:setScale(1.0)
	context:setTextureScale(1)

	context:loadSkinnersInDirectory("prod_ui/skinners", true, "")
	context:loadWidgetDefsInDirectory("prod_ui/widgets", true, "", false)

	local theme = context:loadTheme("vacuum_dark")
	context:applyTheme(theme)

	wid_root = context:addRoot("wimp/root_wimp")
	workspace = wid_root:newWorkspace()
	wid_root:setActiveWorkspace(workspace)
end


-- * Our application state.

local app = {
	state = "game-over", -- "game-over", "playing"
	turn = "X",
	seconds = 0.0,
}


-- The game board, addressed like 'board[x][y]'.
-- Valid cell states: "" (empty), "X", "O"

local board = {
	{"", "", ""},
	{"", "", ""},
	{"", "", ""}
}


--[[
We will be using ProdUI's standard button widgets to interact with the game board.
Each button represents one cell.

We will be keeping direct references to these widgets for easy access later. In this
demo, the buttons will never be destroyed or replaced, so we don't have to worry
about dangling references.
--]]
local btn_new_game, btn_end_game
local cell_buttons = { -- to be filled in later
	{},
	{},
	{}
}


local function _getButtonPosition(button)
	for y = 1, 3 do
		for x = 1, 3 do
			if cell_buttons[x][y] == button then
				return x, y
			end
		end
	end

	error("couldn't find button position")
end


local function _updateCell(x, y, value)
	assert(math.floor(x) == x and math.floor(y) == y and x >= 1 and x <= 3 and y >= 1 and y <= 3)
	assert(value == "" or value == "X" or value == "O")

	board[x][y] = value
	cell_buttons[x][y]:setLabel(value, "single")
end


local function _updateTimerText()
	local timer_text = wid_root:findTag("timer-text")

	if timer_text then
		timer_text:setText(tostring(math.floor(app.seconds)))
	end
end


local function _setButtonsEnabled(enabled)
	for y = 1, 3 do
		for x = 1, 3 do
			cell_buttons[x][y]:setEnabled(enabled)
		end
	end
end


local function _newGame()
	for y = 1, 3 do
		for x = 1, 3 do
			_updateCell(x, y, "")
		end
	end

	app.turn = "X"
	app.seconds = 1.0
	app.state = "playing"

	_updateTimerText()
	_setButtonsEnabled(true)

	btn_end_game:setEnabled(true)
	btn_new_game:setEnabled(true)
end


local function _endGame(result)
	app.state = "game-over"

	_setButtonsEnabled(false)
	btn_end_game:setEnabled(false)
	btn_new_game:setEnabled(true)

	if result == "X" or result == "O" then
		print(result .. " wins!")

	elseif result == "draw" then
		print("Draw!")

	elseif result == "player-stop" then
		print("Player ended the game early!")

	else
		print("Unknown end game state!")
	end
end


local function _threeInARow(a, b, c)
	return (a ~= "" and a == b and b == c) and a or nil
end


local function _checkWin()
	-- Horizontal
	for y = 1, 3 do
		local winner = _threeInARow(board[1][y], board[2][y], board[3][y])
		if winner then
			return winner
		end
	end

	-- Vertical
	for x = 1, 3 do
		local winner = _threeInARow(board[x][1], board[x][2], board[x][3])
		if winner then
			return winner
		end
	end

	-- Diagonal '\'
	do
		local winner = _threeInARow(board[1][1], board[2][2], board[3][3])
		if winner then
			return winner
		end
	end

	-- Diagonal '/'
	do
		local winner = _threeInARow(board[3][1], board[2][2], board[1][3])
		if winner then
			return winner
		end
	end

	-- If all cells are populated, it's a draw.
	for y = 1, 3 do
		for x = 1, 3 do
			if board[x][y] == "" then
				return
			end
		end
	end
	return "draw"
end


local _pickCell, _cpuMove


-- CPU moves are random.


_cpuMove = function()
	if app.turn ~= "O" then
		error("wrong turn for the CPU")
	end

	local list = {}

	for y = 1, 3 do
		for x = 1, 3 do
			if board[x][y] == "" then
				table.insert(list, {x=x, y=y})
			end
		end
	end

	if #list == 0 then
		error("tried to run a CPU turn on a full game board")
	end

	local sel = list[love.math.random(1, #list)]

	_pickCell(cell_buttons[sel.x][sel.y])
end


_pickCell = function(button)
	local x, y = _getButtonPosition(button)
	if board[x][y] == "" then
		_updateCell(x, y, app.turn)

		local result = _checkWin()
		if result then
			_endGame(result)
		else
			-- Advance turn
			if app.turn == "X" then
				app.turn = "O"
			else
				app.turn = "X"
			end

			if app.turn == "O" then
				_cpuMove()
			end
		end
	end
end


local function _cb_buttonNewGame(self)
	_newGame()
end


local function _cb_buttonEndGame(self)
	_endGame("player-stop")
end


local function _cb_buttonPressCell(self)
	_pickCell(self)
end


local function _appTick(dt)
	local old_s = app.seconds

	if app.state == "playing" then
		app.seconds = app.seconds + dt
	end

	if not (old_s == app.seconds) then
		_updateTimerText()
	end
end


-- * Construct the game scene.

do
	-- A side panel with game info and "executive" controls (ie new game)
	local side_bar = workspace:addChild("base/container_panel")
		:geometrySetMode("segment", "right", 200)

	local timer_text = side_bar:addChild("wimp/text_block")
		:geometrySetMode("static", 0.5, 0.5, 488, 128, false, false, "in", "in")
		:setTag("timer-text")
		:setFontId("h1")
		:setAlign("center")
		:setAutoSize("v")

	btn_new_game = side_bar:addChild("base/button")
		:geometrySetMode("segment", "bottom", 56)
		:setTag("button-new")
		:setLabel("New Game", "single")
		:userCallbackSet("cb_buttonAction", _cb_buttonNewGame)

	btn_end_game = side_bar:addChild("base/button")
		:geometrySetMode("segment", "bottom", 56)
		:setTag("button-end")
		:setLabel("End Game", "single")
		:userCallbackSet("cb_buttonAction", _cb_buttonEndGame)

	-- Let's tweak the layout order of the buttons so that 'New Game' appears
	-- above 'End Game'. Use either negative numbers, or numbers greater than
	-- the number of widgets in the container. (Note that widgets with the
	-- same 'order' values will sort unpredictably.)
	btn_new_game:geometrySetOrder(2^50 + 1)
	btn_end_game:geometrySetOrder(2^50 + 0)
	side_bar:layoutSort()

	-- The actual game area.
	local game_board = workspace:addChild("base/container_panel")
		:geometrySetMode("remaining")
		:layoutSetGridDimensions(3, 3)

	-- Make the XO buttons; attach 'em to our lookup table.
	for y = 1, 3 do
		for x = 1, 3 do
			local btn_xo = game_board:addChild("base/button")
				:geometrySetMode("grid", x-1, y-1, 1, 1)
				:userCallbackSet("cb_buttonAction", _cb_buttonPressCell)

			cell_buttons[x][y] = btn_xo
		end
	end

	workspace:tryTakeThimble1()

	btn_end_game:setEnabled(false)
	_setButtonsEnabled(false)
end



_updateTimerText()
wid_root:reshape()


function love.resize(w, h)
	context:love_resize(w, h)
end


function love.visible(visible)
	context:love_visible(visible)
end


function love.mousefocus(focus)
	context:love_mousefocus(focus)
end


function love.focus(focus)
	context:love_focus(focus)
end


function love.mousemoved(x, y, dx, dy, istouch)
	context:love_mousemoved(x, y, dx, dy, istouch)
end


function love.mousepressed(x, y, button, istouch, presses)
	context:love_mousepressed(x, y, button, istouch, presses)
end


function love.mousereleased(x, y, button, istouch, presses)
	context:love_mousereleased(x, y, button, istouch, presses)
end


function love.keypressed(kc, sc, rep)
	if kc == "escape" then
		love.event.quit()
	else
		context:love_keypressed(kc, sc, rep)
	end
end


function love.keyreleased(kc, sc)
	context:love_keyreleased(kc, sc)
end


function love.update(dt)
	_appTick(dt)

	context:love_update(dt)
end


function love.draw()
	if not context:isWindowVisible() then
		return
	end

	love.graphics.push("all")

	context:draw(0, 0)

	love.graphics.pop()
end
