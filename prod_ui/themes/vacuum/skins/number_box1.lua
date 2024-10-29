-- Skin: NumberBox.


return {
	skinner_id = "default",

	["*box"] = "style/boxes/input_box",
	["*font"] = "fonts/p",
	["*font_ghost"] = "fonts/p",

	cursor_on = "ibeam",

	-- Horizontal size of the increment and decrement buttons.
	-- "auto": use Viewport #?'s (XXX) height.
	["$button_spacing"] = 24,

	-- Inc/dec button positioning
	button_placement = "right", -- "left", "right"
	button_alignment = "vertical", -- "horizontal", "vertical"

	text_align = "left", -- "left", "center", "right"

	--color_cursor = {1.0, 1.0, 1.0, 1.0},
	["$caret_w"] = 2,
	color_insert = {1.0, 1.0, 1.0, 1.0},
	--color_replace = {0.75, 0.75, 0.75, 1.0},

	["*tq_inc"] = "tex_quads/ind_increment",
	["*tq_dec"] = "tex_quads/ind_decrement",

	res_idle = {
		["*slice"] = "tex_slices/input_box",
		["*slc_button_up"] = "tex_slices/button_minor",
		["*slc_button_down"] = "tex_slices/button_minor",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_hover = {
		["*slice"] = "tex_slices/input_box_hover",
		["*slc_button_up"] = "tex_slices/button_minor_hover",
		["*slc_button_down"] = "tex_slices/button_minor_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_pressed = {
		["*slice"] = "tex_slices/input_box_hover",
		["*slc_button_up"] = "tex_slices/button_minor_hover",
		["*slc_button_down"] = "tex_slices/button_minor_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_disabled = {
		["*slice"] = "tex_slices/input_box_disabled",
		["*slc_button_up"] = "tex_slices/button_minor_disabled",
		["*slc_button_down"] = "tex_slices/button_minor_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},
}
