-- Menu bar


return {

	skinner_id = "default",

	["*tq_px"] = "tex_quads/pixel",
	["*sl_body"] = "tex_slices/menu_bar_body",
	["*font_item"] = "fonts/p",
	["*thimble_info"] = "common/thimble_info",

	-- NOTE: Very large borders will interfere with clicking on menu-items.
	["$border_x1"] = 1,
	["$border_x2"] = 1,
	["$border_y1"] = 1,
	["$border_y2"] = 1,

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
