--[[
The default application-wide configuration for ProdUI.
--]]

return {
	wimp = {
		key_bindings = {
			close_window_frame = "C+w",
		},

		navigation = {
			-- Scroll animation parameters. See: widShared.scrollTargetUpdate()
			scroll_snap = 1,
			scroll_speed_min = 800,
			scroll_speed_mul = 8.0,

			-- How many pixels to scroll in WIMP widgets when pressing the arrow
			-- keys.
			key_scroll_h = 32,

			-- How many pixels to scroll per one discrete mouse-wheel motion event.
			-- XXX: SDL3 / LÖVE 12 is changing this to distance scrolled.
			-- XXX: for now, this is also used with horizontal wheel movement. As of
			-- this writing, I don't have a mouse with a horizontal wheel.
			mouse_wheel_move_size_v = 64,

			-- How much of a "page" to jump when pressing pageup or pagedown in a
			-- menu. 1.0 is one whole span of the viewport, 0.5 is half, etc.
			page_viewport_factor = 1.0,
		},

		pop_up_menu = {
			-- When clicking outside of a pop-up menu, this stops the user from clicking
			-- any other widget that is behind the base menu.
			-- May prevent accidental clicks, though some people (ahem) hate it.
			block_1st_click_out = false,
		},

		window_frame = {
			-- "all" or "active"
			render_shadow = "all",
		},

		menu_bar = {
			-- Draw shortcut underlines: "never", "when-active", "always"
			-- "when-active" == when a menu bar drawer is open, or the user is holding the 'alt' key.
			draw_underlines = "always",
		},

		text_input = {
			--[[
			NOTE: holding control prevents love.textinput from firing, but holding alt does not.
			--]]

			-- TODO: MacOS shortcuts.

			commands = {
				{"caret-left", "+left"},
				{"caret-left-highlight", "S+left"},

				{"caret-right", "+right"},
				{"caret-right-highlight", "S+right"},

				{"caret-jump-left", "C+left"},
				{"caret-jump-left-highlight", "CS+left"},

				{"caret-jump-right", "C+right"},
				{"caret-jump-right-highlight", "CS+right"},

				{"caret-first", "C+home"},
				{"caret-first-highlight", "CS+home"},

				{"caret-last", "C+end"},
				{"caret-last-highlight", "CS+end"},

				{"caret-line-first", "+home"},
				{"caret-line-first-highlight", "S+home"},

				{"caret-line-last", "+end"},
				{"caret-line-last-highlight", "S+end"},

				{"caret-step-up", "+up"},
				{"caret-step-up-highlight", "S+up"},

				{"caret-step-down", "+down"},
				{"caret-step-down-highlight", "S+down"},

				{"caret-step-up-core-line", "C+up"},
				{"caret-step-up-core-line-highlight", "CS+up"},

				{"caret-step-down-core-line", "C+down"},
				{"caret-step-down-core-line-highlight", "CS+down"},

				{"caret-page-up", "+pageup"},
				{"caret-page-up-highlight", "S+pageup"},

				{"caret-page-down", "+pagedown"},
				{"caret-page-down-highlight", "S+pagedown"},

				{"shift-lines-up", "A+up"},
				{"shift-lines-down", "A+down"},

				{"backspace", "+backspace", "S+backspace"},
				{"delete", "+delete"},
				{"delete-highlighted"},
				{"delete-group", "C+delete"},
				{"delete-line", "C+d"},
				{"delete-all"},
				{"backspace-group", "C+backspace"},
				{"delete-caret-to-line-end", "CS+delete"},
				{"backspace-caret-to-line-start", "CS+backspace"},

				{"type-tab", "+tab"},
				{"type-untab", "S+tab"},
				{"type-line-feed", "S+return", "S+kpenter"},
				{"type-line-feed-with-auto-indent", "+return", "+kpenter"},

				{"toggle-replace-mode", "+insert"},
				{"select-all", "C+a"},
				{"select-current-word"},
				{"cut", "C+x", "S+delete"},
				{"copy", "C+c"},
				{"paste", "C+v"},
				{"undo", "C+z"},
				{"redo", "C+y", "CS+z"},
			},
		}
	}
}
