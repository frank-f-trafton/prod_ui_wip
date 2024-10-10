
--[[
A supplemental module for KeyMgr which provides functions to help parse key combinations (stuff like ctrl+s).
These are intended for application hotkeys, and are probably not suitable for action gameplay input.
--]]


local keyCombo = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- KeyMgr
local keyMgr = require(REQ_PATH .. "key_mgr")


--[[
local demo_key_combo = {

	-- The final key in a combo can either refer to a scancode or a keyConstant, but not both.
	-- Modkeys are KeyConstants, and are merged into one virtual button by keyMgr.
	is_sc = false,

	-- Merged modifier keys. True or false.
	ctrl = true,
	shift = false,
	alt = true,
	gui = false,

	-- Must be a valid KeyConstant or Scancode (depends on 'is_sc')
	code = "a",
}


The KeyString format:

"[K|C|S|A|G][space]<Scancode/KeyConstant>"

K: Indicates that the key substring at the end is a KeyConstant (as opposed to a Scancode)
C: Ctrl modifier key
S: Shift modifier key
A: Alt modifier key
G: Gui modifier key

If any header characters are present, then they must be separated from the final key substring by one space character.
The space must only be present if there are header chars.

The header characters must be upper-case. This distinguishes them from any LÖVE KeyConstant or Scancode (as of 11.4),
which are all lower-case or have symbols.

Header characters are always generated in this order: KCSAG. They can be parsed in any order, but if you want to use
them as hash keys, you need to stick to that arrangement. Duplicate header characters are considered a parsing error,
and the loop will stop if it hasn't encountered whitespace within six iterations.

--]]


-- Used with table.concat()
local temp_c = {}


--- Produce a KeyString based on a set of input parameters.
-- @param is_sc True for a Scancode KeyString, false for a KeyConstant KeyString.
-- @param ctrl The ctrl code: false/nil, true, "l" or "r". All following modifier arguments share the same set of values.
-- @param shift The shift code.
-- @param alt The alt code.
-- @param gui The gui code.
-- @param code The Scancode if 'is_sc' is true or KeyConstant if 'is_sc' is false.
-- @return A KeyString representing the key combination, or nil plus error message if there was an issue reading the input.
function keyCombo.getKeyString(is_sc, ctrl, shift, alt, gui, code)

	-- Temp table index
	local i = 1

	-- Mode
	if not is_sc then
		temp_c[i] = "K"
		i = i + 1
	end

	-- Modifiers
	if ctrl then
		temp_c[i] = "C"
		i = i + 1
	end

	if shift then
		temp_c[i] = "S"
		i = i + 1
	end

	if alt then
		temp_c[i] = "A"
		i = i + 1
	end

	if gui then
		temp_c[i] = "G"
		i = i + 1
	end

	-- Add whitespace separator, if applicable.
	if i > 1 then
		temp_c[i] = " "
		i = i + 1
	end

	-- Validate key
	if is_sc and not keyMgr.scancodes[code] then
		return nil, "unknown scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not keyMgr.key_constants[code] then
		return nil, "unknown keyConstant: |" .. tostring(code) .. "|"
	end

	temp_c[i] = code

	-- Trim excess table contents
	for j = #temp_c, i + 1, -1 do
		temp_c[j] = nil
	end

	local str_out = table.concat(temp_c)

	return str_out
end


--- Generate a string suitable for displaying to the end user.
-- @param ctrl True for the ctrl modifier key.
-- @param shift True for shift.
-- @param alt True for alt.
-- @param gui True for gui.
-- @param code The key label string. (Not validated.)
-- @return A string for displaying to the user.
function keyCombo.getDisplayString(ctrl, shift, alt, gui, code)

	-- Temp table index
	local i = 1

	-- Modifiers
	if ctrl then
		temp_c[i] = "Ctrl+"
		i = i + 1
	end

	if shift then
		temp_c[i] = "Shift+"
		i = i + 1
	end

	if alt then
		temp_c[i] = "Alt+"
		i = i + 1
	end

	if gui then
		temp_c[i] = "Gui+"
		i = i + 1
	end

	temp_c[i] = code

	-- Trim excess table contents
	for j = #temp_c, i + 1, -1 do
		temp_c[j] = nil
	end

	local str_out = table.concat(temp_c)

	return str_out
end


--- Try to parse a KeyString. (See top of source file for formatting.)
-- @param str The input KeyString.
-- @return 'Is Scancode' (bool), the state of the Ctrl, Alt, Shift and Gui modifiers, and the KeyConstant/Scancode, or nil plus error string if there was an issue parsing the input.
function keyCombo.parseKeyString(str)

	local is_sc = true
	local ctrl, shift, alt, gui = false, false, false, false
	local code
	local loop_ok = false

	-- Six iterations is enough to hold every header character, plus one space char.
	local i = 1
	while i <= 6 do
		local b = string.byte(str, i)

		if b == 75 then -- 'K'
			if is_sc == true then
				is_sc = false
				
			else
				return nil, "duplicate header char: 'K' (KeyConstant)"
			end

		elseif b == 67 then -- 'C'
			if ctrl == false then
				ctrl = true
				
			else
				return nil, "duplicate header char: 'C' (Ctrl)"
			end

		elseif b == 83 then -- 'S'
			if shift == false then
				shift = true
				
			else
				return nil, "duplicate header char: 'S' (Shift)"
			end

		elseif b == 65 then -- 'A'
			if alt == false then
				alt = true
				
			else
				return nil, "duplicate header char: 'A' (Alt)"
			end

		elseif b == 71 then -- 'G'
			if gui == false then
				gui = true
				
			else
				return nil, "duplicate header char: 'G' (Gui)"
			end

		-- End of header chars
		elseif b == 32 then -- (space)
			-- At start of string, this is a parsing failure.
			if i == 1 then
				return nil, "KeyString started with header-keystring separator (space)"

			else
				i = i + 1
				loop_ok = true
				break
			end

		-- Non-header char encountered.
		else
			-- Start of string: OK. After that: parsing failure.
			if i == 1 then
				loop_ok = true
				break

			else
				return nil, "non-header char encountered while still parsing header."
			end
		end

		i = i + 1
	end

	if not loop_ok then
		return nil, "the KeyString header exceeds the max allowed parsing loop iterations."
	end

	code = string.sub(str, i)

	-- Validate the code.
	if is_sc and not keyMgr.scancodes[code] then
		return nil, "invalid Scancode: |" .. tostring(code) .. "|"

	elseif not is_sc and not keyMgr.key_constants[code] then
		return nil, "invalid KeyConstant: |" .. tostring(code) .. "|"
	end

	-- Looks good.
	return is_sc, ctrl, shift, alt, gui, code
end


--- Convert a KeyString to a combo table.
-- @param str The input KeyString.
-- @param combo (Optional) An existing combo table to overwrite. If not provided, a new table will be created.
-- @return The updated combo table, or nil plus error message if there was a problem.
function keyCombo.stringToTable(str, combo)

	local is_sc, ctrl_or_err, shift, alt, gui, code = keyCombo.parseKeyString(str)

	if not is_sc then
		return nil, ctrl_or_err
	end

	combo = combo or {}

	combo.is_sc = is_sc

	combo.ctrl = ctrl_or_err
	combo.shift = shift
	combo.alt = alt
	combo.gui = gui

	combo.code = code

	return combo
end


--- Check if a KeyCombo's modkey settings match the current KeyMgr modkey state.
-- @param mgr The keyMgr instance.
-- @param ctrl (coerced to Boolean) The Ctrl state for the KeyCombo.
-- @param shift (coerced to Boolean) The Shift state for the KeyCombo.
-- @param alt (coerced to Boolean) The Alt state for the KeyCombo.
-- @param gui (coerced to Boolean) The Gui state for the KeyCombo.
-- @return True if the current modkey state matches the KeyCombo modkey requirements, false if not.
function keyCombo.checkModKeys(mgr, ctrl, shift, alt, gui)

	local mod = mgr.mod

	return not not ctrl == mod["ctrl"]
		and not not shift == mod["shift"]
		and not not alt == mod["alt"]
		and not not gui == mod["gui"]
end


-- @return 'Is Scancode', ctrl, shift, alt, gui booleans, and a key code string, or nil plus error message if there was a parsing failure (in the case of KeyStrings).
function keyCombo.unpackCombo(combo)
	if type(combo) == "string" then
		return keyCombo.parseKeyString(str)

	else
		-- No error checking on combo tables at this point.
		return combo.is_sc, combo.ctrl, combo.shift, combo.alt, combo.gui, combo.code
	end
end


-- * KeyMgr Query Wrappers *


function keyCombo.isDown(mgr, combo)

	local is_sc, ctrl_or_err, shift, alt, gui, code = keyCombo.unpackCombo(combo)
	if not is_sc then
		error("unpackCombo() failed: " .. tostring(ctrl_or_err))
	end

	if keyCombo.checkModKeys(mgr, ctrl, shift, alt, gui) then
		if is_sc then
			return mgr:isScanDown(code)
			
		else
			return mgr:isKeyDown(code)
		end
	end

	return false
end


function keyCombo.isPressedOnce(mgr, combo)

	local is_sc, ctrl_or_err, shift, alt, gui, code = keyCombo.unpackCombo(combo)
	if not is_sc then
		error("unpackCombo() failed: " .. tostring(ctrl_or_err))
	end

	if keyCombo.checkModKeys(mgr, ctrl, shift, alt, gui) then
		if is_sc then
			return mgr:isScanPressedOnce(code)
			
		else
			return mgr:isKeyPressedOnce(code)
		end
	end

	return false
end


function keyCombo.isPressedRep(mgr, combo)

	local is_sc, ctrl_or_err, shift, alt, gui, code = keyCombo.unpackCombo(combo)
	if not is_sc then
		error("unpackCombo() failed: " .. tostring(ctrl_or_err))
	end

	if keyCombo.checkModKeys(mgr, ctrl, shift, alt, gui) then
		if is_sc then
			return mgr:isScanPressedRep(code)
			
		else
			return mgr:isKeyPressedRep(code)
		end
	end

	return false
end


return keyCombo

