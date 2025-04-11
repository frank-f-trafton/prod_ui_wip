-- Base style data.
return {
	fonts = {
		h1 = 32,
		h2 = 24,
		h3 = 18,
		h4 = 15,
		internal = 13,
		p = 14,
		small = 12,

		--[====[
		-- XXX: Test symbol substitution in single-line text boxes
		p = {
			"fonts/noto_sans/NotoSans-Regular.ttf", 14,
			"fonts/noto_sans/NotoSansSymbols-Regular.ttf", 14,
			"fonts/noto_sans/NotoSansSymbols2-Regular.ttf", 14,
		},
		--]====]
	},

	boxes = {
		panel = {
			sl_body_id = "tex_slices/list_box_body",

			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			margin = {x1 = 2, x2 = 2, y1 = 2, y2 = 2}
		},

		wimp_frame = {
			-- For the frame border
			outpad = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			margin = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},

			-- For the content viewport
			outpad2 = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border2 = {x1 = 1, x2 = 1, y1 = 1, y2 = 1},
			margin2 = {x1 = 1, x2 = 1, y1 = 1, y2 = 1},
		},

		wimp_frame_header_normal = {
			outpad = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border = {x1 = 1, x2 = 1, y1 = 1, y2 = 1},
			margin = {x1 = 0, x2 = 0, y1 = 0, y2 = 0}
		},

		wimp_frame_header_small = {
			outpad = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			margin = {x1 = 0, x2 = 0, y1 = 0, y2 = 0}
		},

		wimp_frame_header_large = {
			outpad = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			margin = {x1 = 0, x2 = 0, y1 = 0, y2 = 0}
		},

		frame_norm = {
			sl_body_id = "tex_slices/list_box_body",

			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			margin = {x1 = 2, x2 = 2, y1 = 2, y2 = 2}
		},

		-- XXX WIP.
		wimp_group = {
			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			margin = {x1 = 2, x2 = 2, y1 = 2, y2 = 2}
		},

		-- Margin is applied to Viewport #2 (graphic).
		button = {
			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 4, x2 = 4, y1 = 4, y2 = 4},
			margin = {x1 = 4, x2 = 4, y1 = 4, y2 = 4}
		},

		-- Margin is applied to Viewport #2 (graphic).
		button_small = {
			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 1, x2 = 1, y1 = 1, y2 = 1},
			margin = {x1 = 1, x2 = 1, y1 = 1, y2 = 1}
		},

		-- Used with checkboxes and radio buttons.
		-- Margin is applied to Viewport #2 (the bijou's drawing area).
		button_bijou = {
			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 4, x2 = 4, y1 = 4, y2 = 4},
			margin = {x1 = 0, x2 = 0, y1 = 0, y2 = 0}
		},

		-- Input box edges.
		input_box = {
			outpad = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			border = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			margin = {x1 = 2, x2 = 2, y1 = 2, y2 = 2}
		},

		menu_bar = {
			outpad = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border = {x1 = 1, x2 = 1, y1 = 1, y2 = 1},
			margin = {x1 = 0, x2 = 0, y1 = 0, y2 = 0}
		},

		text_block = {
			outpad = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
			border = {x1 = 2, x2 = 2, y1 = 2, y2 = 2},
			--margin = {x1 = 2, x2 = 2, y1 = 2, y2 = 2}
		},
	}
}
