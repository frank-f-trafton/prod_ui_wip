return {
	paths = {
		font_data = {
			"%produi%/themes/vacuum/font_data",
			"%produi%/themes/data/font_data"
		},
		fonts = {
			"%produi%/themes/vacuum/fonts",
			"%produi%/themes/data/fonts"
		},
		skins = {
			"%produi%/themes/vacuum/skins",
			"%produi%/themes/data/skins"
		},
		textures = {
			"%produi%/themes/vacuum/tex/%dpi%",
			"%produi%/themes/data/tex/%dpi%"
		},
	},

	textures = {
		atlas = "atlas.png",
	},

	boxes = {
		panel = {
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
	},

	-- Icon classifications
	icons = {
		p = {
			w = 16,
			h = 16,
			pad_x1 = 2,
			pad_x2 = 2,
			pad_y = 2
		}
	},

	-- Widget text label styles.
	labels = {
		-- Standard text label.
		-- font: The LÖVE Font object to use when measuring and rendering label text.
		-- ul_color: An independent underline color (in the form of {R, G, B, A}), or false to use the text color.
		-- ul_h: Underline height or thickness.
		-- ul_oy: Vertical offset for the underline.
		-- Text color, text offsets (for inset buttons), etc. are provided by skin resource tables.
		norm = {
			font = "*fonts/p",
			ul_color = false,
			ul_h = 1, --math.max(1, math.floor(0.5 + 1 * scale)),
			ul_oy = 0, -- FIXME --math.floor(0.5 + (inst.style.labels.norm.font:getHeight() - inst.style.labels.norm.ul_h)),
		},
	},

	-- Scroll bar styles (measurements and initial behavior).
	scroll_bar_styles = {
		norm = {
			has_buttons = true,
			trough_enabled = true,
			thumb_enabled = true,

			bar_size = 16, --math.max(1, math.floor(16 * scale)),
			button_size = 16, --math.max(1, math.floor(16 * scale)),
			thumb_size_min = 16, --math.max(1, math.floor(16 * scale)),
			thumb_size_max = 2^16, --math.max(1, math.floor(2^16 * scale)),

			v_near_side = false,
			v_auto_hide = false,

			v_button1_enabled = true,
			v_button1_mode = "pend-cont",
			v_button2_enabled = true,
			v_button2_mode = "pend-cont",

			h_near_side = false,
			h_auto_hide = false,

			h_button1_enabled = true,
			h_button1_mode = "pend-cont",
			h_button2_enabled = true,
			h_button2_mode = "pend-cont",
		},

		-- Use cases: dropdown drawers
		norm_hide = {
			has_buttons = true,
			trough_enabled = true,
			thumb_enabled = true,

			bar_size = 16, --math.max(1, math.floor(16 * scale))
			button_size = 16, --math.max(1, math.floor(16 * scale))
			thumb_size_min = 16, --math.max(1, math.floor(16 * scale))
			thumb_size_max = 2^16, --math.max(1, math.floor(2^16 * scale))

			v_near_side = false,
			v_auto_hide = true,

			v_button1_enabled = true,
			v_button1_mode = "pend-cont",
			v_button2_enabled = true,
			v_button2_mode = "pend-cont",

			h_near_side = false,
			h_auto_hide = true,

			h_button1_enabled = true,
			h_button1_mode = "pend-cont",
			h_button2_enabled = true,
			h_button2_mode = "pend-cont",
		},

		half = {
			has_buttons = true,
			trough_enabled = true,
			thumb_enabled = true,

			bar_size = 16, --math.max(1, math.floor(8 * scale))
			button_size = 16, --math.max(1, math.floor(8 * scale))
			thumb_size_min = 16, --math.max(1, math.floor(8 * scale))
			thumb_size_max = 2^16, --math.max(1, math.floor(2^16 * scale))

			v_near_side = false,
			v_auto_hide = false,

			v_button1_enabled = true,
			v_button1_mode = "pend-cont",
			v_button2_enabled = true,
			v_button2_mode = "pend-cont",

			h_near_side = false,
			h_auto_hide = false,

			h_button1_enabled = true,
			h_button1_mode = "pend-cont",
			h_button2_enabled = true,
			h_button2_mode = "pend-cont",
		},
	},

	scroll_bar_data = {
		scroll_bar1 = {
			tquad_pixel = "*quads/atlas/pixel",
			tq_arrow_down = "*quads/atlas/arrow2_down",
			tq_arrow_up = "*quads/atlas/arrow2_up",
			tq_arrow_left = "*quads/atlas/arrow2_left",
			tq_arrow_right = "*quads/atlas/arrow2_right",

			-- This might be helpful if the buttons and trough do not fit snugly into the scroll bar's rectangular body.
			render_body = false,

			body_color = {0.1, 0.1, 0.1, 1.0},
			col_trough = {0.1, 0.1, 0.1, 1.0},

			-- In this implementation, the thumb and buttons share slices and colors for idle, hover and press states.
			shared = {
				idle = {
					slice = "*slices/atlas/scroll_button",
					col_body = {1.0, 1.0, 1.0, 1.0},
					col_symbol = {0.65, 0.65, 0.65, 1.0},
				},
				hover = {
					slice = "*slices/atlas/scroll_button_hover",
					col_body = {1.0, 1.0, 1.0, 1.0},
					col_symbol = {0.75, 0.75, 0.75, 1.0},
				},
				press = {
					slice = "*slices/atlas/scroll_button_press",
					col_body = {1.0, 1.0, 1.0, 1.0},
					col_symbol = {0.3, 0.3, 0.3, 1.0},
				},
				disabled = {
					slice = "*slices/atlas/scroll_button_disabled",
					col_body = {0.5, 0.5, 0.5, 1.0},
					col_symbol = {0.1, 0.1, 0.1, 1.0},
				},
			},
		},
	},

	-- General WIMP settings
	wimp = {
		-- How far to allow resizing a widget outside the bounds of its parent.
		-- Used to prevent stretching frames too far outside the LÖVE application window.
		frame_outbound_limit = 32, --math.max(1, math.floor(32 * scale))

		-- How many pixels to extend / pad resize sensors.
		frame_resize_pad = 12, --math.max(1, math.floor(12 * scale))

		-- How much to extend the diagonal parts of the resize area.
		frame_resize_diagonal = 12, --math.max(0, math.floor(12 * scale))

		-- Theme -> Skin settings
		header_button_side = "right",
		header_size = "normal",
		header_show_close_button = true,
		header_show_max_button = true,
		header_text = "Untitled Frame",
		header_text_align_h = 0.5,
		header_text_align_v = 0.5,
	},

	-- Common details for drawing a rectangular thimble glow.
	thimble_info = {
		mode = "line",
		color = {0.2, 0.2, 1.0, 1.0},
		line_style = "smooth",
		line_width = 2, --math.max(1, math.floor(2 * scale))
		line_join = "miter",
		corner_rx = 1,
		corner_ry = 1,

		-- Pushes the thimble outline out from the widget rectangle.
		-- This is overridden if the widget contains 'self.thimble_x(|y|w|h)'.
		outline_pad = 0,

		segments = nil,
	},
}
