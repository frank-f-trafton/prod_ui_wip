-- Skin: Single-line text input box.


return {

	skinner_id = "default",

	["*box"] = "style/boxes/input_box",
	["*font"] = "fonts/p",

	cursor_on = "ibeam",

	text_align = "left", -- "left", "center", "right"

	color_cursor = {1.0, 1.0, 1.0, 1.0},

	["$caret_w"] = 2,

	color_insert = {1.0, 1.0, 1.0, 1.0},
	color_replace = {0.75, 0.75, 0.75, 1.0},

	res_idle = {
		["*slice"] = "tex_slices/input_box",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
	},

	res_hover = {
		["*slice"] = "tex_slices/input_box_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
	},

	res_disabled = {
		["*slice"] = "tex_slices/input_box_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
	},
}
