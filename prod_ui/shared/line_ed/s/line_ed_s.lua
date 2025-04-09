-- To load: local lib = context:getLua("shared/lib")


-- Single-line text editor core object.


--[[
WARNING: Functions tagged with the following comments require special attention:
	[sync]: Must run self:syncDisplayCaretHighlight() when done making changes.
	[update]: Must run self:updateDisplayText() when done making changes.

Note that self:updateDisplayText() also calls self:syncDisplayCaretHighlight() internally.
--]]


local context = select(1, ...)


local lineEdS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local pileTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local structHistory = require(context.conf.prod_ui_req .. "common.struct_history")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


lineEdS.code_groups = code_groups



-- stand-in text colors
local default_text_color = {1, 1, 1, 1}
local default_text_h_color = {0, 0, 0, 1}


local _mt_ed_s = {}
_mt_ed_s.__index = _mt_ed_s


--- Creates a new Line Editor object.
-- @return the line editor table.
function lineEdS.new(font, text_color, text_h_color)
	uiShared.loveType(1, font, "Font")
	uiShared.typeEval(2, text_color, "table")
	uiShared.typeEval(3, text_h_color, "table")

	local self = {}

	self.font = font

	-- dimensions of the display text and highlight box
	self.disp_text_w = 0
	self.disp_text_h = math.ceil(font:getHeight() * font:getLineHeight())

	self.disp_highlighted = false

	self.highlight_x = 0
	self.highlight_y = 0
	self.highlight_w = 0
	self.highlight_h = self.disp_text_h

	-- The internal text.
	self.line = ""

	-- bytes for internal caret and highlight
	self.car_byte = 1
	self.h_byte = 1

	-- bytes for display caret and highlight
	self.d_car_byte = 1
	self.d_h_byte = 1

	-- XXX: skin or some other config system. Currently, 'caret_line_width' is based on the width of 'M' in the current font.
	self.caret_line_width = 0

	-- The position and dimensions of the currently selected character.
	-- The client widget uses these values to determine the size and location of its caret.
	self.caret_box_x = 0
	self.caret_box_y = 0
	self.caret_box_w = 0
	self.caret_box_h = 0

	-- Width of the caret box when it is not placed over text (ie at the far end, or the Line Editor is empty)
	self.caret_box_w_empty = 0

	-- Width to use when keeping the caret in view against the far edge of the field.
	self.caret_box_w_edge = 0

	-- History state.
	self.hist = structHistory.new()
	editHistS.writeEntry(self, true)

	-- External display text.
	self.disp_text = ""

	-- Text colors, normal and highlighted.
	-- References to these tables will be copied around.
	self.text_color = text_color or default_text_color
	self.text_h_color = text_h_color or default_text_h_color

	-- Swaps out missing glyphs in the display string with a replacement glyph.
	-- The internal contents (and results of clipboard actions) remain the same.
	self.replace_missing = true

	-- Glyph masking mode, as used in password fields.
	-- Note that this only changes the UTF-8 string which is sent to text rendering functions.
	-- It does nothing else in terms of security.
	self.masked = false
	self.mask_glyph = "*" -- A string of one code point that references one glyph.

	-- Set true to create a coloredtext table for the display text. Each coloredtext
	-- table contains a color table and a code point string for every code point in the base
	-- string. The initial color table is 'self.text_color_t'. For example, the string "foobar"
	-- would become {col_t, "f", col_t, "o", col_t, "o", col_t, "b", col_t, "a", col_t, "r", }.
	-- This uses considerably more memory than a single string, but allows recoloring on a
	-- per-code point basis, which is convenient if you want to perform more than one pass of
	-- coloring (such as in the case of mixing syntax highlighting and also inverting highlighted
	-- text).
	self.generate_colored_text = false

	-- Assign a function taking 'self', 'str', 'syntax_t', and 'work_t' to colorize the display text when updating
	-- it. 'self' is the LineEditor state. 'syntax_t' is 'self.wip_syntax_colors', and it may contain existing
	-- contents. 'work_t' is self.syntax_work, an arbitrary table you may use to help keep track of your
	-- colorization state.
	self.fn_colorize = false

	-- Temporary workspace for constructing syntax highlighting sequences.
	self.wip_syntax_colors = {}

	-- Arbitrary table of state intended to help manage syntax highlighting.
	self.syntax_work = {}

	setmetatable(self, _mt_ed_s)

	self:updateFont(self.font)
	self:updateDisplayText()

	return self
end


--- Gets caret and highlight offsets in the correct order.
function _mt_ed_s:getHighlightOffsets()
	local byte_1, byte_2 = self.car_byte, self.h_byte
	return math.min(byte_1, byte_2), math.max(byte_1, byte_2)
end


--- Returns if the field currently has a highlighted section (not whether highlighting itself is currently active.)
function _mt_ed_s:isHighlighted()
	return self.h_byte ~= self.car_byte
end


-- @return Byte, X position and width of the glyph (if applicable).
function _mt_ed_s:getLineInfoAtX(x, split_x)
	return textUtil.getTextInfoAtX(self.line, self.font, x, split_x)
end


function _mt_ed_s:clearHighlight() -- [sync]
	self.h_byte = self.car_byte
end


function _mt_ed_s:updateFont(font) -- [update]
	self.font = font
	self.disp_text_h = math.ceil(font:getHeight() * font:getLineHeight())
	self.caret_line_width = math.max(1, math.ceil(font:getWidth("M") / 16))
	self.caret_box_w_empty = math.max(1, math.ceil(font:getWidth("_")))
	--self.caret_box_w_edge = math.max(1, math.ceil(font:getWidth("M") * 1.25))
	self.caret_box_w_edge = math.max(1, math.ceil(font:getWidth("M")))
end


--- Insert a string at the caret position.
-- @param text The string to insert.
function _mt_ed_s:insertText(text) -- [update]
	self:clearHighlight()
	self.line = edComS.add(self.line, text, self.car_byte)
	self.car_byte = self.car_byte + #text
	self.h_byte = self.car_byte
end


--- Delete a section of text.
-- @param copy_deleted If true, return the deleted text as a string.
-- @param byte_1 The first byte offset to delete from.
-- @param byte_2 The final byte offset to delete to.
-- @return The deleted text as a string, if 'copy_deleted' was true and any text was removed, or nil.
function _mt_ed_s:deleteText(copy_deleted, byte_1, byte_2) -- [update]
	if byte_1 <= byte_2 then
		local deleted
		if copy_deleted then
			deleted = self.line:sub(byte_1, byte_2)
		end
		self.line = edComS.delete(self.line, byte_1, byte_2)
		self.car_byte, self.h_byte = byte_1, byte_1

		return deleted ~= "" and deleted
	end
end


function _mt_ed_s:getWordRange(byte_n)
	local line = self.line
	if #line == 0 then
		return 1, 1
	end

	-- If at the end of the line, and the line contains at least one code point, then use that last code point.
	if byte_n >= #line + 1 then
		byte_n = utf8.offset(line, -1)
	end

	local first_group = code_groups[utf8.codepoint(line, byte_n)]

	local byte_left = edComS.huntWordBoundary(code_groups, line, byte_n, -1, true, first_group)
	local byte_right = edComS.huntWordBoundary(code_groups, line, byte_n, 1, true, first_group)

	return byte_left, byte_right
end


--- Update the display text.
function _mt_ed_s:updateDisplayText()
	local font = self.font

	-- Perform optional modifications on the string.
	local work_str = self.line

	-- Replace some whitespace characters with symbolic code points.
	work_str = string.gsub(work_str, utf8.charpattern, textUtil.proxy_code_points)

	if self.replace_missing then
		work_str = textUtil.replaceMissingCodePointGlyphs(work_str, font, "□")
	end

	if self.masked then
		work_str = textUtil.getMaskedString(work_str, self.mask_glyph)

	-- Only syntax-colorize unmasked text.
	elseif self.fn_colorize and self.generate_colored_text then
		self:fn_colorize(work_str, self.wip_syntax_colors, self.syntax_work)
	end

	self.disp_text = work_str
	self.disp_text_w = font:getWidth(self.disp_text) + self.caret_box_w_empty
	self.disp_text_h = math.ceil(font:getHeight() * font:getLineHeight())

	-- XXX: syntax coloring.
	self.syntax_colors = false
	self.colored_text = false

	self:syncDisplayCaretHighlight()
end


--- Updates the display caret offsets, the caret rectangle, and the highlight rectangle. The display text must be current at time of call.
function _mt_ed_s:syncDisplayCaretHighlight()
	local line = self.line
	local font = self.font

	self.d_car_byte = edComS.coreToDisplayOffsets(line, self.car_byte, self.disp_text)
	self.d_h_byte = edComS.coreToDisplayOffsets(line, self.h_byte, self.disp_text)

	-- Update cached caret info.
	self.caret_box_x = textUtil.getCharacterX(self.disp_text, self.d_car_byte, font)

	-- If we are at the end of the string + 1: use the width of the underscore character.
	self.caret_box_w = textUtil.getCharacterW(self.disp_text, self.d_car_byte, font) or font:getWidth("_")

	self.caret_box_y = 0
	self.caret_box_h = font:getHeight()

	-- update highlight rect
	local hi_1, hi_2 = math.min(self.d_car_byte, self.d_h_byte), math.max(self.d_car_byte, self.d_h_byte)
	if hi_1 == hi_2 then
		self.disp_highlighted = false
	else
		local font = self.font
		local disp_text = self.disp_text

		local pixels_before = font:getWidth(disp_text:sub(1, hi_1 - 1))
		local pixels_highlight = font:getWidth(disp_text:sub(hi_1, hi_2 - 1))

		self.disp_highlighted = true

		self.highlight_x = pixels_before
		self.highlight_y = 0
		self.highlight_w = pixels_highlight
		self.highlight_h = self.disp_text_h
	end

	-- If applicable, overwrite or restore syntax colors.
	if self.colored_text and self.syntax_colors then
		local disp_text = self.disp_text
		local col_text = self.colored_text
		local syn_col = self.syntax_colors

		local def_col = self.text_color
		local high_col = self.text_h_color

		-- Tweaks:
		-- hi_1 == hi_2 means no highlight is currently active. If this is the case,
		-- set them to out of bounds so that nothing is highlighted by mistake.
		if hi_1 == hi_2 then
			hi_1, hi_2 = -1, -1
		end

		local i = 1 -- Color table index within coloredtext sequence (step: 2, always odd)
		local j = 1 -- Color table index within syntax colors sequence (step: 1)
		local k = 1 -- Byte position within source string (display, not internal)

		while k <= #disp_text do
			local k2 = utf8.offset(disp_text, 2, k)

			if k >= hi_1 and k < hi_2 then
				col_text[i] = high_col
			else
				col_text[i] = syn_col[j] or def_col
			end

			k = k2
			i = i + 2
			j = j + 1
		end
	end
end


-- @param x X position.
-- @param split_x When true, if the X position is on the right half of a character, get details for the next character to the right.
-- @return Line, byte and character string of the character at (or nearest to) the position.
function _mt_ed_s:getCharacterDetailsAtPosition(x, split_x)
	local font = self.font
	local line = self.line
	local disp_text = self.disp_text

	local byte, x_pos, width = self:getLineInfoAtX(x, split_x)

	-- Convert display offset to core byte.
	local u_count = edComS.utf8LenPlusOne(disp_text, byte)

	local core_byte = utf8.offset(line, u_count)
	local core_char = false
	if core_byte <= #line then
		core_char = line:sub(core_byte, utf8.offset(line, 2, core_byte) - 1)
	end

	return core_byte, core_char
end


function _mt_ed_s:caretToByte(byte_n) -- [sync]
	self.car_byte = math.max(1, math.min(byte_n, #self.line + 1))
end


function _mt_ed_s:highlightToByte(h_byte_n) -- [sync]
	self.h_byte = math.max(1, math.min(h_byte_n, #self.line + 1))
end


function _mt_ed_s:copyState()
	return self.line, self.disp_text, self.car_byte, self.h_byte
end


function _mt_ed_s:setState(line, disp_text, car_byte, h_byte)
	self.line, self.disp_text, self.car_byte, self.h_byte = line, disp_text, car_byte, h_byte
end


return lineEdS
