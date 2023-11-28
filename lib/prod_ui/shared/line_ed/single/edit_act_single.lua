-- To load: local lib = context:getLua("shared/lib")


--[[

Bindable wrapper functions for common LineEditor actions.

Function arguments:
1) self: The client widget.
2) line_ed: The LineEditor instance (self.line_ed). (Redundant but convenient.)

Return values: -- XXX update
1) true: the display object's scrolling information should be updated.
2) true: the caret should be kept in view.
3) true: an explicit history entry should be written after the bound action completes. Note that some
bound actions may handle history directly and return false.

--]]


local context = select(1, ...)


local editActSingle = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local editHist = context:getLua("shared/line_ed/single/edit_hist_single")



-- Step left, right
function editActSingle.caretLeft(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(true)

	else
		self:caretStepLeft(true)
	end

	return true, true, false
end


function editActSingle.caretRight(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(true)

	else
		self:caretStepRight(true)
	end

	return true, true, false
end


--[=====[

-- Step left, right while highlighting
function editAct.caretLeftHighlight(self, line_ed)

	self:caretStepLeft(not line_ed.allow_highlight)

	return true, true, false
end


function editAct.caretRightHighlight(self, line_ed)

	self:caretStepRight(not line_ed.allow_highlight)

	return true, true, false
end


-- Jump left, right
function editAct.caretJumpLeft(self, line_ed)

	-- Don't leak details about the masked string.
	if line_ed.disp.masked then
		self:caretFirst(true)

	else
		self:caretJumpLeft(true)
	end

	return true, true, false
end


function editAct.caretJumpRight(self, line_ed)

	-- Don't leak details about the masked string.
	if line_ed.disp.masked then
		self:caretLast(true)

	else
		self:caretJumpRight(true)
	end

	return true, true, false
end


-- Jump left, right with highlight
function editAct.caretJumpLeftHighlight(self, line_ed)

	-- Don't leak details about the masked string.
	if line_ed.disp.masked then
		self:caretFirst(not line_ed.allow_highlight)

	else
		self:caretJumpLeft(not line_ed.allow_highlight)
	end

	return true, true, false
end


function editAct.caretJumpRightHighlight(self, line_ed)

	-- Don't leak details about the masked string.
	if line_ed.disp.masked then
		self:caretLast(not line_ed.allow_highlight)

	else
		self:caretJumpRight(not line_ed.allow_highlight)
	end

	return true, true, false
end


-- Move to first, end of line
function editAct.caretLineFirst(self, line_ed)

	-- [WARN] If multi-line is enabled, this can leak information about masked line feeds.
	self:caretLineFirst(true)

	return true, true, false
end


function editAct.caretLineLast(self, line_ed)

	-- [WARN] If multi-line is enabled, this can leak information about masked line feeds.
	self:caretLineLast(true)

	return true, true, false
end


-- Jump to start, end of document
function editAct.caretFirst(self, line_ed)

	self:caretFirst(true)

	return true, true, false
end


function editAct.caretLast(self, line_ed)

	self:caretLast(true)

	return true, true, false
end


-- Highlight to start, end of document
function editAct.caretFirstHighlight(self, line_ed)

	self:caretFirst(not line_ed.allow_highlight)

	return true, true, false
end


function editAct.caretLastHighlight(self, line_ed)

	self:caretLast(not line_ed.allow_highlight)

	return true, true, false
end


-- Highlight to first, end of line
function editAct.caretLineFirstHighlight(self, line_ed)

	-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
	self:caretLineFirst(not line_ed.allow_highlight)

	return true, true, false
end


function editAct.caretLineLastHighlight(self, line_ed)

	-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
	self:caretLineLast(not line_ed.allow_highlight)

	return true, true, false
end


-- Step up, down
function editAct.caretStepUp(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(not line_ed.allow_highlight)
	end
	self:caretStepUp(true, 1)

	return true, true, false
end


function editAct.caretStepDown(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(not line_ed.allow_highlight)
	end
	self:caretStepDown(true, 1)

	return true, true, false
end


-- Highlight up, down
function editAct.caretStepUpHighlight(self, line_ed)

	self:caretStepUp(not line_ed.allow_highlight, 1)

	return true, true, false
end


function editAct.caretStepDownHighlight(self, line_ed)

	self:caretStepDown(not line_ed.allow_highlight, 1)

	return true, true, false
end


function editAct.caretStepUpCoreLine(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(not line_ed.allow_highlight)
	end
	self:caretStepUpCoreLine(true)

	return true, true, false
end


function editAct.caretStepDownCoreLine(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(not line_ed.allow_highlight)
	end
	self:caretStepDownCoreLine(true)

	return true, true, false
end


function editAct.caretStepUpCoreLineHighlight(self, line_ed)

	self:caretStepUpCoreLine(not line_ed.allow_highlight)

	return true, true, false
end


function editAct.caretStepDownCoreLineHighlight(self, line_ed)

	self:caretStepDownCoreLine(not line_ed.allow_highlight)

	return true, true, false
end


-- Page-up, page-down
function editAct.caretPageUp(self, line_ed)

	if line_ed:isHighlighted() then
		self:caretHighlightEdgeLeft(not line_ed.allow_highlight)
	end
	self:caretStepUp(true, line_ed.page_jump_steps)

	return true, true, false
end


function editAct.caretPageDown(self, line_ed)

	--print("line_ed.page_jump_steps", line_ed.page_jump_steps)
	if line_ed:isHighlighted() then
		self:caretHighlightEdgeRight(not line_ed.allow_highlight)
	end
	self:caretStepDown(true, line_ed.page_jump_steps)

	return true, true, false
end


function editAct.caretPageUpHighlight(self, line_ed)

	self:caretStepUp(not line_ed.allow_highlight, line_ed.page_jump_steps)

	return true, true, false
end


function editAct.caretPageDownHighlight(self, line_ed)

	self:caretStepDown(not line_ed.allow_highlight, line_ed.page_jump_steps)

	return true, true, false
end


-- Shift selected lines up, down
function editAct.shiftLinesUp(self, line_ed)

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

		return true, true, true
	end
end


function editAct.shiftLinesDown(self, line_ed)

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

		return true, true, true
	end
end


-- Backspace, delete (or delete highlight)
function editAct.backspace(self, line_ed)

	--[[
	Both backspace and delete support partial amendments to history, so they need some special handling here.
	This logic is essentially a copy-and-paste of the code that handles amended text input.
	--]]

	if line_ed.allow_input then
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
			local entry = hist:getCurrentEntry()
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((line_ed.input_category == "backspacing" and no_ws) or (line_ed.input_category == "backspacing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHist.doctorCurrentCaretOffsets(hist, old_line, old_byte, old_h_line, old_h_byte)
			end
			editHist.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "backspacing" or "backspacing-ws"
		end

		return true, true, false
	end
end


function editAct.delete(self, line_ed)

	if line_ed.allow_input then
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
			local entry = hist:getCurrentEntry()
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((line_ed.input_category == "deleting" and no_ws) or (line_ed.input_category == "deleting-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHist.doctorCurrentCaretOffsets(hist, old_line, old_byte, old_h_line, old_h_byte)
			end
			editHist.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "deleting" or "deleting-ws"
		end

		return true, true, false
	end
end


-- Delete highlighted text (for the pop-up menu)
function editAct.deleteHighlighted(self, line_ed)

	if line_ed.allow_input then
		if line_ed:isHighlighted() then
			self:deleteHighlightedText()

			-- Always write history if anything was deleted.
			return true, true, true
		end
	end
end


-- Backspace, delete by group (unhighlights first)
function editAct.deleteGroup(self, line_ed)

	if line_ed.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if line_ed.disp.masked then
			write_hist = not not self:deleteUChar(1)

		else
			line_ed.input_category = false
			write_hist = not not self:deleteGroup()
		end

		return true, true, write_hist
	end
end


function editAct.deleteLine(self, line_ed)

	if line_ed.allow_input then
		local write_hist = false

		-- [WARN] Can leak masked line feeds.
		line_ed.input_category = false
		write_hist = not not self:deleteLine()

		return true, true, write_hist
	end
end


function editAct.backspaceGroup(self, line_ed)

	if line_ed.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if line_ed.disp.masked then
			write_hist = not not self:backspaceUChar(1)

		else
			write_hist = not not self:backspaceGroup()
			line_ed.input_category = false
		end

		return true, true, write_hist
	end
end


-- Backspace, delete from caret to start/end of line, respectively (unhighlights first)
function editAct.deleteCaretToLineEnd(self, line_ed)

	if line_ed.allow_input then
		-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
		self:deleteCaretToLineEnd()
		line_ed.input_category = false

		return true, true, true
	end
end


function editAct.backspaceCaretToLineStart(self, line_ed)

	if line_ed.allow_input then
		-- [WARN] Will leak masked line feeds (or would, if line feeds were masked)
		self:deleteCaretToLineStart()
		line_ed.input_category = false

		return true, true, true
	end
end


-- Add line feed (unhighlights first)
function editAct.typeLineFeedWithAutoIndent(self, line_ed)

	if line_ed.allow_input and line_ed.allow_enter then
		line_ed.input_category = false

		local new_str = "\n"

		if line_ed.auto_indent then
			local top_selected_line = math.min(line_ed.car_line, line_ed.h_line)
			local leading_white_space = string.match(line_ed.lines[top_selected_line], "^%s+")
			if leading_white_space then
				new_str = new_str .. leading_white_space
			end
		end

		self:writeText(new_str, true)

		return true, true, true
	end
end


function editAct.typeLineFeed(self, line_ed)

	if line_ed.allow_input and line_ed.allow_enter then
		line_ed.input_category = false

		self:writeText("\n", true)

		return true, true, true
	end
end


-- Tab key
function editAct.typeTab(self, line_ed)

	if line_ed.allow_input and line_ed.allow_tab then
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
			if line_ed.u_chars + tab_count <= line_ed.u_chars_max then
				for i = r1, r2 do
					local line_changed = line_ed:indentLine(i)

					if line_changed then
						changed = true
					end
				end
			end
		end
		line_ed:updateDispHighlightRange()

		return true, true, changed
	end
end


-- Shift + Tab
function editAct.typeUntab(self, line_ed)

	if line_ed.allow_input and line_ed.allow_untab then
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
		return true, true, changed
	end
end


-- Select all
function editAct.selectAll(self, line_ed)

	if line_ed.allow_highlight then
		self:highlightAll()

	else
		self:clearHighlight()
	end

	return true, false, false
end


function editAct.selectCurrentWord(self, line_ed)

	--print("editAct.selectCurrentWord")
	if line_ed.allow_highlight then
		self:highlightCurrentWord()

	else
		self:clearHighlight()
	end

	return true, false, false
end


function editAct.selectCurrentLine(self, line_ed)

	--print("editAct.selectLine")
	if line_ed.allow_highlight then
		self:highlightCurrentWrappedLine()
		--self:highlightCurrentLine()

	else
		self:clearHighlight()
	end

	return true, false, false
end


-- Copy, cut, paste
function editAct.copy(self, line_ed)

	if line_ed.allow_copy and line_ed.allow_highlight and line_ed:isHighlighted() then
		self:copyHighlightedToClipboard() -- handles masking

		return true, false, false
	end
end


function editAct.cut(self, line_ed)

	if line_ed.allow_input and line_ed.allow_cut and line_ed.allow_highlight and line_ed:isHighlighted() then
		self:cutHighlightedToClipboard() -- handles masking, history, and blanking the input category.

		return true, true, false
	end
end


function editAct.paste(self, line_ed)

	if line_ed.allow_input and line_ed.allow_paste then
		self:pasteClipboardText() -- handles history, and blanking the input category.

		return true, true, false
	end
end


-- Toggle Insert / Replace mode
function editAct.toggleReplaceMode(self, line_ed)

	self:setReplaceMode(not self:getReplaceMode())

	return true, false, false
end


-- Undo / Redo
function editAct.undo(self, line_ed)

	self:stepHistory(-1)
	line_ed.input_category = false

	return true, true, false
end


function editAct.redo(self, line_ed)

	self:stepHistory(1)
	line_ed.input_category = false

	return true, true, false
end


--]=====]


return editActSingle
