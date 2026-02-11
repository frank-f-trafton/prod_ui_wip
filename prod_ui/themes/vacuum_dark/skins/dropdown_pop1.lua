return {
	skinner_id = "wimp/dropdown_pop",

	box = "*boxes/dropdown_pop",
	font = "*fonts/p",
	data_scroll = "*scroll_bar_data/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm_hide",

	text_align = "left",

	icon_side = "left",
	icon_spacing = 24,

	item_pad_v = 2,

	max_visible_items = 16,

	slice = "*slices/list_box_body", -- XXX: replace with a dedicated resource.
	color_body = {1.0, 1.0, 1.0, 1.0},
	color_text = {0.9, 0.9, 0.9, 1.0},
	color_selected = {0.75, 0.75, 1.0, 0.33},
}
