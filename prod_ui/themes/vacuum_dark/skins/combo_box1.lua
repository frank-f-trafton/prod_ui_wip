return {
	skinner_id = "wimp/combo_box",
	skin_id_pop = "dropdown_pop1",

	box = "*boxes/input_box",
	font = "*fonts/p",
	font_ghost = "*fonts/p",

	cursor_on = "ibeam",
	text_align = "left",
	text_align_v = 0.5,

	button_spacing = 24,
	button_placement = "right",

	item_pad_v = 2,

	res_idle = {
		slice = "*slices/atlas/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*slices/atlas/button_minor",
		tq_deco_glyph = "*quads/atlas/arrow_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		deco_ox = 0,
		deco_oy = 0
	},

	res_pressed = {
		slice = "*slices/atlas/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*slices/atlas/button_minor_press",
		tq_deco_glyph = "*quads/atlas/arrow_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		deco_ox = 0,
		deco_oy = 1
	},

	res_disabled = {
		slice = "*slices/atlas/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*slices/atlas/button_minor_disabled",
		tq_deco_glyph = "*quads/atlas/arrow_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_highlight_active = {0.23, 0.23, 0.67, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		deco_ox = 0,
		deco_oy = 0
	}
}
