-- Widget Skin: Application button.
return {
	skinner_id = "skn_button_tquad",

	box = "*boxes/button",
	label_style = "*labels/norm",


	-- Cursor IDs for hover and press states.
	cursor_on = "hand",
	cursor_press = "hand",

	-- A default graphic to use if the widget doesn't provide one.
	-- graphic =

	-- Quad (graphic) alignment within Viewport #1.
	quad_align_h = "center", -- "left", "center", "right"
	quad_align_v = "middle", -- "top", "middle", "bottom"

	-- Placement of graphic in relation to text labels.
	graphic_placement = "overlay", -- "left", "right", "top", "bottom", "overlay"

	-- Additional spacing between graphic and label.
	graphic_spacing = 0,


	res_idle = {
		slice = "*slices/atlas/button",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0
	},

	res_hover = {
		slice = "*slices/atlas/button_hover",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 0
	},

	res_pressed = {
		slice = "*slices/atlas/button_press",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.9, 0.9, 0.9, 1.0},
		label_ox = 0,
		label_oy = 1
	},

	res_disabled = {
		slice = "*slices/atlas/button_disabled",
		color_body = {1.0, 1.0, 1.0, 1.0},
		color_quad = {0.5, 0.5, 0.5, 1.0},
		label_ox = 0,
		label_oy = 0
	},
}
