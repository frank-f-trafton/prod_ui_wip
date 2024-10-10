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
	print("text", text, "byte_n", byte_n)
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

		if not byte then
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

	byte_n = byte_n + 1

	while true do
		local byte = string.byte(text, byte_n)

		if not byte then
			return nil

		-- Continuation byte.
		elseif (byte >= 0x80 and byte <= 0xbf) then
			byte_n = byte_n + 1

		-- Non-continuation byte.
		else
			break
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


function lineManip.countUChars(text, dir, byte_n, n_u_chars)
	local count = 0

	while count < n_u_chars do
		local byte_new = lineManip.offsetStep(text, dir, byte_n)

		-- Reached beginning or end of text
		if not byte_new then
			break

		else
			byte_n = byte_new
			count = count + 1
		end
	end

	return byte_n, count
end


return lineManip
