-- LineEditor (multi) widget functions.


local context = select(1, ...)


local editFuncM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edCom = context:getLua("shared/line_ed/ed_com")
local code_groups = context:getLua("shared/line_ed/code_groups")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")


function editFuncM.cutHighlightedToClipboard(self)
	local LE = self.LE

	local cut = editFuncM.deleteHighlighted(self)
	if cut then
		cut = textUtil.sanitize(cut, self.LE_bad_input_rule)
		love.system.setClipboardText(cut)
		return cut
	end
end


function editFuncM.copyHighlightedToClipboard(self)
	local LE = self.LE

	local copied = self:getHighlightedText()
	copied = textUtil.sanitize(copied, self.LE_bad_input_rule)

	love.system.setClipboardText(copied)
end


function editFuncM.pasteClipboard(self)
	local LE = self.LE

	local text = love.system.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		if LE:isHighlighted() then
			editFuncM.deleteHighlighted(self)
		end

		return not not editFuncM.writeText(self, text, true)
	end
end


function editFuncM.deleteAll(self)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	return LE:deleteText(true, 1, 1, #lines, #lines[#lines])
end


function editFuncM.deleteCaretToLineStart(self)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	return LE:deleteText(true, LE.cl, 1, LE.cl, LE.cb - 1)
end


function editFuncM.deleteCaretToLineEnd(self)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	return LE:deleteText(true, LE.cl, LE.cb, LE.cl, #lines[LE.cl])
end


function editFuncM.backspaceGroup(self)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	local line_left, byte_left

	if LE.cb == 1 and LE.cl > 1 then
		line_left = LE.cl  - 1
		byte_left = #lines[line_left] + 1
	else
		line_left, byte_left = edComM.huntWordBoundary(code_groups, lines, LE.cl, LE.cb, -1, false, -1, true)
	end

	if line_left then
		if line_left ~= LE.cl or byte_left ~= LE.cb then
			return LE:deleteText(true, line_left, byte_left, LE.cl, LE.cb - 1)
		end
	end
end


function editFuncM.caretToHighlightEdgeLeft(self)
	local LE = self.LE

	local l1, b1 = LE:getCaretOffsetsInOrder()
	LE:moveCaret(l1, b1, true, true)
end


function editFuncM.caretToHighlightEdgeRight(self)
	local LE = self.LE

	local _, _, l2, b2 = LE:getCaretOffsetsInOrder()
	LE:moveCaret(l2, b2, true, true)
end


function editFuncM.caretStepLeft(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	local cl, cb = lines:offsetStepLeft(LE.cl, LE.cb)
	if cl then
		LE:moveCaret(cl, cb, clear_highlight, true)
	end
end


function editFuncM.caretStepRight(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	local cl, cb = lines:offsetStepRight(LE.cl, LE.cb)
	if cl then
		LE:moveCaret(cl, math.max(1, cb), clear_highlight, true)
	end
end


function editFuncM.caretJumpLeft(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	local cl, cb = edComM.huntWordBoundary(code_groups, lines, LE.cl, LE.cb, -1, false, -1, false)
	LE:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretJumpRight(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	local hit_non_ws = false
	local first_group = code_groups[lines:peekCodePoint(LE.cl, LE.cb)]
	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	local cl, cb = edComM.huntWordBoundary(code_groups, lines, LE.cl, LE.cb, 1, hit_non_ws, first_group, false)
	LE:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretFullLineFirst(self, clear_highlight)
	local LE = self.LE

	LE:moveCaret(LE.cl, 1, clear_highlight, true)
end


function editFuncM.caretFullLineLast(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	LE:moveCaret(LE.cl, #lines[LE.cl] + 1, clear_highlight, true)
end


function editFuncM.caretSubLineFirst(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	-- Find the first uChar offset for the current Paragraph + sub-line pair.
	local u_count = edComM.getSubLineUCharOffsetStart(LE.paragraphs[LE.dcp], LE.dcs)

	-- Convert the display u_count to a byte offset in the LineEd/source string.
	local cl, cb = LE.cl, utf8.offset(lines[LE.cl], u_count)
	LE:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretSubLineLast(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	-- Find the last uChar offset for the current Paragraph + sub-line pair.
	local u_count = edComM.getSubLineUCharOffsetEnd(LE.paragraphs[LE.dcp], LE.dcs)

	-- Convert to internal LineEd byte offset
	local cl, cb = LE.cl, utf8.offset(lines[LE.cl], u_count)
	LE:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretLineFirst(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	local cl, cb, hl, hb = LE:getCaretOffsets()
	editFuncM.caretSubLineFirst(self, clear_highlight)
	if LE:compareCaretOffsets(cl, cb, hl, hb) then
		editFuncM.caretFullLineFirst(self, clear_highlight)
	end
end


function editFuncM.caretLineLast(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	local cl, cb, hl, hb = LE:getCaretOffsets()
	editFuncM.caretSubLineLast(self, clear_highlight)
	if LE:compareCaretOffsets(cl, cb, hl, hb) then
		editFuncM.caretFullLineLast(self, clear_highlight)
	end
end


function editFuncM.caretFirst(self, clear_highlight)
	local LE = self.LE

	LE:moveCaret(1, 1, clear_highlight, true)
end


function editFuncM.caretLast(self, clear_highlight)
	local LE = self.LE

	LE:moveCaret(#LE.lines, #LE.lines[#LE.lines] + 1, clear_highlight, true)
end


function editFuncM.caretStepUp(self, clear_highlight, n_steps)
	local LE = self.LE
	local lines = LE.lines
	local font = LE.font
	local paragraphs = LE.paragraphs

	n_steps = n_steps or 1

	-- Already at top sub-line: move to start.
	if LE.dcp <= 1 and LE.dcs <= 1 then
		LE:moveCaret(1, 1, clear_highlight, true)
	else
		-- Get the offsets for the sub-line 'n_steps' above.
		local d_para, d_sub = edComM.stepSubLine(paragraphs, LE.dcp, LE.dcs, -n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = paragraphs[d_para][d_sub]
		local d_str = d_sub_t.str
		local new_byte, new_u_char, pixels = textUtil.getByteOffsetAtX(d_str, font, LE.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the Paragraph: correct leftmost position so that it doesn't
		-- spill over to the next sub-line (and get stuck).
		if d_sub < #paragraphs[d_para] then
			new_byte = math.min(#d_str, new_byte)
		end

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edComM.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
		LE:moveCaret(d_para, utf8.offset(lines[d_para], u_count), clear_highlight, false)
	end
end


function editFuncM.caretStepDown(self, clear_highlight, n_steps)
	local LE = self.LE
	local lines = LE.lines
	local font = LE.font
	local paragraphs = LE.paragraphs

	n_steps = n_steps or 1

	-- Already at bottom sub-line: move to end.
	if LE.dcp >= #paragraphs and LE.dcs >= #paragraphs[#paragraphs] then
		LE:moveCaret(#LE.lines, #LE.lines[LE.cl] + 1, clear_highlight, true)
	else
		-- Get the offsets for the sub-line 'n_steps' below.
		local d_para, d_sub = edComM.stepSubLine(paragraphs, LE.dcp, LE.dcs, n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = paragraphs[d_para][d_sub]
		local d_str = d_sub_t.str
		local new_byte, new_u_char, pixels = textUtil.getByteOffsetAtX(d_str, font, LE.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the Paragraph: correct rightmost position so that it doesn't
		-- spill over to the next sub-line.
		if d_sub < #paragraphs[d_para] then
			new_byte = math.min(#d_str, new_byte)
		end

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edComM.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
		LE:moveCaret(d_para, utf8.offset(lines[d_para], u_count), clear_highlight, false)
	end
end


function editFuncM.caretStepUpCoreLine(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	-- Already at top line: move to start.
	if LE.cl <= 1 then
		LE:moveCaret(LE.cl, 1, clear_highlight, true)

	-- Already at position 1 on the current line: move up one line
	elseif LE.cb == 1 then
		LE:moveCaret(math.max(1, LE.cl - 1), 1, clear_highlight, true)

	-- Otherwise, move to position 1 in the current line.
	else
		LE:moveCaret(LE.cl, 1, clear_highlight, true)
	end
end


function editFuncM.caretStepDownCoreLine(self, clear_highlight)
	local LE = self.LE
	local lines = LE.lines

	-- Already at bottom line: move to end.
	if LE.cl == #lines then
		LE:moveCaret(LE.cl, #lines[#lines] + 1, clear_highlight, true)

	-- Already at last position in logical line: move to next line
	elseif LE.cb == #lines[LE.cl] + 1 then
		LE:moveCaret(math.min(LE.cl + 1, #lines), #lines[LE.cl] + 1, clear_highlight, true)

	-- Otherwise, move to the last position in the current line.
	else
		LE:moveCaret(LE.cl, #lines[LE.cl] + 1, clear_highlight, true)
	end
end


function editFuncM.shiftLinesUp(self)
	local LE = self.LE
	local lines = LE.lines

	local r1, r2 = LE:getSelectedLinesRange(true)
	local displaced_line = lines[r1 - 1]

	if displaced_line then
		LE:clearHighlight()

		for i = r1 - 1, r2 - 1 do
			lines[i] = lines[i + 1]
		end

		lines[r2] = displaced_line
		LE:updateDisplayText(r1 - 1, r2)
		LE:moveCaretAndHighlight(r1 - 1, 1, r2 - 1, #lines[r2 - 1] + 1, true)
		LE:syncDisplayCaretHighlight(r1 - 1, r2)

		return true
	end
end


function editFuncM.shiftLinesDown(self)
	local LE = self.LE
	local lines = LE.lines

	local r1, r2 = LE:getSelectedLinesRange(true)
	local displaced_line = lines[r2 + 1]

	if displaced_line then
		LE:clearHighlight()

		for i = r2 + 1, r1 + 1, -1 do
			lines[i] = lines[i - 1]
		end

		lines[r1] = displaced_line
		LE:updateDisplayText(r1, r2 + 1)
		LE:moveCaretAndHighlight(r1 + 1, 1, r2 + 1, #lines[r2 + 1] + 1, true)
		LE:syncDisplayCaretHighlight(r1, r2 + 1)

		return true
	end
end


function editFuncM.deleteHighlighted(self)
	local LE = self.LE

	if self:isHighlighted() then
		local l1, b1, l2, b2 = LE:getCaretOffsetsInOrder()
		LE:clearHighlight()
		return LE:deleteText(true, l1, b1, l2, b2 - 1)
	end
end


function editFuncM.backspaceUChar(self, n_u_chars)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	local line_1, byte_1, u_count = lines:countUChars(-1, LE.cl, LE.cb, n_u_chars)

	if u_count > 0 then
		return LE:deleteText(true, line_1, byte_1, LE.cl, LE.cb - 1)
	end
end


function editFuncM.deleteUChar(self, n_u_chars)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	local line_2, byte_2, u_count = lines:countUChars(1, LE.cl, LE.cb, n_u_chars)

	if u_count > 0 then
		-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
		return LE:deleteText(true, LE.cl, LE.cb, line_2, byte_2 - 1)
	end
end


function editFuncM.deleteGroup(self)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	local line_right, byte_right
	if LE.cb == #lines[LE.cl] + 1 and LE.cl < #lines then
		line_right = LE.cl + 1
		byte_right = 0
	else
		local hit_non_ws = false
		local peeked = lines:peekCodePoint(LE.cl, LE.cb)
		local first_group = code_groups[peeked]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end

		line_right, byte_right = edComM.huntWordBoundary(code_groups, lines, LE.cl, LE.cb, 1, hit_non_ws, first_group, true)
		byte_right = byte_right - 1
	end

	return LE:deleteText(true, LE.cl, LE.cb, line_right, byte_right)
end


function editFuncM.deleteLine(self)
	local LE = self.LE
	local lines = LE.lines

	LE:clearHighlight()

	local retval
	-- Multi-line, caret is not on the last line
	if LE.cl < #lines then
		retval = LE:deleteText(true, LE.cl, 1, LE.cl + 1, 0)

	-- Multi-line, on the last line
	elseif LE.cl > 1 then
		retval = LE:deleteText(true, LE.cl - 1, #lines[LE.cl - 1] + 1, LE.cl, #lines[LE.cl])

	-- Document is a single empty line
	elseif #lines[1] == 0 then
		retval = nil

	-- Document is a single line, with contents that can be deleted
	else
		retval = LE:deleteText(true, LE.cl, 1, LE.cl, #lines[LE.cl])
	end

	LE:moveCaretAndHighlight(self.cl, 1, self.hl, 1)

	return retval
end


function editFuncM.typeLineFeedWithAutoIndent(self)
	local LE = self.LE

	self.LE_input_category = false

	local new_str = "\n"

	if self.LE_auto_indent then
		local top_selected_line = math.min(LE.cl, LE.hl)
		local leading_white_space = string.match(LE.lines[top_selected_line], "^%s+")
		if leading_white_space then
			new_str = new_str .. leading_white_space
		end
	end

	editFuncM.writeText(self, new_str, true)
end


function editFuncM.typeLineFeed(self)
	self.LE_input_category = false
	editFuncM.writeText(self, "\n", true)
end


local function _indentLine(self, line_n)
	local LE = self.LE

	local old_line = LE.lines[line_n]

	LE:moveCaretAndHighlight(line_n, 1, line_n, 1, false)
	LE:insertText("\t")

	return old_line ~= LE.lines[line_n]
end


local function _unindentLine(self, line_n)
	local LE = self.LE

	local old_line = LE.lines[line_n]

	if old_line:sub(1, 1) == "\t" then
		LE:deleteText(false, line_n, 1, line_n, 1)
	else
		local space1, space2 = old_line:find("^[\x20]+") -- (0x20 == space)
		if space1 then
			local offset = ((space2 - 1) % 4) -- XXX space tab width should be a config setting somewhere.
			LE:deleteText(false, line_n, 1, line_n, offset)
		end
	end

	return old_line ~= LE.lines[line_n]
end


function editFuncM.typeTab(self)
	local LE = self.LE

	local changed = false

	-- Caret and highlight are on the same line: write a literal tab.
	-- (Unhighlights first)
	if LE.cl == LE.hl then
		local written = editFuncM.writeText(self, "\t", true)

		if written and #written > 0 then
			changed = true
		end
	-- Caret and highlight are on different lines: indent the range of lines.
	else
		local r1, r2 = LE:getSelectedLinesRange(true)

		-- Only perform the indent if the total number of added tabs will not take us beyond
		-- the max code points setting.
		local tab_count = 1 + (r2 - r1)
		if LE.u_chars + tab_count <= self.LE_u_chars_max then
			for i = r1, r2 do
				local line_changed = _indentLine(self, i) -- TODO: slow implementation.
				if line_changed then
					changed = true
				end
			end
			LE:moveCaretAndHighlight(r2, #LE.lines[r2] + 1, r1, 1)
		end
	end

	return changed
end


function editFuncM.typeUntab(self)
	local LE = self.LE

	local changed = false
	local r1, r2 = LE:getSelectedLinesRange(true)
	local tab_count = 1 + (r2 - r1)

	for i = r1, r2 do
		local line_changed = _unindentLine(self, i) -- TODO: slow implementation.

		if line_changed then
			changed = true
		end
	end
	if changed then
		LE:moveCaretAndHighlight(r2, #LE.lines[r2] + 1, r1, 1)
	end

	return changed
end


function editFuncM.highlightAll(self)
	local LE = self.LE

	LE:moveCaretAndHighlight(#LE.lines, #LE.lines[LE.cl] + 1, 1, 1, true)
end


function editFuncM.clearHighlight(self)
	local LE = self.LE

	self.LE:clearHighlight()
end


function editFuncM.highlightCurrentLine(self)
	local LE = self.LE

	LE:moveCaretAndHighlight(LE.cl, 1, LE.hl, #LE.lines[LE.cl] + 1, true)
end


function editFuncM.highlightCurrentWord(self)
	local LE = self.LE

	local cl, cb, hl, hb = LE:getWordRange(LE.cl, LE.cb)
	LE:moveCaretAndHighlight(cl, cb, hl, hb, true)
end


function editFuncM.highlightCurrentWrappedLine(self)
	local LE = self.LE
	local lines = LE.lines

	local cl, hl = LE.cl, LE.cl
	local cb, hb = LE:getWrappedLineRange(LE.cl, LE.cb)
	LE:moveCaretAndHighlight(cl, cb, hl, hb, true)

	--print("LE.cb", LE.cb, "LE.hl", LE.hb)
end


function editFuncM.stepHistory(self, dir)
	local LE = self.LE

	-- -1 == undo, 1 == redo

	local hist = self.LE_hist
	local changed, entry = hist:moveToEntry(hist.pos + dir)

	if changed then
		editFuncM.applyHistoryEntry(self, entry)
		LE:updateDisplayText()
		LE:syncDisplayCaretHighlight()
		return true
	end
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized, and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
--	entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field, or nil if no text was added.
function editFuncM.writeText(self, text, suppress_replace)
	local LE = self.LE
	local lines = LE.lines

	-- Sanitize input
	text = edCom.cleanString(text, self.LE_bad_input_rule, self.LE_tabs_to_spaces, self.LE_allow_line_feed)

	if not self.LE_allow_highlight then
		LE:clearHighlight()
	end

	-- If there is a highlighted selection, get rid of it and insert the new text. This overrides Replace Mode.
	if LE:isHighlighted() then
		editFuncM.deleteHighlighted(self)

	elseif self.LE_replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		editFuncM.deleteUChar(self, utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	LE.u_chars = lines:uLen()
	text = textUtil.trimString(text, self.LE_u_chars_max - LE.u_chars)

	if #text > 0 then
		LE:insertText(text)

		return text
	end
end


function editFuncM.replaceText(self, text)
	local LE = self.LE

	LE:deleteText(false, 1, 1, #LE.lines, #LE.lines[#LE.lines])
	return editFuncM.writeText(self, text, true)
end


function editFuncM.setText(self, text)
	-- Like replaceText(), but also wipes history.
	editFuncM.replaceText(self, text)
	editFuncM.wipeHistoryEntries(self)
end


--- Enables or disables highlight selection mode. When disabling, any current selection is removed. (Should only be
--	used right after the widget is initialized, because a populated history ledger may contain entries with highlights.)
-- @param enabled true or false/nil.
function editFuncM.setAllowHighlight(self, enabled)
	local LE = self.LE

	enabled = not not enabled
	if self.LE_allow_highlight ~= enabled then
		self.LE_allow_highlight = enabled
		if not enabled then
			LE:clearHighlight()
		end
		return true
	end
end


function editFuncM.initHistoryEntry(self, entry)
	local LE = self.LE
	local src_lines = LE.lines

	entry.lines = entry.lines or {}
	local cl, cb, hl, hb = LE:getCaretOffsets()

	for i = #entry.lines, #src_lines + 1, -1 do
		entry.lines[i] = nil
	end
	for i = 1, #src_lines do
		entry.lines[i] = src_lines[i]
	end

	entry.cl, entry.cb, entry.hl, entry.hb = cl, cb, hl, hb
end


function editFuncM.writeHistoryEntry(self, do_advance)
	local entry = self.LE_hist:writeEntry(do_advance)
	editFuncM.initHistoryEntry(self, entry)
	return entry
end


function editFuncM.applyHistoryEntry(self, entry)
	local LE = self.LE
	local src_lines = LE.lines
	local paragraphs = LE.paragraphs
	local entry_lines = entry.lines

	for i = 1, #entry_lines do
		src_lines[i] = entry_lines[i]
	end
	for i = #src_lines, #entry_lines + 1, -1 do
		src_lines[i] = nil
		paragraphs[i] = nil
	end

	LE.cl, LE.cb, LE.hl, LE.hb = entry.cl, entry.cb, entry.hl, entry.hb
end


function editFuncM.doctorHistoryCaretOffsets(self, cl, cb, hl, hb)
	local hist = self.LE_hist
	local entry = hist.ledger[hist.pos]

	if entry then
		entry.cl, entry.cb, entry.hl, entry.hb = cl, cb, hl, hb
	end
end


-- Deletes all history entries, then writes a new entry based on the current LineEd state.
-- Also clears the widget's input category.
function editFuncM.wipeHistoryEntries(self)
	self.LE_hist:clearAll()
	self:resetInputCategory()
	editFuncM.writeHistoryEntry(self, false)
end


return editFuncM
