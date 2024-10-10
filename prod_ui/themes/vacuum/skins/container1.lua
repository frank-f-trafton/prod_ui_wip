-- Container with embedded scroll bars.

return {
	skinner_id = "default",

	["*box"] = "style/boxes/frame_norm",
	["*data_scroll"] = "common/scroll_bar1",
	["*scr_style"] = "style/scroll_bar_styles/norm",

	-- Padding when scrolling to put a widget into view.
	["$in_view_pad_x"] = 0,
	["$in_view_pad_y"] = 0,
}
