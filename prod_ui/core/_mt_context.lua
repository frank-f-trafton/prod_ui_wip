-- To load: local lib = context:getLua("shared/lib")


local _mt_context = {}
_mt_context.__index = _mt_context


-- Warning! In this file and at this scope, the context is only partially initialized.
-- * It's safe to reference 'conf.prod_ui_req' and 'conf.prod_ui_path'.
-- * 'context:getLua()' and 'context:tryLua()' are safe, having been attached to the context
--   instance rather than the metatable.
local context = select(1, ...)


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local contextDraw = context:getLua("core/context_draw")
local contextResources = context:getLua("core/context_resources")
local mouseLogic = require(context.conf.prod_ui_req .. "core.mouse_logic")
local pUTF8 = require(context.conf.prod_ui_req .. "lib.pile_utf8")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


_mt_context.draw = contextDraw.draw


-- Called first and last in context:love_update():
_mt_context.updateFirst = uiShared.dummyFunc
_mt_context.updateLast = uiShared.dummyFunc


local function _updateLoop(wid, dt, locks)
	if wid.awake then
		local skip_children

		if wid.userUpdate then
			wid:_runUserEvent("userUpdate", dt)
		end

		if wid.uiCall_update then
			skip_children = wid:uiCall_update(dt)
		end

		if not skip_children and #wid.children > 0 then
			locks[wid] = true

			local children = wid.children
			local i = 1

			while i <= #children do
				_updateLoop(children[i], dt, locks)
				i = i + 1
			end

			locks[wid] = nil
		end
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

	mouseLogic.checkHover(self, 0, 0)

	local cur_pres = self.current_pressed

	if cur_pres then
		-- If necessary, the widget needs to check if the pointer is in bounds.
		-- We don't check that here, because what is "in bounds" depends on the
		-- widget's design.
		self.current_pressed:cycleEvent("uiCall_pointerPressRepeat", self.current_pressed, x, y, button, istouch, reps)
	end
end


local function event_mousemoved(context, x, y, dx, dy, istouch)
	-- Update mouse position
	context.mouse_x = x
	context.mouse_y = y

	-- Update click-sequence origin if the mouse is being held.
	if context.mouse_pressed_button then
		context.cseq_x = x
		context.cseq_y = y
	end

	-- Event capture
	local cap_cur = context.captured_focus
	if cap_cur and cap_cur.uiCap_mouseMoved and cap_cur:uiCap_mouseMoved(x, y, dx, dy, istouch) then
		return
	end

	mouseLogic.checkHover(context, dx, dy)
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


function _mt_context:getActiveThimble()
	return self.thimble2 or self.thimble1
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
	if self.root then
		_updateLoop(self.root, dt, self.locks)
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
	event_mousemoved(self, self.mouse_x, self.mouse_y, 0, 0, false)

	-- Update the click-sequence timer.
	if self.cseq_button then
		self.cseq_time = self.cseq_time + dt
	end

	-- Clear the click-sequence state if it has timed out. Only do this if a primary button is not being held.
	if not self.mouse_pressed_button and self.cseq_time >= self.cseq_timeout then
		self:clearClickSequence()
	end

	-- Update cursor state
	local cursor_mgr = self.cursor_mgr
	if cursor_mgr then
		cursor_mgr:assignCursor(self.cursor_low, 4)

		if self.current_hover then
			local _, k = self.current_hover:findAscendingKey("cursor_hover")
			cursor_mgr:assignCursor(k, 3)
		else
			cursor_mgr:assignCursor(false, 3)
		end

		if self.current_pressed then
			local _, k = self.current_pressed:findAscendingKey("cursor_press")
			cursor_mgr:assignCursor(k, 2)
		else
			cursor_mgr:assignCursor(false, 2)
		end

		cursor_mgr:assignCursor(self.cursor_high, 1)

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

	-- Any widget has focus: emit a textInput event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_textInput", wid_cur, text)

	-- Nothing is focused: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_textInput", self.root, text) -- no ancestors
	end
end


function _mt_context:love_focus(focus)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_windowFocus and cap_cur.uiCap_windowFocus(focus) then
		return
	end

	self.window_focus = focus

	if self.root then
		self.root:sendEvent("uiCall_windowFocus", focus)
	end
end


function _mt_context:love_visible(visible)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_windowVisible and cap_cur.uiCap_windowVisible(visible) then
		return
	end

	self.window_visible = visible

	if self.root then
		self.root:sendEvent("uiCall_windowVisible", visible)
	end
end


function _mt_context:love_mousefocus(focus)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_mouseFocus and cap_cur:uiCap_mouseFocus(focus) then
		return
	end

	self.mouse_focus = focus

	if self.root then
		self.root:sendEvent("uiCall_mouseFocus", focus)
	end
end


--[[
function _mt_context:love_textedited(text, start, length)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_textEdited and cap_cur:uiCap_textEdited(text, start, length) then
		return
	end

	-- XXX not handled yet
end
--]]


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

	mouseLogic.checkHover(self, 0, 0)

	if self.wheelmoved_to_thimble then
		local wid = self.thimble2 or self.thimble1
		if wid then
			wid:cycleEvent("uiCall_pointerWheel", wid, x, y)
		end

	elseif self.current_hover then
		self.current_hover:cycleEvent("uiCall_pointerWheel", self.current_hover, x, y)
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
		old_current_pressed:cycleEvent("uiCall_pointerUnpress", old_current_pressed, x, y, button, istouch, presses)

		local old_x, old_y = old_current_pressed:getAbsolutePosition()
		if commonMath.pointInRect(x, y, old_x, old_y, old_x + old_current_pressed.w, old_y + old_current_pressed.h) then
			old_current_pressed:cycleEvent("uiCall_pointerRelease", old_current_pressed, x, y, button, istouch, presses)
		end

	elseif self.root then
		self.root:sendEvent("uiCall_pointerUnpress", self.root, x, y, button, istouch, presses) -- no ancestors
		self.root:sendEvent("uiCall_pointerRelease", self.root, x, y, button, istouch, presses) -- no ancestors
	end

	if self.mouse_pressed_button == button then
		-- Clean up Drag-Dest state.
		local old_drag_dest = self.current_drag_dest
		if old_drag_dest then
			old_drag_dest:cycleEvent("uiCall_pointerDragDestOff", old_drag_dest, x, y, 0, 0)
			old_drag_dest:cycleEvent("uiCall_pointerDragDestRelease", old_drag_dest, x, y, button, istouch, presses)
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

	mouseLogic.checkHover(self, 0, 0)
end


function _mt_context:love_mousemoved(x, y, dx, dy, istouch)
	event_mousemoved(self, x, y, dx, dy, istouch)
end


function _mt_context:love_mousepressed(x, y, button, istouch, presses)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_mousePressed and cap_cur:uiCap_mousePressed(x, y, button, istouch, presses) then
		return
	end

	self.mouse_x = x
	self.mouse_y = y

	mouseLogic.checkHover(self, 0, 0)

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

		local wid_pressed = mouseLogic.checkPressed(self, button, istouch, presses)

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
				old_hover:cycleEvent("uiCall_pointerHoverOff", old_hover, self.mouse_x, self.mouse_y, 0, 0)

				-- Hover on + move
				self.current_hover = wid_pressed
				wid_pressed:cycleEvent("uiCall_pointerHoverOn", wid_pressed, self.mouse_x, self.mouse_y, 0, 0)
				wid_pressed:cycleEvent("uiCall_pointerHover", wid_pressed, self.mouse_x, self.mouse_y, 0, 0)
			end
		end
	end

	self.mouse_buttons[button] = true

	if self.current_pressed then
		self.current_pressed:cycleEvent("uiCall_pointerPress", self.current_pressed, x, y, button, istouch, presses)
	end
end


--[[
function _mt_context:love_touchpressed(id, x, y, dx, dy, pressure) -- XXX Not implemented yet
	--
end
--]]


--[[
function _mt_context:love_touchmoved(id, x, y, dx, dy, pressure) -- XXX Not implemented yet
	--
end
--]]


--[[
function _mt_context:love_touchreleased(id, x, y, dx, dy, pressure) -- XXX Not implemented yet
	--
end
--]]


function _mt_context:love_resize(w, h)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_windowResize and cap_cur:uiCap_windowResize(w, h) then
		return
	end

	if self.root then
		self.root:sendEvent("uiCall_windowResize", w, h) -- no ancestors
	end
end


function _mt_context:love_joystickadded(joystick) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickAdded and cap_cur:uiCap_joystickAdded(joystick) then
		return
	end

	if self.root then
		self.root:sendEvent("uiCall_joystickAdded", joystick) -- no ancestors
	end
end


function _mt_context:love_joystickremoved(joystick) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickRemoved and cap_cur:uiCap_joystickRemoved(joystick) then
		return
	end

	if self.root then
		self.root:sendEvent("uiCall_joystickRemoved", joystick) -- no ancestors
	end
end


function _mt_context:love_joystickpressed(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickPressed and cap_cur:uiCap_joystickPressed(joystick, button) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_joystickPressed", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_joystickPressed", self.root, joystick, button) -- no ancestors
	end
end


function _mt_context:love_joystickreleased(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickReleased and cap_cur:uiCap_joystickReleased(joystick, button) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_joystickReleased", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_joystickReleased", self.root, joystick, button) -- no ancestors
	end
end


function _mt_context:love_joystickaxis(joystick, axis, value) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickAxis and cap_cur:uiCap_joystickAxis(joystick, axis, value) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_joystickAxis", wid_cur, joystick, axis, value)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_joystickAxis", self.root, joystick, axis, value) -- no ancestors
	end
end


function _mt_context:love_joystickhat(joystick, hat, direction) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_joystickHat and cap_cur:uiCap_joystickHat(joystick, hat, direction) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_joystickHat", wid_cur, joystick, hat, direction)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_joystickHat", self.root, joystick, hat, direction) -- no ancestors
	end
end


function _mt_context:love_gamepadpressed(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_gamepadPressed and cap_cur:uiCap_gamepadPressed(joystick, button) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_gamepadPressed", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_gamepadPressed", self.root, joystick, button) -- no ancestors
	end
end


function _mt_context:love_gamepadreleased(joystick, button) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_gamepadReleased and cap_cur:uiCap_gamepadReleased(joystick, button) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_gamepadReleased", wid_cur, joystick, button)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_gamepadReleased", self.root, joystick, button) -- no ancestors
	end
end


function _mt_context:love_gamepadaxis(joystick, axis, value) -- XXX untested
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_gamepadAxis and cap_cur:uiCap_gamepadAxis(joystick, axis, value) then
		return
	end

	-- Any widget has focus: cycle the key event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_gamepadAxis", wid_cur, joystick, axis, value)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_gamepadAxis", self.root, joystick, axis, value) -- no ancestors
	end
end


function _mt_context:love_filedropped(file)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_fileDropped and cap_cur:uiCap_fileDropped(file) then
		return
	end

	-- Any widget has focus: cycle the event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_fileDropped", wid_cur, file)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_fileDropped", self.root, file) -- no ancestors
	end
end


function _mt_context:love_directorydropped(path)
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_directoryDropped and cap_cur:uiCap_directoryDropped(file) then
		return
	end

	-- Any widget has focus: cycle the event
	local wid_cur = self.thimble2 or self.thimble1
	if wid_cur then
		wid_cur:cycleEvent("uiCall_directoryDropped", wid_cur, file)

	-- Nothing has focus: send to root widget, if present
	elseif self.root then
		self.root:sendEvent("uiCall_directoryDropped", self.root, file) -- no ancestors
	end
end


function _mt_context:love_quit()
	-- Event capture
	local cap_cur = self.captured_focus
	if cap_cur and cap_cur.uiCap_quit and cap_cur:uiCap_quit() then
		return
	end

	-- Send to root; return root's response to the love.quit() handler.
	if self.root then
		return self.root:sendEvent("uiCall_quit", self.root)
	end
end


-- * <Unsorted> *


--- Load and register a widget def from a function.
-- @param chunk The function to execute.
-- @param id The ID that this widget def will be referenced by within the UI context.
-- @param def_conf An arbitrary config table for the chunk function.
-- @return The def table. Raises a Lua error if there's an issue with file handling, or parsing and executing the Lua
--	chunk.
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
	setmetatable(out_def, self._mt_widget)

	out_def.id = id
	out_def.default_settings = out_def.default_settings or {}

	if out_def.default_skinner then
		print("self.resources", self.resources)
		if not self.resources then
			error("a theme resource table must be instantiated to use widget default skinners.")
		end
		self:registerSkinnerTable(out_def.default_skinner, id)
	end

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
function _mt_context:loadWidgetDefsInDirectory(dir_path, recursive, id_prepend, def_conf)
	id_prepend = id_prepend or ""
	def_conf = def_conf or false

	local source_files = uiRes.enumerate(dir_path, ".lua", recursive)

	for i, file_path in ipairs(source_files) do
		local id = id_prepend .. uiRes.extractIDFromLuaFile(dir_path, file_path)
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
end


--- Unloads (unregisters) a widget def from the UI Context. It's an error if any instances exist within the context at
--	the time of calling.
-- @param id The widget def to unload.
-- @return Nothing.
function _mt_context:_unloadWidgetDef(id)
	if not self.widget_defs[id] then
		error("no widget definition with this ID: " .. tostring(id))
	end

	if self.root and _unloadFindWidgetByID(self.root, id) then
		error("attempt to unload widget def which still has live instances in this context. ID: " .. tostring(id))
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


--- Sets up a new widget instance table. Internal use.
function _mt_context:_prepareWidgetInstance(id, parent)
	local def = self.widget_defs[id]

	-- Unsupported type. (Corrupt widget defs collection?)
	if type(def) ~= "table" then
		error("unregistered ID or unsupported type for widget def (id: " .. tostring(id) .. ", type: " .. type(def) .. ")")
	end

	local inst = {}

	inst.parent = parent
	inst.settings = def.default_settings and {}

	setmetatable(inst, def._inst_mt)

	if not inst._no_descendants then
		inst.children = {}
	end

	return inst
end


--- Add a root widget to the context. There must not be an existing root.
--  Locked during update: yes (context)
-- @param id The widget def ID.
-- @return A reference to the new root instance.
function _mt_context:addRoot(id)
	uiShared.notNilNotFalseNotNaN(1, id)

	if self.locked then
		uiShared.errLockedContext("add root widget")
	end

	if self.root then
		error("this context already has a root widget.")
	end

	local retval = self:_prepareWidgetInstance(id, nil)
	self.root = retval
	return retval
end


--- Get the context's current root widget.
-- @return The root widget table, or false if there is no root.
function _mt_context:getRoot()
	return self.root
end


--- Registers a skinner.
-- @param skinner The skinner table.
-- @param id The skinner's ID. Can be a string or a number.
function _mt_context:registerSkinnerTable(skinner, id)
	uiShared.type1(1, skinner, "table")
	uiShared.type1(2, id, "string", "number")

	uiRes.assertNotRegistered("skinner", self.skinners, id)

	self.skinners[id] = skinner
end


--- Loads a skinner from a file and registers it.
-- @param file_path The path to the Lua file.
-- @param id The skinner's ID. Can be a string or a number.
function _mt_context:loadSkinner(file_path, id)
	uiShared.type1(1, file_path, "string")
	uiShared.type1(2, id, "string", "number")

	uiRes.assertNotRegistered("skinner", self.skinners, id)

	local skinner = uiRes.loadLuaFile(file_path, self)
	self.skinners[id] = skinner
end


function _mt_context:loadSkinnersInDirectory(dir_path, recursive, id_prepend)
	id_prepend = id_prepend or ""

	local source_files = uiRes.enumerate(dir_path, ".lua", recursive)

	for i, file_path in ipairs(source_files) do
		local id = id_prepend .. uiRes.extractIDFromLuaFile(dir_path, file_path)
		self:loadSkinner(file_path, id)
	end
end


function _mt_context:releaseThimbles()
	if self.thimble2 then
		self.thimble2:releaseThimble2()
	end
	if self.thimble1 then
		self.thimble1:releaseThimble1()
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

	uiCall_pointerDrag() should happen -- soon-ish -- as a result of mouseLogic being called in the context update
	function.
	--]]

	local old_hover = self.current_hover

	self.current_hover = false
	if old_hover then
		old_hover:cycleEvent("uiCall_pointerHoverOff", old_hover, self.mouse_x, self.mouse_y, 0, 0)
	end

	self.current_hover = wid
	wid:cycleEvent("uiCall_pointerHoverOn", wid, self.mouse_x, self.mouse_y, 0, 0)

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


function _mt_context:setScale(scale)
	uiShared.numberNotNaN(1, scale)

	self.scale = math.max(0.1, math.min(scale, 10.0))
end


function _mt_context:getScale()
	return self.scale
end


function _mt_context:setDPI(dpi)
	uiShared.numberNotNaN(1, dpi)

	self.dpi = math.max(1, dpi)
	self.path_symbols.dpi = tostring(self.dpi)
end


function _mt_context:getDPI()
	return self.dpi
end


contextResources.attachMethods(_mt_context)


return _mt_context
