-- * Widget skin: Application checkbox with configurable multiple states.

--[[
This skin provides graphics for states 1-3.
--]]

return {
	skinner_id = "default",

	box = "*style/boxes/button_bijou",
	label_style = "*style/labels/norm",
	tq_px = "*tex_quads/pixel",

	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- Checkbox (quad) render size.
	["$bijou_w"] = 24,
	["$bijou_h"] = 24,

	-- Horizontal spacing between checkbox area and text label.
	["$bijou_spacing"] = 40,

	-- Checkbox horizontal placement.
	bijou_side = "left", -- left (default), right

	-- Alignment of bijou within Viewport #2.
	bijou_align_h = 0.5, -- From 0.0 (left) to 1.0 (right)
	bijou_align_v = 0.5, -- From 0.0 (top) to 1.0 (bottom)

	-- Alignment of label text within Viewport #1.
	label_align_h = "left", -- "left", "center", "right", "justify"
	label_align_v = 0.5, -- From 0.0 (top) to 1.0 (bottom)


	res_idle = {
		quads_state = {
			"*tex_quads/checkbox_off",
			"*tex_quads/checkbox_tri",
			"*tex_quads/checkbox_on"
		},

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_hover = {
		quads_state = {
			"*tex_quads/checkbox_off_hover",
			"*tex_quads/checkbox_tri_hover",
			"*tex_quads/checkbox_on_hover"
		},

		color_bijou = {1.0, 1.0, 1.0, 1.0},
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_pressed = {
		quads_state = {
			"*tex_quads/checkbox_off_press",
			"*tex_quads/checkbox_tri_press",
			"*tex_quads/checkbox_on_press"
		},

		color_bijou = {0.7, 0.7, 0.7, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_disabled = {
		quads_state = {
			"*tex_quads/checkbox_off",
			"*tex_quads/checkbox_tri",
			"*tex_quads/checkbox_on"
		},

		color_bijou = {0.5, 0.5, 0.5, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},
}
