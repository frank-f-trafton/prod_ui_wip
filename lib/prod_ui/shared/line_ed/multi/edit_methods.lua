-- To load: local lib = context:getLua("shared/lib")


--[[
	LineEditor plug-in methods for client widgets. Some internal-facing methods remain attached to 'line_ed' and 'disp'.
--]]


local context = select(1, ...)


local editMethods = {}
editMethods.client = {}
local client = editMethods.client


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edCom = context:getLua("shared/line_ed/multi/ed_com")
local editDisp = context:getLua("shared/line_ed/multi/edit_disp")
local editHist = context:getLua("shared/line_ed/multi/edit_hist")
local lineEditor = context:getLua("shared/line_ed/multi/line_editor") -- XXX work on removing this reference (?)
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


local code_groups = lineEditor.code_groups


function client:getReplaceMode()
	return self.line_ed.replace_mode
end


--- When Replace Mode is active, new text overwrites existing characters under the caret.
function client:setReplaceMode(enabled)
	self.line_ed.replace_mode = not not enabled
end


-- * Font, Wrap, Align state, Width *


function client:getWrapMode()
	return self.line_ed.disp.wrap_mode
end


-- @return true if the mode changed.
function client:setWrapMode(enabled)

	local disp = self.line_ed.disp

	disp.wrap_mode = not not enabled

	self.line_ed:displaySyncAll()

	-- XXX refresh: clamp scroll and get caret in bounds
end
--[[
function def_wid:setWrapMode(enabled)

	local line_ed = self.line_ed
	local disp = line_ed.disp

	line_ed:setWrapMode(enabled)

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
	return self.line_ed.disp.font
end


function client:setFont(font)

	self.line_ed.disp:updateFont(font)
	self.line_ed:displaySyncAll()

	-- Force a cache update on the widget after calling this (self.update_flag = true).
end


function client:getAlign()
	return self.line_ed.disp.align
end


function client:setAlign(align)

	local disp = self.line_ed.disp

	if align ~= "left" and align ~= "center" and align ~= "right" then
		error("arg #2: invalid align setting.")
	end

	local old_align = disp.align
	disp.align = align
	if old_align ~= align then
		-- Update just the alignment of sub-lines.
		self.line_ed:displaySyncAlign(1)
		self.line_ed:displaySyncCaretOffsets()

		-- XXX refresh: update align_offset, clamp scroll, get caret in bounds

		return true
	end
end
--[[
function def_wid:setAlign(align)

	local line_ed = self.line_ed
	local disp = line_ed.disp

	if line_ed:setAlign(align) then
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

	local disp = self.line_ed.disp

	return disp.masked, (disp.masked) and disp.mask_glyph or nil
end


function client:setMasking(enabled, optional_glyph)

	local disp = self.line_ed.disp

	disp.masked = not not enabled

	if optional_glyph then
		self.line_ed:setMaskGlyph(optional_glyph)

	else
		self.line_ed:displaySyncAll()
	end
end


function client:setMaskGlyph(glyph)

	local disp = self.line_ed.disp

	if utf8.len(glyph) ~= 1 then
		error("masking glyph must be exactly one code point.")
	end

	disp.mask_glyph = glyph
	self.line_ed:displaySyncAll()
end


-- * / Masking state *


-- * Colorization state *


function client:getColorization()

	return self.line_ed.disp.generate_colored_text
end


function client:setColorization(enabled)

	local disp = self.line_ed.disp
	disp.generate_colored_text = not not enabled

	-- Refresh everything
	self.line_ed:displaySyncAll()
end


-- * / Colorization state *


-- * Highlight State *


function client:getHighlightEnabled(enabled)
	-- No assertions.

	return self.line_ed.allow_highlight
end


--- Enables or disables highlight selection mode. When disabling, any current selection is removed. (Should only be used immediately after widget is initialized. See source comments for more info.)
-- @param enabled true or false/nil.
function client:setHighlightEnabled(enabled)
	-- No assertions.

	local line_ed = self.line_ed

	local old_state = line_ed.allow_highlight
	line_ed.allow_highlight = not not enabled

	if old_state ~= line_ed.allow_highlight then
		line_ed:clearHighlight()
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
		local hist = self.line_ed.hist
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

	local line_ed = self.line_ed
	local hist = line_ed.hist

	local changed, entry = hist:moveToEntry(hist.pos + dir)

	if changed then
		editHist.applyEntry(self, entry)
		line_ed:displaySyncAll()
	end
end


-- * / History management *


-------------------- Unsorted --------------------


function client:getText(line_1, line_2) -- XXX maybe replace with a call to lines:copyString().

	local lines = self.line_ed.lines

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

	local line_ed = self.line_ed
	local disp = line_ed.disp

	if line_ed:isHighlighted() then
		local lines = line_ed.lines

		local line_1, byte_1, line_2, byte_2 = line_ed:getHighlightOffsets()
		local text = lines:copy(line_1, byte_1, line_2, byte_2 - 1)

		return table.concat(text, "\n")
	end

	return nil
end


function client:isHighlighted()
	return self.line_ed:isHighlighted()
end


function client:clearHighlight()
	self.line_ed:clearHighlight()
end


function client:highlightAll()

	local line_ed = self.line_ed

	line_ed.car_line = 1
	line_ed.car_byte = 1

	line_ed.h_line = #line_ed.lines
	line_ed.h_byte = #line_ed.lines[line_ed.h_line] + 1

	line_ed:displaySyncCaretOffsets()
	line_ed:updateDispHighlightRange()
end


--- Moves caret to the left highlight edge
function client:caretHighlightEdgeLeft()

	local line_ed = self.line_ed

	local line_1, byte_1, line_2, byte_2 = line_ed:getHighlightOffsets()

	line_ed.car_line = line_1
	line_ed.car_byte = byte_1
	line_ed.h_line = line_1
	line_ed.h_byte = byte_1

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	line_ed:updateDispHighlightRange()
end


--- Moves caret to the right highlight edge
function client:caretHighlightEdgeRight()

	local line_ed = self.line_ed

	local line_1, byte_1, line_2, byte_2 = line_ed:getHighlightOffsets()

	line_ed.car_line = line_2
	line_ed.car_byte = byte_2
	line_ed.h_line = line_2
	line_ed.h_byte = byte_2

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	line_ed:updateDispHighlightRange()
end


function client:highlightCurrentLine()

	local line_ed = self.line_ed

	line_ed.h_line = line_ed.car_line
	line_ed.car_byte, line_ed.h_byte = 1, #line_ed.lines[line_ed.car_line] + 1

	line_ed:displaySyncCaretOffsets()
	line_ed:updateDispHighlightRange()
end


function client:highlightCurrentWord()

	local line_ed = self.line_ed
	local disp = line_ed.disp

	line_ed.car_line, line_ed.car_byte, line_ed.h_line, line_ed.h_byte = line_ed:getWordRange(line_ed.car_line, line_ed.car_byte)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateDispHighlightRange()
end


function client:highlightCurrentWrappedLine()

	local line_ed = self.line_ed
	local lines = line_ed.lines
	local disp = line_ed.disp

	-- Temporarily move highlight point to caret, then pre-emptively update the display offsets
	-- so that we have fresh data to work from.
	line_ed.h_line = line_ed.car_line
	line_ed.h_byte = line_ed.car_byte

	line_ed:displaySyncCaretOffsets()

	line_ed.car_byte, line_ed.h_byte = line_ed:getWrappedLineRange(line_ed.car_line, line_ed.car_byte)

	--print("line_ed.car_byte", line_ed.car_byte, "line_ed.h_line", line_ed.h_byte)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	line_ed:updateDispHighlightRange()
end


function client:caretStepUp(clear_highlight, n_steps)

	local line_ed = self.line_ed
	local lines = line_ed.lines
	local disp = line_ed.disp
	local font = disp.font
	local paragraphs = disp.paragraphs

	n_steps = n_steps or 1

	-- Already at top sub-line: move to start.
	if disp.d_car_para <= 1 and disp.d_car_sub <= 1 then
		line_ed.car_line = 1
		line_ed.car_byte = 1

		line_ed:displaySyncCaretOffsets()
		line_ed:updateVertPosHint()
		if clear_highlight then
			line_ed:clearHighlight()
		else
			line_ed:updateDispHighlightRange()
		end

	else
		-- Get the offsets for the sub-line 'n_steps' above.
		local d_para, d_sub = editDisp.stepSubLine(paragraphs, disp.d_car_para, disp.d_car_sub, -n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = paragraphs[d_para][d_sub]
		local d_str = d_sub_t.str
		local new_byte, new_u_char, pixels = textUtil.getByteOffsetAtX(d_str, font, line_ed.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the Paragraph: correct leftmost position so that it doesn't
		-- spill over to the next sub-line (and get stuck).
		-- [[
		if d_sub < #paragraphs[d_para] then
			new_byte = math.min(#d_str, new_byte)
		end
		--]]

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edCom.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
		line_ed.car_line = d_para
		line_ed.car_byte = utf8.offset(lines[line_ed.car_line], u_count)

		line_ed:displaySyncCaretOffsets()
		if clear_highlight then
			line_ed:clearHighlight()
		else
			line_ed:updateDispHighlightRange()
		end
	end
end


function client:caretStepDown(clear_highlight, n_steps)

	local line_ed = self.line_ed
	local lines = line_ed.lines
	local disp = line_ed.disp
	local font = disp.font
	local paragraphs = disp.paragraphs

	n_steps = n_steps or 1

	-- Already at bottom sub-line: move to end.
	if disp.d_car_para >= #paragraphs and disp.d_car_sub >= #paragraphs[#paragraphs] then
		line_ed.car_line = #line_ed.lines
		line_ed.car_byte = #line_ed.lines[line_ed.car_line] + 1

		line_ed:displaySyncCaretOffsets()
		line_ed:updateVertPosHint()
		if clear_highlight then
			line_ed:clearHighlight()
		else
			line_ed:updateDispHighlightRange()
		end

	else
		-- Get the offsets for the sub-line 'n_steps' below.
		local d_para, d_sub = editDisp.stepSubLine(paragraphs, disp.d_car_para, disp.d_car_sub, n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = paragraphs[d_para][d_sub]
		local d_str = d_sub_t.str
		local new_byte, new_u_char, pixels = textUtil.getByteOffsetAtX(d_str, font, line_ed.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the Paragraph: correct rightmost position so that it doesn't
		-- spill over to the next sub-line.
		if d_sub < #paragraphs[d_para] then
			new_byte = math.min(#d_str, new_byte)
		end

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edCom.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
		line_ed.car_line = d_para
		line_ed.car_byte = utf8.offset(lines[line_ed.car_line], u_count)

		line_ed:displaySyncCaretOffsets()
		if clear_highlight then
			line_ed:clearHighlight()

		else
			line_ed:updateDispHighlightRange()
		end
	end
end


function client:caretStepUpCoreLine(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Already at top line: move to start.
	if line_ed.car_line <= 1 then
		line_ed.car_byte = 1

	-- Already at position 1 on the current line: move up one line
	elseif line_ed.car_byte == 1 then
		line_ed.car_line = math.max(1, line_ed.car_line - 1)
		line_ed.car_byte = 1

	-- Otherwise, move to position 1 in the current line.
	else
		line_ed.car_byte = 1
	end

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretStepDownCoreLine(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Already at bottom line: move to end.
	if line_ed.car_line == #lines then
		line_ed.car_byte = #lines[#lines] + 1

	-- Already at last position in logical line: move to next line
	elseif line_ed.car_byte == #lines[line_ed.car_line] + 1 then
		line_ed.car_line = math.min(line_ed.car_line + 1, #lines)
		line_ed.car_byte = #lines[line_ed.car_line] + 1

	-- Otherwise, move to the last position in the current line.
	else
		line_ed.car_byte = #lines[line_ed.car_line] + 1
	end

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretToXY(clear_highlight, x, y, split_x)

	local line_ed = self.line_ed

	local line_ed_line, line_ed_byte = line_ed:getCharacterDetailsAtPosition(x, y, split_x)

	line_ed:caretToLineAndByte(clear_highlight, line_ed_line, line_ed_byte)
end



--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
-- entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function client:writeText(text, suppress_replace)

	local line_ed = self.line_ed
	local disp = line_ed.disp
	local lines = line_ed.lines

	-- Sanitize input
	text = edCom.cleanString(text, line_ed.bad_input_rule, line_ed.tabs_to_spaces, line_ed.allow_line_feed)

	if not line_ed.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		self:deleteHighlightedText()

	elseif line_ed.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		local n_to_delete = edCom.countUChars(text, math.huge)
		self:deleteUChar(n_to_delete)
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	line_ed.u_chars = lines:uLen()
	text = edCom.trimString(text, line_ed.u_chars, line_ed.u_chars_max)

	line_ed:insertText(text)

	return text
end


--- Set the current internal text, wiping anything currently present.
function client:setText(text)

	local line_ed = self.line_ed

	local deleted = self:deleteAll()
	line_ed:insertText(text)

	return deleted
end


--- Delete characters by stepping backwards from the caret position.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:backspaceUChar(n_u_chars)

	local line_ed = self.line_ed
	line_ed:highlightCleanup()

	local lines = line_ed.lines
	local line_1, byte_1, u_count = lines:countUCharsLeft(line_ed.car_line, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		return line_ed:deleteText(true, line_1, byte_1, line_ed.car_line, line_ed.car_byte - 1)
	end

	return nil
end


-- * Clipboard methods *


function client:copyHighlightedToClipboard()

	local line_ed = self.line_ed
	local disp = line_ed.disp

	local copied = self:getHighlightedText()

	-- Don't leak masked string info.
	if disp.masked then
		copied = string.rep(disp.mask_glyph, utf8.len(copied))
	end

	copied = textUtil.sanitize(copied, line_ed.bad_input_rule)

	edCom.setClipboardText(copied)
end


function client:cutHighlightedToClipboard()

	local line_ed = self.line_ed
	local disp = line_ed.disp
	local hist = line_ed.hist

	local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()

	local cut = self:deleteHighlightedText()

	if cut then
		cut = textUtil.sanitize(cut, self.bad_input_rule)

		-- Don't leak masked string info.
		if disp.masked then
			cut = table.concat(cut, "\n")
			cut = string.rep(disp.mask_glyph, utf8.len(cut))
		end

		edCom.setClipboardText(cut)

		self.input_category = false

		editHist.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
		editHist.writeEntry(line_ed, true)
	end
end


function client:pasteClipboardText()

	local line_ed = self.line_ed
	local hist = line_ed.hist

	local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()

	if line_ed:isHighlighted() then
		self:deleteHighlightedText()
	end

	local text = edCom.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		line_ed.input_category = false
		self:writeText(text, true)

		editHist.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
		editHist.writeEntry(line_ed, true)
	end
end


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function client:deleteHighlightedText()

	local line_ed = self.line_ed

	if not self:isHighlighted() then
		return nil
	end

	local lines = line_ed.lines

	-- Clean up display highlight beforehand. Much harder to determine the offsets after deleting things.
	local line_1, byte_1, line_2, byte_2 = line_ed:getHighlightOffsets()
	line_ed:highlightCleanup()

	return line_ed:deleteText(true, line_1, byte_1, line_2, byte_2 - 1)
end


function client:deleteLine()

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines

	local retval
	-- Multi-line, caret is not on the last line
	if line_ed.car_line < #lines then
		retval = line_ed:deleteText(true, line_ed.car_line, 1, line_ed.car_line + 1, 0)

	-- Multi-line, on the last line
	elseif line_ed.car_line > 1 then
		retval = line_ed:deleteText(true, line_ed.car_line - 1, #lines[line_ed.car_line - 1] + 1, line_ed.car_line, #lines[line_ed.car_line])

	-- Document is a single empty line
	elseif #lines[1] == 0 then
		retval = nil

	-- Document is a single line, with contents that can be deleted
	else
		retval = line_ed:deleteText(true, line_ed.car_line, 1, line_ed.car_line, #lines[line_ed.car_line])
	end

	-- Force to position 1 of the current line and recache caret details
	line_ed.car_byte = 1
	line_ed.h_byte = 1

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()

	return retval
end


function client:deleteCaretToLineEnd()

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines

	return line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_ed.car_line, #lines[line_ed.car_line])
end


function client:deleteCaretToLineStart()

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines

	return line_ed:deleteText(true, line_ed.car_line, 1, line_ed.car_line, line_ed.car_byte - 1)
end


--- Delete characters on and to the right of the caret.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:deleteUChar(n_u_chars)

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines
	local line_2, byte_2, u_count = lines:countUCharsRight(line_ed.car_line, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
		return line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_2, byte_2 - 1)
	end

	return nil
end


function client:deleteAll()

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines

	return line_ed:deleteText(true, 1, 1, #lines, #lines[#lines])
end


function client:backspaceGroup()

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines
	local line_left, byte_left

	if line_ed.car_byte == 1 and line_ed.car_line > 1 then
		line_left = line_ed.car_line  - 1
		byte_left = #lines[line_left] + 1

	else
		line_left, byte_left = lineEditor.huntWordBoundary(lines, line_ed.car_line, line_ed.car_byte, -1, false, -1, true)
	end

	if line_left then
		if line_left ~= line_ed.car_line or byte_left ~= line_ed.car_byte then
			return line_ed:deleteText(true, line_left, byte_left, line_ed.car_line, line_ed.car_byte - 1)
		end
	end

	return nil
end


function client:deleteGroup()

	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines
	local line_right, byte_right

	if line_ed.car_byte == #lines[line_ed.car_line] + 1 and line_ed.car_line < #lines then
		line_right = line_ed.car_line + 1
		byte_right = 0

	else
		local hit_non_ws = false
		local peeked = lines:peekCodePoint(line_ed.car_line, line_ed.car_byte)
		local first_group = code_groups[peeked]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end
		--print("HIT_NON_WS", hit_non_ws, "PEEKED", peeked, "FIRST_GROUP", first_group)

		line_right, byte_right = lineEditor.huntWordBoundary(lines, line_ed.car_line, line_ed.car_byte, 1, hit_non_ws, first_group, true)
		byte_right = byte_right - 1
		--print("deleteGroup: line_right", line_right, "byte_right", byte_right)

		--[[
		-- If the range is a single-byte code point, and a code point to the right exists, move one step over.
		if line_right == line_ed.car_line and byte_right == line_ed.car_byte then
			line_right, byte_right = lines:offsetStepRight(line_right, byte_right)
			if not line_right then
				return nil
			end
		end
		--]]

	end

	--print("ranges:", line_ed.car_line, line_ed.car_byte, line_right, byte_right)
	local del = line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_right, byte_right)
	--print("DEL", "|"..(del or "<nil>").."|")
	if del ~= "" then
		return del
	else
		return nil
	end
end


-- * / Clipboard methods *


function client:caretStepLeft(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines

	local left_pos = textUtil.utf8StartByteLeft(lines[line_ed.car_line], line_ed.car_byte - 1)

	-- Move back one uChar
	if left_pos then
		line_ed.car_byte = left_pos

	-- Move to end of previous line
	elseif line_ed.car_line > 1 then
		line_ed.car_line = line_ed.car_line - 1
		line_ed.car_byte = #lines[line_ed.car_line] + 1
	end

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()

	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretStepRight(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines

	local right_pos = textUtil.utf8StartByteRight(lines[line_ed.car_line], line_ed.car_byte + 1)

	-- Move right one uChar
	if right_pos then
		line_ed.car_byte = right_pos

	-- Move to start of next line
	elseif line_ed.car_line < #lines then
		line_ed.car_line = line_ed.car_line + 1
		line_ed.car_byte = 1
	end

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretJumpLeft(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed.car_line, line_ed.car_byte = lineEditor.huntWordBoundary(lines, line_ed.car_line, line_ed.car_byte, -1, false, -1, false)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretJumpRight(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines

	local hit_non_ws = false
	local first_group = code_groups[lines:peekCodePoint(line_ed.car_line, line_ed.car_byte)]
	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	--print("hit_non_ws", hit_non_ws, "first_group", first_group)

	--(lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed)
	line_ed.car_line, line_ed.car_byte = lineEditor.huntWordBoundary(lines, line_ed.car_line, line_ed.car_byte, 1, hit_non_ws, first_group, false)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end

	-- One more step to land on the right position. -- XXX okay to delete?
	--self:caretStepRight(clear_highlight)
end


function client:caretFirst(clear_highlight)

	local line_ed = self.line_ed

	line_ed.car_line = 1
	line_ed.car_byte = 1

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretLast(clear_highlight)

	local line_ed = self.line_ed

	line_ed.car_line = #line_ed.lines
	line_ed.car_byte = #line_ed.lines[line_ed.car_line] + 1

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretLineFirst(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines
	local disp = line_ed.disp

	-- Find the first uChar offset for the current Paragraph + sub-line pair.
	local u_count = disp:getSubLineUCharOffsetStart(disp.d_car_para, disp.d_car_sub)

	-- Convert the display u_count to a byte offset in the line_ed/source string.
	line_ed.car_byte = utf8.offset(lines[line_ed.car_line], u_count)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretLineLast(clear_highlight)

	local line_ed = self.line_ed
	local lines = line_ed.lines
	local disp = line_ed.disp

	-- Find the last uChar offset for the current Paragraph + sub-line pair.
	local u_count = disp:getSubLineUCharOffsetEnd(disp.d_car_para, disp.d_car_sub)

	-- Convert to internal line_ed byte offset
	line_ed.car_byte = utf8.offset(lines[line_ed.car_line], u_count)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateVertPosHint()
	if clear_highlight then
		line_ed:clearHighlight()
	else
		line_ed:updateDispHighlightRange()
	end
end


function client:clickDragByWord(x, y, origin_line, origin_byte)

	local line_ed = self.line_ed

	local drag_line, drag_byte = line_ed:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full words
	local dl1, db1, dl2, db2 = line_ed:getWordRange(drag_line, drag_byte)
	local cl1, cb1, cl2, cb2 = line_ed:getWordRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edCom.mergeRanges(dl1, db1, dl2, db2, cl1, cb1, cl2, cb2)

	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		line_ed:caretAndHighlightToLineAndByte(ml1, mb1, ml2, mb2)

	else
		line_ed:caretAndHighlightToLineAndByte(ml2, mb2, ml1, mb1)
	end
end


function client:clickDragByLine(x, y, origin_line, origin_byte)

	local line_ed = self.line_ed

	local drag_line, drag_byte = line_ed:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full (wrapped) lines
	local drag_first, drag_last = line_ed:getWrappedLineRange(drag_line, drag_byte)
	local click_first, click_last = line_ed:getWrappedLineRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edCom.mergeRanges(
		drag_line, drag_first, drag_line, drag_last,
		origin_line, click_first, origin_line, click_last
	)
	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		line_ed:caretAndHighlightToLineAndByte(ml1, mb1, ml2, mb2)

	else
		line_ed:caretAndHighlightToLineAndByte(ml2, mb2, ml1, mb1)
	end
end


--- Helper that takes care of history changes following an action.
-- @param self The client widget
-- @param bound_func The wrapper function to call. It should take 'self' as its first argument, the LineEditor core as the second, and return values that control if and how the lineEditor object is updated. For more info, see the bound_func(self) call here, and also `edit_act.lua`.
-- @return The results of bound_func(), in case they are helpful to the calling widget logic.
function client:executeBoundAction(bound_func)

	local line_ed = self.line_ed
	local disp = line_ed.disp

	local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()
	local update_viewport, caret_in_view, write_history = bound_func(self, line_ed)

	--print("executeBoundAction()", "update_viewport", update_viewport, "caret_in_view", caret_in_view, "write_history", write_history)

	if update_viewport then
		-- XXX refresh: update scroll bounds
	end

	if caret_in_view then
		-- XXX refresh: tell client widget to get the caret in view
	end

	if write_history then
		line_ed.input_category = false

		editHist.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
		editHist.writeEntry(line_ed, true)
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
