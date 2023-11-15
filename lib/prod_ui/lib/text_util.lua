-- Miscellaneous LÖVE text / font / printing functions.
-- Version: 0.0.2 (Beta)


local textUtil = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local utf8Tools = require(REQ_PATH .. "utf8_tools")


--- Counts the number of line feeds in a string.
-- @param str The string to check.
-- @return The number of line feeds.
function textUtil.countLineFeeds(str)

	local i, c = 1, 0

	while i <= #str do
		i = string.find(str, "\n", i, true)
		if not i then
			break

		else
			i = i + 1
			c = c + 1
		end
	end

	return c
end


function textUtil.trimToFirstLine(text)

--	if type(text) == "string" then
		local i = string.find(text, "\n", i, true)
		if i then
			text = string.sub(text, 1, i - 1)
		end

--[[
	elseif type(text) == "table" then
		for i, chunk in ipairs(text) do
			local j = string.find(chunk, "\n", i, true)
			if j then
				local ret = {}
				for k = 1, i - 1 do
					ret[k] = text[i]
				end
				ret[#ret + 1] = string.sub(text[i], 1, j - 1)
				text = ret
			end
		end

	else
		error("argument #1: bad type (expected string/table, got " .. type(text))
	end
--]]

	return text
end


--- Converts a LÖVE coloredtext table to a string, stripping out color table info.
-- @param text The coloredtext table to convert.
-- @return The converted string.
function textUtil.coloredTextTableToString(text)

	-- Assertions
	-- [[
	if type(text) ~= "table" then error("argument #1: bad type (expected table, got " .. type(text)) end
	--]]

	local str = ""

	-- XXX: benchmark
	if #text <= 16 then
		for i, chunk in ipairs(colored_text) do
			if type(chunk) == "string" then
				str = str .. chunk
			end
		end

	else
		local temp = {}

		for i, chunk in ipairs(colored_text) do
			if type(chunk) == "string" then
				temp[#temp + 1] = chunk
			end
		end
		str = table.concat(temp)
	end

	return str
end


--- Debug-print a coloredtext table, showing colors in the Lua table format ({r, g, b, a}).
-- @param colored_text The coloredtext table to debug-print.
function textUtil.debugPrintColoredText(colored_text)

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


--- Wrapper for Font:getWrap() which also returns the text height.
-- @param font The LÖVE Font.
-- @param text The string or coloredtext sequence.
-- @param limit The horizontal wrap limit for Font:getWrap().
-- @param max_lines (inf) The maximum number of wrapped lines to consider when calculating the text height.
-- @return text width, height, and table of wrapped lines.
function textUtil.getWrapInfo(font, text, limit, max_lines)

	max_lines = max_lines or math.huge
	local width, lines = font:getWrap(text, limit)

	local height = math.floor(0.5 + font:getHeight() * font:getLineHeight() * math.min(#lines, max_lines))
	return width, height, lines
end


--- Given a single-line string with two underscores marking the start and end of an underline, return the string with the underscore markers removed, and an X coordinate and width for drawing the underline.
-- @param str The string to process.
-- @param font The LÖVE Font which will be used to render this text. Needed for measuring the underline.
-- @return The string with underscores removed, an X coordinate, and a width value for rendering the underline, or all nil if the parsing failed.
function textUtil.processUnderline(str, font)

	-- NOTE: This has not been tested with ImageFonts or BMFonts.

	-- This function can't handle multi-line strings or multiple underlines per string.
	if string.find(str, "\n", 1, true) then
		return -- nil
	end

	-- At least one non-underscore byte is needed between the two underscores.
	local i, j = string.find(str, "_[^_]+_")

	if i then
		-- Extract string chunks around the underscores.
		local s1 = string.sub(str, 1, i - 1)
		local s2 = string.sub(str, i + 1, j - 1)
		local s3 = string.sub(str, j + 1)

		local x = font:getWidth(s1)
		local w = font:getWidth(s2)

		-- Check for kerning.
		if #s1 > 0 and #s2 > 0 then
			local k1a = utf8.codepoint(s1, utf8.offset(s1, -1))
			local k1b = utf8.codepoint(s2, 1, utf8.offset(s2, 2) - 1)

			x = x + font:getKerning(k1a, k1b)
		end

		if #s2 > 0 and #s3 > 0 then
			local k2a = utf8.codepoint(s2, utf8.offset(s2, -1))
			local k2b = utf8.codepoint(s3, 1, utf8.offset(s3, 2) - 1)

			w = w + font:getKerning(k2a, k2b)
		end

		-- When drawing with love.graphics.line(), add 0.5 to all coordinates and subtract 1 from the rightmost X coord.
		-- You may also wish to offset the Y position by floor(line_width / 2), so that thick lines don't overlap
		-- with the text.

		return s1 .. s2 .. s3, x, w
	end

	-- return nil
end


-- Upvalues for textUtil.replaceMissingCodePointGlyphs().
local temp_font, temp_replace


-- string.gsub function for textUtil.replaceMissingCodePointGlyphs().
local function hof_replaceMissing(key)

	if key == "\t" or not temp_font:hasGlyphs(key) then
		return temp_replace
	end

	-- return nil
end


--- Given a UTF-8 string and a font, replace code points without glyphs in the font with a stand-in string. Some TrueType fonts specify a code point for this purpose, and will print them automatically (for example, 'ə' with the default LÖVE 11.4 font with display an outlined box.) AFAIK LÖVE ImageFonts do not.
-- @param str The input string.
-- @param font The LÖVE Font to check.
-- @param replacement The string to use in place of any missing code points. (Something like: "□") Can be multi-byte, but should be exactly one code point if you want the resulting string to be the same code point length as the input string.
-- @return The modified string, or the same string if the string was empty or all glyphs were covered by the font.
function textUtil.replaceMissingCodePointGlyphs(str, font, replacement)

	--[[
	NOTES:
	* Font:hasGlyphs() returns false for empty strings.

	* Font:hasGlyphs() may return true or false for '\t' depending on if the font supplies an actual glyph for it.
	LÖVE is still capable of rendering a tab regardless of this, however, so it will be exempted from
	the check below.
	--]]

	-- Nothing to do if the string is empty or all glyphs are covered by the font.
	if #str == 0 or font:hasGlyphs(str) then
		return str

	else
		-- Load upvalues
		temp_font, temp_replace = font, replacement

		local ret_str = string.gsub(str, utf8.charpattern, hof_replaceMissing)

		-- Clear upvalues
		temp_font, temp_replace = false, false

		return ret_str
	end
end


--- Trims a string so it fits into a pixel width when rendered using the given font.
-- @param str The string to trim.
-- @param font The font to use.
-- @param width The maximum allowed width, in pixels.
-- @return A trimmed version of 'str', or an empty string if nothing fit.
function textUtil.trimStringToWidth(str, font, width)

	-- XXX: I don't think this will work with LÖVE 12's advanced text shaping.

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


function textUtil.getCharacterX(str, byte, font)

	local str_before = string.sub(str, 1, byte - 1)

	return font:getWidth(str_before)
end


function textUtil.getCharacterW(str, byte, font)

	local cw
	local offset = utf8.offset(str, 2, byte)

	return (offset) and font:getWidth(string.sub(str, byte, offset - 1)) or nil
end


--- Given a string of text and an X position (relative to the leftmost side of the text), get the byte offset, glyph X position
--  and glyph width for the character closest to the provided X position. If the X position is to the right of all text, then a
--	width of zero is returned.
-- @param text The string to check.
-- @param font The font.
-- @param x X position, starting at the leftmost side of the text.
-- @param split_x When true, select the glyph to the right when the X position is on the right half of a glyph.
function textUtil.getTextInfoAtX(text, font, x, split_x)

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


--- Makes a masked version of a string, where every code point is replaced with the contents of `mask_str`. Can be used for password fields.
-- @param str The string to mask.
-- @param mask_str The replacement string to use for masking.
-- @return The masked string.
function textUtil.getMaskedString(str, mask_str)
	return string.rep(mask_str, utf8.len(str))
end


return textUtil
