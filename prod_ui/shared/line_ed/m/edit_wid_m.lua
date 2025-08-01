-- Functions, methods and plug-ins for widgets with LineEditor (multi) state.


local context = select(1, ...)


local editWidM = {}


local editWid = context:getLua("shared/line_ed/edit_wid")
local widShared = context:getLua("core/wid_shared")


function editWidM.updateTextBatch(self)
	local LE = self.LE
	local text_batch = self.LE_text_batch

	text_batch:clear()

	if LE.font ~= text_batch:getFont() then
		text_batch:setFont(LE.font)
	end

	for i = self.LE_vis_para1, self.LE_vis_para2 do
		local paragraph = LE.paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			text_batch:add(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
		end
	end
end


function editWidM.updateVisibleParagraphs(self)
	local LE = self.LE

	-- Find the first visible display paragraph (or rather, one before it) to cut down on rendering.
	local y_pos = self.scr_y - self.vp2_y

	self.LE_vis_para1 = 1
	for i, paragraph in ipairs(LE.paragraphs) do
		local sub_one = paragraph[1]
		if sub_one.y > y_pos then
			self.LE_vis_para1 = math.max(1, i - 1)
			break
		end
	end

	-- Find the last display paragraph (or one after it) as well.
	self.LE_vis_para2 = #LE.paragraphs
	for i = self.LE_vis_para2, #LE.paragraphs do
		local paragraph = LE.paragraphs[i]
		local sub_last = paragraph[#paragraph]
		if sub_last.y + sub_last.h > y_pos + self.vp2_h then
			self.LE_vis_para2 = i
			break
		end
	end

	--print("updateVisibleParagraphs()", "self.LE_vis_para1", self.LE_vis_para1, "self.LE_vis_para2", self.LE_vis_para2)
end


function editWidM.updatePageJumpSteps(self, font)
	self.LE_page_jump_steps = math.max(1, math.floor(self.vp_h / (font:getHeight() * font:getLineHeight())))
end


--- Call after changing alignment, then update the alignment of all sub-lines.
function editWidM.updateAlignOffset(self)
	local align = self.LE.align

	if align == "left" then
		self.LE_align_ox = 0

	elseif align == "center" then
		self.LE_align_ox = (self.doc_w < self.vp_w) and math.floor(0.5 + self.vp_w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.LE_align_ox = (self.doc_w < self.vp_w) and self.vp_w or self.doc_w
	end
end


function editWidM.updateDocumentDimensions(self)
	local LE = self.LE

	-- height (assumes the final sub-line is current)
	local last_para = LE.paragraphs[#LE.paragraphs]
	local last_sub = last_para[#last_para]

	self.doc_h = last_sub.y + last_sub.h

	-- width
	-- Use viewport #1's width for wrapping text.
	LE.view_w = self.vp_w

	-- When not wrapping, the document width is the widest sub-line.
	if not LE.wrap_mode then
		local x1, x2 = self.LE:getDisplayXBoundaries()
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
	local LE = self.LE

	-- get the extended caret rectangle
	local car_x1 = self.LE_align_ox + LE.caret_box_x - self.LE_caret_extend_x
	local car_y1 = LE.caret_box_y - self.LE_caret_extend_y
	local car_x2 = self.LE_align_ox + LE.caret_box_x + LE.caret_box_w + self.LE_caret_extend_x
	local car_y2 = LE.caret_box_y + LE.caret_box_h + self.LE_caret_extend_y

	widShared.scrollRectInBounds(self, car_x1, car_y1, car_x2, car_y2, immediate)
end


function editWidM.generalUpdate(self, car_shape, dim, car_view, vis_para, txt)
	if car_shape then
		editWid.updateCaretShape(self)
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

	if txt and self.LE_text_batch then
		editWidM.updateTextBatch(self)
	end
end


return editWidM