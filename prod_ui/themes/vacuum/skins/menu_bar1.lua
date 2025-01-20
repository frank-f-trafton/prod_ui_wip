-- Menu bar


return {
	skinner_id = "default",

	-- NOTE: Very large box borders will interfere with clicking on menu items.
	["*box"] = "style/boxes/menu_bar",
	["*tq_px"] = "tex_quads/pixel",
	["*sl_body"] = "tex_slices/menu_bar_body",
	["*font_item"] = "fonts/p",
	["*thimble_info"] = "common/thimble_info",

	color_cat_enabled = {1.0, 1.0, 1.0, 1.0},
	color_cat_selected = {0.1, 0.1, 0.1, 1.0},
	color_cat_disabled = {0.5, 0.5, 0.5, 1.0},
	color_select_glow = {0.33, 0.33, 0.33, 1.0},
	color_hover_glow = {0.33, 0.33, 0.33, 1.0},

	underline_width = 1, -- XXX forgot to scale this?
	height_mult = 1.5,

	base_height = 28, -- XXX clean up. Original assignment follows:
	--self.base_height = math.floor(self.font_item:getHeight() * self.height_mult) + self.border_y1 + self.border_y2
}
