-- To load: local lib = context:getLua("shared/lib")


--[[
	LineEditor (single) plug-in methods for client widgets.
--]]


local context = select(1, ...)


local editMethodsSingle = {}
local client = editMethodsSingle


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


--- Delete highlighted text from the field.
-- @return Substring of the deleted text.
function client:deleteHighlightedText()

	local line_ed = self.line_ed

	if not self:isHighlighted() then
		return nil
	end

	-- Clean up display highlight beforehand. Much harder to determine the offsets after deleting things.
	local byte_1, byte_2 = line_ed:getHighlightOffsets()
	line_ed:highlightCleanup()

	return line_ed:deleteText(true, byte_1, byte_2 - 1)
end


--- Write text to the field, checking for bad input and trimming to fit into the uChar limit.
-- @param text The input text. It will be sanitized and possibly trimmed to fit into the uChar limit.
-- @param suppress_replace When true, the "replace mode" codepath is not selected. Use when pasting,
-- entering line feeds, typing at the end of a line (so as not to overwrite line feeds), etc.
-- @return The sanitized and trimmed text which was inserted into the field.
function client:writeText(text, suppress_replace)

	local line_ed = self.line_ed
	local line = line_ed.line

	-- Sanitize input
	text = edComBase.cleanString(text, line_ed.bad_input_rule, line_ed.tabs_to_spaces, line_ed.allow_line_feed)

	if not line_ed.allow_highlight then
		line_ed:clearHighlight()
	end

	-- If there is a highlight selection, get rid of it and insert the new text. This overrides replace_mode.
	if line_ed:isHighlighted() then
		self:deleteHighlightedText()

	elseif line_ed.replace_mode and not suppress_replace then
		-- Delete up to the number of uChars in 'text', then insert text in the same spot.
		local n_to_delete = edComBase.countUChars(text, math.huge)
		self:deleteUChar(n_to_delete)
	end

	-- Trim text to fit the allowed uChars limit.
	line_ed.u_chars = utf8.len(line_ed.line)
	text = textUtil.trimString(text, line_ed.u_chars_max - line_ed.u_chars)

	line_ed:insertText(text)

	return text
end


return editMethodsSingle
