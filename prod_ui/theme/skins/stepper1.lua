-- * Widget Skin: Stepper button.


return {
	skinner_id = "base/stepper",


	box = "*boxes/button",
	label_style = "*labels/norm",
	tq_px = "*quads/atlas/pixel",


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
	prev_spacing = 40,
	next_spacing = 40,

	--[[
	Arrow quad mappings:

	Orientation    Prev   Next
	---------------------------
	Horizontal     left   right
	Vertical       up     down
	--]]

	res_idle = {
		sl_body = "*slices/atlas/stepper_body",
		sl_button_up = "*slices/atlas/button",
		sl_button = "*slices/atlas/button",
		tq_left = "*quads/atlas/arrow2_left",
		tq_right = "*quads/atlas/arrow2_right",
		tq_up = "*quads/atlas/arrow2_up",
		tq_down = "*quads/atlas/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		button_ox = 0,
		button_oy = 0,
	},

	res_hover = {
		sl_body = "*slices/atlas/stepper_body",
		sl_button_up = "*slices/atlas/button_hover",
		sl_button = "*slices/atlas/button_hover",
		tq_left = "*quads/atlas/arrow2_left",
		tq_right = "*quads/atlas/arrow2_right",
		tq_up = "*quads/atlas/arrow2_up",
		tq_down = "*quads/atlas/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		button_ox = 0,
		button_oy = 0,
	},

	res_pressed = {
		sl_body = "*slices/atlas/stepper_body",
		sl_button_up = "*slices/atlas/button_hover",
		sl_button = "*slices/atlas/button_press",
		tq_left = "*quads/atlas/arrow2_left",
		tq_right = "*quads/atlas/arrow2_right",
		tq_up = "*quads/atlas/arrow2_up",
		tq_down = "*quads/atlas/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		button_ox = 0,
		button_oy = 1,
	},

	res_disabled = {
		sl_body = "*slices/atlas/stepper_body",
		sl_button_up = "*slices/atlas/button_disabled",
		sl_button = "*slices/atlas/button_disabled",
		tq_left = "*quads/atlas/arrow2_left",
		tq_right = "*quads/atlas/arrow2_right",
		tq_up = "*quads/atlas/arrow2_up",
		tq_down = "*quads/atlas/arrow2_down",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul,
		button_ox = 0,
		button_oy = 0,
	},
}
