-- LineEditor (single) widget functions.


local context = select(1, ...)


local editFuncS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


-- Helper functions to save and restore the internal state of the Line Editor.
local _line, _disp_text, _car_byte, _h_byte


local function _check(self)
	return not self.fn_check and true or self:fn_check()
end


local function _deleteHighlighted(LE)
	if LE:isHighlighted() then
		local byte_1, byte_2 = LE:getHighlightOffsets()
		LE:clearHighlight()
		return LE:deleteText(true, byte_1, byte_2 - 1)
	end
end


local function _deleteUChar(LE, n_u_chars)
	local line = LE.line

	LE:clearHighlight()

	-- Nothing to delete at the last caret position.
	if LE.car_byte > #line then
		return
	end

	local byte_2, u_count = edComS.countUChars(line, 1, LE.car_byte, n_u_chars)
	if u_count == 0 then
		byte_2 = #line + 1
	end

	-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
	return LE:deleteText(true, LE.car_byte, byte_2 - 1)
end


local function _writeText(self, LE, text, suppress_replace)
	-- Sanitize input
	text = edComBase.cleanString(text, self.LE_bad_input_rule, self.LE_tabs_to_spaces, self.LE_allow_line_feed)

	if not self.LE_allow_highlight then
		LE:clearHighlight()
	end

	-- If there is a highlighted selection, get rid of it and insert the new text. This overrides Replace Mode.
	if LE:isHighlighted() then
		_deleteHighlighted(LE)

	elseif self.LE_replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		_deleteUChar(LE, utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.
	text = textUtil.trimString(text, self.LE_u_chars_max - utf8.len(LE.line))

	LE:insertText(text)

	return text
end


-- Do not use with methods that change the internal text.
local function _checkClearHighlight(LE, clear_highlight)
	if clear_highlight then
		LE:clearHighlight()
	end
end


-- Updates the widget's caret shape and appearance.
function editFuncS.updateCaretShape(self)
	local LE = self.LE

	self.LE_caret_x = LE.caret_box_x
	self.LE_caret_y = LE.caret_box_y
	self.LE_caret_w = LE.caret_box_w
	self.LE_caret_h = LE.caret_box_h

	if self.LE_replace_mode then
		self.LE_caret_fill = "line"
	else
		self.LE_caret_fill = "fill"
		self.LE_caret_w = LE.caret_line_width
	end
end


function editFuncS.resetCaretBlink(self)
	self.LE_caret_blink_time = self.LE_caret_blink_reset
end


function editFuncS.cutHighlightedToClipboard(self)
	local LE = self.LE

	local cut = _deleteHighlighted(LE)
	if cut then
		cut = textUtil.sanitize(cut, self.LE_bad_input_rule)

		-- Don't leak masked string info.
		if LE.masked then
			cut = LE.mask_glyph:rep(utf8.len(cut))
		end

		if _check(self) then
			love.system.setClipboardText(cut)
			LE:updateDisplayText()
			return cut
		end
	end
end


function editFuncS.copyHighlightedToClipboard(self)
	local LE = self.LE

	local copied = editFuncS.getHighlightedText(self)

	-- Don't leak masked string info.
	if LE.masked then
		copied = string.rep(LE.mask_glyph, utf8.len(copied))
	end

	copied = textUtil.sanitize(copied, self.LE_bad_input_rule)

	love.system.setClipboardText(copied)
end


function editFuncS.pasteClipboard(self)
	local LE = self.LE

	local line, disp, car_byte, h_byte = LE:copyState()
	local text = love.system.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		if LE:isHighlighted() then
			_deleteHighlighted(LE)
		end

		_writeText(self, LE, text, true)
		if _check(self) then
			LE:updateDisplayText()
			return true
		end
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.caretFirst(self, clear_highlight)
	local LE = self.LE

	LE.car_byte = 1

	_checkClearHighlight(LE, clear_highlight)
	LE:syncDisplayCaretHighlight()
end


function editFuncS.caretLast(self, clear_highlight)
	local LE = self.LE

	LE.car_byte = #LE.line + 1

	_checkClearHighlight(LE, clear_highlight)
	LE:syncDisplayCaretHighlight()
end


function editFuncS.deleteCaretToStart(self)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	LE:clearHighlight()
	local rv = LE:deleteText(true, 1, LE.car_byte - 1)

	if rv and _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.deleteCaretToEnd(self)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	LE:clearHighlight()
	local rv = LE:deleteText(true, LE.car_byte, #LE.line)

	if rv and _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.backspaceGroup(self)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	LE:clearHighlight()
	local rv

	if LE.car_byte > 1 then
		local byte_left = edComS.huntWordBoundary(code_groups, LE.line, LE.car_byte, -1, false, -1)
		rv = LE:deleteText(true, byte_left, LE.car_byte - 1)
	end

	if rv and _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.deleteGroup(self)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	LE:clearHighlight()
	local rv

	if LE.car_byte < #LE.line + 1 then
		local hit_non_ws = false
		local first_group = code_groups[utf8.codepoint(LE.line, LE.car_byte)]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end

		local byte_right = edComS.huntWordBoundary(code_groups, LE.line, LE.car_byte, 1, hit_non_ws, first_group)
		byte_right = byte_right - 1

		rv = LE:deleteText(true, LE.car_byte, byte_right)
	end

	if rv and _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


--- Delete characters by stepping backwards from the caret position.
-- @param self The widget.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function editFuncS.backspaceUChar(self, n_u_chars)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	LE:clearHighlight()

	local byte_1, u_count = edComS.countUChars(line, -1, LE.car_byte, n_u_chars)
	local rv
	if u_count > 0 then
		rv = LE:deleteText(true, byte_1, LE.car_byte - 1)

		if rv and _check(self) then
			LE:updateDisplayText()
			return rv
		end
	end

	LE:setState(line, disp, car_byte, h_byte)
end


--- Delete characters on and to the right of the caret.
-- @param self The widget.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function editFuncS.deleteUChar(self, n_u_chars)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	local rv = _deleteUChar(LE, n_u_chars)

	if rv and _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function editFuncS.deleteHighlighted(self)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	local rv = _deleteHighlighted(LE)
	if rv and _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.caretJumpLeft(self, clear_highlight)
	local LE = self.LE

	LE.car_byte = edComS.huntWordBoundary(code_groups, LE.line, LE.car_byte, -1, false, -1)

	_checkClearHighlight(LE, clear_highlight)
	LE:syncDisplayCaretHighlight()
end


function editFuncS.caretJumpRight(self, clear_highlight)
	local LE = self.LE

	local hit_non_ws = false

	local first_group
	if LE.car_byte <= #LE.line then
		first_group = code_groups[utf8.codepoint(LE.line, LE.car_byte)]
	end

	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	--print("hit_non_ws", hit_non_ws, "first_group", first_group)

	--(lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed)
	LE.car_byte = edComS.huntWordBoundary(code_groups, LE.line, LE.car_byte, 1, hit_non_ws, first_group)

	_checkClearHighlight(LE, clear_highlight)
	LE:syncDisplayCaretHighlight()
end


function editFuncS.caretStepLeft(self, clear_highlight)
	local LE = self.LE

	LE.car_byte = edComS.offsetStepLeft(LE.line, LE.car_byte) or 1

	_checkClearHighlight(LE, clear_highlight)
	LE:syncDisplayCaretHighlight()
end


function editFuncS.caretStepRight(self, clear_highlight)
	local LE = self.LE

	local new_byte = edComS.offsetStepRight(LE.line, LE.car_byte)
	LE.car_byte = new_byte or #LE.line + 1

	_checkClearHighlight(LE, clear_highlight)
	LE:syncDisplayCaretHighlight()
end


function editFuncS.caretToHighlightEdgeLeft(self)
	local LE = self.LE

	local byte_1, byte_2 = LE:getHighlightOffsets()
	LE.car_byte, LE.h_byte = byte_1, byte_1

	LE:syncDisplayCaretHighlight()
end


function editFuncS.caretToHighlightEdgeRight(self)
	local LE = self.LE

	local byte_1, byte_2 = LE:getHighlightOffsets()
	LE.car_byte, LE.h_byte = byte_2, byte_2

	LE:syncDisplayCaretHighlight()
end


function editFuncS.highlightCurrentWord(self)
	local LE = self.LE

	LE.car_byte, LE.h_byte = LE:getWordRange(LE.car_byte)

	LE:syncDisplayCaretHighlight()
end


function editFuncS.highlightAll(self)
	local LE = self.LE

	LE.car_byte = #LE.line + 1
	LE.h_byte = 1

	LE:syncDisplayCaretHighlight()
end


function editFuncS.clearHighlight(self)
	local LE = self.LE

	if LE:clearHighlight() then
		LE:syncDisplayCaretHighlight()
	end
end


function editFuncS.getText(self)
	return self.LE.line
end


function editFuncS.getHighlightedText(self)
	local LE = self.LE

	if LE:isHighlighted() then
		local b1, b2 = self.LE:getHighlightOffsets()
		return LE.line:sub(b1, b2 - 1)
	end
end


function editFuncS.getDisplayText(self)
	return self.LE.disp_text
end


function editFuncS.stepHistory(self, dir)
	local LE = self.LE

	-- -1 == undo, 1 == redo

	local hist = LE.hist
	local line, disp, car_byte, h_byte = LE:copyState()
	local old_pos = hist:getPosition()

	if hist.enabled then
		local changed, entry = hist:moveToEntry(hist.pos + dir)

		if changed then
			editHistS.applyEntry(self, entry)

			if not _check(self) then
				hist.pos = old_pos
			else
				LE:updateDisplayText()
				return true
			end
		end
	end

	LE:setState(line, disp, car_byte, h_byte)
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param self The widget.
-- @param text The input text. It will be sanitized, and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
--	entering line feeds, etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function editFuncS.writeText(self, text, suppress_replace)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	local rv = _writeText(self, LE, text, suppress_replace)
	if _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.replaceText(self, text)
	local LE = self.LE
	local line, disp, car_byte, h_byte = LE:copyState()

	LE:deleteText(false, 1, #LE.line)
	local rv = _writeText(self, LE, text, true)

	if _check(self) then
		LE:updateDisplayText()
		return rv
	end

	LE:setState(line, disp, car_byte, h_byte)
end


function editFuncS.setText(self, text)
	-- Like replaceText(), but also wipes history.
	editFuncS.replaceText(self, text)
	editHistS.wipeEntries(self)
end


return editFuncS
