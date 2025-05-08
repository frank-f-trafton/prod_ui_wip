-- Skin: Single-line text input box.


return {
	skinner_id = "input/text_box_single",

	box = "*boxes/input_box",
	font = "*fonts/p",
	font_ghost = "*fonts/p",

	cursor_on = "ibeam",
	text_align = "left", -- "left", "center", "right"

	res_idle = {
		slice = "*slices/atlas/input_box",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
	},

	res_hover = {
		slice = "*slices/atlas/input_box_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
	},

	res_disabled = {
		slice = "*slices/atlas/input_box_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
	},
}
