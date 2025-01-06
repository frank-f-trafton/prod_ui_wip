-- TreeBox.


return {
	skinner_id = "default",

	["*box"] = "style/boxes/panel",
	["*tq_px"] = "tex_quads/pixel",
	["*data_scroll"] = "common/scroll_bar1",
	["*scr_style"] = "style/scroll_bar_styles/norm",
	["*font"] = "fonts/p",
	["*data_icon"] = "style/icons/p",

	["*tq_expander_up"] = "tex_quads/arrow2_up",
	["*tq_expander_down"] = "tex_quads/arrow2_down",
	["*tq_expander_left"] = "tex_quads/arrow2_left",
	["*tq_expander_right"] = "tex_quads/arrow2_right",

	-- Item height is calculated as: math.floor((font:getHeight() * font:getLineHeight()) + item_pad_v)
	["$item_pad_v"] = 2,

	["*sl_body"] = "tex_slices/list_box_body",

	-- Horizontal starting edge for the tree root.
	item_align_h = "left", -- "left", "right"

	-- Vertical text alignment is centered.

	-- Spacing for expanders, and half the initial width for the first pipe indentation.
	["$first_col_spacing"] = 24,

	-- The amount to indent child nodes.
	["$indent"] = 12,

	-- Draw vertical pipes that show the indentation of each node.
	draw_pipes = true,
	["$pipe_width"] = 1,

	-- Icon column width and positioning, if active.
	["$icon_spacing"] = 24,

	-- Item components are always placed in these orders:
	-- Left alignment: pipe decoration, expander, icon, text.
	-- Right alignment: text, icon, expander, pipe decoration

	-- Additional padding for icons.
	["$pad_icon_x"] = 0,

	-- Additional padding for text.
	["$pad_text_x"] = 0,

	color_item_text = {1.0, 1.0, 1.0, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},
	color_hover_glow = {1.0, 1.0, 1.0, 0.16},
	color_active_glow = {0.75, 0.75, 1.0, 0.33},
	color_item_marked = {0.0, 0.0, 1.0, 0.33},
	color_pipe = {0.5, 0.5, 0.5, 1.0}--{1.0, 1.0, 1.0, 1.0}
}
