-- Skin: Dropdown box (the pop-up menu).


return {
	skinner_id = "default",

	box = "*style/boxes/panel",
	font = "*fonts/p",
	data_scroll = "*common/scroll_bar1",
	scr_style = "*style/scroll_bar_styles/norm_hide",

	text_align = "left", -- "left", "center", "right"

	-- Height of items.
	["$item_height"] = 22,

	-- The drawer's maximum height, as measured by the number of visible items (plus margins).
	-- Drawer height is limited by the size of the application window.
	max_visible_items = 16,

	slice = "*tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
	color_body = {1.0, 1.0, 1.0, 1.0},
	color_text = {0.9, 0.9, 0.9, 1.0},
	color_selected = {0.75, 0.75, 1.0, 0.33},
}
