-- Skin: ComboBox (the body).


return {

	skinner_id = "default",

	-- The SkinDef ID for pop-ups made by this widget.
	skin_id_pop = "dropdown_pop1",

	["*box"] = "style/boxes/input_box",
	["*font"] = "fonts/p",

	-- Horizontal size of the expander button.
	-- "auto": use Viewport #2's height.
	["$button_spacing"] = 24,

	-- Placement of the expander button.
	button_placement = "right", -- "left", "right"

	["$item_pad_v"] = 2,

	text_align = "left", -- "left", "center", "right"

	--XXX: Text stuff for ComboBoxes.
	--color_cursor = {1.0, 1.0, 1.0, 1.0},
	--["$caret_w"] = 2,
	--color_insert = {1.0, 1.0, 1.0, 1.0},
	--color_replace = {0.75, 0.75, 0.75, 1.0},

	["*tq_deco_glyph"] = "tex_quads/arrow_down",

	res_idle = {
		["*slice"] = "tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		["*slc_deco_button"] = "tex_slices/button_minor",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_pressed = {
		["*slice"] = "tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		["*slc_deco_button"] = "tex_slices/button_minor_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 1,
	},

	res_disabled = {
		["*slice"] = "tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		["*slc_deco_button"] = "tex_slices/button_minor_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},
}
