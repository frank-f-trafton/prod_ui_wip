-- To load: local lib = context:getLua("shared/lib")


--[[
The default action bindings.
--]]


local context = select(1, ...)


local editBind = {}


-- ProdUI
local editAct = context:getLua("shared/edit_field/edit_act")


-- The nesting order of modifier keys must always be: control -> gui -> alt -> shift
-- This doesn't affect the order of keys which must be held down.
-- NOTE: holding control prevents love.textinput from firing, but holding alt does not.


-- "OS X", "Windows", "Linux", "Android" or "iOS".
-- XXX: macOS variations of shortcuts.
local host_os = love.system.getOS()


editBind["!control"] = {}
editBind["!control"]["!gui"] = {}
editBind["!control"]        ["!alt"] = {}
editBind["!control"]["!gui"]["!alt"] = {}
editBind["!control"]                ["!shift"] = {}
editBind["!control"]["!gui"]        ["!shift"] = {}
editBind["!control"]        ["!alt"]["!shift"] = {}
editBind["!control"]["!gui"]["!alt"]["!shift"] = {}

editBind            ["!gui"] = {}
editBind            ["!gui"]["!alt"] = {}
editBind            ["!gui"]        ["!shift"] = {}
editBind            ["!gui"]["!alt"]["!shift"] = {}

editBind                    ["!alt"] = {}
editBind                    ["!alt"]["!shift"] = {}

editBind                            ["!shift"] = {}


editBind["left"] = editAct.caretLeft
editBind["right"] = editAct.caretRight
editBind["!shift"]["left"] = editAct.caretLeftHighlight
editBind["!shift"]["right"] = editAct.caretRightHighlight

editBind["!control"]["left"] = editAct.caretJumpLeft
editBind["!control"]["right"] = editAct.caretJumpRight
editBind["!control"]["!shift"]["left"] = editAct.caretJumpLeftHighlight
editBind["!control"]["!shift"]["right"] = editAct.caretJumpRightHighlight

editBind["home"] = editAct.caretLineFirst
editBind["end"] = editAct.caretLineLast

editBind["!control"]["home"] = editAct.caretFirst
editBind["!control"]["end"] = editAct.caretLast
editBind["!control"]["!shift"]["home"] = editAct.caretFirstHighlight
editBind["!control"]["!shift"]["end"] = editAct.caretLastHighlight
editBind["!shift"]["home"] = editAct.caretLineFirstHighlight
editBind["!shift"]["end"] = editAct.caretLineLastHighlight

editBind["up"] = editAct.caretStepUp
editBind["down"] = editAct.caretStepDown
editBind["!shift"]["up"] = editAct.caretStepUpHighlight
editBind["!shift"]["down"] = editAct.caretStepDownHighlight

editBind["!alt"]["up"] = editAct.shiftLinesUp
editBind["!alt"]["down"] = editAct.shiftLinesDown

editBind["!control"]["up"] = editAct.caretStepUpCoreLine
editBind["!control"]["down"] = editAct.caretStepDownCoreLine
editBind["!control"]["!shift"]["up"] = editAct.caretStepUpCoreLineHighlight
editBind["!control"]["!shift"]["down"] = editAct.caretStepDownCoreLineHighlight

editBind["pageup"] = editAct.caretPageUp
editBind["pagedown"] = editAct.caretPageDown
editBind["!shift"]["pageup"] = editAct.caretPageUpHighlight
editBind["!shift"]["pagedown"] = editAct.caretPageDownHighlight

editBind["backspace"] = editAct.backspace
editBind["!shift"]["backspace"] = editAct.backspace
editBind["delete"] = editAct.delete
editBind["!control"]["delete"] = editAct.deleteGroup
editBind["!control"]["backspace"] = editAct.backspaceGroup
editBind["!control"]["!shift"]["delete"] = editAct.deleteCaretToLineEnd
editBind["!control"]["!shift"]["backspace"] = editAct.backspaceCaretToLineStart

editBind["!control"]["d"] = editAct.deleteLine

editBind["return"] = editAct.typeLineFeed
editBind["kpenter"] = editAct.typeLineFeed

editBind["tab"] = editAct.typeTab
editBind["!shift"]["tab"] = editAct.typeUntab

editBind["!control"]["a"] = editAct.selectAll
editBind["!control"]["c"] = editAct.copy
editBind["!control"]["x"] = editAct.cut
editBind["!shift"]["delete"] = editAct.cut
editBind["!control"]["v"] = editAct.paste
editBind["insert"] = editAct.toggleReplaceMode

editBind["!control"]["z"] = editAct.undo
editBind["!control"]["!shift"]["z"] = editAct.redo
editBind["!control"]["y"] = editAct.redo


-- DEBUG: Test mouse-click commands from the keyboard
--[[
editBind["!control"]["!alt"]["w"] = editAct.selectCurrentWord
editBind["!control"]["!alt"]["a"] = editAct.selectCurrentLine
--]]


return editBind
