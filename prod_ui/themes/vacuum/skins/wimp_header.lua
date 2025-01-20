-- WIMP frame header.


return {
	skinner_id = "default",

	-- Frames with normal headers.
	res_norm = {
		["*header_box"] = "style/boxes/wimp_frame_header_norm",
		["*header_slc_body"] = "tex_slices/window_header_norm",

		["*header_font"] = "fonts/h4",
		["$header_h"] = 32,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)
		["$button_pad_w"] = 2,
		["$button_w"] = 30,
		["$button_h"] = 28,

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0},
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0},
		}
	},

	-- Frames with condensed headers.
	res_cond = {
		["*header_box"] = "style/boxes/wimp_frame_header_cond",
		["*header_slc_body"] = "tex_slices/window_header_cond",

		["*header_font"] = "fonts/small",
		["$header_h"] = 18,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)
		["$button_pad_w"] = 2,
		["$button_w"] = 30,
		["$button_h"] = 14,

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0},
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0},
		}
	}
}
