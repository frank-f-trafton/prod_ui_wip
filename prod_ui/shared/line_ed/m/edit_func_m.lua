local editFuncM = {}


function editFuncM.updateCaretShape(self)
	local line_ed = self.line_ed

	self.caret_x = line_ed.caret_box_x
	self.caret_y = line_ed.caret_box_y
	self.caret_w = line_ed.caret_box_w
	self.caret_h = line_ed.caret_box_h

	if self.replace_mode then
		self.caret_fill = "line"
	else
		self.caret_fill = "fill"
		self.caret_w = line_ed.caret_line_width
	end
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


function editFuncM.updateVisibleParagraphs(self)
	local line_ed = self.line_ed

	-- Find the first visible display paragraph (or rather, one before it) to cut down on rendering.
	local y_pos = self.scr_y - self.vp_y -- XXX should this be viewport #2? Or does the viewport offset matter at all?

	-- XXX default to 1?
	--self.vis_para_top
	for i, paragraph in ipairs(line_ed.paragraphs) do
		local sub_one = paragraph[1]
		if sub_one.y > y_pos then
			self.vis_para_top = math.max(1, i - 1)
			break
		end
	end

	-- Find the last display paragraph (or one after it) as well.
	self.vis_para_bot = #line_ed.paragraphs
	for i = self.vis_para_top, #line_ed.paragraphs do
		local paragraph = line_ed.paragraphs[i]
		local sub_last = paragraph[#paragraph]
		if sub_last.y + sub_last.h > y_pos + self.vp2_h then
			self.vis_para_bot = i
			break
		end
	end

	--print("updateVisibleParagraphs()", "self.vis_para_top", self.vis_para_top, "self.vis_para_bot", self.vis_para_bot)
end


function editFuncM.updateTextBatch(self)
	local line_ed = self.line_ed
	local text_object = self.text_object

	text_object:clear()

	if line_ed.font ~= text_object:getFont() then
		text_object:setFont(line_ed.font)
	end

	for i = self.vis_para_top, self.vis_para_bot do
		local paragraph = line_ed.paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			text_object:add(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
		end
	end
end


return editFuncM
