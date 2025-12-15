-- LineEditor (multi) plug-in methods for client widgets.
-- M == multi-line only.


local context = select(1, ...)


local editMethodsM = {}
local client = editMethodsM


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidM = context:getLua("shared/line_ed/m/edit_wid_m")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local widShared = context:getLua("core/wid_shared")


function client:writeText(text, suppress_replace)
	uiAssert.type(1, text, "string")

	editWidM.wrapAction(self, editCommandM.writeText, text, suppress_replace)

	return self
end


function client:replaceText(text)
	uiAssert.type(1, text, "string")

	editWidM.wrapAction(self, editCommandM.replaceText, text)

	return self
end


function client:setText(text)
	uiAssert.type(1, text, "string")

	editWidM.wrapAction(self, editCommandM.setText, text)

	return self
end


function client:getText(l1, l2)
	uiAssert.typeEval(1, l1, "number")
	uiAssert.typeEval(2, l2, "number")

	return editFuncM.getText(self, l1, l2)
end


function client:getHighlightedText()
	local LE = self.LE

	if LE:isHighlighted() then
		local lines = LE.lines

		local l1, b1, l2, b2 = LE:getCaretOffsetsInOrder()
		local text = lines:copy(l1, b1, l2, b2 - 1)
		return table.concat(text, "\n")
	end
end


function client:cut()
	editWidM.wrapAction(self, editCommandM.cut)

	return self
end


function client:copy()
	editWidM.wrapAction(self, editCommandM.copy)

	return self
end


function client:paste()
	editWidM.wrapAction(self, editCommandM.paste)

	return self
end


function client:getLineCount() -- M
	return #self.LE.lines
end


function client:caretStepLeft(clear_highlight)
	editWidM.wrapAction(self, editCommandM.caretStepLeft, clear_highlight)

	return self
end


function client:caretStepRight(clear_highlight)
	editWidM.wrapAction(self, editCommandM.caretStepRight, clear_highlight)

	return self
end


function client:caretJumpLeft(clear_highlight)
	editWidM.wrapAction(self, editCommandM.caretJumpLeft, clear_highlight)

	return self
end


function client:caretJumpRight(clear_highlight)
	editWidM.wrapAction(self, editCommandM.caretJumpRight, clear_highlight)

	return self
end


function client:caretFirst(clear_highlight)
	editWidM.wrapAction(self, editCommandM.caretFirst, clear_highlight)

	return self
end


function client:caretLast(clear_highlight)
	editWidM.wrapAction(self, editCommandM.caretLast, clear_highlight)

	return self
end


function client:caretFullLineFirst(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretFullLineFirst, clear_highlight)

	return self
end


function client:caretFullLineLast(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretFullLineLast, clear_highlight)

	return self
end


function client:caretSubLineFirst(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretSubLineFirst, clear_highlight)

	return self
end


function client:caretSubLineLast(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretSubLineLast, clear_highlight)

	return self
end


function client:caretLineFirst(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretLineFirst, clear_highlight)

	return self
end


function client:caretLineLast(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretLineLast, clear_highlight)

	return self
end


function client:caretToHighlightEdgeLeft()
	editWidM.wrapAction(self, editCommandM.caretToHighlightEdgeLeft)

	return self
end


function client:caretToHighlightEdgeRight()
	editWidM.wrapAction(self, editCommandM.caretToHighlightEdgeRight)

	return self
end


function client:caretStepUp(clear_highlight, n_steps) -- M
	editWidM.wrapAction(self, editCommandM.caretStepUp, clear_highlight, n_steps)

	return self
end


function client:caretStepDown(clear_highlight, n_steps) -- M
	editWidM.wrapAction(self, editCommandM.caretStepDown, clear_highlight, n_steps)

	return self
end


function client:caretStepUpCoreLine(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretStepUpCoreLine, clear_highlight)

	return self
end


function client:caretStepDownCoreLine(clear_highlight) -- M
	editWidM.wrapAction(self, editCommandM.caretStepDownCoreLine, clear_highlight)

	return self
end


function client:isHighlighted()
	return self.LE:isHighlighted()
end


function client:highlightAll()
	editWidM.wrapAction(self, editCommandM.highlightAll)

	return self
end


function client:highlightCurrentLine() -- M
	editWidM.wrapAction(self, editCommandM.highlightCurrentLine)

	return self
end


function client:highlightCurrentWrappedLine() -- M
	editWidM.wrapAction(self, editCommandM.highlightCurrentWrappedLine)

	return self
end


function client:highlightCurrentWord()
	editWidM.wrapAction(self, editCommandM.highlightCurrentWord)

	return self
end


function client:clearHighlight()
	editWidM.wrapAction(self, editCommandM.clearHighlight)

	return self
end


function client:deleteHighlighted()
	editWidM.wrapAction(self, editCommandM.deleteHighlighted)

	return self
end


function client:deleteCaretToLineStart() -- M
	editWidM.wrapAction(self, editCommandM.deleteCaretToLineStart)

	return self
end


function client:deleteCaretToLineEnd() -- M
	editWidM.wrapAction(self, editCommandM.deleteCaretToLineEnd)

	return self
end


function client:deleteLine() -- M
	editWidM.wrapAction(self, editCommandM.deleteLine)

	return self
end


function client:backspace()
	editWidM.wrapAction(self, editCommandM.backspace)

	return self
end


function client:deleteAll()
	editWidM.wrapAction(self, editCommandM.deleteAll)

	return self
end


function client:backspaceGroup()
	editWidM.wrapAction(self, editCommandM.backspaceGroup)

	return self
end


function client:deleteGroup()
	editWidM.wrapAction(self, editCommandM.deleteGroup)

	return self
end


--- Delete characters on and to the right of the caret.
-- @param n_u_chars The number of code points to delete.
-- @return The deleted characters in string form, or nil if nothing was deleted.
function client:deleteUChar(n_u_chars)
	uiAssert.type(1, n_u_chars, "number")

	editWidM.wrapAction(self, editCommandM.deleteUChar, n_u_chars)

	return self
end


function client:undo()
	editWidM.wrapAction(self, editCommandM.undo)

	return self
end


function client:redo()
	editWidM.wrapAction(self, editCommandM.redo)

	return self
end


function client:resetInputCategory()
	-- Used to force a new history entry.
	self.LE_input_category = false

	return self
end


function client:scrollGetCaretInBounds(immediate)
	editWidM.scrollGetCaretInBounds(self, immediate)

	return self
end


function client:setAllowReplaceMode(enabled)
	editWidM.wrapAction(self, editCommandM.setAllowReplaceMode, enabled)

	return self
end


function client:getAllowReplaceMode()
	return self.LE_allow_replace
end


function client:setReplaceMode(enabled)
	editWidM.wrapAction(self, editCommandM.setReplaceMode, enabled)

	return self
end


function client:getReplaceMode()
	return self.LE_replace_mode
end


function client:setWrapMode(enabled) -- M
	editWidM.wrapAction(self, editCommandM.setWrapMode, enabled)

	return self
end


function client:getWrapMode() -- M
	return self.LE.wrap_mode
end


function client:setTextAlignment(align)
	uiAssert.namedMap(1, align, editWid._nm_align)

	editWidM.wrapAction(self, editCommandM.setTextAlignment, align)

	return self
end


function client:getTextAlignment()
	return self.LE.align
end


function client:setColorization(enabled)
	editWidM.wrapAction(self, editCommandM.setColorization, enabled)

	return self
end


function client:getColorization()
	return self.LE.generate_colored_text
end


function client:setAllowHighlight(enabled)
	editWidM.wrapAction(self, editCommandM.setAllowHighlight, enabled)

	return self
end


function client:getAllowHighlight(enabled)
	return self.LE_allow_highlight
end


function client:setAllowTab(enabled) -- M
	self.LE_allow_tab = not not enabled

	return self
end


function client:getAllowTab() -- M
	return self.LE_allow_tab
end


function client:setAllowUntab(enabled) -- M
	self.LE_allow_untab = not not enabled

	return self
end


function client:getAllowUntab() -- M
	return self.LE_allow_untab
end


function client:setTabsToSpaces(enabled) -- M
	self.LE_tabs_to_spaces = not not enabled

	return self
end


function client:getTabsToSpaces() -- M
	return self.LE_tabs_to_spaces
end


function client:setAutoIndent(enabled) -- M
	self.LE_auto_indent = not not enabled

	return self
end


function client:getAutoIndent() -- M
	return self.LE_auto_indent
end


function client:setAllowInput(enabled)
	editWidM.wrapAction(self, editCommandM.setAllowInput, enabled)

	return self
end


function client:getAllowInput()
	return self.LE_allow_input
end


function client:setAllowCut(enabled)
	self.LE_allow_cut = not not enabled

	return self
end


function client:getAllowCut()
	return self.LE_allow_cut
end


function client:setAllowCopy(enabled)
	self.LE_allow_copy = not not enabled

	return self
end


function client:getAllowCopy()
	return self.LE_allow_copy
end


function client:setAllowPaste(enabled)
	self.LE_allow_paste = not not enabled

	return self
end


function client:getAllowPaste()
	return self.LE_allow_paste
end


function client:setAllowLineFeed(enabled)
	self.LE_allow_line_feed = not not enabled

	return self
end


function client:getAllowLineFeed()
	return self.LE_allow_line_feed
end


-- @param rule The rule to use.
-- * "trim": Cut the string at the first bad byte.
-- * "replacement_char": Replace every unrecognized byte with the Unicode replacement code point.
-- * false/nil: return an empty string on bad unput.
function client:setBadInputRule(rule)
	uiAssert.namedMapEval(1, rule, editWid._nm_bad_input)

	self.LE_bad_input_rule = rule or false

	return self
end


function client:getBadInputRule()
	return self.LE_bad_input_rule
end


function client:setSelectAllOnThimble1Take(enabled)
	self.LE_select_all_on_thimble1_take = not not enabled

	return self
end


function client:getSelectAllOnThimble1Take()
	return self.LE_select_all_on_thimble1_take
end


function client:setDeselectAllOnThimble1Release(enabled)
	self.LE_deselect_all_on_thimble1_release = not not enabled

	return self
end


function client:getDeselectAllOnThimble1Release()
	return self.LE_deselect_all_on_thimble1_release
end


function client:setClearHistoryOnDeselect(enabled)
	self.LE_clear_history_on_deselect = not not enabled

	return self
end


function client:getClearHistoryOnDeselect()
	return self.LE_clear_history_on_deselect
end


function client:setClearInputCategoryOnDeselect(enabled)
	self.LE_clear_input_category_on_deselect = not not enabled

	return self
end


function client:getClearInputCategoryOnDeselect()
	return self.LE_clear_input_category_on_deselect
end


function client:setGhostText(str)
	uiAssert.typeEval(1, str, "string")

	self.LE_ghost_text = str or false

	return self
end


function client:getGhostText()
	return self.LE_ghost_text and self.LE_ghost_text
end


function client:setMaxCodePoints(n)
	uiAssert.integerGE(1, n, 0)

	editWidM.wrapAction(self, editCommandM.setMaxCodePoints, n)

	return self
end


function client:getMaxCodePoints()
	return self.LE_u_chars_max
end


return editMethodsM
