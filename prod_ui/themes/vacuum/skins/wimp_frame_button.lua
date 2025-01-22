-- Buttons that are part of the window frame.


return {
	skinner_id = "skn_button_tquad",

	box = "*style/boxes/button_small",
	label_style = "*style/labels/norm",

	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- Quad alignment within Viewport #1.
	quad_align_h = "center", -- "left", "center", "right"
	quad_align_v = "middle", -- "top", "middle", "bottom"


	res_idle = {
		slice = "*tex_slices/window_header_button",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_hover = {
		slice = "*tex_slices/window_header_button_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_pressed = {
		slice = "*tex_slices/window_header_button_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 1,
	},

	res_disabled = {
		slice = "*tex_slices/window_header_button_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.5, 0.5, 0.5, 1.0},
		label_ox = 0,
		label_oy = 0,
	},
}
