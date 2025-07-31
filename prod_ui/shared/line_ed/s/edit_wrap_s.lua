local context = select(1, ...)


local editWrapS = {}


local utf8 = require("utf8")


local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")


--- Helper that takes care of history changes following an action.
-- @param self The client widget
-- @param func The function to call. It should take 'self' as its first argument; pass any variadic functions along, as
--	well. It should return values that control if and how the lineEditor object is updated. For more info, see the
--	func(self) call here, and also in EditAct.
-- @param [...] Extra arguments for func.
-- @return true if the function reported success, and a boolean indicating if the action was undo/redo.
function editWrapS.wrapAction(self, func, ...)
	local LE = self.LE
	local old_car, old_h = LE.car_byte, LE.h_byte

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
		editFuncS.updateCaretShape(self)
		if update_widget then
			self:updateDocumentDimensions(self)
			self:scrollClampViewport()
		end

		if caret_in_view then
			self:scrollGetCaretInBounds(true)
		end

		if LE.hist.enabled then
			-- 'Delete' and 'backspace' can amend history entries.
			if type(write_history) == "string" then -- "del", "bsp"
				assert(type(deleted) == "string", "expected string for deleted text")
				local cat1, cat2
				if write_history == "bsp" then cat1, cat2 = "backspacing", "backspacing-ws"
				elseif write_history == "del" then cat1, cat2 = "deleting", "deleting-ws" end

				-- Partial / conditional history updates
				local hist = LE.hist
				local non_ws = deleted:find("%S")
				local entry = hist:getEntry()
				local do_advance = true

				if utf8.len(deleted) == 1
				and (entry and entry.car_byte == old_car)
				and ((self.LE_input_category == cat1 and non_ws) or (self.LE_input_category == cat2))
				then
					do_advance = false
				end

				if do_advance then
					editHistS.doctorCurrentCaretOffsets(hist, old_car, old_h)
				end
				editHistS.writeEntry(LE, do_advance)
				self.LE_input_category = non_ws and cat1 or cat2

			-- Unconditional new history entry:
			elseif write_history then
				self.LE_input_category = false

				editHistS.doctorCurrentCaretOffsets(LE.hist, old_car, old_h)
				editHistS.writeEntry(LE, true)
			end
		end

		return true, hist_change
	end
end


return editWrapS
