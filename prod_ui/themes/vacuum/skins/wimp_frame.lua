-- WIMP frame outline.

return {
	skinner_id = "default",

	["*box"] = "style/boxes/wimp_frame",

	["*slc_body"] = "tex_slices/window_body",
	["*slc_shadow"] = "tex_slices/window_shadow",

	["$shadow_extrude"] = 8,

	color_body = {1.0, 1.0, 1.0, 1.0},
	color_shadow = {1.0, 1.0, 1.0, 1.0},

	["*sensor_resize_pad"] = "wimp/frame_resize_pad",

	-- normal headers
	res_norm = {
		["*header_box"] = "style/boxes/wimp_frame_header_norm",
		["*header_slc_body"] = "tex_slices/window_header_norm",
		["*header_font"] = "fonts/h4",
		["$header_h"] = 32,
		["$button_pad_w"] = 2,
		["$button_w"] = 30,
		["$button_h"] = 28,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0},
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0},
		}
	},

	-- condensed headers
	res_cond = {
		["*header_box"] = "style/boxes/wimp_frame_header_cond",
		["*header_slc_body"] = "tex_slices/window_header_cond",
		["*header_font"] = "fonts/small",
		["$header_h"] = 18,
		["$button_pad_w"] = 2,
		["$button_w"] = 30,
		["$button_h"] = 14,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)

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
