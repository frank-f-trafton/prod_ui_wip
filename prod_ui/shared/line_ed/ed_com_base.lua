local context = select(1, ...)


local edComBase = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


function edComBase.cleanString(str, bad_byte_policy, tabs_to_spaces, allow_line_feed)
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


function edComBase.applyCaretAlignOffset(caret_x, line_str, align, font)
	if align == "left" then
		-- n/a

	elseif align == "center" then
		caret_x = caret_x + math.floor(0.5 - font:getWidth(line_str) / 2)

	elseif align == "right" then
		caret_x = caret_x - font:getWidth(line_str)
	end

	return caret_x
end


return edComBase
