local uiKeyboard = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local key_constants = require(REQ_PATH .. "data.keyboard.key_constants")
local scancodes = require(REQ_PATH .. "data.keyboard.scancodes")


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


function uiKeyboard.assertScancode(sc)
	if not scancodes[sc] then
		error("invalid Scancode: " .. tostring(sc), 2)
	end
end


function uiKeyboard.assertKeyConstant(kc)
	-- NOTE: This assertion will miss some obscure Scancodes which also count as KeyConstants, like muteaudio.
	if not key_constants[kc] then
		error("invalid KeyConstant: " .. tostring(kc), 2)
	end
end


function uiKeyboard.assertKey(is_sc, code)
	if is_sc then
		if not scancodes[code] then
			error("invalid Scancode: " .. tostring(code), 2)
		end
	else
		if not key_constants[code] then
			error("invalid KeyConstant: " .. tostring(code), 2)
		end
	end
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
function uiKeyboard.getKeyString(ctrl, shift, alt, gui, is_sc, code)
	-- Validate key
	if is_sc and not scancodes[code] then
		return nil, "unknown scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not key_constants[code] then
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
function uiKeyboard.getDisplayString(ctrl, shift, alt, gui, is_sc, code)
	-- Validate key
	if is_sc and not scancodes[code] then
		return nil, "unknown scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not key_constants[code] then
		return nil, "unknown keyConstant: |" .. tostring(code) .. "|"
	end

	local str = _d_ctrl[ctrl] .. _d_shift[shift] .. _d_alt[alt] .. code .. _d_is_sc[is_sc]

	return str
end


--- Try to parse a KeyString. (See comments above for formatting.)
-- @param str The input KeyString.
-- @return The state of the Ctrl, Alt, Shift and Gui modifiers, 'Is Scancode' (bool), and the KeyConstant/Scancode, or nil plus error string if there was an issue parsing the input.
function uiKeyboard.parseKeyString(str)
	local ctrl, shift, alt, gui, is_sc, code = str:find("(C?)(S?)(A?)(G?)([%-%+])(.+)")
	if not code then
		return nil, "failed to parse KeyString."
	end
	is_sc = is_sc == "-"

	-- Validate the code.
	if is_sc and not scancodes[code] then
		return nil, "invalid Scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not key_constants[code] then
		return nil, "invalid KeyConstant: |" .. tostring(code) .. "|"
	end

	-- Looks good.
	return not not ctrl, not not shift, not not alt, not not gui, not not is_sc, code
end


-- Compare a KeyString against one or multiple other KeyStrings.
function uiKeyboard.keyStringsEqual(first, ...)
	for i = 1, select("#", ...) do
		local str = select(i, ...)
		if first == str then
			return true
		end
	end
	return false
end


function uiKeyboard.keyStringsInKeyBinds(binds, ...)
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
function uiKeyboard.buildKeyMap(arr)
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


return uiKeyboard
