-- 'Timer' demo.
-- To run, navigate to the main project directory and invoke:
-- $ love . demo/timer


require("lib.test.strict")


love.window.setMode(384, 384, {
	resizable=true,
	minwidth=384,
	minheight=384
})
love.window.setTitle("ProdUI: Timer")


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
	seconds = 0.0,
	minutes = 0.0,
	hours = 0.0,
	counting = false,
}


local function _updateTimerText()
	-- Grab a reference to the timer text widget.
	--[[
	If we created the widget before this point, we could now access it through an upvalue.
	Care must be taken in that case, because such an upvalue can become a dangling reference
	if the widget is destroyed.

	In any case, the findTag() method can allow far-flung callback logic to locate pertinent
	controls and labels.
	--]]
	local timer_text = wid_root:findTag("timer-text")

	if timer_text then
		-- Format to 'H:MM:SS.S'
		local fmt = string.format
		local str = fmt("%01d", app.hours) .. ":" .. fmt("%02d", app.minutes) .. ":" .. fmt("%04.1f", app.seconds)

		timer_text:setText(str)
	end
end


local function _cb_buttonStartPause(self)
	app.counting = not app.counting
end


local function _cb_buttonReset(self)
	app.counting = false
	app.seconds, app.minutes, app.hours = 0, 0, 0

	_updateTimerText()
end


-- This runs in love.update(), just before updating the ProdUI Context.
local function _tick(dt)
	-- Testing
	--dt = dt * 1000

	local old_s, old_m, old_h = app.seconds, app.minutes, app.hours

	if app.counting then
		app.seconds = app.seconds + dt
		for i = 1, 1000 do
			if app.seconds >= 60 then
				app.seconds = app.seconds - 60
				app.minutes = app.minutes + 1
			end
		end

		for i = 1, 1000 do
			if app.minutes >= 60 then
				app.minutes = app.minutes - 60
				app.hours = app.hours + 1
			end
		end
	end

	if not (old_s == app.seconds and old_m == app.minutes and old_h == app.hours) then
		_updateTimerText()
	end
end


-- * Construct the timer scene.

do
	local panel = workspace:addChild("base/container_panel")
		:geometrySetMode("remaining")

	local timer_text = panel:addChild("wimp/text_block")
		:geometrySetMode("static", 0.5, 0.5, 488, 128, false, false, "in", "in")
		:setTag("timer-text")
		:setText("This text should be replaced before the first frame is drawn.")
		:setFontId("h1")
		:setAlign("center")
		:setAutoSize("v")

	local btn_start = panel:addChild("base/button")
		:geometrySetMode("relative", 0.5, 96, 240, 56, false, true, "in", nil)
		:setLabel("Start/Pause", "single")
		:userCallbackSet("cb_buttonAction", _cb_buttonStartPause)

	local btn_reset = panel:addChild("base/button")
		:geometrySetMode("relative", 0.5, 32, 240, 56, false, true, "in", nil)
		:setLabel("Reset", "single")
		:userCallbackSet("cb_buttonAction", _cb_buttonReset)

	workspace:tryTakeThimble1()
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
	_tick(dt)

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
