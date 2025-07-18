-- LineEditor (multi) plug-in methods for client widgets.


local context = select(1, ...)


local editMethodsM = {}
local client = editMethodsM


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")
local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")
local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local editWrapM = context:getLua("shared/line_ed/m/edit_wrap_m")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


local _enum_align = uiShared.makeLUTV("left", "center", "right")


function client:deleteHighlighted()
	editWrapM.wrapAction(self, editCommandM.deleteHighlighted)
end


function client:backspace()
	editWrapM.wrapAction(self, editCommandM.backspace)
end


--[[!]] function client:getReplaceMode()
	return self.replace_mode
end


--[[!]] function client:setReplaceMode(enabled)
	self.replace_mode = not not enabled
end


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


function client:setTextAlignment(align)
	if not _enum_align[align] then
		error("invalid align mode")
	end

	editWrapM.wrapAction(self, editCommandM.setTextAlignment, align)
end


function client:getColorization()
	return self.line_ed.generate_colored_text
end


function client:setColorization(enabled)
	local line_ed = self.line_ed
	line_ed.generate_colored_text = not not enabled

	-- Refresh everything
	self.line_ed:displaySyncAll()
end


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


function client:stepHistory(dir)
	uiShared.type1(1, dir, "number")

	editWrapM.wrapAction(self, editCommandM.stepHistory, dir)
end


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
	editWrapM.wrapAction(self, editCommandM.clearHighlight)
end


function client:highlightAll()
	editWrapM.wrapAction(self, editCommandM.highlightAll)
end


function client:caretHighlightEdgeLeft()
	editWrapM.wrapAction(self, editCommandM.caretHighlightEdgeLeft)
end


function client:caretHighlightEdgeRight()
	editWrapM.wrapAction(self, editCommandM.caretHighlightEdgeRight)
end


function client:highlightCurrentLine()
	editWrapM.wrapAction(self, editCommandM.highlightCurrentLine)
end


function client:highlightCurrentWord()
	editWrapM.wrapAction(self, editCommandM.highlightCurrentWord)
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
	editWrapM.wrapAction(self, editCommandM.caretStepUp, clear_highlight, n_steps)
end


function client:caretStepDown(clear_highlight, n_steps)
	editWrapM.wrapAction(self, editCommandM.caretStepDown, clear_highlight, n_steps)
end


function client:caretStepUpCoreLine(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretStepUpCoreLine, clear_highlight)
end


function client:caretStepDownCoreLine(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretStepDownCoreLine, clear_highlight)
end


function client:caretToXY(clear_highlight, x, y, split_x)
	local line_ed = self.line_ed

	local line_ed_line, line_ed_byte = line_ed:getCharacterDetailsAtPosition(x, y, split_x)

	line_ed:caretToLineAndByte(clear_highlight, line_ed_line, line_ed_byte)
end


function client:writeText(text, suppress_replace)
	uiShared.type1(1, text, "string")

	editWrapM.wrapAction(self, editCommandM.writeText, text, suppress_replace)
end


--- Set the current internal text, wiping anything currently present.
function client:setText(text)
	local line_ed = self.line_ed

	local deleted = self:deleteAll()
	line_ed:insertText(text)

	return deleted
end


function client:cut()
	editWrapM.wrapAction(self, editCommandM.cut)
end


function client:copy()
	editWrapM.wrapAction(self, editCommandM.copy)
end


function client:paste()
	editWrapM.wrapAction(self, editCommandM.paste)
end


function client:deleteLine()
	editWrapM.wrapAction(self, editCommandM.deleteLine)
end


function client:deleteCaretToLineEnd()
	editWrapM.wrapAction(self, editCommandM.deleteCaretToLineEnd)
end


function client:deleteCaretToLineStart()
	editWrapM.wrapAction(self, editCommandM.deleteCaretToLineStart)
end


--- Delete characters on and to the right of the caret.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:deleteUChar(n_u_chars)
	uiShared.type1(1, n_u_chars, "number")

	editWrapM.wrapAction(self, editCommandM.deleteUChar, n_u_chars)
end


function client:deleteAll()
	local line_ed = self.line_ed

	line_ed:highlightCleanup()

	local lines = line_ed.lines

	return line_ed:deleteText(true, 1, 1, #lines, #lines[#lines])
end


function client:backspaceGroup()
	editWrapM.wrapAction(self, editCommandM.backspaceGroup)
end


function client:deleteGroup()
	editWrapM.wrapAction(self, editCommandM.deleteGroup)
end


function client:caretStepLeft(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretStepLeft, clear_highlight)
end


function client:caretStepRight(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretStepRight, clear_highlight)
end


function client:caretJumpLeft(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretJumpLeft, clear_highlight)
end


function client:caretJumpRight(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretJumpRight, clear_highlight)
end


function client:caretFirst(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretFirst, clear_highlight)
end


function client:caretLast(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretLast, clear_highlight)
end


function client:caretLineFirst(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretLineFirst, clear_highlight)
end


function client:caretLineLast(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretLineLast, clear_highlight)
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
