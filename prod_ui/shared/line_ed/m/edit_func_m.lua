local editFuncM = {}


function editFuncM.updateCaretShape(self)
	local line_ed = self.line_ed

	self.caret_x = line_ed.caret_box_x
	self.caret_y = line_ed.caret_box_y
	self.caret_w = line_ed.caret_box_w
	self.caret_h = line_ed.caret_box_h
end


function editFuncM.dispResetCaretBlink(line_ed)
	line_ed.caret_blink_time = line_ed.caret_blink_reset
end


function editFuncM.dispUpdateCaretBlink(line_ed, dt)
	line_ed.caret_blink_time = line_ed.caret_blink_time + dt
	if line_ed.caret_blink_time > line_ed.caret_blink_on + line_ed.caret_blink_off then
		line_ed.caret_blink_time = math.max(-(line_ed.caret_blink_on + line_ed.caret_blink_off), line_ed.caret_blink_time - (line_ed.caret_blink_on + line_ed.caret_blink_off))
	end

	line_ed.caret_is_showing = line_ed.caret_blink_time < line_ed.caret_blink_off
end


return editFuncM
