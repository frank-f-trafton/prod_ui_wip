-- To load: local lib = context:getLua("shared/lib")


-- Provides seqString-like functions for single lines of text.


--local context = select(1, ...)


local lineManip = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


function lineManip.add(text, byte_pos)

	-- Assertions.
	-- [[
	if byte_pos < 0 or byte_pos > #self[line_n] + 1 then
		error("byte_pos is out of range.")
	end
	--]]

	-- Empty string: nothing to do.
	if #text == 0 then
		return byte_pos
	end

	return string.sub(text, 1, byte_pos - 1) .. text .. string.sub(text, byte_pos), byte_pos + #text
end


function lineManip.delete(text, byte_start, byte_end)

	-- Assertions
	-- [[
	if byte_start < 0 or byte_start > #text + 1 then
		error("byte_start is out of bounds.")

	elseif byte_end < 0 or byte_end > #text + 1 then
		error("byte_end is out of bounds.")
	end
	--]]

	return string.sub(text, 1, byte_start - 1) .. string.sub(text, byte_end + 1)
end


return lineManip
