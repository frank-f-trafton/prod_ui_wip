-- LineEditor (single) widget functions.


local context = select(1, ...)


local editFuncS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edCom = context:getLua("shared/line_ed/ed_com")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


-- Helper functions to save and restore the internal state of the Line Editor.
local _line, _disp_text, _cb, _hb


local function _check(self)
	return not self.fn_check and true or self:fn_check()
end


local function _checkMask(self, str)
	local LE = self.LE
	if LE.masked then
		return textUtil.getMaskedString(str, LE.mask_glyph)
	end
	return str
end


local function _assertNotMasked(self)
	if self.LE.masked then
		error("this function should not be called on a text box with masked (hidden) text.")
	end
end


local function _deleteHighlighted(LE)
	if LE:isHighlighted() then
		local byte_1, byte_2 = LE:getCaretOffsetsInOrder()
		LE:clearHighlight()
		return LE:deleteText(true, byte_1, byte_2 - 1)
	end
end


local function _deleteUChar(LE, n_u_chars)
	local line = LE.line

	LE:clearHighlight()

	-- Nothing to delete at the last caret position.
	if LE.cb > #line then
		return
	end

	local byte_2, u_count = edComS.countUChars(line, 1, LE.cb, n_u_chars)
	if u_count == 0 then
		byte_2 = #line + 1
	end

	-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
	return LE:deleteText(true, LE.cb, byte_2 - 1)
end


local function _writeText(self, LE, text, suppress_replace)
	-- Sanitize input
	text = edCom.cleanString(text, self.LE_bad_input_rule, false, self.LE_allow_line_feed)

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

	if #text > 0 then
		LE:insertText(text)
		return text
	end
end


function editFuncS.cutHighlightedToClipboard(self)
	local LE = self.LE

	local line, disp, cb, hb = LE:copyState()
	local cut = _deleteHighlighted(LE)
	if cut then
		cut = textUtil.sanitize(cut, self.LE_bad_input_rule)

		-- Don't leak masked string info.
		cut = _checkMask(self, cut)

		if _check(self) then
			love.system.setClipboardText(cut)
			return cut
		end
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.copyHighlightedToClipboard(self)
	local LE = self.LE

	local copied = editFuncS.getHighlightedText(self)

	-- Don't leak masked string info.
	copied = _checkMask(self, copied)

	copied = textUtil.sanitize(copied, self.LE_bad_input_rule)

	love.system.setClipboardText(copied)
end


function editFuncS.pasteClipboard(self)
	local LE = self.LE

	local line, disp, cb, hb = LE:copyState()
	local text = love.system.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		if LE:isHighlighted() then
			_deleteHighlighted(LE)
		end

		if _writeText(self, LE, text, true) and _check(self) then
			return true
		end
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.caretFirst(self, clear_highlight)
	self.LE:moveCaret(1, clear_highlight)
end


function editFuncS.caretLast(self, clear_highlight)
	local LE = self.LE

	LE:moveCaret(#LE.line + 1, clear_highlight)
end


function editFuncS.deleteCaretToStart(self)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	LE:clearHighlight()
	local rv = LE:deleteText(true, 1, LE.cb - 1)

	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.deleteCaretToEnd(self)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	LE:clearHighlight()
	local rv = LE:deleteText(true, LE.cb, #LE.line)

	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.backspaceGroup(self)
	_assertNotMasked(self)

	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	LE:clearHighlight()
	local rv

	if LE.cb > 1 then
		local byte_left = edComS.huntWordBoundary(code_groups, LE.line, LE.cb, -1, false, -1)
		rv = LE:deleteText(true, byte_left, LE.cb - 1)
	end

	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.deleteGroup(self)
	_assertNotMasked(self)

	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	LE:clearHighlight()
	local rv

	if LE.cb < #LE.line + 1 then
		local hit_non_ws = false
		local first_group = code_groups[utf8.codepoint(LE.line, LE.cb)]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end

		local byte_right = edComS.huntWordBoundary(code_groups, LE.line, LE.cb, 1, hit_non_ws, first_group)
		byte_right = byte_right - 1

		rv = LE:deleteText(true, LE.cb, byte_right)
	end

	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


--- Delete characters by stepping backwards from the caret position.
-- @param self The widget.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function editFuncS.backspaceUChar(self, n_u_chars)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	LE:clearHighlight()

	local byte_1, u_count = edComS.countUChars(line, -1, LE.cb, n_u_chars)
	local rv
	if u_count > 0 then
		rv = LE:deleteText(true, byte_1, LE.cb - 1)

		if rv and _check(self) then
			return rv
		end
	end

	LE:setState(line, disp, cb, hb)
end


--- Delete characters on and to the right of the caret.
-- @param self The widget.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function editFuncS.deleteUChar(self, n_u_chars)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	local rv = _deleteUChar(LE, n_u_chars)

	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function editFuncS.deleteHighlighted(self)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	local rv = _deleteHighlighted(LE)
	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.caretJumpLeft(self, clear_highlight)
	_assertNotMasked(self)

	local LE = self.LE

	local new_cb = edComS.huntWordBoundary(code_groups, LE.line, LE.cb, -1, false, -1)
	LE:moveCaret(new_cb, clear_highlight)
end


function editFuncS.caretJumpRight(self, clear_highlight)
	_assertNotMasked(self)

	local LE = self.LE

	local hit_non_ws = false

	local first_group
	if LE.cb <= #LE.line then
		first_group = code_groups[utf8.codepoint(LE.line, LE.cb)]
	end

	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	local new_cb = edComS.huntWordBoundary(code_groups, LE.line, LE.cb, 1, hit_non_ws, first_group)
	LE:moveCaret(new_cb, clear_highlight)
end


function editFuncS.caretStepLeft(self, clear_highlight)
	local LE = self.LE

	local new_cb = edComS.offsetStepLeft(LE.line, LE.cb) or 1
	LE:moveCaret(new_cb, clear_highlight)
end


function editFuncS.caretStepRight(self, clear_highlight)
	local LE = self.LE

	local new_cb = edComS.offsetStepRight(LE.line, LE.cb) or #LE.line + 1
	LE:moveCaret(new_cb, clear_highlight)
end


function editFuncS.caretToHighlightEdgeLeft(self)
	local LE = self.LE

	local b1, _ = LE:getCaretOffsetsInOrder()
	LE:moveCaret(b1, true)
end


function editFuncS.caretToHighlightEdgeRight(self)
	local LE = self.LE

	local _, b2 = LE:getCaretOffsetsInOrder()
	LE:moveCaret(b2, true)
end


function editFuncS.highlightCurrentWord(self)
	local LE = self.LE

	-- Don't leak masked info.
	if LE.masked then
		LE:moveCaretAndHighlight(#LE.line + 1, 1)
	else
		local b1, b2 = LE:getWordRange(LE.cb)
		LE:moveCaretAndHighlight(b1, b2)
	end
end


function editFuncS.highlightAll(self)
	local LE = self.LE

	LE:moveCaretAndHighlight(#LE.line + 1, 1)
end


function editFuncS.clearHighlight(self)
	self.LE:clearHighlight()
end


function editFuncS.getText(self, unmask)
	local LE = self.LE
	if not LE.masked or unmask then
		return LE.line
	else
		return textUtil.getMaskedString(LE.line, LE.mask_glyph)
	end
end


function editFuncS.getHighlightedText(self)
	local LE = self.LE

	if LE:isHighlighted() then
		local b1, b2 = LE:getCaretOffsetsInOrder()
		local rv = LE.line:sub(b1, b2 - 1)

		-- Don't leak masked string info.
		if LE.masked then
			rv = textUtil.getMaskedString(rv, LE.mask_glyph)
		end

		return rv
	end
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param self The widget.
-- @param text The input text. It will be sanitized, and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
--	entering line feeds, etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function editFuncS.writeText(self, text, suppress_replace)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	local rv = _writeText(self, LE, text, suppress_replace)
	if rv and _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.replaceText(self, text)
	local LE = self.LE
	local line, disp, cb, hb = LE:copyState()

	LE:deleteText(false, 1, #LE.line)
	local rv = _writeText(self, LE, text, true) or ""

	if _check(self) then
		return rv
	end

	LE:setState(line, disp, cb, hb)
end


local function _debugHistEntry(entry)
	return "line: " .. tostring(entry.line) .. ", cb: " .. tostring(entry.cb) .. ", hb: " .. entry.hb
end


function editFuncS.setText(self, text)
	-- Like replaceText(), but also wipes history.

	--print(debug.traceback())
	--print("1/3", self.LE_hist:_debugGetState(_debugHistEntry))
	editFuncS.replaceText(self, text)
	--print("2/3", self.LE_hist:_debugGetState(_debugHistEntry))
	editFuncS.wipeHistoryEntries(self)
	--print("3/3", self.LE_hist:_debugGetState(_debugHistEntry))
end


function editFuncS.setAllowInput(self, enabled)
	self.LE_allow_input = not not enabled
	-- Turn off Replace Mode when editing is disabled.
	if not self.LE_allow_input and self.LE_replace_mode then
		self.LE_replace_mode = false
	end
end


function editFuncS.stepHistory(self, dir)
	local LE = self.LE

	-- -1 == undo, 1 == redo

	local hist = self.LE_hist
	local line, disp, cb, hb = LE:copyState()
	local old_pos = hist:getPosition()

	if hist.enabled then
		local changed, entry = hist:moveToEntry(hist.pos + dir)

		if changed then
			editFuncS.applyHistoryEntry(self, entry)

			if not _check(self) then
				hist.pos = old_pos
			else
				LE:updateDisplayText()
				LE:syncDisplayCaretHighlight()
				return true
			end
		end
	end

	LE:setState(line, disp, cb, hb)
end


function editFuncS.initHistoryEntry(entry, source_line, cb, hb)
	entry.line, entry.cb, entry.hb = source_line, cb, hb
end


function editFuncS.writeHistoryEntry(self, do_advance)
	local LE = self.LE
	local hist = self.LE_hist
	if hist.enabled then
		local entry
		if hist.locked_first then
			hist.ledger[1] = hist.ledger[1] or {}
			hist.ledger[2] = hist.ledger[2] or {}
			entry = hist.ledger[2]
			hist.pos = 2
		else
			entry = hist:writeEntry(do_advance)
		end

		if entry then
			editFuncS.initHistoryEntry(entry, LE.line, LE.cb, LE.hb)
			return entry
		end
	end
end


function editFuncS.writeHistoryLockedFirst(self)
	local LE = self.LE
	local hist = self.LE_hist
	assert(hist.locked_first, "called on a history struct without a locked first entry")
	if hist.enabled then
		hist.ledger[1] = hist.ledger[1] or {}
		local entry = hist.ledger[1]
		editFuncS.initHistoryEntry(entry, LE.line, LE.cb, LE.hb)
		hist.pos = 1
		return entry
	end
end


function editFuncS.applyHistoryEntry(self, entry)
	local LE = self.LE

	--print("editFuncS.applyHistoryEntry", "|"..entry.line.."|", entry.cb, entry.hb)

	LE.line, LE.cb, LE.hb = entry.line, entry.cb, entry.hb
end


function editFuncS.doctorHistoryCaretOffsets(self, cb, hb)
	local hist = self.LE_hist
	if hist.enabled then
		if not hist.locked_first or (hist.locked_first and hist.pos > 1) then
			local entry = hist.ledger[hist.pos]

			if entry then
				entry.cb, entry.hb = cb, hb
			end
		end
	end
end


-- Deletes all history entries, then writes a new entry based on the current LE state.
-- Also clears the widget's input category.
function editFuncS.wipeHistoryEntries(self)
	self.LE_hist:clearAll()
	self:resetInputCategory()
	editFuncS.writeHistoryEntry(self, true)
end


return editFuncS
