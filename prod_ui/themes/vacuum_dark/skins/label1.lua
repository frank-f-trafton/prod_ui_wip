return {
	skinner_id = "base/label",

	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/atlas/pixel",

	label_align_h = "center",
	label_align_v = "middle",

	res_idle = {
		--[[optional]] --sl_body = "*slices/atlas/label",
		--[[optional]] --color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0
	},

	res_disabled = {
		--[[optional]] --sl_body = "*slices/atlas/label_disabled",
		--[[optional]] --color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		label_ox = 0,
		label_oy = 0
	},
}
