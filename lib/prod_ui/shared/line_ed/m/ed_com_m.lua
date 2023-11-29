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


--- Given an input line, a byte offset and a specific Paragraph structure, return a byte and sub-line offset suitable for the display structure.
function edComM.coreToDisplayOffsets(line, byte_n, paragraph)

	if #paragraph == 0 then
		error("LineEditor corruption: empty paragraph.")
	end

	-- End of line
	if byte_n == #line + 1 then
		return #paragraph[#paragraph].str + 1, #paragraph

	else
		local code_point_index = utf8.len(line, 1, byte_n)
		local line_sub = 1

		while true do
			if not paragraph[line_sub] then
				error("LineEditor: subline (" .. line_sub .. ") is out of bounds (max: "..#paragraph..")")
			end

			local sub_line_utf8_len = utf8.len(paragraph[line_sub].str)
			if code_point_index <= sub_line_utf8_len then
				break
			end

			code_point_index = code_point_index - sub_line_utf8_len
			line_sub = line_sub + 1
		end

		local ret_byte = utf8.offset(paragraph[line_sub].str, code_point_index)

		return ret_byte, line_sub
	end
end


--- Sorts display caret and highlight offsets from first to last. (Paragraph, sub-line, and byte.)
function edComM.getHighlightOffsetsParagraph(line_1, sub_1, byte_1, line_2, sub_2, byte_2)

	if line_1 == line_2 and sub_1 == sub_2 then
		byte_1, byte_2 = math.min(byte_1, byte_2), math.max(byte_1, byte_2)

	elseif line_1 == line_2 and sub_1 > sub_2 then
		sub_1, sub_2, byte_1, byte_2 = sub_2, sub_1, byte_2, byte_1

	elseif line_1 > line_2 then
		line_1, line_2, sub_1, sub_2, byte_1, byte_2 = line_2, line_1, sub_2, sub_1, byte_2, byte_1
	end

	return line_1, sub_1, byte_1, line_2, sub_2, byte_2
end


--- Given a display-lines object, a Paragraph index, a sub-line index, and a number of steps, get the sub-line 'n_steps' away, or
--  the top or bottom sub-line if reaching the start or end respectively.
function edComM.stepSubLine(display_lines, d_car_para, d_car_sub, n_steps)

	while n_steps < 0 do
		-- First line
		if d_car_para <= 1 and d_car_sub <= 1 then
			d_car_para = 1
			d_car_sub = 1
			break

		else
			d_car_sub = d_car_sub - 1
			if d_car_sub == 0 then
				d_car_para = d_car_para - 1
				d_car_sub = #display_lines[d_car_para]
			end

			n_steps = n_steps + 1
		end
	end

	while n_steps > 0 do
		-- Last line
		if d_car_para >= #display_lines and d_car_sub >= #display_lines[#display_lines] then
			d_car_para = #display_lines
			d_car_sub = #display_lines[#display_lines]
			break

		else
			d_car_sub = d_car_sub + 1

			if d_car_sub > #display_lines[d_car_para] then
				d_car_para = d_car_para + 1
				d_car_sub = 1
			end

			n_steps = n_steps - 1
		end
	end

	return d_car_para, d_car_sub
end


return edComM
