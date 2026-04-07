-- 'Hello, world!' demo.
-- To run, navigate to the main project directory and invoke:
-- $ love . demo/hello


-- Catches undeclared globals.
require("lib.test.strict")


-- * Set up the window and title.

--[[
Normally, this stuff can be specified in the LÖVE project's 'conf.lua' file. In this
case, there are multiple demos with different windowing requirements, so it makes
more sense to do the setup here.
--]]

love.window.setMode(640, 480, {
	resizable=true,
	minwidth=512,
	minheight=256
})
love.window.setTitle("ProdUI: Hello World")


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


-- * Construct the "Hello, world!" scene.

do
	-- Make a container with a panel-like background.
	local panel = workspace:addChild("base/container_panel")
		:geometrySetMode("static", 0.5, 0.5, 512, 256, false, false, "in", "in")

	-- Make some text.
	local text_block = panel:addChild("wimp/text_block")
		:geometrySetMode("static", 0.5, 0.5, 488, 128, false, false, "in", "in")
		:setText("Hello, world!")
		:setFontId("h1")
		:setAlign("center")
		:setAutoSize("v")

	-- Make a button to close the program.
	local btn = panel:addChild("base/button")
		:geometrySetMode("relative", 0.5, 32, 240, 56, false, true, "in", nil)
		:setLabel("OK", "single")
		:userCallbackSet("cb_buttonAction", function(self) love.event.quit() end)

	-- Assign keyboard focus to the button.
	btn:tryTakeThimble1()
end


--[[
We now have a widget tree that looks like this:

    [Root]
      |
  [Workspace]
      |
    [Panel]
      |
   +--+----+
   |       |
[Text]  [Button]
--]]


-- * Reshape the Root.

--[[
At this point, nothing (save for the Root) is correctly positioned or sized.
To fix that, we now call the 'reshape()' method on the root.
--]]

wid_root:reshape()


-- * Event Callbacks

--[[
Finally, the Context requires information from LÖVE events to work.

We also call the Context's draw method within love.draw().
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
