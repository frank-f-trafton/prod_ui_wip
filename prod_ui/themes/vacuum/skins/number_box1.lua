-- Skin: NumberBox.


return {

	skinner_id = "default",

	["*box"] = "style/boxes/input_box",
	["*font"] = "fonts/p",
	["*font_ghost"] = "fonts/p",

	-- XXX: inc/dec button resources

	cursor_on = "ibeam",

	-- Horizontal size of the increment and decrement buttons.
	-- "auto": use Viewport #?'s (XXX) height.
	["$button_spacing"] = 24,

	-- Placement of the increment and decrement buttons.
	button_placement = "right", -- "left", "right"

	["$item_pad_v"] = 2,

	text_align = "left", -- "left", "center", "right"

	--color_cursor = {1.0, 1.0, 1.0, 1.0},
	["$caret_w"] = 2,
	color_insert = {1.0, 1.0, 1.0, 1.0},
	--color_replace = {0.75, 0.75, 0.75, 1.0},

	["*tq_arrow_up"] = "tex_quads/arrow_up",
	["*tq_arrow_down"] = "tex_quads/arrow_down",

	res_idle = {
		["*slice"] = "tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		["*slc_button_up"] = "tex_slices/button_minor",
		["*slc_button_down"] = "tex_slices/button_minor",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},

	res_pressed = {
		["*slice"] = "tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		["*slc_button_up"] = "tex_slices/button_minor_press",
		["*slc_button_down"] = "tex_slices/button_minor_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.9, 0.9, 0.9, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 1,
	},

	res_disabled = {
		["*slice"] = "tex_slices/list_box_body", -- XXX: replace with a dedicated resource.
		["*slc_button_up"] = "tex_slices/button_minor_disabled",
		["*slc_button_down"] = "tex_slices/button_minor_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_text = {0.5, 0.5, 0.5, 1.0},
		color_highlight = {0.5, 0.5, 0.5, 1.0},
		["$deco_ox"] = 0,
		["$deco_oy"] = 0,
	},
}
