local context = select(1, ...)


local editCommandS = context:getLua("shared/line_ed/s/edit_command_s")
local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")


-- Be careful not to mix the callbacks for single and multi-line code.


return {
	-- single-line
	single = {
		["caret-left"] = editCommandS.caretLeft,
		["caret-left-highlight"] = editCommandS.caretLeftHighlight,

		["caret-right"] = editCommandS.caretRight,
		["caret-right-highlight"] = editCommandS.caretRightHighlight,

		["caret-jump-left"] = editCommandS.caretJumpLeft,
		["caret-jump-left-highlight"] = editCommandS.caretJumpLeftHighlight,

		["caret-jump-right"] = editCommandS.caretJumpRight,
		["caret-jump-right-highlight"] = editCommandS.caretJumpRightHighlight,

		["caret-first"] = editCommandS.caretFirst,
		["caret-first-highlight"] = editCommandS.caretFirstHighlight,

		["caret-last"] = editCommandS.caretLast,
		["caret-last-highlight"] = editCommandS.caretLastHighlight,

		["caret-line-first"] = editCommandS.caretFirst,
		["caret-line-first-highlight"] = editCommandS.caretFirstHighlight,

		["caret-line-last"] = editCommandS.caretLast,
		["caret-line-last-highlight"] = editCommandS.caretLastHighlight,

		["backspace"] = editCommandS.backspace,
		["delete"] = editCommandS.delete,
		["delete-highlighted"] = editCommandS.deleteHighlighted,
		["delete-group"] = editCommandS.deleteGroup,
		["delete-all"] = editCommandS.deleteAll,
		["backspace-group"] = editCommandS.backspaceGroup,
		--["delete-caret-to-line-end"] = editCommandS.deleteCaretToEnd,
		--["backspace-caret-to-line-start"] = editCommandS.deleteCaretToStart,

		-- no "type-tab"
		-- no "type-untab"
		["type-line-feed"] = editCommandS.typeLineFeed,
		["type-line-feed-with-auto-indent"] = editCommandS.typeLineFeed,

		["toggle-replace-mode"] = editCommandS.toggleReplaceMode,
		["select-all"] = editCommandS.highlightAll,
		["select-current-word"] = editCommandS.highlightCurrentWord,
		["cut"] = editCommandS.cut,
		["copy"] = editCommandS.copy,
		["paste"] = editCommandS.paste,
		["undo"] = editCommandS.undo,
		["redo"] = editCommandS.redo
	},
	-- multi-line
	multi = {
		["caret-left"] = editCommandM.caretLeft,
		["caret-left-highlight"] = editCommandM.caretLeftHighlight,

		["caret-right"] = editCommandM.caretRight,
		["caret-right-highlight"] = editCommandM.caretRightHighlight,

		["caret-jump-left"] = editCommandM.caretJumpLeft,
		["caret-jump-left-highlight"] = editCommandM.caretJumpLeftHighlight,

		["caret-jump-right"] = editCommandM.caretJumpRight,
		["caret-jump-right-highlight"] = editCommandM.caretJumpRightHighlight,

		["caret-first"] = editCommandM.caretFirst,
		["caret-first-highlight"] = editCommandM.caretFirstHighlight,

		["caret-last"] = editCommandM.caretLast,
		["caret-last-highlight"] = editCommandM.caretLastHighlight,

		["caret-line-first"] = editCommandM.caretLineFirst,
		["caret-line-first-highlight"] = editCommandM.caretLineFirstHighlight,

		["caret-line-last"] = editCommandM.caretLineLast,
		["caret-line-last-highlight"] = editCommandM.caretLineLastHighlight,

		["caret-step-up"] = editCommandM.caretStepUp,
		["caret-step-up-highlight"] = editCommandM.caretStepUpHighlight,

		["caret-step-down"] = editCommandM.caretStepDown,
		["caret-step-down-highlight"] = editCommandM.caretStepDownHighlight,

		--["caret-step-up-core-line"] = editCommandM.caretStepUpCoreLine,
		--["caret-step-up-core-line-highlight"] = editCommandM.caretStepUpCoreLineHighlight,

		--["caret-step-down-core-line"] = editCommandM.caretStepDownCoreLine,
		--["caret-step-down-core-line-highlight"] = editCommandM.caretStepDownCoreLineHighlight,

		["caret-page-up"] = editCommandM.caretPageUp,
		["caret-page-up-highlight"] = editCommandM.caretPageUpHighlight,

		["caret-page-down"] = editCommandM.caretPageDown,
		["caret-page-down-highlight"] = editCommandM.caretPageDownHighlight,

		--["shift-lines-up"] = editCommandM.shiftLinesUp,
		--["shift-lines-down"] = editCommandM.shiftLinesDown,

		["backspace"] = editCommandM.backspace,
		["delete"] = editCommandM.delete,
		["delete-highlighted"] = editCommandM.deleteHighlighted,
		["delete-group"] = editCommandM.deleteGroup,
		["delete-all"] = editCommandM.deleteAll,
		["backspace-group"] = editCommandM.backspaceGroup,
		--["delete-caret-to-line-end"] = editCommandM.deleteCaretToLineEnd,
		--["backspace-caret-to-line-start"] = editCommandM.deleteCaretToLineStart,

		["type-tab"] = editCommandM.typeTab,
		["type-untab"] = editCommandM.typeUntab,
		["type-line-feed"] = editCommandM.typeLineFeed,
		["type-line-feed-with-auto-indent"] = editCommandM.typeLineFeed, -- (not editCommandM.typeLineFeedWithAutoIndent)

		["toggle-replace-mode"] = editCommandM.toggleReplaceMode,
		["select-all"] = editCommandM.highlightAll,
		["select-current-word"] = editCommandM.highlightCurrentWord,
		["cut"] = editCommandM.cut,
		["copy"] = editCommandM.copy,
		["paste"] = editCommandM.paste,
		["undo"] = editCommandM.undo,
		["redo"] = editCommandM.redo
	},
	-- (slightly more) advanced multi-line
	script = {
		["caret-left"] = editCommandM.caretLeft,
		["caret-left-highlight"] = editCommandM.caretLeftHighlight,

		["caret-right"] = editCommandM.caretRight,
		["caret-right-highlight"] = editCommandM.caretRightHighlight,

		["caret-jump-left"] = editCommandM.caretJumpLeft,
		["caret-jump-left-highlight"] = editCommandM.caretJumpLeftHighlight,

		["caret-jump-right"] = editCommandM.caretJumpRight,
		["caret-jump-right-highlight"] = editCommandM.caretJumpRightHighlight,

		["caret-first"] = editCommandM.caretFirst,
		["caret-first-highlight"] = editCommandM.caretFirstHighlight,

		["caret-last"] = editCommandM.caretLast,
		["caret-last-highlight"] = editCommandM.caretLastHighlight,

		["caret-line-first"] = editCommandM.caretLineFirst,
		["caret-line-first-highlight"] = editCommandM.caretLineFirstHighlight,

		["caret-line-last"] = editCommandM.caretLineLast,
		["caret-line-last-highlight"] = editCommandM.caretLineLastHighlight,

		["caret-step-up"] = editCommandM.caretStepUp,
		["caret-step-up-highlight"] = editCommandM.caretStepUpHighlight,

		["caret-step-down"] = editCommandM.caretStepDown,
		["caret-step-down-highlight"] = editCommandM.caretStepDownHighlight,

		["caret-step-up-core-line"] = editCommandM.caretStepUpCoreLine,
		["caret-step-up-core-line-highlight"] = editCommandM.caretStepUpCoreLineHighlight,

		["caret-step-down-core-line"] = editCommandM.caretStepDownCoreLine,
		["caret-step-down-core-line-highlight"] = editCommandM.caretStepDownCoreLineHighlight,

		["caret-page-up"] = editCommandM.caretPageUp,
		["caret-page-up-highlight"] = editCommandM.caretPageUpHighlight,

		["caret-page-down"] = editCommandM.caretPageDown,
		["caret-page-down-highlight"] = editCommandM.caretPageDownHighlight,

		["shift-lines-up"] = editCommandM.shiftLinesUp,
		["shift-lines-down"] = editCommandM.shiftLinesDown,

		["backspace"] = editCommandM.backspace,
		["delete"] = editCommandM.delete,
		["delete-highlighted"] = editCommandM.deleteHighlighted,
		["delete-group"] = editCommandM.deleteGroup,
		["delete-all"] = editCommandM.deleteAll,
		["backspace-group"] = editCommandM.backspaceGroup,
		["delete-caret-to-line-end"] = editCommandM.deleteCaretToLineEnd,
		["backspace-caret-to-line-start"] = editCommandM.deleteCaretToLineStart,

		["type-tab"] = editCommandM.typeTab,
		["type-untab"] = editCommandM.typeUntab,
		["type-line-feed"] = editCommandM.typeLineFeed,
		["type-line-feed-with-auto-indent"] = editCommandM.typeLineFeedWithAutoIndent,

		["toggle-replace-mode"] = editCommandM.toggleReplaceMode,
		["select-all"] = editCommandM.highlightAll,
		["select-current-word"] = editCommandM.highlightCurrentWord,
		["cut"] = editCommandM.cut,
		["copy"] = editCommandM.copy,
		["paste"] = editCommandM.paste,
		["undo"] = editCommandM.undo,
		["redo"] = editCommandM.redo
	}
}
