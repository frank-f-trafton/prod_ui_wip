-- To load: local lib = context:getLua("shared/lib")


--[[
Bindable wrapper functions for common LineEditor actions.

Function arguments:
1) self: The client widget
2) line_ed: The LineEditor instance (self.line_ed)

Return values:
1) true: the action was successful, and event handling should be stopped
2) true: update the widget (recalculate document dimensions, clamp scrolling offsets, etc.)
3) true: keep the caret in view
4) true: write a history entry
   "del": write a conditional history entry for deleting text
   "bsp": write a conditional history entry for backspacing text
5) string: The deleted or backspaced text, if 4 was "del" or "bsp"

When return value 1 is not true, all other return values are invalid.

Do not make changes to the history ledger from this codepath, as the
caller might reject the updated state. Always use the return values
to signal that the history ledger should be updated.
--]]


local context = select(1, ...)


local editActS = {}


-- Step left, right
function editActS.caretLeft(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(true)
	else
		self:caretStepLeft(true)
	end

	return true, false, true, false
end


function editActS.caretRight(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(true)
	else
		self:caretStepRight(true)
	end

	return true, false, true, false
end


-- Step left, right while highlighting
function editActS.caretLeftHighlight(self, line_ed)
	self:caretStepLeft(not self.allow_highlight)

	return true, false, true, false
end


function editActS.caretRightHighlight(self, line_ed)
	self:caretStepRight(not self.allow_highlight)

	return true, false, true, false
end


-- Jump left, right
function editActS.caretJumpLeft(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretFirst(true)
	else
		self:caretJumpLeft(true)
	end

	return true, false, true, false
end


function editActS.caretJumpRight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretLast(true)
	else
		self:caretJumpRight(true)
	end

	return true, false, true, false
end


-- Jump left, right with highlight
function editActS.caretJumpLeftHighlight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretFirst(not self.allow_highlight)
	else
		self:caretJumpLeft(not self.allow_highlight)
	end

	return true, false, true, false
end


function editActS.caretJumpRightHighlight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretLast(not self.allow_highlight)
	else
		self:caretJumpRight(not self.allow_highlight)
	end

	return true, false, true, false
end


-- Jump to start, end of document
function editActS.caretFirst(self, line_ed)
	self:caretFirst(true)

	return true, false, true, false
end


function editActS.caretLast(self, line_ed)
	self:caretLast(true)

	return true, false, true, false
end


-- Highlight to start, end of line
function editActS.caretFirstHighlight(self, line_ed)
	self:caretFirst(not self.allow_highlight)

	return true, false, true, false
end


function editActS.caretLastHighlight(self, line_ed)
	self:caretLast(not self.allow_highlight)

	return true, false, true, false
end


-- Backspace, delete (or delete highlight)
function editActS.backspace(self, line_ed)
	if self.allow_input then
		local backspaced

		if line_ed:isHighlighted() then
			backspaced = self:deleteHighlightedText()
			if backspaced then
				return true, true, true, true
			end
		else
			backspaced = self:backspaceUChar(1)
			if backspaced then
				return true, true, true, "bsp", backspaced
			end
		end
	end
end


function editActS.delete(self, line_ed)
	if self.allow_input then
		local deleted

		if line_ed:isHighlighted() then
			deleted = self:deleteHighlightedText()
			if deleted then
				return true, true, true, true
			end
		else
			deleted = self:deleteUChar(1)
			if deleted then
				return true, true, true, "del", deleted
			end
		end
	end
end


-- Delete highlighted text (for the pop-up menu)
function editActS.deleteHighlighted(self, line_ed)
	if self.allow_input then
		if line_ed:isHighlighted() then
			self:deleteHighlightedText()

			-- Always write history if anything was deleted.
			return true, true, true, true
		end
	end
end


-- Backspace, delete by group (unhighlights first)
function editActS.deleteGroup(self, line_ed)
	if self.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if line_ed.masked then
			write_hist = not not self:deleteUChar(1)
		else
			self.input_category = false
			write_hist = not not self:deleteGroup()
		end

		return true, true, true, write_hist
	end
end


function editActS.deleteAll(self, line_ed)
	if self.allow_input then
		local old_line = line_ed.line

		self.input_category = false
		line_ed:deleteText(false, 1, #line_ed.line)
		line_ed:updateDisplayText()

		return true, true, true, (old_line ~= line_ed.line)
	end
end


function editActS.backspaceGroup(self, line_ed)
	if self.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if line_ed.masked then
			write_hist = not not self:backspaceUChar(1)
		else
			write_hist = not not self:backspaceGroup()
			self.input_category = false
		end

		return true, true, true, write_hist
	end
end


-- Backspace, delete from caret to start/end of line, respectively (unhighlights first)
function editActS.deleteCaretToEnd(self, line_ed)
	if self.allow_input then
		self:deleteCaretToEnd()
		self.input_category = false

		return true, true, true, true
	end
end


function editActS.backspaceCaretToStart(self, line_ed)
	if self.allow_input then
		self:deleteCaretToStart()
		self.input_category = false

		return true, true, true, true
	end
end


-- Tab key
function editActS.typeTab(self, line_ed)
	if self.allow_input and self.allow_tab then
		local written = self:writeText("\t", true)
		local changed = #written > 0

		return true, true, true, changed
	end
end


--- Return / Enter key
function editActS.typeLineFeed(self, line_ed)
	if self.allow_input and self.allow_line_feed and self.allow_enter_line_feed then
		self.input_category = false
		self:writeText("\n", true)

		return true, true, true, true
	end
end


-- Select all
function editActS.selectAll(self, line_ed)
	if self.allow_highlight then
		self:highlightAll()
	else
		self:clearHighlight()
	end

	return true, false, false, false
end


function editActS.selectCurrentWord(self, line_ed)
	if self.allow_highlight then
		self:highlightCurrentWord()
	else
		self:clearHighlight()
	end

	return true, false, false, false
end


-- Copy, cut, paste
function editActS.copy(self, line_ed)
	if self.allow_copy and self.allow_highlight and line_ed:isHighlighted() then
		self:copyHighlightedToClipboard() -- handles masking

		return true, false, false, false
	end
end


function editActS.cut(self, line_ed)
	if self.allow_input and self.allow_cut and self.allow_highlight and line_ed:isHighlighted() then
		if self:cutHighlightedToClipboard() then -- handles masking
			self.input_category = false

			return true, true, true, true
		end
	end
end


function editActS.paste(self, line_ed)
	if self.allow_input and self.allow_paste and self:pasteClipboardText() then
		self.input_category = false

		return true, true, true, true
	end
end


-- Toggle Insert / Replace mode
function editActS.toggleReplaceMode(self, line_ed)
	self:setReplaceMode(not self:getReplaceMode())

	return true, false, false, false
end


-- Undo / Redo
function editActS.undo(self, line_ed)
	if line_ed.hist.enabled then
		if self:stepHistory(-1) then
			self.input_category = false

			return true, true, true, false
		end
	end
end


function editActS.redo(self, line_ed)
	if line_ed.hist.enabled then
		if self:stepHistory(1) then
			self.input_category = false

			return true, true, true, false
		end
	end
end


return editActS
