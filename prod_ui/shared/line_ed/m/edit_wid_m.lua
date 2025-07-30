-- Functions, methods and plug-ins for widgets with LineEditor (multi) state.


local context = select(1, ...)


local editWidM = {}


local widShared = context:getLua("core/wid_shared")


function editWidM.updateCaretShape(self)
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


function editWidM.updateTextBatch(self)
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


function editWidM.updateVisibleParagraphs(self)
	local line_ed = self.line_ed

	-- Find the first visible display paragraph (or rather, one before it) to cut down on rendering.
	local y_pos = self.scr_y - self.vp2_y

	self.vis_para_top = 1
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


function editWidM.updatePageJumpSteps(self, font)
	self.page_jump_steps = math.max(1, math.floor(self.vp_h / (font:getHeight() * font:getLineHeight())))
end


--- Call after changing alignment, then update the alignment of all sub-lines.
function editWidM.updateAlignOffset(self)
	local align = self.line_ed.align

	if align == "left" then
		self.align_offset = 0

	elseif align == "center" then
		self.align_offset = (self.doc_w < self.vp_w) and math.floor(0.5 + self.vp_w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.align_offset = (self.doc_w < self.vp_w) and self.vp_w or self.doc_w
	end
end


function editWidM.updateDocumentDimensions(self)
	local line_ed = self.line_ed

	-- height (assumes the final sub-line is current)
	local last_para = line_ed.paragraphs[#line_ed.paragraphs]
	local last_sub = last_para[#last_para]

	self.doc_h = last_sub.y + last_sub.h

	-- width
	-- Use viewport #1's width for wrapping text.
	line_ed.view_w = self.vp_w

	-- When not wrapping, the document width is the widest sub-line.
	if not line_ed.wrap_mode then
		local x1, x2 = self.line_ed:getDisplayXBoundaries()
		self.doc_w = (x2 - x1)

	-- When wrapping, the document width is fixed to the viewport width.
	-- (Reason: to prevent horizontal scrolling when wrapped text contains
	-- trailing whitespace.)
	else
		self.doc_w = self.vp_w
	end

	editWidM.updateAlignOffset(self)
end


function editWidM.scrollGetCaretInBounds(self, immediate)
	local line_ed = self.line_ed

	-- get the extended caret rectangle
	local car_x1 = self.align_offset + line_ed.caret_box_x - self.caret_extend_x
	local car_y1 = line_ed.caret_box_y - self.caret_extend_y
	local car_x2 = self.align_offset + line_ed.caret_box_x + line_ed.caret_box_w + self.caret_extend_x
	local car_y2 = line_ed.caret_box_y + line_ed.caret_box_h + self.caret_extend_y

	widShared.scrollRectInBounds(self, car_x1, car_y1, car_x2, car_y2, immediate)
end


function editWidM.resetCaretBlink(self)
	self.caret_blink_time = self.caret_blink_reset
end


function editWidM.updateCaretBlink(self, dt)
	self.caret_blink_time = self.caret_blink_time + dt
	if self.caret_blink_time > self.caret_blink_on + self.caret_blink_off then
		self.caret_blink_time = math.max(-(self.caret_blink_on + self.caret_blink_off), self.caret_blink_time - (self.caret_blink_on + self.caret_blink_off))
	end

	self.caret_is_showing = self.caret_blink_time < self.caret_blink_off
end


function editWidM.generalUpdate(self, car_shape, dim, car_view, vis_para, txt)
	if car_shape then
		editWidM.updateCaretShape(self)
	end

	if dim then
		editWidM.updateDocumentDimensions(self)
	end

	if car_view then
		self:scrollGetCaretInBounds(true)
	end

	if vis_para then
		editWidM.updateVisibleParagraphs(self)
	end

	if txt and self.text_object then
		editWidM.updateTextBatch(self)
	end
end


return editWidM