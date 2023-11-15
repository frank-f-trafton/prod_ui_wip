-- To load: local lib = context:getLua("shared/lib")


-- editField common visual functions.
-- Put stuff that requires a LÖVE font here.


local context = select(1, ...)


local edVis = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edCom = context:getLua("shared/edit_field/ed_com")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


function edVis.getDisplayTextSingle(text, font, replace_missing, masked)

	local display_text = text
	if masked then
		display_text = textUtil.getMaskedString(display_text, "*")

	elseif replace_missing then
		display_text = textUtil.replaceMissingCodePointGlyphs(display_text, font, "□")
	end

	return display_text
end


function edVis.countToWidth(text, font, width)

	local pixels = 0
	local byte = 1
	local u_char_count = 0

	local last_glyph = false

	while byte <= #text do

		if pixels >= width then
			break
		end

		local byte_2 = utf8.offset(text, 2, byte)
		if byte_2 == nil then
			break
		end

		-- [UPGRADE] Use codepoint integers in LÖVE 12
		local ch = string.sub(text, byte, byte_2 - 1)

		pixels = pixels + font:getWidth(ch)

		if last_glyph then
			pixels = pixels + font:getKerning(last_glyph, ch)
		end

		last_glyph = ch
		byte = byte_2
		u_char_count = u_char_count + 1
	end

	--print("pixels", pixels, "byte", byte, "u_char_count", u_char_count)

	return pixels, byte, u_char_count
end


--- Given a super-line, sub-line offset and byte within the sub-line, get a count of unicode code points from the start to the byte as if it were a single string.
function edVis.displaytoUCharCount(super_line, sub_i, byte)

	local string_one = super_line[sub_i].str

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
		u_count = u_count + utf8.len(super_line[i].str)
		--print("i", i, "u_count", u_count)
	end

	--print("final u_count", u_count + plus_one)

	return u_count + plus_one
end


local color_seq_dummy = {}
--- Create or update an alternating coloredtext table. Odd indices are colors, even indices are code point strings.
-- @param str The input string.
-- @param text_t (nil) An existing coloredtext table to recycle, if applicable.
-- @param col_t ({1,1,1,1}) An existing color table to recycle, if applicable.
-- @param color_seq (nil) A table of existing color tables to apply to the code points, if applicable.
-- @return The coloredtext table.
function edVis.stringToColoredText(str, text_t, col_t, color_seq)

	text_t = text_t or {}
	col_t = col_t or {1, 1, 1, 1}
	color_seq = color_seq or color_seq_dummy

	local old_text_len = #text_t

	local i = 1 -- byte in str
	local j = 1 -- index in coloredtext array

	while i <= #str do
		local i2 = utf8.offset(str, 2, i)

		text_t[j] = color_seq[i] or col_t
		text_t[j + 1] = string.sub(str, i, i2 - 1)

		i = i2
		j = j + 2
	end

	-- Trim table excess
	--print("TRIM", "#text_t", #text_t, "j", j)
	for k = #text_t, j, -1 do
		--print("k", k, "#text_t", #text_t, "text_t[i]", text_t[k])
		text_t[k] = nil
	end

	return text_t
end


return edVis
