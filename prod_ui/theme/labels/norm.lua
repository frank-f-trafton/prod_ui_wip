-- Standard text label.
-- font: The LÖVE Font object to use when measuring and rendering label text.
-- ul_color: An independent underline color (in the form of {R, G, B, A}), or false to use the text color.
-- ul_h: Underline height or thickness.
-- Text color, text offsets (for inset buttons), etc. are provided by skin resource tables.
return {
	font = "*fonts/p",
	ul_color = false,
	ul_h = 1, --math.max(1, math.floor(0.5 + 1 * scale)),
}
