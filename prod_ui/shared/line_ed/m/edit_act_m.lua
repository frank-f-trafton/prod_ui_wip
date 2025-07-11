-- To load: local lib = context:getLua("shared/lib")


--[[
Bindable wrapper functions for common LineEditor actions.

Function arguments:
1) self: The client widget.
2) line_ed: The LineEditor instance (self.line_ed). (Redundant but convenient.)

Return values: -- XXX update
1) true: the action was successful, and event handling should be stopped.
2) true: the display object's scrolling information should be updated.
3) true: the caret should be kept in view.
4) true: an explicit history entry should be written after the bound action completes. Note that some
bound actions may handle history directly and return false.

Return values 2, 3 and 4 depend on 1 being true.
--]]


local context = select(1, ...)


local editActM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")


-- Step left, right
function editActM.caretLeft(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(true)
	else
		self:caretStepLeft(true)
	end

	return true, true, true, false
end


function editActM.caretRight(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(true)
	else
		self:caretStepRight(true)
	end

	return true, true, true, false
end


-- Step left, right while highlighting
function editActM.caretLeftHighlight(self, line_ed)
	self:caretStepLeft(not self.allow_highlight)

	return true, true, true, false
end


function editActM.caretRightHighlight(self, line_ed)
	self:caretStepRight(not self.allow_highlight)

	return true, true, true, false
end


-- Jump left, right
function editActM.caretJumpLeft(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretFirst(true)
	else
		self:caretJumpLeft(true)
	end

	return true, true, true, false
end


function editActM.caretJumpRight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretLast(true)
	else
		self:caretJumpRight(true)
	end

	return true, true, true, false
end


-- Jump left, right with highlight
function editActM.caretJumpLeftHighlight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretFirst(not self.allow_highlight)
	else
		self:caretJumpLeft(not self.allow_highlight)
	end

	return true, true, true, false
end


function editActM.caretJumpRightHighlight(self, line_ed)
	-- Don't leak details about the masked string.
	if line_ed.masked then
		self:caretLast(not self.allow_highlight)
	else
		self:caretJumpRight(not self.allow_highlight)
	end

	return true, true, true, false
end


-- Move to first, end of line
function editActM.caretLineFirst(self, line_ed)
	-- [WARN] If multi-line is enabled, this can leak information about masked line feeds.
	self:caretLineFirst(true)

	return true, true, true, false
end


function editActM.caretLineLast(self, line_ed)
	-- [WARN] If multi-line is enabled, this can leak information about masked line feeds.
	self:caretLineLast(true)

	return true, true, true, false
end


-- Jump to start, end of document
function editActM.caretFirst(self, line_ed)
	self:caretFirst(true)

	return true, true, true, false
end


function editActM.caretLast(self, line_ed)
	self:caretLast(true)

	return true, true, true, false
end


-- Highlight to start, end of document
function editActM.caretFirstHighlight(self, line_ed)
	self:caretFirst(not self.allow_highlight)

	return true, true, true, false
end


function editActM.caretLastHighlight(self, line_ed)
	self:caretLast(not self.allow_highlight)

	return true, true, true, false
end


-- Highlight to first, end of line
function editActM.caretLineFirstHighlight(self, line_ed)
	-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
	self:caretLineFirst(not self.allow_highlight)

	return true, true, true, false
end


function editActM.caretLineLastHighlight(self, line_ed)
	-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
	self:caretLineLast(not self.allow_highlight)

	return true, true, true, false
end


-- Step up, down
function editActM.caretStepUp(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(not self.allow_highlight)
	end
	self:caretStepUp(true, 1)

	return true, true, true, false
end


function editActM.caretStepDown(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(not self.allow_highlight)
	end
	self:caretStepDown(true, 1)

	return true, true, true, false
end


-- Highlight up, down
function editActM.caretStepUpHighlight(self, line_ed)
	self:caretStepUp(not self.allow_highlight, 1)

	return true, true, true, false
end


function editActM.caretStepDownHighlight(self, line_ed)
	self:caretStepDown(not self.allow_highlight, 1)

	return true, true, true, false
end


function editActM.caretStepUpCoreLine(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(not self.allow_highlight)
	end
	self:caretStepUpCoreLine(true)

	return true, true, true, false
end


function editActM.caretStepDownCoreLine(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(not self.allow_highlight)
	end
	self:caretStepDownCoreLine(true)

	return true, true, true, false
end


function editActM.caretStepUpCoreLineHighlight(self, line_ed)
	self:caretStepUpCoreLine(not self.allow_highlight)

	return true, true, true, false
end


function editActM.caretStepDownCoreLineHighlight(self, line_ed)
	self:caretStepDownCoreLine(not self.allow_highlight)

	return true, true, true, false
end


-- Page-up, page-down
function editActM.caretPageUp(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(not self.allow_highlight)
	end
	self:caretStepUp(true, self.page_jump_steps)

	return true, true, true, false
end


function editActM.caretPageDown(self, line_ed)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(not self.allow_highlight)
	end
	self:caretStepDown(true, self.page_jump_steps)

	return true, true, true, false
end


function editActM.caretPageUpHighlight(self, line_ed)
	self:caretStepUp(not self.allow_highlight, self.page_jump_steps)

	return true, true, true, false
end


function editActM.caretPageDownHighlight(self, line_ed)
	self:caretStepDown(not self.allow_highlight, self.page_jump_steps)

	return true, true, true, false
end


-- Shift selected lines up, down
function editActM.shiftLinesUp(self, line_ed)
	local r1, r2 = line_ed:getSelectedLinesRange(true)
	local lines = line_ed.lines
	local displaced_line = lines[r1 - 1]

	if displaced_line then
		for i = r1 - 1, r2 - 1 do
			lines[i] = lines[i + 1]
		end

		lines[r2] = displaced_line

		line_ed.car_line = math.max(1, r1 - 1)
		line_ed.car_byte = 1
		line_ed.h_line = math.max(1, r2 - 1)
		line_ed.h_byte = #line_ed.lines[line_ed.h_line] + 1
		line_ed:displaySyncAll(r1 - 1)

		return true, true, true, true
	end
end


function editActM.shiftLinesDown(self, line_ed)
	local r1, r2, b1, b2 = line_ed:getSelectedLinesRange(true)
	local lines = line_ed.lines
	local displaced_line = lines[r2 + 1]

	if displaced_line then
		for i = r2 + 1, r1 + 1, -1 do
			lines[i] = lines[i - 1]
		end

		lines[r1] = displaced_line

		line_ed.car_line = math.min(#lines, r1 + 1)
		line_ed.car_byte = 1
		line_ed.h_line = math.min(#lines, r2 + 1)
		line_ed.h_byte = #line_ed.lines[line_ed.h_line] + 1
		line_ed:displaySyncAll(r1)

		return true, true, true, true
	end
end


-- Backspace, delete (or delete highlight)
function editActM.backspace(self, line_ed)
	--[[
	Both backspace and delete support partial amendments to history, so they need some special handling here.
	This logic is essentially a copy-and-paste of the code that handles amended text input.
	--]]

	if self.allow_input then
		-- Need to handle history here.
		local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()
		local deleted

		if line_ed:isHighlighted() then
			deleted = self:deleteHighlightedText()
		else
			deleted = self:backspaceUChar(1)
		end

		if deleted then
			local hist = line_ed.hist

			local no_ws = string.find(deleted, "%S")
			local entry = hist:getEntry()
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((self.input_category == "backspacing" and no_ws) or (self.input_category == "backspacing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHistM.doctorCurrentCaretOffsets(hist, old_line, old_byte, old_h_line, old_h_byte)
			end
			editHistM.writeEntry(line_ed, do_advance)
			self.input_category = no_ws and "backspacing" or "backspacing-ws"
		end

		return true, true, true, false
	end
end


function editActM.delete(self, line_ed)
	if self.allow_input then
		-- Need to handle history here.
		local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()
		local deleted

		if line_ed:isHighlighted() then
			deleted = self:deleteHighlightedText()
		else
			deleted = self:deleteUChar(1)
		end

		if deleted then
			local hist = line_ed.hist

			local no_ws = string.find(deleted, "%S")
			local entry = hist:getEntry()
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((self.input_category == "deleting" and no_ws) or (self.input_category == "deleting-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHistM.doctorCurrentCaretOffsets(hist, old_line, old_byte, old_h_line, old_h_byte)
			end
			editHistM.writeEntry(line_ed, do_advance)
			self.input_category = no_ws and "deleting" or "deleting-ws"
		end

		return true, true, true, false
	end
end


-- Delete highlighted text (for the pop-up menu)
function editActM.deleteHighlighted(self, line_ed)
	if self.allow_input then
		if line_ed:isHighlighted() then
			self:deleteHighlightedText()

			-- Always write history if anything was deleted.
			return true, true, true, true
		end
	end
end


-- Backspace, delete by group (unhighlights first)
function editActM.deleteGroup(self, line_ed)
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


function editActM.deleteLine(self, line_ed)
	if self.allow_input then
		local write_hist = false

		-- [WARN] Can leak masked line feeds.
		self.input_category = false
		write_hist = not not self:deleteLine()

		return true, true, true, write_hist
	end
end


function editActM.backspaceGroup(self, line_ed)
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
function editActM.deleteCaretToLineEnd(self, line_ed)
	if self.allow_input then
		-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
		self:deleteCaretToLineEnd()
		self.input_category = false

		return true, true, true, true
	end
end


function editActM.backspaceCaretToLineStart(self, line_ed)
	if self.allow_input then
		-- [WARN] Will leak masked line feeds (or would, if line feeds were masked)
		self:deleteCaretToLineStart()
		self.input_category = false

		return true, true, true, true
	end
end


-- Add line feed (unhighlights first)
function editActM.typeLineFeedWithAutoIndent(self, line_ed)
	if self.allow_input and self.allow_line_feed then
		self.input_category = false

		local new_str = "\n"

		if self.auto_indent then
			local top_selected_line = math.min(line_ed.car_line, line_ed.h_line)
			local leading_white_space = string.match(line_ed.lines[top_selected_line], "^%s+")
			if leading_white_space then
				new_str = new_str .. leading_white_space
			end
		end

		self:writeText(new_str, true)

		return true, true, true, true
	end
end


function editActM.typeLineFeed(self, line_ed)
	if self.allow_input and self.allow_line_feed then
		self.input_category = false

		self:writeText("\n", true)

		return true, true, true, true
	end
end


-- Tab key
function editActM.typeTab(self, line_ed)
	if self.allow_input and self.allow_tab then
		local changed = false

		-- Caret and highlight are on the same line: write a literal tab.
		-- (Unhighlights first)
		if line_ed.car_line == line_ed.h_line then
			local written = self:writeText("\t", true)

			if #written > 0 then
				changed = true
			end
		-- Caret and highlight are on different lines: indent the range of lines.
		else
			local r1, r2 = line_ed:getSelectedLinesRange(true)

			-- Only perform the indent if the total number of added tabs will not take us beyond
			-- the max code points setting.
			local tab_count = 1 + (r2 - r1)
			if line_ed.u_chars + tab_count <= self.u_chars_max then
				for i = r1, r2 do
					local line_changed = line_ed:indentLine(i)

					if line_changed then
						changed = true
					end
				end
			end
		end
		line_ed:updateDispHighlightRange()

		return true, true, true, changed
	end
end


-- Shift + Tab
function editActM.typeUntab(self, line_ed)
	if self.allow_input and self.allow_untab then
		local changed = false
		local r1, r2 = line_ed:getSelectedLinesRange(true)

		local tab_count = 1 + (r2 - r1)

		for i = r1, r2 do
			local line_changed = line_ed:unindentLine(i)

			if line_changed then
				changed = true
			end
		end

		line_ed:updateDispHighlightRange()
		return true, true, true, changed
	end
end


-- Select all
function editActM.selectAll(self, line_ed)
	if self.allow_highlight then
		self:highlightAll()
	else
		self:clearHighlight()
	end

	return true, true, false, false
end


function editActM.selectCurrentWord(self, line_ed)
	--print("editActM.selectCurrentWord")
	if self.allow_highlight then
		self:highlightCurrentWord()
	else
		self:clearHighlight()
	end

	return true, true, false, false
end


function editActM.selectCurrentLine(self, line_ed)
	--print("editActM.selectLine")
	if self.allow_highlight then
		self:highlightCurrentWrappedLine()
		--self:highlightCurrentLine()
	else
		self:clearHighlight()
	end

	return true, true, false, false
end


-- Copy, cut, paste
function editActM.copy(self, line_ed)
	if self.allow_copy and self.allow_highlight and line_ed:isHighlighted() then
		self:copyHighlightedToClipboard() -- handles masking

		return true, true, false, false
	end
end


function editActM.cut(self, line_ed)
	if self.allow_input and self.allow_cut and self.allow_highlight and line_ed:isHighlighted() then
		self:cutHighlightedToClipboard() -- handles masking, history, and blanking the input category.

		return true, true, true, false
	end
end


function editActM.paste(self, line_ed)
	if self.allow_input and self.allow_paste then
		self:pasteClipboardText() -- handles history, and blanking the input category.

		return true, true, true, false
	end
end


-- Toggle Insert / Replace mode
function editActM.toggleReplaceMode(self, line_ed)
	self:setReplaceMode(not self:getReplaceMode())

	return true, true, false, false
end


-- Undo / Redo
function editActM.undo(self, line_ed)
	self:stepHistory(-1)
	self.input_category = false

	return true, true, true, false
end


function editActM.redo(self, line_ed)
	self:stepHistory(1)
	self.input_category = false

	return true, true, true, false
end


return editActM
