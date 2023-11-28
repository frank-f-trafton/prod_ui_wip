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


-- * <Unsorted> *


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
