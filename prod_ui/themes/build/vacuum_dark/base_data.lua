-- Atlas texture data.

return {
	-- Run-time texture config hints.
	config = {
		filter_min = "linear",
		filter_mag = "linear",
		wrap_h = "clamp",
		wrap_v = "clamp",

		-- BlendMode is included here for ease of organization. A texture could have a mix of premultiplied
		-- and unassociated art, so it's not really a per-texture setting in the way that filters and
		-- wrap-modes are.
		blend_mode = "alpha",
		alpha_mode = "alphamultiply",
	},

	--[[
	QuadSlice coordinates. Hash keys correspond to image filenames without extensions.
	x,y: Offset to the upper-left.

	w1,h1: Dimensions of the left column and top row.

	w2,h2: Dimensions of the middle column and middle row.

	w3,h3: Dimensions of the right column and bottom row.

	draw_fn_id: Optional string indicating that a particular function from `quadSlice.draw_functions`
	should be attached when creating the slice def. If not present, use the default draw function. Invalid
	IDs will raise an error.

	tiles_state: Optional table of booleans indicating which tiles should be enabled at first.
	The default is for all tiles to be active.

	To make a hollow slice, you could use this:
	local tiles_hollow = {
		true,  true,  true, -- 1, 2, 3
		true,  false, true, -- 4, 5, 6
		true,  true,  true, -- 7, 8, 9
	}

	Or this (admittedly cryptic) line:
	local tiles_hollow = {[5] = false}

	Note that the theme code *always* reads indices 1 through 9, and *only* acts on booleans.


	*** Behavior of the following depends on widget and skinner code ***

	ox1,oy1, ox2,oy2: Drawing offsets. Positive values enlarge the total rectangle drawn.
	For example, when drawing a QuadSlice at (0, 0) with the dimensions 64x64, an ox1 value of 6 would cause
	the slice to be drawn at (-6, 0) with the dimensions 70x64.

	                ^
	               +oy1
	        ┌───────────────┐
	        │               │
	        │               │
	<- +ox1 │               │ +ox2 ->
	        │               │
	        │               │
	        └───────────────┘
	               +oy2
	                v

	bx1,by1, bx2,by2: Optional border offsets. These have no direct impact on drawing, and are intended for reference
	by other parts of your application.

	For example, picture a message box with thick borders. The safe text rendering area could be calculated by
	applying the QuadSlice's border offsets to the drawn rectangular area.

	NOTE: Border offsets do not automatically account for drawing offsets (ox1,oy1, ox2,oy2).

	            v
	  ┌────────────────────┐
	  │  ┌──── +by1 ────┐  │
	  │  ╵              ╵  │
	> │+bx1           +bx2 │ <
	  │  ╷              ╷  │
	  │  └──── +by2 ────┘  │
	  └────────────────────┘
	            ^
	--]]

	slice_coords = {
		["button"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["button_depressed"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["button_disabled"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["button_hover"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["button_press"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["button_minor"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["button_minor_depressed"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["button_minor_disabled"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["button_minor_hover"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["button_minor_press"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["dropdown_body"] = {
			x = 0, y = 0, w1 = 6, h1 = 6, w2 = 4, h2 = 4, w3 = 6, h3 = 6,
		},
		["dropdown_drawer"] = {
			x = 0, y = 0, w1 = 6, h1 = 6, w2 = 4, h2 = 4, w3 = 6, h3 = 6,
		},
		["group_perimeter_unbroken"] = { -- XXX: untested.
			draw_fn_id = "hollow",
			x = 2, y = 2, w1 = 4, h1 = 4, w2 = 12, h2 = 12, w3 = 4, h3 = 4,
		},
		["group_perimeter_a"] = {
			draw_fn_id = "hollow", -- XXX: 3x2 mosaic with a hollow middle.
			x = 2, y = 2, w1 = 4, h1 = 0, w2 = 12, h2 = 16, w3 = 4, h3 = 4,
		},
		["group_perimeter_b"] = {
			draw_fn_id = "x0y0w3h1",
			x = 1, y = 1, w1 = 2, h1 = 2, w2 = 5, h2 = 0, w3 = 2, h3 = 0,
		},
		["group_perimeter_c"] = {
			draw_fn_id = "x0y0w3h1",
			x = 1, y = 1, w1 = 2, h1 = 2, w2 = 5, h2 = 0, w3 = 2, h3 = 0,
		},
		["input_box"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["input_box_disabled"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["input_box_hover"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["input_keyboard_key"] = {
			x = 0, y = 0, w1 = 9, h1 = 9, w2 = 23, h2 = 23, w3 = 9, h3 = 9,
		},
		["label"] = {
			x = 0, y = 0, w1 = 5, h1 = 5, w2 = 2, h2 = 2, w3 = 5, h3 = 5,
		},
		["label_disabled"] = {
			x = 0, y = 0, w1 = 5, h1 = 5, w2 = 2, h2 = 2, w3 = 5, h3 = 5,
		},
		["list_box_body"] = {
			x = 0, y = 0, w1 = 6, h1 = 6, w2 = 4, h2 = 4, w3 = 6, h3 = 6,
		},
		["menu_bar_body"] = {
			draw_fn_id = "x1y1w1h2",
	 		x = 0, y = 0, w1 = 0, h1 = 0, w2 = 4, h2 = 9, w3 = 0, h3 = 3,
		},
		["menu_pop_body"] = {
			x = 0, y = 0, w1 = 6, h1 = 6, w2 = 4, h2 = 4, w3 = 6, h3 = 6,
		},
		["progress_back"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 4, h2 = 4, w3 = 2, h3 = 2,
		},
		["progress_ichor"] = {
			x = 0, y = 0, w1 = 1, h1 = 3, w2 = 1, h2 = 2, w3 = 1, h3 = 3,
		},
		["scroll_button"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["scroll_button_disabled"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["scroll_button_hover"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["scroll_button_press"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["slider_trough_active"] = {
			x = 0, y = 0, w1 = 3, h1 = 3, w2 = 2, h2 = 2, w3 = 3, h3 = 3,
		},
		["slider_trough_empty"] = {
			x = 0, y = 0, w1 = 3, h1 = 3, w2 = 2, h2 = 2, w3 = 3, h3 = 3,
		},
		["stepper_body"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["tabular_category_body"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["tabular_category_body_hover"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["tabular_category_body_press"] = {
			x = 0, y = 0, w1 = 2, h1 = 2, w2 = 8, h2 = 8, w3 = 2, h3 = 2,
		},
		["window_body"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 16, h2 = 16, w3 = 4, h3 = 4,
		},
		["window_header"] = {
			x = 0, y = 0, w1 = 6, h1 = 6, w2 = 12, h2 = 12, w3 = 6, h3 = 6,
		},
		["window_header_button"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["window_header_button_disabled"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["window_header_button_hover"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
		["window_header_button_press"] = {
			x = 0, y = 0, w1 = 4, h1 = 4, w2 = 4, h2 = 4, w3 = 4, h3 = 4,
		},
	},

	-- 'quads' will be populated after the atlas is built.
}
