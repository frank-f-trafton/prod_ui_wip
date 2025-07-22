-- LineEditor (multi) widget functions.


local context = select(1, ...)


local editFuncM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local code_groups = context:getLua("shared/line_ed/code_groups")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")


local function _deleteHighlighted(line_ed)
	if line_ed:isHighlighted() then
		local l1, b1, l2, b2 = line_ed:getHighlightOffsets()
		line_ed:clearHighlight()
		return line_ed:deleteText(true, l1, b1, l2, b2 - 1)
	end
end


local function _deleteUChar(line_ed, n_u_chars)
	local lines = line_ed.lines

	line_ed:clearHighlight()

	local line_2, byte_2, u_count = lines:countUChars(1, line_ed.car_line, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
		return line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_2, byte_2 - 1)
	end
end


local function _writeText(self, line_ed, text, suppress_replace)
	local lines = line_ed.lines

	-- Sanitize input
	text = edComBase.cleanString(text, self.bad_input_rule, self.tabs_to_spaces, self.allow_line_feed)

	if not self.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlighted selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		_deleteHighlighted(line_ed)

	elseif self.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		_deleteUChar(line_ed, utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	line_ed.u_chars = lines:uLen()
	text = textUtil.trimString(text, self.u_chars_max - line_ed.u_chars)

	line_ed:insertText(text)

	return text
end



function editFuncM.updateCaretShape(self)
	local line_ed = self.line_ed

	self.caret_x = line_ed.caret_box_x
	self.caret_y = line_ed.caret_box_y
	self.caret_w = line_ed.caret_box_w
	self.caret_h = line_ed.caret_box_h

	if self.replace_mode then
		self.caret_fill = "line"
	else
		self.caret_fill = "fill"
		self.caret_w = line_ed.caret_line_width
	end
end


function editFuncM.updateVisibleParagraphs(self)
	local line_ed = self.line_ed

	-- Find the first visible display paragraph (or rather, one before it) to cut down on rendering.
	local y_pos = self.scr_y - self.vp_y -- XXX should this be viewport #2? Or does the viewport offset matter at all?

	-- XXX default to 1?
	--self.vis_para_top
	for i, paragraph in ipairs(line_ed.paragraphs) do
		local sub_one = paragraph[1]
		if sub_one.y > y_pos then
			self.vis_para_top = math.max(1, i - 1)
			break
		end
	end

	-- Find the last display paragraph (or one after it) as well.
	self.vis_para_bot = #line_ed.paragraphs
	for i = self.vis_para_top, #line_ed.paragraphs do
		local paragraph = line_ed.paragraphs[i]
		local sub_last = paragraph[#paragraph]
		if sub_last.y + sub_last.h > y_pos + self.vp2_h then
			self.vis_para_bot = i
			break
		end
	end

	--print("updateVisibleParagraphs()", "self.vis_para_top", self.vis_para_top, "self.vis_para_bot", self.vis_para_bot)
end


function editFuncM.updateTextBatch(self)
	local line_ed = self.line_ed
	local text_object = self.text_object

	text_object:clear()

	if line_ed.font ~= text_object:getFont() then
		text_object:setFont(line_ed.font)
	end

	for i = self.vis_para_top, self.vis_para_bot do
		local paragraph = line_ed.paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			text_object:add(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
		end
	end
end


function editFuncM.setReplaceMode(self, enabled)
	local old_replace_mode = self.replace_mode
	self.replace_mode = not not enabled
	return old_replace_mode ~= self.replace_mode
end


function editFuncM.getReplaceMode(self)
	return self.replace_mode
end


function editFuncM.cutHighlightedToClipboard(self)
	local line_ed = self.line_ed

	local cut = _deleteHighlighted(line_ed)
	if cut then
		cut = textUtil.sanitize(cut, self.bad_input_rule)

		love.system.setClipboardText(cut)
		line_ed:updateDisplayText()
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
			_deleteHighlighted(line_ed)
		end

		_writeText(self, line_ed, text, true)
		line_ed:updateDisplayText()
		return true
	end
end


function editFuncM.deleteCaretToLineStart(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	return line_ed:deleteText(true, line_ed.car_line, 1, line_ed.car_line, line_ed.car_byte - 1)
end


function editFuncM.deleteCaretToLineEnd(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

	return line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_ed.car_line, #lines[line_ed.car_line])
end


function editFuncM.backspaceGroup(self)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed:clearHighlight()

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


function editFuncM.caretHighlightEdgeLeft(self)
	local line_ed = self.line_ed

	local l1, b1, _, _ = line_ed:getHighlightOffsets()
	line_ed.car_line, line_ed.car_byte, line_ed.h_line, line_ed.h_byte = l1, b1, l1, b1

	-- ZXC update
end


function editFuncM.caretHighlightEdgeRight(self)
	local line_ed = self.line_ed

	local _, _, l2, b2 = line_ed:getHighlightOffsets()
	line_ed.car_line, line_ed.car_byte, line_ed.h_line, line_ed.h_byte = l2, b2, l2, b2

	-- ZXC update
end


function editFuncM.caretStepLeft(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local new_line, new_byte = lines:offsetStepLeft(line_ed.car_line, line_ed.car_byte)
	if new_line then
		line_ed.car_line, line_ed.car_byte = new_line, new_byte
	end

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretStepRight(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local new_line, new_byte = lines:offsetStepRight(line_ed.car_line, line_ed.car_byte)
	if new_line then
		line_ed.car_line, line_ed.car_byte = new_line, math.max(1, new_byte)
	end

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretJumpLeft(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	line_ed.car_line, line_ed.car_byte = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, -1, false, -1, false)

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretJumpRight(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local hit_non_ws = false
	local first_group = code_groups[lines:peekCodePoint(line_ed.car_line, line_ed.car_byte)]
	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	line_ed.car_line, line_ed.car_byte = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, 1, hit_non_ws, first_group, false)

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretLineFirst(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Find the first uChar offset for the current Paragraph + sub-line pair.
	local u_count = edComM.getSubLineUCharOffsetStart(self.paragraphs[line_ed.d_car_para], line_ed.d_car_sub)

	-- Convert the display u_count to a byte offset in the line_ed/source string.
	line_ed.car_byte = utf8.offset(lines[line_ed.car_line], u_count)

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretLineLast(self, clear_highlight)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Find the last uChar offset for the current Paragraph + sub-line pair.
	local u_count = edComM.getSubLineUCharOffsetEnd(self.paragraphs[line_ed.d_car_para], line_ed.d_car_sub)

	-- Convert to internal line_ed byte offset
	line_ed.car_byte = utf8.offset(lines[line_ed.car_line], u_count)

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretFirst(self, clear_highlight)
	local line_ed = self.line_ed

	line_ed.car_line = 1
	line_ed.car_byte = 1

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretLast(self, clear_highlight)
	local line_ed = self.line_ed

	line_ed.car_line = #line_ed.lines
	line_ed.car_byte = #line_ed.lines[line_ed.car_line] + 1

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretStepUp(self, clear_highlight, n_steps)
	local line_ed = self.line_ed
	local lines = line_ed.lines
	local font = line_ed.font
	local paragraphs = line_ed.paragraphs

	n_steps = n_steps or 1

	-- Already at top sub-line: move to start.
	if line_ed.d_car_para <= 1 and line_ed.d_car_sub <= 1 then
		line_ed.car_line = 1
		line_ed.car_byte = 1

		-- ZXC update
		if clear_highlight then
			line_ed:clearHighlight()
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
		end
	end
end


function editFuncM.caretStepDown(self, clear_highlight, n_steps)
	local line_ed = self.line_ed
	local lines = line_ed.lines
	local font = line_ed.font
	local paragraphs = line_ed.paragraphs

	n_steps = n_steps or 1

	-- Already at bottom sub-line: move to end.
	if line_ed.d_car_para >= #paragraphs and line_ed.d_car_sub >= #paragraphs[#paragraphs] then
		line_ed.car_line = #line_ed.lines
		line_ed.car_byte = #line_ed.lines[line_ed.car_line] + 1

		-- ZXC update
		if clear_highlight then
			line_ed:clearHighlight()
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

		-- ZXC update
		if clear_highlight then
			line_ed:clearHighlight()
		end
	end
end


function editFuncM.caretStepUpCoreLine(self, clear_highlight)
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

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.caretStepDownCoreLine(self, clear_highlight)
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

	-- ZXC update
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


function editFuncM.shiftLinesUp(self)
	local line_ed = self.line_ed

	local r1, r2 = line_ed:getSelectedLinesRange(true)
	local lines = line_ed.lines
	local displaced_line = lines[r1 - 1]

	if displaced_line then
		for i = r1 - 1, r2 - 1 do
			lines[i] = lines[i + 1]
		end

		lines[r2] = displaced_line

		line_ed.car_line = math.max(1, r1 - 1)
		line_ed.car_byte = 1
		line_ed.h_line = math.max(1, r2 - 1)
		line_ed.h_byte = #line_ed.lines[line_ed.h_line] + 1
		-- ZXC update

		return true
	end
end


function editFuncM.shiftLinesDown(self)
	local line_ed = self.line_ed

	local r1, r2, b1, b2 = line_ed:getSelectedLinesRange(true)
	local lines = line_ed.lines
	local displaced_line = lines[r2 + 1]

	if displaced_line then
		for i = r2 + 1, r1 + 1, -1 do
			lines[i] = lines[i - 1]
		end

		lines[r1] = displaced_line

		line_ed.car_line = math.min(#lines, r1 + 1)
		line_ed.car_byte = 1
		line_ed.h_line = math.min(#lines, r2 + 1)
		line_ed.h_byte = #line_ed.lines[line_ed.h_line] + 1
		-- ZXC update

		return true
	end
end


function editFuncM.deleteHighlighted(self)
	local line_ed = self.line_ed

	if self:isHighlighted() then
		local rv = _deleteHighlighted(line_ed)
		return rv
	end
end


function editFuncM.backspaceUChar(self, n_u_chars)
	local line_ed = self.line_ed

	line_ed:clearHighlight()
	local lines = line_ed.lines
	local line_1, byte_1, u_count = lines:countUChars(-1, line_ed.car_line, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		return line_ed:deleteText(true, line_1, byte_1, line_ed.car_line, line_ed.car_byte - 1)
	end
end


function editFuncM.deleteUChar(self, n_u_chars)
	return _deleteUChar(self.line_ed, n_u_chars)
end


function editFuncM.deleteGroup(self)
	local line_ed = self.line_ed

	line_ed:clearHighlight()

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

		line_right, byte_right = edComM.huntWordBoundary(code_groups, lines, line_ed.car_line, line_ed.car_byte, 1, hit_non_ws, first_group, true)
		byte_right = byte_right - 1
	end

	local del = line_ed:deleteText(true, line_ed.car_line, line_ed.car_byte, line_right, byte_right)
	return del
end


function editFuncM.deleteLine(self)
	local line_ed = self.line_ed

	line_ed:clearHighlight()

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

	-- ZXC update

	return retval
end


function editFuncM.typeLineFeedWithAutoIndent(self)
	local line_ed = self.line_ed

	self.input_category = false

	local new_str = "\n"

	if self.auto_indent then
		local top_selected_line = math.min(line_ed.car_line, line_ed.h_line)
		local leading_white_space = string.match(line_ed.lines[top_selected_line], "^%s+")
		if leading_white_space then
			new_str = new_str .. leading_white_space
		end
	end

	self:writeText(new_str, true)
end


function editFuncM.typeLineFeed(self)
	self.input_category = false
	self:writeText("\n", true)
end


local function _fixCaretAfterIndent(self, line_n, offset)
	if self.car_line == line_n then
		self.car_byte = math.max(1, self.car_byte + offset)
	end

	if self.h_line == line_n then
		self.h_byte = math.max(1, self.h_byte + offset)
	end
end


function editFuncM.indentLine(self, line_n)
	local line_ed = self.line_ed

	local old_line = line_ed.lines[line_n]
	line_ed.lines:add("\t", line_n, 1)
	line_ed.u_chars = self.u_chars + 1

	_fixCaretAfterIndent(line_ed, line_n, 1)

	-- ZXC update

	return old_line ~= line_ed.lines[line_n]
end


function editFuncM.unindentLine(self, line_n)
	local line_ed = self.line_ed

	local old_line = line_ed.lines[line_n]
	local offset

	if string.sub(old_line, 1, 1) == "\t" then
		offset = 1
		line_ed.lines:delete(line_n, 1, line_n, 1)
	else
		local space1, space2 = string.find(old_line, "^[\x20]+") -- (0x20 == space)
		if space1 then
			offset = ((space2 - 1) % 4) -- XXX space tab width should be a config setting somewhere.
			line_ed.lines:delete(line_n, 1, line_n, offset)
		end
	end

	if offset then
		line_ed.u_chars = line_ed.u_chars - 1

		_fixCaretAfterIndent(line_ed, line_n, -offset)

		line_ed:displaySyncDeletion(line_n, line_n)
		line_ed:displaySyncCaretOffsets()

		-- ZXC update
	end

	return old_line ~= line_ed.lines[line_n]
end


function editFuncM.typeTab(self)
	local line_ed = self.line_ed

	local changed = false

	-- Caret and highlight are on the same line: write a literal tab.
	-- (Unhighlights first)
	if line_ed.car_line == line_ed.h_line then
		local written = self:writeText("\t", true)

		if #written > 0 then
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
				local line_changed = editFuncM.indentLine(self, i)

				if line_changed then
					changed = true
				end
			end
		end
	end
	-- ZXC update

	return changed
end


function editFuncM.typeUntab(self)
	local line_ed = self.line_ed

	local changed = false
	local r1, r2 = line_ed:getSelectedLinesRange(true)
	local tab_count = 1 + (r2 - r1)

	for i = r1, r2 do
		local line_changed = editFuncM.unindentLine(self, i)

		if line_changed then
			changed = true
		end
	end

	-- ZXC update

	return changed
end


function editFuncM.highlightAll(self)
	local line_ed = self.line_ed

	line_ed.car_line = #line_ed.lines
	line_ed.car_byte = #line_ed.lines[line_ed.car_line] + 1

	line_ed.h_line = 1
	line_ed.h_byte = 1

	-- ZXC update
end


function editFuncM.clearHighlight(self)
	self.line_ed:clearHighlight()
end


function editFuncM.highlightCurrentLine(self)
	local line_ed = self.line_ed

	line_ed.h_line = line_ed.car_line
	line_ed.car_byte, line_ed.h_byte = 1, #line_ed.lines[line_ed.car_line] + 1

	-- ZXC update
end


function editFuncM.highlightCurrentWord(self)
	local line_ed = self.line_ed

	line_ed.car_line, line_ed.car_byte, line_ed.h_line, line_ed.h_byte = line_ed:getWordRange(line_ed.car_line, line_ed.car_byte)

	-- ZXC update
end


function editFuncM.stepHistory(self, dir)
	local line_ed = self.line_ed

	-- -1 == undo, 1 == redo

	local hist = line_ed.hist
	local changed, entry = hist:moveToEntry(hist.pos + dir)

	if changed then
		editHistM.applyEntry(self, entry)
		-- ZXC update
		return true
	end
end


function editFuncM.setTextAlignment(self, align)
	local line_ed = self.line_ed

	local old_align = line_ed.align
	line_ed.align = align
	if old_align ~= align then
		-- Update just the alignment of sub-lines.
		self.line_ed:syncDisplayAlignment()
		self.line_ed:displaySyncCaretOffsets()
		-- ZXC update

		return true
	end
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
--	entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function editFuncM.writeText(self, text, suppress_replace)
	local line_ed = self.line_ed
	local lines = line_ed.lines

	-- Sanitize input
	text = edComBase.cleanString(text, self.bad_input_rule, self.tabs_to_spaces, self.allow_line_feed)

	if not self.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		editFuncM.deleteHighlighted(self)

	elseif self.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		_deleteUChar(line_ed, utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.

	-- XXX Planning to add and subtract to this as strings are written and deleted.
	-- For now, just recalculate the length to ensure things are working.
	line_ed.u_chars = lines:uLen()
	text = textUtil.trimString(text, self.u_chars_max - line_ed.u_chars)

	line_ed:insertText(text)

	return text
end


function editFuncM.replaceText(self, text)
	local line_ed = self.line_ed

	line_ed:deleteText(false, 1, 1, #line_ed.lines, #line_ed.lines[#line_ed.lines])
	local rv = _writeText(self, line_ed, text, true)

	line_ed:updateDisplayText(1, #line_ed.paragraphs)

	-- WIP
	-- [[
	for i, para in ipairs(line_ed.paragraphs) do
		for j, sub_line in ipairs(para) do
			print(i, j, "|" .. sub_line.str .. "|")
		end
	end
	--]]

	return rv
end


function editFuncM.setText(self, text)
	-- Like replaceText(), but also wipes history.
	editFuncM.replaceText(self, text)
	editHistM.wipeEntries(self)
end


return editFuncM
