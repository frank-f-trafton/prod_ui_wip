-- TreeBox.


return {
	skinner_id = "wimp/tree_box",

	-- settings
	--TR_item_align_h = "left",
	--TR_expanders_active = false,
	--TR_show_icons = false,
	-- /settings

	box = "*boxes/panel",
	tq_px = "*quads/atlas/pixel",
	data_scroll = "*scroll_bar_data/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm",
	font = "*fonts/p",
	data_icon = "*icons/p",

	tq_expander_up = "*quads/atlas/arrow2_up",
	tq_expander_down = "*quads/atlas/arrow2_down",
	tq_expander_left = "*quads/atlas/arrow2_left",
	tq_expander_right = "*quads/atlas/arrow2_right",

	-- Item height is calculated as: math.floor((font:getHeight() * font:getLineHeight()) + item_pad_v)
	item_pad_v = 2,

	sl_body = "*slices/atlas/list_box_body",

	-- Vertical text alignment is centered.

	-- Spacing for expanders, and half the initial width for the first pipe indentation.
	first_col_spacing = 24,

	-- The amount to indent child nodes.
	indent = 12,

	-- Draw vertical pipes that show the indentation of each node.
	draw_pipes = true,
	pipe_width = 1,

	-- Icon column width and positioning, if active.
	icon_spacing = 24,

	-- Item components are always placed in these orders:
	-- Left alignment: pipe decoration, expander, icon, text.
	-- Right alignment: text, icon, expander, pipe decoration

	-- Additional padding for icons.
	pad_icon_x = 0,

	-- Additional padding for text.
	pad_text_x = 0,

	color_item_text = {1.0, 1.0, 1.0, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},
	color_hover_glow = {1.0, 1.0, 1.0, 0.16},
	color_active_glow = {0.75, 0.75, 1.0, 0.33},
	color_item_marked = {0.0, 0.0, 1.0, 0.33},
	color_pipe = {0.5, 0.5, 0.5, 1.0}--{1.0, 1.0, 1.0, 1.0}
}
