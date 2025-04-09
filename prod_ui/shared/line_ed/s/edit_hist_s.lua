-- To load: local lib = context:getLua("shared/lib")


--[[
	LineEditor (single) history implementation.

	IMPORTANT: For password fields, you should disable undo/redo history.
--]]


local context = select(1, ...)


local editHistS = {}


local _mt_hist = {}
_mt_hist.__index = _mt_hist


function editHistS.initEntry(entry, source_line, car_byte, h_byte)
	entry.line = source_line
	entry.car_byte = car_byte
	entry.h_byte = h_byte
end


function editHistS.writeEntry(line_ed, do_advance)
	local hist = line_ed.hist
	if hist.enabled then
		local entry
		if hist.locked_first then
			hist.ledger[1] = hist.ledger[1] or {}
			hist.ledger[2] = hist.ledger[2] or {}
			entry = hist.ledger[2]
		else
			entry = line_ed.hist:writeEntry(do_advance)
		end

		editHistS.initEntry(entry, line_ed.line, line_ed.car_byte, line_ed.h_byte)
		return entry
	end
end


function editHistS.writeLockedFirst(line_ed)
	local hist = line_ed.hist
	assert(hist.locked_first, "called on a history struct without a locked first entry")
	if hist.enabled then
		hist.ledger[1] = hist.ledger[1] or {}
		local entry = hist.ledger[1]
		editHistS.initEntry(entry, line_ed.line, line_ed.car_byte, line_ed.h_byte)
		return entry
	end
end


function editHistS.applyEntry(self, entry)
	print("editHistS.applyEntry", "|"..entry.line.."|", entry.car_byte, entry.h_byte)

	local line_ed = self.line_ed

	line_ed.line = entry.line
	line_ed.car_byte = entry.car_byte
	line_ed.h_byte = entry.h_byte
end


function editHistS.doctorCurrentCaretOffsets(hist, car_byte, h_byte)
	if hist.enabled then
		if not hist.locked_first or (hist.locked_first and hist.pos > 1) then
			local entry = hist.ledger[hist.pos]

			if entry then
				entry.car_byte = car_byte
				entry.h_byte = h_byte
			end
		end
	end
end


-- Deletes all history entries, then writes a new entry based on the current line_ed state.
-- Also clears the widget's input category.
function editHistS.wipeEntries(self)
	local line_ed = self.line_ed

	line_ed.hist:clearAll()
	self:resetInputCategory()
	editHistS.writeEntry(line_ed, true)
end


return editHistS
