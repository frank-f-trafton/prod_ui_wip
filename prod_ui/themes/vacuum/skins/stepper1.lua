-- * Widget Skin: Stepper button.


return {
	skinner_id = "default",


	["*box"] = "style/boxes/button",
	["*label_style"] = "style/labels/norm",
	["*tq_px"] = "tex_quads/pixel",


	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- Alignment of label text in Viewport #1.
	label_align_h = "center", -- "left", "center", "right", "justify"
	label_align_v = "middle", -- "top", "middle", "bottom"

	-- Alignment of the 'prev' and 'next' arrow (or plus/minus, etc.) graphics within Viewports #2 and #3.
	gfx_prev_align_h = "center", -- "left", "center", "right"
	gfx_prev_align_v = "middle", -- "top", "middle", "bottom"

	gfx_next_align_h = "center", -- "left", "center", "right"
	gfx_next_align_v = "middle", -- "top", "middle", "bottom"

	-- How much space to assign the next+prev buttons when not using "overlay" placement.
	["$prev_spacing"] = 40,
	["$next_spacing"] = 40,

	--[[
	Arrow quad mappings:

	Orientation    Prev   Next
	---------------------------
	Horizontal     left   right
	Vertical       up     down
	--]]

	res_idle = {
		["*sl_body"] = "tex_slices/stepper_body",
		["*sl_button_up"] = "tex_slices/button",
		["*sl_button"] = "tex_slices/button",
		["*tq_left"] = "tex_quads/arrow2_left",
		["*tq_right"] = "tex_quads/arrow2_right",
		["*tq_up"] = "tex_quads/arrow2_up",
		["*tq_down"] = "tex_quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		["$button_ox"] = 0,
		["$button_oy"] = 0,
	},

	res_hover = {
		["*sl_body"] = "tex_slices/stepper_body",
		["*sl_button_up"] = "tex_slices/button_hover",
		["*sl_button"] = "tex_slices/button_hover",
		["*tq_left"] = "tex_quads/arrow2_left",
		["*tq_right"] = "tex_quads/arrow2_right",
		["*tq_up"] = "tex_quads/arrow2_up",
		["*tq_down"] = "tex_quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		["$button_ox"] = 0,
		["$button_oy"] = 0,
	},

	res_pressed = {
		["*sl_body"] = "tex_slices/stepper_body",
		["*sl_button_up"] = "tex_slices/button_hover",
		["*sl_button"] = "tex_slices/button_press",
		["*tq_left"] = "tex_quads/arrow2_left",
		["*tq_right"] = "tex_quads/arrow2_right",
		["*tq_up"] = "tex_quads/arrow2_up",
		["*tq_down"] = "tex_quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		["$button_ox"] = 0,
		["$button_oy"] = 1,
	},

	res_disabled = {
		["*sl_body"] = "tex_slices/stepper_body",
		["*sl_button_up"] = "tex_slices/button_disabled",
		["*sl_button"] = "tex_slices/button_disabled",
		["*tq_left"] = "tex_quads/arrow2_left",
		["*tq_right"] = "tex_quads/arrow2_right",
		["*tq_up"] = "tex_quads/arrow2_up",
		["*tq_down"] = "tex_quads/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul,
		["$button_ox"] = 0,
		["$button_oy"] = 0,
	},
}
