-- LineEditor (multi) widget functions.


local context = select(1, ...)


local editFuncM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local code_groups = context:getLua("shared/line_ed/code_groups")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")


function editFuncM.cutHighlightedToClipboard(self)
	local line_ed = self.line_ed

	local cut = editFuncM.deleteHighlighted(self)
	if cut then
		cut = textUtil.sanitize(cut, self.bad_input_rule)
		love.system.setClipboardText(cut)
		return cut
	end
end


function editFuncM.copyHighlightedToClipboard(self)
	local line_ed = self.line_ed

	local copied = self:getHighlightedText()
	copied = textUtil.sanitize(copied, self.bad_input_rule)

	love.system.setClipboardText(copied)
end


function editFuncM.pasteClipboard(self)
	local line_ed = self.line_ed

	local text = love.system.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		if line_ed:isHighlighted() then
			editFuncM.deleteHighlighted(self)
		end

		return not not editFuncM.writeText(self, text, true)
	end
end


function editFuncM.deleteAll(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	return line_ed:deleteText(true, 1, 1, #lines, #lines[#lines])
end


function editFuncM.deleteCaretToLineStart(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	return line_ed:deleteText(true, line_ed.cl, 1, line_ed.cl, line_ed.cb - 1)
end


function editFuncM.deleteCaretToLineEnd(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	return line_ed:deleteText(true, line_ed.cl, line_ed.cb, line_ed.cl, #lines[line_ed.cl])
end


function editFuncM.backspaceGroup(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	local line_left, byte_left

	if line_ed.cb == 1 and line_ed.cl > 1 then
		line_left = line_ed.cl  - 1
		byte_left = #lines[line_left] + 1
	else
		line_left, byte_left = edComM.huntWordBoundary(code_groups, lines, line_ed.cl, line_ed.cb, -1, false, -1, true)
	end

	if line_left then
		if line_left ~= line_ed.cl or byte_left ~= line_ed.cb then
			return line_ed:deleteText(true, line_left, byte_left, line_ed.cl, line_ed.cb - 1)
		end
	end
end


function editFuncM.caretToHighlightEdgeLeft(self)
	local line_ed = self.line_ed

	local l1, b1 = line_ed:getCaretOffsetsInOrder()
	line_ed:moveCaret(l1, b1, true, true)
end


function editFuncM.caretToHighlightEdgeRight(self)
	local line_ed = self.line_ed

	local _, _, l2, b2 = line_ed:getCaretOffsetsInOrder()
	line_ed:moveCaret(l2, b2, true, true)
end


function editFuncM.caretStepLeft(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local cl, cb = lines:offsetStepLeft(line_ed.cl, line_ed.cb)
	if cl then
		line_ed:moveCaret(cl, cb, clear_highlight, true)
	end
end


function editFuncM.caretStepRight(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local cl, cb = lines:offsetStepRight(line_ed.cl, line_ed.cb)
	if cl then
		line_ed:moveCaret(cl, math.max(1, cb), clear_highlight, true)
	end
end


function editFuncM.caretJumpLeft(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local cl, cb = edComM.huntWordBoundary(code_groups, lines, line_ed.cl, line_ed.cb, -1, false, -1, false)
	line_ed:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretJumpRight(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local hit_non_ws = false
	local first_group = code_groups[lines:peekCodePoint(line_ed.cl, line_ed.cb)]
	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	local cl, cb = edComM.huntWordBoundary(code_groups, lines, line_ed.cl, line_ed.cb, 1, hit_non_ws, first_group, false)
	line_ed:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretFullLineFirst(self, clear_highlight)
	local line_ed = self.line_ed

	line_ed:moveCaret(line_ed.cl, 1, clear_highlight, true)
end


function editFuncM.caretFullLineLast(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:moveCaret(line_ed.cl, #lines[line_ed.cl] + 1, clear_highlight, true)
end


function editFuncM.caretSubLineFirst(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Find the first uChar offset for the current Paragraph + sub-line pair.
	local u_count = edComM.getSubLineUCharOffsetStart(line_ed.paragraphs[line_ed.dcp], line_ed.dcs)

	-- Convert the display u_count to a byte offset in the line_ed/source string.
	local cl, cb = line_ed.cl, utf8.offset(lines[line_ed.cl], u_count)
	line_ed:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretSubLineLast(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Find the last uChar offset for the current Paragraph + sub-line pair.
	local u_count = edComM.getSubLineUCharOffsetEnd(line_ed.paragraphs[line_ed.dcp], line_ed.dcs)

	-- Convert to internal line_ed byte offset
	local cl, cb = line_ed.cl, utf8.offset(lines[line_ed.cl], u_count)
	line_ed:moveCaret(cl, cb, clear_highlight, true)
end


function editFuncM.caretLineFirst(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local cl, cb, hl, hb = line_ed:getCaretOffsets()
	editFuncM.caretSubLineFirst(self, clear_highlight)
	if line_ed:compareCaretOffsets(cl, cb, hl, hb) then
		editFuncM.caretFullLineFirst(self, clear_highlight)
	end
end


function editFuncM.caretLineLast(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local cl, cb, hl, hb = line_ed:getCaretOffsets()
	editFuncM.caretSubLineLast(self, clear_highlight)
	if line_ed:compareCaretOffsets(cl, cb, hl, hb) then
		editFuncM.caretFullLineLast(self, clear_highlight)
	end
end


function editFuncM.caretFirst(self, clear_highlight)
	local line_ed = self.line_ed

	line_ed:moveCaret(1, 1, clear_highlight, true)
end


function editFuncM.caretLast(self, clear_highlight)
	local line_ed = self.line_ed

	line_ed:moveCaret(#line_ed.lines, #line_ed.lines[#line_ed.lines] + 1, clear_highlight, true)
end


function editFuncM.caretStepUp(self, clear_highlight, n_steps)
	local line_ed = self.line_ed
	local lines = line_ed.lines
	local font = line_ed.font
	local paragraphs = line_ed.paragraphs

	n_steps = n_steps or 1

	-- Already at top sub-line: move to start.
	if line_ed.dcp <= 1 and line_ed.dcs <= 1 then
		line_ed:moveCaret(1, 1, clear_highlight, true)
	else
		-- Get the offsets for the sub-line 'n_steps' above.
		local d_para, d_sub = edComM.stepSubLine(paragraphs, line_ed.dcp, line_ed.dcs, -n_steps)

		-- Find the closest uChar / glyph to the current X hint.
		local d_sub_t = paragraphs[d_para][d_sub]
		local d_str = d_sub_t.str
		local new_byte, new_u_char, pixels = textUtil.getByteOffsetAtX(d_str, font, line_ed.vertical_x_hint - d_sub_t.x)

		-- Not the last sub-line in the Paragraph: correct leftmost position so that it doesn't
		-- spill over to the next sub-line (and get stuck).
		if d_sub < #paragraphs[d_para] then
			new_byte = math.min(#d_str, new_byte)
		end

		-- Convert display offsets to ones suitable for logical lines.
		local u_count = edComM.displaytoUCharCount(paragraphs[d_para], d_sub, new_byte)
		line_ed:moveCaret(d_para, utf8.offset(lines[d_para], u_count), clear_highlight, false)
	end
end


function editFuncM.caretStepDown(self, clear_highlight, n_steps)
	local line_ed = self.line_ed
	local lines = line_ed.lines
	local font = line_ed.font
	local paragraphs = line_ed.paragraphs

	n_steps = n_steps or 1

	-- Already at bottom sub-line: move to end.
	if line_ed.dcp >= #paragraphs and line_ed.dcs >= #paragraphs[#paragraphs] then
		line_ed:moveCaret(#line_ed.lines, #line_ed.lines[line_ed.cl] + 1, clear_highlight, true)
	else
		-- Get the offsets for the sub-line 'n_steps' below.
		local d_para, d_sub = edComM.stepSubLine(paragraphs, line_ed.dcp, line_ed.dcs, n_steps)

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
		line_ed:moveCaret(d_para, utf8.offset(lines[d_para], u_count), clear_highlight, false)
	end
end


function editFuncM.caretStepUpCoreLine(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Already at top line: move to start.
	if line_ed.cl <= 1 then
		line_ed:moveCaret(line_ed.cl, 1, clear_highlight, true)

	-- Already at position 1 on the current line: move up one line
	elseif line_ed.cb == 1 then
		line_ed:moveCaret(math.max(1, line_ed.cl - 1), 1, clear_highlight, true)

	-- Otherwise, move to position 1 in the current line.
	else
		line_ed:moveCaret(line_ed.cl, 1, clear_highlight, true)
	end
end


function editFuncM.caretStepDownCoreLine(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Already at bottom line: move to end.
	if line_ed.cl == #lines then
		line_ed:moveCaret(line_ed.cl, #lines[#lines] + 1, clear_highlight, true)

	-- Already at last position in logical line: move to next line
	elseif line_ed.cb == #lines[line_ed.cl] + 1 then
		line_ed:moveCaret(math.min(line_ed.cl + 1, #lines), #lines[line_ed.cl] + 1, clear_highlight, true)

	-- Otherwise, move to the last position in the current line.
	else
		line_ed:moveCaret(line_ed.cl, #lines[line_ed.cl] + 1, clear_highlight, true)
	end
end


function editFuncM.shiftLinesUp(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local r1, r2 = line_ed:getSelectedLinesRange(true)
	local displaced_line = lines[r1 - 1]

	if displaced_line then
		line_ed:clearHighlight()

		for i = r1 - 1, r2 - 1 do
			lines[i] = lines[i + 1]
		end

		lines[r2] = displaced_line
		line_ed:updateDisplayText(r1 - 1, r2)
		line_ed:moveCaretAndHighlight(r1 - 1, 1, r2 - 1, #lines[r2 - 1] + 1, true)
		line_ed:syncDisplayCaretHighlight(r1 - 1, r2)

		return true
	end
end


function editFuncM.shiftLinesDown(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local r1, r2 = line_ed:getSelectedLinesRange(true)
	local displaced_line = lines[r2 + 1]

	if displaced_line then
		line_ed:clearHighlight()

		for i = r2 + 1, r1 + 1, -1 do
			lines[i] = lines[i - 1]
		end

		lines[r1] = displaced_line
		line_ed:updateDisplayText(r1, r2 + 1)
		line_ed:moveCaretAndHighlight(r1 + 1, 1, r2 + 1, #lines[r2 + 1] + 1, true)
		line_ed:syncDisplayCaretHighlight(r1, r2 + 1)

		return true
	end
end


function editFuncM.deleteHighlighted(self)
	local line_ed = self.line_ed

	if self:isHighlighted() then
		local l1, b1, l2, b2 = line_ed:getCaretOffsetsInOrder()
		line_ed:clearHighlight()
		return line_ed:deleteText(true, l1, b1, l2, b2 - 1)
	end
end


function editFuncM.backspaceUChar(self, n_u_chars)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	local line_1, byte_1, u_count = lines:countUChars(-1, line_ed.cl, line_ed.cb, n_u_chars)

	if u_count > 0 then
		return line_ed:deleteText(true, line_1, byte_1, line_ed.cl, line_ed.cb - 1)
	end
end


function editFuncM.deleteUChar(self, n_u_chars)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	local line_2, byte_2, u_count = lines:countUChars(1, line_ed.cl, line_ed.cb, n_u_chars)

	if u_count > 0 then
		-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
		return line_ed:deleteText(true, line_ed.cl, line_ed.cb, line_2, byte_2 - 1)
	end
end


function editFuncM.deleteGroup(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	local line_right, byte_right
	if line_ed.cb == #lines[line_ed.cl] + 1 and line_ed.cl < #lines then
		line_right = line_ed.cl + 1
		byte_right = 0
	else
		local hit_non_ws = false
		local peeked = lines:peekCodePoint(line_ed.cl, line_ed.cb)
		local first_group = code_groups[peeked]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end

		line_right, byte_right = edComM.huntWordBoundary(code_groups, lines, line_ed.cl, line_ed.cb, 1, hit_non_ws, first_group, true)
		byte_right = byte_right - 1
	end

	return line_ed:deleteText(true, line_ed.cl, line_ed.cb, line_right, byte_right)
end


function editFuncM.deleteLine(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	local retval
	-- Multi-line, caret is not on the last line
	if line_ed.cl < #lines then
		retval = line_ed:deleteText(true, line_ed.cl, 1, line_ed.cl + 1, 0)

	-- Multi-line, on the last line
	elseif line_ed.cl > 1 then
		retval = line_ed:deleteText(true, line_ed.cl - 1, #lines[line_ed.cl - 1] + 1, line_ed.cl, #lines[line_ed.cl])

	-- Document is a single empty line
	elseif #lines[1] == 0 then
		retval = nil

	-- Document is a single line, with contents that can be deleted
	else
		retval = line_ed:deleteText(true, line_ed.cl, 1, line_ed.cl, #lines[line_ed.cl])
	end

	line_ed:moveCaretAndHighlight(self.cl, 1, self.hl, 1)

	return retval
end


function editFuncM.typeLineFeedWithAutoIndent(self)
	local line_ed = self.line_ed

	self.input_category = false

	local new_str = "\n"

	if self.auto_indent then
		local top_selected_line = math.min(line_ed.cl, line_ed.hl)
		local leading_white_space = string.match(line_ed.lines[top_selected_line], "^%s+")
		if leading_white_space then
			new_str = new_str .. leading_white_space
		end
	end

	editFuncM.writeText(self, new_str, true)
end


function editFuncM.typeLineFeed(self)
	self.input_category = false
	editFuncM.writeText(self, "\n", true)
end


local function _indentLine(self, line_n)
	local line_ed = self.line_ed

	local old_line = line_ed.lines[line_n]

	line_ed:moveCaretAndHighlight(line_n, 1, line_n, 1, false)
	line_ed:insertText("\t")

	return old_line ~= line_ed.lines[line_n]
end


local function _unindentLine(self, line_n)
	local line_ed = self.line_ed

	local old_line = line_ed.lines[line_n]

	if old_line:sub(1, 1) == "\t" then
		line_ed:deleteText(false, line_n, 1, line_n, 1)
	else
		local space1, space2 = old_line:find("^[\x20]+") -- (0x20 == space)
		if space1 then
			local offset = ((space2 - 1) % 4) -- XXX space tab width should be a config setting somewhere.
			line_ed:deleteText(false, line_n, 1, line_n, offset)
		end
	end

	return old_line ~= line_ed.lines[line_n]
end


function editFuncM.typeTab(self)
	local line_ed = self.line_ed

	local changed = false

	-- Caret and highlight are on the same line: write a literal tab.
	-- (Unhighlights first)
	if line_ed.cl == line_ed.hl then
		local written = editFuncM.writeText(self, "\t", true)

		if written and #written > 0 then
			changed = true
		end
	-- Caret and highlight are on different lines: indent the range of lines.
	else
		local r1, r2 = line_ed:getSelectedLinesRange(true)

		-- Only perform the indent if the total number of added tabs will not take us beyond
		-- the max code points setting.
		local tab_count = 1 + (r2 - r1)
		if line_ed.u_chars + tab_count <= self.u_chars_max then
			for i = r1, r2 do
				local line_changed = _indentLine(self, i) -- TODO: slow implementation.
				if line_changed then
					changed = true
				end
			end
			line_ed:moveCaretAndHighlight(r2, #line_ed.lines[r2] + 1, r1, 1)
		end
	end

	return changed
end


function editFuncM.typeUntab(self)
	local line_ed = self.line_ed

	local changed = false
	local r1, r2 = line_ed:getSelectedLinesRange(true)
	local tab_count = 1 + (r2 - r1)

	for i = r1, r2 do
		local line_changed = _unindentLine(self, i) -- TODO: slow implementation.

		if line_changed then
			changed = true
		end
	end
	if changed then
		line_ed:moveCaretAndHighlight(r2, #line_ed.lines[r2] + 1, r1, 1)
	end

	return changed
end


function editFuncM.highlightAll(self)
	local line_ed = self.line_ed

	line_ed:moveCaretAndHighlight(#line_ed.lines, #line_ed.lines[line_ed.cl] + 1, 1, 1, true)
end


function editFuncM.clearHighlight(self)
	local line_ed = self.line_ed

	self.line_ed:clearHighlight()
end


function editFuncM.highlightCurrentLine(self)
	local line_ed = self.line_ed

	line_ed:moveCaretAndHighlight(line_ed.cl, 1, line_ed.hl, #line_ed.lines[line_ed.cl] + 1, true)
end


function editFuncM.highlightCurrentWord(self)
	local line_ed = self.line_ed

	local cl, cb, hl, hb = line_ed:getWordRange(line_ed.cl, line_ed.cb)
	line_ed:moveCaretAndHighlight(cl, cb, hl, hb, true)
end


function editFuncM.highlightCurrentWrappedLine(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local cl, hl = line_ed.cl, line_ed.cl
	local cb, hb = line_ed:getWrappedLineRange(line_ed.cl, line_ed.cb)
	line_ed:moveCaretAndHighlight(cl, cb, hl, hb, true)

	--print("line_ed.cb", line_ed.cb, "line_ed.hl", line_ed.hb)
end


function editFuncM.stepHistory(self, dir)
	local line_ed = self.line_ed

	-- -1 == undo, 1 == redo

	local hist = self.hist
	local changed, entry = hist:moveToEntry(hist.pos + dir)

	if changed then
		editFuncM.applyHistoryEntry(self, entry)
		line_ed:updateDisplayText()
		line_ed:syncDisplayCaretHighlight()
		return true
	end
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized, and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
--	entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field, or nil if no text was added.
function editFuncM.writeText(self, text, suppress_replace)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Sanitize input
	text = edComBase.cleanString(text, self.bad_input_rule, self.tabs_to_spaces, self.allow_line_feed)

	if not self.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlighted selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		editFuncM.deleteHighlighted(self)

	elseif self.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		editFuncM.deleteUChar(self, utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	line_ed.u_chars = lines:uLen()
	text = textUtil.trimString(text, self.u_chars_max - line_ed.u_chars)

	if #text > 0 then
		line_ed:insertText(text)

		return text
	end
end


function editFuncM.replaceText(self, text)
	local line_ed = self.line_ed

	line_ed:deleteText(false, 1, 1, #line_ed.lines, #line_ed.lines[#line_ed.lines])
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
function editFuncM.setHighlightEnabled(self, enabled)
	local line_ed = self.line_ed

	enabled = not not enabled
	if self.allow_highlight ~= enabled then
		self.allow_highlight = enabled
		if not enabled then
			line_ed:clearHighlight()
		end
		return true
	end
end


function editFuncM.initHistoryEntry(self, entry)
	local line_ed = self.line_ed
	local src_lines = line_ed.lines

	entry.lines = entry.lines or {}
	local cl, cb, hl, hb = line_ed:getCaretOffsets()

	for i = #entry.lines, #src_lines + 1, -1 do
		entry.lines[i] = nil
	end
	for i = 1, #src_lines do
		entry.lines[i] = src_lines[i]
	end

	entry.cl, entry.cb, entry.hl, entry.hb = cl, cb, hl, hb
end


function editFuncM.writeHistoryEntry(self, do_advance)
	local entry = self.hist:writeEntry(do_advance)
	editFuncM.initHistoryEntry(self, entry)
	return entry
end


function editFuncM.applyHistoryEntry(self, entry)
	local line_ed = self.line_ed
	local src_lines = line_ed.lines
	local paragraphs = line_ed.paragraphs
	local entry_lines = entry.lines

	for i = 1, #entry_lines do
		src_lines[i] = entry_lines[i]
	end
	for i = #src_lines, #entry_lines + 1, -1 do
		src_lines[i] = nil
		paragraphs[i] = nil
	end

	line_ed.cl, line_ed.cb, line_ed.hl, line_ed.hb = entry.cl, entry.cb, entry.hl, entry.hb
end


function editFuncM.doctorHistoryCaretOffsets(self, cl, cb, hl, hb)
	local hist = self.hist
	local entry = hist.ledger[hist.pos]

	if entry then
		entry.cl, entry.cb, entry.hl, entry.hb = cl, cb, hl, hb
	end
end


-- Deletes all history entries, then writes a new entry based on the current line_ed state.
-- Also clears the widget's input category.
function editFuncM.wipeHistoryEntries(self)
	self.hist:clearAll()
	self:resetInputCategory()
	editFuncM.writeHistoryEntry(self, false)
end


return editFuncM
