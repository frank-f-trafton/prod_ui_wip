return {
	skinner_id = "wimp/embed/checkbox",

	box = "*/boxes/button_bijou",
	tq_px = "*/quads/atlas/pixel",

	cursor_on = "hand",
	cursor_press = "hand",

	bijou_w = 24,
	bijou_h = 24,

	bijou_align_h = 0.5,
	bijou_align_v = 0.5,

	res_idle = {
		quad_checked = "*/quads/atlas/checkbox_on",
		quad_unchecked = "*/quads/atlas/checkbox_off",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
	},

	res_hover = {
		quad_checked = "*/quads/atlas/checkbox_on_hover",
		quad_unchecked = "*/quads/atlas/checkbox_off_hover",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
	},

	res_pressed = {
		quad_checked = "*/quads/atlas/checkbox_on_press",
		quad_unchecked = "*/quads/atlas/checkbox_off_press",

		color_bijou = {0.7, 0.7, 0.7, 1.0},
	},

	res_disabled = {
		quad_checked = "*/quads/atlas/checkbox_on",
		quad_unchecked = "*/quads/atlas/checkbox_off",

		color_bijou = {0.5, 0.5, 0.5, 1.0},
	},
}
