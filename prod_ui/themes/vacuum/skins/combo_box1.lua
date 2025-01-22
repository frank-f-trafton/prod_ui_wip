-- Skin: ComboBox (the body).


return {
	skinner_id = "wimp/combo_box",

	-- The SkinDef ID for pop-ups made by this widget.
	skin_id_pop = "dropdown_pop1",

	box = "*style/boxes/input_box",
	font = "*fonts/p",
	font_ghost = "*fonts/p",

	cursor_on = "ibeam",
	text_align = "left", -- "left", "center", "right"

	-- Horizontal size of the expander button.
	-- "auto": use Viewport #2's height.
	button_spacing = 24,

	-- Placement of the expander button.
	button_placement = "right", -- "left", "right"

	item_pad_v = 2,

	res_idle = {
		slice = "*tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*tex_slices/button_minor",
		tq_deco_glyph = "*tex_quads/arrow_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		deco_ox = 0,
		deco_oy = 0
	},

	res_pressed = {
		slice = "*tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*tex_slices/button_minor_press",
		tq_deco_glyph = "*tex_quads/arrow_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		deco_ox = 0,
		deco_oy = 1
	},

	res_disabled = {
		slice = "*tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		slc_deco_button = "*tex_slices/button_minor_disabled",
		tq_deco_glyph = "*tex_quads/arrow_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		color_caret_insert = {1.0, 1.0, 1.0, 1.0},
		color_caret_replace = {0.75, 0.75, 0.75, 1.0},
		deco_ox = 0,
		deco_oy = 0
	}
}
