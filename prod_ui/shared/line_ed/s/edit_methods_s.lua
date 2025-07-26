-- LineEditor (single) plug-in methods for client widgets.


local context = select(1, ...)


local editMethodsS = {}
local client = editMethodsS


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local editCommandS = context:getLua("shared/line_ed/s/edit_command_s")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editWrapS = context:getLua("shared/line_ed/s/edit_wrap_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


local _enum_align = uiShared.makeLUTV("left", "center", "right")


function client:deleteHighlighted()
	editWrapS.wrapAction(self, editCommandS.deleteHighlighted)
end


function client:backspace()
	editWrapS.wrapAction(self, editCommandS.backspace)
end


function client:writeText(text, suppress_replace)
	uiShared.type1(1, text, "string")

	editWrapS.wrapAction(self, editCommandS.writeText, text, suppress_replace)
end


function client:replaceText(text)
	uiShared.type1(1, text, "string")

	editWrapS.wrapAction(self, editCommandS.replaceText, text)
end


function client:setText(text)
	uiShared.type1(1, text, "string")

	editWrapS.wrapAction(self, editCommandS.setText, text)
end


function client:undo()
	editWrapS.wrapAction(self, editCommandS.undo)
end


function client:redo()
	editWrapS.wrapAction(self, editCommandS.redo)
end


function client:getText()
	return editFuncS.getText(self)
end


function client:getDisplayText()
	return editFuncS.getDisplayText(self)
end


function client:getHighlightedText()
	return editFuncS.getHighlightedText(self)
end


function client:isHighlighted()
	return self.line_ed:isHighlighted()
end


function client:clearHighlight()
	editWrapS.wrapAction(self, editCommandS.clearHighlight)
end


function client:highlightAll()
	editWrapS.wrapAction(self, editCommandS.highlightAll)
end


function client:caretToHighlightEdgeLeft()
	editWrapS.wrapAction(self, editCommandS.caretToHighlightEdgeLeft)
end


function client:caretToHighlightEdgeRight()
	editWrapS.wrapAction(self, editCommandS.caretToHighlightEdgeRight)
end


function client:highlightCurrentWord()
	editWrapS.wrapAction(self, editCommandS.highlightCurrentWord)
end


function client:caretStepLeft(clear_highlight)
	editWrapS.wrapAction(self, editCommandS.caretLeft, clear_highlight)
end


function client:caretStepRight(clear_highlight)
	editWrapS.wrapAction(self, editCommandS.caretRight, clear_highlight)
end


function client:caretJumpLeft(clear_highlight)
	editWrapS.wrapAction(self, editCommandS.caretJumpRight, clear_highlight)
end


function client:caretJumpRight(clear_highlight)
	editWrapS.wrapAction(self, editCommandS.caretJumpRight, clear_highlight)
end


function client:deleteUChar(n_u_chars)
	uiShared.type1(1, n_u_chars, "number")

	editWrapS.wrapAction(self, editCommandS.deleteUChar, n_u_chars)
end


function client:deleteGroup()
	editWrapS.wrapAction(self, editCommandS.deleteGroup)
end


function client:backspaceGroup()
	editWrapS.wrapAction(self, editCommandS.backspaceGroup)
end


function client:deleteCaretToEnd()
	editWrapS.wrapAction(self, editCommandS.deleteCaretToEnd)
end


function client:deleteCaretToStart()
	editWrapS.wrapAction(self, editCommandS.deleteCaretToStart)
end


function client:caretFirst(clear_highlight)
	editWrapS.wrapAction(self, editFuncS.caretFirst, clear_highlight)
end


function client:caretLast(clear_highlight)
	editWrapS.wrapAction(self, editFuncS.caretLast, clear_highlight)
end


function client:cut()
	editWrapS.wrapAction(self, editCommandS.cut)
end


function client:copy()
	editWrapS.wrapAction(self, editCommandS.copy)
end


function client:paste()
	editWrapS.wrapAction(self, editCommandS.paste)
end


function client:getReplaceMode()
	return self.replace_mode
end


function client:setReplaceMode(enabled)
	editWrapS.wrapAction(self, editCommandS.setReplaceMode, enabled)
end


function client:toggleReplaceMode()
	editWrapS.wrapAction(self, editCommandS.toggleReplaceMode)
end


function client:getTextAlignment()
	return self.align
end


function client:setTextAlignment(align)
	if not _enum_align[align] then
		error("invalid align mode")
	end

	editWrapS.wrapAction(self, editCommandS.setTextAlignment, align)
end


function client:resetInputCategory()
	-- Used to force a new history entry.
	self.input_category = false
end


return editMethodsS
