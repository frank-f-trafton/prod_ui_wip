--[[
Wrappable command functions for common LineEditor actions.

For more info, see the comments at the top of 'shared/line_ed/s/edit_command_s.lua'.

Recap of return values:
-- 1) success, 2) update_wid, 3) caret_in_view, 4) write_hist, 5) del_text, 6) stepped_hist
--]]


local context = select(1, ...)


local editCommandM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


function editCommandM.noOpTrue(self)
	return true
end


function editCommandM.noOpNil(self)
	-- n/a
end


function editCommandM.setAllowReplaceMode(self, enabled)
	local LE = self.LE

	enabled = not not enabled
	if self.LE_allow_replace ~= enabled then
		self.LE_allow_replace = enabled
		if not enabled then
			self.LE_replace_mode = false
		end
	end

	return true, true
end


function editCommandM.setReplaceMode(self, enabled)
	if not (self.LE_allow_input and self.LE_allow_replace) then
		enabled = false
	end
	self.LE_replace_mode = not not enabled
	return true, true
end


function editCommandM.toggleReplaceMode(self)
	if not (self.LE_allow_input and self.LE_allow_replace) then
		self.LE_replace_mode = false
	else
		self.LE_replace_mode = not self.LE_replace_mode
	end
	return true, true
end


function editCommandM.setAllowInput(self, enabled)
	editFuncM.setAllowInput(self, enabled)
	return true, true
end


function editCommandM.cut(self)
	if self.LE_allow_input and self.LE_allow_cut and self.LE_allow_highlight and self.LE:isHighlighted() then
		if editFuncM.cutHighlightedToClipboard(self) then
			self.LE_input_category = false

			return true, true, true, true
		end
	end
end


function editCommandM.copy(self)
	if self.LE_allow_copy and self.LE_allow_highlight and self.LE:isHighlighted() then
		editFuncM.copyHighlightedToClipboard(self)

		return true
	end
end


function editCommandM.paste(self)
	if self.LE_allow_input and self.LE_allow_paste and editFuncM.pasteClipboard(self) then
		self.LE_input_category = false

		return true, true, true, true
	end
end


function editCommandM.deleteCaretToLineStart(self)
	if self.LE_allow_input then
		editFuncM.deleteCaretToLineStart(self)
		self.LE_input_category = false

		return true, true, true, true
	end
end


function editCommandM.deleteCaretToLineEnd(self)
	if self.LE_allow_input then
		editFuncM.deleteCaretToLineEnd(self)
		self.LE_input_category = false

		return true, true, true, true
	end
end


function editCommandM.backspaceGroup(self)
	if self.LE_allow_input then
		local write_hist = not not editFuncM.backspaceGroup(self)
		self.LE_input_category = false

		return true, true, true, write_hist
	end
end


function editCommandM.caretLeft(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self)
	else
		editFuncM.caretStepLeft(self, true)
	end

	return true, true, true
end


function editCommandM.caretRight(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	else
		editFuncM.caretStepRight(self, true)
	end

	return true, true, true
end


function editCommandM.caretToHighlightEdgeLeft(self)
	if self.LE_allow_highlight then
		editFuncM.caretToHighlightEdgeLeft(self)
	else
		self.LE:clearHighlight()
	end

	return true, true, true
end


function editCommandM.caretToHighlightEdgeRight(self)
	if self.LE_allow_highlight then
		editFuncM.caretToHighlightEdgeRight(self)
	else
		self.LE:clearHighlight()
	end

	return true, true, true
end


-- Step left, right while highlighting
function editCommandM.caretLeftHighlight(self)
	editFuncM.caretStepLeft(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretRightHighlight(self)
	editFuncM.caretStepRight(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretJumpLeft(self)
	editFuncM.caretJumpLeft(self, true)

	return true, true, true
end


function editCommandM.caretJumpRight(self)
	editFuncM.caretJumpRight(self, true)

	return true, true, true
end


function editCommandM.caretJumpLeftHighlight(self)
	editFuncM.caretJumpLeft(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretJumpRightHighlight(self)
	editFuncM.caretJumpRight(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretFullLineFirst(self)
	editFuncM.caretFullLineFirst(self, true)

	return true, true, true
end


function editCommandM.caretFullLineFirstHighlight(self)
	editFuncM.caretFullLineFirst(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretFullLineLast(self)
	editFuncM.caretFullLineLast(self, true)

	return true, true, true
end


function editCommandM.caretFullLineLastHighlight(self)
	editFuncM.caretFullLineLast(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretSubLineFirst(self)
	editFuncM.caretSubLineFirst(self, true)

	return true, true, true
end


function editCommandM.caretSubLineFirstHighlight(self)
	editFuncM.caretSubLineFirst(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretSubLineLast(self)
	editFuncM.caretSubLineLast(self, true)

	return true, true, true
end


function editCommandM.caretSubLineLastHighlight(self)
	editFuncM.caretSubLineLast(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretLineFirst(self)
	editFuncM.caretLineFirst(self, true)

	return true, true, true
end


function editCommandM.caretLineFirstHighlight(self)
	editFuncM.caretLineFirst(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretLineLast(self)
	editFuncM.caretLineLast(self, true)

	return true, true, true
end


function editCommandM.caretLineLastHighlight(self)
	editFuncM.caretLineLast(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretFirst(self)
	editFuncM.caretFirst(self, true)

	return true, true, true
end


function editCommandM.caretFirstHighlight(self)
	editFuncM.caretFirst(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretLast(self)
	editFuncM.caretLast(self, true)

	return true, true, true
end


function editCommandM.caretLastHighlight(self)
	editFuncM.caretLast(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretStepUp(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self, not self.LE_allow_highlight)
	end
	editFuncM.caretStepUp(self, true, 1)

	return true, true, true
end


function editCommandM.caretStepDown(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	end
	editFuncM.caretStepDown(self, true, 1)

	return true, true, true
end


function editCommandM.caretStepUpHighlight(self)
	editFuncM.caretStepUp(self, not self.LE_allow_highlight, 1)

	return true, true, true
end


function editCommandM.caretStepDownHighlight(self)
	editFuncM.caretStepDown(self, not self.LE_allow_highlight, 1)

	return true, true, true
end


function editCommandM.caretStepUpCoreLine(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self, not self.LE_allow_highlight)
	end
	editFuncM.caretStepUpCoreLine(self, true)

	return true, true, true
end


function editCommandM.caretStepDownCoreLine(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	end
	editFuncM.caretStepDownCoreLine(self, true)

	return true, true, true
end


function editCommandM.caretStepUpCoreLineHighlight(self)
	editFuncM.caretStepUpCoreLine(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretStepDownCoreLineHighlight(self)
	editFuncM.caretStepDownCoreLine(self, not self.LE_allow_highlight)

	return true, true, true
end


function editCommandM.caretPageUp(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self, not self.LE_allow_highlight)
	end
	editFuncM.caretStepUp(self, true, self.LE_page_jump_steps)

	return true, true, true
end


function editCommandM.caretPageDown(self)
	if self.LE:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	end
	editFuncM.caretStepDown(self, true, self.LE_page_jump_steps)

	return true, true, true
end


function editCommandM.caretPageUpHighlight(self)
	editFuncM.caretStepUp(self, not self.LE_allow_highlight, self.LE_page_jump_steps)

	return true, true, true
end


function editCommandM.caretPageDownHighlight(self)
	editFuncM.caretStepDown(self, not self.LE_allow_highlight, self.LE_page_jump_steps)

	return true, true, true
end


function editCommandM.shiftLinesUp(self)
	if self.LE_allow_input and editFuncM.shiftLinesUp(self) then
		return true, true, true, true
	end
end


function editCommandM.shiftLinesDown(self)
	if self.LE_allow_input and editFuncM.shiftLinesDown(self) then
		return true, true, true, true
	end
end


function editCommandM.deleteAll(self)
	if self.LE_allow_input and editFuncM.deleteAll(self) then
		return true, true, true, true
	end
end


function editCommandM.deleteHighlighted(self)
	if self.LE_allow_input and self.LE:isHighlighted() then
		-- Always write history if anything was deleted.
		if editFuncM.deleteHighlighted(self) then
			return true, true, true, true
		end
	end
end


function editCommandM.backspace(self)
	if self.LE_allow_input then
		if self.LE:isHighlighted() then
			local backspaced = editFuncM.deleteHighlighted(self)
			if backspaced then
				return true, true, true, true
			end
		else
			local backspaced = editFuncM.backspaceUChar(self, 1)
			if backspaced then
				return true, true, true, "bsp", backspaced
			end
		end
	end
end


function editCommandM.delete(self)
	if self.LE_allow_input then
		if self.LE:isHighlighted() then
			local deleted = editFuncM.deleteHighlighted(self)
			if deleted then
				return true, true, true, true
			end
		else
			local deleted = editFuncM.deleteUChar(self, 1)
			if deleted then
				return true, true, true, "del", deleted
			end
		end
	end
end


function editCommandM.deleteUChar(self, n_u_chars)
	if self.LE_allow_input then
		local write_hist = not not editFuncM.deleteUChar(self, n_u_chars)

		return true, true, true, write_hist
	end
end


function editCommandM.deleteGroup(self)
	if self.LE_allow_input then
		self.LE_input_category = false
		local write_hist = not not editFuncM.deleteGroup(self)

		return true, true, true, write_hist
	end
end


function editCommandM.deleteLine(self)
	if self.LE_allow_input then
		self.LE_input_category = false
		local write_hist = not not editFuncM.deleteLine(self)

		return true, true, true, write_hist
	end
end


function editCommandM.backspaceCaretToLineStart(self)
	if self.LE_allow_input then
		self:deleteCaretToLineStart()
		self.LE_input_category = false

		return true, true, true, true
	end
end


-- Add line feed (unhighlights first)
function editCommandM.typeLineFeedWithAutoIndent(self)
	if self.LE_allow_input and self.LE_allow_line_feed then
		editFuncM.typeLineFeedWithAutoIndent(self)
		return true, true, true, true
	end
end


function editCommandM.typeLineFeed(self)
	if self.LE_allow_input and self.LE_allow_line_feed then
		editFuncM.typeLineFeed(self)
		return true, true, true, true
	end
end


function editCommandM.typeTab(self)
	if self.LE_allow_input and self.LE_allow_tab then
		local ok = editFuncM.typeTab(self)
		return true, ok, false, ok, false
	end
end


function editCommandM.typeUntab(self)
	if self.LE_allow_input and self.LE_allow_untab then
		local ok = editFuncM.typeUntab(self)
		return true, ok, false, ok, false
	end
end


function editCommandM.highlightAll(self)
	if self.LE_allow_highlight then
		editFuncM.highlightAll(self)
	else
		self.LE:clearHighlight()
	end

	return true, true
end


function editCommandM.highlightCurrentWord(self)
	if self.LE_allow_highlight then
		editFuncM.highlightCurrentWord(self)
	else
		self.LE:clearHighlight()
	end

	return true, true
end


function editCommandM.highlightCurrentLine(self)
	if self.LE_allow_highlight then
		editFuncM.highlightCurrentLine(self)
	else
		self.LE:clearHighlight()
	end

	return true, true
end


function editCommandM.highlightCurrentWrappedLine(self)
	if self.LE_allow_highlight then
		editFuncM.highlightCurrentWrappedLine(self)
	else
		self.LE:clearHighlight()
	end

	return true, true
end


function editCommandM.clearHighlight(self)
	self.LE:clearHighlight()

	return true, true
end


function editCommandM.stepHistory(self, dir)
	if self.LE_allow_input and editFuncM.stepHistory(self, dir) then
		self.LE_input_category = false
		return true, true, true, nil, nil, true
	end
end


function editCommandM.undo(self)
	if self.LE_allow_input and editFuncM.stepHistory(self, -1) then
		self.LE_input_category = false
		return true, true, true, nil, nil, true
	end
end


function editCommandM.redo(self)
	if self.LE_allow_input and editFuncM.stepHistory(self, 1) then
		self.LE_input_category = false
		return true, true, true, nil, nil, true
	end
end


function editCommandM.setTextAlignment(self, align)
	local ok = self.LE:setTextAlignment(align)
	return ok, ok, ok
end


function editCommandM.writeText(self, text)
	editFuncM.writeText(self, text)

	return true, true, true, true
end


function editCommandM.replaceText(self, text)
	editFuncM.replaceText(self, text)

	return true, true, true, true
end


function editCommandM.setText(self, text)
	editFuncM.setText(self, text)

	-- Don't write a history entry from here. One has already been set up in editFuncM.setText().
	return true, true, true
end


function editCommandM.setWrapMode(self, enabled)
	if self.LE:setWrapMode(enabled) then
		return true, true, true
	end
end


function editCommandM.setColorization(self, enabled)
	if self.LE:setColorization(enabled) then
		return true, true, true
	end
end


function editCommandM.setAllowHighlight(self, enabled)
	if editFuncM.setAllowHighlight(self, enabled) then
		return true, true, true
	end
end


function editCommandM.caretToLineAndByte(self, clear_highlight, l1, b1)
	local LE = self.LE

	local ok = LE:moveCaret(l1, b1, clear_highlight, true)
	return ok, ok, ok
end


return editCommandM
