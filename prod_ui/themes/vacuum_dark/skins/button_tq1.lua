return {
	skinner_id = "skn_button_tquad",

	box = "*boxes/button",

	cursor_on = "hand",
	cursor_press = "hand",

	-- graphic =

	quad_align_h = "center",
	quad_align_v = "middle",

	graphic_placement = "overlay",
	graphic_spacing = 0,

	res_idle = {
		slice = "*slices/button",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		graphic_ox = 0,
		graphic_oy = 0
	},

	res_hover = {
		slice = "*slices/button_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		graphic_ox = 0,
		graphic_oy = 0
	},

	res_pressed = {
		slice = "*slices/button_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		graphic_ox = 0,
		graphic_oy = 1
	},

	res_disabled = {
		slice = "*slices/button_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.5, 0.5, 0.5, 1.0},
		graphic_ox = 0,
		graphic_oy = 0
	},
}
