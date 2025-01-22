-- * Skin: Progress Bar 1.


return {
	skinner_id = "default",

	box = "*style/boxes/button",
	label_style = "*style/labels/norm",
	tq_px = "*tex_quads/pixel",

	-- Alignment of label text in Viewport #1.
	label_align_h = "center", -- "left", "center", "right", "justify"
	label_align_v = "middle", -- "top", "middle", "bottom"

	-- Placement of the progress bar in relation to text labels.
	bar_placement = "overlay", -- "left", "right", "top", "bottom", "overlay"

	-- How much space to assign the progress bar when not using "overlay" placement.
	["$bar_spacing"] = 50,

	slc_back = "*tex_slices/progress_back",
	slc_ichor = "*tex_slices/progress_ichor",

	res_active = {
		color_back = {1.0, 1.0, 1.0, 1.0},
		color_ichor = {0.5, 0.5, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_inactive = {
		color_back = {0.75, 0.75, 0.75, 1.0},
		color_ichor = {0.50, 0.50, 0.50, 1.0},
		color_label = {0.75, 0.75, 0.75, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},
}
