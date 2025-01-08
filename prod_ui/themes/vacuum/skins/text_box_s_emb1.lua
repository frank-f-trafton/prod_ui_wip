-- * Widget skin: Embedded single-line text input box.

return {
	skinner_id = "default",

	["*box"] = "style/boxes/input_box",
	["*font"] = "fonts/p",
	["*font_ghost"] = "fonts/p",

	cursor_on = "ibeam",
	text_align = "left", -- "left", "center", "right"

	res_idle = {
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
	},

	res_hover = {
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
	},

	res_disabled = {
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
	},
}
