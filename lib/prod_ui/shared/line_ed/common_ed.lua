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


return commonEd
