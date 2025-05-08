-- Menu bar


return {
	skinner_id = "wimp/menu_bar",

	-- NOTE: Very large box borders will interfere with clicking on menu items.
	box = "*boxes/menu_bar",
	tq_px = "*quads/atlas/pixel",
	sl_body = "*slices/atlas/menu_bar_body",
	font_item = "*fonts/p",
	thimble_info = "*thimble_info",

	color_cat_enabled = {1.0, 1.0, 1.0, 1.0},
	color_cat_selected = {0.1, 0.1, 0.1, 1.0},
	color_cat_disabled = {0.5, 0.5, 0.5, 1.0},
	color_select_glow = {0.33, 0.33, 0.33, 1.0},
	color_hover_glow = {0.33, 0.33, 0.33, 1.0},

	underline_width = 1,
	height_mult = 1.5,

	base_height = 28, -- XXX clean up. Original assignment follows:
	--self.base_height = math.floor(self.font_item:getHeight() * self.height_mult) + self.border_y1 + self.border_y2
}
