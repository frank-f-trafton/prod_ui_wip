return {
	-- How far to allow resizing a widget outside the bounds of its parent.
	-- Used to prevent stretching frames too far outside the LÖVE application window.
	frame_outbound_limit = 32, --math.max(1, math.floor(32 * scale))

	-- How many pixels to extend / pad resize sensors.
	frame_resize_pad = 12, --math.max(1, math.floor(12 * scale))

	-- How much to extend the diagonal parts of the resize area.
	frame_resize_diagonal = 12, --math.max(0, math.floor(12 * scale))

	-- Theme -> Skin settings
	header_button_side = "right",
	header_size = "normal",
	header_show_close_button = true,
	header_show_max_button = true,
	header_text = "Untitled Frame",
	header_text_align_h = 0.5,
	header_text_align_v = 0.5
}
