-- WIMP frame outline.

return {
	skinner_id = "wimp/window_frame",

	-- settings
	--allow_close
	--allow_drag_move
	--allow_maximize
	--allow_resize
	--header_visible = true,
	header_button_side = "*info/window_frames/header_button_side",
	header_show_close_button = "*info/window_frames/header_show_close_button",
	header_show_max_button = "*info/window_frames/header_show_max_button",
	header_text = "*info/window_frames/header_text",
	header_size = "*info/window_frames/header_size",
	-- /settings

	box = "*boxes/wimp_frame",
	data_scroll = "*scroll_bar_data/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm",

	-- Padding when scrolling to put a widget into view.
	in_view_pad_x = 0,
	in_view_pad_y = 0,

	slc_body = "*slices/atlas/win_body",
	slc_shadow = "*slices/atlas/win_shadow",

	header_text_align_h = "*info/window_frames/header_text_align_h",
	header_text_align_v = "*info/window_frames/header_text_align_v",
	sensor_resize_pad = "*info/window_frames/frame_resize_pad",
	sensor_resize_diagonal = "*info/window_frames/frame_resize_diagonal",
	shadow_extrude = 8,

	-- Alignment of textures within control sensors
	sensor_tex_align_h = 0.5, -- 0.0: left, 0.5: middle, 1.0: right
	sensor_tex_align_v = 0.5, -- 0.0: top, 0.5: middle, 1.0: bottom

	color_body = {1.0, 1.0, 1.0, 1.0},
	color_shadow = {1.0, 1.0, 1.0, 1.0},

	-- * Sash State *

	slc_sash_lr = "*slices/atlas/sash_lr",
	slc_sash_tb = "*slices/atlas/sash_tb",

	sash_breadth = 8,

	-- Reduces the intersection box when checking for the mouse *entering* a sash.
	-- NOTE: overly large values will make the sash unclickable.
	sash_contract_x = 0,
	sash_contract_y = 0,

	-- Increases the intersection box when checking for the mouse *leaving* a sash.
	-- NOTES:
	-- * Overly large values will prevent the user from clicking on widgets that
	--   are descendants of the divider.
	-- * The expansion does not go beyond the divider's body.
	sash_expand_x = 2,
	sash_expand_y = 2,

	cursor_sash_hover_h = "sizewe",
	cursor_sash_hover_v = "sizens",

	cursor_sash_drag_h = "sizewe",
	cursor_sash_drag_v = "sizens",

	-- * / Sash State *

	res_normal = {
		-- Which rectangle to use for fitting the header.
		-- false: 'self.w', 'self.h'
		-- number: a corresponding viewport.
		viewport_fit = 4,
		header_box = "*boxes/wimp_frame_header_normal",
		header_slc_body = "*slices/atlas/winheader_normal",
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
