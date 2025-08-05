-- Functions, methods and plug-ins for widgets with LineEditor (single) state.


local context = select(1, ...)


local editWidS = {}


local utf8 = require("utf8")


local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
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


--- Helper that takes care of history changes following an action.
-- @param self The client widget
-- @param func The function to call. It should take 'self' as its first argument; pass any variadic functions along, as
--	well. It should return values that control if and how the lineEditor object is updated. For more info, see the
--	func(self) call here, and also the comments at the top of EditCommandS.
-- @param [...] Extra arguments for func.
-- @return true if the function reported success, and a boolean indicating if the action was undo/redo (which is
--	important to some widgets).
function editWidS.wrapAction(self, func, ...)
	local LE = self.LE
	local xcb, xhb = LE:getCaretOffsets() -- old offsets

	local ok, update_widget, caret_in_view, write_history, deleted, hist_change = func(self, ...)

	--[[
	print("wrapAction()",
		"ok", ok,
		"update_widget", update_widget,
		"caret_in_view", caret_in_view,
		"write_history", write_history,
		"deleted", deleted,
		"hist_change", hist_change
	)
	--]]

	if ok then
		editWidS.generalUpdate(self, true, update_widget, caret_in_view, update_widget)

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
				and (entry and entry.cb == xcb)
				and ((self.LE_input_category == cat1 and non_ws) or (self.LE_input_category == cat2))
				then
					do_advance = false
				end

				if do_advance then
					editFuncS.doctorHistoryCaretOffsets(self, xcb, xhb)
				end
				editFuncS.writeHistoryEntry(self, do_advance)
				self.LE_input_category = non_ws and cat1 or cat2

			-- Unconditional new history entry:
			elseif write_history then
				self.LE_input_category = false

				editFuncS.doctorHistoryCaretOffsets(self, xcb, xhb)
				editFuncS.writeHistoryEntry(self, true)
			end
		end

		return true, hist_change
	end
end


return editWidS