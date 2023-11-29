-- To load: local lib = context:getLua("shared/lib")


-- Single-line text editor core object.


local context = select(1, ...)


local lineEdS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local commonEd = context:getLua("shared/line_ed/common_ed")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")

lineEdS.code_groups = context:getLua("shared/line_ed/code_groups")
local code_groups = lineEdS.code_groups


local history = require(context.conf.prod_ui_req .. "logic.struct.history")
local lineManip = context:getLua("shared/line_ed/line_manip")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


local _mt_ed_s = {}
_mt_ed_s.__index = _mt_ed_s


local function updateDisplayLineHorizontal(self, align, font)

	self.disp_text_w = font:getWidth(self.disp_text)

	if align == "left" then
		self.disp_text_x = 0

	elseif align == "center" then
		self.disp_text_x = math.floor(0.5 - self.disp_text_w / 2)

	elseif align == "right" then
		self.disp_text_x = -self.disp_text_w
	end
end


local function dispUpdateLineSyntaxColors(self, byte_1, byte_2)

	if self.colored_text and self.syntax_colors then

		local disp_text = self.disp_text
		local col_text = sub_line.colored_text
		local syn_col = sub_line.syntax_colors

		local def_col = self.text_color
		local high_col = self.text_h_color

		-- Tweaks:
		-- byte_1 == byte_2 means no highlight is currently active. If this is the case,
		-- set them to out of bounds so that nothing is highlighted by mistake.
		if byte_1 == byte_2 then
			byte_1 = -1
			byte_2 = -1
		end

		local i = 1 -- Color table index within coloredtext sequence (step: 2, always odd)
		local j = 1 -- Color table index within syntax colors sequence (step: 1)
		local k = 1 -- Byte position within source string

		while k <= #disp_text do
			local k2 = utf8.offset(disp_text, 2, k)

			if k >= byte_1 and k < byte_2 then
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


--- Creates a new Line Editor object.
-- @return the edit_field table.
function lineEdS.new(font)

	if not font then
		error("missing argument #1 (font) for new LineEditor (single) object.")
	end

	local self = {}

	-- The internal text.
	self.line = ""

	-- Position and dimensions of the display text and highlight box.
	self.disp_text_x = 0
	self.disp_text_y = 0
	self.disp_text_w = 0
	self.disp_text_h = 0

	self.highlight_x = 0
	self.highlight_y = 0
	self.highlight_w = 0
	self.highlight_h = 0

	commonEd.setupCaretInfo(self, true, false)
	commonEd.setupCaretDisplayInfo(self, true, false)
	commonEd.setupCaretBox(self)

	-- When true, typing overwrites the current position instead of inserting.
	self.replace_mode = false

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'textUtil.sanitize()' for options.
	self.bad_input_rule = false

	-- Enable/disable specific editing actions.
	self.allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.allow_cut = true
	self.allow_copy = true
	self.allow_paste = true
	self.allow_highlight = true

	-- Allows '\n' as text input.
	-- Single-line input treats line feeds like any other character. For example, 'home' and 'end' will not
	-- stop at line feeds. The external string may substitute line feeds for U+23CE (⏎).
	self.allow_line_feed = false

	self.enter_types_line_feed = false -- Makes the enter/return key type '\n\.
	self.allow_tab = false -- affects single presses of the tab key
	self.allow_untab = false -- affects shift+tab (unindenting)
	self.tabs_to_spaces = false -- affects '\t' in writeText()

	-- Helps with amending vs making new history entries.
	self.input_category = false

	-- Cached copy of text length in Unicode code points.
	self.u_chars = utf8.len(self.line)

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.u_chars_max = math.huge


	-- History state.
	self.hist = history.new()
	editHistS.writeEntry(self, true)


	-- Display state.

	-- External display text.
	self.disp_text = ""

	self.align = "left" -- "left", "center", "right"

	self.font = font
	self.font_height = font:getHeight()
	self.line_height = math.ceil(font:getHeight() * font:getLineHeight())

	-- Text colors, normal and highlighted.
	-- References to these tables will be copied around.
	self.text_color = {1, 1, 1, 1} -- XXX: skin
	self.text_h_color = {0, 0, 0, 1} -- XXX: skin

	-- Swaps out missing glyphs in the display string with a replacement glyph.
	-- The internal contents (and results of clipboard actions) remain the same.
	self.replace_missing = true

	commonEd.setupMaskedState(self)

	-- Set true to create coloredtext tables for each sub-line string. Each coloredtext
	-- table contains a color table and a code point string for every code point in the base
	-- string. The initial color table is 'self.text_color_t'. For example, the string "foobar"
	-- would become {col_t, "f", col_t, "o", col_t, "o", col_t, "b", col_t, "a", col_t, "r", }.
	-- This uses considerably more memory than a single string, but allows recoloring on a
	-- per-code point basis, which is convenient if you want to perform more than one pass of
	-- coloring (such as in the case of mixing syntax highlighting and also inverting highlighted
	-- text).
	self.generate_colored_text = false

	-- Assign a function taking 'self', 'str', 'syntax_t', and 'work_t' to colorize a Paragraph when updating
	-- it. 'self' is the LineEditor state. 'syntax_t' is 'self.wip_syntax_colors', and it may contain existing
	-- contents. You must return the number of entries written to the table so that the update logic can clip
	-- the contents. 'work_t' is self.syntax_work, an arbitrary table you may use to help keep track of your
	-- colorization state.
	self.fn_colorize = false

	-- Temporary workspace for constructing syntax highlighting sequences.
	self.wip_syntax_colors = {}

	-- Arbitrary table of state intended to help manage syntax highlighting.
	self.syntax_work = {}


	setmetatable(self, _mt_ed_s)

	--self.disp:refreshFontParams()
	--self:displaySyncAll()

	return self
end


function _mt_ed_s:getCaretOffsets()
	return self.car_byte, self.h_byte
end


--- Gets caret and highlight offsets in the correct order.
function _mt_ed_s:getHighlightOffsets()

	-- You may need to subtract 1 from byte_2 to get the correct range.
	local byte_1, byte_2 = self.car_byte, self.h_byte
	return math.min(byte_1, byte_2), math.max(byte_1, byte_2)
end


--- Returns if the field currently has a highlighted section (not whether highlighting itself is currently active.)
function _mt_ed_s:isHighlighted()
	return not (self.h_byte == self.car_byte)
end


function _mt_ed_s:clearHighlight()

	self.h_byte = self.car_byte

	-- XXX: displaySyncCaretOffsets()
	-- XXX: updateDispHighlightRange()
end


function _mt_ed_s:getDocumentXBoundaries()
	return sub_line.x, sub_line.x + sub_line.w
end


-- @return Byte, X position and width of the glyph (if applicable).
function _mt_ed_s:getLineInfoAtX(x, split_x)

	local font = self.font
	local line = self.line

	-- Temporarily make X relative to the start of the line.
	x = x - self.disp_text_x

	local byte, glyph_x, glyph_w = textUtil.getTextInfoAtX(line, font, x, split_x)

	return byte, glyph_x + self.disp_text_x, glyph_w
end


--- Update the external display text.
function _mt_ed_s:updateDisplayText()

	local font = self.font
	local str = self.line

	-- Perform optional modifications on the string.
	local work_str = str

	if self.replace_missing then
		work_str = textUtil.replaceMissingCodePointGlyphs(work_str, font, "□")
	end

	if self.masked then
		work_str = textUtil.getMaskedString(work_str, self.mask_glyph)

	-- Only syntax-colorize unmasked text.
	elseif self.fn_colorize and self.generate_colored_text then
		local len = self:fn_colorize(work_str, self.wip_syntax_colors, self.syntax_work)
		-- Trim color table
		for i = #self.wip_syntax_colors, len + 1, -1 do
			self.wip_syntax_colors[i] = nil
		end
	end

	--self:updateSubLine(i_para, 1, work_str, self.wip_syntax_colors, 1) -- XXX: fix
end


-- Updates the display text alignment.
function _mt_ed_s:updateDisplayTextAlign()

	local align, font, width = self.align, self.font, self.view_w

	for i = line_1, line_2 do
		local paragraph = paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			updateDisplayLineHorizontal(self, align, font)
		end
	end
end


function _mt_ed_s:updateHighlight()

	-- Get line offsets relative to the display sequence.
	local byte_1, byte_2 = math.min(self.d_car_byte, self.d_h_byte), math.max(self.d_car_byte, self.d_h_byte)

	if byte_1 ~= byte_2 then
		local font = self.font
		local line = self.line

		local pixels_before = font:getWidth(string.sub(line, 1, byte_1 - 1))
		local pixels_highlight = font:getWidth(string.sub(line, byte_1, byte_2 - 1))

		self.highlight_x = pixels_before
		self.highlight_y = 0
		self.highlight_w = pixels_highlight
		self.highlight_h = self.disp_text_h
	end

	-- If applicable, overwrite or restore syntax colors.
	dispUpdateLineSyntaxColors(self, byte_1, byte_2)
end


function _mt_ed_s:clearHighlight()

	dispUpdateLineSyntaxColors(self, -1, -1)
end


function _mt_ed_s:updateCaretRect()

	--print("_mt_ed_s:updateCaretRect()")

	local font = self.font

	-- Update cached caret info.
	self.caret_box_x = textUtil.getCharacterX(self.disp_text, self.d_car_byte, font)

	-- If we are at the end of the string + 1: use the width of the underscore character.
	self.caret_box_w = textUtil.getCharacterW(self.disp_text, self.d_car_byte, font) or font:getWidth("_")

	-- Apply horizontal alignment offsetting to caret.
	self.caret_box_x = applyCaretAlignOffset(self.caret_box_x, self.disp_text, self.align, font)

	self.caret_box_y = self.disp_text_y
	self.caret_box_h = font:getHeight()
end


function _mt_ed_s:updateFont(font)

	self.font = font
	self.font_height = font:getHeight()
	self.line_height = math.ceil(font:getHeight() * font:getLineHeight())

	self:refreshFontParams()
	-- The display text needs to be updated after calling.
end


function _mt_ed_s:refreshFontParams()

	local font = self.font
	local em_width = font:getWidth("M")
	local line_height = font:getHeight() * font:getLineHeight()

	self.caret_line_width = math.max(1, math.ceil(em_width / 16))

	-- Client should refresh/clamp scrolling and ensure the caret is visible after this function is called.
end


function _mt_ed_s:highlightCleanup()

	if self:isHighlighted() then
		self:clearHighlight()
	end
end


--- Insert a string at the caret position.
-- @param text The string to insert.
-- @return Nothing.
function _mt_ed_s:insertText(text)

	self:highlightCleanup()

	self.line = lineManip.add(self.line, text, self.car_byte)
	self.car_byte = self.car_byte + #text
	self.h_byte = self.car_byte

	--self:displaySyncInsertion(old_line, self.car_line)
	--self:displaySyncCaretOffsets()
end


--- Delete a section of text.
-- @param copy_deleted If true, return the deleted text as a string.
-- @param byte_1 The first byte offset to delete from.
-- @param byte_2 The final byte offset to delete to.
-- @return The deleted text as a string, if 'copy_deleted' was true, or nil.
function _mt_ed_s:deleteText(copy_deleted, byte_1, byte_2)

	local deleted
	if copy_deleted then
		deleted = string.sub(self.line, byte_1, byte_2)
	end
	self.line = lineManip.delete(self.line, byte_1, byte_2)

	self.car_byte = byte_1
	self.h_byte = self.car_byte

	-- XXX: update caret details.

	return deleted
end


_mt_ed_s.resetCaretBlink = commonEd.resetCaretBlink
_mt_ed_s.updateCaretBlink = commonEd.updateCaretBlink


function _mt_ed_s:getWordRange(byte_n)

	local line = self.line

	-- If at the end of the line, and it contains at least one code point, then use that last code point.
	if #line > 0 and byte_n == #line + 1 then
		byte_n = utf8.offset(line, -1, byte_n)
	end

	local peeked = utf8.codepoint(byte_n)

	local first_group = code_groups[peeked]

	local byte_left, byte_right

	line_left, byte_left = edComS.huntWordBoundary(code_groups, line, byte_n, -1, true, first_group, true)
	line_right, byte_right = edComS.huntWordBoundary(code_groups, line, byte_n, 1, true, first_group, true)

	--print("line+byte left, line+byte right", line_left, byte_left, line_right, byte_right)

	return line_left, byte_left, line_right, byte_right
end


--- Update the display container offsets to reflect the current core offsets. Also update the caret rectangle as stored in 'disp'. The display text must be current at time of call.
function _mt_ed_s:displaySyncCaretOffsets()

	local line = self.line

	--d_car_byte
	--d_h_byte
	disp.d_car_byte, disp.d_car_sub = editDispM.coreToDisplayOffsets(#car_str, self.car_byte, paragraphs[disp.d_car_para])

	disp.d_h_para = self.h_line
	disp.d_h_byte, disp.d_h_sub = editDispM.coreToDisplayOffsets(#h_str, self.h_byte, paragraphs[disp.d_h_para])

	disp:updateCaretRect()
end


return lineEdS
