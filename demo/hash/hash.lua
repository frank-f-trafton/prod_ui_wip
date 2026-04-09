-- 'Hash' demo.
-- To run, navigate to the main project directory and invoke:
-- $ love . demo/hash


--[[
This demo is intended to give an example of dropped file events. It will crash when
fed very large files.
--]]


require("lib.test.strict")


love.window.setMode(640, 480, {
	resizable=true,
	minwidth=384,
	minheight=384
})
love.window.setTitle("ProdUI: Hash")


love.graphics.setDefaultFilter("nearest", "nearest")
love.keyboard.setKeyRepeat(true)
love.keyboard.setTextInput(false)


local prodUi = require("prod_ui")


local default_settings = prodUi.res.loadLuaTable("prod_ui/data/default_settings.lua")


local context, wid_root, workspace
do
	context, wid_root = prodUi.context.newContext("prod_ui", default_settings)
	context:setScale(1.0)
	context:setTextureScale(1)

	local theme = context:loadTheme("vacuum_dark")
	context:applyTheme(theme)

	workspace = wid_root:newWorkspace()
	wid_root:setActiveWorkspace(workspace)
end


local app = {
	last_hex_string = false,
	showing_copy_text = false
}


-- * Construct the scene.

do
	local panel = workspace:addChild("base/container_panel")
		:geometrySetMode("remaining")

	-- Initially holds instructions, then shows the filename after a file is dropped.
	local text_top = panel:addChild("wimp/text_block")
		:geometrySetMode("segment", "top")
		:setTag("text-top")
		:setText("Drag a file onto this window to compute its SHA-2 hash.")
		:setFontId("p")
		:setAlign("center")
		:setAutoSize("v")
		:setWrapping(true)

	local hash_text = panel:addChild("wimp/text_block")
		:geometrySetMode("segment", "top")
		:setTag("text-hash")
		:setFontId("h3")
		:setAlign("center")
		:setAutoSize("v")
		:setWrapping(true)

	local copy_text = panel:addChild("wimp/text_block")
		:geometrySetMode("static", 16, 16, 300, 32, false, true)
		:setTag("text-copy")
		:setFontId("p")

	workspace:tryTakeThimble1()
end


--[[
A callback to run whenever a file is dropped onto the window. It can be
assigned to the Root widget, a Workspace or a Window Frame (not used here).

Since this demo has only one state, we may as well assign the callback to the
Root.
--]]


local function _checkFile(self, file)
	-- The usual LÖVE file handling stuff.
	local file_name = file:getFilename()
	file:open("r")
	local data = file:read()
	file:close()

	-- SHA-2 stuff.
	local message_digest = love.data.hash("sha224", data)
	app.last_hex_string = love.data.encode("string", "hex", message_digest)

	-- OK, now find and update the two text widgets.
	local root = self:nodeGetRoot()

	local text_top = root:findTag("text-top")
	if text_top then
		text_top:setText(file_name)
	end

	local text_hash = root:findTag("text-hash")
	if text_hash then
		text_hash:setText(app.last_hex_string)
	end

	-- Set up the "Ctrl+C to copy" text
	if not app.showing_copy_text then
		local text_copy = root:findTag("text-copy")
		if text_copy then
			text_copy:setText("(Ctrl+C to copy)")
		end

		app.showing_copy_text = true
	end

	root:reshape()

	-- Tells the event emitter to stop
	return true
end


wid_root:userCallbackSet("cb_fileDropped", _checkFile)


--[[
We're not dealing with dropped directories in this demo. Nevertheless, give some
kind of feedback in case it happens.
--]]


local function _checkDirectory(self, path)
	app.last_hex_string = false
	app.showing_copy_text = false

	local root = self:nodeGetRoot()

	local text_top = root:findTag("text-top")
	if text_top then
		text_top:setText("I can't do whole directories; drop a file instead.")
	end

	local text_hash = root:findTag("text-hash")
	if text_hash then
		text_hash:setText("")
	end

	local text_copy = root:findTag("text-copy")
	if text_copy then
		text_copy:setText("")
	end

	root:reshape()

	-- Tells the event emitter to stop
	return true
end


wid_root:userCallbackSet("cb_directoryDropped", _checkDirectory)


wid_root:reshape()


-- Keyboard shortcuts
do
	local function _fn_quit(self, key, scancode, isrepeat)
		love.event.quit()
	end

	local shortcuts = {
		["+escape"] = _fn_quit,
		["C+q"] = _fn_quit,

		["C+c"] = function(self, key, scancode, isrepeat)
			if app.last_hex_string then
				love.system.setClipboardText(app.last_hex_string)
			end
		end,
	}
	local hook_pressed = function(self, tbl, key, scancode, isrepeat)
		local key_mgr = self.context.key_mgr
		local mod = key_mgr.mod

		local input_str = prodUi.keyboard.getKeyString(mod["ctrl"], mod["shift"], mod["alt"], mod["gui"], false, key)
		if shortcuts[input_str] then
			shortcuts[input_str](self, key, scancode, isrepeat)
			return true
		end
	end

	table.insert(wid_root.KH_trickle_key_pressed, hook_pressed)
end



function love.filedropped(file)
	context:love_filedropped(file)
end


function love.directorydropped(path)
	context:love_directorydropped(path)
end


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
	context:love_keypressed(kc, sc, rep)
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


-- Uncomment to test the callback directly:
--_checkFile(context.root, love.filesystem.newFile("main.lua"))

