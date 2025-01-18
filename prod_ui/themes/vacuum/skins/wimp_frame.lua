-- WIMP frame outline.

return {
	skinner_id = "default",

	["*box"] = "style/boxes/wimp_frame",

	["*slc_body"] = "tex_slices/window_body",
	color_body = {1.0, 1.0, 1.0, 1.0},

	["*sensor_resize_pad"] = "wimp/frame_resize_pad",

	-- Header skins for normal and condensed modes.
	skin_header_norm = "wimp_header_norm",
	skin_header_cond = "wimp_header_cond"
}
