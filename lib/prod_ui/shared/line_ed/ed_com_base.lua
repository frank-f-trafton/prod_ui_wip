-- To load: local lib = context:getLua("shared/lib")


local context = select(1, ...)


local edComBase = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


function edComBase.countUChars(text, u_char_room)

	local i = 1
	local byte_count = 0

	while u_char_room > 0 do
		local o1 = utf8.offset(text, i)
		local o2 = utf8.offset(text, i + 1)
		if not o2 then
			break
		end
		u_char_room = u_char_room - 1
		i = i + 1
		byte_count = o2 - 1
	end

	return byte_count, i - 1
end


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


return edComBase
