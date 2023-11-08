-- Application slider bar.


return {

	skinner_id = "default",

	["*box"] = "style/boxes/button",
	["*label_style"] = "style/labels/norm",
	["*tq_px"] = "tex_quads/pixel",


	-- Label placement and spacing.
	-- Note that this default skin isn't really designed to accommodate labels.
	["$label_spacing"] = 0,
	label_placement = "left",

	["$trough_breadth"] = 1, -- For the empty part.
	["$trough_breadth2"] = 4, -- For the in-use part.

	-- When true, engage thumb-moving state even if the user clicked outside of the trough area.
	trough_click_anywhere = true,

	-- Thumb visual dimensions. The size may be reduced if it does not fit into the trough.
	["$thumb_w"] = 24,
	["$thumb_h"] = 24,

	-- Thumb visual offsets.
	["$thumb_ox"] = 12,
	["$thumb_oy"] = 12,

	-- Adjusts the visual length of the trough line. Positive extends, negative reduces.
	["$trough_ext"] = 12,

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
		["*tq_thumb"] = "tex_quads/slider_thumb1", -- XXX make some variations for hover, press, disabled
		["*sl_trough_active"] = "tex_slices/slider_trough_active",
		["*sl_trough_empty"] = "tex_slices/slider_trough_empty",

		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_hover = {
		["*tq_thumb"] = "tex_quads/slider_thumb1",
		["*sl_trough_active"] = "tex_slices/slider_trough_active",
		["*sl_trough_empty"] = "tex_slices/slider_trough_empty",

		color_label = {1.0, 1.0, 1.0, 1.0},
		--color_label_ul,
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_pressed = {
		["*tq_thumb"] = "tex_quads/slider_thumb1",
		["*sl_trough_active"] = "tex_slices/slider_trough_active",
		["*sl_trough_empty"] = "tex_slices/slider_trough_empty",

		color_label = {0.9, 0.9, 0.9, 1.0},
		--color_label_ul,
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},

	res_disabled = {
		["*tq_thumb"] = "tex_quads/slider_thumb1",
		["*sl_trough_active"] = "tex_slices/slider_trough_active",
		["*sl_trough_empty"] = "tex_slices/slider_trough_empty",

		color_label = {0.5, 0.5, 0.5, 1.0},
		--color_label_ul,
		["$label_ox"] = 0,
		["$label_oy"] = 0,
	},
}
