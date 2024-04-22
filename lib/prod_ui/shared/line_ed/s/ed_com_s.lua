-- To load: local lib = context:getLua("shared/lib")


-- LineEditor (single) common utility functions.


local context = select(1, ...)


local edComS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local lineManip = context:getLua("shared/line_ed/line_manip")


--[=[
-- XXX: to be used with single-line versions of text boxes.
function edComS.getDisplayTextSingle(text, font, replace_missing, masked)

	local display_text = text
	if masked then
		display_text = textUtil.getMaskedString(display_text, "*")

	elseif replace_missing then
		display_text = textUtil.replaceMissingCodePointGlyphs(display_text, font, "□")
	end

	return display_text
end
--]=]


function edComS.huntWordBoundary(code_groups, line, byte_n, dir, hit_non_ws, first_group)

	print("(Single) huntWordBoundary", "line", line, "byte_n", byte_n, "dir", dir, "hit_non_ws", hit_non_ws, "first_group", first_group)

	-- If 'hit_non_ws' is true, this function skips over initial whitespace.

	while true do
		print("LOOP: huntWordBoundary")

		print("line", line, "dir", dir, "byte_n", byte_n)
		local byte_p, peeked = lineManip.offsetStep(line, dir, byte_n)
		local group = code_groups[peeked]

		print("byte_p", byte_p, "peeked", peeked)
		print("group", group)

		-- Beginning or end of document
		if peeked == nil then
			print("break: peeked == nil")
			byte_n = (dir == 1) and #line + 1 or 1
			break

		-- We're past the initial whitespace and have encountered our first group mismatch.
		elseif hit_non_ws and group ~= first_group then
			print("break: hit_non_ws and group ~= first_group")
			print("hit_non_ws", hit_non_ws, "group", group, "first_group", first_group, "peeked: ", peeked)
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

	print("return byte_n", byte_n)

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

	local u_count = utf8.len(str, 1, byte)

	--print("", "str", str)
	--print("", "u_count", u_count, "plus_one", plus_one)

	return u_count + plus_one
end


local number_ptn = {
	binary = "^[01]+$",
	octal = "^[0-7]+$",
	decimal = "^[0-9%.%-]+$",
	decimal_exp = "^[%d%.%-%+e]+$",
	hexadecimal = "^%x+$",
}


--- Check text input for number boxes.
function edComS.checkNumberInput(str, number_mode)

	assert(number_ptn[number_mode], "invalid number_mode.")

	-- Strip leading and trailing whitespace.
	str = string.match(str, "^%s*(.-)%s*$")

	return string.find(str, number_ptn[number_mode])
end


--[[
if true then
	print("testing checkNumberInput()")

	local test = {
		{"binary", "0"},
		{"binary", "1"},
		{"binary", "01"},
		{"binary", "10"},
		{"binary", " 10 "},
		{"binary", "1 0"}, -- fail
		{"octal", "-1"}, -- fail
		{"octal", "0"},
		{"octal", "1"},
		{"octal", "2"},
		{"octal", "3"},
		{"octal", "4"},
		{"octal", "5"},
		{"octal", "6"},
		{"octal", "7"},
		{"octal", "8"}, -- fail
		{"octal", " 01234567 "},
		{"decimal", "0.0.0"}, -- pass
		{"decimal", "-----1"}, -- pass
		{"decimal_exp", "-+1e..."}, -- pass
		{"hexadecimal", "0123456789abcdefABCDEF"}, -- pass
		{"hexadecimal", "1.1"}, -- fail
	}

	for i, tbl in ipairs(test) do
		print("mode", tbl[1], "input", tbl[2], "test", edComS.checkNumberInput(tbl[2], tbl[1]))
	end

	os.exit()
end
--]]


return edComS
