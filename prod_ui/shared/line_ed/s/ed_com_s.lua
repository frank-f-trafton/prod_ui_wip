-- To load: local lib = context:getLua("shared/lib")


-- LineEditor (single) common utility functions.


local context = select(1, ...)


local edComS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


function edComS.huntWordBoundary(code_groups, line, byte_n, dir, hit_non_ws, first_group)
	--print("(Single) huntWordBoundary", "line", line, "byte_n", byte_n, "dir", dir, "hit_non_ws", hit_non_ws, "first_group", first_group)

	-- If 'hit_non_ws' is true, this function skips over initial whitespace.

	while true do
		--print("LOOP: huntWordBoundary")

		--print("line", line, "dir", dir, "byte_n", byte_n)
		local byte_p, peeked = edComS.offsetStep(line, dir, byte_n)
		local group = code_groups[peeked]

		--print("byte_p", byte_p, "peeked", peeked)
		--print("group", group)

		-- Beginning or end of document
		if peeked == nil then
			--print("break: peeked == nil")
			byte_n = (dir == 1) and #line + 1 or 1
			break

		-- We're past the initial whitespace and have encountered our first group mismatch.
		elseif hit_non_ws and group ~= first_group then
			--print("break: hit_non_ws and group ~= first_group")
			--print("hit_non_ws", hit_non_ws, "group", group, "first_group", first_group, "peeked: ", peeked)
			-- Correct right-dir offsets
			if dir == 1 then
				byte_n = byte_p
			end

			break

		elseif group ~= "whitespace" then
			hit_non_ws = true
			first_group = code_groups[peeked] -- nil means "content" group
		end

		byte_n = byte_p
	end

	--print("return byte_n", byte_n)

	return byte_n
end


--- Given an input line, an input byte offset, and an output line, return a byte offset suitable for the output line.
function edComS.coreToDisplayOffsets(line_in, byte_n, line_out)
	-- End of line
	if byte_n == #line_in + 1 then
		return #line_out + 1
	else
		local code_point_index = utf8.len(line_in, 1, byte_n)
		local offset = utf8.offset(line_out, code_point_index)

		return offset
	end
end


function edComS.displaytoUCharCount(str, byte)
	-- 'byte' can be one past the end of the string to represent the caret being at the final position.
	-- However, arg #3 to utf8.len() cannot exceed the size of the string (though arg #3 can handle offsets
	-- on UTF-8 continuation bytes).
	local plus_one = 0
	if byte > #str then
		plus_one = 1
		byte = byte - 1
	end

	print("|" .. str .. "|", byte)
	local u_count = utf8.len(str, 1, byte)

	--print("", "str", str)
	--print("", "u_count", u_count, "plus_one", plus_one)

	return u_count + plus_one
end


function edComS.add(line, added, pos)
	if pos < 0 or pos > #line + 1 then error("position is out of range") end

	-- empty string: nothing to do
	if #added == 0 then return line, pos end

	return line:sub(1, pos - 1) .. added .. line:sub(pos), pos + #added
end


function edComS.delete(line, byte_start, byte_end)
	if byte_start < 0 or byte_start > #line + 1 then error("byte_start is out of bounds")
	elseif byte_end < 0 or byte_end > #line + 1 then error("byte_end is out of bounds") end

	return line:sub(1, byte_start - 1) .. line:sub(byte_end + 1)
end


function edComS.offsetStepLeft(line, byte_n)
	if byte_n < 1 or byte_n > #line + 1 then error("byte_n is out of range") end

	local peeked

	while true do
		byte_n = byte_n - 1
		local byte = line:byte(byte_n)

		if not byte then
			return nil
		end

		-- Non-continuation byte
		if not (byte >= 0x80 and byte <= 0xbf) then
			peeked = utf8.codepoint(line, byte_n)
			break
		end
	end

	return byte_n, peeked
end


function edComS.offsetStepRight(line, byte_n)
	if byte_n < 1 or byte_n > #line + 1 then error("byte_n is out of range.") end

	local peeked
	byte_n = byte_n + 1

	while true do
		local byte = line:byte(byte_n)

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

	peeked = utf8.codepoint(line, byte_n)

	return byte_n, peeked
end


local offsetStep_fn = {}
offsetStep_fn[-1] = "offsetStepLeft"
offsetStep_fn[1] = "offsetStepRight"
function edComS.offsetStep(line, dir, byte_n)
	return edComS[offsetStep_fn[dir]](line, byte_n)
end


function edComS.countUChars(line, dir, byte_n, n_u_chars)
	local count = 0
	while count < n_u_chars do
		local byte_new = edComS.offsetStep(line, dir, byte_n)

		-- Reached beginning or end
		if not byte_new then
			break
		else
			byte_n = byte_new
			count = count + 1
		end
	end

	return byte_n, count
end


return edComS
