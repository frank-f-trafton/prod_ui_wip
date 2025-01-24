-- WIMP frame outline.

return {
	skinner_id = "wimp/window_frame",

	-- Begin settings
	frame_render_shadow = "*wimp/frame_render_shadow",
	header_button_side = "*wimp/header_button_side",
	header_enable_close_button = "*wimp/header_enable_close_button",
	header_enable_size_button = "*wimp/header_enable_size_button",
	header_show_close_button = "*wimp/header_show_close_button",
	header_show_size_button = "*wimp/header_show_size_button",
	header_text = "*wimp/header_text",
	header_size = "*wimp/header_size",
	-- End settings

	box = "*style/boxes/wimp_frame",

	slc_body = "*tex_slices/window_body",
	slc_shadow = "*tex_slices/window_shadow",

	tex_max = "*tex_quads/window_graphic_maximize",
	tex_unmax = "*tex_quads/window_graphic_unmaximize",
	tex_close = "*tex_quads/window_graphic_close",

	header_text_align_h = "*wimp/header_text_align_h",
	header_text_align_v = "*wimp/header_text_align_v",
	sensor_resize_pad = "*wimp/frame_resize_pad",
	shadow_extrude = 8,

	color_body = {1.0, 1.0, 1.0, 1.0},
	color_shadow = {1.0, 1.0, 1.0, 1.0},

	res_normal = {
		-- Which rectangle to use for fitting the header.
		-- false: 'self.w', 'self.h'
		-- number: a corresponding viewport.
		viewport_fit = 2,
		header_box = "*style/boxes/wimp_frame_header_normal",
		header_slc_body = "*tex_slices/window_header_normal",
		header_font = "*fonts/h4",
		header_h = 32,
		button_pad_w = 2,
		button_w = 30,
		button_h = 28,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0}
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0}
		}
	},

	res_small = {
		viewport_fit = 2,
		header_box = "*style/boxes/wimp_frame_header_small",
		header_slc_body = "*tex_slices/window_header_small",
		header_font = "*fonts/small",
		header_h = 18,
		button_pad_w = 2,
		button_w = 30,
		button_h = 14,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0}

		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0}
		}
	},

	res_large = {
		viewport_fit = 2,
		header_box = "*style/boxes/wimp_frame_header_large",
		header_slc_body = "*tex_slices/window_header_large",
		header_font = "*fonts/h3",
		header_h = 48,
		button_pad_w = 2,
		button_w = 40,
		button_h = 46,
		button_align_v = 0.5, -- from 0 (top) to 1 (bottom)

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0}
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0}
		}
	},
}
