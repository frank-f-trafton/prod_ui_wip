-- Header: Draggable bar along the top with optional title and control buttons (max/restore window, close)


return {

	skinner_id = "default",

	["*slc_body"] = "tex_slices/window_header",

	["*font_norm"] = "fonts/h4",
	["*font_cond"] = "fonts/small",

	res_selected = {
		col_fill = {0.3, 0.3, 0.5, 1.0},
		col_text = {1.0, 1.0, 1.0, 1.0},
	},

	res_unselected = {
		col_fill = {0.25, 0.25, 0.45, 1.0},
		col_text = {0.80, 0.80, 0.80, 1.0},
	},
}
