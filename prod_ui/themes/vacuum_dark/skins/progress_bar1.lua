return {
	skinner_id = "status/progress_bar",

	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/pixel",

	label_align_h = "center",
	label_align_v = "middle",

	bar_placement = "overlay",
	bar_spacing = 50,

	slc_back = "*slices/progress_back",
	slc_ichor = "*slices/progress_ichor",

	res_active = {
		color_back = {1.0, 1.0, 1.0, 1.0},
		color_ichor = {0.5, 0.5, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0,
	},

	res_inactive = {
		color_back = {0.75, 0.75, 0.75, 1.0},
		color_ichor = {0.50, 0.50, 0.50, 1.0},
		color_label = {0.75, 0.75, 0.75, 1.0},
		label_ox = 0,
		label_oy = 0,
	},
}
