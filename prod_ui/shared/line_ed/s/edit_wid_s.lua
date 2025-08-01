-- Functions, methods and plug-ins for widgets with LineEditor (single) state.


local context = select(1, ...)


local editWidS = {}


local editWid = context:getLua("shared/line_ed/edit_wid")
local widShared = context:getLua("core/wid_shared")


function editWidS.updateTextBatch(self)
	local LE = self.LE
	local text_batch = self.LE_text_batch

	text_batch:clear()

	if LE.font ~= text_batch:getFont() then
		text_batch:setFont(LE.font)
	end

	text_batch:add(LE.colored_text or LE.line, 0, 0)
end


function editWidS.updateDocumentDimensions(self)
	local LE = self.LE
	local font = LE.font

	--[[
	The document width is the larger of: 1) viewport width, 2) text width (plus an empty caret slot).
	When alignment is center or right and the text is smaller than the viewport, the text, caret,
	etc. are transposed.
	--]]
	self.doc_w = math.max(self.vp_w, LE.disp_text_w)
	self.doc_h = math.floor(font:getHeight() * font:getLineHeight())

	local align = LE.align
	if align == "left" then
		self.LE_align_ox = 0

	elseif align == "center" then
		self.LE_align_ox = math.max(0, (self.vp_w - LE.disp_text_w) * .5)

	else -- align == "right"
		self.LE_align_ox = math.max(0, self.vp_w - LE.disp_text_w)
	end
end


function editWidS.scrollGetCaretInBounds(self, immediate)
	local LE = self.LE

	-- get the extended caret rectangle
	local car_x1 = self.LE_align_ox + LE.caret_box_x - self.LE_caret_extend_x
	local car_y1 = LE.caret_box_y
	local car_x2 = self.LE_align_ox + LE.caret_box_x + math.max(LE.caret_box_w, LE.caret_box_w_edge) + self.LE_caret_extend_x
	local car_y2 = LE.caret_box_y + LE.caret_box_h

	widShared.scrollRectInBounds(self, car_x1, car_y1, car_x2, car_y2, immediate)
end


function editWidS.generalUpdate(self, car_shape, dim, car_view, txt)
	if car_shape then
		editWid.updateCaretShape(self)
	end

	if dim then
		editWidS.updateDocumentDimensions(self)
	end

	if car_view then
		self:scrollGetCaretInBounds(true)
	end

	if txt and self.LE_text_batch then
		editWidS.updateTextBatch(self)
	end
end


return editWidS