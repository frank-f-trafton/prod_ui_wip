-- This skin provides graphics for checkbox states 1-3.
return {
	skinner_id = "base/checkbox_multi",

	box = "*boxes/button_bijou",
	label_style = "*labels/norm",
	tq_px = "*quads/pixel",

	default_height = 32,

	cursor_on = "hand",
	cursor_press = "hand",

	bijou_w = 24,
	bijou_h = 24,

	bijou_spacing = 40,

	bijou_side_h = "left",

	bijou_align_h = 0.5,
	bijou_align_v = 0.5,

	label_align_h = "left",
	label_align_v = 0.5,

	res_idle = {
		quads_state = {
			"*quads/checkbox_off",
			"*quads/checkbox_tri",
			"*quads/checkbox_on"
		},

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_hover = {
		quads_state = {
			"*quads/checkbox_off_hover",
			"*quads/checkbox_tri_hover",
			"*quads/checkbox_on_hover"
		},

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_pressed = {
		quads_state = {
			"*quads/checkbox_off_press",
			"*quads/checkbox_tri_press",
			"*quads/checkbox_on_press"
		},

		color_bijou = {0.7, 0.7, 0.7, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_disabled = {
		quads_state = {
			"*quads/checkbox_off",
			"*quads/checkbox_tri",
			"*quads/checkbox_on"
		},

		color_bijou = {0.5, 0.5, 0.5, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		label_ox = 0,
		label_oy = 0,
	},
}
