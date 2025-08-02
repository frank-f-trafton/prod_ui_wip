-- Wrappable command functions that are suitable to use with key bindings.
-- Such functions do not take arguments (besides 'self').


local context = select(1, ...)


local editCommandS = context:getLua("shared/line_ed/s/edit_command_s")


return {
	["caret-left"] = editCommandS.caretLeft,
	["caret-right"] = editCommandS.caretRight,
	["caret-left-highlight"] = editCommandS.caretLeftHighlight,
	["caret-right-highlight"] = editCommandS.caretRightHighlight,
	["caret-jump-left"] = editCommandS.caretJumpLeft,
	["caret-jump-right"] = editCommandS.caretJumpRight,
	["caret-jump-left-highlight"] = editCommandS.caretJumpLeftHighlight,
	["caret-jump-right-highlight"] = editCommandS.caretJumpRightHighlight,
	["caret-first"] = editCommandS.caretFirst,
	["caret-last"] = editCommandS.caretLast,
	["caret-first-highlight"] = editCommandS.caretFirstHighlight,
	["caret-last-highlight"] = editCommandS.caretLastHighlight,
	["backspace"] = editCommandS.backspace,
	["delete"] = editCommandS.delete,
	["delete-highlighted"] = editCommandS.deleteHighlighted,
	["delete-group"] = editCommandS.deleteGroup,
	["delete-all"] = editCommandS.deleteAll,
	["backspace-group"] = editCommandS.backspaceGroup,
	["delete-caret-to-end"] = editCommandS.deleteCaretToEnd,
	["backspace-caret-to-start"] = editCommandS.deleteCaretToStart,
	["type-tab"] = editCommandS.typeTab,
	["type-line-feed"] = editCommandS.typeLineFeed,
	["select-all"] = editCommandS.highlightAll,
	["select-current-word"] = editCommandS.highlightCurrentWord,
	["cut"] = editCommandS.cut,
	["copy"] = editCommandS.copy,
	["paste"] = editCommandS.paste,
	["toggle-replace-mode"] = editCommandS.toggleReplaceMode,
	["undo"] = editCommandS.undo,
	["redo"] = editCommandS.redo
}
