-- Version 0.0.1b5 (Beta)


local keyMgr = {}


--[[
	KeyConstants and Scancodes are passed along in callbacks, and you can query the state of a Scancode via its
	matching KeyConstant, but the internal representation of each key revolves around Scancodes. The only exception
	is modifier key state (self.mod), which is based on KeyConstants.

	TODO: The behavior described below probably depends on the desktop environment in use, the version of SDL, etc.
	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	On Linux, 'isrepeat' normally doesn't trigger for ctrl, shift and alt. It may trigger sometimes, if the user
	presses the key on the very first application frame, or while using the mouse to drag or resize the window. It can
	be duplicated by sleeping for a second on the first frame and holding the ctrl, shift or alt keys.

	On Windows, 'isrepeat' does trigger for ctrl, shift and alt.

	On Linux, if a given frame is excessively long, repeated key-down events can occur multiple times per frame.
	On Windows, key-repeat events are limited to one per frame.
	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	Some key-combos may be intercepted by the user's OS, such as gui+l to lock the computer.

	As love.keyboard.isDown("unknown") always returns false, 'unknown' key events are discarded.

	Currently, LÖVE 12 modkey state is not tracked here. Use direct calls to `love.keyboard.isModifierActive()` to
	get the modkey state.

	https://love2d.org/wiki/love.keyboard.isModifierActive
	https://love2d.org/wiki/ModifierKey
--]]


local _mt_mgr = {}
_mt_mgr.__index = _mt_mgr


local _getScancodeFromKey = love.keyboard.getScancodeFromKey
local _getKeyFromScancode = love.keyboard.getKeyFromScancode


-- Keep a list of valid scancode string IDs to help with assertions.
-- Valid for: LÖVE 11.4, 11.5
keyMgr.scancodes = {}
do
	-- https://love2d.org/wiki/Scancode
	for i, v in ipairs({
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h",
		"i",
		"j",
		"k",
		"l",
		"m",
		"n",
		"o",
		"p",
		"q",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"0",
		"return",
		"escape",
		"backspace",
		"tab",
		"space",
		"-",
		"=",
		"[",
		"]",
		"\\",
		"nonus#",
		";",
		"'",
		"`",
		",",
		".",
		"/",
		"capslock",
		"f1",
		"f2",
		"f3",
		"f4",
		"f5",
		"f6",
		"f7",
		"f8",
		"f9",
		"f10",
		"f11",
		"f12",
		"f13",
		"f14",
		"f15",
		"f16",
		"f17",
		"f18",
		"f19",
		"f20",
		"f21",
		"f22",
		"f23",
		"f24",
		"lctrl",
		"lshift",
		"lalt",
		"lgui",
		"rctrl",
		"rshift",
		"ralt",
		"rgui",
		"printscreen",
		"scrolllock",
		"pause",
		"insert",
		"home",
		"numlock",
		"pageup",
		"delete",
		"end",
		"pagedown",
		"right",
		"left",
		"down",
		"up",
		"nonusbackslash",
		"application",
		"execute",
		"help",
		"menu",
		"select",
		"stop",
		"again",
		"undo",
		"cut",
		"copy",
		"paste",
		"find",
		"kp/",
		"kp*",
		"kp-",
		"kp+",
		"kp=",
		"kpenter",
		"kp1",
		"kp2",
		"kp3",
		"kp4",
		"kp5",
		"kp6",
		"kp7",
		"kp8",
		"kp9",
		"kp0",
		"kp.",
		"international1",
		"international2",
		"international3",
		"international4",
		"international5",
		"international6",
		"international7",
		"international8",
		"international9",
		"lang1",
		"lang2",
		"lang3",
		"lang4",
		"lang5",
		"mute",
		"volumeup",
		"volumedown",
		"audionext",
		"audioprev",
		"audiostop",
		"audioplay",
		"audiomute",
		"mediaselect",
		"www",
		"mail",
		"calculator",
		"computer",
		"acsearch",
		"achome",
		"acback",
		"acforward",
		"acstop",
		"acrefresh",
		"acbookmarks",
		"power",
		"brightnessdown",
		"brightnessup",
		"displayswitch",
		"kbdillumtoggle",
		"kbdillumdown",
		"kbdillumup",
		"eject",
		"sleep",
		"alterase",
		"sysreq",
		"cancel",
		"clear",
		"prior",
		"return2",
		"separator",
		"out",
		"oper",
		"clearagain",
		"crsel",
		"exsel",
		"kp00",
		"kp000",
		"thsousandsseparator", -- [sic]
		"decimalseparator",
		"currencyunit",
		"currencysubunit",
		"app1",
		"app2",
		"unknown",
	}) do
		keyMgr.scancodes[v] = true
	end
end


-- KeyConstants.
-- Valid for: LÖVE 11.4, 11.5
keyMgr.key_constants = {}
do
	-- https://love2d.org/wiki/KeyConstant
	for i, v in ipairs({
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h",
		"i",
		"j",
		"k",
		"l",
		"m",
		"n",
		"o",
		"p",
		"q",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
		"0",
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"space",
		"!",
		"\"",
		"#",
		"$",
		"&",
		"'",
		"(",
		")",
		"*",
		"+",
		",",
		"-",
		".",
		"/",
		":",
		";",
		"<",
		"=",
		">",
		"?",
		"@",
		"[",
		"\\",
		"]",
		"^",
		"_",
		"`",
		"kp0",
		"kp1",
		"kp2",
		"kp3",
		"kp4",
		"kp5",
		"kp6",
		"kp7",
		"kp8",
		"kp9",
		"kp.",
		"kp,",
		"kp/",
		"kp*",
		"kp-",
		"kp+",
		"kpenter",
		"kp=",
		"up",
		"down",
		"right",
		"left",
		"home",
		"end",
		"pageup",
		"pagedown",
		"insert",
		"backspace",
		"tab",
		"clear",
		"return", -- AKA Enter
		"delete",
		"f1",
		"f2",
		"f3",
		"f4",
		"f5",
		"f6",
		"f7",
		"f8",
		"f9",
		"f10",
		"f11",
		"f12",
		"f13",
		"f14",
		"f15",
		"f16",
		"f17",
		"f18",
		"numlock",
		"capslock",
		"scrolllock",
		"rshift",
		"lshift",
		"rctrl",
		"lctrl",
		"ralt",
		"lalt",
		"rgui",
		"lgui",
		"mode",
		"www",
		"mail",
		"calculator",
		"computer",
		"appsearch",
		"apphome",
		"appback",
		"appforward",
		"apprefresh",
		"appbookmarks",
		"pause",
		"escape",
		"help",
		"printscreen",
		"sysreq",
		"menu",
		"application",
		"power",
		"currencyunit",
		"undo",
	}) do
		keyMgr.key_constants[v] = true
	end
end


-- Mappings for scancodes which are affected by NumLock.
keyMgr.scan_numlock = {
	kp0 = "insert",
	kp1 = "end",
	kp2 = "down",
	kp3 = "pagedown",
	kp4 = "left",
	-- (no mapping for kp5)
	kp6 = "right",
	kp7 = "home",
	kp8 = "up",
	kp9 = "pageup",
	["kp."] = "delete",
}


function keyMgr.assertScancode(sc)
	if not keyMgr.scancodes[sc] then
		error("invalid Scancode: " .. tostring(sc), 2)
	end
end


function keyMgr.assertKeyConstant(kc)
	-- NOTE: This assertion will miss some obscure Scancodes which also count as KeyConstants, like muteaudio.
	if not keyMgr.key_constants[kc] then
		error("invalid KeyConstant: " .. tostring(kc), 2)
	end
end


function keyMgr.assertKey(is_sc, code)
	if is_sc then
		if not keyMgr.scancodes[code] then
			error("invalid Scancode: " .. tostring(code), 2)
		end
	else
		if not keyMgr.key_constants[code] then
			error("invalid KeyConstant: " .. tostring(code), 2)
		end
	end
end


function keyMgr.newManager()
	local self = {}

	-- When true, handles virtual key-repeat events. This should be treated as mutually exclusive to
	-- LÖVE's built-in key-repeat: only one or the other should be enabled at any given time.
	self.virtual_repeat = false

	-- When true, all held keys are processed for key-repeat events.
	-- When false, only 'sc_last' is ticked.
	self.repeat_all = false

	-- Max number of allowed virtual key repeats per frame.
	self.n_virt_reps = 1

	-- When true, use KeyConstants instead of Scancodes for modifier keys.
	-- This may be able to catch special key setups, such as if the user has swapped ctrl and caps lock.
	-- If it interferes / causes conflicts, set to false.
	self.mods_use_kc = true

	-- Hash of held keys by scancode. The value is a number used to implement virtual key-repeats.
	-- A key is held if it evaluates to true.
	self.hash = {}

	-- Current state of modifiers (KeyConstants by default) and merged modifiers.
	self.mod = {
		ctrl = false,
		lctrl = false,
		rctrl = false,

		alt = false,
		lalt = false,
		ralt = false,

		shift = false,
		lshift = false,
		rshift = false,

		gui = false,
		lgui = false,
		rgui = false,
	}

	-- ID of the most recently pressed scancode. Modifier keys are excluded.
	-- Used when 'repeat_all' is false.
	self.sc_last = false

	-- ID of the most recently pressed Scancode, including modifier keys.
	-- Intended to help monitor single key press->release actions with no other
	-- keys pressed in-between.
	-- Excludes the "unknown" Scancode and ignores 'isrepeat' events.
	self.sc_recent = false

	-- When true, sc_recent cannot update and will always be set to false.
	self.sc_recent_locked = false

	-- Note that sc_recent may contain stale information at times, as it is
	-- only updated in key-down events and when locking or unlocking the feature.

	-- Ordered sequence of currently held keys.
	self.seq = {}

	-- Hash of scancodes which were pressed or repeat-pressed on this frame.
	-- These are not affected by key-release events, and the contents should
	-- be flushed after polling input (probably at the very end of love.update())
	-- using self:clearActive().
	self.active = {}

	-- Hash of scancodes which were pressed on this frame. Does not include
	-- repeat-press events.
	self.pressed_once = {}

	-- Initial, then continuous delay for virtual key-repeat.
	self.rep_delay = 1/4
	self.rep_interval = 1/16

	setmetatable(self, _mt_mgr)

	return self
end


--- Call after you are done with input polling.
function _mt_mgr:clearActive()
	local active = self.active
	for k in pairs(active) do
		active[k] = nil
	end

	local pressed_once = self.pressed_once
	for k in pairs(pressed_once) do
		pressed_once[k] = nil
	end
end


--- Lock or unlock the recent scancode value. The variable is blanked to false when locked.
-- @param locked Whether to lock or unlock the recent scancode feature.
-- @return Nothing.
function _mt_mgr:setRecentLock(locked)
	self.sc_recent_locked = not not locked
	if locked then
		self.sc_recent = false
	end
end


--- Blank out the recent scancode field as a one-time action.
-- @return Nothing.
function _mt_mgr:stunRecent()
	self.sc_recent = false
end


--- Get the most recent Scancode info. Not guaranteed to be up-to-date unless called as part of key-up callback logic.
-- @return The recent Scancode string, or false if there has been no key pressed or it was blanked out.
function _mt_mgr:getRecentScancode()
	return self.sc_recent
end


--- Converts getRecentScancode() to a KeyConstant. Not guaranteed to be up-to-date unless called as part of key-up callback logic.
-- @return The recent KeyConstant string, or false if there has been no key pressed or it was blanked out.
function _mt_mgr:getRecentKeyConstant()
	local sc_recent = self.sc_recent
	return sc_recent and _getKeyFromScancode(self.sc_recent) or false
end


function _mt_mgr:setDelayInterval(delay, interval)
	-- Assertions
	-- [[
	if type(delay) ~= "number" or delay < 0 then
		error("'delay' must be a number >= 0.")

	elseif type(interval) ~= "number" or interval < 0 then
		error("'interval' must be a number >= 0.")
	end
	--]]

	self.rep_delay = delay
	self.rep_interval = interval
end


function _mt_mgr:setVirtualRepeat(enabled)
	self.virtual_repeat = not not enabled
end


function _mt_mgr:setRepeatAll(enabled)
	self.repeat_all = not not enabled
end


-- Functions to set and unset merged modkey state.
-- It looks bad, but they just set a flag representing the combined state of two modifier keys.
local mods_down = {}
local mods_up = {}

mods_down["lctrl"] = function(self, kc)
	local mod = self.mod
	mod[kc] = true
	mod["ctrl"] = true
end
mods_down["rctrl"] = mods_down["lctrl"]

mods_up["lctrl"] = function(self, kc)
	local mod = self.mod
	mod[kc] = false
	mod["ctrl"] = (mod["lctrl"] or mod["rctrl"]) and true or false
end
mods_up["rctrl"] = mods_up["lctrl"]

mods_down["lalt"] = function(self, kc)
	local mod = self.mod
	mod[kc] = true
	mod["alt"] = true
end
mods_down["ralt"] = mods_down["lalt"]

mods_up["lalt"] = function(self, kc)
	local mod = self.mod
	mod[kc] = false
	mod["alt"] = (mod["lalt"] or mod["ralt"]) and true or false
end
mods_up["ralt"] = mods_up["lalt"]

mods_down["lshift"] = function(self, kc)
	local mod = self.mod
	mod[kc] = true
	mod["shift"] = true
end
mods_down["rshift"] = mods_down["lshift"]

mods_up["lshift"] = function(self, kc)
	local mod = self.mod
	mod[kc] = false
	mod["shift"] = (mod["lshift"] or mod["rshift"]) and true or false
end
mods_up["rshift"] = mods_up["lshift"]

mods_down["lgui"] = function(self, kc)
	local mod = self.mod
	mod[kc] = true
	mod["gui"] = true
end
mods_down["rgui"] = mods_down["lgui"]

mods_up["lgui"] = function(self, kc)
	local mod = self.mod
	mod[kc] = false
	mod["gui"] = (mod["lgui"] or mod["rgui"]) and true or false
end
mods_up["rgui"] = mods_up["lgui"]


local mod_key_codes = {lctrl=true, rctrl=true, lshift=true, rshift=true, lalt=true, ralt=true, lgui=true, rgui=true}


--- Place in love.keypressed().
-- @param owner An optional state table to be passed to the 'cb_keyDown' callback.
-- @param kc The 'key' argument provided by love.keypressed().
-- @param sc The 'scancode' argument provided by love.keypressed().
-- @param isrepeat The 'isrepeat' argument provided by love.keypressed().
-- @return The result of 'cb_keyDown', if defined, or nil otherwise.
function _mt_mgr:keyDown(owner, kc, sc, isrepeat)
	if sc == "unknown" then
		return
	end

	self.hash[sc] = self.rep_delay

	local check_mod_key = self.mods_use_kc and kc or sc
	if mods_down[check_mod_key] then
		mods_down[check_mod_key](self, check_mod_key)
	else
		self.sc_last = sc
	end

	-- Add to ordered sequence (check for an existing appearance first).
	local seq = self.seq
	local do_add = true
	for i = 1, #seq do
		local seq_sc = seq[i]
		if seq_sc == sc then
			do_add = false
			break
		end
	end

	if do_add then
		seq[#seq + 1] = sc
	end

	-- Add to hash of keys known to have been pressed on this frame
	self.active[sc] = true

	-- Add to a second hash that excludes repeat-events.
	if not isrepeat then
		self.pressed_once[sc] = true
	end

	-- Most recently pressed
	if not self.sc_recent_locked then
		if not isrepeat then
			self.sc_recent = sc
		end
	else
		self.sc_recent = false
	end

	-- Hotkey strings, if applicable.
	local mods = self.mod
	local hot_kc, hot_sc = false, false

	if not mods[check_mod_key] then
		hot_kc = keyMgr.getKeyString(mods["ctrl"], mods["shift"], mods["alt"], mods["gui"], false, kc)
		hot_sc = keyMgr.getKeyString(mods["ctrl"], mods["shift"], mods["alt"], mods["gui"], true, sc)
	end

	-- Fire callback, if applicable
	if self.cb_keyDown then
		return self.cb_keyDown(owner, kc, sc, isrepeat, self.sc_last == sc, hot_kc, hot_sc)
	end
end


--- Place in love.keyreleased().
-- @param owner An optional state table to be passed to the 'cb_keyUp' callback.
-- @param kc The 'key' argument provided by love.keyreleased().
-- @param sc The 'scancode' argument provided by love.keyreleased().
-- @return The results of 'cb_keyUp', if defined, or nil otherwise.
function _mt_mgr:keyUp(owner, kc, sc)
	if sc == "unknown" then
		return
	end

	self.hash[sc] = nil

	if self.sc_last == sc then
		self.sc_last = false
	end

	local check_mod_key = self.mods_use_kc and kc or sc
	if mods_up[check_mod_key] then
		mods_up[check_mod_key](self, check_mod_key)
	end

	-- Eliminate all appearances of sc in the sequence.
	local seq = self.seq
	for i = #seq, 1, -1 do
		if seq[i] == sc then
			table.remove(seq, i)
		end
	end

	-- Fire callback, if applicable
	if self.cb_keyUp then
		return self.cb_keyUp(owner, kc, sc)
	end
end


--- Per-frame update function. Currently handles virtual key-repeats only.
-- @param time Time since the last update, usually the frame delta provided by love.update().
function _mt_mgr:update(owner, time)
	local seq = self.seq
	local hash = self.hash

	if self.virtual_repeat then

		-- Only allow the last pressed scancode to repeat
		if not self.repeat_all then
			for reps = 1, self.n_virt_reps do
				local done = true

				local sc_last = self.sc_last

				if sc_last then
					hash[sc_last] = hash[sc_last] - time
					if hash[sc_last] <= 0.0 then
						hash[sc_last] = hash[sc_last] + self.rep_interval
						done = false

						-- Add to "active" list
						self.active[sc_last] = true

						-- ('pressed_once' always excludes repeat-press events.)

						-- Fire callback, if applicable
						if self.cb_keyDown then
							self.cb_keyDown(owner, _getKeyFromScancode(sc_last), sc_last, true, true)
						end
					end
				end
			end
		-- Allow all held scancodes to repeat
		else
			for reps = 1, self.n_virt_reps do
				local done = true

				for i = 1, #seq do
					local sc = seq[i]

					hash[sc] = hash[sc] - time
					if hash[sc] <= 0.0 then
						hash[sc] = hash[sc] + self.rep_interval
						done = false

						-- Add to "active" list
						self.active[sc] = true

						-- ('pressed_once' always excludes repeat-press events.)

						-- Fire callback, if applicable
						if self.cb_keyDown then
							self.cb_keyDown(owner, _getKeyFromScancode(sc), sc, true, self.sc_last == sc)
						end
					end
				end

				if done then
					break
				end
			end
		end
	end
end


-- * State query methods: modifier keys *


--- Get the state of the merged modifier keys.
-- @return four booleans representing ctrl, shift, alt and gui respectively.
function _mt_mgr:getModState()
	return self.mod["ctrl"], self.mod["shift"], self.mod["alt"], self.mod["gui"]
end


--- Get merged state of the Ctrl modifier key.
-- @return True if left or right Ctrl is held, false if not.
function _mt_mgr:getModCtrl()
	return self.mod["ctrl"]
end


--- Get merged state of the Shift modifier key.
-- @return True if left or right Shift is held, false if not.
function _mt_mgr:getModShift()
	return self.mod["shift"]
end


--- Get merged state of the Alt modifier key.
-- @return True if left or right Alt is held, false if not.
function _mt_mgr:getModAlt()
	return self.mod["alt"]
end


--- Get merged state of the Gui modifier key.
-- @return True if left or right Gui is held, false if not.
function _mt_mgr:getModGui()
	return self.mod["gui"]
end


-- * State query methods: Scancodes *


function _mt_mgr:isScanDown(...)
	local hash = self.hash
	local codes = keyMgr.scancodes

	for i = 1, select("#", ...) do
		local sc = select(i, ...)

		-- [[
		if not codes[sc] then
			error("invalid scancode: " .. tostring(sc))
		end
		--]]

		if hash[sc] then
			return true
		end
	end

	return false
end


function _mt_mgr:lastScanDown(sc)
	keyMgr.assertScancode(sc)

	return self.sc_last == sc
end


function _mt_mgr:isScanPressedOnce(...)
	local pressed_once = self.pressed_once
	local codes = keyMgr.scancodes

	for i = 1, select("#", ...) do
		local sc = select(i, ...)

		-- [[
		if not codes[sc] then
			error("invalid scancode: " .. tostring(sc))
		end
		--]]

		if pressed_once[sc] then
			return true
		end
	end

	return false
end


function _mt_mgr:isScanPressedRep(...)
	local active = self.active
	local codes = keyMgr.scancodes

	for i = 1, select("#", ...) do
		local sc = select(i, ...)

		-- [[
		if not codes[sc] then
			error("invalid scancode: " .. tostring(sc))
		end
		--]]

		if active[sc] then
			return true
		end
	end

	return false
end


-- * State query methods: KeyConstants *
--[[
	NOTE: 'love.keyboard.getScancodeFromKey()' asserts that the keyconstant is valid. The resulting scancode
	might be "unknown", though.
--]]


function _mt_mgr:isKeyDown(...)
	local hash = self.hash

	for i = 1, select("#", ...) do
		local kc = select(i, ...)
		local sc = _getScancodeFromKey(kc)

		if hash[sc] then
			return true
		end
	end

	return false
end


function _mt_mgr:lastKeyDown(kc)
	local sc = _getScancodeFromKey(kc)

	return self.sc_last == sc
end


function _mt_mgr:isKeyPressedOnce(...)
	local pressed_once = self.pressed_once

	for i = 1, select("#", ...) do
		local kc = select(i, ...)
		local sc = _getScancodeFromKey(kc)

		if pressed_once[sc] then
			return true
		end
	end

	return false
end


function _mt_mgr:isKeyPressedRep(...)
	local active = self.active

	for i = 1, select("#", ...) do
		local kc = select(i, ...)
		local sc = _getScancodeFromKey(kc)

		if active[sc] then
			return true
		end
	end

	return false
end


--[[
Functions for parsing key combinations (like ctrl+s).

The KeyString format:

C? S? A? G? (+KeyConstant|-Scancode)

C: Ctrl modifier key
S: Shift modifier key
A: Alt modifier key
G: Gui modifier key

KeyString examples:

F: +f
F (Scancode): -f
Ctrl + W: C+w
Ctrl + Shift + Alt + S: CSA+s
Gui + Q (Scancode): G-q
--]]


local _h_ctrl = {[true] = "C", [false] = ""}
local _h_shift = {[true] = "S", [false] = ""}
local _h_alt = {[true] = "A", [false] = ""}
local _h_gui = {[true] = "G", [false] = ""}
local _h_is_sc = {[true] = "-", [false] = "+"}

local _d_ctrl = {[true] = "Ctrl +", [false] = ""}
local _d_shift = {[true] = "Shift +", [false] = ""}
local _d_alt = {[true] = "Alt +", [false] = ""}
local _d_gui = {[true] = "Gui +", [false] = ""}
local _d_is_sc = {[true] = " (Scancode)", [false] = ""}


--- Produce a KeyString based on a set of input parameters.
-- @param ctrl, shift, alt, gui Booleans representing the state of the four modifier keys.
-- @param is_sc True for a Scancode KeyString, false for a KeyConstant KeyString.
-- @param code The Scancode if 'is_sc' is true or KeyConstant if 'is_sc' is false.
-- @return A KeyString representing the key combination, or nil plus error message if there was an issue reading the input.
function keyMgr.getKeyString(ctrl, shift, alt, gui, is_sc, code)
	-- Validate key
	if is_sc and not keyMgr.scancodes[code] then
		return nil, "unknown scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not keyMgr.key_constants[code] then
		return nil, "unknown keyConstant: |" .. tostring(code) .. "|"
	end

	local str = _h_ctrl[ctrl] .. _h_shift[shift] .. _h_alt[alt] .. _h_is_sc[is_sc] .. code

	return str
end


--- Generate a string suitable for displaying to the end user.
-- @param ctrl True for the ctrl modifier key.
-- @param shift True for shift.
-- @param alt True for alt.
-- @param gui True for gui.
-- @param is_sc True if the key is a scancode.
-- @param code The key label string. (Not validated.)
-- @return A string for displaying to the user.
function keyMgr.getDisplayString(ctrl, shift, alt, gui, is_sc, code)
	-- Validate key
	if is_sc and not keyMgr.scancodes[code] then
		return nil, "unknown scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not keyMgr.key_constants[code] then
		return nil, "unknown keyConstant: |" .. tostring(code) .. "|"
	end

	local str = _d_ctrl[ctrl] .. _d_shift[shift] .. _d_alt[alt] .. code .. _d_is_sc[is_sc]

	return str
end


--- Try to parse a KeyString. (See comments above for formatting.)
-- @param str The input KeyString.
-- @return The state of the Ctrl, Alt, Shift and Gui modifiers, 'Is Scancode' (bool), and the KeyConstant/Scancode, or nil plus error string if there was an issue parsing the input.
function keyMgr.parseKeyString(str)

	local ctrl, shift, alt, gui, is_sc, code = str:find("(C?)(S?)(A?)(G?)([%-%+])(.+)")
	if not code then
		return nil, "failed to parse KeyString."
	end
	is_sc = is_sc == "-"

	-- Validate the code.
	if is_sc and not keyMgr.scancodes[code] then
		return nil, "invalid Scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not keyMgr.key_constants[code] then
		return nil, "invalid KeyConstant: |" .. tostring(code) .. "|"
	end

	-- Looks good.
	return not not ctrl, not not shift, not not alt, not not gui, not not is_sc, code
end


-- Compare a KeyString against one or multiple other KeyStrings.
function keyMgr.keyStringsEqual(first, ...)
	for i = 1, select("#", ...) do
		local str = select(i, ...)
		if first == str then
			return true
		end
	end
	return false
end


function keyMgr.keyStringsInKeyBinds(binds, ...)
	for i, chunk in ipairs(binds) do
		for j = 2, #chunk do
			local comp = chunk[j]
			for k = 1, select("#", ...) do
				local code = select(k, ...)
				if code == comp then
					return chunk[1]
				end
			end
		end
	end
end


local function _applyKey(t, key, id)
	if t[key] then
		return false
	else
		t[key] = id
	end
end


local function _populateDupe(dupes, id, key)
	dupes = dupes or {}
	dupes[id] = dupes[id] or {}
	local present = false
	for i, v in ipairs(dupes[id]) do
		if v == key then
			present = true
			break
		end
	end
	if not present then
		table.insert(dupes[id], key)
	end
	return dupes
end


--- Builds an inverse hash of hotkeys.
-- @param arr An array of arrays. In each sub-array, the first value is an arbitrary identifier ("save-file", etc.), and the following values are hotkey
--	strings. The IDs must be unique; the hotkeys should be unique.
-- @return The inverted table, plus a table of duplicate hotkeys, if any were found.
function keyMgr.buildKeyMap(arr)
	-- Check for, and reject duplicate / invalid IDs.
	local temp = {}
	for i, chunk in ipairs(arr) do
		local id = chunk[1]
		if id == nil then
			error("invalid (nil) KeyMap ID.")

		elseif temp[id] then
			error("duplicate KeyMap ID in array.")
		end
		temp[id] = true
	end
	temp = nil

	local t = {}
	local dupes

	for i, chunk in ipairs(arr) do
		local id = chunk[1]
		for j = 2, #chunk do
			local hotkey = chunk[j]
			if type(hotkey) ~= "string" then
				error("expected string for hotkey.")
			end
			if not _applyKey(t, hotkey, id) then
				dupes = _populateDupe(dupes, id, hotkey)
			end
		end
	end

	return t, dupes
end


return keyMgr
