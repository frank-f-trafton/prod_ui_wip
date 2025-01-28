-- Copy+paste of skins/slider_bar1.
-- Radial slider / dial.


return {
	skinner_id = "base/slider_radial",

	box = "*style/boxes/button",
	label_style = "*style/labels/norm",
	tq_px = "*tex_quads/pixel",


	-- Label placement and spacing.
	-- Note that this default skin isn't really designed to accommodate labels.
	label_spacing = 0,
	label_placement = "overlay",

	trough_breadth = 1, -- For the empty part.
	trough_breadth2 = 4, -- For the in-use part.

	-- When true, engage thumb-moving state even if the user clicked outside of the trough area.
	trough_click_anywhere = true,

	-- Cursor IDs for hover and press states (when over the trough area).
	cursor_on = "hand",
	cursor_press = "hand",

	-- Label config.
	label_align_h = "center",
	label_align_v = "middle",

	--[[
	An old WIP note:

	quads:
	slider_trough_tick_minor
	slider_trough_tick_major
	--]]

	res_idle = {
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		label_ox = 0,
		label_oy = 0,
	},

	res_hover = {
		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul,
		label_ox = 0,
		label_oy = 0,
	},

	res_pressed = {
		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		label_ox = 0,
		label_oy = 0,
	},

	res_disabled = {
		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul,
		label_ox = 0,
		label_oy = 0,
	},
}
