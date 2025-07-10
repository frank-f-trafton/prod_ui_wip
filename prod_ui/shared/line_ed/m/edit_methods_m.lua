-- To load: local lib = context:getLua("shared/lib")


--[[
	LineEditor plug-in methods for client widgets. Some internal-facing methods remain attached to 'line_ed'.
--]]


local context = select(1, ...)


local editMethodsM = {}
local client = editMethodsM


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


function client:getReplaceMode()
	return self.replace_mode
end


function client:setReplaceMode(enabled)
	self.replace_mode = not not enabled
end


-- * Font, Wrap, Align state, Width *


function client:getWrapMode()
	return self.line_ed.wrap_mode
end


-- @return true if the mode changed.
function client:setWrapMode(enabled)
	local line_ed = self.line_ed

	line_ed.wrap_mode = not not enabled

	self.line_ed:displaySyncAll()

	-- XXX refresh: clamp scroll and get caret in bounds
end


function client:getAlign()
	return self.line_ed.align
end


function client:setAlign(align)
	local line_ed = self.line_ed

	if align ~= "left" and align ~= "center" and align ~= "right" then
		error("arg #2: invalid align setting.")
	end

	local old_align = line_ed.align
	line_ed.align = align
	if old_align ~= align then
		-- Update just the alignment of sub-lines.
		self.line_ed:displaySyncAlign(1)
		self.line_ed:displaySyncCaretOffsets()

		-- XXX refresh: update align_offset, clamp scroll, get caret in bounds

		return true
	end
end


-- * / Font, Wrap, Align state, Width *


-- * Masking state *


function client:getMasking()
	local line_ed = self.line_ed

	return line_ed.masked, (line_ed.masked) and line_ed.mask_glyph or nil
end


function client:setMasking(enabled, optional_glyph)
	local line_ed = self.line_ed

	line_ed.masked = not not enabled

	if optional_glyph then
		self.line_ed:setMaskGlyph(optional_glyph)
	else
		self.line_ed:displaySyncAll()
	end
end


function client:setMaskGlyph(glyph)
	local line_ed = self.line_ed

	if utf8.len(glyph) ~= 1 then
		error("masking glyph must be exactly one code point.")
	end

	line_ed.mask_glyph = glyph
	self.line_ed:displaySyncAll()
end


-- * / Masking state *


-- * Colorization state *


function client:getColorization()
	return self.line_ed.generate_colored_text
end


function client:setColorization(enabled)
	local line_ed = self.line_ed
	line_ed.generate_colored_text = not not enabled

	-- Refresh everything
	self.line_ed:displaySyncAll()
end


-- * / Colorization state *


-- * Highlight State *


function client:getHighlightEnabled(enabled)
	-- No assertions.

	return self.allow_highlight
end


--- Enables or disables highlight selection mode. When disabling, any current selection is removed. (Should only be used immediately after widget is initialized. See source comments for more info.)
-- @param enabled true or false/nil.
function client:setHighlightEnabled(enabled)
	-- No assertions.

	local line_ed = self.line_ed

	local old_state = self.allow_highlight
	self.allow_highlight = not not enabled

	if old_state ~= self.allow_highlight then
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
		editHistM.applyEntry(self, entry)
		line_ed:displaySyncAll()
	end
end


-- * / History management *


-------------------- Unsorted --------------------


function client:getText(line_1, line_2) -- XXX maybe replace with a call to lines:copyString().
	local lines = self.line_ed.lines

	line_1 = line_1 or 1
	line_2 = line_2 or #lines

	return lines:copyString(line_1, 1, line_end, #lines[line_end])
end


function client:getHighlightedText()
	local line_ed = self.line_ed

	if line_ed:isHighlighted() then
		local lines = line_ed.lines

		local line_1, byte_1, line_2, byte_2 = line_ed:getHighlightOffsets()
		local text = lines:copy(line_1, byte_1, line_2, byte_2 - 1)

		return table.concat(text, "\n")
	end
end


function client:isHighlighted()
	return self.line_ed:isHighlighted()
end


function client:clearHighlight()
	self.line_ed:clearHighlight()
end


function client:highlightAll()
	local line_ed = self.line_ed

	line_ed.car_line = #line_ed.lines
	line_ed.car_byte = #line_ed.lines[line_ed.car_line] + 1

	line_ed.h_line = 1
	line_ed.h_byte = 1

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

	line_ed.car_line, line_ed.car_byte, line_ed.h_line, line_ed.h_byte = line_ed:getWordRange(line_ed.car_line, line_ed.car_byte)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateDispHighlightRange()
end


function client:highlightCurrentWrappedLine()
	local line_ed = self.line_ed
	local lines = line_ed.lines

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
	local font = line_ed.font
	local paragraphs = line_ed.paragraphs

	n_steps = n_steps or 1

	-- Already at top sub-line: move to start.
	if line_ed.d_car_para <= 1 and line_ed.d_car_sub <= 1 then
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
		local d_para, d_sub = edComM.stepSubLine(paragraphs, line_ed.d_car_para, line_ed.d_car_sub, -n_steps)

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
		local u_count = edComM.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
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
	local font = line_ed.font
	local paragraphs = line_ed.paragraphs

	n_steps = n_steps or 1

	-- Already at bottom sub-line: move to end.
	if line_ed.d_car_para >= #paragraphs and line_ed.d_car_sub >= #paragraphs[#paragraphs] then
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
		local d_para, d_sub = edComM.stepSubLine(paragraphs, line_ed.d_car_para, line_ed.d_car_sub, n_steps)

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
		local u_count = edComM.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
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
	local lines = line_ed.lines

	-- Sanitize input
	text = edComBase.cleanString(text, self.bad_input_rule, self.tabs_to_spaces, self.allow_line_feed)

	if not self.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		self:deleteHighlightedText()

	elseif self.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		self:deleteUChar(utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	line_ed.u_chars = lines:uLen()
	text = textUtil.trimString(text, self.u_chars_max - line_ed.u_chars)

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
	local line_1, byte_1, u_count = lines:countUChars(-1, line_ed.car_line, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		return line_ed:deleteText(true, line_1, byte_1, line_ed.car_line, line_ed.car_byte - 1)
	end
end


-- * Clipboard methods *


function client:copyHighlightedToClipboard()
	local line_ed = self.line_ed

	local copied = self:getHighlightedText()

	-- Don't leak masked string info.
	if line_ed.masked then
		copied = string.rep(line_ed.mask_glyph, utf8.len(copied))
	end

	copied = textUtil.sanitize(copied, self.bad_input_rule)

	love.system.setClipboardText(copied)
end


function client:cutHighlightedToClipboard()
	local line_ed = self.line_ed

	local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()

	local cut = self:deleteHighlightedText()

	if cut then
		cut = textUtil.sanitize(cut, self.bad_input_rule)

		-- Don't leak masked string info.
		if line_ed.masked then
			cut = table.concat(cut, "\n")
			cut = string.rep(line_ed.mask_glyph, utf8.len(cut))
		end

		love.system.setClipboardText(cut)

		self.input_category = false

		editHistM.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
		editHistM.writeEntry(line_ed, true)
	end
end


function client:pasteClipboardText()
	local line_ed = self.line_ed

	local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()

	if line_ed:isHighlighted() then
		self:deleteHighlightedText()
	end

	local text = love.system.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		self.input_category = false
		self:writeText(text, true)

		editHistM.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
		editHistM.writeEntry(line_ed, true)
	end
end


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function client:deleteHighlightedText()
	local line_ed = self.line_ed

	if not self:isHighlighted() then
		return
	end

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
	local line_2, byte_2, u_count = lines:countUChars(1, line_ed.car_line, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
		return line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_2, byte_2 - 1)
	end
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
		line_left, byte_left = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, -1, false, -1, true)
	end

	if line_left then
		if line_left ~= line_ed.car_line or byte_left ~= line_ed.car_byte then
			return line_ed:deleteText(true, line_left, byte_left, line_ed.car_line, line_ed.car_byte - 1)
		end
	end
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

		line_right, byte_right = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, 1, hit_non_ws, first_group, true)
		byte_right = byte_right - 1
		--print("deleteGroup: line_right", line_right, "byte_right", byte_right)
	end

	--print("ranges:", line_ed.car_line, line_ed.car_byte, line_right, byte_right)
	local del = line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_right, byte_right)
	--print("DEL", "|"..(del or "<nil>").."|")
	if del ~= "" then
		return del
	end
end


-- * / Clipboard methods *


function client:caretStepLeft(clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local new_line, new_byte = lines:offsetStepLeft(line_ed.car_line, line_ed.car_byte)
	if new_line then
		line_ed.car_line = new_line
		line_ed.car_byte = new_byte
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

	local new_line, new_byte = lines:offsetStepRight(line_ed.car_line, line_ed.car_byte)
	if new_line then
		line_ed.car_line = new_line
		line_ed.car_byte = math.max(1, new_byte)
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

	line_ed.car_line, line_ed.car_byte = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, -1, false, -1, false)

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
	line_ed.car_line, line_ed.car_byte = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, 1, hit_non_ws, first_group, false)

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

	-- Find the first uChar offset for the current Paragraph + sub-line pair.
	local u_count = line_ed:dispGetSubLineUCharOffsetStart(line_ed.d_car_para, line_ed.d_car_sub)

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

	-- Find the last uChar offset for the current Paragraph + sub-line pair.
	local u_count = line_ed:dispGetSubLineUCharOffsetEnd(line_ed.d_car_para, line_ed.d_car_sub)

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
	local ml1, mb1, ml2, mb2 = edComM.mergeRanges(dl1, db1, dl2, db2, cl1, cb1, cl2, cb2)

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
	local ml1, mb1, ml2, mb2 = edComM.mergeRanges(
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
-- @param bound_func The wrapper function to call. It should take 'self' as its first argument, the LineEditor core as the second, and return values that control if and how the lineEditor object is updated. For more info, see the bound_func(self) call here, and also EditAct.
-- @return The results of bound_func(), in case they are helpful to the calling widget logic.
function client:executeBoundAction(bound_func)
	local line_ed = self.line_ed

	local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()
	local ok, update_viewport, caret_in_view, write_history = bound_func(self, line_ed)

	--print("executeBoundAction()", "ok", ok, "update_viewport", update_viewport, "caret_in_view", caret_in_view, "write_history", write_history)
	if ok then
		if update_viewport then
			-- XXX refresh: update scroll bounds
		end

		if caret_in_view then
			-- XXX refresh: tell client widget to get the caret in view
		end

		if write_history then
			self.input_category = false

			editHistM.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
			editHistM.writeEntry(line_ed, true)
		end

		return true, update_viewport, caret_in_view, write_history
	end
end


return editMethodsM
