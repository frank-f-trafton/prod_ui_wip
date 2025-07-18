-- LineEditor (multi-line) history implementation.


local context = select(1, ...)


local editHistM = {}


local _mt_hist = {}
_mt_hist.__index = _mt_hist


function editHistM.initEntry(entry, source_lines, car_line, car_byte, h_line, h_byte)
	entry.lines = entry.lines or {}

	for i = #entry.lines, #source_lines + 1, -1 do
		entry.lines[i] = nil
	end
	for i = 1, #source_lines do
		entry.lines[i] = source_lines[i]
	end

	entry.car_line = car_line
	entry.car_byte = car_byte
	entry.h_line = h_line
	entry.h_byte = h_byte
end


function editHistM.writeEntry(line_ed, do_advance)
	local entry = line_ed.hist:writeEntry(do_advance)
	editHistM.initEntry(entry, line_ed.lines, line_ed.car_line, line_ed.car_byte, line_ed.h_line, line_ed.h_byte)
	return entry
end


function editHistM.applyEntry(self, entry)
	local line_ed = self.line_ed
	local line_ed_lines = line_ed.lines
	local entry_lines = entry.lines

	for i = 1, #entry_lines do
		line_ed_lines[i] = entry_lines[i]
	end
	for i = #line_ed_lines, #entry_lines + 1, -1 do
		line_ed_lines[i] = nil
	end

	line_ed.car_line = entry.car_line
	line_ed.car_byte = entry.car_byte
	line_ed.h_line = entry.h_line
	line_ed.h_byte = entry.h_byte
end


function editHistM.doctorCurrentCaretOffsets(hist, car_line, car_byte, h_line, h_byte)
	local entry = hist.ledger[hist.pos]

	if entry then
		entry.car_line = car_line
		entry.car_byte = car_byte
		entry.h_line = h_line
		entry.h_byte = h_byte
	end
end


return editHistM
