-- editField common visual functions.
-- Put stuff that requires a LÖVE font here.


local edVis = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local edCom = require(PATH .. "ed_com")


--- Given a string and a font, replace glyphs that aren't present in the font with a stand-in glyph. Some TrueType fonts specify a character for this purpose, and will print them automatically (for example, 'ə' with the default LÖVE 11.4 font with display an outlined box.) AFAIK LÖVE ImageFonts do not.
-- @param str The input string.
-- @param font The LÖVE Font to check the string against.
-- @param err_glyph The glyph to insert. (Something like this: "□") Can be multi-byte, but should be exactly one code point if you want the resulting string to be the same Unicode length.
-- @return A modified string, or the same string if all glyphs were covered by the font.
function edVis.replaceMissingGlyphs(str, font, err_glyph)
	--[[
	NOTES:
	* Font:hasGlyphs() returns false for empty strings.

	* Font:hasGlyphs() may return true or false for '\t' depending on if the font supplies an actual glyph for it.
	LÖVE is still capable of rendering a tab regardless of this, however, so it will be exempted from
	the check below.
	--]]

	-- Nothing to do if the string is empty or all glyphs are covered by the font.
	--print("|"..str.."|", #str, string.byte(str))
	if #str == 0 or font:hasGlyphs(str) then
		return str

	else
		local ret_str = ""
		local byte, u8_pos = 1, 1

		while byte <= #str do
			local byte2 = utf8.offset(str, u8_pos + 1)
			if not byte2 then
				break
			end

			local glyph = string.sub(str, byte, byte2 - 1)
			if glyph == "\t" or font:hasGlyphs(glyph) then
				ret_str = ret_str .. glyph
			else
				ret_str = ret_str .. err_glyph
			end

			u8_pos = u8_pos + 1
			byte = byte2
		end

		return ret_str
	end
end


--- Trims a string so that it fits within a pixel width when rendered through a specific font.
-- @param str The string to trim.
-- @param font The font to use.
-- @param width The maximum allowed width, in pixels.
-- @return A trimmed version of 'str', or an empty string if nothing fit.
function edVis.trimStringToWidth(str, font, width)
	-- XXX maybe you'd be better off just using font:getWrap() and taking only the first array entry.
	if font:getWidth(str) <= width then
		return str
	end

	local byte, pos = 1, 1
	local last_fit = ""

	while true do
		local sub = string.sub(str, 1, byte)
		if font:getWidth(sub) > width then
			break

		else
			last_fit = sub
			pos = pos + 1
			byte = utf8.offset(str, pos)

			if not byte then
				break
			end
		end
	end

	return last_fit
end


function edVis.getCaretXW(display_text, d_car_byte, font)
	local text_before = string.sub(display_text, 1, d_car_byte - 1)

	local cx = font:getWidth(text_before)

	-- Get width of character the caret is currently resting on.
	local cw
	local offset = edCom.utf8FindRightStartOctet(display_text, d_car_byte + 1)

	if offset then
		cw = font:getWidth(string.sub(display_text, d_car_byte, offset - 1))

	else
		-- At end of string + 1: use the width of the underscore character
		cw = font:getWidth("_")
	end

	return cx, cw
end


function edVis.getCaretX(display_text, d_car_byte, font)
	-- Does not include alignment offsetting
	local text_before = string.sub(display_text, 1, d_car_byte - 1)

	return font:getWidth(text_before)
end


function edVis.getDisplayTextSingle(text, font, replace_missing, masked)
	local display_text = text
	if masked then
		display_text = edCom.getMaskedString(display_text, "*")

	elseif replace_missing then
		display_text = edVis.replaceMissingGlyphs(display_text, font, "□")
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


--- Given a string of text and an X position (relative to the leftmost side of the text), 
function edVis.textInfoAtX(text, font, x, split_x)

	local byte, glyph_x, glyph_w

	-- Empty string
	if #text == 0 then
		byte = 1
		glyph_x = 0
		glyph_w = 0

	-- Input X is left of the line
	elseif x < 0 then
		byte = 1
		local char_str = string.sub(text, 1, utf8.offset(text, 2) - 1)
		glyph_x = 0
		glyph_w = font:getWidth(char_str)

	-- Input X is within, or to the right of the line
	else
		byte = 1
		glyph_x = 0
		glyph_w = 0

		local char_str
		local last_glyph = false

		while byte <= #text do
			local byte_2 = utf8.offset(text, 2, byte)
			char_str = string.sub(text, byte, byte_2 - 1)
			glyph_w = font:getWidth(char_str)

			-- Apply kerning offset
			if last_glyph then
				glyph_x = glyph_x + font:getKerning(last_glyph, char_str)
			end
			last_glyph = char_str

			-- 'split_x' will cause the following glyph to be selected if the X position is on the right side.
			local split_w = glyph_w
			if split_x then
				split_w = split_w / 2
			end

			if x < glyph_x + split_w then
				break
			else
				glyph_x = glyph_x + glyph_w
				byte = byte_2
			end
		end

		-- Byte exceeds text length: wipe glyph width.
		if byte > #text then
			glyph_w = 0
		end
	end

	return byte, glyph_x, glyph_w
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
--- Create or update a coloredtext table based on a string, where every code point is assigned its own color table.
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


-- * Debug *


function edVis.printColoredText(colored_text)
	for i, chunk in ipairs(colored_text) do
		if type(chunk) == "table" then
			io.write("{"
				.. tostring(chunk[1]) .. ", "
				.. tostring(chunk[2]) .. ", "
				.. tostring(chunk[3]) .. ", "
				.. tostring(chunk[4]) .. "}, ")

		else
			io.write("| " .. tostring(chunk) .. " |,\n")
		end
	end
end


-- * / Debug *


return edVis

