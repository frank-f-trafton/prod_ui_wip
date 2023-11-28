-- To load: local lib = context:getLua("shared/lib")


-- Provides seqString-like functions for single lines of text.


--local context = select(1, ...)


local lineManip = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


function lineManip.add(line, text, byte_pos)

	-- Assertions.
	-- [[
	if byte_pos < 0 or byte_pos > #line + 1 then
		error("byte_pos is out of range.")
	end
	--]]

	-- Empty string: nothing to do.
	if #text == 0 then
		return line, byte_pos
	end

	local ret1, ret2 = string.sub(line, 1, byte_pos - 1) .. text .. string.sub(line, byte_pos), byte_pos + #text
	print("lineManip.add(): ret1:", ret1, "ret2:", ret2)
	return ret1, ret2
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



function lineManip.offsetStepLeft(text, byte_n)

	-- Assertions
	-- [[
	if byte_n < 1 or byte_n > #text + 1 then
		error("byte_n is out of range.")
	end
	--]]

	local peeked

	while true do
		byte_n = byte_n - 1
		local byte = string.byte(text, byte_n)

		if byte_n == 0 or not byte then
			return nil
		end

		-- Non-continuation byte
		if not (byte >= 0x80 and byte <= 0xbf) then
			peeked = utf8.codepoint(text, byte_n)
			break
		end
	end

	return byte_n, peeked
end


function lineManip.offsetStepRight(text, byte_n)

	-- Assertions
	-- [[
	if byte_n < 1 or byte_n > #text + 1 then
		error("byte_n is out of range.")
	end
	--]]

	local peeked

	while true do
		if byte_n == #text + 1 then
			return nil
		end

		local byte = string.byte(text, byte_n)

		-- Non-continuation byte
		if byte < 0x80 then
			byte_n = byte_n + 1
			break

		elseif byte < 0xe0 then
			byte_n = byte_n + 2
			break

		elseif byte < 0xf0 then
			byte_n = byte_n + 3
			break

		elseif byte < 0xf8 then
			byte_n = byte_n + 4
			break

		-- Continuation byte
		else
			byte_n = byte_n + 1
		end
	end

	peeked = utf8.codepoint(text, byte_n)

	return byte_n, peeked
end


local offsetStep_fn = {}
offsetStep_fn[-1] = "offsetStepLeft"
offsetStep_fn[1] = "offsetStepRight"
function lineManip.offsetStep(text, dir, byte_n)
	return lineManip[offsetStep_fn[dir]](text, byte_n)
end


return lineManip
