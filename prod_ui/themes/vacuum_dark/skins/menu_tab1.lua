return {
	skinner_id = "wimp/menu_tab",

	box = "*boxes/panel",
	tq_px = "*quads/pixel",
	data_scroll = "*scroll_bar_data/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm",
	font = "*fonts/p",

	default_icon_set_id = "bureau",

	default_height = 80,

	column_min_w = 4,
	column_def_w = 128,
	column_bar_height = 32,

	col_def_text_align = "left",
	content_def_text_align = "left",

	col_arrow_show = true,
	col_arrow_side = "right",

	item_h = 24,

	drag_threshold = 5,
	col_click_threshold = 16,

	column_sep_width = 1,

	cell_font = "*fonts/p",

	cell_icon_side = "left",
	cell_icon_w = 16,
	cell_icon_h = 16,

	header_icon_w = 12,
	header_icon_h = 12,

	tq_arrow_up = "*quads/arrow2_up",
	tq_arrow_down = "*quads/arrow2_down",

	category_h_pad = 4,

	color_header_body = {0.25, 0.25, 0.25, 1.0},
	color_background = {0.2, 0.2, 0.2, 1.0},
	color_item_text = {1.0, 1.0, 1.0, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},
	color_hover_glow = {1.0, 1.0, 1.0, 0.16},
	color_active_glow = {0.75, 0.75, 1.0, 0.33},
	color_column_sep = {1.0, 1.0, 1.0, 0.125},
	color_drag_col_bg = {0.2, 0.2, 0.2, 0.85},
	color_cell_icon = {1.0, 1.0, 1.0, 1.0},
	color_cell_text = {1.0, 1.0, 1.0, 1.0},

	res_column_idle = {
		sl_body = "*slices/tabular_category_body",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.8, 0.8, 0.8, 1.0},
		offset_x = 0,
		offset_y = 0
	},

	res_column_hover = {
		sl_body = "*slices/tabular_category_body_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		offset_x = 0,
		offset_y = 0
	},

	res_column_press = {
		sl_body = "*slices/tabular_category_body_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {1.0, 1.0, 1.0, 1.0},
		offset_x = 0,
		offset_y = 1
	}
}
