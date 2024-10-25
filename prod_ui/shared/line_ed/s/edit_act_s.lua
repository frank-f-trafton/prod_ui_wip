-- To load: local lib = context:getLua("shared/lib")


--[[
Bindable wrapper functions for common LineEditor actions.

Function arguments:
1) self: The client widget
2) line_ed: The LineEditor instance (self.line_ed)

Return values:
1) true: the action was successful, and event handling should be stopped.
2) true: the display object's scrolling information should be updated.
3) true: the caret should be kept in view.
4) true: an explicit history entry should be written after the bound action completes.

The validity of returned values 2, 3 and 4 depend on 1 being true.
--]]


local context = select(1, ...)


local editActS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")


-- Step left, right
function editActS.caretLeft(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(true)
	else
		self:caretStepLeft(true)
	end

	return true, true, true, false
end


function editActS.caretRight(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(true)
	else
		self:caretStepRight(true)
	end

	return true, true, true, false
end


-- Step left, right while highlighting
function editActS.caretLeftHighlight(self, line_ed)
	self:caretStepLeft(not line_ed.allow_highlight)

	return true, true, true, false
end


function editActS.caretRightHighlight(self, line_ed)
	self:caretStepRight(not line_ed.allow_highlight)

	return true, true, true, false
end


-- Jump left, right
function editActS.caretJumpLeft(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretFirst(true)
	else
		self:caretJumpLeft(true)
	end

	return true, true, true, false
end


function editActS.caretJumpRight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretLast(true)
	else
		self:caretJumpRight(true)
	end

	return true, true, true, false
end


-- Jump left, right with highlight
function editActS.caretJumpLeftHighlight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretFirst(not line_ed.allow_highlight)
	else
		self:caretJumpLeft(not line_ed.allow_highlight)
	end

	return true, true, true, false
end


function editActS.caretJumpRightHighlight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretLast(not line_ed.allow_highlight)
	else
		self:caretJumpRight(not line_ed.allow_highlight)
	end

	return true, true, true, false
end


-- Jump to start, end of document
function editActS.caretFirst(self, line_ed)
	self:caretFirst(true)

	return true, true, true, false
end


function editActS.caretLast(self, line_ed)
	self:caretLast(true)

	return true, true, true, false
end


-- Highlight to start, end of line
function editActS.caretFirstHighlight(self, line_ed)
	self:caretFirst(not line_ed.allow_highlight)

	return true, true, true, false
end


function editActS.caretLastHighlight(self, line_ed)
	self:caretLast(not line_ed.allow_highlight)

	return true, true, true, false
end


-- Backspace, delete (or delete highlight)
function editActS.backspace(self, line_ed)
	--[[
	Both backspace and delete support partial amendments to history, so they need some special handling here.
	This logic is essentially a copy-and-paste of the code that handles amended text input.
	--]]

	if line_ed.allow_input then
		-- Need to handle history here.
		local old_byte, old_h_byte = line_ed:getCaretOffsets()
		local deleted

		if line_ed:isHighlighted() then
			deleted = self:deleteHighlightedText()
		else
			deleted = self:backspaceUChar(1)
		end

		if deleted then
			local hist = line_ed.hist

			local no_ws = string.find(deleted, "%S")
			local entry = hist:getCurrentEntry()
			local do_advance = true

			if utf8.len(deleted) == 1
			and (entry and entry.car_byte == old_byte)
			and ((line_ed.input_category == "backspacing" and no_ws) or (line_ed.input_category == "backspacing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHistS.doctorCurrentCaretOffsets(hist, old_byte, old_h_byte)
			end
			editHistS.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "backspacing" or "backspacing-ws"
		end

		return true, true, true, false
	end
end


function editActS.delete(self, line_ed)
	if line_ed.allow_input then
		-- Need to handle history here.
		local old_byte, old_h_byte = line_ed:getCaretOffsets()
		local deleted

		if line_ed:isHighlighted() then
			deleted = self:deleteHighlightedText()
		else
			deleted = self:deleteUChar(1)
		end

		if deleted then
			local hist = line_ed.hist
			local entry = hist:getCurrentEntry()

			local no_ws = string.find(deleted, "%S")
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_byte == old_byte)
			and ((line_ed.input_category == "deleting" and no_ws) or (line_ed.input_category == "deleting-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHistS.doctorCurrentCaretOffsets(hist, old_byte, old_h_byte)
			end
			editHistS.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "deleting" or "deleting-ws"
		end

		return true, true, true, false
	end
end


-- Delete highlighted text (for the pop-up menu)
function editActS.deleteHighlighted(self, line_ed)
	if line_ed.allow_input then
		if line_ed:isHighlighted() then
			self:deleteHighlightedText()

			-- Always write history if anything was deleted.
			return true, true, true, true
		end
	end
end


-- Backspace, delete by group (unhighlights first)
function editActS.deleteGroup(self, line_ed)
	if line_ed.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if line_ed.masked then
			write_hist = not not self:deleteUChar(1)
		else
			line_ed.input_category = false
			write_hist = not not self:deleteGroup()
		end

		return true, true, true, write_hist
	end
end


function editActS.deleteAll(self, line_ed)
	if line_ed.allow_input then
		local old_line = line_ed.line

		line_ed.input_category = false
		line_ed:deleteText(false, 1, #line_ed.line)
		line_ed:updateDisplayText()

		return true, true, true, (old_line ~= line_ed.line)
	end
end


function editActS.backspaceGroup(self, line_ed)
	if line_ed.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if line_ed.masked then
			write_hist = not not self:backspaceUChar(1)
		else
			write_hist = not not self:backspaceGroup()
			line_ed.input_category = false
		end

		return true, true, true, write_hist
	end
end


-- Backspace, delete from caret to start/end of line, respectively (unhighlights first)
function editActS.deleteCaretToEnd(self, line_ed)
	if line_ed.allow_input then
		self:deleteCaretToEnd()
		line_ed.input_category = false

		return true, true, true, true
	end
end


function editActS.backspaceCaretToStart(self, line_ed)
	if line_ed.allow_input then
		self:deleteCaretToStart()
		line_ed.input_category = false

		return true, true, true, true
	end
end


-- Tab key
function editActS.typeTab(self, line_ed)
	if line_ed.allow_input and line_ed.allow_tab then
		local written = self:writeText("\t", true)
		local changed = #written > 0

		return true, true, true, changed
	end
end


--- Return / Enter key
function editActS.typeLineFeed(self, line_ed)
	if line_ed.allow_input and line_ed.allow_line_feed and line_ed.allow_enter_line_feed then
		line_ed.input_category = false
		self:writeText("\n", true)

		return true, true, true, true
	end
end


-- Select all
function editActS.selectAll(self, line_ed)
	if line_ed.allow_highlight then
		self:highlightAll()
	else
		self:clearHighlight()
	end

	return true, true, false, false
end


function editActS.selectCurrentWord(self, line_ed)
	if line_ed.allow_highlight then
		self:highlightCurrentWord()
	else
		self:clearHighlight()
	end

	return true, true, false, false
end


-- Copy, cut, paste
function editActS.copy(self, line_ed)
	if line_ed.allow_copy and line_ed.allow_highlight and line_ed:isHighlighted() then
		self:copyHighlightedToClipboard() -- handles masking

		return true, true, false, false
	end
end


function editActS.cut(self, line_ed)
	if line_ed.allow_input and line_ed.allow_cut and line_ed.allow_highlight and line_ed:isHighlighted() then
		self:cutHighlightedToClipboard() -- handles masking, history, and blanking the input category.

		return true, true, true, false
	end
end


function editActS.paste(self, line_ed)
	if line_ed.allow_input and line_ed.allow_paste then
		self:pasteClipboardText() -- handles history, and blanking the input category.

		return true, true, true, false
	end
end


-- Toggle Insert / Replace mode
function editActS.toggleReplaceMode(self, line_ed)
	self:setReplaceMode(not self:getReplaceMode())

	return true, true, false, false
end


-- Undo / Redo
function editActS.undo(self, line_ed)
	self:stepHistory(-1)
	line_ed.input_category = false

	return true, true, true, false
end


function editActS.redo(self, line_ed)
	self:stepHistory(1)
	line_ed.input_category = false

	return true, true, true, false
end


return editActS
