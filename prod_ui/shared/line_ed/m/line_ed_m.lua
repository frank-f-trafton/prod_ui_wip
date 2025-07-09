-- LineEditor (multi) core object.


local context = select(1, ...)


local lineEdM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edComBase = context:getLua("shared/line_ed/ed_com_base")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local seqString = context:getLua("shared/line_ed/seq_string")
local structHistory = context:getLua("shared/struct_history")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


lineEdM.code_groups = code_groups


local _mt_ed_m = {}
_mt_ed_m.__index = _mt_ed_m


-- * Public Functions *


local _wip_dummy_font


--- Creates a new Line Editor object.
-- @return the LineEd table.
function lineEdM.new()
	-- WIP
	_wip_dummy_font = _wip_dummy_font or love.graphics.newFont(13)
	local font = _wip_dummy_font

	local self = {}

	-- String sequence representing each line of internal text.
	self.lines = seqString.new()

	-- Current line and position (in bytes) of the text caret and the highlight selection.
	-- The highlight can be greater or less than self.car_byte.
	-- If (h_line == car_line and h_byte == car_byte), then highlighting is not active.
	self.car_byte = 1
	self.car_line = 1
	self.h_byte = 1
	self.h_line = 1

	-- History state.
	self.hist = structHistory.new()
	editHistM.writeEntry(self, true)

	-- Cached display details for rendering text, highlights, and the caret.
	-- The LineEditor is responsible for keeping this in sync with the internal state.
	self.disp = lineEdM.newLineContainer(font)

	self.disp:setHighlightDirtyRange(self.car_line, self.h_line)

	-- X position hint when stepping up or down.
	self.vertical_x_hint = 0

	-- Cached copy of 'lines' length in Unicode code points.
	self.u_chars = self.lines:uLen()

	setmetatable(self, _mt_ed_m)

	self.disp:refreshFontParams()
	self:displaySyncAll()

	return self
end


-- * Support Methods *


function _mt_ed_m:getCaretOffsets()
	return self.car_line, self.car_byte, self.h_line, self.h_byte
end


--- Gets caret and highlight lines and offsets in the correct order.
function _mt_ed_m:getHighlightOffsets()
	-- You may need to subtract 1 from byte_2 to get the correct range.
	local line_1, byte_1, line_2, byte_2 = self.car_line, self.car_byte, self.h_line, self.h_byte

	if line_1 == line_2 then
		byte_1, byte_2 = math.min(byte_1, byte_2), math.max(byte_1, byte_2)

	elseif line_1 > line_2 then
		line_1, line_2, byte_1, byte_2 = line_2, line_1, byte_2, byte_1
	end

	return line_1, byte_1, line_2, byte_2
end


function _mt_ed_m:updateVertPosHint()
	local disp = self.disp
	local font = disp.font

	local d_sub = disp.paragraphs[disp.d_car_para][disp.d_car_sub]
	local d_str = d_sub.str

	self.vertical_x_hint = d_sub.x + textUtil.getCharacterX(d_str, disp.d_car_byte, font)
end


-- @param x X position.
-- @param y Y position.
-- @param split_x When true, if the X position is on the right half of a character, get details for the next character to the right.
-- @return Line, byte and character string of the character at (or nearest to) the position.
function _mt_ed_m:getCharacterDetailsAtPosition(x, y, split_x)
	local disp = self.disp
	local paragraphs = disp.paragraphs
	local font = disp.font

	local para_i, sub_i = disp:getOffsetsAtY(y)

	local paragraph = paragraphs[para_i]
	local sub_line = paragraph[sub_i]
	--print("para_i", para_i, "sub_i", sub_i, "y1", sub_line.y, "y2", sub_line.y + sub_line.h)

	local byte, x_pos, width = disp:getSubLineInfoAtX(para_i, sub_i, x, split_x)
	--print("byte", byte, "x_pos", x_pos, "width", width)

	-- Convert display offset to core byte
	local u_count = edComM.displaytoUCharCount(paragraph, sub_i, byte)

	--print("u_count", u_count)

	local core_line = para_i
	local core_str = self.lines[core_line]
	local core_byte = utf8.offset(core_str, u_count)
	--print("core_byte", core_byte, "#core_str", #core_str)
	local core_char = false
	if core_byte <= #core_str then
		core_char = string.sub(core_str, core_byte, utf8.offset(core_str, 2, core_byte) - 1)
	end

	--print("core_line", core_line, "core_byte", core_byte, "core_char", core_char)

	return core_line, core_byte, core_char
end


--- Gets the top and bottom selected line indices and the selection bytes that go with them, in order.
-- @param omit_empty_last_selection When true, exclude the bottom line if the selection is at the start.
function _mt_ed_m:getSelectedLinesRange(omit_empty_last_selection)
	local r1, r2, b1, b2 = self.car_line, self.h_line, self.car_byte, self.h_byte
	if r1 > r2 then
		r1, r2, b1, b2 = r2, r1, b2, b1
	end

	if r1 == r2 then
		b1, b2 = math.min(b1, b2), math.max(b1, b2)
	end

	if omit_empty_last_selection and r2 > r1 and b2 <= 1 then
		r2 = math.max(r1, r2 - 1)
		b2 = #self.lines[r2] + 1
	end

	return r1, r2, b1, b2
end


function _mt_ed_m:updateDispHighlightRange()
	local disp = self.disp

	disp:updateHighlightDirtyRange(self.car_line, self.h_line)
	disp:updateHighlights()
	disp:setHighlightDirtyRange(self.car_line, self.h_line)
end


function _mt_ed_m:getWordRange(line_n, byte_n)
	local lines = self.lines

	-- If at the end of the last line, and it contains at least one code point, use that last code point.
	if line_n == #lines and #lines[line_n] > 0 and byte_n == #lines[line_n] + 1 then
		line_n, byte_n = lines:offsetStepLeft(line_n, byte_n)
	end

	local peeked = lines:peekCodePoint(line_n, byte_n)

	local first_group = code_groups[peeked]

	local line_left, byte_left
	local line_right, byte_right

	-- Treat line feeds as single words.
	if peeked == 0x0a then
		line_left, byte_left = line_n, byte_n
		line_right, byte_right = line_n + 1, 1
	else
		line_left, byte_left = edComM.huntWordBoundary(code_groups, lines, line_n, byte_n, -1, true, first_group, true)
		line_right, byte_right = edComM.huntWordBoundary(code_groups, lines, line_n, byte_n, 1, true, first_group, true)
	end

	--print("line+byte left, line+byte right", line_left, byte_left, line_right, byte_right)

	return line_left, byte_left, line_right, byte_right
end


function _mt_ed_m:getWrappedLineRange(line_n, byte_n)
	local lines = self.lines
	local disp = self.disp

	if line_n < 1 or line_n > #lines then
		error("'line_n' is out of range.")
	end

	local line_str = lines[line_n]
	if byte_n < 1 or byte_n > #line_str + 1 then
		error("'byte_n' is out of range.")
	end

	-- Convert input line+byte pair to display paragraph, sub, byte offsets.
	local d_para = line_n
	local d_byte, d_sub = edComM.coreToDisplayOffsets(line_str, byte_n, disp.paragraphs[d_para])

	-- Get first, last uChar offsets
	local u_count_1, u_count_2 = disp:getSubLineUCharOffsetStartEnd(d_para, d_sub)

	-- Convert soft-wrap code point counts in disp to byte offsets in the core/source string
	local byte_start = utf8.offset(lines[line_n], u_count_1)
	local byte_end = utf8.offset(lines[line_n], u_count_2)

	return byte_start, byte_end
end


function _mt_ed_m:highlightCleanup()
	if self:isHighlighted() then
		self:clearHighlight()
	end
end


--- Insert a string at the caret position.
-- @param text The string to insert.
-- @return Nothing.
function _mt_ed_m:insertText(text)
	local lines = self.lines
	local old_line = self.car_line
	local disp = self.disp

	self:highlightCleanup()

	self.car_line, self.car_byte = lines:add(text, self.car_line, self.car_byte)
	self.h_line, self.h_byte = self.car_line, self.car_byte

	self:displaySyncInsertion(old_line, self.car_line)
	self:displaySyncCaretOffsets()

	self:updateVertPosHint()
end


--- Delete a section of text.
-- @param copy_deleted If true, return the deleted text as a string.
-- @param line_1 The first line to delete from.
-- @param byte_1 The first byte offset to delete from.
-- @param line_2 The final line to delete to.
-- @param byte_2 The final byte offset to delete to.
-- @return The deleted text as a string, if 'copy_deleted' was true, or nil.
function _mt_ed_m:deleteText(copy_deleted, line_1, byte_1, line_2, byte_2)
	-- XXX Maybe write a line and/or uChar offset version for the client method collection.
	local lines = self.lines

	local deleted
	if copy_deleted then
		deleted = lines:copy(line_1, byte_1, line_2, byte_2)
		deleted = table.concat(deleted, "\n")
	end
	lines:delete(line_1, byte_1, line_2, byte_2)

	self.car_line = line_1
	self.car_byte = byte_1
	self.h_line = self.car_line
	self.h_byte = self.car_byte

	self:displaySyncDeletion(line_1, line_2)
	self:displaySyncCaretOffsets()

	self:updateVertPosHint()

	return deleted
end


local function fixCaretAfterIndent(self, line_n, offset)
	if self.car_line == line_n then
		self.car_byte = math.max(1, self.car_byte + offset)
	end

	if self.h_line == line_n then
		self.h_byte = math.max(1, self.h_byte + offset)
	end
end


function _mt_ed_m:indentLine(line_n)
	local old_line = self.lines[line_n]

	self.lines:add("\t", line_n, 1)

	self.u_chars = self.u_chars + 1

	fixCaretAfterIndent(self, line_n, 1)

	self:displaySyncDeletion(line_n, line_n)
	self:displaySyncCaretOffsets()

	self:updateVertPosHint()

	return old_line ~= self.lines[line_n]
end


function _mt_ed_m:unindentLine(line_n)
	local old_line = self.lines[line_n]

	local offset

	if string.sub(old_line, 1, 1) == "\t" then
		print("line_n", line_n, "tabs codepath")
		offset = 1
		self.lines:delete(line_n, 1, line_n, 1)
	else
		print("line_n", line_n, "spaces codepath")
		local space1, space2 = string.find(old_line, "^[\x20]+") -- (0x20 == space)
		if space1 then
			offset = ((space2 - 1) % 4) -- XXX space tab width should be a config setting somewhere.
			print("", "space1", space1, "space2", space2)
			self.lines:delete(line_n, 1, line_n, offset)
		end
	end

	if offset then
		self.u_chars = self.u_chars - 1

		fixCaretAfterIndent(self, line_n, -offset)

		self:displaySyncDeletion(line_n, line_n)
		self:displaySyncCaretOffsets()

		self:updateVertPosHint()
	end

	return old_line ~= self.lines[line_n]
end


--- Returns if the field currently has a highlighted section (not whether highlighting itself is currently active.)
function _mt_ed_m:isHighlighted()
	return not (self.h_line == self.car_line and self.h_byte == self.car_byte)
end


function _mt_ed_m:clearHighlight()
	self.h_line = self.car_line
	self.h_byte = self.car_byte

	self:displaySyncCaretOffsets()
	self:updateDispHighlightRange()
end


function _mt_ed_m:caretToLineAndByte(clear_highlight, line_n, byte_n)
	-- XXX Maybe write an equivalent client method for jumping to a line and/or uChar offset.

	line_n = math.max(1, math.min(line_n, #self.lines))
	local line = self.lines[line_n]
	byte_n = math.max(1, math.min(byte_n, #line + 1))

	self.car_line = line_n
	self.car_byte = byte_n

	--print("self.car_line", self.car_line, "self.car_byte", self.car_byte)

	self:displaySyncCaretOffsets()
	self:updateVertPosHint()
	if clear_highlight then
		self:clearHighlight()
	else
		self:updateDispHighlightRange()
	end
end


function _mt_ed_m:caretAndHighlightToLineAndByte(car_line_n, car_byte_n, h_line_n, h_byte_n)
	-- XXX Maybe write an equivalent client method for jumping to a line and/or uChar offset.

	car_line_n = math.max(1, math.min(car_line_n, #self.lines))
	local line = self.lines[car_line_n]
	car_byte_n = math.max(1, math.min(car_byte_n, #line + 1))
	local line = self.lines[car_line_n]

	self.car_line = car_line_n
	self.car_byte = car_byte_n

	h_line_n = math.max(1, math.min(h_line_n, #self.lines))
	local line = self.lines[h_line_n]
	h_byte_n = math.max(1, math.min(h_byte_n, #line + 1))
	local line = self.lines[h_line_n]

	self.h_line = h_line_n
	self.h_byte = h_byte_n

	--print("self.car_line", self.car_line, "self.car_byte", self.car_byte)
	--print("self.h_line", self.h_line, "self.h_byte", self.h_byte)

	self:displaySyncCaretOffsets()
	self:updateVertPosHint()

	self:updateDispHighlightRange()
end


-- * Core-to-display synchronization *


--- Update the display container offsets to reflect the current core offsets. Also update the caret rectangle as stored in 'disp'. The display text must be current at time of call.
function _mt_ed_m:displaySyncCaretOffsets()
	local car_str = self.lines[self.car_line]
	local h_str = self.lines[self.h_line]
	local disp = self.disp
	local paragraphs = disp.paragraphs

	--[[
	print(
		"car_line", self.car_line,
		"h_line", self.h_line,
		"#car_str", car_str and #car_str or "nil",
		"self.car_byte", self.car_byte
	)
	--]]

	disp.d_car_para = self.car_line
	disp.d_car_byte, disp.d_car_sub = edComM.coreToDisplayOffsets(car_str, self.car_byte, paragraphs[disp.d_car_para])

	disp.d_h_para = self.h_line
	disp.d_h_byte, disp.d_h_sub = edComM.coreToDisplayOffsets(h_str, self.h_byte, paragraphs[disp.d_h_para])

	disp:updateCaretRect()
end


function _mt_ed_m:displaySyncInsertion(line_1, line_2) -- XXX integrate into insertText directly
	local lines = self.lines
	local disp = self.disp

	if line_1 ~= line_2 then
		disp:insertParagraphs(line_1, line_2 - line_1)
	end
	for i = line_1, line_2 do
		disp:updateParagraph(i, lines[i])
	end

	disp:refreshYOffsets(line_1)

	disp:updateHighlightDirtyRange(line_1, line_2)
	disp:updateHighlights()
	disp:setHighlightDirtyRange(self.car_line, self.h_line)
end


function _mt_ed_m:displaySyncDeletion(line_1, line_2) -- XXX integrate into deleteText directly
	local lines = self.lines
	local disp = self.disp

	if line_1 ~= line_2 then
		disp:removeParagraphs(line_1, line_2 - line_1)
	end

	disp:updateParagraph(line_1, lines[line_1])
	disp:refreshYOffsets(line_1)

	disp:updateHighlightDirtyRange(line_1, line_2)
	disp:updateHighlights()
	disp:setHighlightDirtyRange(self.car_line, self.h_line)
end


function _mt_ed_m:displaySyncAll(line_i)
	local lines = self.lines
	local disp = self.disp

	line_i = line_i or 1

	-- Update all display paragraphs starting at the requested index.
	-- We assume that all prior display paragraphs are up-to-date.
	for i = line_i, #lines do
		disp:updateParagraph(i, lines[i])
	end

	-- Trim excess paragraphs
	local paragraphs = disp.paragraphs
	for i = #paragraphs, #lines + 1, -1 do
		paragraphs[i] = nil
	end

	-- Update Y positions of the remaining sub-lines
	disp:refreshYOffsets(line_i)

	-- And the caret...
	self:displaySyncCaretOffsets()
	self:updateVertPosHint()

	-- Finally, update all highlight ranges.
	disp:updateHighlightDirtyRange(line_i, #paragraphs)
	disp:updateHighlights()
end


function _mt_ed_m:displaySyncAlign(line_i)
	local disp = self.disp
	line_i = line_i or 1

	disp:updateParagraphAlign(line_i)
	self:updateVertPosHint()
end


function _mt_ed_m:getFont()
	return self.disp.font
end


function _mt_ed_m:setFont(font)
	self.font = font or false
	self.disp:updateFont(font)
	self:displaySyncAll()

	-- Force a cache update on the widget after calling this (client.update_flag = true).
end


-- WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP
--   WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP
-- WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP


--[[
	LineEditor graphics state. Handles wrapped and aligned text, highlight rectangles, and provides caret XYWH values and blinking state.
	Does not handle scrolling, scroll bars, margins, line numbers, etc.
--]]


--[[
	(Logical) Line: An input string to be used as a source.
	Wrap-Line: A single line of display text to be printed. May also include a coloredtext version of the text.
	Paragraph: Holds one or more Wrap-Lines that correspond to a single Logical Line. Without wrapping, each Paragraph
		contains exactly one Wrap-Line.
	Line Container: The main 'disp' object. Holds Paragraphs, plus metadata and an optional LÖVE Text object.
--]]



-- Object metatables
-- Display line container (of paragraphs)
local _mt_lc = {}
_mt_lc.__index = _mt_lc


local function dispUpdateSubLineSyntaxColors(self, sub_line, byte_1, byte_2)
	--print("dispUpdateSubLineSyntaxColors", byte_1, byte_2, "colored_text", sub_line.colored_text, "syntax_colors", sub_line.syntax_colors)

	if sub_line.colored_text and sub_line.syntax_colors then
		local sub_str = sub_line.str
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

		while k <= #sub_str do
			local k2 = utf8.offset(sub_str, 2, k)

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


local function dispUpdateHighlight(self, i_para, i_sub, byte_1, byte_2)
	local font = self.font
	local paragraph = self.paragraphs[i_para]
	local sub_line = paragraph[i_sub]

	if byte_1 == byte_2 then
		sub_line.highlighted = false
	else
		local sub_str = sub_line.str

		-- NOTE: byte_1 and byte_2 can be OOB because string.sub() clamps the ranges.
		-- I guess there is a limit that is related to the maximum size of strings?
		-- math.huge for the second byte will lead to an empty string.

		local pixels_before = font:getWidth(string.sub(sub_str, 1, byte_1 - 1))
		local pixels_highlight = font:getWidth(string.sub(sub_str, byte_1, byte_2 - 1))

		-- Make byte_2 longer than #string + 1 to signify that the line feed is also highlighted.
		if byte_2 > #sub_str + 1 then
			pixels_highlight = pixels_highlight + self.width_line_feed
		end

		sub_line.highlighted = true

		sub_line.h_x = pixels_before
		sub_line.h_y = 0
		sub_line.h_w = pixels_highlight
		sub_line.h_h = sub_line.h
	end

	-- If applicable, overwrite or restore syntax colors.
	dispUpdateSubLineSyntaxColors(self, sub_line, byte_1, byte_2)
end


local function updateSubLineHorizontal(sub_line, align, font)
	sub_line.w = font:getWidth(sub_line.str)

	if align == "left" then
		sub_line.x = 0

	elseif align == "center" then
		sub_line.x = math.floor(0.5 - sub_line.w / 2)

	elseif align == "right" then
		sub_line.x = -sub_line.w
	end
end


-- * / Internal *


-- * Object creation *


function lineEdM.newLineContainer(font, color_t, color_h_t)
	local self = {} -- AKA "disp"

	self.paragraphs = {}

	-- To change align and wrap mode, use the methods in the LineEditor object.
	-- With center and right alignment, sub-lines will have negative X positions. The client
	-- needs to keep track of the align mode and offset the positions based on the document
	-- dimensions (which in turn are based on the number of lines and which lines are widest).
	-- Center alignment: Zero X == center of
	self.align = "left" -- "left", "center", "right"

	self.wrap_mode = false

	-- Copy of viewport #1 width. Used when wrapping text.
	self.view_w = 0

	self.font = font
	self.line_height = math.ceil(font:getHeight() * font:getLineHeight())

	-- Additional space between logical lines (in pixels).
	self.paragraph_pad = 0

	-- Pixels to add to a highlight to represent a selected line feed.
	-- Update this relative to the font size, maybe with a minimum size of 1 pixel.
	self.width_line_feed = 4

	-- Text colors, normal and highlighted.
	-- References to these tables will be copied around.
	self.text_color = color_t or {1, 1, 1, 1} -- XXX: skin
	self.text_h_color = color_h_t or {0, 0, 0, 1} -- XXX: skin

	editFuncM.setupCaretDisplayInfo(self, true, true)
	editFuncM.setupCaretBox(self)

	-- Update range for highlights, tracked on a per-Paragraph basis.
	self.h_line_min = math.huge
	self.h_line_max = 0

	-- Swaps out missing glyphs in the display string with a replacement glyph.
	-- The internal contents (and results of clipboard actions) remain the same.
	self.replace_missing = true

	--[[
	WARNING: masking cannot hide line feeds in the source string.
	--]]
	editFuncM.setupMaskedState(self)

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
	-- it. 'self' is the line container. 'syntax_t' is 'self.wip_syntax_colors', and it may contain existing
	-- contents. You must return the number of entries written to the table so that the update logic can clip
	-- the contents. 'work_t' is self.syntax_work, an arbitrary table you may use to help keep track of your
	-- colorization state.
	self.fn_colorize = false

	-- Temporary workspace for constructing syntax highlighting sequences.
	self.wip_syntax_colors = {}

	-- Arbitrary table of state intended to help manage syntax highlighting.
	self.syntax_work = {}

	setmetatable(self, _mt_lc)

	return self
end


-- * / Object creation *


-- * Line container methods *


function _mt_lc:getDocumentHeight()
	-- Assumes the final sub-line is current.
	local last_para = self.paragraphs[#self.paragraphs]
	local last_sub = last_para[#last_para]

	return last_sub.y + last_sub.h
end


function _mt_lc:getDocumentXBoundaries()
	local x1, x2 = 0, 0

	for i, paragraph in ipairs(self.paragraphs) do
		for j, sub_line in ipairs(paragraph) do
			x1 = math.min(x1, sub_line.x)
			x2 = math.max(x2, sub_line.x + sub_line.w)
		end
	end

	return x1, x2
end


-- @param y Y position, relative to the line container start point.
function _mt_lc:getOffsetsAtY(y)
	local paragraphs = self.paragraphs

	-- Find Paragraph and sub-line that are closest to the Y position.
	-- Default to the first sub-line, and progressively select each sub-line which
	-- is at least equal to the input Y position.
	local para_i = 1
	local sub_i = 1

	local sub_one = paragraphs[1][1]

	for i, paragraph in ipairs(paragraphs) do
		for j, sub_line in ipairs(paragraph) do
			if y < sub_line.y then
				break
			else
				para_i = i
				sub_i = j
			end
		end
	end

	return para_i, sub_i
end


-- @return Byte, X position and width of the glyph (if applicable).
function _mt_lc:getSubLineInfoAtX(para_i, sub_i, x, split_x)
	local paragraphs = self.paragraphs
	local font = self.font

	local para_t = paragraphs[para_i]
	local sub_t = para_t[sub_i]

	local sub_str = sub_t.str

	-- Temporarily make X relative to start of sub-line.
	x = x - sub_t.x

	local byte, glyph_x, glyph_w = textUtil.getTextInfoAtX(sub_str, font, x, split_x)

	return byte, glyph_x + sub_t.x, glyph_w
end


--- Get the height of a Paragraph by comparing its first and last sub-lines. The positions must be up to date when calling. Includes lineHeight spacing, but not paragraph spacing.
function _mt_lc:getParagraphHeight(para_i) -- XXX test
	local paragraph = self.paragraphs[para_i]
	local sub_first, sub_last = paragraph[1], paragraph[#paragraph]

	return sub_last.y + sub_last.h - sub_first.y
end


function _mt_lc:getSubLineUCharOffsetStart(para_i, sub_i)
	local paragraph = self.paragraphs[para_i]
	local u_count = 1

	for i = 1, sub_i - 1 do
		u_count = u_count + utf8.len(paragraph[i].str)
	end

	return u_count
end


function _mt_lc:getSubLineUCharOffsetEnd(para_i, sub_i)
	local paragraph = self.paragraphs[para_i]
	local u_count = 0

	for i = 1, sub_i do
		u_count = u_count + utf8.len(paragraph[i].str)
	end

	-- End of the Paragraph: add one more byte past the end.
	if sub_i >= #paragraph then
		u_count = u_count + 1
	end

	return u_count
end


function _mt_lc:getSubLineUCharOffsetStartEnd(para_i, sub_i)
	local paragraph = self.paragraphs[para_i]
	local u_count_1 = 1
	local u_count_2

	for i = 1, sub_i - 1 do
		u_count_1 = u_count_1 + utf8.len(paragraph[i].str)
	end
	u_count_2 = u_count_1 + utf8.len(paragraph[sub_i].str) - 1

	-- End of the Paragraph: add one more byte past the end.
	if sub_i >= #paragraph then
		u_count_2 = u_count_2 + 1
	end

	return u_count_1, u_count_2
end


--- Update sub-line Y offsets, beginning at the specified Paragraph index and continuing to the end of the `paragraphs` array.
-- @param para_i The first Paragraph to check. All previous sub-lines in the container must have up-to-date Y offsets.
function _mt_lc:refreshYOffsets(para_i)
	local paragraphs = self.paragraphs
	local y = 0

	-- If starting after Paragraph #1, assume that the previous sub-line has known-good coordinates.
	if para_i > 1 then
		local para_prev = paragraphs[para_i - 1]
		local sub_prev = para_prev[#para_prev]
		y = sub_prev.y + sub_prev.h + self.paragraph_pad
	end

	for i = para_i, #paragraphs do
		local paragraph = paragraphs[i]

		for j, sub_line in ipairs(paragraph) do
			sub_line.y = y
			y = y + sub_line.h
		end

		y = y + self.paragraph_pad
	end
end


--- Within a line container, update a Paragraph's contents.
-- @param i_para Index of the Paragraph. If not the first Paragraph, then all Paragraphs from 'index 1' to 'this index - 1' must be populated at time of call.
-- @param str The source / input string.
function _mt_lc:updateParagraph(i_para, str)
	local paragraphs = self.paragraphs
	local font = self.font

	-- Provision the Paragraph table.
	local paragraph = paragraphs[i_para] or {}
	paragraphs[i_para] = paragraph

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

	local final_index = 1
	if not self.wrap_mode then
		self:updateSubLine(i_para, 1, work_str, self.wip_syntax_colors, 1)
	else
		local width, wrapped = font:getWrap(work_str, self.view_w)
		local start_code_point = 1
		--[[
		XXX 13-NOV-2023: LÖVE 12-Development (17362b6) returns an empty table when given an empty string.
		LÖVE 11.4 returns a table with an empty string.
		LÖVE 0.10.2 returns an empty table.
		Just make 12 behave like 11.4 for now.
		--]]
		if #wrapped == 0 then
			wrapped[1] = ""
		end

		for i, wrapped_line in ipairs(wrapped) do
			--[[
			XXX 13-NOV-2023: LÖVE 11.4 font:getWrap() drops code points if the first glyph in a sub-line is thinner than
			the wraplimit. LÖVE 12-Development (17362b6) will place at least one glyph. LÖVE 0.10.2 behaves like 11.4.
			--]]
			if i < #wrapped and wrapped_line == "" then
				wrapped_line = "~"
			end
			self:updateSubLine(i_para, i, wrapped_line, self.wip_syntax_colors, start_code_point)

			start_code_point = start_code_point + utf8.len(wrapped_line)
		end
		final_index = #wrapped
	end

	-- Clear any stale sub-lines beyond the last-touched index
	for j = #paragraph, final_index + 1, -1 do
		paragraph[j] = nil
	end
end


-- Updates the alignment of sub-lines.
function _mt_lc:updateParagraphAlign(line_1, line_2)
	local paragraphs = self.paragraphs

	line_1 = line_1 or 1
	line_2 = line_2 or #paragraphs

	local align, font, width = self.align, self.font, self.view_w

	for i = line_1, line_2 do
		local paragraph = paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			updateSubLineHorizontal(sub_line, align, font)
		end
	end
end


--- Update a sub-line's text contents and X, width and height. Does not update Y position: call refreshYOffsets() afterward.
-- @param i_para Paragraph index.
-- @param i_sub Sub-line index.
-- @param str The new string to use.
function _mt_lc:updateSubLine(i_para, i_sub, str, syntax_colors, syntax_start)
	local font = self.font

	-- All sub-lines from index 1 to this index - 1 must be populated at time of call.
	local paragraph = self.paragraphs[i_para]

	-- Get / create sub-line table
	local sub_line = paragraph[i_sub] or {}
	paragraph[i_sub] = sub_line

	-- Position relative to top-left corner of the text region.
	sub_line.x = 0
	sub_line.y = 0

	-- Cached font:getWidth(self.str)
	sub_line.w = 0

	-- Cached 'math.ceil(font:getHeight() * font:getLineHeight())'
	sub_line.line_height = 0

	-- Normal string display text.
	if not str then
		error("DEBUG TODO: check why 'str' might be false/nil here.")
	end
	sub_line.str = str or ""

	-- Update syntax coloring, if applicable
	-- Colored display text (a table), or false if no table is provisioned for this line.
	if self.generate_colored_text then
		sub_line.syntax_colors = sub_line.syntax_colors or {}
		local len = utf8.len(str)
		local i = 1
		while i <= len do
			sub_line.syntax_colors[i] = syntax_colors[syntax_start + (i-1)]
			i = i + 1
		end
		for j = #sub_line.syntax_colors, i + 1, -1 do
			sub_line.syntax_colors[j] = nil
		end

		sub_line.colored_text = textUtil.stringToColoredText(sub_line.str, sub_line.colored_text, self.text_color, sub_line.syntax_colors)

		-- Debug
		--textUtil.debugPrintColoredText(sub_line.colored_text)
	else
		sub_line.syntax_colors = false
		sub_line.colored_text = false
	end

	-- Highlight rectangle enabled/disabled, and position relative to sub_line.x and sub_line.y.
	sub_line.highlighted = false
	sub_line.h_x = 0
	sub_line.h_y = 0
	sub_line.h_w = 0
	sub_line.h_h = 0

	paragraph[i_sub] = sub_line

	sub_line.h = math.ceil(font:getHeight() * font:getLineHeight())
	updateSubLineHorizontal(sub_line, self.align, font)
end


function _mt_lc:insertParagraphs(i_para, qty)
	for i = 1, qty do
		table.insert(self.paragraphs, i_para + i, {})
	end
end


function _mt_lc:removeParagraphs(i_para, qty)
	for i = 1, qty do
		table.remove(self.paragraphs, i_para)
	end
end


function _mt_lc:clearHighlightDirtyRange()
	self.h_line_min = math.huge
	self.h_line_max = 0
end


function _mt_lc:setHighlightDirtyRange(car_line, h_line)
	self.h_line_min = math.min(car_line, h_line)
	self.h_line_max = math.max(car_line, h_line)
end


function _mt_lc:updateHighlightDirtyRange(car_line, h_line)
	self.h_line_min = math.min(self.h_line_min, car_line, h_line)
	self.h_line_max = math.max(self.h_line_max, car_line, h_line)
end


function _mt_lc:fullHighlightDirtyRange()
	self.h_line_min = 1
	self.h_line_max = math.huge
end


function _mt_lc:updateHighlights()
	local paragraphs = self.paragraphs

	local line_1 = math.max(self.h_line_min, 1)
	local line_2 = math.min(self.h_line_max, #paragraphs)

	if line_1 > line_2 then
		return
	end

	-- Get line offsets relative to the display sequence.
	local para_1, sub_1, byte_1, para_2, sub_2, byte_2 = edComM.getHighlightOffsetsParagraph(
		self.d_car_para,
		self.d_car_sub,
		self.d_car_byte,
		self.d_h_para,
		self.d_h_sub,
		self.d_h_byte
	)

	-- paint_mode:
	-- 0: Painting a single line
	-- 1: Awaiting top of multiple lines
	-- 2: Handling in-between lines and bottom of multiple lines
	-- 3: Done / fall through to 'not highlighted'
	local paint_mode = 1
	if para_1 == para_2 and sub_1 == sub_2 then
		paint_mode = 0
	end

	for i = line_1, line_2 do
		local paragraph = paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			-- Single highlighted line
			if paint_mode == 0 and i == para_1 and j == sub_1 then
				dispUpdateHighlight(self, i, j, byte_1, byte_2)

			-- Top of multiple lines
			elseif paint_mode == 1 and i == para_1 and j == sub_1 then
				dispUpdateHighlight(self, i, j, byte_1, #sub_line.str + 2)
				paint_mode = 2

			-- Bottom of multiple lines
			elseif paint_mode == 2 and i == para_2 and j == sub_2 then
				dispUpdateHighlight(self, i, j, 1, byte_2)
				paint_mode = 3

			-- In-betweens
			elseif paint_mode == 2 then
				dispUpdateHighlight(self, i, j, 1, #sub_line.str + 2)

			-- Not highlighted
			else
				sub_line.highlighted = false
				dispUpdateSubLineSyntaxColors(self, sub_line, -1, -1)
			end
		end
	end
end


function _mt_lc:clearHighlights()
	for i, paragraph in ipairs(self.paragraphs) do
		for j, sub_line in ipairs(paragraph) do
			sub_line.highlighted = false
			dispUpdateSubLineSyntaxColors(self, sub_line, -1, -1)
		end
	end
end


function _mt_lc:updateCaretRect()
	--print("disp:updateCaretRect()")

	local font = self.font
	local paragraphs = self.paragraphs

	local para_cur = paragraphs[self.d_car_para]
	local sub_line_cur = para_cur[self.d_car_sub]

	-- Update cached caret info.
	self.caret_box_x = textUtil.getCharacterX(sub_line_cur.str, self.d_car_byte, font)

	-- If we are at the end of the string + 1: use the width of the underscore character.
	self.caret_box_w = textUtil.getCharacterW(sub_line_cur.str, self.d_car_byte, font) or font:getWidth("_")

	-- Apply horizontal alignment offsetting to caret.
	self.caret_box_x = edComBase.applyCaretAlignOffset(self.caret_box_x, sub_line_cur.str, self.align, font)

	self.caret_box_y = sub_line_cur.y
	self.caret_box_h = font:getHeight()
end


function _mt_lc:updateFont(font)
	self.font = font
	if font then
		self.line_height = math.ceil(font:getHeight() * font:getLineHeight())
	else
		self.line_height = 0
	end

	self:refreshFontParams()
	-- All display lines need to be updated after calling.
end


-- * / Line container methods *


function _mt_lc:refreshFontParams()
	local font = self.font
	local em_width
	if font then
		em_width = font:getWidth("M")
	else
		em_width = 1
	end

	self.caret_line_width = math.max(1, math.ceil(em_width / 16))
	self.width_line_feed = math.max(1, math.ceil(em_width / 4))

	-- Client should refresh/clamp scrolling and ensure the caret is visible after this function is called.
end


_mt_lc.resetCaretBlink = editFuncM.dispResetCaretBlink
_mt_lc.updateCaretBlink = editFuncM.dispUpdateCaretBlink


return lineEdM
