return {
	skinner_id = "base/stepper",

	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/pixel",

	default_height = 40,

	cursor_on = "hand",
	cursor_press = "hand",

	label_align_h = "center",
	label_align_v = "middle",

	gfx_prev_align_h = "center",
	gfx_prev_align_v = "middle",

	gfx_next_align_h = "center",
	gfx_next_align_v = "middle",

	prev_spacing = 40,
	next_spacing = 40,

	res_idle = {
		sl_body = "*slices/stepper_body",
		sl_button_up = "*slices/button",
		sl_button = "*slices/button",
		tq_left = "*quads/arrow2_left",
		tq_right = "*quads/arrow2_right",
		tq_up = "*quads/arrow2_up",
		tq_down = "*quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		button_ox = 0,
		button_oy = 0,
	},

	res_hover = {
		sl_body = "*slices/stepper_body",
		sl_button_up = "*slices/button_hover",
		sl_button = "*slices/button_hover",
		tq_left = "*quads/arrow2_left",
		tq_right = "*quads/arrow2_right",
		tq_up = "*quads/arrow2_up",
		tq_down = "*quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		button_ox = 0,
		button_oy = 0,
	},

	res_pressed = {
		sl_body = "*slices/stepper_body",
		sl_button_up = "*slices/button_hover",
		sl_button = "*slices/button_press",
		tq_left = "*quads/arrow2_left",
		tq_right = "*quads/arrow2_right",
		tq_up = "*quads/arrow2_up",
		tq_down = "*quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		button_ox = 0,
		button_oy = 1,
	},

	res_disabled = {
		sl_body = "*slices/stepper_body",
		sl_button_up = "*slices/button_disabled",
		sl_button = "*slices/button_disabled",
		tq_left = "*quads/arrow2_left",
		tq_right = "*quads/arrow2_right",
		tq_up = "*quads/arrow2_up",
		tq_down = "*quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		button_ox = 0,
		button_oy = 0,
	},
}
