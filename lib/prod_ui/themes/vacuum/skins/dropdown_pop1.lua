-- Skin: Dropdown box (the pop-up menu).
-- XXX: Unfinished. Copy of text_box_s1.lua.


return {

	skinner_id = "default",

	["*box"] = "style/boxes/panel",
	["*font"] = "fonts/p",

	text_align = "left", -- "left", "center", "right"

	["$caret_w"] = 2,

	["*slice"] = "tex_slices/input_box",
	color_body = {1.0, 1.0, 1.0, 1.0},
	color_text = {0.9, 0.9, 0.9, 1.0},
	color_selected = {0.5, 0.5, 0.5, 1.0},
}
