local context = select(1, ...)


local editWrapM = {}


local utf8 = require("utf8")


local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editWidM = context:getLua("shared/line_ed/m/edit_wid_m")


function editWrapM.wrapAction(self, func, ...)
	local line_ed = self.line_ed
	local xcl, xcb, xhl, xhb = line_ed:getCaretOffsets() -- old offsets

	local ok, update_widget, caret_in_view, write_history, deleted, hist_change = func(self, ...)

	--[[
	print("wrapAction()", "ok", ok, "update_widget", update_widget, "caret_in_view", caret_in_view,
		"write_history", write_history, "deleted", deleted, "hist_change", hist_change
	)
	--]]

	if ok then
		editWidM.generalUpdate(self, true, update_widget, caret_in_view, update_widget, update_widget)

		local hist = self.hist
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
				and ((self.input_category == cat1 and non_ws) or (self.input_category == cat2))
				then
					do_advance = false
				end

				if do_advance then
					editFuncM.doctorHistoryCaretOffsets(self, xcl, xcb, xhl, xhb)
				end
				editFuncM.writeHistoryEntry(self, do_advance)
				self.input_category = non_ws and cat1 or cat2

			-- Unconditional new history entry:
			elseif write_history then
				self.input_category = false

				editFuncM.doctorHistoryCaretOffsets(self, xcl, xcb, xhl, xhb)
				editFuncM.writeHistoryEntry(self, true)
			end
		end

		return true, hist_change
	end
end


return editWrapM
