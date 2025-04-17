-- Pop-Up (Context) menu


return {
	skinner_id = "wimp/menu_pop",

	box = "*boxes/panel",

	separator_size = 1,


	-- (Pop up menus do not render hover-glow.)


	-- (While pop-up menus can scroll if needed, they do not have explicit scroll bars.)


	font_item = "*fonts/p",


	slc_body = "*slices/atlas/menu_pop_body",
	tq_px = "*quads/atlas/pixel",

	tq_arrow = "*quads/atlas/arrow_right",

	tq_check_on = "*quads/atlas/menu_check_on",
	tq_check_off = "*quads/atlas/menu_check_off",
	tq_radio_on = "*quads/atlas/menu_radio_on",
	tq_radio_off = "*quads/atlas/menu_radio_off",


	color_separator = {0.125, 0.125, 0.125, 1.0},
	color_select_glow = {1.0, 1.0, 1.0, 0.33},

	color_actionable = {1, 1, 1, 1.0},
	color_selected = {0.1, 0.1, 0.1, 1.0},
	color_inactive = {0.5, 0.5, 0.5, 1.0},
}
