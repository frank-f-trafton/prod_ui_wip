return {
	skinner_id = "wimp/menu_pop",

	box = "*boxes/panel",
	icon_set_id = "bureau",
	font_item = "*fonts/p",
	slc_body = "*slices/menu_pop_body",
	tq_px = "*quads/pixel",
	tq_arrow = "*quads/arrow_right",

	separator_item_height = 4,
	separator_graphic_height = 1,

	underline_width = 1,

	pad_x1 = 0,
	pad_x2 = 18,

	pad_icon_x1 = 0,
	pad_icon_x2 = 0,
	pad_icon_y1 = 2,
	pad_icon_y2 = 2,

	icon_draw_w = 24,
	icon_draw_h = 24,

	pad_text_x1 = 6,
	pad_text_x2 = 0,
	pad_text_y1 = 4,
	pad_text_y2 = 4,

	arrow_draw_w = 24,
	arrow_draw_h = 24,

	pad_shortcut_x1 = 16,
	pad_shortcut_x2 = 0,

	color_separator = {0.125, 0.125, 0.125, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.5},

	res_actionable_selected = {
		col_icon = {1.0, 1.0, 1.0, 1.0},
		col_label = {0.0, 0.0, 0.0, 1.0},
		col_shortcut = {0.0, 0.0, 0.0, 1.0},
		col_arrow = {0.0, 0.0, 0.0, 1.0},
	},

	res_actionable_unselected = {
		col_icon = {1.0, 1.0, 1.0, 1.0},
		col_label = {1.0, 1.0, 1.0, 1.0},
		col_shortcut = {0.8, 0.8, 0.8, 1.0},
		col_arrow = {1.0, 1.0, 1.0, 1.0},
	},

	res_inactionable_selected = {
		col_icon = {0.35, 0.35, 0.35, 1.0},
		col_label = {0.35, 0.35, 0.35, 1.0},
		col_shortcut = {0.35, 0.35, 0.35, 1.0},
		col_arrow = {0.35, 0.35, 0.35, 1.0},
	},

	res_inactionable_unselected = {
		col_icon = {0.5, 0.5, 0.5, 1.0},
		col_label = {0.5, 0.5, 0.5, 1.0},
		col_shortcut = {0.5, 0.5, 0.5, 1.0},
		col_arrow = {0.5, 0.5, 0.5, 1.0},
	},
}
