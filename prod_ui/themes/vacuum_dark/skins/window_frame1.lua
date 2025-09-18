return {
	skinner_id = "wimp/window_frame",

	box = "*boxes/wimp_frame",
	data_scroll = "*scroll_bar_data/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm",
	sash_style = "*sash_styles/norm",

	in_view_pad_x = 0,
	in_view_pad_y = 0,

	slc_body = "*slices/atlas/win_body",
	slc_shadow = "*slices/atlas/win_shadow",

	header_text_align_h = 0.5,
	header_text_align_v = 0.5,

	sensor_resize_pad = 12,
	sensor_resize_diagonal = 12,
	frame_outbound_limit = 32,

	shadow_extrude = 8,

	sensor_tex_align_h = 0.5,
	sensor_tex_align_v = 0.5,

	color_body = {1.0, 1.0, 1.0, 1.0},
	color_shadow = {1.0, 1.0, 1.0, 1.0},

	res_normal = {
		viewport_fit = 4,
		header_box = "*boxes/wimp_frame_header_normal",
		header_slc_body = "*slices/atlas/winheader_normal",
		header_font = "*fonts/h4",
		header_h = 32,
		button_pad_w = 2,
		button_w = 30,
		button_h = 28,
		button_align_v = 0.5,

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0}
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0}
		},

		btn_close = {
			graphic = "*quads/atlas/wingraphic_normal_close",
		},

		btn_size = {
			graphic = "*quads/atlas/wingraphic_normal_maximize",
			graphic_max = "*quads/atlas/wingraphic_normal_maximize",
			graphic_unmax = "*quads/atlas/wingraphic_normal_unmaximize"
		},

		res_btn_idle = {
			slice = "*slices/atlas/winbutton_normal_idle",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_hover = {
			slice = "*slices/atlas/winbutton_normal_hover",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_pressed = {
			slice = "*slices/atlas/winbutton_normal_press",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 1,
		},

		res_btn_disabled = {
			slice = "*slices/atlas/winbutton_normal_disabled",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.5, 0.5, 0.5, 1.0},
			label_ox = 0,
			label_oy = 0,
		},
	},

	res_small = {
		viewport_fit = 4,
		header_box = "*boxes/wimp_frame_header_small",
		header_slc_body = "*slices/atlas/winheader_small",
		header_font = "*fonts/small",
		header_h = 18,
		button_pad_w = 2,
		button_w = 30,
		button_h = 14,
		button_align_v = 0.5,

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0}

		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0}
		},

		btn_close = {
			graphic = "*quads/atlas/wingraphic_small_close",
		},

		btn_size = {
			graphic = "*quads/atlas/wingraphic_small_maximize",
			graphic_max = "*quads/atlas/wingraphic_small_maximize",
			graphic_unmax = "*quads/atlas/wingraphic_small_unmaximize"
		},

		res_btn_idle = {
			slice = "*slices/atlas/winbutton_small_idle",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_hover = {
			slice = "*slices/atlas/winbutton_small_hover",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_pressed = {
			slice = "*slices/atlas/winbutton_small_press",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 1,
		},

		res_btn_disabled = {
			slice = "*slices/atlas/winbutton_small_disabled",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.5, 0.5, 0.5, 1.0},
			label_ox = 0,
			label_oy = 0,
		}
	},

	res_large = {
		viewport_fit = 4,
		header_box = "*boxes/wimp_frame_header_large",
		header_slc_body = "*slices/atlas/winheader_large",
		header_font = "*fonts/h3",
		header_h = 48,
		button_pad_w = 2,
		button_w = 40,
		button_h = 46,
		button_align_v = 0.5,

		res_selected = {
			col_header_fill = {0.3, 0.3, 0.5, 1.0},
			col_header_text = {1.0, 1.0, 1.0, 1.0}
		},

		res_unselected = {
			col_header_fill = {0.25, 0.25, 0.45, 1.0},
			col_header_text = {0.80, 0.80, 0.80, 1.0}
		},

		btn_close = {
			graphic = "*quads/atlas/wingraphic_large_close",
		},

		btn_size = {
			graphic = "*quads/atlas/wingraphic_large_maximize",
			graphic_max = "*quads/atlas/wingraphic_large_maximize",
			graphic_unmax = "*quads/atlas/wingraphic_large_unmaximize",
		},

		res_btn_idle = {
			slice = "*slices/atlas/winbutton_large_idle",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_hover = {
			slice = "*slices/atlas/winbutton_large_hover",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_pressed = {
			slice = "*slices/atlas/winbutton_large_press",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 1,
		},

		res_btn_disabled = {
			slice = "*slices/atlas/winbutton_large_disabled",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.5, 0.5, 0.5, 1.0},
			label_ox = 0,
			label_oy = 0,
		}
	}
}
