return {
	skinner_id = "skn_button_bijou",

	box = "*boxes/button_bijou",
	label_style = "*labels/norm",
	tq_px = "*quads/pixel",

	cursor_on = "hand",
	cursor_press = "hand",

	default_height = 32,

	bijou_w = 24,
	bijou_h = 24,
	bijou_spacing = 40,

	bijou_side_h = "left",

	bijou_align_h = 0.5,
	bijou_align_v = 0.5,

	label_align_h = "left",
	label_align_v = 0.5,

	res_idle = {
		quad_checked = "*quads/radio_on",
		quad_unchecked = "*quads/radio_off",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},

		label_ox = 0,
		label_oy = 0
	},

	res_hover = {
		quad_checked = "*quads/radio_on_hover",
		quad_unchecked = "*quads/radio_off_hover",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},

		label_ox = 0,
		label_oy = 0
	},

	res_pressed = {
		quad_checked = "*quads/radio_on_press",
		quad_unchecked = "*quads/radio_off_press",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},

		label_ox = 0,
		label_oy = 0
	},

	res_disabled = {
		quad_checked = "*quads/radio_on",
		quad_unchecked = "*quads/radio_off",

		color_bijou = {0.5, 0.5, 0.5, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},

		label_ox = 0,
		label_oy = 0
	}
}
