-- Miscellaneous LÖVE text / font / printing functions.
-- Version: 0.0.2 (Beta)


local textUtil = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


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


--- Converts a LÖVE coloredtext table to a string.
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


return textUtil

