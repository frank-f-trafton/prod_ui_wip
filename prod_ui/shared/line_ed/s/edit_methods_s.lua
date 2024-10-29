-- To load: local lib = context:getLua("shared/lib")


--[[
	LineEditor (single) plug-in methods for client widgets.
--]]


local context = select(1, ...)


local editMethodsS = {}
local client = editMethodsS


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local commonEd = context:getLua("shared/line_ed/common_ed")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


client.getReplaceMode = commonEd.client_getReplaceMode
client.setReplaceMode = commonEd.client_setReplaceMode


local function _checkClearHighlight(line_ed, clear_highlight)
	if clear_highlight then
		line_ed:clearHighlight()
	end
end


local function _deleteHighlightedText(self)
	local line_ed = self.line_ed

	if line_ed:isHighlighted() then
		local byte_1, byte_2 = line_ed:getHighlightOffsets()
		line_ed:clearHighlight()
		return line_ed:deleteText(true, byte_1, byte_2 - 1)
	end
end


local function _deleteUChar(self, n_u_chars)
	local line_ed = self.line_ed
	local line = line_ed.line

	line_ed:clearHighlight()

	-- Nothing to delete at the last caret position.
	if line_ed.car_byte > #line then
		return
	end

	local byte_2, u_count = edComS.countUChars(line, 1, line_ed.car_byte, n_u_chars)
	if u_count == 0 then
		byte_2 = #line + 1
	end

	-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
	return line_ed:deleteText(true, line_ed.car_byte, byte_2 - 1)
end


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function client:deleteHighlightedText()
	local line_ed = self.line_ed
	local rv = _deleteHighlightedText(self)
	line_ed:updateDisplayText()
	return rv
end


--- Delete characters by stepping backwards from the caret position.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:backspaceUChar(n_u_chars)
	local line_ed = self.line_ed
	local line = line_ed.line

	line_ed:clearHighlight()

	local byte_1, u_count = edComS.countUChars(line, -1, line_ed.car_byte, n_u_chars)
	local rv
	if u_count > 0 then
		rv = line_ed:deleteText(true, byte_1, line_ed.car_byte - 1)
	end

	line_ed:updateDisplayText()
	return rv
end


local function _writeText(self, text, suppress_replace)
	local line_ed = self.line_ed

	-- Sanitize input
	text = edComBase.cleanString(text, self.bad_input_rule, self.tabs_to_spaces, self.allow_line_feed)

	if not self.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		_deleteHighlightedText(self)

	elseif self.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		_deleteUChar(self, utf8.len(text))
	end

	-- Trim text to fit the allowed uChars limit.
	text = textUtil.trimString(text, self.u_chars_max - utf8.len(line_ed.line))

	line_ed:insertText(text)
	line_ed:updateDisplayText()

	return text
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized, and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
-- entering line feeds, etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function client:writeText(text, suppress_replace)
	local rv = _writeText(self, text, suppress_replace)
	self.line_ed:updateDisplayText()
	return rv
end


function client:replaceText(text)
	local line_ed = self.line_ed

	line_ed:deleteText(false, 1, #line_ed.line)
	return self:writeText(text, true)
end


-- -1 == undo, 1 == redo
function client:stepHistory(dir)
	local line_ed = self.line_ed
	local hist = line_ed.hist

	local changed, entry = hist:moveToEntry(hist.pos + dir)

	if changed then
		editHistS.applyEntry(self, entry)
		line_ed:updateDisplayText()
	end
end


function client:getText()
	return self.line_ed.line
end


function client:getDisplayText()
	return self.line_ed.disp_text
end


function client:getHighlightedText()
	local line_ed = self.line_ed

	if line_ed:isHighlighted() then
		local b1, b2 = self.line_ed:getHighlightOffsets()
		return line_ed.line:sub(b1, b2 - 1)
	end
end


function client:isHighlighted()
	return self.line_ed:isHighlighted()
end


function client:clearHighlight()
	local line_ed = self.line_ed

	if line_ed:clearHighlight() then
		line_ed:syncDisplayCaretHighlight()
	end
end


function client:highlightAll()
	local line_ed = self.line_ed

	line_ed.car_byte = #line_ed.line + 1
	line_ed.h_byte = 1

	line_ed:syncDisplayCaretHighlight()
end


--- Moves caret to the left highlight edge
function client:caretHighlightEdgeLeft()
	local line_ed = self.line_ed

	local byte_1, byte_2 = line_ed:getHighlightOffsets()
	line_ed.car_byte, line_ed.h_byte = byte_1, byte_1

	line_ed:syncDisplayCaretHighlight()
end


--- Moves caret to the right highlight edge
function client:caretHighlightEdgeRight()
	local line_ed = self.line_ed

	local byte_1, byte_2 = line_ed:getHighlightOffsets()
	line_ed.car_byte, line_ed.h_byte = byte_2, byte_2

	line_ed:syncDisplayCaretHighlight()
end


function client:highlightCurrentWord()
	local line_ed = self.line_ed

	line_ed.car_byte, line_ed.h_byte = line_ed:getWordRange(line_ed.car_byte)

	line_ed:syncDisplayCaretHighlight()
end


function client:caretStepLeft(clear_highlight)
	local line_ed = self.line_ed

	line_ed.car_byte = edComS.offsetStepLeft(line_ed.line, line_ed.car_byte) or 1

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


function client:caretStepRight(clear_highlight)
	local line_ed = self.line_ed

	local new_byte = edComS.offsetStepRight(line_ed.line, line_ed.car_byte)
	line_ed.car_byte = new_byte or #line_ed.line + 1

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


function client:caretJumpLeft(clear_highlight)
	local line_ed = self.line_ed

	line_ed.car_byte = edComS.huntWordBoundary(code_groups, line_ed.line, line_ed.car_byte, -1, false, -1)

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


function client:caretJumpRight(clear_highlight)
	local line_ed = self.line_ed

	local hit_non_ws = false

	local first_group
	if line_ed.car_byte <= #line_ed.line then
		first_group = code_groups[utf8.codepoint(line_ed.line, line_ed.car_byte)]
	end

	if first_group ~= "whitespace" then
		hit_non_ws = true
	end

	--print("hit_non_ws", hit_non_ws, "first_group", first_group)

	--(lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed)
	line_ed.car_byte = edComS.huntWordBoundary(code_groups, line_ed.line, line_ed.car_byte, 1, hit_non_ws, first_group)

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


--- Delete characters on and to the right of the caret.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:deleteUChar(n_u_chars)
	local rv = _deleteUChar(self, n_u_chars)
	self.line_ed:updateDisplayText()
	return rv
end


function client:deleteGroup()
	local line_ed = self.line_ed

	line_ed:clearHighlight()
	local rv

	if line_ed.car_byte < #line_ed.line + 1 then
		local hit_non_ws = false
		local first_group = code_groups[utf8.codepoint(line_ed.line, line_ed.car_byte)]
		if first_group ~= "whitespace" then
			hit_non_ws = true
		end
		--print("HIT_NON_WS", hit_non_ws, "FIRST_GROUP", first_group)

		local byte_right = edComS.huntWordBoundary(code_groups, line_ed.line, line_ed.car_byte, 1, hit_non_ws, first_group)
		byte_right = byte_right - 1
		--print("deleteGroup: byte_right", byte_right)

		--print("ranges:", line_ed.car_byte, byte_right)
		rv = line_ed:deleteText(true, line_ed.car_byte, byte_right)
	end
	line_ed:updateDisplayText()
	--print("DEL", "|"..(rv or "<nil>").."|")
	if rv ~= "" then
		return rv
	end
end


function client:backspaceGroup()
	local line_ed = self.line_ed

	line_ed:clearHighlight()
	local rv

	if line_ed.car_byte > 1 then
		local byte_left = edComS.huntWordBoundary(code_groups, line_ed.line, line_ed.car_byte, -1, false, -1)
		if byte_left ~= line_ed.car_byte then
			rv = line_ed:deleteText(true, byte_left, line_ed.car_byte - 1)
		end
	end
	line_ed:updateDisplayText()
	return rv
end


function client:deleteCaretToEnd()
	local line_ed = self.line_ed

	line_ed:clearHighlight()
	local rv = line_ed:deleteText(true, line_ed.car_byte, #line_ed.line)
	line_ed:updateDisplayText()
	return rv
end


function client:deleteCaretToStart()
	local line_ed = self.line_ed

	line_ed:clearHighlight()
	local rv = line_ed:deleteText(true, 1, line_ed.car_byte - 1)
	self:updateDisplayText()
	return rv
end


function client:caretFirst(clear_highlight)
	local line_ed = self.line_ed

	line_ed.car_byte = 1

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


function client:caretLast(clear_highlight)
	local line_ed = self.line_ed

	line_ed.car_byte = #line_ed.line + 1

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


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

	local cut = self:deleteHighlightedText()

	if cut then
		cut = textUtil.sanitize(cut, self.bad_input_rule)

		-- Don't leak masked string info.
		if line_ed.masked then
			cut = table.concat(cut, "\n")
			cut = string.rep(line_ed.mask_glyph, utf8.len(cut))
		end

		love.system.setClipboardText(cut)
		return cut
	end
end


function client:pasteClipboardText()
	local line_ed = self.line_ed

	if line_ed:isHighlighted() then
		_deleteHighlightedText(self)
	end

	local text = love.system.getClipboardText()

	-- love.system.getClipboardText() may return an empty string if there is nothing in the clipboard,
	-- or if the current clipboard payload is not text. I'm not sure if it can return nil as well.
	-- Check both cases here to be sure.
	if text and text ~= "" then
		self:writeText(text, true)
		return true
	end
end


function client:caretToX(clear_highlight, x, split_x)
	local line_ed = self.line_ed
	local byte = line_ed:getCharacterDetailsAtPosition(x, split_x)

	line_ed:caretToByte(byte)

	_checkClearHighlight(line_ed, clear_highlight)
	line_ed:syncDisplayCaretHighlight()
end


function client:clickDragByWord(x, origin_byte)
	local line_ed = self.line_ed

	local drag_byte = line_ed:getCharacterDetailsAtPosition(x, true)

	-- Expand ranges to cover full words
	local db1, db2 = line_ed:getWordRange(drag_byte)
	local cb1, cb2 = line_ed:getWordRange(origin_byte)

	-- Merge the two ranges.
	local mb1, mb2 = math.min(cb1, db1), math.max(cb2, db2)
	if origin_byte < drag_byte then
		mb1, mb2 = mb2, mb1
	end

	line_ed:caretToByte(mb1)
	line_ed:highlightToByte(mb2)
	line_ed:syncDisplayCaretHighlight()
end


function client:getReplaceMode()
	return self.replace_mode
end


--- When Replace Mode is active, new text overwrites existing characters under the caret.
function client:setReplaceMode(enabled)
	self.replace_mode = not not enabled
end


return editMethodsS
