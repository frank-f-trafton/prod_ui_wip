-- To load: local lib = context:getLua("shared/lib")


-- Default action bindings.


local context = select(1, ...)


local editBindS = {}


-- ProdUI
local editActS = context:getLua("shared/line_ed/s/edit_act_s")


--[[
NOTE: holding control prevents love.textinput from firing, but holding alt does not.
--]]


-- "OS X", "Windows", "Linux", "Android" or "iOS".
-- XXX: macOS variations of shortcuts.
local host_os = love.system.getOS()


editBindS["+left"] = editActS.caretLeft
editBindS["+right"] = editActS.caretRight

editBindS["S+left"] = editActS.caretLeftHighlight
editBindS["S+right"] = editActS.caretRightHighlight

editBindS["C+left"] = editActS.caretJumpLeft
editBindS["C+right"] = editActS.caretJumpRight

editBindS["CS+left"] = editActS.caretJumpLeftHighlight
editBindS["CS+right"] = editActS.caretJumpRightHighlight

editBindS["+home"] = editActS.caretFirst
editBindS["+end"] = editActS.caretLast

editBindS["C+home"] = editActS.caretFirst
editBindS["C+end"] = editActS.caretLast

editBindS["CS+home"] = editActS.caretFirstHighlight
editBindS["CS+end"] = editActS.caretLastHighlight

editBindS["S+home"] = editActS.caretFirstHighlight
editBindS["S+end"] = editActS.caretLastHighlight

editBindS["+backspace"] = editActS.backspace
editBindS["S+backspace"] = editActS.backspace
editBindS["C+backspace"] = editActS.backspaceGroup
editBindS["CS+backspace"] = editActS.backspaceCaretToStart

editBindS["+delete"] = editActS.delete
editBindS["S+delete"] = editActS.delete
editBindS["C+delete"] = editActS.deleteGroup
editBindS["CS+delete"] = editActS.deleteCaretToEnd

--editBindS["C d"] = editActS.deleteAll

editBindS["+return"] = editActS.typeLineFeed
editBindS["+kpenter"] = editActS.typeLineFeed

editBindS["S+return"] = editActS.typeLineFeed
editBindS["S+kpenter"] = editActS.typeLineFeed

editBindS["+tab"] = editActS.typeTab

editBindS["C+a"] = editActS.selectAll
editBindS["C+c"] = editActS.copy
editBindS["C+x"] = editActS.cut
editBindS["S+delete"] = editActS.cut
editBindS["C+v"] = editActS.paste

editBindS["+insert"] = editActS.toggleReplaceMode

editBindS["C+z"] = editActS.undo
editBindS["CS+z"] = editActS.redo
editBindS["C+y"] = editActS.redo


-- DEBUG: Test mouse-click commands from the keyboard
--[[
editBindS["CA+w"] = editActS.selectCurrentWord
--]]


return editBindS
