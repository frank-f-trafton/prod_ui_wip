-- Chart (column) menu.


return {
	skinner_id = "wimp/menu_tab",

	box = "*boxes/panel",
	tq_px = "*tex_quads/pixel",
	data_scroll = "*common/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm",
	font = "*fonts/p",
	data_icon = "*icons/p",

	color_background = {0.2, 0.2, 0.2, 1.0},
	color_item_text = {1.0, 1.0, 1.0, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},
	color_hover_glow = {1.0, 1.0, 1.0, 0.16},
	color_column_sep = {1.0, 1.0, 1.0, 0.125},

	color_drag_col_bg = {0.2, 0.2, 0.2, 0.85},

	column_sep_width = 1,

	-- Some default data for cell implementations.
	color_cell_bijou = {1.0, 1.0, 1.0, 1.0},
	color_cell_text = {1.0, 1.0, 1.0, 1.0},
	cell_font = "*fonts/p",

	bar_height = 32,
	col_sep_line_width = 1,
	bijou_w = 12,
	bijou_h = 12,

	color_body = {0.25, 0.25, 0.25, 1.0},
	color_col_sep = {0.4, 0.4, 0.4, 1.0}, -- vertical separator between columns
	color_body_sep = {0.4, 0.4, 0.4, 1.0}, -- a line between the header body and rest of widget

	tq_arrow_up = "*tex_quads/arrow2_up",
	tq_arrow_down = "*tex_quads/arrow2_down",

	-- Padding between:
	-- * Category panel left and label text
	-- * Category panel right and sorting badge
	category_h_pad = 4,

	res_column_idle = {
		sl_body = "*tex_slices/tabular_category_body",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.8, 0.8, 0.8, 1.0},
		offset_x = 0,
		offset_y = 0
	},

	res_column_hover = {
		sl_body = "*tex_slices/tabular_category_body_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		offset_x = 0,
		offset_y = 0
	},

	res_column_press = {
		sl_body = "*tex_slices/tabular_category_body_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {1.0, 1.0, 1.0, 1.0},
		offset_x = 0,
		offset_y = 1
	}
}
