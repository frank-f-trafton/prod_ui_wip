-- WIMP frame outline.

return {
	skinner_id = "wimp/window_frame",

	-- settings
	frame_render_shadow = "*wimp/frame_render_shadow",
	--frame_resizable = true,
	header_button_side = "*wimp/header_button_side",
	header_enable_close_button = "*wimp/header_enable_close_button",
	header_enable_size_button = "*wimp/header_enable_size_button",
	header_show_close_button = "*wimp/header_show_close_button",
	header_show_size_button = "*wimp/header_show_size_button",
	header_text = "*wimp/header_text",
	header_size = "*wimp/header_size",
	-- /settings

	box = "*style/boxes/wimp_frame",

	slc_body = "*tex_slices/win_body",
	slc_shadow = "*tex_slices/win_shadow",

	header_text_align_h = "*wimp/header_text_align_h",
	header_text_align_v = "*wimp/header_text_align_v",
	sensor_resize_pad = "*wimp/frame_resize_pad",
	sensor_resize_diagonal = "*wimp/frame_resize_diagonal",
	shadow_extrude = 8,

	-- Alignment of textures within control sensors
	sensor_tex_align_h = 0.5, -- 0.0: left, 0.5: middle, 1.0: right
	sensor_tex_align_v = 0.5, -- 0.0: top, 0.5: middle, 1.0: bottom

	color_body = {1.0, 1.0, 1.0, 1.0},
	color_shadow = {1.0, 1.0, 1.0, 1.0},

	res_normal = {
		-- Which rectangle to use for fitting the header.
		-- false: 'self.w', 'self.h'
		-- number: a corresponding viewport.
		viewport_fit = 2,
		header_box = "*style/boxes/wimp_frame_header_normal",
		header_slc_body = "*tex_slices/winheader_normal",
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
		},

		btn_close = {
			graphic = "*tex_quads/wingraphic_normal_close",
		},

		btn_size = {
			graphic = "*tex_quads/wingraphic_normal_maximize",
			graphic_max = "*tex_quads/wingraphic_normal_maximize",
			graphic_unmax = "*tex_quads/wingraphic_normal_unmaximize"
		},

		res_btn_idle = {
			slice = "*tex_slices/winbutton_normal_idle",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_hover = {
			slice = "*tex_slices/winbutton_normal_hover",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_pressed = {
			slice = "*tex_slices/winbutton_normal_press",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 1,
		},

		res_btn_disabled = {
			slice = "*tex_slices/winbutton_normal_disabled",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.5, 0.5, 0.5, 1.0},
			label_ox = 0,
			label_oy = 0,
		},
	},

	res_small = {
		viewport_fit = 2,
		header_box = "*style/boxes/wimp_frame_header_small",
		header_slc_body = "*tex_slices/winheader_small",
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
		},

		btn_close = {
			graphic = "*tex_quads/wingraphic_small_close",
		},

		btn_size = {
			graphic = "*tex_quads/wingraphic_small_maximize",
			graphic_max = "*tex_quads/wingraphic_small_maximize",
			graphic_unmax = "*tex_quads/wingraphic_small_unmaximize"
		},

		res_btn_idle = {
			slice = "*tex_slices/winbutton_small_idle",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_hover = {
			slice = "*tex_slices/winbutton_small_hover",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_pressed = {
			slice = "*tex_slices/winbutton_small_press",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 1,
		},

		res_btn_disabled = {
			slice = "*tex_slices/winbutton_small_disabled",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.5, 0.5, 0.5, 1.0},
			label_ox = 0,
			label_oy = 0,
		}
	},

	res_large = {
		viewport_fit = 2,
		header_box = "*style/boxes/wimp_frame_header_large",
		header_slc_body = "*tex_slices/winheader_large",
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
		},

		btn_close = {
			graphic = "*tex_quads/wingraphic_large_close",
		},

		btn_size = {
			graphic = "*tex_quads/wingraphic_large_maximize",
			graphic_max = "*tex_quads/wingraphic_large_maximize",
			graphic_unmax = "*tex_quads/wingraphic_large_unmaximize",
		},

		res_btn_idle = {
			slice = "*tex_slices/winbutton_large_idle",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_hover = {
			slice = "*tex_slices/winbutton_large_hover",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 0,
		},

		res_btn_pressed = {
			slice = "*tex_slices/winbutton_large_press",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.9, 0.9, 0.9, 1.0},
			label_ox = 0,
			label_oy = 1,
		},

		res_btn_disabled = {
			slice = "*tex_slices/winbutton_large_disabled",
			color_body = {1.0, 1.0, 1.0, 1.0},
			color_quad = {0.5, 0.5, 0.5, 1.0},
			label_ox = 0,
			label_oy = 0,
		}
	}
}
