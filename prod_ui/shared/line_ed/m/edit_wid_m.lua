-- Functions, methods and plug-ins for widgets with LineEditor (multi) state.


local context = select(1, ...)


local editWidM = {}


local utf8 = require("utf8")


local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
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
	local y_pos = self.scr_y - self.vp2.y

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
		if sub_last.y + sub_last.h > y_pos + self.vp2.h then
			self.LE_vis_para2 = i
			break
		end
	end

	--print("updateVisibleParagraphs()", "self.LE_vis_para1", self.LE_vis_para1, "self.LE_vis_para2", self.LE_vis_para2)
end


function editWidM.updatePageJumpSteps(self, font)
	self.LE_page_jump_steps = math.max(1, math.floor(self.vp.h / (font:getHeight() * font:getLineHeight())))
end


function editWidM.getLineNumberColumnWidth(self)
	local skin = self.skin
	local x1, x2 = skin.lnc_x1, skin.lnc_x2
	local digit_w, reserved = self.LE_lnc_digit_w, skin.lnc_reserved
	local digits = math.max(reserved, 1 + math.floor(math.log10(#self.LE.lines))) -- ie editWidM.getLineNumberColumnDigitCount()
	return (digit_w*digits + x1 + x2)
end


function editWidM.getLineNumberColumnDigitCount(self)
	local LE = self.LE
	return math.max(self.skin.lnc_reserved, 1 + math.floor(math.log10(#LE.lines)))
end


function editWidM.updateDocumentDimensions(self)
	local LE = self.LE
	local vp = self.vp

	-- vp #1 is assumed to be correct here.

	-- height (assumes the final sub-line is current)
	local last_para = LE.paragraphs[#LE.paragraphs]
	local last_sub = last_para[#last_para]

	self.doc_h = last_sub.y + last_sub.h

	-- width
	-- When not wrapping, the document width is the widest sub-line.
	if not LE.wrap_mode then
		local x1, x2 = self.LE:getDisplayXBoundaries()
		self.doc_w = (x2 - x1)

	-- When wrapping, the document width is fixed to the viewport width.
	-- (Reason: to prevent horizontal scrolling when wrapped text contains
	-- trailing whitespace.)
	else
		self.doc_w = vp.w
	end

	local align = self.LE.align
	if align == "left" then
		self.LE_align_ox = 0

	elseif align == "center" then
		self.LE_align_ox = (self.doc_w < vp.w) and math.floor(0.5 + vp.w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.LE_align_ox = (self.doc_w < vp.w) and vp.w or self.doc_w
	end
end


function editWidM.scrollGetCaretInBounds(self, immediate)
	local LE = self.LE

	-- get the extended caret rectangle
	local car_x1 = self.LE_align_ox + LE.caret_box_x - self.LE_caret_extend_x
	local car_x2 = self.LE_align_ox + LE.caret_box_x + self.LE_caret_extend_x
	local car_y1 = LE.caret_box_y - self.LE_caret_extend_y
	local car_y2 = LE.caret_box_y + LE.caret_box_h + self.LE_caret_extend_y

	widShared.scrollRectInBounds(self, car_x1, car_y1, car_x2, car_y2, immediate)
end


function editWidM.generalUpdate(self, car_shape, dim, car_view, vis_para, batch, text_changed)
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

	if batch and self.LE_text_batch then
		editWidM.updateTextBatch(self)
	end

	if text_changed and self.LE_textChanged then
		self:LE_textChanged()
	end
end


function editWidM.updateDuringReshape(self)
	local LE = self.LE
	local new_wrap = self.vp.w

	if LE.font ~= self.LE_last_font or LE.wrap_w ~= new_wrap then
		LE:setWrapWidth(new_wrap)
		LE:updateDisplayText()
		LE:syncDisplayCaretHighlight()
		editWidM.generalUpdate(self, true, true, false, true, true, false)
		editWidM.updatePageJumpSteps(self, self.LE.font)
		self.LE_last_font = LE.font
	end
end


function editWidM.wrapAction(self, func, ...)
	local LE = self.LE
	local xcl, xcb, xhl, xhb = LE:getCaretOffsets() -- old offsets

	local ok, update_widget, caret_in_view, write_history, deleted, hist_change = func(self, ...)

	--[[
	print("wrapAction()", "ok", ok, "update_widget", update_widget, "caret_in_view", caret_in_view,
		"write_history", write_history, "deleted", deleted, "hist_change", hist_change
	)
	--]]

	if ok then
		editWidM.generalUpdate(self, true, update_widget, caret_in_view, update_widget, update_widget, update_widget)

		local hist = self.LE_hist
		if hist.enabled then
			-- 'Delete' and 'backspace' can amend history entries.
			if type(write_history) == "string" then -- "del", "bsp"
				assert(type(deleted) == "string", "expected string for deleted text")
				local cat1, cat2
				if write_history == "bsp" then cat1, cat2 = "backspacing", "backspacing-ws"
				elseif write_history == "del" then cat1, cat2 = "deleting", "deleting-ws" end

				-- Partial / conditional history updates
				local non_ws = deleted:find("%S")
				local entry = hist:getEntry()
				local do_advance = true

				if utf8.len(deleted) == 1
				and (entry and entry.cl == xcl and entry.cb == xcb)
				and ((self.LE_input_category == cat1 and non_ws) or (self.LE_input_category == cat2))
				then
					do_advance = false
				end

				if do_advance then
					editFuncM.doctorHistoryCaretOffsets(self, xcl, xcb, xhl, xhb)
				end
				editFuncM.writeHistoryEntry(self, do_advance)
				self.LE_input_category = non_ws and cat1 or cat2

			-- Unconditional new history entry:
			elseif write_history then
				self.LE_input_category = false

				editFuncM.doctorHistoryCaretOffsets(self, xcl, xcb, xhl, xhb)
				editFuncM.writeHistoryEntry(self, true)
			end
		end

		return true, hist_change
	end
end


return editWidM