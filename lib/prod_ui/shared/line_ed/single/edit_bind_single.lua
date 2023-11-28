-- To load: local lib = context:getLua("shared/lib")


-- Default action bindings.


local context = select(1, ...)


local editBindSingle = {}


-- ProdUI
local editActSingle = context:getLua("shared/line_ed/single/edit_act_single")
local keyCombo = require(context.conf.prod_ui_req .. "lib.key_combo")


--[[
NOTE: holding control prevents love.textinput from firing, but holding alt does not.
--]]


-- "OS X", "Windows", "Linux", "Android" or "iOS".
-- XXX: macOS variations of shortcuts.
local host_os = love.system.getOS()


editBindSingle["left"] = editActSingle.caretLeft
editBindSingle["right"] = editActSingle.caretRight

editBindSingle["S left"] = editActSingle.caretLeftHighlight
editBindSingle["S right"] = editActSingle.caretRightHighlight

editBindSingle["C left"] = editActSingle.caretJumpLeft
editBindSingle["C right"] = editActSingle.caretJumpRight

editBindSingle["CS left"] = editActSingle.caretJumpLeftHighlight
editBindSingle["CS right"] = editActSingle.caretJumpRightHighlight

editBindSingle["home"] = editActSingle.caretLineFirst
editBindSingle["end"] = editActSingle.caretLineLast

editBindSingle["C home"] = editActSingle.caretLineFirst
editBindSingle["C end"] = editActSingle.caretLineLast

editBindSingle["CS home"] = editActSingle.caretLineFirst
editBindSingle["CS end"] = editActSingle.caretLineLast

editBindSingle["S home"] = editActSingle.caretLineFirstHighlight
editBindSingle["S end"] = editActSingle.caretLineLastHighlight

editBindSingle["backspace"] = editActSingle.backspace
editBindSingle["S backspace"] = editActSingle.backspace
editBindSingle["C backspace"] = editActSingle.backspaceGroup
editBindSingle["CS backspace"] = editActSingle.backspaceCaretToLineStart

editBindSingle["delete"] = editActSingle.delete
editBindSingle["C delete"] = editActSingle.deleteGroup
editBindSingle["CS delete"] = editActSingle.deleteCaretToLineEnd

editBindSingle["return"] = editActSingle.typeLineFeed
editBindSingle["kpenter"] = editActSingle.typeLineFeed

editBindSingle["S return"] = editActSingle.typeLineFeed
editBindSingle["S kpenter"] = editActSingle.typeLineFeed

editBindSingle["tab"] = editActSingle.typeTab

editBindSingle["C a"] = editActSingle.selectAll
editBindSingle["C c"] = editActSingle.copy
editBindSingle["C x"] = editActSingle.cut
editBindSingle["S delete"] = editActSingle.cut
editBindSingle["C v"] = editActSingle.paste

editBindSingle["insert"] = editActSingle.toggleReplaceMode

editBindSingle["C z"] = editActSingle.undo
editBindSingle["CS z"] = editActSingle.redo
editBindSingle["C y"] = editActSingle.redo


-- DEBUG: Test mouse-click commands from the keyboard
--[[
editBindSingle["CA w"] = editActSingle.selectCurrentWord
editBindSingle["CA a"] = editActSingle.selectCurrentLine
--]]


return editBindSingle
