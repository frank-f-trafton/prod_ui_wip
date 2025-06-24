return {
	skinner_id = "base/slider_bar",

	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/atlas/pixel",

	-- NOTE: this default skin isn't really designed to accommodate labels.
	label_spacing = 0,
	label_placement = "left",

	trough_breadth = 1,
	trough_breadth2 = 4,

	trough_click_anywhere = true,

	thumb_w = 24,
	thumb_h = 24,

	thumb_ox = 12,
	thumb_oy = 12,

	trough_ext = 12,

	cursor_on = "hand",
	cursor_press = "hand",

	label_align_h = "center",
	label_align_v = "middle",

	res_idle = {
		tq_thumb = "*quads/atlas/slider_thumb1", -- XXX make some variations for hover, press, disabled
		sl_trough_active = "*slices/atlas/slider_trough_active",
		sl_trough_empty = "*slices/atlas/slider_trough_empty",

		color_label = {1.0, 1.0, 1.0, 1.0},

		label_ox = 0,
		label_oy = 0,
	},

	res_hover = {
		tq_thumb = "*quads/atlas/slider_thumb1",
		sl_trough_active = "*slices/atlas/slider_trough_active",
		sl_trough_empty = "*slices/atlas/slider_trough_empty",

		color_label = {1.0, 1.0, 1.0, 1.0},

		label_ox = 0,
		label_oy = 0,
	},

	res_pressed = {
		tq_thumb = "*quads/atlas/slider_thumb1",
		sl_trough_active = "*slices/atlas/slider_trough_active",
		sl_trough_empty = "*slices/atlas/slider_trough_empty",

		color_label = {0.9, 0.9, 0.9, 1.0},

		label_ox = 0,
		label_oy = 0,
	},

	res_disabled = {
		tq_thumb = "*quads/atlas/slider_thumb1",
		sl_trough_active = "*slices/atlas/slider_trough_active",
		sl_trough_empty = "*slices/atlas/slider_trough_empty",

		color_label = {0.5, 0.5, 0.5, 1.0},

		label_ox = 0,
		label_oy = 0,
	},
}
