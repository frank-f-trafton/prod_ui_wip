-- Wrappable command functions that are suitable to use with key bindings.
-- Such functions do not take arguments (besides 'self').


local context = select(1, ...)


local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")


return {
	["caret-left"] = editCommandM.caretLeft,
	["caret-right"] = editCommandM.caretRight,
	["caret-left-highlight"] = editCommandM.caretLeftHighlight,
	["caret-right-highlight"] = editCommandM.caretRightHighlight,
	["caret-jump-left"] = editCommandM.caretJumpLeft,
	["caret-jump-right"] = editCommandM.caretJumpRight,
	["caret-jump-left-highlight"] = editCommandM.caretJumpLeftHighlight,
	["caret-jump-right-highlight"] = editCommandM.caretJumpRightHighlight,
	["caret-first"] = editCommandM.caretFirst,
	["caret-last"] = editCommandM.caretLast,
	["caret-first-highlight"] = editCommandM.caretFirstHighlight,
	["caret-last-highlight"] = editCommandM.caretLastHighlight,
	["caret-step-up"] = editCommandM.caretStepUp,
	["caret-step-down"] = editCommandM.caretStepDown,
	["caret-page-up"] = editCommandM.caretPageUp,
	["caret-page-down"] = editCommandM.caretPageDown,
	["caret-page-up-highlight"] = editCommandM.caretPageUpHighlight,
	["caret-page-down-highlight"] = editCommandM.caretPageDownHighlight,
	["caret-step-up-highlight"] = editCommandM.caretStepUpHighlight,
	["caret-step-down-highlight"] = editCommandM.caretStepDownHighlight,
	["shift-lines-up"] = editCommandM.shiftLinesUp,
	["shift-lines-down"] = editCommandM.shiftLinesDown,
	["caret-line-first"] = editCommandM.caretLineFirst,
	["caret-line-last"] = editCommandM.caretLineLast,
	["caret-line-first-highlight"] = editCommandM.caretLineFirstHighlight,
	["caret-line-last-highlight"] = editCommandM.caretLineLastHighlight,
	["backspace"] = editCommandM.backspace,
	["delete"] = editCommandM.delete,
	["delete-highlighted"] = editCommandM.deleteHighlighted,
	["delete-group"] = editCommandM.deleteGroup,
	["delete-all"] = editCommandM.deleteAll,
	["backspace-group"] = editCommandM.backspaceGroup,
	["delete-caret-to-end"] = editCommandM.deleteCaretToEnd,
	["backspace-caret-to-start"] = editCommandM.deleteCaretToStart,
	["type-tab"] = editCommandM.typeTab,
	["type-untab"] = editCommandM.typeUntab,
	["type-line-feed"] = editCommandM.typeLineFeed,
	["type-line-feed-with-auto-indent"] = editCommandM.typeLineFeedWithAutoIndent,
	["select-all"] = editCommandM.highlightAll,
	["select-current-word"] = editCommandM.highlightCurrentWord,
	["cut"] = editCommandM.cut,
	["copy"] = editCommandM.copy,
	["paste"] = editCommandM.paste,
	["toggle-replace-mode"] = editCommandM.toggleReplaceMode,
	["undo"] = editCommandM.undo,
	["redo"] = editCommandM.redo
}
