--[[
	EditField plug-in methods for client widgets. Some internal-facing methods remain attached to 'core' and 'disp'.
--]]

-- LÖVE Supplemental
local utf8 = require("utf8")

local client = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""

local edCom = require(PATH .. "ed_com")
local edVis = require(PATH .. "ed_vis")
local editDisp = require(PATH .. "edit_disp")
local editField = require(PATH .. "edit_field") -- XXX work on removing this reference (?)


local code_groups = editField.code_groups


function client:getReplaceMode()
	return self.core.replace_mode
end


--- When Replace Mode is active, new text overwrites existing characters under the caret.
function client:setReplaceMode(enabled)
	self.core.replace_mode = not not enabled
end


-- * Font, Wrap, Align state, Width *


function client:getWrapMode()
	return self.core.disp.wrap_mode
end


-- @return true if the mode changed.
function client:setWrapMode(enabled)

	local disp = self.core.disp

	disp.wrap_mode = not not enabled

	self.core:displaySyncAll()

	-- XXX refresh: clamp scroll and get caret in bounds
end
--[[
function def_wid:setWrapMode(enabled)

	local core = self.core
	local disp = core.disp

	core:setWrapMode(enabled)

	-- Disable horizontal scroll bar when wrapping
	self.scr_h.show = not enabled

	setCoreDimensions(self)
	disp:updateScrollBoundaries()
	disp:enforceScrollBounds()
	disp:scrollGetCaretInBounds()
	updateScrollIndicators(self)
end
--]]


function client:getFont()
	return self.core.disp.font
end


function client:setFont(font)

	self.core.disp:updateFont(font)
	self.core:displaySyncAll()

	-- Force a cache update on the widget after calling this (self.update_flag = true).
end


function client:getAlign()
	return self.core.disp.align
end


function client:setAlign(align)

	local disp = self.core.disp

	if align ~= "left" and align ~= "center" and align ~= "right" then
		error("arg #2: invalid align setting.")
	end

	local old_align = disp.align
	disp.align = align
	if old_align ~= align then
		-- Update just the alignment of sub-lines.
		self.core:displaySyncAlign(1)
		self.core:displaySyncCaretOffsets()

		-- XXX refresh: update align_offset, clamp scroll, get caret in bounds

		return true
	end
end
--[[
function def_wid:setAlign(align)

	local core = self.core
	local disp = core.disp

	if core:setAlign(align) then
		disp:updateScrollBoundaries()
		disp:enforceScrollBounds()
		disp:scrollGetCaretInBounds()
		updateScrollIndicators(self)
	end
end

--]]


-- * / Font, Wrap, Align state, Width *


-- * Masking state *


function client:getMasking()

	local disp = self.core.disp

	return disp.masked, (disp.masked) and disp.mask_glyph or nil
end


function client:setMasking(enabled, optional_glyph)

	local disp = self.core.disp

	disp.masked = not not enabled

	if optional_glyph then
		self.core:setMaskGlyph(optional_glyph)

	else
		self.core:displaySyncAll()
	end
end


function client:setMaskGlyph(glyph)

	local disp = self.core.disp

	if utf8.len(glyph) ~= 1 then
		error("masking glyph must be exactly one code point.")
	end

	disp.mask_glyph = glyph
	self.core:displaySyncAll()
end


-- * / Masking state *


-- * Colorization state *


function client:getColorization()

	return self.core.disp.generate_colored_text
end


function client:setColorization(enabled)

	local disp = self.core.disp
	disp.generate_colored_text = not not enabled

	-- Refresh everything
	self.core:displaySyncAll()
end


-- * / Colorization state *


-- * Highlight State *


function client:getHighlightEnabled(enabled)
	-- No assertions.

	return self.core.allow_highlight
end


--- Enables or disables highlight selection mode. When disabling, any current selection is removed. (Should only be used immediately after widget is initialized. See source comments for more info.)
-- @param enabled true or false/nil.
function client:setHighlightEnabled(enabled)
	-- No assertions.

	local core = self.core

	local old_state = core.allow_highlight
	core.allow_highlight = not not enabled

	if old_state ~= core.allow_highlight then
		core:clearHighlight()
		--self.update_flag = true

		--[[
		NOTE: if the field has already accumulated history entries with highlighting, selections may
		still be loaded when undoing/redoing entries.

		The following block removes all selections in the history ledger. This is a destructive change:
		they won't be restored if you re-enable highlighting. It might be batter to just clear all
		history when calling this. Ideally, you wouldn't be changing allow/disallow highlight after
		initialization of the widget.
		--]]
		--[[
		local hist = self.core.hist
		for i, entry in ipairs(hist.ledger) do -- XXX untested
			entry.h_line = entry.car_line
			entry.h_byte = entry.car_byte
		end
		--]]
	end
end


-- * / Highlight State *


-- * History management *


function client:stepHistory(dir)

	-- -1 == undo
	-- 1 == redo

	local core = self.core
	local hist = core.hist

	local changed, entry = hist:moveToEntry(hist.pos + dir)

	if changed then
		local core_lines = core.lines
		local entry_lines = entry.lines

		for i = 1, #entry_lines do
			core_lines[i] = entry_lines[i]
		end
		for i = #core_lines, #entry_lines + 1, -1 do
			core_lines[i] = nil
		end

		core.car_line = entry.car_line
		core.car_byte = entry.car_byte
		core.h_line = entry.h_line
		core.h_byte = entry.h_byte

		core:displaySyncAll()
	end
end


-- * / History management *


-------------------- Unsorted --------------------


function client:getText(line_1, line_2) -- XXX maybe replace with a call to lines:copyString().

	local lines = self.core.lines

	line_1 = line_1 or 1
	line_2 = line_2 or #lines

	if line_1 > line_2 then
		error("'line_1' must be less than or equal to 'line_2'.")

	elseif line_1 < 1 or line_1 > #lines then
		error("'line_1' is out of range.")

	elseif line_2 < 1 or line_2 > #lines then
		error("'line_2' is out of range.")
	end

	if line_1 == line_2 then
		return lines[line_1]

	elseif line_1 == 1 and line_2 == #lines then
		return table.concat(lines, "\n")

	else
		local tbl = {}
		for i = line_1, line_2 do
			table.insert(tbl, lines[i])
		end

		return table.concat(tbl, "\n")
	end
end


function client:getHighlightedText()

	local core = self.core
	local disp = core.disp

	if core:isHighlighted() then
		local lines = core.lines

		local line_1, byte_1, line_2, byte_2 = core:getHighlightOffsets()
		local text = lines:copy(line_1, byte_1, line_2, byte_2 - 1)

		return table.concat(text, "\n")
	end

	return nil
end


function client:isHighlighted()
	return self.core:isHighlighted()
end


function client:clearHighlight()
	self.core:clearHighlight()
end


function client:highlightAll()

	local core = self.core

	core.car_line = 1
	core.car_byte = 1

	core.h_line = #core.lines
	core.h_byte = #core.lines[core.h_line] + 1

	core:displaySyncCaretOffsets()
	core:updateDispHighlightRange()
end


--- Moves caret to the left highlight edge
function client:caretHighlightEdgeLeft()

	local core = self.core

	local line_1, byte_1, line_2, byte_2 = core:getHighlightOffsets()

	core.car_line = line_1
	core.car_byte = byte_1
	core.h_line = line_1
	core.h_byte = byte_1

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	core:updateDispHighlightRange()
end


--- Moves caret to the right highlight edge
function client:caretHighlightEdgeRight()

	local core = self.core

	local line_1, byte_1, line_2, byte_2 = core:getHighlightOffsets()

	core.car_line = line_2
	core.car_byte = byte_2
	core.h_line = line_2
	core.h_byte = byte_2

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	core:updateDispHighlightRange()
end


function client:highlightCurrentLine()

	local core = self.core

	core.h_line = core.car_line
	core.car_byte, core.h_byte = 1, #core.lines[core.car_line] + 1

	core:displaySyncCaretOffsets()
	core:updateDispHighlightRange()
end


function client:highlightCurrentWord()

	local core = self.core
	local disp = core.disp

	core.car_line, core.car_byte, core.h_line, core.h_byte = core:getWordRange(core.car_line, core.car_byte)

	core:displaySyncCaretOffsets()
	core:updateDispHighlightRange()
end


function client:highlightCurrentWrappedLine()

	local core = self.core
	local lines = core.lines
	local disp = core.disp

	-- Temporarily move highlight point to caret, then pre-emptively update the display offsets
	-- so that we have fresh data to work from.
	core.h_line = core.car_line
	core.h_byte = core.car_byte

	core:displaySyncCaretOffsets()

	core.car_byte, core.h_byte = core:getWrappedLineRange(core.car_line, core.car_byte)

	--print("core.car_byte", core.car_byte, "core.h_line", core.h_byte)

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	core:updateDispHighlightRange()
end


function client:caretStepUp(clear_highlight, n_steps)

	local core = self.core
	local lines = core.lines
	local disp = core.disp
	local font = disp.font
	local super_lines = disp.super_lines

	n_steps = n_steps or 1

	-- Already at top sub-line: move to start.
	if disp.d_car_super <= 1 and disp.d_car_sub <= 1 then
		core.car_line = 1
		core.car_byte = 1

		core:displaySyncCaretOffsets()
		core:updateVertPosHint()
		if clear_highlight then
			core:clearHighlight()
		else
			core:updateDispHighlightRange()
		end

	else
		-- Get the offsets for the sub-line 'n_steps' above.
		local d_super, d_sub = editDisp.stepSubLine(super_lines, disp.d_car_super, disp.d_car_sub, -n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = super_lines[d_super][d_sub]
		local d_str = d_sub_t.str
		local pixels, new_byte, new_u_char = edVis.countToWidth(d_str, font, core.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the super-line: correct leftmost position so that it doesn't
		-- spill over to the next sub-line (and get stuck).
		-- [[
		if d_sub < #super_lines[d_super] then
			new_byte = math.min(#d_str, new_byte)
		end
		--]]

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edVis.displaytoUCharCount(super_lines[d_super], d_sub, new_byte)
		core.car_line = d_super
		core.car_byte = utf8.offset(lines[core.car_line], u_count)

		core:displaySyncCaretOffsets()
		if clear_highlight then
			core:clearHighlight()
		else
			core:updateDispHighlightRange()
		end
	end
end


function client:caretStepDown(clear_highlight, n_steps)

	local core = self.core
	local lines = core.lines
	local disp = core.disp
	local font = disp.font
	local super_lines = disp.super_lines

	n_steps = n_steps or 1

	-- Already at bottom sub-line: move to end.
	if disp.d_car_super >= #super_lines and disp.d_car_sub >= #super_lines[#super_lines] then
		core.car_line = #core.lines
		core.car_byte = #core.lines[core.car_line] + 1

		core:displaySyncCaretOffsets()
		core:updateVertPosHint()
		if clear_highlight then
			core:clearHighlight()
		else
			core:updateDispHighlightRange()
		end

	else
		-- Get the offsets for the sub-line 'n_steps' below.
		local d_super, d_sub = editDisp.stepSubLine(super_lines, disp.d_car_super, disp.d_car_sub, n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = super_lines[d_super][d_sub]
		local d_str = d_sub_t.str
		local pixels, new_byte, new_u_char = edVis.countToWidth(d_str, font, core.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the super-line: correct rightmost position so that it doesn't
		-- spill over to the next sub-line.
		if d_sub < #super_lines[d_super] then
			new_byte = math.min(#d_str, new_byte)
		end

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edVis.displaytoUCharCount(super_lines[d_super], d_sub, new_byte)
		core.car_line = d_super
		core.car_byte = utf8.offset(lines[core.car_line], u_count)

		core:displaySyncCaretOffsets()
		if clear_highlight then
			core:clearHighlight()

		else
			core:updateDispHighlightRange()
		end
	end
end


function client:caretStepUpCoreLine(clear_highlight)

	local core = self.core
	local lines = core.lines

	-- Already at top line: move to start.
	if core.car_line <= 1 then
		core.car_byte = 1

	-- Already at position 1 on the current line: move up one line
	elseif core.car_byte == 1 then
		core.car_line = math.max(1, core.car_line - 1)
		core.car_byte = 1

	-- Otherwise, move to position 1 in the current line.
	else
		core.car_byte = 1
	end

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretStepDownCoreLine(clear_highlight)

	local core = self.core
	local lines = core.lines

	-- Already at bottom line: move to end.
	if core.car_line == #lines then
		core.car_byte = #lines[#lines] + 1

	-- Already at last position in logical line: move to next line
	elseif core.car_byte == #lines[core.car_line] + 1 then
		core.car_line = math.min(core.car_line + 1, #lines)
		core.car_byte = #lines[core.car_line] + 1

	-- Otherwise, move to the last position in the current line.
	else
		core.car_byte = #lines[core.car_line] + 1
	end

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretToXY(clear_highlight, x, y, split_x)

	local core = self.core

	local core_line, core_byte = core:getCharacterDetailsAtPosition(x, y, split_x)

	core:caretToLineAndByte(clear_highlight, core_line, core_byte)
end



--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
-- entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function client:writeText(text, suppress_replace)

	local core = self.core
	local disp = core.disp
	local lines = core.lines

	-- Sanitize input
	text = edCom.cleanString(text, core.bad_input_rule, core.tabs_to_spaces, core.allow_line_feed)

	if not core.allow_highlight then
		core:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if core:isHighlighted() then
		self:deleteHighlightedText()

	elseif core.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		local n_to_delete = edCom.countUChars(text, math.huge)
		self:deleteUChar(n_to_delete)
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	core.u_chars = lines:uLen()
	text = edCom.trimString(text, core.u_chars, core.u_chars_max)

	core:insertText(text)

	return text
end


--- Set the current internal text, wiping anything currently present.
function client:setText(text)

	local core = self.core

	local deleted = self:deleteAll()
	core:insertText(text)

	return deleted
end


--- Delete characters by stepping backwards from the caret position.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:backspaceUChar(n_u_chars)

	local core = self.core
	core:highlightCleanup()

	local lines = core.lines
	local line_1, byte_1, u_count = lines:countUCharsLeft(core.car_line, core.car_byte, n_u_chars)

	if u_count > 0 then
		-- Assumes there was no highlighted text at time of call.
		return core:deleteText(true, line_1, byte_1, core.car_line, core.car_byte - 1)
	end

	return nil
end


-- * Clipboard methods *


function client:copyHighlightedToClipboard()

	local core = self.core
	local disp = core.disp

	local copied = self:getHighlightedText()

	-- Don't leak masked string info.
	if disp.masked then
		copied = string.rep(disp.mask_glyph, utf8.len(copied))
	end

	copied = edCom.validateEncoding(copied, core.bad_input_rule, false, false)

	edCom.setClipboardText(copied)
end


function client:cutHighlightedToClipboard()

	local core = self.core
	local disp = core.disp
	local hist = core.hist

	local old_line, old_byte, old_h_line, old_h_byte = core:getCaretOffsets()

	local cut = self:deleteHighlightedText()

	if cut then
		cut = edCom.validateEncoding(cut, self.bad_input_rule, false, false)

		-- Don't leak masked string info.
		if disp.masked then
			cut = table.concat(cut, "\n")
			cut = string.rep(disp.mask_glyph, utf8.len(cut))
		end

		edCom.setClipboardText(cut)

		self.input_category = false

		hist:doctorCurrentCaretOffsets(old_line, old_byte, old_h_line, old_h_byte)
		hist:writeEntry(true, core.lines, core.car_line, core.car_byte, core.h_line, core.h_byte)
	end
end


function client:pasteClipboardText()

	local core = self.core
	local hist = core.hist

	local old_line, old_byte, old_h_line, old_h_byte = core:getCaretOffsets()

	if core:isHighlighted() then
		self:deleteHighlightedText()
	end

	local text = edCom.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		core.input_category = false
		self:writeText(text, true)

		hist:doctorCurrentCaretOffsets(old_line, old_byte, old_h_line, old_h_byte)
		hist:writeEntry(true, core.lines, core.car_line, core.car_byte, core.h_line, core.h_byte)
	end
end


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function client:deleteHighlightedText()

	local core = self.core

	if not self:isHighlighted() then
		return nil
	end

	local lines = core.lines

	-- Clean up display highlight beforehand. Much harder to determine the offsets after deleting things.
	local line_1, byte_1, line_2, byte_2 = core:getHighlightOffsets()
	core:highlightCleanup()

	return core:deleteText(true, line_1, byte_1, line_2, byte_2 - 1)
end


function client:deleteLine()

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines

	local retval
	-- Multi-line, caret is not on the last line
	if core.car_line < #lines then
		retval = core:deleteText(true, core.car_line, 1, core.car_line + 1, 0)

	-- Multi-line, on the last line
	elseif core.car_line > 1 then
		retval = core:deleteText(true, core.car_line - 1, #lines[core.car_line - 1] + 1, core.car_line, #lines[core.car_line])

	-- Document is a single empty line
	elseif #lines[1] == 0 then
		retval = nil

	-- Document is a single line, with contents that can be deleted
	else
		retval = core:deleteText(true, core.car_line, 1, core.car_line, #lines[core.car_line])
	end

	-- Force to position 1 of the current line and recache caret details
	core.car_byte = 1
	core.h_byte = 1

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()

	return retval
end


function client:deleteCaretToLineEnd()

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines

	return core:deleteText(true, core.car_line, core.car_byte, core.car_line, #lines[core.car_line])
end


function client:deleteCaretToLineStart()

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines

	return core:deleteText(true, core.car_line, 1, core.car_line, core.car_byte - 1)
end


--- Delete characters on and to the right of the caret.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:deleteUChar(n_u_chars)

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines
	local line_2, byte_2, u_count = lines:countUCharsRight(core.car_line, core.car_byte, n_u_chars)

	-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
	local right_edge = math.max(0, byte_2 - 1)
	local right_bounds = edCom.utf8FindRightStartOctet(lines[core.car_line], right_edge + 1) - 1

	if u_count > 0 then
		-- Assumes there was no highlighted text at time of call.
		return core:deleteText(true, core.car_line, core.car_byte, line_2, right_bounds)
	end

	return nil
end


function client:deleteAll()

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines

	return core:deleteText(true, 1, 1, #lines, #lines[#lines])
end


function client:backspaceGroup()

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines
	local line_left, byte_left

	if core.car_byte == 1 and core.car_line > 1 then
		line_left = core.car_line  - 1
		byte_left = #lines[line_left] + 1

	else
		line_left, byte_left = editField.huntWordBoundary(lines, core.car_line, core.car_byte, -1, false, -1, true)
	end

	if line_left then
		if line_left ~= core.car_line or byte_left ~= core.car_byte then
			return core:deleteText(true, line_left, byte_left, core.car_line, core.car_byte - 1)
		end
	end

	return nil
end


function client:deleteGroup()

	local core = self.core

	core:highlightCleanup()

	local lines = core.lines
	local line_right, byte_right

	if core.car_byte == #lines[core.car_line] + 1 and core.car_line < #lines then
		line_right = core.car_line + 1
		byte_right = 0

	else
		local hit_non_ws = false
		local peeked = lines:peekCodePoint(core.car_line, core.car_byte)
		local first_group = code_groups[peeked]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end
		--print("HIT_NON_WS", hit_non_ws, "PEEKED", peeked, "FIRST_GROUP", first_group)

		line_right, byte_right = editField.huntWordBoundary(lines, core.car_line, core.car_byte, 1, hit_non_ws, first_group, true)
		byte_right = byte_right - 1
		--print("deleteGroup: line_right", line_right, "byte_right", byte_right)

		--[[
		-- If the range is a single-byte code point, and a code point to the right exists, move one step over.
		if line_right == core.car_line and byte_right == core.car_byte then
			line_right, byte_right = lines:offsetStepRight(line_right, byte_right)
			if not line_right then
				return nil
			end
		end
		--]]

	end

	--print("ranges:", core.car_line, core.car_byte, line_right, byte_right)
	local del = core:deleteText(true, core.car_line, core.car_byte, line_right, byte_right)
	--print("DEL", "|"..(del or "<nil>").."|")
	if del ~= "" then
		return del
	else
		return nil
	end
end


-- * / Clipboard methods *


function client:caretStepLeft(clear_highlight)

	local core = self.core
	local lines = core.lines
	local left_pos = edCom.utf8FindLeftStartOctet(lines[core.car_line], core.car_byte - 1)

	-- Move back one uChar
	if left_pos then
		core.car_byte = left_pos

	-- Move to end of previous line
	elseif core.car_line > 1 then
		core.car_line = core.car_line - 1
		core.car_byte = #lines[core.car_line] + 1
	end

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretStepRight(clear_highlight)

	local core = self.core
	local lines = core.lines
	local right_pos = edCom.utf8FindRightStartOctet(lines[core.car_line], core.car_byte + 1)

	-- Move right one uChar
	if right_pos then
		core.car_byte = right_pos

	-- Move to start of next line
	elseif core.car_line < #lines then
		core.car_line = core.car_line + 1
		core.car_byte = 1
	end

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretJumpLeft(clear_highlight)

	local core = self.core
	local lines = core.lines

	core.car_line, core.car_byte = editField.huntWordBoundary(lines, core.car_line, core.car_byte, -1, false, -1, false)

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretJumpRight(clear_highlight)

	local core = self.core
	local lines = core.lines

	local hit_non_ws = false
	local first_group = code_groups[lines:peekCodePoint(core.car_line, core.car_byte)]
	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	--print("hit_non_ws", hit_non_ws, "first_group", first_group)

	--(lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed)
	core.car_line, core.car_byte = editField.huntWordBoundary(lines, core.car_line, core.car_byte, 1, hit_non_ws, first_group, false)

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end

	-- One more step to land on the right position. -- XXX okay to delete?
	--self:caretStepRight(clear_highlight)
end


function client:caretFirst(clear_highlight)

	local core = self.core

	core.car_line = 1
	core.car_byte = 1

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretLast(clear_highlight)

	local core = self.core

	core.car_line = #core.lines
	core.car_byte = #core.lines[core.car_line] + 1

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretLineFirst(clear_highlight)

	local core = self.core
	local lines = core.lines
	local disp = core.disp

	-- Find the first uChar offset for the current super-line + sub-line pair.
	local u_count = disp:getSubLineUCharOffsetStart(disp.d_car_super, disp.d_car_sub)

	-- Convert the display u_count to a byte offset in the core/source string.
	core.car_byte = utf8.offset(lines[core.car_line], u_count)

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:caretLineLast(clear_highlight)

	local core = self.core
	local lines = core.lines
	local disp = core.disp

	-- Find the last uChar offset for the current super-line + sub-line pair.
	local u_count = disp:getSubLineUCharOffsetEnd(disp.d_car_super, disp.d_car_sub)

	-- Convert to internal core byte offset
	core.car_byte = utf8.offset(lines[core.car_line], u_count)

	core:displaySyncCaretOffsets()
	core:updateVertPosHint()
	if clear_highlight then
		core:clearHighlight()
	else
		core:updateDispHighlightRange()
	end
end


function client:clickDragByWord(x, y, origin_line, origin_byte)

	local core = self.core

	local drag_line, drag_byte = core:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full words
	local dl1, db1, dl2, db2 = core:getWordRange(drag_line, drag_byte)
	local cl1, cb1, cl2, cb2 = core:getWordRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edCom.mergeRanges(dl1, db1, dl2, db2, cl1, cb1, cl2, cb2)

	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		core:caretAndHighlightToLineAndByte(ml1, mb1, ml2, mb2)

	else
		core:caretAndHighlightToLineAndByte(ml2, mb2, ml1, mb1)
	end
end


function client:clickDragByLine(x, y, origin_line, origin_byte)

	local core = self.core

	local drag_line, drag_byte = core:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full (wrapped) lines
	local drag_first, drag_last = core:getWrappedLineRange(drag_line, drag_byte)
	local click_first, click_last = core:getWrappedLineRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edCom.mergeRanges(
		drag_line, drag_first, drag_line, drag_last,
		origin_line, click_first, origin_line, click_last
	)
	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		core:caretAndHighlightToLineAndByte(ml1, mb1, ml2, mb2)

	else
		core:caretAndHighlightToLineAndByte(ml2, mb2, ml1, mb1)
	end
end


--- Helper that takes care of history changes following an action.
-- @param self The client widget
-- @param bound_func The wrapper function to call. It should take 'self' as its first argument, the EditField core as the second, and return values that control if and how the editField object is updated. For more info, see the bound_func(self) call here, and also `edit_act.lua`.
-- @return The results of bound_func(), in case they are helpful to the calling widget logic.
function client:executeBoundAction(bound_func)

	local core = self.core
	local disp = core.disp

	local old_line, old_byte, old_h_line, old_h_byte = core:getCaretOffsets()
	local update_viewport, caret_in_view, write_history = bound_func(self, core)

	--print("executeBoundAction()", "update_viewport", update_viewport, "caret_in_view", caret_in_view, "write_history", write_history)

	if update_viewport then
		-- XXX refresh: update scroll bounds
	end

	if caret_in_view then
		-- XXX refresh: tell client widget to get the caret in view
	end

	if write_history then
		core.input_category = false

		local hist = core.hist

		hist:doctorCurrentCaretOffsets(old_line, old_byte, old_h_line, old_h_byte)
		hist:writeEntry(true, core.lines, core.car_line, core.car_byte, core.h_line, core.h_byte)
	end

	return update_viewport, caret_in_view, write_history
end


function client:executeRemoteAction(item_t) -- XXX WIP

	local res_1, res_2, res_3 = self:executeBoundAction(item_t.bound_func)
	if res_1 then
		self.update_flag = true
	end

	self:updateDocumentDimensions(self) -- XXX WIP
	self:scrollGetCaretInBounds(true) -- XXX WIP
end


return client
