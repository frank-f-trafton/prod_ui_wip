local editFuncM = {}


function editFuncM.updateCaretShape(self)
	local disp = self.line_ed.disp

	self.caret_x = disp.caret_box_x
	self.caret_y = disp.caret_box_y
	self.caret_w = disp.caret_box_w
	self.caret_h = disp.caret_box_h
end


function editFuncM.dispResetCaretBlink(disp)
	disp.caret_blink_time = disp.caret_blink_reset
end


function editFuncM.dispUpdateCaretBlink(disp, dt)
	-- Implement caret blinking.
	disp.caret_blink_time = disp.caret_blink_time + dt
	if disp.caret_blink_time > disp.caret_blink_on + disp.caret_blink_off then
		disp.caret_blink_time = math.max(-(disp.caret_blink_on + disp.caret_blink_off), disp.caret_blink_time - (disp.caret_blink_on + disp.caret_blink_off))
	end

	disp.caret_is_showing = disp.caret_blink_time < disp.caret_blink_off
end


function editFuncM.setupCaretDisplayInfo(disp, highlight, paragraphs)
	-- XXX: skin or some other config system. Currently, 'caret_line_width' is based on the width of 'M' in the current font.
	disp.caret_line_width = 0
	disp.caret_is_showing = true

	disp.caret_blink_time = 0

	-- XXX: skin or some other config system
	disp.caret_blink_reset = -0.5
	disp.caret_blink_on = 0.5
	disp.caret_blink_off = 0.5

	-- Caret and highlight lines, sub-lines and bytes for the display text.
	disp.d_car_byte = 1
	if paragraphs then
		disp.d_car_para = 1
		disp.d_car_sub = 1
	end

	if highlight then
		disp.d_h_byte = 1
		if paragraphs then
			disp.d_h_para = 1
			disp.d_h_sub = 1
		end
	end
end


function editFuncM.setupCaretBox(disp)
	-- The position and dimensions of the currently selected character.
	-- The client widget uses these values to determine the size and location of its caret.
	disp.caret_box_x = 0
	disp.caret_box_y = 0
	disp.caret_box_w = 0
	disp.caret_box_h = 0
end


function editFuncM.setupMaskedState(disp)
	-- Glyph masking mode, as used in password fields.
	-- Note that this only changes the UTF-8 string which is sent to text rendering functions.
	-- It does nothing else in terms of security.

	disp.masked = false
	disp.mask_glyph = "*" -- Must be exactly one glyph.
end


return editFuncM
