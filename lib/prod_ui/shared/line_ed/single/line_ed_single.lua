-- To load: local lib = context:getLua("shared/lib")


-- Single-line text editor core object.


local context = select(1, ...)


local lineEdSingle = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


lineEdSingle.code_groups = context:getLua("shared/line_ed/code_groups")
local code_groups = lineEdSingle.code_groups


local lineManip = context:getLua("shared/line_ed/line_manip")


local _mt_line_s = {}
_mt_line_s.__index = _mt_line_s


--- Creates a new Line Editor object.
-- @return the edit_field table.
function lineEdSingle.new(font)

	if not font then
		error("missing argument #1 (font) for new lineEdSingle object.")
	end

	local self = {}

	-- The internal text.
	self.line = ""

	-- Current position (in bytes) of the text caret and the highlight selection.
	-- The highlight can be greater or less than self.car_byte.
	-- If (h_byte == car_byte), then highlighting is not active.
	self.car_byte = 1
	self.h_byte = 1

	-- XXX: History container.

	-- XXX: Display details.

	-- Enable/disable specific editing actions.
	self.allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.allow_cut = true
	self.allow_copy = true
	self.allow_paste = true
	self.allow_highlight = true

	-- Allows '\n' as text input.
	-- Single-line input treats line feeds like any other character. The external string will substitute
	-- line feeds for U+23CE (⏎).
	self.allow_line_feed = false

	self.enter_types_line_feed = false -- Makes the enter/return key type '\n\.
	self.allow_tab = false -- affects single presses of the tab key
	self.allow_untab = false -- affects shift+tab (unindenting)
	self.tabs_to_spaces = false -- affects '\t' in writeText()

	-- When true, typing overwrites the current position instead of inserting.
	self.replace_mode = false

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'edCom.validateEncoding()' for options.
	self.bad_input_rule = false

	-- Helps with amending vs making new history entries.
	self.input_category = false

	-- Cached copy of text length in Unicode code points.
	self.u_chars = utf8.len(self.text)

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.u_chars_max = 5000

	setmetatable(self, _mt_line_s)

	--self.disp:refreshFontParams()
	--self:displaySyncAll()

	return self
end


function _mt_line_s:getCaretOffsets()
	return self.car_byte, self.h_byte
end


--- Gets caret and highlight offsets in the correct order.
function _mt_line_s:getHighlightOffsets()

	-- You may need to subtract 1 from byte_2 to get the correct range.
	local byte_1, byte_2 = self.car_byte, self.h_byte
	return math.min(byte_1, byte_2), math.max(byte_1, byte_2)
end


--- Returns if the field currently has a highlighted section (not whether highlighting itself is currently active.)
function _mt_line_s:isHighlighted()
	return not (self.h_byte == self.car_byte)
end


function _mt_line_s:clearHighlight()

	self.h_byte = self.car_byte

	-- XXX: displaySyncCaretOffsets()
	-- XXX: updateDispHighlightRange()
end


return lineEdSingle
