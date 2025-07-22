-- LineEditor (multi) common utility functions.


local context = select(1, ...)


local edComM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


function edComM.mergeRanges(al1, ab1, al2, ab2, bl1, bb1, bl2, bb2)
	-- a, b: first, second ranges
	-- l, b: line, byte
	local l1, l2 = math.min(al1, bl1), math.max(al2, bl2)
	local b1 = al1 == bl1 and math.min(ab1, bb1) or al1 < bl1 and ab1 or bb1
	local b2 = al2 == bl2 and math.max(ab2, bb2) or al2 > bl2 and ab2 or bb2

	return l1, b1, l2, b2
end


--- Given a Paragraph, sub-line offset and byte within the sub-line, get a count of unicode code points from the start
--	to the byte as if it were a single string.
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

	for i = 1, sub_i - 1 do
		u_count = u_count + utf8.len(paragraph[i].str)
	end

	return u_count + plus_one
end


-- @param hit_non_ws When true, skips over initial whitespace.
function edComM.huntWordBoundary(code_groups, lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed)
	while true do
		local line_p, byte_p, peeked = lines:offsetStep(dir, line_n, byte_n)
		local group = code_groups[peeked]

		-- Beginning or end of document
		if peeked == nil then
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
function edComM.getHighlightOffsetsParagraph(l1, s1, b1, l2, s2, b2)
	-- l, s, b == line, sub-line, byte
	if l1 == l2 and s1 == s2 then
		b1, b2 = math.min(b1, b2), math.max(b1, b2)

	elseif l1 == l2 and s1 > s2 then
		s1, s2, b1, b2 = s2, s1, b2, b1

	elseif l1 > l2 then
		l1, l2, s1, s2, b1, b2 = l2, l1, s2, s1, b2, b1
	end

	return l1, s1, b1, l2, s2, b2
end


--- Given a display-lines object, a Paragraph index, a sub-line index, and a number of steps, get the sub-line 'n_steps' away, or
--  the top or bottom sub-line if reaching the start or end respectively.
function edComM.stepSubLine(display_lines, d_car_para, d_car_sub, n_steps)
	while n_steps < 0 do
		-- first line
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
		-- last line
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


function edComM.applyCaretAlignOffset(caret_x, line_str, align, font)
	if align == "left" then
		-- n/a

	elseif align == "center" then
		caret_x = caret_x + math.floor(0.5 - font:getWidth(line_str) / 2)

	elseif align == "right" then
		caret_x = caret_x - font:getWidth(line_str)
	end

	return caret_x
end


--- Gets the starting code point index for a sub-line.
function edComM.getSubLineUCharOffsetStart(para, sub_i)
	local u_count = 1

	for i = 1, sub_i - 1 do
		u_count = u_count + utf8.len(para[i].str)
	end

	return u_count
end


--- Gets the ending code point index for a sub-line.
function edComM.getSubLineUCharOffsetEnd(para, sub_i)
	local u_count = 0

	for i = 1, sub_i do
		u_count = u_count + utf8.len(para[i].str)
	end

	-- End of the Paragraph: add one more byte past the end.
	if sub_i >= #para then
		u_count = u_count + 1
	end

	return u_count
end


--- Gets both the starting and ending code point indices for a sub-line.
function edComM.getSubLineUCharOffsetStartEnd(para, sub_i)
	local u_count_1, u_count_2 = 1, nil

	for i = 1, sub_i - 1 do
		u_count_1 = u_count_1 + utf8.len(para[i].str)
	end
	u_count_2 = u_count_1 + utf8.len(para[sub_i].str) - 1

	-- End of the Paragraph: add one more byte past the end.
	if sub_i >= #para then
		u_count_2 = u_count_2 + 1
	end

	return u_count_1, u_count_2
end


return edComM
