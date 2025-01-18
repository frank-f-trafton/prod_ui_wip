-- WIMP frame header (normal).


return {
	skinner_id = "default",

	["*box"] = "style/boxes/wimp_frame_header_norm",
	["*slc_body"] = "tex_slices/window_header_norm",

	["*font"] = "fonts/h4",
	["$h"] = 32,
	button_side = "right", -- "left", "right"
	button_align_v = 0.5, -- from 0 (top) to 1 (bottom)
	["$button_pad_w"] = 2,
	["$button_w"] = 30,
	["$button_h"] = 28,

	text_align_h = 0.5, -- From 0 (left) to 1 (right)
	text_align_v = 0.5, -- From 0 (top) to 1 (bottom)

	res_selected = {
		col_fill = {0.3, 0.3, 0.5, 1.0},
		col_text = {1.0, 1.0, 1.0, 1.0},
	},

	res_unselected = {
		col_fill = {0.25, 0.25, 0.45, 1.0},
		col_text = {0.80, 0.80, 0.80, 1.0},
	}
}