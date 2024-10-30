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
	if line_ed.hist.enabled then
		local entry = line_ed.hist:writeEntry(do_advance)
		editHistS.initEntry(entry, line_ed.line, line_ed.car_byte, line_ed.h_byte)
		return entry
	end
end


function editHistS.applyEntry(self, entry)
	local line_ed = self.line_ed

	line_ed.line = entry.line
	line_ed.car_byte = entry.car_byte
	line_ed.h_byte = entry.h_byte
end


function editHistS.doctorCurrentCaretOffsets(hist, car_byte, h_byte)
	local entry = hist.ledger[hist.pos]

	if entry then
		entry.car_byte = car_byte
		entry.h_byte = h_byte
	end
end


return editHistS
