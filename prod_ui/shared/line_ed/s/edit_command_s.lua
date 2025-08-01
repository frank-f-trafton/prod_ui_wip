--[[
Wrappable command functions for common LineEditor actions.

Function arguments:
1) self: The client widget
2) [...]: Additional arguments for the function. [*1]

Return values:
1) true: the action was successful, and event handling should be stopped
2) true: update the widget (recalculate document dimensions, clamp scrolling offsets, etc.)
3) true: keep the caret in view
4) true: write a history entry
   "del": write a conditional history entry for deleting text
   "bsp": write a conditional history entry for backspacing text
5) string: if 4 was "del" or "bsp", the deleted or backspaced text
6) true: the action involved changing the history position (undo/redo)

When return value #1 is not true, then all other return values should be ignored.

Return value #1 being true updates the caret visual state, even if #2 is false.

[*1]: Commands used as key bindings do not take these arguments.

Recap:
-- 1) success, 2) update_wid, 3) caret_in_view, 4) write_hist, 5) del_text, 6) stepped_hist
--]]


local context = select(1, ...)


local editCommandS = {}


-- ProdUI
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


function editCommandS.setTextAlignment(self, align)
	local LE = self.LE
	if align ~= LE.align then
		LE.align = align
		return true, true, true
	end
end


function editCommandS.setReplaceMode(self, enabled)
	enabled = not not enabled
	if enabled ~= self.LE_replace_mode then
		self.LE_replace_mode = enabled
		return true
	end
end


function editCommandS.toggleReplaceMode(self)
	self.LE_replace_mode = not self.LE_replace_mode
	return true
end


function editCommandS.cut(self)
	if self.LE_allow_input and self.LE_allow_cut and self.LE_allow_highlight and self.LE:isHighlighted() then
		if editFuncS.cutHighlightedToClipboard(self) then -- handles masking
			self.LE_input_category = false

			return true, true, true, true
		end
	end
end


function editCommandS.copy(self)
	if self.LE_allow_copy and self.LE_allow_highlight and self.LE:isHighlighted() then
		editFuncS.copyHighlightedToClipboard(self) -- handles masking

		return true
	end
end


function editCommandS.paste(self)
	if self.LE_allow_input and self.LE_allow_paste and editFuncS.pasteClipboard(self) then
		self.LE_input_category = false

		return true, true, true, true
	end
end


function editCommandS.deleteCaretToStart(self)
	if self.LE_allow_input then
		editFuncS.deleteCaretToStart(self)
		self.LE_input_category = false

		return true, true, true, true
	end
end


function editCommandS.deleteCaretToEnd(self)
	if self.LE_allow_input then
		editFuncS.deleteCaretToEnd(self)
		self.LE_input_category = false

		return true, true, true, true
	end
end


function editCommandS.backspaceGroup(self)
	if self.LE_allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if self.LE.masked then
			write_hist = not not editFuncS.backspaceUChar(self, 1)
		else
			write_hist = not not editFuncS.backspaceGroup(self)
			self.LE_input_category = false
		end

		return true, true, true, write_hist
	end
end


function editCommandS.deleteGroup(self)
	if self.LE_allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if self.LE.masked then
			write_hist = not not editFuncS.deleteUChar(self, 1)
		else
			self.LE_input_category = false
			write_hist = not not editFuncS.deleteGroup(self)
		end

		return true, true, true, write_hist
	end
end


function editCommandS.deleteUChar(self, n_u_chars)
	if self.LE_allow_input then
		local write_hist = not not editFuncS.deleteUChar(self, n_u_chars)

		return true, true, true, write_hist
	end
end


function editCommandS.caretJumpRight(self)
	-- Don't leak details about the masked string.
	if self.LE.masked then
		editFuncS.caretLast(self, true)
	else
		editFuncS.caretJumpRight(self, true)
	end

	return true, nil, true
end


function editCommandS.caretJumpLeft(self)
	-- Don't leak details about the masked string.
	if self.LE.masked then
		editFuncS.caretFirst(self, true)
	else
		editFuncS.caretJumpLeft(self, true)
	end

	return true, nil, true
end


function editCommandS.caretLeft(self)
	if self.LE:isHighlighted() then
		editFuncS.caretToHighlightEdgeLeft(self)
	else
		editFuncS.caretStepLeft(self, true)
	end

	return true, nil, true
end


function editCommandS.caretRight(self)
	if self.LE:isHighlighted() then
		editFuncS.caretToHighlightEdgeRight(self)
	else
		editFuncS.caretStepRight(self, true)
	end

	return true, nil, true
end


function editCommandS.highlightCurrentWord(self)
	if self.LE_allow_highlight then
		editFuncS.highlightCurrentWord(self)
	else
		editFuncS.clearHighlight(self)
	end

	return true
end


function editCommandS.caretToHighlightEdgeLeft(self)
	if self.LE_allow_highlight then
		editFuncS.caretToHighlightEdgeLeft(self)
	else
		editFuncS.clearHighlight(self)
	end

	return true
end


function editCommandS.caretToHighlightEdgeRight(self)
	if self.LE_allow_highlight then
		editFuncS.caretToHighlightEdgeRight(self)
	else
		editFuncS.clearHighlight(self)
	end

	return true
end


function editCommandS.highlightAll(self)
	if self.LE_allow_highlight then
		editFuncS.highlightAll(self)
	else
		editFuncS.clearHighlight(self)
	end

	return true
end


function editCommandS.deleteAll(self)
	if self.LE_allow_input then
		local LE = self.LE
		local old_line = LE.line

		self.LE_input_category = false
		LE:deleteText(false, 1, #LE.line)
		LE:updateDisplayText()

		return true, true, true, (old_line ~= LE.line)
	end
end


function editCommandS.clearHighlight(self)
	editFuncS.clearHighlight(self)

	return true
end


function editCommandS.writeText(self, text)
	editFuncS.writeText(self, text)

	return true, true, true, true
end


function editCommandS.replaceText(self, text)
	editFuncS.replaceText(self, text)

	return true, true, true, true
end


function editCommandS.setText(self, text)
	editFuncS.setText(self, text)

	return true, true, true, true
end


function editCommandS.backspace(self)
	if self.LE_allow_input then
		if self.LE:isHighlighted() then
			local backspaced = editFuncS.deleteHighlighted(self)
			if backspaced then
				return true, true, true, true
			end
		else
			local backspaced = editFuncS.backspaceUChar(self, 1)
			if backspaced then
				return true, true, true, "bsp", backspaced
			end
		end
	end
end


function editCommandS.deleteHighlighted(self)
	if self.LE_allow_input then
		if self.LE:isHighlighted() then
			-- Always write history if anything was deleted.
			if editFuncS.deleteHighlighted(self) then
				return true, true, true, true
			end
		end
	end
end


function editCommandS.delete(self)
	if self.LE_allow_input then
		local deleted

		if self.LE:isHighlighted() then
			deleted = editFuncS.deleteHighlighted(self)
			if deleted then
				return true, true, true, true
			end
		else
			deleted = editFuncS.deleteUChar(self, 1)
			if deleted then
				return true, true, true, "del", deleted
			end
		end
	end
end


function editCommandS.caretLeftHighlight(self)
	editFuncS.caretStepLeft(self, not self.LE_allow_highlight)

	return true, nil, true
end


function editCommandS.caretRightHighlight(self)
	editFuncS.caretStepRight(self, not self.LE_allow_highlight)

	return true, nil, true
end


function editCommandS.stepHistory(self, dir)
	if editFuncS.stepHistory(self, dir) then
		self.LE_input_category = false

		return true, true, true, nil, nil, true
	end
end


function editCommandS.undo(self)
	if editFuncS.stepHistory(self, -1) then
		self.LE_input_category = false

		return true, true, true, nil, nil, true
	end
end


function editCommandS.redo(self)
	if editFuncS.stepHistory(self, 1) then
		self.LE_input_category = false

		return true, true, true, nil, nil, true
	end
end


function editCommandS.typeLineFeed(self)
	-- (Return / Enter key)
	if self.LE_allow_input and self.LE_allow_line_feed and self.LE_allow_enter_line_feed then
		self.LE_input_category = false
		editFuncS.writeText(self, "\n", true)

		return true, true, true, true
	end
end


function editCommandS.typeTab(self)
	if self.LE_allow_input and self.LE_allow_tab then
		local written = editFuncS.writeText(self, "\t", true)
		local changed = #written > 0

		return true, true, true, changed
	end
end


function editCommandS.caretFirstHighlight(self)
	editFuncS.caretFirst(self, not self.LE_allow_highlight)

	return true, nil, true
end


function editCommandS.caretLastHighlight(self)
	editFuncS.caretLast(self, not self.LE_allow_highlight)

	return true, nil, true
end


function editCommandS.caretFirst(self)
	editFuncS.caretFirst(self, true)

	return true, nil, true
end


function editCommandS.caretLast(self)
	editFuncS.caretLast(self, true)

	return true, nil, true
end


function editCommandS.caretJumpLeftHighlight(self)
	-- Don't leak details about the masked string.
	if self.LE.masked then
		editFuncS.caretFirst(self, not self.LE_allow_highlight)
	else
		editFuncS.caretJumpLeft(self, not self.LE_allow_highlight)
	end

	return true, nil, true
end


function editCommandS.caretJumpRightHighlight(self)
	-- Don't leak details about the masked string.
	if self.LE.masked then
		editFuncS.caretLast(self, not self.LE_allow_highlight)
	else
		editFuncS.caretJumpRight(self, not self.LE_allow_highlight)
	end

	return true, nil, true
end


return editCommandS