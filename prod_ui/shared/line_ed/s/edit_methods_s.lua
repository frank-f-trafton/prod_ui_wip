-- LineEditor (single) plug-in methods for client widgets.
-- S == single-line only.


local context = select(1, ...)


local editMethodsS = {}
local client = editMethodsS


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local editCommandS = context:getLua("shared/line_ed/s/edit_command_s")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


function client:writeText(text, suppress_replace)
	uiShared.type1(1, text, "string")

	editWidS.wrapAction(self, editCommandS.writeText, text, suppress_replace)
end


function client:replaceText(text)
	uiShared.type1(1, text, "string")

	editWidS.wrapAction(self, editCommandS.replaceText, text)
end


function client:setText(text)
	uiShared.type1(1, text, "string")

	editWidS.wrapAction(self, editCommandS.setText, text)
end


function client:getText()
	return editFuncS.getText(self)
end


function client:getHighlightedText()
	return editFuncS.getHighlightedText(self)
end


function client:cut()
	editWidS.wrapAction(self, editCommandS.cut)
end


function client:copy()
	editWidS.wrapAction(self, editCommandS.copy)
end


function client:paste()
	editWidS.wrapAction(self, editCommandS.paste)
end


function client:caretStepLeft(clear_highlight)
	editWidS.wrapAction(self, editCommandS.caretLeft, clear_highlight)
end


function client:caretStepRight(clear_highlight)
	editWidS.wrapAction(self, editCommandS.caretRight, clear_highlight)
end


function client:caretJumpLeft(clear_highlight)
	editWidS.wrapAction(self, editCommandS.caretJumpRight, clear_highlight)
end


function client:caretJumpRight(clear_highlight)
	editWidS.wrapAction(self, editCommandS.caretJumpRight, clear_highlight)
end


function client:caretFirst(clear_highlight)
	editWidS.wrapAction(self, editFuncS.caretFirst, clear_highlight)
end


function client:caretLast(clear_highlight)
	editWidS.wrapAction(self, editFuncS.caretLast, clear_highlight)
end


function client:caretToHighlightEdgeLeft()
	editWidS.wrapAction(self, editCommandS.caretToHighlightEdgeLeft)
end


function client:caretToHighlightEdgeRight()
	editWidS.wrapAction(self, editCommandS.caretToHighlightEdgeRight)
end


function client:isHighlighted()
	return self.LE:isHighlighted()
end


function client:highlightAll()
	print("highlight all!")
	editWidS.wrapAction(self, editCommandS.highlightAll)
end


function client:highlightCurrentWord()
	editWidS.wrapAction(self, editCommandS.highlightCurrentWord)
end


function client:clearHighlight()
	editWidS.wrapAction(self, editCommandS.clearHighlight)
end


function client:deleteHighlighted()
	editWidS.wrapAction(self, editCommandS.deleteHighlighted)
end


function client:deleteCaretToStart() -- S
	editWidS.wrapAction(self, editCommandS.deleteCaretToStart)
end


function client:deleteCaretToEnd() -- S
	editWidS.wrapAction(self, editCommandS.deleteCaretToEnd)
end


function client:backspace()
	editWidS.wrapAction(self, editCommandS.backspace)
end


function client:deleteUChar(n_u_chars)
	uiShared.type1(1, n_u_chars, "number")

	editWidS.wrapAction(self, editCommandS.deleteUChar, n_u_chars)
end


function client:deleteAll()
	editWidS.wrapAction(self, editCommandS.deleteAll)
end


function client:backspaceGroup()
	editWidS.wrapAction(self, editCommandS.backspaceGroup)
end


function client:deleteGroup()
	editWidS.wrapAction(self, editCommandS.deleteGroup)
end


function client:undo()
	editWidS.wrapAction(self, editCommandS.undo)
end


function client:redo()
	editWidS.wrapAction(self, editCommandS.redo)
end


function client:resetInputCategory()
	-- Used to force a new history entry.
	self.LE_input_category = false
end


function client:scrollGetCaretInBounds(immediate)
	editWidS.scrollGetCaretInBounds(self, immediate)
end


function client:setAllowReplaceMode(enabled)
	editWidS.wrapAction(self, editCommandS.setAllowReplaceMode, enabled)
end


function client:getAllowReplaceMode()
	return self.LE_allow_replace
end


function client:setReplaceMode(enabled)
	editWidS.wrapAction(self, editCommandS.setReplaceMode, enabled)
end


function client:getReplaceMode()
	return self.LE_replace_mode
end


function client:setTextAlignment(align)
	uiShared.enum(1, align, "AlignMode", editWid._enum_align)

	editWidS.wrapAction(self, editCommandS.setTextAlignment, align)
end


function client:getTextAlignment()
	return self.LE.align
end


function client:setColorization(enabled)
	editWidS.wrapAction(self, editCommandS.setColorization, enabled)
end


function client:getColorization()
	return self.LE.generate_colored_text
end


function client:setAllowHighlight(enabled)
	editWidS.wrapAction(self, editCommandS.setAllowHighlight, enabled)
end


function client:getAllowHighlight(enabled)
	return self.LE_allow_highlight
end


function client:setAllowInput(enabled)
	editWidS.wrapAction(self, editCommandS.setAllowInput, enabled)
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


function client:setAllowEnterLineFeed(enabled) -- S
	self.LE_allow_enter_line_feed = not not enabled
end


function client:getAllowEnterLineFeed() -- S
	return self.LE_allow_enter_line_feed
end


-- @param rule The rule to use.
-- * "trim": Cut the string at the first bad byte.
-- * "replacement_char": Replace every unrecognized byte with the Unicode replacement code point.
-- * false/nil: return an empty string on bad unput.
function client:setBadInputRule(rule)
	uiShared.enumEval(1, rule, "BadInputRule", editWid._enum_bad_input)

	self.LE_bad_input_rule = rule or false
end


function client:getBadInputRule()
	return self.LE_bad_input_rule
end


function client:setSelectAllOnThimble1Take(enabled)
	self.LE_select_all_on_thimble1_take = not not enabled
end


function client:getSelectAllOnThimble1Take()
	return self.LE_select_all_on_thimble1_take
end


function client:setDeselectAllOnThimble1Release(enabled)
	self.LE_deselect_all_on_thimble1_release = not not enabled
end


function client:getDeselectAllOnThimble1Release()
	return self.LE_deselect_all_on_thimble1_release
end


function client:setClearHistoryOnDeselect(enabled)
	self.LE_clear_history_on_deselect = not not enabled
end


function client:getClearHistoryOnDeselect()
	return self.LE_clear_history_on_deselect
end


function client:setClearInputCategoryOnDeselect(enabled)
	self.LE_clear_input_category_on_deselect = not not enabled
end


function client:getClearInputCategoryOnDeselect()
	return self.LE_clear_input_category_on_deselect
end


return editMethodsS
