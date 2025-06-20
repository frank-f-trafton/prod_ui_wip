return {
	tquad_pixel = "*/quads/atlas/pixel",
	tq_arrow_down = "*/quads/atlas/arrow2_down",
	tq_arrow_up = "*/quads/atlas/arrow2_up",
	tq_arrow_left = "*/quads/atlas/arrow2_left",
	tq_arrow_right = "*/quads/atlas/arrow2_right",

	-- This might be helpful if the buttons and trough do not fit snugly into the scroll bar's rectangular body.
	render_body = false,

	body_color = {0.1, 0.1, 0.1, 1.0},
	col_trough = {0.1, 0.1, 0.1, 1.0},

	-- In this implementation, the thumb and buttons share slices and colors for idle, hover and press states.
	shared = {
		idle = {
			slice = "*/slices/atlas/scroll_button",
			col_body = {1.0, 1.0, 1.0, 1.0},
			col_symbol = {0.65, 0.65, 0.65, 1.0},
		},
		hover = {
			slice = "*/slices/atlas/scroll_button_hover",
			col_body = {1.0, 1.0, 1.0, 1.0},
			col_symbol = {0.75, 0.75, 0.75, 1.0},
		},
		press = {
			slice = "*/slices/atlas/scroll_button_press",
			col_body = {1.0, 1.0, 1.0, 1.0},
			col_symbol = {0.3, 0.3, 0.3, 1.0},
		},
		disabled = {
			slice = "*/slices/atlas/scroll_button_disabled",
			col_body = {0.5, 0.5, 0.5, 1.0},
			col_symbol = {0.1, 0.1, 0.1, 1.0},
		},
	}
}
