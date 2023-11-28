-- To load: local lib = context:getLua("shared/lib")


-- Default action bindings.


local context = select(1, ...)


local editBindM = {}


-- ProdUI
local editActM = context:getLua("shared/line_ed/m/edit_act_m")
local keyCombo = require(context.conf.prod_ui_req .. "lib.key_combo")


--[[
NOTE: holding control prevents love.textinput from firing, but holding alt does not.
--]]


-- "OS X", "Windows", "Linux", "Android" or "iOS".
-- XXX: macOS variations of shortcuts.
local host_os = love.system.getOS()


editBindM["left"] = editActM.caretLeft
editBindM["right"] = editActM.caretRight

editBindM["S left"] = editActM.caretLeftHighlight
editBindM["S right"] = editActM.caretRightHighlight

editBindM["C left"] = editActM.caretJumpLeft
editBindM["C right"] = editActM.caretJumpRight

editBindM["CS left"] = editActM.caretJumpLeftHighlight
editBindM["CS right"] = editActM.caretJumpRightHighlight

editBindM["home"] = editActM.caretLineFirst
editBindM["end"] = editActM.caretLineLast

editBindM["C home"] = editActM.caretFirst
editBindM["C end"] = editActM.caretLast

editBindM["CS home"] = editActM.caretFirstHighlight
editBindM["CS end"] = editActM.caretLastHighlight

editBindM["S home"] = editActM.caretLineFirstHighlight
editBindM["S end"] = editActM.caretLineLastHighlight

editBindM["up"] = editActM.caretStepUp
editBindM["down"] = editActM.caretStepDown

editBindM["S up"] = editActM.caretStepUpHighlight
editBindM["S down"] = editActM.caretStepDownHighlight

editBindM["A up"] = editActM.shiftLinesUp
editBindM["A down"] = editActM.shiftLinesDown

editBindM["C up"] = editActM.caretStepUpCoreLine
editBindM["C down"] = editActM.caretStepDownCoreLine

editBindM["CS up"] = editActM.caretStepUpCoreLineHighlight
editBindM["CS down"] = editActM.caretStepDownCoreLineHighlight

editBindM["pageup"] = editActM.caretPageUp
editBindM["pagedown"] = editActM.caretPageDown

editBindM["S pageup"] = editActM.caretPageUpHighlight
editBindM["S pagedown"] = editActM.caretPageDownHighlight

editBindM["backspace"] = editActM.backspace
editBindM["S backspace"] = editActM.backspace
editBindM["C backspace"] = editActM.backspaceGroup
editBindM["CS backspace"] = editActM.backspaceCaretToLineStart

editBindM["delete"] = editActM.delete
editBindM["C delete"] = editActM.deleteGroup
editBindM["CS delete"] = editActM.deleteCaretToLineEnd

editBindM["C d"] = editActM.deleteLine

editBindM["return"] = editActM.typeLineFeedWithAutoIndent
editBindM["kpenter"] = editActM.typeLineFeedWithAutoIndent

editBindM["S return"] = editActM.typeLineFeed
editBindM["S kpenter"] = editActM.typeLineFeed

editBindM["tab"] = editActM.typeTab
editBindM["S tab"] = editActM.typeUntab

editBindM["C a"] = editActM.selectAll
editBindM["C c"] = editActM.copy
editBindM["C x"] = editActM.cut
editBindM["S delete"] = editActM.cut
editBindM["C v"] = editActM.paste

editBindM["insert"] = editActM.toggleReplaceMode

editBindM["C z"] = editActM.undo
editBindM["CS z"] = editActM.redo
editBindM["C y"] = editActM.redo


-- DEBUG: Test mouse-click commands from the keyboard
--[[
editBindM["CA w"] = editActM.selectCurrentWord
editBindM["CA a"] = editActM.selectCurrentLine
--]]


return editBindM
