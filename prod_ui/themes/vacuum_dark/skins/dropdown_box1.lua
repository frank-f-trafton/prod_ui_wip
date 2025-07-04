return {
	skinner_id = "wimp/dropdown_box",
	skin_id_pop = "dropdown_pop1",

	-- settings
	icon_set_id = "bureau",
	show_icons = false,
	-- /settings

	box = "*boxes/dropdown_box",
	font = "*fonts/p",

	button_spacing = 24,
	button_placement = "right",

	icon_side = "left",
	icon_spacing = 24,

	text_align = "left",

	tq_deco_glyph = "*quads/atlas/arrow_down",

	res_idle = {
		slice = "*slices/atlas/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*slices/atlas/button_minor",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_icon = {1.0, 1.0, 1.0, 1.0},
		color_highlight = {0.75, 0.75, 1.0, 0.33},
		deco_ox = 0,
		deco_oy = 0,
	},

	res_pressed = {
		slice = "*slices/atlas/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*slices/atlas/button_minor_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_icon = {1.0, 1.0, 1.0, 1.0},
		color_highlight = {0.75, 0.75, 1.0, 0.33},
		deco_ox = 0,
		deco_oy = 1,
	},

	res_disabled = {
		slice = "*slices/atlas/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*slices/atlas/button_minor_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_icon = {1.0, 1.0, 1.0, 1.0},
		color_highlight = {0.75, 0.75, 1.0, 0.33},
		deco_ox = 0,
		deco_oy = 0,
	},
}
