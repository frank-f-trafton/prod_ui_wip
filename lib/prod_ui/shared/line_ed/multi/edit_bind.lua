-- To load: local lib = context:getLua("shared/lib")


--[[
The default action bindings.
--]]


local context = select(1, ...)


local editBind = {}


-- ProdUI
local editAct = context:getLua("shared/line_ed/multi/edit_act")
local keyCombo = require(context.conf.prod_ui_req .. "lib.key_combo")


--[[
NOTE: holding control prevents love.textinput from firing, but holding alt does not.
--]]


-- "OS X", "Windows", "Linux", "Android" or "iOS".
-- XXX: macOS variations of shortcuts.
local host_os = love.system.getOS()


editBind["left"] = editAct.caretLeft
editBind["right"] = editAct.caretRight

editBind["S left"] = editAct.caretLeftHighlight
editBind["S right"] = editAct.caretRightHighlight

editBind["C left"] = editAct.caretJumpLeft
editBind["C right"] = editAct.caretJumpRight

editBind["CS left"] = editAct.caretJumpLeftHighlight
editBind["CS right"] = editAct.caretJumpRightHighlight

editBind["home"] = editAct.caretLineFirst
editBind["end"] = editAct.caretLineLast

editBind["C home"] = editAct.caretFirst
editBind["C end"] = editAct.caretLast

editBind["CS home"] = editAct.caretFirstHighlight
editBind["CS end"] = editAct.caretLastHighlight

editBind["S home"] = editAct.caretLineFirstHighlight
editBind["S end"] = editAct.caretLineLastHighlight

editBind["up"] = editAct.caretStepUp
editBind["down"] = editAct.caretStepDown

editBind["S up"] = editAct.caretStepUpHighlight
editBind["S down"] = editAct.caretStepDownHighlight

editBind["A up"] = editAct.shiftLinesUp
editBind["A down"] = editAct.shiftLinesDown

editBind["C up"] = editAct.caretStepUpCoreLine
editBind["C down"] = editAct.caretStepDownCoreLine

editBind["CS up"] = editAct.caretStepUpCoreLineHighlight
editBind["CS down"] = editAct.caretStepDownCoreLineHighlight

editBind["pageup"] = editAct.caretPageUp
editBind["pagedown"] = editAct.caretPageDown

editBind["S pageup"] = editAct.caretPageUpHighlight
editBind["S pagedown"] = editAct.caretPageDownHighlight

editBind["backspace"] = editAct.backspace
editBind["S backspace"] = editAct.backspace
editBind["C backspace"] = editAct.backspaceGroup
editBind["CS backspace"] = editAct.backspaceCaretToLineStart

editBind["delete"] = editAct.delete
editBind["C delete"] = editAct.deleteGroup
editBind["CS delete"] = editAct.deleteCaretToLineEnd

editBind["C d"] = editAct.deleteLine

editBind["return"] = editAct.typeLineFeedWithAutoIndent
editBind["kpenter"] = editAct.typeLineFeedWithAutoIndent

editBind["S return"] = editAct.typeLineFeed
editBind["S kpenter"] = editAct.typeLineFeed

editBind["tab"] = editAct.typeTab
editBind["S tab"] = editAct.typeUntab

editBind["C a"] = editAct.selectAll
editBind["C c"] = editAct.copy
editBind["C x"] = editAct.cut
editBind["S delete"] = editAct.cut
editBind["C v"] = editAct.paste

editBind["insert"] = editAct.toggleReplaceMode

editBind["C z"] = editAct.undo
editBind["CS z"] = editAct.redo
editBind["C y"] = editAct.redo


-- DEBUG: Test mouse-click commands from the keyboard
--[[
editBind["CA w"] = editAct.selectCurrentWord
editBind["CA a"] = editAct.selectCurrentLine
--]]


return editBind
