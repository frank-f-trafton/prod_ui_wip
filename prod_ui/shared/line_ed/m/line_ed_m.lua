-- LineEditor (multi) core object.

--[[
Widgets may need to run additional update code after a method is executed (for example,
to update the visual state of the caret).

Data structures:

* LE.lines {strings}: The internal text, split by line feeds. For the implementation, see 'seq_string.lua'.
* LE.paragraphs {tables}: Display data for each line of text. Each paragraph is an array of sub-lines.
* Sub-line: A single line of display text to be printed. May also include a coloredtext version of the text.
--]]


local context = select(1, ...)


local lineEdM = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local code_groups = context:getLua("shared/line_ed/code_groups")
local edCom = context:getLua("shared/line_ed/ed_com")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")
local seqString = context:getLua("shared/line_ed/seq_string")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")


lineEdM.code_groups = code_groups


local _mt_ed_m = {}
_mt_ed_m.__index = _mt_ed_m


--- Creates a new Line Editor object.
-- @return the LineEd table.
function lineEdM.new()
	local self = setmetatable({}, _mt_ed_m)

	self.font = false

	-- String sequence representing each line of internal text.
	self.lines = seqString.new()

	-- Current line and position (in bytes) of the text caret and the highlight selection.
	-- The caret can appear before or after the highlight position. If they have the same
	-- position, then highlighting is not active.
	self.cl = 1 -- caret line
	self.cb = 1 -- caret byte
	self.hl = 1 -- highlight line
	self.hb = 1 -- highlight byte

	-- Display state.
	self.paragraphs = {}

	-- Caret and highlight lines, sub-lines and bytes for the display text.
	-- These are based on the internal caret and highlight positions.
	self.dcp = 1 -- caret paragraph
	self.dcs = 1 -- caret sub-line
	self.dcb = 1 -- caret byte
	self.dhp = 1 -- highlight paragraph
	self.dhs = 1 -- highlight sub-line
	self.dhb = 1 -- highlight byte

	-- To change align and wrap mode, use the methods provided by the widget.
	-- With center and right alignment, sub-lines will have negative X positions. The client
	-- needs to keep track of the align mode and offset the positions based on the document
	-- dimensions (which in turn are based on the number of lines and which lines are widest).
	-- Center alignment: Zero X == center of
	self.align = "left" -- "left", "center", "right"

	self.wrap_mode = false

	-- Used when wrapping text. See: LE:setWrapWidth()
	self.wrap_w = 0

	-- Additional space between logical lines (in pixels).
	-- TODO: theming/scaling
	self.paragraph_pad = 0

	-- Pixels to add to a highlight to represent a selected line feed.
	-- Update this relative to the font size, maybe with a minimum size of 1 pixel.
	self.line_feed_width = 0

	self.caret_line_width = 1

	-- Text colors, normal and highlighted.
	-- References to these tables will be copied around.
	self.text_color = edCom.default_text_color
	self.text_h_color = edCom.default_text_h_color

	-- The position and dimensions of the currently selected character.
	-- The client widget uses these values to determine the size and location of its caret.
	self.caret_box_x = 0
	self.caret_box_y = 0
	self.caret_box_w = 0
	self.caret_box_h = 0

	-- Swaps out missing glyphs in the display string with a replacement glyph.
	-- The internal contents (and results of clipboard actions) remain the same.
	self.replace_missing = true

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

	-- X position hint when stepping up or down.
	self.vertical_x_hint = 0

	-- Cached copy of 'lines' length in Unicode code points.
	self.u_chars = self.lines:uLen()

	-- ASAP:
	-- * Assign a font with LE:setFont()
	-- * Update display text
	return self
end


-- Updates the X position hint for when stepping the caret up and down. The display text must be up to date.
local function _updateVerticalCaretHint(self)
	local d_sub = self.paragraphs[self.dcp][self.dcs]
	local d_str = d_sub.str
	self.vertical_x_hint = d_sub.x + textUtil.getCharacterX(d_str, self.dcb, self.font)
end


local function _updateDisplaySubHorizontal(sub_line, align, font)
	sub_line.w = font:getWidth(sub_line.str)

	if align == "left" then
		sub_line.x = 0

	elseif align == "center" then
		sub_line.x = math.floor(0.5 - sub_line.w / 2)

	elseif align == "right" then
		sub_line.x = -sub_line.w
	end
end


--- Update a sub-line's text contents and X, width and height. Does not update Y position.
-- @param i_para Paragraph index.
-- @param i_sub Sub-line index.
-- @param str The new string to use.
local function _updateDisplaySubLine(self, i_para, i_sub, str, syntax_colors, syntax_start)
	local font = self.font

	-- All sub-lines from index 1 to this index - 1 must be populated at time of call.
	local paragraph = self.paragraphs[i_para]

	-- Get / create sub-line table
	local sub_line = paragraph[i_sub] or {}
	paragraph[i_sub] = sub_line

	-- Position relative to top-left corner of the text region.
	sub_line.x = 0
	sub_line.y = 0

	-- Cached font:getWidth(str)
	sub_line.w = 0

	-- Normal string display text.
	if not str then
		error("DEBUG TODO: check why 'str' might be false/nil here.") -- TODO
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
	_updateDisplaySubHorizontal(sub_line, self.align, font)
end


local function _updateSubLineSyntaxColors(self, sub_line, byte_1, byte_2)
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


local function _updateHighlight(self, i_para, i_sub, byte_1, byte_2)
	local font = self.font
	local paragraph = self.paragraphs[i_para]
	local sub_line = paragraph[i_sub]

	if byte_1 == byte_2 then
		sub_line.highlighted = false
	else
		local sub_str = sub_line.str

		-- NOTE: byte_1 and byte_2 can be OOB because string.sub() clamps the ranges.
		local pixels_before = font:getWidth(sub_str:sub(1, byte_1 - 1))
		local pixels_highlight = font:getWidth(sub_str:sub(byte_1, byte_2 - 1))

		-- When byte_2 > #string + 1, it's a signal that the invisible line feed is highlighted.
		if byte_2 > #sub_str + 1 then
			pixels_highlight = pixels_highlight + self.line_feed_width
		end

		sub_line.highlighted = true

		sub_line.h_x = pixels_before
		sub_line.h_y = 0
		sub_line.h_w = pixels_highlight
		sub_line.h_h = sub_line.h
	end

	-- If applicable, overwrite or restore syntax colors.
	_updateSubLineSyntaxColors(self, sub_line, byte_1, byte_2)
end


function _mt_ed_m:getCaretOffsets()
	return self.cl, self.cb, self.hl, self.hb
end


--- Gets caret and highlight lines and offsets (in order from top to bottom).
function _mt_ed_m:getCaretOffsetsInOrder()
	local l1, b1, l2, b2 = self.cl, self.cb, self.hl, self.hb

	if l1 == l2 then
		b1, b2 = math.min(b1, b2), math.max(b1, b2)

	elseif l1 > l2 then
		l1, l2, b1, b2 = l2, l1, b2, b1
	end

	return l1, b1, l2, b2
end


function _mt_ed_m:compareCaretOffsets(cl, cb, hl, hb)
	return cl == self.cl and cb == self.cb and hl == self.hl and hb == self.hb
end


--- Returns if the LineEd currently has a highlighted section (not whether highlighting itself is currently active.)
function _mt_ed_m:isHighlighted()
	return not (self.hl == self.cl and self.hb == self.cb)
end


function _mt_ed_m:clearHighlight()
	local l1, _, l2, _ = self:getCaretOffsetsInOrder()
	local xhl, xhb = self.hl, self.hb
	self.hl, self.hb = self.cl, self.cb
	if not (self.hl == xhl and self.hb == xhb) then
		self:syncDisplayCaretHighlight(l1, l2)
	end
end


-- @param x X position.
-- @param y Y position.
-- @param split_x When true, if the X position is on the right half of a character, get details for the next character to the right.
-- @return Line and byte at (or nearest to) the position.
function _mt_ed_m:getCharacterDetailsAtPosition(x, y, split_x)
	local paragraphs = self.paragraphs
	local font = self.font

	-- Find Paragraph and sub-line that are closest to the Y position.
	-- Default to the first sub-line, and progressively select each sub-line which
	-- is at least equal to the input Y position.
	local para_i, sub_i = 1, 1

	-- TODO: could probably write this to be faster.
	for i, paragraph in ipairs(paragraphs) do
		for j, sub_line in ipairs(paragraph) do
			if y < sub_line.y then
				break
			else
				para_i, sub_i = i, j
			end
		end
	end

	local paragraph = paragraphs[para_i]
	local sub_line = paragraph[sub_i]

	local byte, x_pos, width = self:dispGetSubLineInfoAtX(para_i, sub_i, x, split_x)

	-- Convert display offset to core byte
	local u_count = edComM.displaytoUCharCount(paragraph, sub_i, byte)

	local core_line = para_i
	local core_str = self.lines[core_line]
	local core_byte = utf8.offset(core_str, u_count)

	return core_line, core_byte
end


-- @return Byte, X position and width of the glyph (if applicable).
function _mt_ed_m:dispGetSubLineInfoAtX(para_i, sub_i, x, split_x)
	local font = self.font
	local para_t = self.paragraphs[para_i]
	local sub_t = para_t[sub_i]
	local sub_str = sub_t.str

	-- Temporarily make X relative to start of sub-line.
	x = x - sub_t.x

	local byte, glyph_x, glyph_w = textUtil.getTextInfoAtX(sub_str, font, x, split_x)

	return byte, glyph_x + sub_t.x, glyph_w
end


-- @param cl, cb The new caret line and byte offsets.
-- @param clear_highlight When true, sets the highlight to the caret.
-- @param update_x_hint True to update the vertical X hint.
-- @return true if the caret position (including highlight) changed.
function _mt_ed_m:moveCaret(cl, cb, clear_highlight, update_x_hint)
	local temp

	cl = math.max(1, math.min(cl, #self.lines))
	temp = self.lines[cl]
	cb = math.max(1, math.min(cb, #temp + 1))

	local xcl, xcb, xhl, xhb = self.cl, self.cb, self.hl, self.hb
	self.cl, self.cb = cl, cb
	if clear_highlight then
		self.hl, self.hb = cl, cb
	end
	self:syncDisplayCaretHighlight(math.min(xcl, xhl), math.max(xcl, xhl))
	self:syncDisplayCaretHighlight(math.min(self.cl, self.hl), math.max(self.cl, self.hl))

	if update_x_hint then
		_updateVerticalCaretHint(self)
	end

	return not (xcl == self.cl and xcb == self.cb and xhl == self.hl and xhb == self.hb)
end


-- @param cl, cb The new caret line and byte offsets.
-- @param hl, hb The new highlight line and byte offsets.
-- @param update_x_hint True to update the vertical X hint.
-- @return true if the caret position (including highlight) changed.
function _mt_ed_m:moveCaretAndHighlight(cl, cb, hl, hb, update_x_hint)
	local temp

	cl = math.max(1, math.min(cl, #self.lines))
	temp = self.lines[cl]
	cb = math.max(1, math.min(cb, #temp + 1))

	hl = math.max(1, math.min(hl, #self.lines))
	temp = self.lines[hl]
	hb = math.max(1, math.min(hb, #temp + 1))

	local xcl, xcb, xhl, xhb = self.cl, self.cb, self.hl, self.hb
	self.cl, self.cb, self.hl, self.hb = cl, cb, hl, hb
	self:syncDisplayCaretHighlight(math.min(xcl, xhl), math.max(xcl, xhl))
	self:syncDisplayCaretHighlight(math.min(cl, hl), math.max(cl, hl))

	if update_x_hint then
		_updateVerticalCaretHint(self)
	end

	return not (xcl == self.cl and xcb == self.cb and xhl == self.hl and xhb == self.hb)
end


--- Insert a string at the caret position.
-- @param text The string to insert.
function _mt_ed_m:insertText(text)
	local xcl = self.cl

	self:clearHighlight()

	self.cl, self.cb = self.lines:add(text, self.cl, self.cb)
	self.hl, self.hb = self.cl, self.cb

	if xcl ~= self.cl then
		for i = xcl + 1, self.cl do
			table.insert(self.paragraphs, i, {})
			--print("inserted at index " .. i, #self.paragraphs)
		end
	end

	self:updateDisplayText(xcl, self.cl)
	self:syncDisplayCaretHighlight(self.cl, self.cl)
	_updateVerticalCaretHint(self)
end


--- Delete a section of text.
-- @param copy_deleted If true, return the deleted text as a string.
-- @param l1, b1 The first line and byte to delete from.
-- @param l2, b2 The final line and byte to delete to.
-- @return The deleted text as a string, if 'copy_deleted' was true (and at least one character was deleted), or nil.
function _mt_ed_m:deleteText(copy_deleted, l1, b1, l2, b2)
	local lines = self.lines

	self:clearHighlight()

	local deleted
	if copy_deleted then
		deleted = table.concat(lines:copy(l1, b1, l2, b2), "\n")
	end

	lines:delete(l1, b1, l2, b2)

	self.cl, self.cb, self.hl, self.hb = l1, b1, l1, b1

	if l1 ~= l2 then
		for i = l2, l1 + 1, -1 do
			table.remove(self.paragraphs, i)
		end
	end

	self:updateDisplayText(self.cl, self.cl)
	self:syncDisplayCaretHighlight(self.cl, self.cl)
	_updateVerticalCaretHint(self)

	return deleted ~= "" and deleted
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

	return line_left, byte_left, line_right, byte_right
end


function _mt_ed_m:updateDisplayText(para_1, para_2)
	local lines = self.lines
	local paragraphs = self.paragraphs
	local font = self.font

	para_1 = para_1 or 1
	para_2 = para_2 or #lines

	for i = para_1, para_2 do
		local str = lines[i]

		-- Make sure the paragraph table exists.
		local paragraph = paragraphs[i] or {}
		paragraphs[i] = paragraph

		-- Perform optional modifications on the string.
		local work_str = str

		if self.replace_missing then
			work_str = textUtil.replaceMissingCodePointGlyphs(work_str, font, "□")
		end

		if self.fn_colorize and self.generate_colored_text then
			local len = self:fn_colorize(work_str, self.wip_syntax_colors, self.syntax_work)
			-- Trim color table
			for j = #self.wip_syntax_colors, len + 1, -1 do
				self.wip_syntax_colors[j] = nil
			end
		end

		local final_index = 1
		if not self.wrap_mode then
			_updateDisplaySubLine(self, i, 1, work_str, self.wip_syntax_colors, 1)
		else
			local width, wrapped = font:getWrap(work_str, self.wrap_w)
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

			for j, wrapped_line in ipairs(wrapped) do
				--[[
				XXX 13-NOV-2023: LÖVE 11.4 font:getWrap() drops code points if the first glyph in a sub-line is thinner than
				the wraplimit. LÖVE 12-Development (17362b6) will place at least one glyph. LÖVE 0.10.2 behaves like 11.4.
				--]]
				if i < #wrapped and wrapped_line == "" then
					wrapped_line = "~"
				end
				_updateDisplaySubLine(self, i, j, wrapped_line, self.wip_syntax_colors, start_code_point)

				start_code_point = start_code_point + utf8.len(wrapped_line)
			end
			final_index = #wrapped
		end

		-- Clear any stale sub-lines beyond the last-touched index
		for j = #paragraph, final_index + 1, -1 do
			paragraph[j] = nil
		end
	end

	-- Update sub-line Y offsets.
	local y = 0

	-- If starting after Paragraph #1, assume that the previous sub-line's coords are good.
	if para_1 > 1 then
		local para_prev = paragraphs[para_1 - 1]
		local sub_prev = para_prev[#para_prev]
		y = sub_prev.y + sub_prev.h + self.paragraph_pad
	end

	for i = para_1, #paragraphs do
		local paragraph = paragraphs[i]

		for j, sub_line in ipairs(paragraph) do
			sub_line.y = y
			y = y + sub_line.h
		end

		y = y + self.paragraph_pad
	end
end


--- Updates caret shape and display offsets.
function _mt_ed_m:updateCaret()
	local car_str = self.lines[self.cl]
	local h_str = self.lines[self.hl]
	local paragraphs = self.paragraphs

	--print("cl", self.cl, "hl", self.hl, "#car_str", car_str and #car_str or "nil", "self.cb", self.cb)

	self.dcp = self.cl
	self.dcb, self.dcs = edComM.coreToDisplayOffsets(car_str, self.cb, paragraphs[self.dcp])

	self.dhp = self.hl
	self.dhb, self.dhs = edComM.coreToDisplayOffsets(h_str, self.hb, paragraphs[self.dhp])

	local font = self.font
	local para_cur = paragraphs[self.dcp]
	local sub_line_cur = para_cur[self.dcs]

	-- Update cached caret info.
	self.caret_box_x = textUtil.getCharacterX(sub_line_cur.str, self.dcb, font)

	-- If we are at the end of the string + 1: use the width of the underscore character.
	self.caret_box_w = textUtil.getCharacterW(sub_line_cur.str, self.dcb, font) or font:getWidth("_")

	-- Apply horizontal alignment offsetting to caret.
	self.caret_box_x = edComM.applyCaretAlignOffset(self.caret_box_x, sub_line_cur.str, self.align, font)

	self.caret_box_y = sub_line_cur.y
	self.caret_box_h = font:getHeight()
end


--- Updates the display caret offsets, the caret rectangle, and the highlight rectangle. The display text must be
--	current at time of call.
function _mt_ed_m:syncDisplayCaretHighlight(para_1, para_2)
	local paragraphs = self.paragraphs

	para_1 = para_1 or 1
	para_2 = para_2 or #self.lines

	self:updateCaret()

	-- Get line offsets relative to the display sequence.
	local dp1, ds1, db1, dp2, ds2, db2 = edComM.getDisplayOffsetsInOrder(
		self.dcp, self.dcs, self.dcb, self.dhp, self.dhs, self.dhb
	)

	-- paint_mode:
	-- 0: Painting a single line
	-- 1: Awaiting top of multiple lines
	-- 2: Handling in-between lines and bottom of multiple lines
	-- 3: Done / fall through to 'not highlighted'
	local paint_mode = 1
	if dp1 == dp2 and ds1 == ds2 then
		paint_mode = 0
	end

	for i = para_1, para_2 do
		local paragraph = paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			-- Single highlighted line
			if paint_mode == 0 and i == dp1 and j == ds1 then
				_updateHighlight(self, i, j, db1, db2)

			-- Top of multiple lines
			elseif paint_mode == 1 and i == dp1 and j == ds1 then
				_updateHighlight(self, i, j, db1, #sub_line.str + 2)
				paint_mode = 2

			-- Bottom of multiple lines
			elseif paint_mode == 2 and i == dp2 and j == ds2 then
				_updateHighlight(self, i, j, 1, db2)
				paint_mode = 3

			-- In-betweens
			elseif paint_mode == 2 then
				_updateHighlight(self, i, j, 1, #sub_line.str + 2)

			-- Not highlighted
			else
				sub_line.highlighted = false
				_updateSubLineSyntaxColors(self, sub_line, -1, -1)
			end
		end
	end
end


function _mt_ed_m:syncDisplayAlignment(line_1, line_2)
	local paragraphs = self.paragraphs

	line_1 = line_1 or 1
	line_2 = line_2 or #paragraphs

	local align, font, width = self.align, self.font, self.wrap_w

	for i = line_1, line_2 do
		local paragraph = paragraphs[i]
		for j, sub_line in ipairs(paragraph) do
			_updateDisplaySubHorizontal(sub_line, align, font)
		end
	end
end


--- Gets the top and bottom selected line indices and the selection bytes that go with them, in order.
-- @param omit_empty_last_selection When true, exclude the bottom line if the selection is at the start.
function _mt_ed_m:getSelectedLinesRange(omit_empty_last_selection)
	local l1, b1, l2, b2 = self:getCaretOffsetsInOrder()

	if omit_empty_last_selection and l2 > l1 and b2 <= 1 then
		l2 = math.max(l1, l2 - 1)
		b2 = #self.lines[l2] + 1
	end

	return l1, l2, b1, b2
end


function _mt_ed_m:getWrappedLineRange(line_n, byte_n)
	local lines = self.lines

	if line_n < 1 or line_n > #lines then
		error("'line_n' is out of range.")
	end

	local line_str = lines[line_n]
	if byte_n < 1 or byte_n > #line_str + 1 then
		error("'byte_n' is out of range.")
	end

	-- Convert input line+byte pair to display paragraph, sub, byte offsets.
	local d_para = line_n
	local d_byte, d_sub = edComM.coreToDisplayOffsets(line_str, byte_n, self.paragraphs[d_para])

	-- Get first, last uChar offsets
	local u_count_1, u_count_2 = edComM.getSubLineUCharOffsetStartEnd(self.paragraphs[d_para], d_sub)

	-- Convert soft-wrap code point counts in the display text to byte offsets in the core/source string
	local byte_start = utf8.offset(lines[line_n], u_count_1)
	local byte_end = utf8.offset(lines[line_n], u_count_2)

	return byte_start, byte_end
end


function _mt_ed_m:getDisplayXBoundaries()
	local x1, x2 = 0, 0

	for i, paragraph in ipairs(self.paragraphs) do
		for j, sub_line in ipairs(paragraph) do
			x1 = math.min(x1, sub_line.x)
			x2 = math.max(x2, sub_line.x + sub_line.w)
		end
	end

	return x1, x2
end


--- Get the height of a Paragraph by comparing its first and last sub-lines. The positions must be up to date when
--	calling. Includes lineHeight spacing, but not paragraph spacing.
function _mt_ed_m:getDisplayParagraphHeight(para_i) -- XXX test
	local paragraph = self.paragraphs[para_i]
	local sub_first, sub_last = paragraph[1], paragraph[#paragraph]

	return sub_last.y + sub_last.h - sub_first.y
end


function _mt_ed_m:setFont(font)
	uiAssert.loveTypeEval(1, font, "Font")

	if font and self.font == font then
		return
	end

	self.font = font or false
	if self.font then
		local em_width = font:getWidth("M")
		self.caret_line_width = math.max(1, math.ceil(em_width / 16))
		self.line_feed_width = math.max(1, math.ceil(em_width / 4))

		self:updateDisplayText()
		self:syncDisplayCaretHighlight()
		_updateVerticalCaretHint(self)
	end
end


function _mt_ed_m:setTextColors(text_color, text_h_color)
	uiAssert.typeEval(1, text_color, "table")
	uiAssert.typeEval(2, text_h_color, "table")

	self.text_color = text_color or edCom.default_text_color
	self.text_h_color = text_h_color or edCom.default_text_h_color

	self:syncDisplayCaretHighlight()
end


function _mt_ed_m:setWrapMode(enabled)
	enabled = not not enabled
	if self.wrap_mode ~= enabled then
		self.wrap_mode = enabled
		self:updateDisplayText()
		self:syncDisplayCaretHighlight()
		_updateVerticalCaretHint(self)
		return true
	end
end


function _mt_ed_m:setWrapWidth(w)
	if self.wrap_w ~= w then
		self.wrap_w = w
		if self.wrap_mode then
			self:updateDisplayText()
			self:syncDisplayCaretHighlight()
			_updateVerticalCaretHint(self)
		end
		return true
	end
end


function _mt_ed_m:setColorization(enabled)
	enabled = not not enabled
	if self.generate_colored_text ~= enabled then
		self.generate_colored_text = enabled
		self:updateDisplayText()
		self:syncDisplayCaretHighlight()
		_updateVerticalCaretHint(self)
		return true
	end
end


function _mt_ed_m:setTextAlignment(align)
	if self.align ~= align then
		self.align = align
		self:syncDisplayAlignment()
		self:syncDisplayCaretHighlight()
		_updateVerticalCaretHint(self)
		return true
	end
end


function _mt_ed_m:setParagraphPadding(pad)
	self.paragraph_pad = math.max(0, pad)
end


-- Debug methods.
-- [====[
function _mt_ed_m:_printInternalText(first, last)
	first = first or 1
	last = last or #self.lines
	for i = first, last do
		local line = self.lines[i]
		print(i, "|" .. line .. "|")
	end
end


function _mt_ed_m:_printDisplayText(first, last)
	first = first or 1
	last = last or #self.paragraphs
	for i = first, last do
		local para = self.paragraphs[i]
		for j, sub_line in ipairs(para) do
			print(i, j, "|" .. sub_line.str .. "|")
		end
	end
end
--]====]


return lineEdM
