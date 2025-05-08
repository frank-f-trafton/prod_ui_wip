-- Use cases: dropdown drawers
return {
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
	h_button2_mode = "pend-cont"
}
