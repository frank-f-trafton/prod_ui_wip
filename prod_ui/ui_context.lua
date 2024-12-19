local uiContext = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local _mcursors_supported = love.mouse.isCursorSupported()


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local cursorMgr = _mcursors_supported and require(REQ_PATH .. "lib.cursor_mgr") or false
local eventHandlers = require(REQ_PATH .. "common.event_handlers")
local hoverLogic = require(REQ_PATH .. "common.hover_logic")
local commonMath = require(REQ_PATH .. "common.common_math")
local keyMgr = require(REQ_PATH .. "lib.key_mgr")
local pUTF8 = require(REQ_PATH .. "lib.pile_utf8")
local uiLoad = require(REQ_PATH .. "ui_load")
local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")
local uiWidget = require(REQ_PATH .. "ui_widget")


local dummyFunc = function() end


local _mt_context = {}
_mt_context.__index = _mt_context
uiContext._mt_context = _mt_context


-- Called first and last in context:love_update():
_mt_context.updateFirst = dummyFunc
_mt_context.updateLast = dummyFunc


-- (Key-down and key-up handling is fed through callbacks in a keyboard manager table.)
local function cb_keyDown(self, kc, sc, rep, latest)
	-- XXX not handling 'latest' for now.

	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_keyPressed and cap_cur:uiCap_keyPressed(kc, sc, rep) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_keyPressed", wid_cur, kc, sc, rep)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_keyPressed", self.tree, kc, sc, rep) -- no ancestors
	end
end


local function cb_keyUp(self, kc, sc)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_keyReleased and cap_cur:uiCap_keyReleased(kc, sc) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_keyReleased", wid_cur, kc, sc)

	-- Nothing is focused: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_keyReleased", self.tree, kc, sc) -- no ancestors
	end
end


local function _loader_lua(file_path, self)
	local chunk = love.filesystem.load(file_path)
	local result = chunk(self, file_path)
	return result
end


--- Create a new UI context object.
-- @param prod_ui_path The file system path to ProdUI (where ui_context.lua is located). Needed so
--	that ProdUI components can pull in additional Lua source files through love.filesystem.load().
-- @param x Context viewport X.
-- @param y Context viewport Y.
-- @param w Context viewport width.
-- @param h Context viewport height.
-- @return The UI context.
function uiContext.newContext(prod_ui_path, x, y, w, h)
	uiShared.type1(1, prod_ui_path, "string")
	uiShared.numberNotNaN(2, x)
	uiShared.numberNotNaN(3, y)
	uiShared.numberNotNaN(4, w)
	uiShared.numberNotNaN(5, h)

	if w < 1 then error("context viewport width must be greater than zero.")
	elseif h < 1 then error("context viewport height must be greater than zero.") end

	-- Default to non-empty paths having a slash on the end.
	if prod_ui_path ~= "" and string.sub(prod_ui_path, -1) ~= "/" then
		prod_ui_path = prod_ui_path .. "/"
	end

	-- Verify the ProdUI path by checking for ui_context.lua.
	-- (Maybe there's a better way to do this...)
	if not love.filesystem.getInfo(prod_ui_path .. "ui_context.lua") then
		error("argument #1: couldn't find ui_context.lua within prod_ui_path.")
	end

	local self = {}

	-- Context config table.
	self.conf = {
		prod_ui_req = REQ_PATH,
		prod_ui_path = prod_ui_path,
	}

	-- Loader cache for shared Lua source files.
	-- For convenience, cache:get() and cache:try() are wrapped as context:getLua() and
	-- context:tryLua().
	local cache_opts = {
		paths = {prod_ui_path},
		extensions = {"lua"},
		owner = self,
	}
	self._shared = uiLoad.new(_loader_lua, cache_opts)

	-- Cache of loaded and prepped widget defs.
	-- defs are of type "table" and serve as the metatable for instances.
	self.widget_defs = {}

	-- Sequence of top-level widget instances associated with this context.
	self.instances = {}

	-- Only one top-level widget may be active (root) at a time.
	self.tree = false

	-- Maintain a stack of top-level widgets to help with layered UI roots and drawing order.
	self.stack = {}

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
	-- hover: cursor hovers over this widget while no mouse buttons are pressed.
	-- pressed: cursor is pressing down on this widget.
	-- drag_dest: cursor hovers over this widget while `current_pressed` is active.
	--   Used for drag-and-drop.
	-- current_thimble: this widget has the keyboard focus.
	-- captured_focus: this widget is in focus capture mode.
	self.current_hover = false
	self.current_pressed = false
	self.current_drag_dest = false
	self.current_thimble = false
	self.captured_focus = false

	-- Window state.
	self.window_focus = false -- love.focus()
	self.window_visible = false -- love.visible()
	self.mouse_focus = false -- love.mousefocus()

	-- The mouse pointer's most recent position. Can be outside the window bounds if the user
	-- clicks in the app and drags outwards.
	self.mouse_x = 0
	self.mouse_y = 0

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

	-- Pixel multiplier for wheelmoved events.
	self.mouse_wheel_scale = 64 -- XXX scaling?

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

	-- Place shared resources (textures, etc.) in a table here.
	self.resources = false

	-- Mouse cursor repository
	if cursorMgr then
		self.cursor_mgr = cursorMgr.newManager(5)
	end

	--[[
	Cursor priority slots:
	1: Busy / wait
	2: Context, high priority
	3: Widget, high priority (press)
	4: Widget, low priority (hover)
	5: Context, low priority (idle pointer)
	--]]

	-- Fields beginning with 'app' or 'usr' are reserved for use by the
	-- host application.

	setmetatable(self, _mt_context)

	return self
end


local function _updateLoop(wid, dt, locks)
	local skip_children

	if wid.userUpdate then
		uiWidget._runUserEvent(wid, "userUpdate", dt)
	end

	if wid.uiCall_update then
		skip_children = wid:uiCall_update(dt)
	end

	if not skip_children and #wid.children > 0 then
		locks[wid] = true

		local i = 1
		local children = wid.children
		local child = children[i]

		while child do
			_updateLoop(child, dt, locks)
			i = i + 1
			child = children[i]
		end

		locks[wid] = nil
	end
end


local function event_virtualMouseRepeat(self, x, y, button, istouch, reps)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_virtualMouseRepeat and cap_cur:uiCap_virtualMouseRepeat(x, y, button, istouch, reps) then
		return
	end

	self.mouse_x = x
	self.mouse_y = y

	hoverLogic.update(self, 0, 0)

	local cur_pres = self.current_pressed

	if cur_pres then
		local a_x, a_y = cur_pres:getAbsolutePosition()
		local m_x = x - a_x
		local m_y = y - a_y

		if cur_pres.click_repeat_oob
		or (m_x >= 0 and m_y >= 0 and m_x < cur_pres.w and m_y < cur_pres.h)
		then
			self.current_pressed:bubbleStatement("uiCall_pointerPressRepeat", self.current_pressed, x, y, button, istouch, reps)
		end
	end
end


--[[
*** WARNING ***

If you use both context:get|tryLua() and require() to access the same source modules, you will end
up with two separate cached versions of the module.

Files which need to be loaded with context:get|tryLua() typically pull in context state from varargs
in the first few lines.
--]]


--- Gets a ProdUI Lua source file, caching it for future calls. Raises an error if the file cannot be
--	loaded.
-- @param file_path The file path. Start at the prod_ui directory, use forward slashes, and omit the
-- '.lua' extension.
-- @return The loaded module.
function _mt_context:getLua(file_path)
	return self._shared:get(file_path)
end


--- Tries to get a Lua source file, caching it for future calls. Returns false plus error message if
--	the file cannot be loaded.
-- @param file_path The file path. Start at the prod_ui directory, use forward slashes, and omit the
-- '.lua' extension.
-- @return The loaded module, or false plus error message if there was a problem.
function _mt_context:tryLua(file_path)
	return self._shared:try(file_path)
end


--- Append an asynchronous action to the UI context, to be run after the main update loop is finished (and after all
--  widget tables are unlocked). This method can only be called during widget update time (ie 'uiCall_update()').
-- @param wid The widget which will perform the action.
-- @param func The function the widget will call (Arguments: widget, params, dt)
-- @param opt A value (presumably a table of parameters) for the function's arg #2. Nil is replaced with false.
-- @return Nothing.
function _mt_context:appendAsyncAction(wid, func, opt)
	if self.async_lock then
		error("async action creation is locked at time of call.")

	elseif type(wid) ~= "table" then
		error("missing widget reference (arg #1) for async action.")

	elseif type(func) ~= "function" then
		error("missing function (arg #2) for async action.")
	end

	local async = self.async

	async[#async + 1] = wid
	async[#async + 1] = func
	async[#async + 1] = opt or false
end


-- * LÖVE Callbacks *


function _mt_context:love_update(dt)
	-- Make virtual input events here.
	-- Mouse
	if self.mouse_pressed_button then
		self.mouse_pressed_dt_acc = self.mouse_pressed_dt_acc + dt
		self.mouse_pressed_ticks = self.mouse_pressed_ticks + 1

		for failsafe = 1, 64 do
			if self.mouse_pressed_dt_acc < self.mouse_pressed_rep_1 then
				break
			end

			self.mouse_pressed_dt_acc = self.mouse_pressed_dt_acc - self.mouse_pressed_rep_2
			self.mouse_pressed_rep_n = self.mouse_pressed_rep_n + 1

			event_virtualMouseRepeat(
				self,
				self.mouse_x,
				self.mouse_y,
				self.mouse_pressed_button,
				false,
				self.mouse_pressed_rep_n
			)
		end
	end

	-- If a widget has captured focus, let it run its own update function now, and optionally deny
	-- updates for the widget tree.
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCall_captureTick and not cap_cur:uiCall_captureTick(dt) then
		return
	end

	self:updateFirst(dt)

	self.locked = true
	self.async_lock = false

	-- Run all other widget update functions.
	if self.tree then
		_updateLoop(self.tree, dt, self.locks)
	end

	-- All widgets should have been unlocked by the end of the update loop.
	if next(self.locks) then
		local count = 0
		for k, v in pairs(self.locks) do
			count = count + 1
		end
		error("UI corruption: " .. count .. " widgets remain locked after the update loop completed.")
	end

	self.locked = false
	self.async_lock = true

	-- Run async (deferred) post-update functions.
	local async = self.async

	for i = 1, #async, 3 do
		local wid = async[i]

		-- Skip widgets that have been purged ('wid' is false).
		if wid then
			local func = async[i + 1]
			local opt = async[i + 2]

			func(wid, opt, dt)
		end
	end

	-- Clean out the table.
	for i = #async, 1, -1 do
		async[i] = nil
	end

	-- Update mouse hover state
	eventHandlers.mousemoved(self, self.mouse_x, self.mouse_y, 0, 0, false)

	-- Update the click-sequence timer.
	if self.cseq_button then
		self.cseq_time = self.cseq_time + dt
	end

	-- Clear the click-sequence state if it has timed out. Only do this if a primary button is not being held.
	if not self.mouse_pressed_button and self.cseq_time >= self.cseq_timeout then
		self:clearClickSequence()
	end

	-- Update cursor state
	if self.cursor_mgr then
		self.cursor_mgr:refreshMouseState(dt)
	end

	self:updateLast(dt)
end


--- Manually clear the mouse click-sequence state.
function _mt_context:clearClickSequence()
	self.cseq_button = false
	self.cseq_presses = 0
	self.cseq_time = 0
	self.cseq_widget = false
end


--- Manually set the mouse click-sequence state. May be useful in cases where a widget contains arbitrary content, and
-- guarding against accidental, drifting double-clicks is desired.
function _mt_context:forceClickSequence(widget, button, n_presses)
	self.cseq_button = button
	self.cseq_presses = n_presses
	self.cseq_time = 0
	self.cseq_widget = widget
end


function _mt_context:love_textinput(text)
	local mod = self.key_mgr.mod

	-- Discard textinput events if LÖVE TextInput is off. This can happen if TextInput was disabled while
	-- there are still pending textinput events in the queue.
	if not love.keyboard.hasTextInput() then
		return

	-- Discard textinput events if the ctrl, alt or gui modkeys are active.
	-- XXX Need to test if this interferes with keyboard macro software.
	-- -> AutoHotKey, Windows 10: seems to temporarily release keys for the duration of the macro.
	elseif mod["ctrl"] or mod["alt"] or mod["gui"] then
		return

	-- In rare cases, a user's system or virtual keyboard may pass in badly-encoded strings as text input.
	-- NOTE: The Lua 5.3-derived utf8.len() doesn't reject surrogate pairs, which will cause an error with
	-- LÖVE's UTF-8 conversion code.
	elseif not pUTF8.check(text) then
		return
	end

	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_textInput and cap_cur:uiCap_textInput(text) then
		return
	end

	-- Any widget has focus: bubble up the textInput event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_textInput", wid_cur, text)

	-- Nothing is focused: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_textInput", self.tree, text) -- no ancestors
	end
end


function _mt_context:love_focus(focus)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_windowFocus and cap_cur.uiCap_windowFocus(focus) then
		return
	end

	self.window_focus = focus

	if self.tree then
		self.tree:runStatement("uiCall_windowFocus", self.tree, focus) -- XXX maybe trickleStatement would be better.
	end
end


function _mt_context:love_visible(visible)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_windowVisible and cap_cur.uiCap_windowVisible(visible) then
		return
	end

	self.window_visible = visible

	if self.tree then
		self.tree:runStatement("uiCall_windowVisible", self.tree, visible)
	end
end


function _mt_context:love_mousefocus(focus)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_mouseFocus and cap_cur:uiCap_mouseFocus(focus) then
		return
	end

	self.mouse_focus = focus

	if self.tree then
		self.tree:runStatement("uiCall_mouseFocus", self.tree, focus) -- XXX maybe trickleStatement would be better.
	end
end


function _mt_context:love_textedited(text, start, length)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_textEdited and cap_cur:uiCap_textEdited(text, start, length) then
		return
	end

	-- XXX not handled yet
end


function _mt_context:love_keypressed(key, scancode, isrepeat)
	self.key_mgr:keyDown(self, key, scancode, isrepeat) -- See cb_keyDown() for logic
end


function _mt_context:love_keyreleased(key, scancode)
	self.key_mgr:keyUp(self, key, scancode) -- See cb_keyUp() for logic
end


function _mt_context:love_wheelmoved(x, y)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_wheelMoved and cap_cur:uiCap_wheelMoved(x, y) then
		return
	end

	hoverLogic.update(self, 0, 0)

	-- Bubble up from the current hover widget.
	if self.current_hover then
		self.current_hover:bubbleStatement("uiCall_pointerWheel", self.current_hover, x, y)
	end
end


function _mt_context:love_mousereleased(x, y, button, istouch, presses)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_mouseReleased and cap_cur:uiCap_mouseReleased(x, y, button, istouch, presses) then
		return
	end

	--[[
	NOTE: The context mouse button state is updated after callbacks are fired.
	This gives uiCall_pointerUnpress / uiCall_pointerRelease a chance to check 'mouse_current_pressed'
	before it is potentially erased.
	--]]

	self.mouse_x = x
	self.mouse_y = y

	local old_current_pressed = self.current_pressed

	-- 'pointerUnpress' triggers even when the mouse cursor is out of bounds of the formerly pressed widget.
	-- 'pointerRelease' does an additional intersection test before firing.
	-- The latter used to rely on a comparison with current_hover, but hover state no longer updates
	-- while any mouse button is held (XXX should maybe just be the primary and auxiliary buttons, as
	-- some mice have a lot of buttons). As a side effect, you can release on a widget which is covered by
	-- other widgets, if you were able to hover over it for the initial down-click.
	if old_current_pressed then
		old_current_pressed:bubbleStatement("uiCall_pointerUnpress", old_current_pressed, x, y, button, istouch, presses)

		local old_x, old_y = old_current_pressed:getAbsolutePosition()
		if commonMath.pointToRect(x, y, old_x, old_y, old_x + old_current_pressed.w, old_y + old_current_pressed.h) then
			old_current_pressed:bubbleStatement("uiCall_pointerRelease", old_current_pressed, x, y, button, istouch, presses)
		end

	elseif self.tree then
		self.tree:runStatement("uiCall_pointerUnpress", self.tree, x, y, button, istouch, presses) -- no ancestors
		self.tree:runStatement("uiCall_pointerRelease", self.tree, x, y, button, istouch, presses) -- no ancestors
	end

	if self.mouse_pressed_button == button then
		-- Clean up Drag-Dest state.
		local old_drag_dest = self.current_drag_dest
		if old_drag_dest then
			old_drag_dest:bubbleStatement("uiCall_pointerDragDestOff", old_drag_dest, x, y, 0, 0)
			old_drag_dest:bubbleStatement("uiCall_pointerDragDestRelease", old_drag_dest, x, y, button, istouch, presses)
			self.current_drag_dest = false
		end

		self.current_pressed = false
		self.mouse_pressed_button = false
		self.mouse_pressed_ticks = 0

		-- Check for click-sequence timeout.
		if self.cseq_time >= self.cseq_timeout then
			self.cseq_button = false
			self.cseq_presses = 0
			self.cseq_time = 0
			self.cseq_widget = false
		end
	end

	self.mouse_buttons[button] = false

	hoverLogic.update(self, 0, 0)
end


function _mt_context:love_mousemoved(x, y, dx, dy, istouch)
	eventHandlers.mousemoved(self, x, y, dx, dy, istouch)
end


function _mt_context:love_mousepressed(x, y, button, istouch, presses)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_mousePressed and cap_cur:uiCap_mousePressed(x, y, button, istouch, presses) then
		return
	end

	self.mouse_x = x
	self.mouse_y = y

	hoverLogic.update(self, 0, 0)

	-- Mouse clicking blocks single 'keypress->keyrelease' actions.
	self.key_mgr:stunRecent()

	-- There should not be an old 'current_pressed' widget.
	-- If there is, ignore it.

	if self.mouse_pressed_button == false then
		self.mouse_pressed_button = button
		self.mouse_pressed_rep_n = 0
		self.mouse_pressed_dt_acc = 0
		self.mouse_pressed_ticks = 0

		self.mouse_pressed_x = x
		self.mouse_pressed_y = y

		local wid_pressed = hoverLogic.checkPressed(self, button, istouch, presses)

		self.current_pressed = wid_pressed or false

		-- Set click-sequence state
		if self.cseq_button == button
		and self.cseq_widget == self.current_pressed
		and x >= self.cseq_x - self.cseq_range
		and x < self.cseq_x + self.cseq_range
		and y >= self.cseq_y - self.cseq_range
		and y < self.cseq_y + self.cseq_range
		then
			self.cseq_presses = self.cseq_presses + 1
			self.cseq_time = 0
		else
			self.cseq_button = button
			self.cseq_presses = 1
			self.cseq_time = 0
			self.cseq_widget = self.current_pressed
		end

		self.cseq_x = x
		self.cseq_y = y

		-- Successful pressing overrides existing hover. Run the hover callbacks before running the pressed callback.
		if wid_pressed then
			local old_hover = self.current_hover
			if old_hover and old_hover ~= wid_pressed then
				-- Hover off
				self.current_hover = false
				old_hover:bubbleStatement("uiCall_pointerHoverOff", old_hover, self.mouse_x, self.mouse_y, 0, 0)

				-- Hover on + move
				self.current_hover = wid_pressed
				wid_pressed:bubbleStatement("uiCall_pointerHoverOn", wid_pressed, self.mouse_x, self.mouse_y, 0, 0)
				wid_pressed:bubbleStatement("uiCall_pointerHoverMove", wid_pressed, self.mouse_x, self.mouse_y, 0, 0)
			end
		end
	end

	self.mouse_buttons[button] = true

	-- The mouse position is relative to the screen because this statement can bubble up through multiple widgets.
	-- Subtract the results of 'widget:getAbsolutePosition()' to get the point relative to a given widget.
	if self.current_pressed then
		self.current_pressed:bubbleStatement("uiCall_pointerPress", self.current_hover, x, y, button, istouch, presses)
	end
end


function _mt_context:love_touchpressed(id, x, y, dx, dy, pressure) -- XXX Not implemented yet
	--
end


function _mt_context:love_touchmoved(id, x, y, dx, dy, pressure) -- XXX Not implemented yet
	--
end


function _mt_context:love_touchreleased(id, x, y, dx, dy, pressure) -- XXX Not implemented yet
	--
end


function _mt_context:love_resize(w, h)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_windowResize and cap_cur:uiCap_windowResize(w, h) then
		return
	end

	if self.tree then
		self.tree:runStatement("uiCall_windowResize", w, h) -- no ancestors
	end
end


function _mt_context:love_joystickadded(joystick) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickAdded and cap_cur:uiCap_joystickAdded(joystick) then
		return
	end

	if self.tree then
		self.tree:runStatement("uiCall_joystickAdded", joystick) -- no ancestors
	end
end


function _mt_context:love_joystickremoved(joystick) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickRemoved and cap_cur:uiCap_joystickRemoved(joystick) then
		return
	end

	if self.tree then
		self.tree:runStatement("uiCall_joystickRemoved", joystick) -- no ancestors
	end
end


function _mt_context:love_joystickpressed(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickPressed and cap_cur:uiCap_joystickPressed(joystick, button) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_joystickPressed", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_joystickPressed", self.tree, joystick, button) -- no ancestors
	end
end


function _mt_context:love_joystickreleased(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickReleased and cap_cur:uiCap_joystickReleased(joystick, button) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_joystickReleased", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_joystickReleased", self.tree, joystick, button) -- no ancestors
	end
end


function _mt_context:love_joystickaxis(joystick, axis, value) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickAxis and cap_cur:uiCap_joystickAxis(joystick, axis, value) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_joystickAxis", wid_cur, joystick, axis, value)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_joystickAxis", self.tree, joystick, axis, value) -- no ancestors
	end
end


function _mt_context:love_joystickhat(joystick, hat, direction) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickHat and cap_cur:uiCap_joystickHat(joystick, hat, direction) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_joystickHat", wid_cur, joystick, hat, direction)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_joystickHat", self.tree, joystick, hat, direction) -- no ancestors
	end
end


function _mt_context:love_gamepadpressed(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_gamepadPressed and cap_cur:uiCap_gamepadPressed(joystick, button) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_gamepadPressed", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_gamepadPressed", self.tree, joystick, button) -- no ancestors
	end
end


function _mt_context:love_gamepadreleased(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_gamepadReleased and cap_cur:uiCap_gamepadReleased(joystick, button) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_gamepadReleased", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_gamepadReleased", self.tree, joystick, button) -- no ancestors
	end
end


function _mt_context:love_gamepadaxis(joystick, axis, value) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_gamepadAxis and cap_cur:uiCap_gamepadAxis(joystick, axis, value) then
		return
	end

	-- Any widget has focus: bubble up the key event
	local wid_cur = self.current_thimble
	if wid_cur then
		wid_cur:bubbleStatement("uiCall_gamepadAxis", wid_cur, joystick, axis, value)

	-- Nothing has focus: send to root widget, if present
	elseif self.tree then
		self.tree:runStatement("uiCall_gamepadAxis", self.tree, joystick, axis, value) -- no ancestors
	end
end


-- * <Unsorted> *


--- Load and register a widget def from a function.
-- @param chunk The function to execute.
-- @param id The ID that this widget def will be referenced by within the UI context.
-- @param def_conf An arbitrary config table for the chunk function.
-- @return The def table. Raises a Lua error if there's an issue with file-handling or parsing and executing the Lua chunk.
function _mt_context:loadWidgetDefFromFunction(chunk, id, def_conf)
	uiShared.type1(1, chunk, "function")
	uiShared.notNilNotFalseNotNaN(2, id)

	if self.widget_defs[id] then
		error("widget ID " .. id .. " is already loaded.")
	end

	local out_def = chunk(self, def_conf) -- args 1 and 2 of '...'

	if type(out_def) ~= "table" then
		error("chunk return value is not of type 'table'. ID: " .. id)
	end

	-- Chain instances to the def, and the def to the widget base metatable.
	out_def._inst_mt = {__index = out_def}
	setmetatable(out_def, uiWidget._mt_widget)

	--print("\tout_def", out_def)
	--print("\tout_def._inst_mt", out_def._inst_mt)

	out_def.id = id
	self.widget_defs[id] = out_def

	-- (later on, when creating instances: setmetatable(instance, def._inst_mt))

	return out_def
end


--- Load and initialize widget def from a file. You will need to register it to the context with an ID in order to create instances without explicitly passing the def table around.
-- @param file_path The file path (using forward slashes, not a 'require()' path) to the .lua source file.
-- @param id The ID that this widget def will be referenced by within the UI context.
-- @param def_conf An arbitrary config table for the chunk function.
-- @return The def table or fab function. Raises a Lua error if there's an issue with file-handling or parsing and executing the Lua chunk.
function _mt_context:loadWidgetDef(file_path, id, def_conf)
	uiShared.type1(1, file_path, "string")
	uiShared.notNilNotFalseNotNaN(2, id)

	local chunk, err = love.filesystem.load(file_path)
	if not chunk then
		error("couldn't load widget def file. Path: '" .. file_path .. "'. Error: " .. err)
	end

	return self:loadWidgetDefFromFunction(chunk, id, def_conf)
end


--- Loads and registers all widgets in a path, using the path and file name without extension as the ID. Note that all .lua files encountered must be widget defs.
-- @param dir_path The base directory to scan.
-- @param recursive If true, scan subdirectories within the base dir.
-- @param id_prepend ("") An optional string to prepend to widget IDs. May help with organization.
-- @param def_conf (false) An optional, arbitrary config table to pass to each chunk to help with configuration.
-- @return Nothing.
function _mt_context:loadWidgetDefsInDirectory(dir_path, recursive, id_prepend, def_conf)
	id_prepend = id_prepend or ""
	def_conf = def_conf or false

	local path_info = love.filesystem.getInfo(dir_path)
	if not path_info then
		error("Can't access widget definition path: " .. tostring(dir_path))
	end

	local source_files = uiRes.enumerate(dir_path, ".lua", recursive)

	for i, file_path in ipairs(source_files) do
		-- Use file path without '.lua' extension as the ID.
		local id = string.match(file_path, "^(.-)%.lua$")
		if not id then
			error("couldn't extract ID from file path: " .. file_path)
		end

		-- ... And snip out the base directory as well.
		local dir_chop = #dir_path + 1
		if string.sub(id, dir_chop, dir_chop) == "/" then
			dir_chop = dir_chop + 1
		end
		id = string.sub(id, dir_chop)

		self:loadWidgetDef(file_path, id, def_conf)
	end
end


local function _unloadFindWidgetByID(wid, id)
	if wid.id == id then
		return wid
	else
		for i, child in ipairs(wid.children) do
			local found = findWidgetByID(child, id)
			if found then
				return found
			end
		end
	end

	return nil
end


--- Unloads (unregisters) a widget def from the UI Context. It's an error if any instances exist in the context at the time of calling.
-- @param id The widget def to unload.
-- @return Nothing.
function _mt_context:_unloadWidgetDef(id)
	for i, instance in ipairs(self.instances) do
		if _unloadFindWidgetByID(instance, id) then
			error("attempt to unload widget def which still has live instances in this context. ID: " .. tostring(id))
		end
	end

	self.widget_defs[id] = nil
end


--- Unloads (unregisters) all widget defs. It's an error if any widget instances exist at all in the context at the time of calling.
-- @return Nothing.
function _mt_context:_unloadAllWidgetDefs()
	for id in pairs(self.widget_defs) do
		self:_unloadWidgetDef(id)
	end
end


--- Get a widget def table based on the registered ID.
-- @param id The widget definition ID. Cannot be NaN.
-- @return the definition table, or nil if nothing is registered by that ID.
function _mt_context:getWidgetDef(id)
	uiShared.notNilNotFalseNotNaN(1, id)

	return self.widget_defs[id]
end


--- Add a top-level widget instance to the context.
--  Locked during update: yes (context)
--	Callbacks:
--	* uiCall_create (run)
-- @param id The widget def ID.
-- @param init_t An optional table the caller may provide as the basis for the instance table. This may be necessary in
--	cases where resources must be provided to the widget before uiCall_create() is called. If no table is provided, a
--	fresh table will be used instead. Note that uiCall_create() may overwrite certain fields depending on how the widget
--	def is written. It's best to only use this in ways that are described by the widget documentation or def code. Do
--	not share the table among multiple instances.
-- @param pos (#children + 1) Where to add the widget within the caller's children array. Must be between 1 and
--	#children + 1.
-- @return A reference to the new instance. The function will raise an error in the event of a problem.
function _mt_context:addWidget(id, init_t, pos)
	uiShared.notNilNotFalseNotNaN(1, id)
	uiShared.typeEval1(2, init_t, "table")
	uiShared.numberNotNaNEval(3, pos)

	if self.locked then
		uiShared.errLockedContext("add top-level instance widget")
	end

	pos = pos or #self.instances + 1
	if pos < 1 or pos > #self.instances + 1 then
		error("position is out of range.")
	end

	local def = self.widget_defs[id]

	if not def then
		error("unregistered widget ID: " .. tostring(id))

	elseif type(def) ~= "table" then
		error("bad type for widget def. ID: " .. tostring(id) .. ". Expected table, got " .. type(def) .. ".")

	else
		init_t = init_t or {}
		uiWidget._initWidgetInstance(init_t, def, self, false)

		table.insert(self.instances, pos, init_t)

		init_t:runStatement("uiCall_create", init_t) -- no ancestors
		uiWidget._runUserEvent(init_t, "userCreate")

		return init_t
	end
end


--- Get the context's current root widget.
-- @return The root widget table, or false if there is no root.
function _mt_context:getRoot()
	return self.tree
end


--- Push a new root instance onto the context tree.
--  Locked during update: yes (context)
-- @param new_root The new root instance.
function _mt_context:pushRoot(new_root)
	uiShared.type1(1, new_root, "table")

	if self.locked then
		uiShared.errLockedContext("push top-level root instance")

	elseif new_root.context ~= self then
		error("new root doesn't belong to this context.")

	elseif new_root.parent then
		error("only top-level widget instances can become the context root.")
	end

	local old_root = self.tree

	-- Bank the existing focus state
	if old_root then
		old_root._ctx_banked_current_hover = self.current_hover
		old_root._ctx_banked_current_pressed = self.current_pressed
		old_root._ctx_banked_current_thimble = self.current_thimble
		old_root._ctx_banked_captured_focus = self.captured_focus
	end

	-- Update the focus state
	self.current_hover = new_root._ctx_banked_current_hover or false
	self.current_pressed = new_root._ctx_banked_current_pressed or false
	self.current_thimble = new_root._ctx_banked_current_thimble or false
	self.captured_focus = new_root._ctx_banked_captured_focus or false

	self.stack[#self.stack + 1] = new_root
	self.tree = new_root
	new_root:runStatement("uiCall_rootPush", new_root) -- no ancestors
end


--- Pop the current root off of the context. Safe to call on an empty instance stack.
--  Locked during update: yes (context)
-- @return The popped root widget, or nothing if the stack was empty.
function _mt_context:popRoot()
	-- Assertions
	-- [[
	if self.locked then
		uiShared.errLockedContext("pop top-level root instance")
	end
	--]]

	local stack = self.stack
	if #stack == 0 then
		return nil
	end

	local old_root = self.tree
	if old_root then
		old_root:runStatement("uiCall_rootPop", old_root) -- no ancestors
	end
	stack[#stack] = nil
	self.tree = stack[#stack] or false

	-- Restore the previous focus state, if applicable.
	local new_root = self.tree
	if new_root then
		self.current_hover = new_root._ctx_banked_current_hover or false
		self.current_pressed = new_root._ctx_banked_current_pressed or false
		self.current_thimble = new_root._ctx_banked_current_thimble or false
		self.captured_focus = new_root._ctx_banked_captured_focus or false
	else
		self.current_hover = false
		self.current_pressed = false
		self.current_thimble = false
		self.captured_focus = false
	end

	return old_root
end


--- Set or clear the top-level widget as the root and top of the stack, by popping the existing root (if applicable) and pushing this one onto it.
--  Locked during update: yes (context)
--	Callbacks:
--	* uiCall_rootPop() -> the popped widget, if applicable.
--	* uiCall_rootPush() -> the newly pushed root widget, if applicable.
--	NOTE: calling setRoot() on the current-root widget will fire both callbacks on it.
-- @param instance The widget table which should become the new root (must be owned by the context). Pass nil/false to unset the current root.
-- @return The old root widget, or nil if the stack was empty.
function _mt_context:setRoot(instance)
	local old_root = self:popRoot()
	self:pushRoot(instance)

	return old_root
end


--- Like wid:releaseThimble(), but with fewer restrictions.
function _mt_context:clearThimble()
	if self.current_thimble then
		local temp_thimble = self.current_thimble
		self.current_thimble = false
		temp_thimble:bubbleStatement("uiCall_thimbleRelease", self)
	end
end


-- Depth-first widget tag search.
function _mt_context:findTag(str)
	for i, instance in ipairs(self.instances) do
		if instance.tag == str then
			return instance, i
		else
			local ret1, ret2 = instance:findTag(str)
			if ret1 then
				return ret1, ret2
			end
		end
	end
end


function _mt_context:setCursorHigh(id)
	if self.cursor_mgr then
		self.cursor_mgr:assignCursor(id, 2)
	end
end


function _mt_context:getCursorHigh()
	if self.cursor_mgr then
		return self.cursor_mgr:getCursorID(2)
	else
		return false
	end
end


function _mt_context:setCursorLow(id)
	if self.cursor_mgr then
		self.cursor_mgr:assignCursor(id, 5)
	end
end


function _mt_context:getCursorLow()
	if self.cursor_mgr then
		return self.cursor_mgr:getCursorID(5)
	else
		return false
	end
end


--- Move The context's 'current_hover' and/or 'current_pressed' state to another widget. Intended for special use
--  cases, between compatible widgets, within 'uiCall_pointerDrag' callbacks. The widgets must be programmed to
--  correctly deal with the transfer. See source code for notes, including which callbacks are fired and which
--  are skipped.
-- @param wid The widget to transfer hover and/or pressed state to.
-- @return Nothing.
function _mt_context:transferPressedState(wid)
	--print(debug.traceback())

	if not wid then
		error("attempt to transfer pressed state to false/nil reference.")

	elseif not self.current_pressed then
		error("no widget to transfer pressed state from. ('context.current_pressed' is false)")

	elseif not wid.allow_hover then
		error("destination widget doesn't allow hover+press state. ('self.allow_hover' is false)")
	end

	--[[
	Callbacks triggered:
	* uiCall_pointerHoverOff() for the old hover.
	* uiCall_pointerHoverOn() for the new hover.

	Not triggered:
	* uiCall_pointerUnpress() for the old pressed widget.
	* uiCall_pointerRelease() for the old pressed widget.
	* uiCall_pointerPress() for the new pressed widget.

	uiCall_pointerDrag() should happen -- soon-ish -- as a result of hoverLogic being called in the context update
	function.
	--]]

	local old_hover = self.current_hover

	self.current_hover = false
	if old_hover then
		old_hover:bubbleStatement("uiCall_pointerHoverOff", old_hover, self.mouse_x, self.mouse_y, 0, 0)
	end

	self.current_hover = wid
	wid:bubbleStatement("uiCall_pointerHoverOn", wid, self.mouse_x, self.mouse_y, 0, 0)

	self.current_pressed = wid
end


--- Check if the UI Context is currently locked for updating.
function _mt_context:isLocked()
	return not not self.locked
end


--- Check if the UI Context async updates are locked.
function _mt_context:isAsyncLocked()
	return not not self.async_lock
end


return uiContext
