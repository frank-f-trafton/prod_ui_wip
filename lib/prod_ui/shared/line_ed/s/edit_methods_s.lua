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
local commonEd = context:getLua("shared/line_ed/common_ed")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local lineManip = context:getLua("shared/line_ed/line_manip")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


client.getReplaceMode = commonEd.client_getReplaceMode
client.setReplaceMode = commonEd.client_setReplaceMode


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function client:deleteHighlightedText()

	local line_ed = self.line_ed

	if not self:isHighlighted() then
		return nil
	end

	-- Clean up display highlight beforehand. Much harder to determine the offsets after deleting things.
	local byte_1, byte_2 = line_ed:getHighlightOffsets()
	line_ed:highlightCleanup()

	return line_ed:deleteText(true, byte_1, byte_2 - 1)
end


--- Delete characters by stepping backwards from the caret position.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:backspaceUChar(n_u_chars)

	local line_ed = self.line_ed
	line_ed:highlightCleanup()

	local line = line_ed.line
	local byte_1, u_count = lineManip.countUChars(line, -1, line_ed.car_byte, n_u_chars)

	if u_count > 0 then
		return line_ed:deleteText(true, byte_1, line_ed.car_byte - 1)
	end

	return nil
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
-- entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function client:writeText(text, suppress_replace)

	local line_ed = self.line_ed
	local line = line_ed.line

	-- Sanitize input
	text = edComBase.cleanString(text, line_ed.bad_input_rule, line_ed.tabs_to_spaces, line_ed.allow_line_feed)

	if not line_ed.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		self:deleteHighlightedText()

	elseif line_ed.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		local n_to_delete = edComBase.countUChars(text, math.huge)
		self:deleteUChar(n_to_delete)
	end

	-- Trim text to fit the allowed uChars limit.
	line_ed.u_chars = utf8.len(line_ed.line)
	text = textUtil.trimString(text, line_ed.u_chars_max - line_ed.u_chars)

	line_ed:insertText(text)

	return text
end


function client:stepHistory(dir)

	-- -1 == undo
	-- 1 == redo

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


function client:getHighlightedText()

	local line_ed = self.line_ed

	if line_ed:isHighlighted() then
		local b1, b2 = self.line_ed:getHighlightOffsets()
		return string.sub(line_ed.line, b1, b2)
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

	line_ed.car_byte = 1
	line_ed.h_byte = #line_ed.line + 1

	--line_ed:displaySyncCaretOffsets()
	--line_ed:updateDispHighlightRange()
end


--- Moves caret to the left highlight edge
function client:caretHighlightEdgeLeft()

	local line_ed = self.line_ed

	local byte_1, byte_2 = line_ed:getHighlightOffsets()

	line_ed.car_byte = byte_1
	line_ed.h_byte = byte_1

	--line_ed:displaySyncCaretOffsets()
	--line_ed:updateDispHighlightRange()
end


--- Moves caret to the right highlight edge
function client:caretHighlightEdgeRight()

	local line_ed = self.line_ed

	local byte_1, byte_2 = line_ed:getHighlightOffsets()

	line_ed.car_byte = byte_2
	line_ed.h_byte = byte_2

	--line_ed:displaySyncCaretOffsets()
	--line_ed:updateDispHighlightRange()
end


function client:highlightCurrentWord()

	local line_ed = self.line_ed

	line_ed.car_byte, line_ed.h_byte = line_ed:getWordRange(line_ed.car_line, line_ed.car_byte)

	line_ed:displaySyncCaretOffsets()
	line_ed:updateDispHighlightRange()
end


--- Helper that takes care of history changes following an action.
-- @param self The client widget
-- @param bound_func The wrapper function to call. It should take 'self' as its first argument, the LineEditor core as the second, and return values that control if and how the lineEditor object is updated. For more info, see the bound_func(self) call here, and also in EditAct.
-- @return The results of bound_func(), in case they are helpful to the calling widget logic.
function client:executeBoundAction(bound_func)

	local line_ed = self.line_ed

	local old_byte, old_h_byte = line_ed:getCaretOffsets()
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

		editHist.doctorCurrentCaretOffsets(line_ed.hist, old_byte, old_h_byte)
		editHist.writeEntry(line_ed, true)
	end

	return update_viewport, caret_in_view, write_history
end


function client:caretStepLeft(clear_highlight)

	local line_ed = self.line_ed

	local new_byte = lineManip.offsetStepLeft(line_ed.line, line_ed.car_byte)
	line_ed.car_byte = new_byte or 1

	line_ed:displaySyncCaretOffsets()

	if clear_highlight then
		print("??? clear_highlight ???", clear_highlight)
		line_ed:clearHighlight()

	else
		line_ed:updateDispHighlightRange()
	end
end


function client:caretStepRight(clear_highlight)

	local line_ed = self.line_ed

	local new_byte = lineManip.offsetStepRight(line_ed.line, line_ed.car_byte)
	line_ed.car_byte = new_byte or #line_ed.line + 1

 	line_ed:displaySyncCaretOffsets()

	if clear_highlight then
		line_ed:clearHighlight()

	else
		line_ed:updateDispHighlightRange()
	end
end


--- Delete characters on and to the right of the caret.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:deleteUChar(n_u_chars)

	local line_ed = self.line_ed
	local line = line_ed.line

	line_ed:highlightCleanup()

	-- Nothing to delete at the last caret position.
	if line_ed.car_byte > #line then
		return -- nil
	end

	local byte_2, u_count = lineManip.countUChars(line, 1, line_ed.car_byte, n_u_chars)
	if u_count == 0 then
		byte_2 = #line + 1
	end

	-- Delete offsets are inclusive, so get the rightmost byte that is part of the final code point.
	return line_ed:deleteText(true, line_ed.car_byte, byte_2 - 1)
end


return editMethodsS
