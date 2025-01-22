-- * Widget skin: Embedded checkbox.

return {
	skinner_id = "wimp/embed/checkbox",

	box = "*style/boxes/button_bijou",
	tq_px = "*tex_quads/pixel",

	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- Checkbox (quad) render size.
	bijou_w = 24,
	bijou_h = 24,

	-- Alignment of bijou within Viewport #1.
	bijou_align_h = 0.5, -- From 0.0 (left) to 1.0 (right)
	bijou_align_v = 0.5, -- From 0.0 (top) to 1.0 (bottom)

	res_idle = {
		quad_checked = "*tex_quads/checkbox_on",
		quad_unchecked = "*tex_quads/checkbox_off",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
	},

	res_hover = {
		quad_checked = "*tex_quads/checkbox_on_hover",
		quad_unchecked = "*tex_quads/checkbox_off_hover",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
	},

	res_pressed = {
		quad_checked = "*tex_quads/checkbox_on_press",
		quad_unchecked = "*tex_quads/checkbox_off_press",

		color_bijou = {0.7, 0.7, 0.7, 1.0},
	},

	res_disabled = {
		quad_checked = "*tex_quads/checkbox_on",
		quad_unchecked = "*tex_quads/checkbox_off",

		color_bijou = {0.5, 0.5, 0.5, 1.0},
	},
}