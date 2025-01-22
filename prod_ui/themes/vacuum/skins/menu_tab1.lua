-- Chart (column) menu.


return {
	skinner_id = "wimp/menu_tab",

	box = "*style/boxes/panel",
	tq_px = "*tex_quads/pixel",
	data_scroll = "*common/scroll_bar1",
	scr_style = "*style/scroll_bar_styles/norm",
	font = "*fonts/p",
	data_icon = "*style/icons/p",

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

	impl_column = "*common/impl_column",
}
