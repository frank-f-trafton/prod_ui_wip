-- WIP

-- * Widget skin: Embedded checkbox.

return {
	skinner_id = "default",

	["*box"] = "style/boxes/button_bijou",
	["*tq_px"] = "tex_quads/pixel",

	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- Checkbox (quad) render size.
	["$bijou_w"] = 24,
	["$bijou_h"] = 24,

	-- Alignment of bijou within Viewport #2.
	bijou_align_h = "center", -- "left", "center", "right"
	bijou_align_v = "middle", -- "top", "middle", "bottom"

	-- Alignment of label text within Viewport #1.
	label_align_h = "left", -- "left", "center", "right", "justify"
	label_align_v = "middle", -- "top", "middle", "bottom"


	res_idle = {
		["*quad_checked"] = "tex_quads/checkbox_on",
		["*quad_unchecked"] = "tex_quads/checkbox_off",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_hover = {
		["*quad_checked"] = "tex_quads/checkbox_on_hover",
		["*quad_unchecked"] = "tex_quads/checkbox_off_hover",

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_pressed = {
		["*quad_checked"] = "tex_quads/checkbox_on_press",
		["*quad_unchecked"] = "tex_quads/checkbox_off_press",

		color_bijou = {0.7, 0.7, 0.7, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_disabled = {
		["*quad_checked"] = "tex_quads/checkbox_on",
		["*quad_unchecked"] = "tex_quads/checkbox_off",

		color_bijou = {0.5, 0.5, 0.5, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},
}
