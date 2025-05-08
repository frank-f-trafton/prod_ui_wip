-- Container with embedded scroll bars and an optional body 9-slice.

return {
	skinner_id = "base/container",

	box = "*boxes/frame_norm",
	data_scroll = "*scroll_bar_data/scroll_bar1",
	scr_style = "*scroll_bar_styles/norm",

	-- Padding when scrolling to put a widget into view.
	in_view_pad_x = 0,
	in_view_pad_y = 0,

	-- * Sash State *

	slc_sash_lr = "*slices/atlas/sash_lr",
	slc_sash_tb = "*slices/atlas/sash_tb",

	sash_breadth = 8,

	-- Reduces the intersection box when checking for the mouse *entering* a sash.
	-- NOTE: overly large values will make the sash unclickable.
	sash_contract_x = 0,
	sash_contract_y = 0,

	-- Increases the intersection box when checking for the mouse *leaving* a sash.
	-- NOTES:
	-- * Overly large values will prevent the user from clicking on widgets that
	--   are descendants of the divider.
	-- * The expansion does not go beyond the divider's body.
	sash_expand_x = 2,
	sash_expand_y = 2,

	cursor_sash_hover_h = "sizewe",
	cursor_sash_hover_v = "sizens",

	cursor_sash_drag_h = "sizewe",
	cursor_sash_drag_v = "sizens",

	-- * / Sash State *

	color_body = {1.0, 1.0, 1.0, 1.0},
	slc_body = "*slices/atlas/container_body1",
}
