-- * Widget Skin: Application label.


return {
	skinner_id = "base/label",

	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/atlas/pixel",

	-- Alignment of label text in Viewport #1.
	label_align_h = "center", -- "left", "center", "right", "justify"
	label_align_v = "middle", -- "top", "middle", "bottom"


	res_idle = {
		-- Optional body slice and color
		--sl_body = "*slices/atlas/label",
		--color_body = {1.0, 1.0, 1.0, 1.0},

		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0
	},

	res_disabled = {
		-- Optional body slice and color
		--sl_body = "*slices/atlas/label_disabled",
		--color_body = {1.0, 1.0, 1.0, 1.0},

		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0
	},
}
