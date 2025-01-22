-- * Widget Skin: Sash.


return {
	skinner_id = "wimp/sash",

	box = "*style/boxes/panel",
	tq_px = "*tex_quads/pixel",
	slc_lr = "*tex_slices/sash_lr",
	slc_tb = "*tex_slices/sash_tb",

	cursor_h = "sizewe",
	cursor_v = "sizens",

	-- width for vertical sashes, height for horizontal sashes
	breadth = 8,

	-- Allows shrinking the drag sensor if it interferes with
	-- adjacent widgets.
	sensor_margin = 0,

	color = {1.0, 1.0, 1.0, 1.0}
}
