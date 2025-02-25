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
			-- When clicking off of a pop-up menu, stops the user from clicking
			-- any other widget that is behind the base menu.
			-- May prevent accidental clicks, though some people (ahem) hate it.
			block_1st_click_out = false,
		},

		window_frame = {
			-- "all" or "active"
			render_shadow = "all",
		},
	}
}
