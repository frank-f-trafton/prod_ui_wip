-- Wrappable command functions that are suitable to use with key bindings.
-- Such functions do not take arguments (besides 'self').


local context = select(1, ...)


local editCommandS = context:getLua("shared/line_ed/s/edit_command_s")


return {
	caretLeft = editCommandS.caretLeft,
	caretRight = editCommandS.caretRight,
	caretLeftHighlight = editCommandS.caretLeftHighlight,
	caretRightHighlight = editCommandS.caretRightHighlight,
	caretJumpLeft = editCommandS.caretJumpLeft,
	caretJumpRight = editCommandS.caretJumpRight,
	caretJumpLeftHighlight = editCommandS.caretJumpLeftHighlight,
	caretJumpRightHighlight = editCommandS.caretJumpRightHighlight,
	caretFirst = editCommandS.caretFirst,
	caretLast = editCommandS.caretLast,
	caretFirstHighlight = editCommandS.caretFirstHighlight,
	caretLastHighlight = editCommandS.caretLastHighlight,
	backspace = editCommandS.backspace,
	delete = editCommandS.delete,
	deleteHighlighted = editCommandS.deleteHighlighted,
	deleteGroup = editCommandS.deleteGroup,
	deleteAll = editCommandS.deleteAll,
	backspaceGroup = editCommandS.backspaceGroup,
	deleteCaretToEnd = editCommandS.deleteCaretToEnd,
	backspaceCaretToStart = editCommandS.deleteCaretToStart,
	typeTab = editCommandS.typeTab,
	typeLineFeed = editCommandS.typeLineFeed,
	selectAll = editCommandS.highlightAll,
	selectCurrentWord = editCommandS.highlightCurrentWord,
	cut = editCommandS.cut,
	copy = editCommandS.copy,
	paste = editCommandS.paste,
	toggleReplaceMode = editCommandS.toggleReplaceMode,
	undo = editCommandS.undo,
	redo = editCommandS.redo
}
