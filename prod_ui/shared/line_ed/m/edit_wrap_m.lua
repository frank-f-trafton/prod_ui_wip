local context = select(1, ...)


local editWrapM = {}


local utf8 = require("utf8")


local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")


function editWrapM.wrapAction(self, func, ...)
	local line_ed = self.line_ed
	local old_cl, old_cb, old_hl, old_hb = line_ed:getCaretOffsets()

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
		editFuncM.updateCaretShape(self)
		if update_widget then
			self:updateDocumentDimensions(self)
			self:scrollClampViewport()
		end

		if caret_in_view then
			self:scrollGetCaretInBounds(true)
		end

		if line_ed.hist.enabled then
			-- 'Delete' and 'backspace' can amend history entries.
			if type(write_history) == "string" then -- "del", "bsp"
				assert(type(deleted) == "string", "expected string for deleted text")
				local cat1, cat2
				if write_history == "bsp" then cat1, cat2 = "backspacing", "backspacing-ws"
				elseif write_history == "del" then cat1, cat2 = "deleting", "deleting-ws" end

				-- Partial / conditional history updates
				local hist = line_ed.hist
				local non_ws = string.find(deleted, "%S")
				local entry = hist:getEntry()
				local do_advance = true

				if utf8.len(deleted) == 1
				and (entry and entry.car_line == old_cl and entry.car_byte == old_cb)
				and ((self.input_category == cat1 and non_ws) or (self.input_category == cat2))
				then
					do_advance = false
				end

				if do_advance then
					editHistM.doctorCurrentCaretOffsets(hist, old_cl, old_cb, old_hl, old_hb)
				end
				editHistM.writeEntry(line_ed, do_advance)
				self.input_category = non_ws and cat1 or cat2

			-- Unconditional new history entry:
			elseif write_history then
				self.input_category = false

				editHistM.doctorCurrentCaretOffsets(line_ed.hist, old_cl, old_cb, old_hl, old_hb)
				editHistM.writeEntry(line_ed, true)
			end
		end

		return true, hist_change
	end
end


return editWrapM
