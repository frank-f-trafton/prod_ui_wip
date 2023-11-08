--[[
	'code_groups' is a hash table of code points that are considered whitespace or punctuation.
	This is used when jumping the caret across multiple code points of text. By default, only
	some single-byte ASCII characters are included. You can add more fields to the table after
	loading the module (or replace this source file entirely with one that contains the entries
	your application needs).
--]]


local code_groups = {}


do
	local utf8 = require("utf8")

	local ascii_ws = "\x09\x0a\x20" -- horizontal tab, line feed, space

	for pos, code in utf8.codes(ascii_ws) do
		code_groups[code] = "whitespace"
	end

	local ascii_punct = "~`!@#$%^&*()-=+[{]}\\|;:'\",<.>/?" -- absent: underscore
	for pos, code in utf8.codes(ascii_punct) do
		code_groups[code] = "punctuation"
	end
end


return code_groups
