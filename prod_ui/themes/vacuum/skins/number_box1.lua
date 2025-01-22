-- Skin: NumberBox.


return {
	skinner_id = "default",

	box = "*style/boxes/input_box",
	font = "*fonts/p",
	font_ghost = "*fonts/p",

	cursor_on = "ibeam",
	text_align = "right", -- "left", "center", "right"

	-- Horizontal size of the increment and decrement buttons.
	-- "auto": use Viewport #?'s (XXX) height.
	["$button_spacing"] = 24,

	-- Inc/dec button positioning
	button_placement = "right", -- "left", "right"
	button_alignment = "vertical", -- "horizontal", "vertical"

	res_idle = {
		slice = "*tex_slices/input_box",
		slc_button_inc = "*tex_slices/button_minor",
		slc_button_dec = "*tex_slices/button_minor",
		tq_inc = "*tex_quads/ind_increment",
		tq_dec = "*tex_quads/ind_decrement",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_hover = {
		slice = "*tex_slices/input_box_hover",
		slc_button_inc = "*tex_slices/button_minor_hover",
		slc_button_dec = "*tex_slices/button_minor_hover",
		tq_inc = "*tex_quads/ind_increment",
		tq_dec = "*tex_quads/ind_decrement",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_pressed = {
		slice = "*tex_slices/input_box_hover",
		slc_button_inc = "*tex_slices/button_minor_press",
		slc_button_dec = "*tex_slices/button_minor_press",
		tq_inc = "*tex_quads/ind_increment",
		tq_dec = "*tex_quads/ind_decrement",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 1,
	},

	res_disabled = {
		slice = "*tex_slices/input_box_disabled",
		slc_button_inc = "*tex_slices/button_minor_disabled",
		slc_button_dec = "*tex_slices/button_minor_disabled",
		tq_inc = "*tex_quads/ind_increment",
		tq_dec = "*tex_quads/ind_decrement",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},
}
