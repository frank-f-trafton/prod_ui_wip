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


function editCommandM.setReplaceMode(self, enabled)
	local old = self.replace_mode
	self.replace_mode = not not enabled
	return old ~= self.replace_mode
end


function editCommandM.toggleReplaceMode(self)
	local old = self.replace_mode
	self.replace_mode = not self.replace_mode
	return old ~= self.replace_mode
end


function editCommandM.cut(self)
	if self.allow_input and self.allow_cut and self.allow_highlight and self.line_ed:isHighlighted() then
		if editFuncM.cutHighlightedToClipboard(self) then
			self.input_category = false

			return true, true, true, true
		end
	end
end


function editCommandM.copy(self)
	if self.allow_copy and self.allow_highlight and self.line_ed:isHighlighted() then
		editFuncM.copyHighlightedToClipboard(self)

		return true
	end
end


function editCommandM.paste(self)
	if self.allow_input and self.allow_paste and editFuncM.pasteClipboard(self) then
		self.input_category = false

		return true, true, true, true
	end
end


function editCommandM.deleteCaretToLineStart(self)
	if self.allow_input then
		editFuncM.deleteCaretToLineStart(self)
		self.input_category = false

		return true, true, true, true
	end
end


function editCommandM.deleteCaretToLineEnd(self)
	if self.allow_input then
		editFuncM.deleteCaretToLineEnd(self)
		self.input_category = false

		return true, true, true, true
	end
end


function editCommandM.backspaceGroup(self)
	if self.allow_input then
		local write_hist = not not editFuncM.backspaceGroup(self)
		self.input_category = false

		return true, true, true, write_hist
	end
end


function editCommandM.caretLeft(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self)
	else
		editFuncM.caretStepLeft(self, true)
	end

	return true, true, true
end


function editCommandM.caretRight(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	else
		editFuncM.caretStepRight(self, true)
	end

	return true, true, true
end


function editCommandM.caretToHighlightEdgeLeft(self)
	if self.allow_highlight then
		editFuncM.caretToHighlightEdgeLeft(self)
	else
		editFuncM.clearHighlight(self)
	end

	return true, true, true
end


function editCommandM.caretToHighlightEdgeRight(self)
	if self.allow_highlight then
		editFuncM.caretToHighlightEdgeRight(self)
	else
		editFuncM.clearHighlight(self)
	end

	return true, true, true
end


-- Step left, right while highlighting
function editCommandM.caretLeftHighlight(self)
	editFuncM.caretStepLeft(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretRightHighlight(self)
	editFuncM.caretStepRight(self, not self.allow_highlight)

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
	editFuncM.caretJumpLeft(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretJumpRightHighlight(self)
	editFuncM.caretJumpRight(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretLineFirst(self)
	editFuncM.caretLineFirst(self, true)

	return true, true, true
end


function editCommandM.caretLineLast(self)
	editFuncM.caretLineLast(self, true)

	return true, true, true
end


function editCommandM.caretFirst(self)
	editFuncM.caretFirst(self, true)

	return true, true, true
end


function editCommandM.caretLast(self)
	editFuncM.caretLast(self, true)

	return true, true, true
end


function editCommandM.caretFirstHighlight(self)
	editFuncM.caretFirst(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretLastHighlight(self)
	editFuncM.caretLast(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretLineFirstHighlight(self)
	editFuncM.caretLineFirst(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretLineLastHighlight(self)
	editFuncM.caretLineLast(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretStepUp(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self, not self.allow_highlight)
	end
	editFuncM.caretStepUp(self, true, 1)

	return true, true, true
end


function editCommandM.caretStepDown(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	end
	editFuncM.caretStepDown(self, true, 1)

	return true, true, true
end


function editCommandM.caretStepUpHighlight(self)
	editFuncM.caretStepUp(self, not self.allow_highlight, 1)

	return true, true, true
end


function editCommandM.caretStepDownHighlight(self)
	editFuncM.caretStepDown(self, not self.allow_highlight, 1)

	return true, true, true
end


function editCommandM.caretStepUpCoreLine(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self, not self.allow_highlight)
	end
	editFuncM.caretStepUpCoreLine(self, true)

	return true, true, true
end


function editCommandM.caretStepDownCoreLine(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	end
	editFuncM.caretStepDownCoreLine(self, true)

	return true, true, true
end


function editCommandM.caretStepUpCoreLineHighlight(self)
	editFuncM.caretStepUpCoreLine(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretStepDownCoreLineHighlight(self)
	editFuncM.caretStepDownCoreLine(self, not self.allow_highlight)

	return true, true, true
end


function editCommandM.caretPageUp(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeLeft(self, not self.allow_highlight)
	end
	editFuncM.caretStepUp(self, true, self.page_jump_steps)

	return true, true, true
end


function editCommandM.caretPageDown(self)
	if self.line_ed:isHighlighted() then
		editFuncM.caretToHighlightEdgeRight(self)
	end
	editFuncM.caretStepDown(self, true, self.page_jump_steps)

	return true, true, true
end


function editCommandM.caretPageUpHighlight(self)
	editFuncM.caretStepUp(self, not self.allow_highlight, self.page_jump_steps)

	return true, true, true
end


function editCommandM.caretPageDownHighlight(self)
	editFuncM.caretStepDown(self, not self.allow_highlight, self.page_jump_steps)

	return true, true, true
end


function editCommandM.shiftLinesUp(self)
	if self.allow_input and editFuncM.shiftLinesUp(self) then
		return true, true, true, true
	end
end


function editCommandM.shiftLinesDown(self)
	if self.allow_input and editFuncM.shiftLinesDown(self) then
		return true, true, true, true
	end
end


function editCommandM.deleteAll(self)
	if self.allow_input and editFuncM.deleteAll(self) then
		return true, true, true, true
	end
end


function editCommandM.deleteHighlighted(self)
	if self.allow_input and self.line_ed:isHighlighted() then
		-- Always write history if anything was deleted.
		if editFuncM.deleteHighlighted() then
			return true, true, true, true
		end
	end
end


function editCommandM.backspace(self)
	if self.allow_input then
		if self.line_ed:isHighlighted() then
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
	if self.allow_input then
		if self.line_ed:isHighlighted() then
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
	if self.allow_input then
		local write_hist = not not editFuncM.deleteUChar(self, n_u_chars)

		return true, true, true, write_hist
	end
end


function editCommandM.deleteGroup(self)
	if self.allow_input then
		self.input_category = false
		local write_hist = not not editFuncM.deleteGroup(self)

		return true, true, true, write_hist
	end
end


function editCommandM.deleteLine(self)
	if self.allow_input then
		self.input_category = false
		local write_hist = not not editFuncM.deleteLine(self)

		return true, true, true, write_hist
	end
end


function editCommandM.backspaceCaretToLineStart(self)
	if self.allow_input then
		self:deleteCaretToLineStart()
		self.input_category = false

		return true, true, true, true
	end
end


-- Add line feed (unhighlights first)
function editCommandM.typeLineFeedWithAutoIndent(self)
	if self.allow_input and self.allow_line_feed then
		editFuncM.typeLineFeedWithAutoIndent(self)
		return true, true, true, true
	end
end


function editCommandM.typeLineFeed(self)
	if self.allow_input and self.allow_line_feed then
		editFuncM.typeLineFeed(self)
		return true, true, true, true
	end
end


function editCommandM.typeTab(self)
	if self.allow_input and self.allow_tab then
		if editFuncM.typeTab(self) then
			return true, true, true, true
		end
	end
end


function editCommandM.typeUntab(self)
	if self.allow_input and self.allow_untab then
		if editFuncM.untypeTab(self) then
			return true, true, true, true
		end
	end
end


function editCommandM.highlightAll(self)
	if self.allow_highlight then
		editFuncM.highlightAll(self)
	else
		editFuncM.clearHighlight(self)
	end

	return true, true
end


function editCommandM.highlightCurrentWord(self)
	if self.allow_highlight then
		editFuncM.highlightCurrentWord(self)
	else
		editFuncM.clearHighlight(self)
	end

	return true, true
end


function editCommandM.highlightCurrentLine(self)
	if self.allow_highlight then
		editFuncM.highlightCurrentLine(self)
	else
		editFuncM.clearHighlight(self)
	end

	return true, true
end


function editCommandM.highlightCurrentWrappedLine(self)
	if self.allow_highlight then
		editFuncM.highlightCurrentWrappedLine(self)
	else
		editFuncM.clearHighlight(self)
	end

	return true, true
end


function editCommandM.stepHistory(self, dir)
	if self.hist.enabled then
		if editFuncM.stepHistory(self, dir) then
			self.input_category = false

			return true, true, true, nil, nil, true
		end
	end
end


function editCommandM.undo(self)
	if editFuncM.stepHistory(self, -1) then
		self.input_category = false
		return true, true, true, nil, nil, true
	end
end


function editCommandM.redo(self)
	if editFuncM.stepHistory(self, 1) then
		self.input_category = false
		return true, true, true, nil, nil, true
	end
end


function editCommandM.setTextAlignment(self, align)
	local ok = self.line_ed:setTextAlignment(align)
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

	return true, true, true, true
end


function editCommandM.setWrapMode(self, enabled)
	if self.line_ed:setWrapMode(enabled) then
		return true, true, true
	end
end


function editCommandM.setColorization(self, enabled)
	if self.line_ed:setColorization(enabled) then
		return true, true, true
	end
end


function editCommandM.setHighlightEnabled(self, enabled)
	if editFuncM.setHighlightEnabled(self, enabled) then
		return true, true, true
	end
end


function editCommandM.caretToLineAndByte(self, clear_highlight, line_n, byte_n)
	local line_ed = self.line_ed

	local ok = line_ed:moveCaret(line_n, byte_n, clear_highlight)
	return ok, ok, ok
end


return editCommandM
