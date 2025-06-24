return {
	skinner_id = "wimp/button_split",

	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/atlas/pixel",

	cursor_on = "hand",
	cursor_press = "hand",

	label_align_h = "center",
	label_align_v = "middle",

	-- graphic =

	tq_aux_glyph = "*quads/atlas/arrow_down",

	aux_placement = "right",
	aux_size = 28,

	quad_align_h = "center",
	quad_align_v = "middle",

	graphic_placement = "overlay",
	graphic_spacing = 0,

	res_idle = {
		slice = "*slices/atlas/button",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		color_aux_icon = {1.0, 1.0, 1.0, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_hover = {
		slice = "*slices/atlas/button_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		color_aux_icon = {1.0, 1.0, 1.0, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_pressed = {
		slice = "*slices/atlas/button_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		color_aux_icon = {1.0, 1.0, 1.0, 1.0},
		label_ox = 0,
		label_oy = 1,
	},

	res_disabled = {
		slice = "*slices/atlas/button_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		color_aux_icon = {0.5, 0.5, 0.5, 1.0},
		label_ox = 0,
		label_oy = 0,
	},
}
