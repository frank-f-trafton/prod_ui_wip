-- To load: local lib = context:getLua("shared/lib")


-- editField common utility functions.


local context = select(1, ...)


local edCom = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")


-- Overwrite these functions with your own clipboard handling code, if applicable.
edCom.getClipboardText = love.system.getClipboardText
edCom.setClipboardText = love.system.setClipboardText


function edCom.validateEncoding(str, bad_byte_policy)

	-- Input is good: nothing to do.
	if utf8Tools.check(str) then
		-- NOTE: As a validator, utf8.len() doesn't catch surrogate pairs.
		-- LÖVE text functions reject code point values in the surrogate range.
		return str

	else
		local str_out = ""
		local byte_n = 1

		while byte_n <= #str do
			local len_ok, bad_byte = utf8.len(str, byte_n)

			-- String is good from byte_n to #str
			if len_ok then
				str_out = str_out .. string.sub(str, byte_n, #str)
				break

			-- Encoding error at 'bad_byte'
			elseif bad_byte_policy == "trim" then
				str_out = string.sub(str, 1, bad_byte - 1)
				break

			elseif bad_byte_policy == "replacement_char" then
				-- One '�' for every unrecognized byte.
				str_out = str_out .. string.sub(str, byte_n, bad_byte - 1) .. "�"
				byte_n = bad_byte + 1

			else -- no policy: return empty string on bad input
				break
			end
		end
	end

	return str_out
end


function edCom.cleanString(str, bad_byte_policy, tabs_to_spaces, allow_line_feed)

	str = edCom.validateEncoding(str, bad_byte_policy)

	if not allow_line_feed then
		-- Stops just before the first line feed.
		str = string.match(str, "^([^\n]*)")
	end

	if tabs_to_spaces then
		str = string.gsub(str, "\t", " ")
	end

	-- Exclude all remaining ASCII control codes, except for tabs (0x09) and line feeds (0x0a) (conditionally excluded above).
	str = string.gsub(str, "[%z\x01-\x08\x0b-\x1f]+", "")

	return str
end


function edCom.countUChars(text, u_char_room) 
	local i = 1
	local byte_count = 0

	while u_char_room > 0 do
		local o1 = utf8.offset(text, i)
		local o2 = utf8.offset(text, i + 1)
		if not o2 then
			break
		end
		u_char_room = u_char_room - 1
		i = i + 1
		byte_count = o2 - 1		
	end

	return byte_count, i - 1
end


function edCom.getUCharSpan(str, i, n_u_chars)

	local u_char_count = 0

	-- [WARN] getUCharSpan() cannot work on empty strings.

	-- Assertions
	-- [[
	if i < 1 or i > #str then
		if #str > 0 then
			error("'i' is out of range.")
		else
			error("this function doesn't work with empty strings (there is no code point to begin counting from).")
		end

	elseif n_u_chars < 0 then
		error("'n_u_chars' must be at least 0.")
	end
	--]]

	while true do
		local byte = string.byte(str, i)

		-- End of string or reached uChar count
		if not byte or u_char_count >= n_u_chars then
			break

		-- One-byte uChars
		elseif byte <= 0x7f then
			i = i + 1

		-- Two-byte
		elseif byte >= 0xc0 and byte <= 0xdf then
			i = i + 2

		-- Three-byte
		elseif byte >= 0xe0 and byte <= 0xef then
			i = i + 3

		-- Four-byte
		elseif byte >= 0xf0 and byte <= 0xf7 then
			i = i + 4

		else
			error("counting uChar length failed.")
		end

		u_char_count = u_char_count + 1
	end

	return i - 1, u_char_count
end


-- UTF-8 Support functions


-- NOTE: The byte search criteria skips over any byte which is within the "continuation byte" range. It assumes the subject string is valid UTF-8.
function edCom.utf8FindLeftStartOctet(str, byte_pos)
	if byte_pos < 1 or byte_pos > #str then
		return nil
	end

	while byte_pos > 0 do
		local byte = string.byte(str, byte_pos)
		if byte < 0x80 or byte > 0xbf then
			return byte_pos
		else
			byte_pos = byte_pos - 1
		end
	end

	return nil
end


function edCom.utf8FindRightStartOctet(str, byte_pos)
	if byte_pos < 1 or byte_pos > #str + 1 then
		return nil
	end

	while true do
		if byte_pos == #str + 1 then
			return byte_pos
		end

		local byte = string.byte(str, byte_pos)
		if byte < 0x80 or byte > 0xbf then
			return byte_pos
		else
			byte_pos = byte_pos + 1
		end
	end

	return nil
end


-- * / UTF-8 Support *


--- Gets caret and highlight lines and offsets in the correct order.
function edCom.sortOffsets(line_1, byte_1, line_2, byte_2)
	-- You may need to subtract 1 from byte_2 to get the correct range.
	if line_1 == line_2 then
		byte_1, byte_2 = math.min(byte_1, byte_2), math.max(byte_1, byte_2)

	elseif line_1 > line_2 then
		line_1, line_2, byte_1, byte_2 = line_2, line_1, byte_2, byte_1
	end

	return line_1, byte_1, line_2, byte_2	
end


function edCom.trimString(text, used, max)

	-- Empty string: nothing to trim.
	if #text == 0 then
		return ""
	end

	local trim_point, u_char_count = edCom.getUCharSpan(text, 1, math.max(0, max - used))

	return string.sub(text, 1, trim_point)
end


function edCom.mergeRanges(a_line_1, a_byte_1, a_line_2, a_byte_2, b_line_1, b_byte_1, b_line_2, b_byte_2)

	local line_1 = math.min(a_line_1, b_line_1)
	local line_2 = math.max(a_line_2, b_line_2)

	local byte_1, byte_2

	if a_line_1 == b_line_1 then
		byte_1 = math.min(a_byte_1, b_byte_1)

	elseif a_line_1 < b_line_1 then
		byte_1 = a_byte_1

	else
		byte_1 = b_byte_1
	end

	if a_line_2 == b_line_2 then
		byte_2 = math.max(a_byte_2, b_byte_2)

	elseif a_line_2 > b_line_2 then
		byte_2 = a_byte_2

	else
		byte_2 = b_byte_2
	end

	return line_1, byte_1, line_2, byte_2
end


return edCom
