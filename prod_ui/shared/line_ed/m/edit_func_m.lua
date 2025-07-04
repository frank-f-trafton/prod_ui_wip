local editFuncM = {}


function editFuncM.updateCaretShape(self)
	local disp = self.line_ed.disp

	self.caret_x = disp.caret_box_x
	self.caret_y = disp.caret_box_y
	self.caret_w = disp.caret_box_w
	self.caret_h = disp.caret_box_h
end


return editFuncM