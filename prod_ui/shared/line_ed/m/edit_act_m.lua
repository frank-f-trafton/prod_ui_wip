-- Wrappable command functions that are suitable to use with key bindings.
-- Such functions do not take arguments (besides 'self').


local context = select(1, ...)


local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")


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
	caretStepUp = editCommandM.caretStepUp,
	caretStepDown = editCommandM.caretStepDown,
	caretPageUp = editCommandM.caretPageUp,
	caretPageDown = editCommandM.caretPageDown,
	caretPageUpHighlight = editCommandM.caretPageUpHighlight,
	caretPageDownHighlight = editCommandM.caretPageDownHighlight,
	caretStepUpHighlight = editCommandM.caretStepUpHighlight,
	caretStepDownHighlight = editCommandM.caretStepDownHighlight,
	shiftLinesUp = editCommandM.shiftLinesUp,
	shiftLinesDown = editCommandM.shiftLinesDown,
	caretLineFirst = editCommandM.caretLineFirst,
	caretLineLast = editCommandM.caretLineLast,
	caretLineFirstHighlight = editCommandM.caretLineFirstHighlight,
	caretLineLastHighlight = editCommandM.caretLineLastHighlight,
	-- caret: first of wrapped line
	-- caret: last of wrapped line
	backspace = editCommandM.backspace,
	delete = editCommandM.delete,
	deleteHighlighted = editCommandM.deleteHighlighted,
	deleteGroup = editCommandM.deleteGroup,
	deleteAll = editCommandM.deleteAll,
	backspaceGroup = editCommandM.backspaceGroup,
	deleteCaretToEnd = editCommandM.deleteCaretToEnd,
	backspaceCaretToStart = editCommandM.deleteCaretToStart,
	typeTab = editCommandM.typeTab,
	typeUntab = editCommandM.typeUntab,
	typeLineFeed = editCommandM.typeLineFeed,
	typeLineFeedWithAutoIndent = editCommandM.typeLineFeedWithAutoIndent,
	selectAll = editCommandM.highlightAll,
	selectCurrentWord = editCommandM.highlightCurrentWord,
	cut = editCommandM.cut,
	copy = editCommandM.copy,
	paste = editCommandM.paste,
	toggleReplaceMode = editCommandM.toggleReplaceMode,
	undo = editCommandM.undo,
	redo = editCommandM.redo
}
