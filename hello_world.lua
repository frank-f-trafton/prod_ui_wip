love.window.setTitle("ProdUI: Hello World")


-- Catches undeclared globals.
require("lib.test.strict")


-- LÖVE Setup
love.graphics.setDefaultFilter("nearest", "nearest")
love.keyboard.setKeyRepeat(true)
love.keyboard.setTextInput(false) -- ProdUI programs should start with text input disabled.


-- ProdUI
local prodUi = require("prod_ui")


local default_settings = prodUi.res.loadLuaTable("prod_ui/data/default_settings.lua")


-- * Make a ProdUI Context, a Root widget, and a Workspace widget.

--[[
The Context is the main object.
The Root is an invisible widget that holds all other widgets.
A Workspace is one visible "screen" in your program. Typically, small programs like
this only need one Workspace.
--]]

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


-- * Construct the "Hello World!" scene.

do
	-- Make some text.
	local text_block = workspace:addChild("wimp/text_block")
		:setText("Hello world!")
		:setFontID("h1")
		:geometrySetMode("segment", "top")
		:setAutoSize("v")

	-- Make a button to close the program.
	local btn = workspace:addChild("base/button")
		:setLabel("OK", "single")
		:geometrySetMode("relative", 0, 16, 250, 64)
		:userCallbackSet("cb_buttonAction", function(self) love.event.quit() end)

	-- Assign keyboard focus to the button.
	btn:tryTakeThimble1()
end


-- * Reshape the Root.

--[[
At this point, nothing (save for the Root) is correctly positioned or sized.
To fix that, we now call the 'reshape()' method on the root.
--]]

wid_root:reshape()


-- * Event Callbacks

--[[
Finally, the Context requires information from LÖVE events to work.

We also have to call the Context's draw method within love.draw().
--]]

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
