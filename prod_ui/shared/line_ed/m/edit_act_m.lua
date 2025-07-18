-- Wrappable command functions that are suitable to use with key bindings.
-- Such functions do not take arguments (besides 'self').


local context = select(1, ...)


local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")


-- TODO: fill in the missing stuff (up, down, pageup, pagedown, and so on).

-- YOU WERE HERE


return {
	caretLeft = editCommandM.caretLeft,
	caretRight = editCommandM.caretRight,
	caretLeftHighlight = editCommandM.caretLeftHighlight,
	caretRightHighlight = editCommandM.caretRightHighlight,
	caretJumpLeft = editCommandM.caretJumpLeft,
	caretJumpRight = editCommandM.caretJumpRight,
	caretJumpLeftHighlight = editCommandM.caretJumpLeftHighlight,
	caretJumpRightHighlight = editCommandM.caretJumpRightHighlight,
	caretFirst = editCommandM.caretFirst,
	caretLast = editCommandM.caretLast,
	caretFirstHighlight = editCommandM.caretFirstHighlight,
	caretLastHighlight = editCommandM.caretLastHighlight,
	backspace = editCommandM.backspace,
	delete = editCommandM.delete,
	deleteHighlighted = editCommandM.deleteHighlighted,
	deleteGroup = editCommandM.deleteGroup,
	deleteAll = editCommandM.deleteAll,
	backspaceGroup = editCommandM.backspaceGroup,
	deleteCaretToEnd = editCommandM.deleteCaretToEnd,
	backspaceCaretToStart = editCommandM.deleteCaretToStart,
	typeTab = editCommandM.typeTab,
	typeLineFeed = editCommandM.typeLineFeed,
	selectAll = editCommandM.highlightAll,
	selectCurrentWord = editCommandM.highlightCurrentWord,
	cut = editCommandM.cut,
	copy = editCommandM.copy,
	paste = editCommandM.paste,
	toggleReplaceMode = editCommandM.toggleReplaceMode,
	undo = editCommandM.undo,
	redo = editCommandM.redo
}
