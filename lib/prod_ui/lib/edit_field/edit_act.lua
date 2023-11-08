--[[

Bindable wrapper functions for common editField actions.

Function arguments:
1) self: The client widget.
2) core: The editField instance (self.core). (Redundant but convenient.)

Return values: -- XXX update
1) true: the display object's scrolling information should be updated.
2) true: the caret should be kept in view.
3) true: an explicit history entry should be written after the bound action completes. Note that some
bound actions may handle history directly and return false.

--]]

-- LÖVE Supplemental
local utf8 = require("utf8")


local editAct = {}


-- Step left, right
function editAct.caretLeft(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeLeft(true)

	else
		self:caretStepLeft(true)
	end

	return true, true, false
end


function editAct.caretRight(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeRight(true)

	else
		self:caretStepRight(true)
	end

	return true, true, false
end


-- Step left, right while highlighting
function editAct.caretLeftHighlight(self, core)
	self:caretStepLeft(not core.allow_highlight)

	return true, true, false
end


function editAct.caretRightHighlight(self, core)
	self:caretStepRight(not core.allow_highlight)

	return true, true, false
end


-- Jump left, right
function editAct.caretJumpLeft(self, core)
	-- Don't leak details about the masked string.
	if core.disp.masked then
		self:caretFirst(true)
	else
		self:caretJumpLeft(true)
	end

	return true, true, false
end


function editAct.caretJumpRight(self, core)
	-- Don't leak details about the masked string.
	if core.disp.masked then
		self:caretLast(true)
	else
		self:caretJumpRight(true)
	end

	return true, true, false
end


-- Jump left, right with highlight
function editAct.caretJumpLeftHighlight(self, core)
	-- Don't leak details about the masked string.
	if core.disp.masked then
		self:caretFirst(not core.allow_highlight)
	else
		self:caretJumpLeft(not core.allow_highlight)
	end

	return true, true, false
end


function editAct.caretJumpRightHighlight(self, core)
	-- Don't leak details about the masked string.
	if core.disp.masked then
		self:caretLast(not core.allow_highlight)
	else
		self:caretJumpRight(not core.allow_highlight)
	end

	return true, true, false
end


-- Move to first, end of line
function editAct.caretLineFirst(self, core)
	-- [WARN] If multi-line is enabled, this can leak information about masked line feeds.
	self:caretLineFirst(true)

	return true, true, false
end


function editAct.caretLineLast(self, core)
	-- [WARN] If multi-line is enabled, this can leak information about masked line feeds.
	self:caretLineLast(true)

	return true, true, false
end


-- Jump to start, end of document
function editAct.caretFirst(self, core)
	self:caretFirst(true)

	return true, true, false
end


function editAct.caretLast(self, core)
	self:caretLast(true)

	return true, true, false
end


-- Highlight to start, end of document
function editAct.caretFirstHighlight(self, core)
	self:caretFirst(not core.allow_highlight)

	return true, true, false
end


function editAct.caretLastHighlight(self, core)
	self:caretLast(not core.allow_highlight)

	return true, true, false
end


-- Highlight to first, end of line
function editAct.caretLineFirstHighlight(self, core)
	-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
	self:caretLineFirst(not core.allow_highlight)

	return true, true, false
end


function editAct.caretLineLastHighlight(self, core)
	-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
	self:caretLineLast(not core.allow_highlight)

	return true, true, false
end


-- Step up, down
function editAct.caretStepUp(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeLeft(not core.allow_highlight)
	end
	self:caretStepUp(true, 1)

	return true, true, false
end


function editAct.caretStepDown(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeRight(not core.allow_highlight)
	end
	self:caretStepDown(true, 1)

	return true, true, false
end


-- Highlight up, down
function editAct.caretStepUpHighlight(self, core)
	self:caretStepUp(not core.allow_highlight, 1)

	return true, true, false
end


function editAct.caretStepDownHighlight(self, core)
	self:caretStepDown(not core.allow_highlight, 1)

	return true, true, false
end


function editAct.caretStepUpCoreLine(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeLeft(not core.allow_highlight)
	end
	self:caretStepUpCoreLine(true)

	return true, true, false
end


function editAct.caretStepDownCoreLine(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeRight(not core.allow_highlight)
	end
	self:caretStepDownCoreLine(true)

	return true, true, false
end


function editAct.caretStepUpCoreLineHighlight(self, core)
	self:caretStepUpCoreLine(not core.allow_highlight)

	return true, true, false
end


function editAct.caretStepDownCoreLineHighlight(self, core)
	self:caretStepDownCoreLine(not core.allow_highlight)

	return true, true, false
end


-- Page-up, page-down
function editAct.caretPageUp(self, core)
	if core:isHighlighted() then
		self:caretHighlightEdgeLeft(not core.allow_highlight)
	end
	self:caretStepUp(true, core.page_jump_steps)

	return true, true, false
end


function editAct.caretPageDown(self, core)
	--print("core.page_jump_steps", core.page_jump_steps)
	if core:isHighlighted() then
		self:caretHighlightEdgeRight(not core.allow_highlight)
	end
	self:caretStepDown(true, core.page_jump_steps)

	return true, true, false
end


function editAct.caretPageUpHighlight(self, core)
	self:caretStepUp(not core.allow_highlight, core.page_jump_steps)

	return true, true, false
end


function editAct.caretPageDownHighlight(self, core)
	self:caretStepDown(not core.allow_highlight, core.page_jump_steps)

	return true, true, false
end


-- Backspace, delete (or delete highlight)
function editAct.backspace(self, core)

	--[[
	Both backspace and delete support partial amendments to history, so they need some special handling here.
	This logic is essentially a copy-and-paste of the code that handles amended text input.
	--]]

	if core.allow_input then
		-- Need to handle history here.
		local old_line, old_byte, old_h_line, old_h_byte = core:getCaretOffsets()
		local deleted

		if core:isHighlighted() then
			deleted = self:deleteHighlightedText()
		else
			deleted = self:backspaceUChar(1)
		end

		if deleted then
			local hist = core.hist

			local no_ws = string.find(deleted, "%S")
			local entry = hist:getCurrentEntry()
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((core.input_category == "backspacing" and no_ws) or (core.input_category == "backspacing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				hist:doctorCurrentCaretOffsets(old_line, old_byte, old_h_line, old_h_byte)
			end
			hist:writeEntry(do_advance, core.lines, core.car_line, core.car_byte, core.h_line, core.h_byte)
			core.input_category = no_ws and "backspacing" or "backspacing-ws"
		end

		return true, true, false
	end
end


function editAct.delete(self, core)

	if core.allow_input then
		-- Need to handle history here.
		local old_line, old_byte, old_h_line, old_h_byte = core:getCaretOffsets()
		local deleted

		if core:isHighlighted() then
			deleted = self:deleteHighlightedText()
		else
			deleted = self:deleteUChar(1)
		end

		if deleted then
			local hist = core.hist

			local no_ws = string.find(deleted, "%S")
			local entry = hist:getCurrentEntry()
			local do_advance = true

			if utf8.len(deleted) == 1 and deleted ~= "\n"
			and (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((core.input_category == "deleting" and no_ws) or (core.input_category == "deleting-ws"))
			then
				do_advance = false
			end

			if do_advance then
				hist:doctorCurrentCaretOffsets(old_line, old_byte, old_h_line, old_h_byte)
			end
			hist:writeEntry(do_advance, core.lines, core.car_line, core.car_byte, core.h_line, core.h_byte)
			core.input_category = no_ws and "deleting" or "deleting-ws"
		end

		return true, true, false
	end
end


-- Delete highlighted text (for the pop-up menu)
function editAct.deleteHighlighted(self, core)

	if core.allow_input then
		if core:isHighlighted() then
			self:deleteHighlightedText()

			-- Always write history if anything was deleted.
			return true, true, true
		end
	end
end


-- Backspace, delete by group (unhighlights first)
function editAct.deleteGroup(self, core)

	if core.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if core.disp.masked then
			write_hist = not not self:deleteUChar(1)
		else
			core.input_category = false
			write_hist = not not self:deleteGroup()
		end

		return true, true, write_hist
	end
end


function editAct.deleteLine(self, core)

	if core.allow_input then
		local write_hist = false

		-- [WARN] Can leak masked line feeds.
		core.input_category = false
		write_hist = not not self:deleteLine()

		return true, true, write_hist
	end
end


function editAct.backspaceGroup(self, core)

	if core.allow_input then
		local write_hist = false

		-- Don't leak masked info.
		if core.disp.masked then
			write_hist = not not self:backspaceUChar(1)

		else
			write_hist = not not self:backspaceGroup()
			core.input_category = false
		end

		return true, true, write_hist
	end
end


-- Backspace, delete from caret to start/end of line, respectively (unhighlights first)
function editAct.deleteCaretToLineEnd(self, core)
	if core.allow_input then
		-- [WARN] Can leak masked line feeds (or would, if line feeds were masked)
		self:deleteCaretToLineEnd()
		core.input_category = false

		return true, true, true
	end
end


function editAct.backspaceCaretToLineStart(self, core)
	if core.allow_input then
		-- [WARN] Will leak masked line feeds (or would, if line feeds were masked)
		self:deleteCaretToLineStart()
		core.input_category = false

		return true, true, true
	end
end


-- Add line feed (unhighlights first)
function editAct.typeLineFeed(self, core)
	if core.allow_input and core.allow_enter then
		core.input_category = false
		self:writeText("\n", true)

		return true, true, true
	end
end


-- Add tab (unhighlights first)
function editAct.typeTab(self, core)
	if core.allow_input and core.allow_tab then
		self:writeText("\t", true)

		return true, true, true
	end
end


-- (XXX Unfinished) Delete one tab (or an equivalent # of spaces) at the start of a line.
function editAct.typeUntab(self, core)
	if core.allow_input and core.allow_untab then
		-- XXX TODO

		-- return true, true, true
	end
end


-- Select all
function editAct.selectAll(self, core)
	if core.allow_highlight then
		self:highlightAll()

	else
		self:clearHighlight()
	end

	return true, false, false
end


function editAct.selectCurrentWord(self, core)
	--print("editAct.selectCurrentWord")

	if core.allow_highlight then
		self:highlightCurrentWord()

	else
		self:clearHighlight()
	end

	return true, false, false
end


function editAct.selectCurrentLine(self, core)
	--print("editAct.selectLine")

	if core.allow_highlight then
		self:highlightCurrentWrappedLine()
		--self:highlightCurrentLine()

	else
		self:clearHighlight()
	end

	return true, false, false
end


-- Copy, cut, paste
function editAct.copy(self, core)
	if core.allow_copy and core.allow_highlight and core:isHighlighted() then
		self:copyHighlightedToClipboard() -- handles masking

		return true, false, false
	end
end


function editAct.cut(self, core)
	if core.allow_input and core.allow_cut and core.allow_highlight and core:isHighlighted() then
		self:cutHighlightedToClipboard() -- handles masking, history, and blanking the input category.

		return true, true, false
	end
end


function editAct.paste(self, core)
	if core.allow_input and core.allow_paste then
		self:pasteClipboardText() -- handles history, and blanking the input category.

		return true, true, false
	end
end


-- Toggle Insert / Replace mode
function editAct.toggleReplaceMode(self, core)
	self:setReplaceMode(not self:getReplaceMode())

	return true, false, false
end


-- Undo / Redo
function editAct.undo(self, core)
	self:stepHistory(-1)
	core.input_category = false

	return true, true, false
end


function editAct.redo(self, core)
	self:stepHistory(1)
	core.input_category = false

	return true, true, false
end


return editAct

