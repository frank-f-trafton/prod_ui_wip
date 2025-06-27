local uiContext = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local _mcursors_supported = love.mouse.isCursorSupported()


-- ProdUI
local cursorMgr = _mcursors_supported and require(REQ_PATH .. "lib.cursor_mgr") or false
local keyMgr = require(REQ_PATH .. "lib.key_mgr")
local pTable = require(REQ_PATH .. "lib.pile_table")
local uiLoad = require(REQ_PATH .. "ui_load")
local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")


-- (Key-down and key-up handling is fed through callbacks in a keyboard manager table.)
local function cb_keyDown(self, kc, sc, rep, latest, hot_kc, hot_sc)
	-- XXX not handling 'latest' for now.

	--print("hot_kc", hot_kc, "hot_sc", hot_sc)

	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_keyPressed and cap_cur:uiCap_keyPressed(kc, sc, rep, hot_kc, hot_sc) then
		return
	end

	-- Any widget has thimble focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_keyPressed", wid_cur, kc, sc, rep, hot_kc, hot_sc)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_keyPressed", self.root, kc, sc, rep, hot_kc, hot_sc) -- no ancestors
	end
end


local function cb_keyUp(self, kc, sc)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_keyReleased and cap_cur:uiCap_keyReleased(kc, sc) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_keyReleased", wid_cur, kc, sc)

	-- Nothing is focused: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_keyReleased", self.root, kc, sc) -- no ancestors
	end
end


local _path_stack = {}
local function _loader_lua(self, file_path)
	uiShared.type1(2, file_path, "string")

	for i, v in ipairs(_path_stack) do
		if v == file_path then
			local temp = pTable.copyArray(_path_stack)
			pTable.clearArray(_path_stack)
			pTable.reverseArray(temp)
			error("circular file dependency. This path: " .. tostring(file_path) .. "\n\nPath stack:\n\t" .. table.concat(temp, "\n\t"))
		end
	end

	table.insert(_path_stack, file_path)

	local chunk, err = love.filesystem.load(self.conf.prod_ui_path .. file_path .. ".lua")
	if not chunk then
		return false, err
	end

	local rv = chunk(self, file_path)

	table.remove(_path_stack)

	return rv
end


--[[
context:getLua() and context:tryLua() are similar to require(), but they use forward slashes for directory separators,
and they pass the UI context table through varargs. The modules are cached inside of `context._shared`, with file paths as
keys.

Each context will have its own cached instance of a module. Avoid using both getLua() and require() on the same file.
--]]


local function _getLua(self, file_path)
	return self._shared:get(file_path)
end


local function _tryLua(self, file_path)
	return self._shared:try(file_path)
end


--- Create a new UI context object.
-- @param prod_ui_path The file system path to ProdUI (where ui_context.lua is located). Needed so
--	that ProdUI components can pull in additional Lua source files through love.filesystem.load().
-- @param settings Table of settings. Usage depends on the front end. If not provided, an empty
--	table will be provisioned.
-- @return The UI context.
function uiContext.newContext(prod_ui_path, settings)
	uiShared.type1(1, prod_ui_path, "string")
	uiShared.typeEval1(2, settings, "table")

	-- Ensure that 'prod_ui_path' ends in a slash so that it doesn't need to be
	-- appended upon later use.
	if prod_ui_path ~= "" and string.sub(prod_ui_path, -1) ~= "/" then
		prod_ui_path = prod_ui_path .. "/"
	end

	-- Verify the ProdUI path by checking for ui_context.lua.
	-- (Maybe there's a better way to do this...)
	if not love.filesystem.getInfo(prod_ui_path .. "ui_context.lua") then
		error("argument #1: couldn't find ui_context.lua within prod_ui_path.")
	end

	local self = {}

	-- UI scale. Affects font sizes, preferred dimensions of widgets, layouts, etc.
	self.scale = 1.0

	-- DPI class. Determines which set of textures and associated metadata to load.
	-- Should be an integer.
	self.dpi = 96

	-- When false, no theme is loaded.
	self.theme_id = false

	self.path_symbols = {
		[""] = "%", -- escapes '%%' to '%'
		produi = prod_ui_path:sub(1, -2),
		resources = prod_ui_path .. "resources",
		dpi = tostring(self.dpi),
	}

	-- Context config table. Internal use.
	self.conf = {
		prod_ui_req = REQ_PATH,
		prod_ui_path = prod_ui_path,
	}

	-- Usage of the settings table depends on the front-end.
	self.settings = settings or {}

	-- Passed as the settings argument when creating new layer canvases.
	self.canvas_settings = {}

	-- Stack of canvases used for tint/fade layering.
	self.canvas_layers = {}
	self.canvas_layers_i = 0
	self.canvas_layers_max = 32

	-- Cache of loaded and prepped widget defs.
	-- defs are of type "table" and serve as the metatable for instances.
	self.widget_defs = {}

	self.skinners = {}

	-- The root widget must be created as soon as possible.
	self.root = false

	-- Some context actions are locked during the update function.
	self.locked = false

	-- Table of locked widgets. Prevents some actions that would corrupt the widget tree
	-- during update time.
	-- Note that this can't catch all issues (such as the mistake of removing entries from
	-- a table while also iterating first-to-last with 'for'.)
	self.locks = {}

	-- Table of async actions to run after the widget update loop.
	self.async = {}

	-- Creation of new async actions is only permitted during the widget update loop.
	self.async_lock = true

	-- Focus state. These point to widget tables when active, and are false otherwise.
	-- * hover: the cursor hovers over this widget while no mouse buttons are pressed.
	-- * pressed: the cursor is pressing down on this widget.
	-- * drag_dest: the cursor hovers over this widget while `current_pressed` is active.
	--   Used for drag-and-drop.
	-- * thimble1: a "concrete" widget that has keyboard focus.
	-- * thimble2: an "ephemeral" widget that has keyboard focus. Takes priority over 'thimble1'.
	-- * captured_focus: this widget is in focus capture mode.
	self.current_hover = false
	self.current_pressed = false
	self.current_drag_dest = false
	self.thimble1 = false
	self.thimble2 = false
	self.captured_focus = false

	-- Window state.
	self.window_focus = false -- love.focus()
	self.window_visible = false -- love.visible()
	self.mouse_focus = false -- love.mousefocus()

	-- When populated with a widget table, mouse hover and press state checks
	-- begin here. When false, they begin at the root.
	-- Note that while this prevents some events from emitting, it does not affect the
	-- overall propagation of events (that is, they can still trickle and bubble through
	-- the root).
	self.mouse_start = false

	-- The mouse pointer's most recent position. Can be outside the window bounds if the user
	-- clicks in the app and drags outwards.
	self.mouse_x = 0
	self.mouse_y = 0

	-- When true, 'wheelmoved' events target the current top thimble rather than the
	-- currently hovered widget.
	self.wheelmoved_to_thimble = false

	--[[
	XXX: ^ LÖVE 11.5+ will clamp to window bounds.
	https://github.com/love2d/love/commit/e582677344954d43369fb1a16a520b75c610cb0a
	--]]

	-- State of all mouse buttons (hash of booleans).
	self.mouse_buttons = {}

	-- The mouse button pressed when 'current_pressed' was assigned.
	-- When pressing multiple buttons, the first button to overwrite 'false' gets priority.
	self.mouse_pressed_button = false

	-- Mouse pointer location when 'mouse_pressed_button' was assigned.
	-- Used by some drag-and-drop logic.
	-- Valid only when 'mouse_pressed_button' is active.
	self.mouse_pressed_x = 0
	self.mouse_pressed_y = 0

	-- How far the mouse pointer should be dragged before initiating a drag-and-drop transaction.
	-- Note that this value is not universal: widgets may have their own ranges, or pull in values
	-- from the theme table.
	self.mouse_pressed_range = 16 -- (x - range, x + range; y - range, y + range)

	-- Internal use. Accumulates delta time as part of determining virtual repeat mouse-press actions.
	self.mouse_pressed_dt_acc = 0

	-- Number of ticks that 'mouse_pressed_button' has been active for.
	-- 0 == not held, 1 == pressed on this tick, 2 == pressed on the last tick, etc.
	self.mouse_pressed_ticks = 0

	-- Hints for repeating actions associated with pressing and holding mouse buttons.
	-- Primarily used for mouse click-repeat virtual events, but you could use them
	-- elsewhere, such as in capture-tick callbacks related to the mouse in some way.
	-- Time in seconds to wait before firing repeat mouse-press actions.
	self.mouse_pressed_rep_1 = 1/4

	-- Time in seconds between repeat mouse-press actions.
	self.mouse_pressed_rep_2 = 1/16

	-- Number of repeated mouse-press actions.
	self.mouse_pressed_rep_n = 0

	-- cseq: "click-sequence" state, used to implement widget-aware multi-click actions.
	-- Aims to prevent unintentional double-clicks, such as when clicking on two different
	-- widgets in a short span of time.

	-- The sequence button number, or false if not currently in a click-sequence.
	self.cseq_button = false

	-- Number of presses in the sequence detected.
	self.cseq_presses = 0

	-- Time in seconds since the last click.
	self.cseq_time = 0

	-- The timeout for the click-sequence.
	self.cseq_timeout = 0.5

	-- The widget being clicked.
	self.cseq_widget = false

	-- Location of the last click, and the max range in which clicks should be considered
	-- part of the same click-sequence. Only valid while a click-sequence is active.
	self.cseq_x = 0
	self.cseq_y = 0
	self.cseq_range = 32 -- (x - range, x + range; y - range, y + range)

	-- Keyboard input manager
	self.key_mgr = keyMgr.newManager()
	self.key_mgr.cb_keyDown = cb_keyDown
	self.key_mgr.cb_keyUp = cb_keyUp

	-- Mouse cursor state.
	if cursorMgr then
		self.cursor_mgr = cursorMgr.newManager(4)
	end

	self.cursor_low = false
	self.cursor_high = false

	-- Cache for shared Lua source files.
	-- For convenience, cache:get() and cache:try() are wrapped as context:getLua() and
	-- context:tryLua() in the metatable.
	self._shared = uiLoad.new(self, _loader_lua)

	self.getLua = _getLua
	self.tryLua = _tryLua

	local _mt_context = self:getLua("core/_mt_context")
	setmetatable(self, _mt_context)

	-- Resources. See context_resources.lua for more info.
	self.resources = self:_initResourcesTable()

	self._mt_widget = self:getLua("core/_mt_widget")

	-- Fields beginning with 'app' or 'usr' are reserved for use by the
	-- host application.

	return self
end


return uiContext
