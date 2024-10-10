-- * Widget Skin: Application label.


return {
	skinner_id = "default",

	["*box"] = "style/boxes/button",
	["*label_style"] = "style/labels/norm",
	["*tq_px"] = "tex_quads/pixel",

	-- Alignment of label text in Viewport #1.
	label_align_h = "center", -- "left", "center", "right", "justify"
	label_align_v = "middle", -- "top", "middle", "bottom"


	res_idle = {
		-- Optional body slice and color
		--["*sl_body"] = "tex_slices/label",
		--color_body = {1.0, 1.0, 1.0, 1.0},

		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_disabled = {
		-- Optional body slice and color
		--["*sl_body"] = "tex_slices/label_disabled",
		--color_body = {1.0, 1.0, 1.0, 1.0},

		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},
}
