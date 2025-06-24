-- Common details for drawing a rectangular thimble glow.
return {
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

	segments = nil
}
