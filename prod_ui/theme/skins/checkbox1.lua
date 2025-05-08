-- * Widget skin: Application checkbox.

return {
	skinner_id = "skn_button_bijou",

	box = "*boxes/button_bijou",
	label_style = "*labels/norm",
	tq_px = "*quads/atlas/pixel",

	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- Checkbox (quad) render size.
	bijou_w = 24,
	bijou_h = 24,

	-- Horizontal spacing between checkbox area and text label.
	bijou_spacing = 40,

	-- Checkbox horizontal placement.
	bijou_side = "left", -- left (default), right

	-- Alignment of bijou within Viewport #2.
	bijou_align_h = 0.5, -- From 0.0 (left) to 1.0 (right)
	bijou_align_v = 0.5, -- From 0.0 (top) to 1.0 (bottom)

	-- Alignment of label text within Viewport #1.
	label_align_h = "left", -- "left", "center", "right", "justify"
	label_align_v = 0.5, -- From 0.0 (top) to 1.0 (bottom)


	res_idle = {
		quad_checked = "*quads/atlas/checkbox_on",
		quad_unchecked = "*quads/atlas/checkbox_off",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0,
	},

	res_hover = {
		quad_checked = "*quads/atlas/checkbox_on_hover",
		quad_unchecked = "*quads/atlas/checkbox_off_hover",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0,
	},

	res_pressed = {
		quad_checked = "*quads/atlas/checkbox_on_press",
		quad_unchecked = "*quads/atlas/checkbox_off_press",

		color_bijou = {0.7, 0.7, 0.7, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0,
	},

	res_disabled = {
		quad_checked = "*quads/atlas/checkbox_on",
		quad_unchecked = "*quads/atlas/checkbox_off",

		color_bijou = {0.5, 0.5, 0.5, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0,
	},
}
