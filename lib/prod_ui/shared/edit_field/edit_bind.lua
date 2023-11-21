-- To load: local lib = context:getLua("shared/lib")


--[[
The default action bindings.
--]]


local context = select(1, ...)


local editBind = {}


-- ProdUI
local editAct = context:getLua("shared/edit_field/edit_act")

--[[
The nesting order of modifier keys must always be: control -> gui -> alt -> shift

This doesn't affect the order of keys which must be held down.

NOTE: holding control prevents love.textinput from firing, but holding alt does not.
--]]


-- "OS X", "Windows", "Linux", "Android" or "iOS".
-- XXX: macOS variations of shortcuts.
local host_os = love.system.getOS()


-- Tree structure to hold keybindings.               -- CGAS
-----------------------------------------------------------------------------
editBind["!control"]                           = {}  -- 1000
editBind            ["!gui"]                   = {}  -- 0100
editBind["!control"]["!gui"]                   = {}  -- 1100
editBind                    ["!alt"]           = {}  -- 0010
editBind["!control"]        ["!alt"]           = {}  -- 1010
editBind            ["!gui"]["!alt"]           = {}  -- 0110
editBind["!control"]["!gui"]["!alt"]           = {}  -- 1110
editBind                            ["!shift"] = {}  -- 0001
editBind["!control"]                ["!shift"] = {}  -- 1001
editBind            ["!gui"]        ["!shift"] = {}  -- 0101
editBind["!control"]["!gui"]        ["!shift"] = {}  -- 1101
editBind                    ["!alt"]["!shift"] = {}  -- 0011
editBind["!control"]        ["!alt"]["!shift"] = {}  -- 1011
editBind            ["!gui"]["!alt"]["!shift"] = {}  -- 0111
editBind["!control"]["!gui"]["!alt"]["!shift"] = {}  -- 1111


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
editBind["!control"]["backspace"] = editAct.backspaceGroup
editBind["!control"]["!shift"]["backspace"] = editAct.backspaceCaretToLineStart

editBind["delete"] = editAct.delete
editBind["!control"]["delete"] = editAct.deleteGroup
editBind["!control"]["!shift"]["delete"] = editAct.deleteCaretToLineEnd

editBind["!control"]["d"] = editAct.deleteLine

editBind["return"] = editAct.typeLineFeedWithAutoIndent
editBind["kpenter"] = editAct.typeLineFeedWithAutoIndent

editBind["!shift"]["return"] = editAct.typeLineFeed
editBind["!shift"]["kpenter"] = editAct.typeLineFeed

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
