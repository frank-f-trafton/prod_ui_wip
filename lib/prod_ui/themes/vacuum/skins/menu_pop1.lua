-- Pop-Up (Context) menu


return {

	skinner_id = "default",

	["*box"] = "style/boxes/panel",

	["$separator_size"] = 1,


	-- (Pop up menus do not render hover-glow.)


	-- (While pop-up menus can scroll if needed, they do not have explicit scroll bars.)


	["*font_item"] = "fonts/p",


	["*slc_body"] = "tex_slices/menu_pop_body",
	["*tq_px"] = "tex_quads/pixel",

	["*tq_arrow"] = "tex_quads/arrow_right",

	["*tq_check_on"] = "tex_quads/menu_check_on",
	["*tq_check_off"] = "tex_quads/menu_check_off",
	["*tq_radio_on"] = "tex_quads/menu_radio_on",
	["*tq_radio_off"] = "tex_quads/menu_radio_off",


	color_separator = {0.125, 0.125, 0.125, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},

	color_actionable = {1, 1, 1, 1.0},
	color_selected = {0.1, 0.1, 0.1, 1.0},
	color_inactive = {0.5, 0.5, 0.5, 1.0},
}
