-- PropertiesBox.


return {
	skinner_id = "default",

	box = "*style/boxes/panel",
	tq_px = "*tex_quads/pixel",
	data_scroll = "*common/scroll_bar1",
	scr_style = "*style/scroll_bar_styles/norm",
	font = "*fonts/p",
	data_icon = "*style/icons/p",

	cursor_sash = "sizewe",
	["$sash_w"] = 12,

	["$item_h"] = 40,
	["$control_min_w"] = 128,

	sl_body = "*tex_slices/list_box_body",

	-- Alignment of property name text:
	text_align_h = "left", -- "left", "center", "right"
	-- Vertical text alignment is centered.

	-- Property name icon column width and positioning, if active.
	["$icon_spacing"] = 24,
	icon_side = "left", -- "left", "right"

	-- Additional padding for left or right-aligned text. No effect with center alignment.
	["$pad_text_x"] = 0,

	color_item_text = {1.0, 1.0, 1.0, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},
	color_active_glow = {0.75, 0.75, 1.0, 0.33},
	color_item_marked = {0.0, 0.0, 1.0, 0.33},
}
