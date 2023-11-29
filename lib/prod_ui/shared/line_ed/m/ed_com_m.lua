-- To load: local lib = context:getLua("shared/lib")


-- LineEditor (multi) common utility functions.


local context = select(1, ...)


local edComM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


-- Overwrite these functions with your own clipboard handling code, if applicable.
edComM.getClipboardText = love.system.getClipboardText
edComM.setClipboardText = love.system.setClipboardText


-- * <Unsorted> *


function edComM.mergeRanges(a_line_1, a_byte_1, a_line_2, a_byte_2, b_line_1, b_byte_1, b_line_2, b_byte_2)

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


--- Given a Paragraph, sub-line offset and byte within the sub-line, get a count of unicode code points from the start to the byte as if it were a single string.
function edComM.displaytoUCharCount(paragraph, sub_i, byte)

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


function edComM.huntWordBoundary(code_groups, lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed)

	--print("huntWordBoundary", "dir", dir, "hit_non_ws", hit_non_ws, "first_group", first_group, "stop_on_line_feed", stop_on_line_feed)

	-- If 'hit_non_ws' is true, this function skips over initial whitespace.

	while true do
		--print("LOOP: huntWordBoundary")
		local line_p, byte_p, peeked = lines:offsetStep(dir, line_n, byte_n)
		--print("line_p", line_p, "byte_p", byte_p, "peeked", peeked)
		--print("^", not peeked and "nil" or peeked == 0x0a and "\\n" or utf8.char(peeked))

		local group = code_groups[peeked]

		--print("group", group)

		-- Beginning or end of document
		if peeked == nil then
			--print("break: peeked == nil")
			if dir == 1 then
				line_n = #lines
				byte_n = #lines[#lines] + 1

			else
				line_n = 1
				byte_n = 1
			end

			break

		-- Hit line feed and instructed to stop, or we're past the initial whitespace and encountered
		-- our first group mismatch
		elseif (stop_on_line_feed and peeked == 0x0a) or (hit_non_ws and group ~= first_group) then
			--print("break: hit_non_ws and group ~= first_group")
			--print("hit_non_ws", hit_non_ws, "group", group, "first_group", first_group, "peeked: ", peeked)
			-- Correct right-dir offsets
			if dir == 1 then
				line_n = line_p
				byte_n = byte_p
			end

			break

		elseif group ~= "whitespace" then
			hit_non_ws = true
			first_group = code_groups[peeked] -- nil means "content" group
		end

		line_n, byte_n = line_p, byte_p
	end

	--print("return line_n", line_n, "byte_n", byte_n)

	return line_n, byte_n
end


return edComM
