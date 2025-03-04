-- Container with embedded scroll bars and an optional body 9-slice.

return {
	skinner_id = "base/container",

	box = "*style/boxes/frame_norm",
	data_scroll = "*common/scroll_bar1",
	scr_style = "*style/scroll_bar_styles/norm",

	-- Padding when scrolling to put a widget into view.
	in_view_pad_x = 0,
	in_view_pad_y = 0,

	color_body = {1.0, 1.0, 1.0, 1.0},
	slc_body = "*tex_slices/container_body1",
}
