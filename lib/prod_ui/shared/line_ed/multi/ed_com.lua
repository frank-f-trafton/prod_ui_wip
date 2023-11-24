-- To load: local lib = context:getLua("shared/lib")


-- LineEditor common utility functions.


local context = select(1, ...)


local edCom = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


-- Overwrite these functions with your own clipboard handling code, if applicable.
edCom.getClipboardText = love.system.getClipboardText
edCom.setClipboardText = love.system.setClipboardText


function edCom.cleanString(str, bad_byte_policy, tabs_to_spaces, allow_line_feed)

	str = textUtil.sanitize(str, bad_byte_policy)

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


-- * <Unsorted> *


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


--[=[
-- XXX: to be used with single-line versions of text boxes.
function edCom.getDisplayTextSingle(text, font, replace_missing, masked)

	local display_text = text
	if masked then
		display_text = textUtil.getMaskedString(display_text, "*")

	elseif replace_missing then
		display_text = textUtil.replaceMissingCodePointGlyphs(display_text, font, "□")
	end

	return display_text
end
--]=]


--- Given a Paragraph, sub-line offset and byte within the sub-line, get a count of unicode code points from the start to the byte as if it were a single string.
function edCom.displaytoUCharCount(paragraph, sub_i, byte)

	local string_one = paragraph[sub_i].str

	-- 'byte' can be one past the end of the string to represent the caret being at the final position.
	-- However, arg #3 to utf8.len() cannot exceed the size of the string (though arg #3 can handle offsets
	-- on UTF-8 continuation bytes).
	local plus_one = 0
	if byte > #string_one then
		plus_one = 1
		byte = byte - 1
	end

	local u_count = utf8.len(string_one, 1, byte)

	--print("string_one", string_one)
	--print("initial u_count", u_count)

	for i = 1, sub_i - 1 do
		u_count = u_count + utf8.len(paragraph[i].str)
		--print("i", i, "u_count", u_count)
	end

	--print("final u_count", u_count + plus_one)

	return u_count + plus_one
end


return edCom
