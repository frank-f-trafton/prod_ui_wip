return {
	skinner_id = "input/text_box_single",

	box = "*boxes/input_box",
	font = "*fonts/p",
	font_ghost = "*fonts/p",
	ghost_mode = "no-focus",

	default_height = 32,

	cursor_on = "ibeam",
	text_align = "left",
	text_align_v = 0.5,

	res_idle = {
		slice = "*slices/input_box",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_ghost_text = {0.75, 0.75, 0.75, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_insert_not_focused = {0.8, 0.8, 0.8, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		color_caret_replace_not_focused = {0.8, 0.8, 0.8, 1.0},
	},

	res_hover = {
		slice = "*slices/input_box_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_ghost_text = {0.75, 0.75, 0.75, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_insert_not_focused = {0.8, 0.8, 0.8, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		color_caret_replace_not_focused = {0.8, 0.8, 0.8, 1.0},
	},

	res_disabled = {
		slice = "*slices/input_box_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_ghost_text = {0.75, 0.75, 0.75, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_insert_not_focused = {0.8, 0.8, 0.8, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		color_caret_replace_not_focused = {0.8, 0.8, 0.8, 1.0},
	},
}
