-- To load: local lib = context:getLua("shared/lib")


-- Data structure: Sequence of Strings.


--local context = select(1, ...)


--[[
MIT License

Copyright (c) 2022, 2023 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local seqString = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local _mt_seq = {}
_mt_seq.__index = _mt_seq


-- * Public Functions *


function seqString.new()
	return setmetatable({""}, _mt_seq)
end


-- * Object Methods *


function _mt_seq:add(text, line_n, byte_pos)

	-- Assertions
	-- [[
	if line_n > #self or line_n < 1 then
		error("line_n is out of range.")

	elseif byte_pos < 0 or byte_pos > #self[line_n] + 1 then
		error("byte_pos is out of range.")
	end
	--]]

	-- Empty string: nothing to do.
	if #text == 0 then
		return line_n, byte_pos
	end

	local byte1 = 1

	-- Split the first target line.
	local line_1 = self[line_n]
	local t1a = string.sub(line_1, 1, byte_pos - 1)
	local t1b = string.sub(line_1, byte_pos)

	-- Get the first destination line.
	local byte2 = string.find(text, "\n", byte1, true)
	local hit_line_feed = byte2 and string.sub(text, byte2, byte2) == "\n" or false
	byte2 = byte2 and byte2 - 1 or #text

	local dest_1 = string.sub(text, byte1, byte2)

	-- Append the first destination line after the first part of the first target line.
	self[line_n] = t1a .. dest_1

	-- Add line feed, if applicable
	if hit_line_feed then
		line_n = line_n + 1
		table.insert(self, line_n, "")
	end

	-- Step over the line feed (or if at end of the destination string, move byte1 out of bounds).
	byte1 = byte2 + 2

	-- Handle the remaining lines, if applicable
	while byte1 <= #text do
		byte2 = string.find(text, "\n", byte1, true)
		local hit_line_feed = byte2 and string.sub(text, byte2, byte2) == "\n" or false
		byte2 = byte2 and byte2 - 1 or #text

		local dest_n = string.sub(text, byte1, byte2)

		self[line_n] = dest_n

		if hit_line_feed then
			line_n = line_n + 1
			table.insert(self, line_n, "")
		end

		byte1 = byte2 + 2
	end

	local ret_byte = #self[line_n] + 1

	-- Append the last part of the first target line onto the last-added line, if applicable.
	if #t1b > 0 then
		self[line_n] = self[line_n] .. t1b
	end

	return line_n, ret_byte
end


function _mt_seq:delete(line_start, byte_start, line_end, byte_end)

	-- Assertions
	-- [[
	if line_start < 1 or line_start > #self then
		error("line_start is out of bounds.")

	elseif line_end < line_start or line_end > #self then
		error("line_end is out of bounds or before line_start.")

	elseif byte_start < 0 or byte_start > #self[line_start] + 1 then
		error("byte_start is out of bounds.")

	elseif byte_end < 0 or byte_end > #self[line_end] + 1 then
		error("byte_end is out of bounds.")
	end
	--]]

	-- Same line
	if line_start == line_end then
		local line = self[line_start]
		local s1 = string.sub(line, 1, byte_start - 1)
		local s3 = string.sub(line, byte_end + 1)

		self[line_start] = s1 .. s3

	-- Spans multiple lines
	else

		-- Handle the last line.
		local last_chunk
		if byte_end < #self[line_end] then
			last_chunk = string.sub(self[line_end], byte_end + 1)
		end
		table.remove(self, line_end)

		-- Handle lines between.
		for i = line_end - 1, line_start + 1, -1 do
			table.remove(self, i)
		end

		-- Handle the first line
		self[line_start] = string.sub(self[line_start], 1, byte_start - 1)

		if last_chunk then
			self[line_start] = self[line_start] .. last_chunk
		end
	end
end


function _mt_seq:copy(line_start, byte_start, line_end, byte_end)

	-- Assertions
	-- [[
	if line_start < 1 or line_start > #self then
		error("line_start is out of bounds.")

	elseif line_end < line_start or line_end > #self then
		error("line_end is out of bounds or before line_start.")

	elseif byte_start < 0 or byte_start > #self[line_start] + 1 then
		error("byte_start is out of bounds.")

	elseif byte_end < 0 or byte_end > #self[line_end] + 1 then
		error("byte_end is out of bounds.")
	end
	--]]

	local str_t = {}

	-- Single line
	if line_start == line_end then
		str_t[1] = string.sub(self[line_start], byte_start, byte_end)
		return str_t
	end

	-- Multi-line

	-- Handle first line
	str_t[1] = string.sub(self[line_start], byte_start)

	-- Handle between lines, if applicable
	for i = line_start + 1, line_end - 1 do
		str_t[#str_t + 1] = self[i]
	end

	-- Handle final line
	str_t[#str_t + 1] = string.sub(self[line_end], 1, byte_end)

	return str_t
end


function _mt_seq:copyString(line_start, byte_start, line_end, byte_end)

	local str = table.concat(self:copy(line_start, byte_start, line_end, byte_end), "\n")

	return str
end


function _mt_seq:len()

	-- Add phantom line feeds
	local byte_count = math.max(0, #self - 1)

	for _, line in ipairs(self) do
		byte_count = byte_count + #line
	end

	return byte_count
end


function _mt_seq:uLen()

	-- Add phantom line feeds
	local u_count = math.max(0, #self - 1)

	for _, line in ipairs(self) do
		u_count = u_count + utf8.len(line)
	end

	return u_count	
end


function _mt_seq:isEmpty()
	return #self == 1 and #self[1] == 0
end


function _mt_seq:offsetStepLeft(line_n, byte_n)

	-- Assertions
	-- [[
	if line_n < 1 or line_n > #self then
		error("line_n is out of range.")

	elseif byte_n < 1 or byte_n > #self[line_n] + 1 then
		error("byte_n is out of range.")
	end
	--]]

	local peeked

	while true do
		byte_n = byte_n - 1

		if byte_n == 0 then
			if line_n == 1 then
				return nil

			else
				line_n = line_n - 1
				byte_n = #self[line_n] + 1
				peeked = 0x0a -- "\n"
				break
			end
		end

		local byte = string.byte(self[line_n], byte_n)
		-- Non-continuation byte
		if byte and not (byte >= 0x80 and byte <= 0xbf) then
			peeked = utf8.codepoint(self[line_n], byte_n)
			break
		end
	end

	return line_n, byte_n, peeked
end


function _mt_seq:offsetStepRight(line_n, byte_n)

	-- Assertions
	-- [[
	if line_n < 1 or line_n > #self then
		error("line_n is out of range.")
	end
	--]]

	local str = self[line_n]
	local peeked

	if byte_n < 1 or byte_n > #str + 1 then
		error("byte_n is out of range.")

	elseif byte_n == #str + 1 then
		if line_n == #self then
			return nil

		else
			line_n = line_n + 1
			byte_n = 1
			peeked = #self[line_n] > 0 and utf8.codepoint(self[line_n], byte_n) or 0x0a
		end

	else
		local byte = string.byte(str, byte_n)

		-- Non-continuation byte
		if byte < 0x80 then
			byte_n = byte_n + 1

		elseif byte < 0xe0 then
			byte_n = byte_n + 2

		elseif byte < 0xf0 then
			byte_n = byte_n + 3

		else
			byte_n = byte_n + 4
		end

		peeked = (byte_n == #str + 1) and 0x0a or utf8.codepoint(self[line_n], byte_n)
	end

	return line_n, byte_n, peeked
end


local offsetStep_fn = {}
offsetStep_fn[-1] = "offsetStepLeft"
offsetStep_fn[1] = "offsetStepRight"
function _mt_seq:offsetStep(dir, line_n, byte_n)
	return self[offsetStep_fn[dir]](self, line_n, byte_n)
end


function _mt_seq:peekCodePoint(line_n, byte_n)

	-- Assertions
	-- [[
	if line_n < 1 or line_n > #self then
		error("line_n is out of bounds.")

	elseif byte_n < 0 or byte_n > #self[line_n] + 1 then
		error("byte_n is out of bounds.")
	end
	--]]

	if byte_n == #self[line_n] + 1 then

		-- End of document
		if line_n == #self then
			return nil

		-- End of line
		else
			return 0x0a -- \n
		end

	else
		return utf8.codepoint(self[line_n], byte_n)
	end
end


function _mt_seq:countUCharsLeft(line_n, byte_n, n_u_chars)

	local count = 0

	while count < n_u_chars do
		local line_new, byte_new = self:offsetStepLeft(line_n, byte_n)

		-- Reached beginning of text
		if not line_new then
			break

		else
			line_n = line_new
			byte_n = byte_new
			count = count + 1
		end
	end

	return line_n, byte_n, count
end


function _mt_seq:countUCharsRight(line_n, byte_n, n_u_chars)

	local count = 0

	while count < n_u_chars do
		local line_new, byte_new = self:offsetStepRight(line_n, byte_n)

		-- Reached end of text
		if not line_new then
			break

		else
			line_n = line_new
			byte_n = byte_new
			count = count + 1
		end
	end

	return line_n, byte_n, count
end


function _mt_seq:peekUChar(line_n, byte_n)
	local code_point = self:peekCodePoint(line_n, byte_n)

	return code_point and utf8.char(code_point) or nil
end


return seqString
