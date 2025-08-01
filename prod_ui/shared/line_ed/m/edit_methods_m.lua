-- LineEditor (multi) plug-in methods for client widgets.


local context = select(1, ...)


local editMethodsM = {}
local client = editMethodsM


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")
local editWidM = context:getLua("shared/line_ed/m/edit_wid_m")
local editWrapM = context:getLua("shared/line_ed/m/edit_wrap_m")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = context:getLua("core/wid_shared")


local _enum_align = uiShared.makeLUTV("left", "center", "right")
local _enum_bad_input = uiShared.makeLUTV("trim", "replacement_char")


function client:deleteHighlighted()
	editWrapM.wrapAction(self, editCommandM.deleteHighlighted)
end


function client:backspace()
	editWrapM.wrapAction(self, editCommandM.backspace)
end


function client:undo()
	editWrapM.wrapAction(self, editCommandM.undo)
end


function client:redo()
	editWrapM.wrapAction(self, editCommandM.redo)
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


function client:isHighlighted()
	return self.LE:isHighlighted()
end


function client:clearHighlight()
	editWrapM.wrapAction(self, editCommandM.clearHighlight) -- TODO: wrapped function doesn't exist
end


function client:highlightAll()
	editWrapM.wrapAction(self, editCommandM.highlightAll)
end


function client:caretToHighlightEdgeLeft()
	editWrapM.wrapAction(self, editCommandM.caretToHighlightEdgeLeft)
end


function client:caretToHighlightEdgeRight()
	editWrapM.wrapAction(self, editCommandM.caretToHighlightEdgeRight)
end


function client:highlightCurrentLine()
	editWrapM.wrapAction(self, editCommandM.highlightCurrentLine)
end


function client:highlightCurrentWrappedLine()
	editWrapM.wrapAction(self, editCommandM.highlightCurrentWrappedLine)
end


function client:highlightCurrentWord()
	editWrapM.wrapAction(self, editCommandM.highlightCurrentWord)
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


function client:writeText(text, suppress_replace)
	uiShared.type1(1, text, "string")

	editWrapM.wrapAction(self, editCommandM.writeText, text, suppress_replace)
end


function client:replaceText(text)
	uiShared.type1(1, text, "string")

	editWrapM.wrapAction(self, editCommandM.replaceText, text)
end


function client:setText(text)
	uiShared.type1(1, text, "string")

	editWrapM.wrapAction(self, editCommandM.setText, text)
end


function client:getText(l1, l2)
	return self.LE.lines:copyString(l1, l2)
end


function client:getLineCount()
	return #self.LE.lines
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
	editWrapM.wrapAction(self, editCommandM.deleteAll)
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


function client:caretFullLineFirst(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretFullLineFirst, clear_highlight)
end


function client:caretFullLineLast(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretFullLineLast, clear_highlight)
end


function client:caretSubLineFirst(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretSubLineFirst, clear_highlight)
end


function client:caretSubLineLast(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretSubLineLast, clear_highlight)
end


function client:caretLineFirst(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretLineFirst, clear_highlight)
end


function client:caretLineLast(clear_highlight)
	editWrapM.wrapAction(self, editCommandM.caretLineLast, clear_highlight)
end


function client:resetInputCategory()
	-- Used to force a new history entry.
	self.LE_input_category = false
end


function client:scrollGetCaretInBounds(immediate)
	editWidM.scrollGetCaretInBounds(self, immediate)
end


function client:setAllowReplaceMode(enabled)
	editWrapM.wrapAction(self, editCommandM.setAllowReplaceMode, enabled)
end


function client:getAllowReplaceMode()
	return self.LE_allow_replace
end


function client:setReplaceMode(enabled)
	editWrapM.wrapAction(self, editCommandM.setReplaceMode, enabled)
end


function client:getReplaceMode()
	return self.LE_replace_mode
end


function client:setWrapMode(enabled)
	editWrapM.wrapAction(self, editCommandM.setWrapMode, enabled)
end


function client:getWrapMode()
	return self.LE.wrap_mode
end


function client:setTextAlignment(align)
	uiShared.enum(1, align, "alignMode", _enum_align)

	editWrapM.wrapAction(self, editCommandM.setTextAlignment, align)
end


function client:getTextAlignment()
	return self.LE.align
end


function client:setColorization(enabled)
	editWrapM.wrapAction(self, editCommandM.setColorization, enabled)
end


function client:getColorization()
	return self.LE.generate_colored_text
end


function client:setAllowHighlight(enabled)
	editWrapM.wrapAction(self, editCommandM.setAllowHighlight, enabled)
end


function client:getAllowHighlight(enabled)
	return self.LE_allow_highlight
end


function client:setAllowTab(enabled)
	self.LE_allow_tab = not not enabled
end


function client:getAllowTab()
	return self.LE_allow_tab
end


function client:setAllowUntab(enabled)
	self.LE_allow_untab = not not enabled
end


function client:getAllowUntab()
	return self.LE_allow_untab
end


function client:setTabsToSpaces(enabled)
	self.LE_tabs_to_spaces = not not enabled
end


function client:getTabsToSpaces()
	return self.LE_tabs_to_spaces
end


function client:setAutoIndent(enabled)
	self.LE_auto_indent = not not enabled
end


function client:getAutoIndent()
	return self.LE_auto_indent
end


function client:setAllowInput(enabled)
	self.LE_allow_input = not not enabled
end


function client:getAllowInput()
	return self.LE_allow_input
end


function client:setAllowCut(enabled)
	self.LE_allow_cut = not not enabled
end


function client:getAllowCut()
	return self.LE_allow_cut
end


function client:setAllowCopy(enabled)
	self.LE_allow_copy = not not enabled
end


function client:getAllowCopy()
	return self.LE_allow_copy
end


function client:setAllowPaste(enabled)
	self.LE_allow_paste = not not enabled
end


function client:getAllowPaste()
	return self.LE_allow_paste
end


function client:setAllowLineFeed(enabled)
	self.LE_allow_line_feed = not not enabled
end


function client:getAllowLineFeed()
	return self.LE_allow_line_feed
end


-- @param rule The rule to use.
-- * "trim": Cut the string at the first bad byte.
-- * "replacement_char": Replace every unrecognized byte with the Unicode replacement code point.
-- * false/nile: return an empty string on bad unput.
function client:setBadInputRule(rule)
	uiShared.enumEval(1, rule, "badInputRule", _enum_bad_input)

	self.LE_bad_input_rule = rule or false
end


function client:getBadInputRule()
	return self.LE_bad_input_rule
end


return editMethodsM
