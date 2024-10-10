-- To load: local lib = context:getLua("shared/lib")


local commonEd = {}


function commonEd.setupCaretInfo(self, highlight, lines)
	-- Current line and position (in bytes) of the text caret and the highlight selection.
	-- The highlight can be greater or less than self.car_byte.
	-- If (h_line == car_line and h_byte == car_byte), then highlighting is not active.
	self.car_byte = 1
	if lines then
		self.car_line = 1
	end

	if highlight then
		self.h_byte = 1
		if lines then
			self.h_line = 1
		end
	end
end


function commonEd.setupCaretDisplayInfo(self, highlight, paragraphs)
	self.caret_line_width = 1 -- XXX: skin
	self.caret_is_showing = true

	self.caret_blink_time = 0

	-- XXX: skin or some other config system
	self.caret_blink_reset = -0.5
	self.caret_blink_on = 0.5
	self.caret_blink_off = 0.5

	-- Caret and highlight lines, sub-lines and bytes for the display text.
	self.d_car_byte = 1
	if paragraphs then
		self.d_car_para = 1
		self.d_car_sub = 1
	end

	if highlight then
		self.d_h_byte = 1
		if paragraphs then
			self.d_h_para = 1
			self.d_h_sub = 1
		end
	end
end


function commonEd.setupCaretBox(self)
	-- The position and dimensions of the currently selected character.
	-- The client widget uses these values to determine the size and location of its caret.
	self.caret_box_x = 0
	self.caret_box_y = 0
	self.caret_box_w = 0
	self.caret_box_h = 0
end


function commonEd.setupMaskedState(self)
	-- Glyph masking mode, as used in password fields.
	-- Note that this only changes the UTF-8 string which is sent to text rendering functions.
	-- It does nothing else with respect to security.

	self.masked = false
	self.mask_glyph = "*" -- Must be exactly one glyph.
end


function commonEd.resetCaretBlink(self)
	self.caret_blink_time = self.caret_blink_reset
end


function commonEd.updateCaretBlink(self, dt)
	-- Implement caret blinking.
	self.caret_blink_time = self.caret_blink_time + dt
	if self.caret_blink_time > self.caret_blink_on + self.caret_blink_off then
		self.caret_blink_time = math.max(-(self.caret_blink_on + self.caret_blink_off), self.caret_blink_time - (self.caret_blink_on + self.caret_blink_off))
	end

	if self.caret_blink_time < self.caret_blink_off then
		self.caret_is_showing = true
	else
		self.caret_is_showing = false
	end
end


function commonEd.client_getReplaceMode(self)
	return self.line_ed.replace_mode
end


--- When Replace Mode is active, new text overwrites existing characters under the caret.
function commonEd.client_setReplaceMode(self, enabled)
	self.line_ed.replace_mode = not not enabled
end


return commonEd
