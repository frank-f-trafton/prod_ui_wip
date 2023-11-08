--[[
	EditField graphics state. Handles wrapped and aligned text, highlight rectangles, and provides caret XYWH values and blinking state.
	Does not handle scrolling, scroll bars, margins, line numbers, etc.
--]]


local editDisp = {}


--[[
	Logical line: An input string to be used as a source.
	Sub-line: A single line of display text to be printed. May also include a coloredtext sequence version of the text.
	Super-line: One display line, broken up into sub-lines by word-wrap.
		(Without wrapping, each super-line contains exactly one sub-line.)
	Line container: Holds super-lines, plus metadata and an optional LÖVE Text object.
--]]


local PATH = ... and (...):match("(.-)[^%.]+$") or ""

-- LÖVE Supplemental
local utf8 = require("utf8")


local edCom = require(PATH .. "ed_com")
local edVis = require(PATH .. "ed_vis")


-- Object metatables
-- Line container
local _mt_lc = {}
_mt_lc.__index = _mt_lc


-- Super-Line
local _mt_sup = {}
_mt_sup.__index = _mt_sup


-- Sub-Line
local _mt_sub = {}
_mt_sub.__index = _mt_sub


-- * Internal *


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


local function dispUpdateHighlight(self, i_super, i_sub, byte_1, byte_2)

	local font = self.font
	local super_line = self.super_lines[i_super]
	local sub_line = super_line[i_sub]

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


local function applyCaretAlignOffset(caret_x, line_str, align, font)

	if align == "left" then
		-- n/a

	elseif align == "center" then
		caret_x = caret_x + math.floor(0.5 - font:getWidth(line_str) / 2)

	elseif align == "right" then
		caret_x = caret_x - font:getWidth(line_str)
	end

	return caret_x
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


-- * Public helper functions *


--- Given a line length, a byte offset and a specific super-line structure, return a byte and sub-line offset suitable for the display structure.
function editDisp.coreToDisplayOffsets(s_bytes, byte_n, super_line)

	-- End of line
	if byte_n == s_bytes + 1 then
		return #super_line[#super_line].str + 1, #super_line

	else
		local line_sub = 1

		while true do
			-- Uncomment to help debug OOB issues here:
			--print("byte_n", byte_n, "super_line[line_sub]", super_line[line_sub])

			if byte_n <= #super_line[line_sub].str then
				break
			end

			byte_n = byte_n - #super_line[line_sub].str
			line_sub = line_sub + 1
		end

		return byte_n, line_sub
	end
end


--- Given a display-lines object, a super-line index, a sub-line index, and a number of steps, get the sub-line 'n_steps' away, or
--  the top or bottom sub-line if reaching the start or end respectively.
function editDisp.stepSubLine(display_lines, d_car_super, d_car_sub, n_steps)

	while n_steps < 0 do
		-- First line
		if d_car_super <= 1 and d_car_sub <= 1 then
			d_car_super = 1
			d_car_sub = 1
			break

		else
			d_car_sub = d_car_sub - 1
			if d_car_sub == 0 then
				d_car_super = d_car_super - 1
				d_car_sub = #display_lines[d_car_super]
			end

			n_steps = n_steps + 1
		end
	end

	while n_steps > 0 do
		-- Last line
		if d_car_super >= #display_lines and d_car_sub >= #display_lines[#display_lines] then
			d_car_super = #display_lines
			d_car_sub = #display_lines[#display_lines]
			break

		else
			d_car_sub = d_car_sub + 1

			if d_car_sub > #display_lines[d_car_super] then
				d_car_super = d_car_super + 1
				d_car_sub = 1
			end

			n_steps = n_steps - 1
		end
	end

	return d_car_super, d_car_sub
end


function editDisp.getSubLineCount(super_lines, line_1, sub_1, line_2, sub_2)

	local count = 0
	local sub_c = sub_1

	for i = line_1, #super_lines do
		local super = super_lines[i]
		while sub_c <= #super do
			count = count + 1

			if i == line_2 and sub_c == sub_2 then
				return count
			end

			sub_c = sub_c + 1
		end
		sub_c = 1
	end

	return count
end


--- Sorts display caret and highlight offsets from first to last. (Super-line, sub-line, and byte.)
function editDisp.getHighlightOffsetsSuperLine(line_1, sub_1, byte_1, line_2, sub_2, byte_2)

	if line_1 == line_2 and sub_1 == sub_2 then
		byte_1, byte_2 = math.min(byte_1, byte_2), math.max(byte_1, byte_2)

	elseif line_1 == line_2 and sub_1 > sub_2 then
		sub_1, sub_2, byte_1, byte_2 = sub_2, sub_1, byte_2, byte_1

	elseif line_1 > line_2 then
		line_1, line_2, sub_1, sub_2, byte_1, byte_2 = line_2, line_1, sub_2, sub_1, byte_2, byte_1
	end

	return line_1, sub_1, byte_1, line_2, sub_2, byte_2
end


-- * / Public helper functions *


-- * Object creation *


function editDisp.newLineContainer(font, color_t, color_h_t)

	local self = {} -- AKA "disp"

	self.super_lines = {}

	-- To change align and wrap mode, use the methods in the core object.
	-- With center and right alignment, sub-lines will have negative X positions. The client
	-- needs to keep track of the align mode and offset the positions based on the document
	-- dimensions (which in turn are based on the number of lines and which lines are widest).
	-- Center alignment: Zero X == center of 
	self.align = "left" -- "left", "center", "right"

	self.wrap_mode = false

	self.font = font
	self.font_height = font:getHeight()
	self.line_height = math.ceil(font:getHeight() * font:getLineHeight())

	-- Additional space between logical lines (in pixels).
	self.paragraph_pad = 0

	-- Pixels to add to a highlight to represent a selected line feed.
	-- Update this relative to the font size, maybe with a minimum size of 1 pixel.
	self.width_line_feed = 4

	-- Text colors, normal and highlighted.
	-- References to these tables will be copied around.
	self.text_color = color_t or {1, 1, 1, 1}
	self.text_h_color = color_h_t or {0, 0, 0, 1}

	-- Caret and highlight lines, sub-lines and bytes for the display text.
	self.d_car_super = 1
	self.d_car_sub = 1
	self.d_car_byte = 1

	self.d_h_super = 1
	self.d_h_sub = 1
	self.d_h_byte = 1

	-- Update range for highlights, tracked on a per-super-line basis.
	self.h_line_min = math.huge
	self.h_line_max = 0

	-- Caret position + dimensions relative to text.
	self.caret_box_x = 0
	self.caret_box_y = 0
	self.caret_box_w = 0
	self.caret_box_h = 0

	-- Show the caret (text cursor).
	self.caret_line_width = 1
	self.show_caret = true

	self.blink_time = 0
	self.blink_reset = -0.5
	self.blink_on = 0.5
	self.blink_off = 0.5

	-- Swaps out missing glyphs in the display string with a replacement glyph.
	-- The internal contents (and results of clipboard actions) remain the same.
	self.replace_missing = true

	-- Glyph masking mode, as used in password fields.
	-- Note that this only changes the UTF-8 string which is sent to text rendering functions.
	-- It does nothing else with respect to security.
	self.masked = false
	self.mask_glyph = "*" -- Must be exactly one glyph.

	-- Set true to create coloredtext tables for each sub-line string. Each coloredtext
	-- table contains a color table and a code point string for every code point in the base
	-- string. The initial color table is 'self.text_color_t'. For example, the string "foobar"
	-- would become {col_t, "f", col_t, "o", col_t, "o", col_t, "b", col_t, "a", col_t, "r", }.
	-- This uses considerably more memory than a single string, but allows recoloring on a
	-- per-code point basis, which is convenient if you want to perform more than one pass of
	-- coloring (such as in the case of mixing syntax highlighting and also inverting highlighted
	-- text).
	self.generate_colored_text = false

	-- Assign a function taking 'self', 'str', 'syntax_t', and 'work_t' to colorize a super-line when updating
	-- it. 'self' is the line container. 'syntax_t' is 'self.wip_syntax_colors', and it may contain existing
	-- contents. You must return the number of entries written to the table so that the update logic can clip
	-- the contents. 'work_t' is self.syntax_work, an arbitrary table you may use to help keep track of your
	-- colorization state.
	self.fn_colorize = false

	-- Temporary workspace for constructing syntax highlighting sequences.
	self.wip_syntax_colors = {}

	-- Arbitrary table of state intended to help manage syntax highlighting.
	self.syntax_work = {}

	-- Used for word wrapping.
	self.view_x = 0

	-- How much to amplify wheel movement values. Is set in refreshFontParams().
	self.wheel_scroll_x = 1.0
	self.wheel_scroll_y = 1.0

	setmetatable(self, _mt_lc)

	return self
end


function editDisp.newSuperLine()

	local self = {}

	-- Super-lines are basically just an array of sub-lines.

	setmetatable(self, _mt_sup)

	return self
end


-- * / Object creation *


-- * Line container methods *


function _mt_lc:getDocumentHeight()

	-- Assumes the final sub-line is current.
	local last_super = self.super_lines[#self.super_lines]
	local last_sub = last_super[#last_super]

	return last_sub.y + last_sub.h
end


function _mt_lc:getDocumentXBoundaries()

	local x1, x2 = 0, 0

	for i, super_line in ipairs(self.super_lines) do
		for j, sub_line in ipairs(super_line) do
			x1 = math.min(x1, sub_line.x)
			x2 = math.max(x2, sub_line.x + sub_line.w)
		end
	end

	return x1, x2
end


-- @param y Y position, relative to the line container start point.
function _mt_lc:getOffsetsAtY(y)

	local super_lines = self.super_lines

	-- Find super-line and sub-line that are closest to the Y position.
	-- Default to the first sub-line, and progressively select each sub-line which
	-- is at least equal to the input Y position.
	local super_i = 1
	local sub_i = 1

	local sub_one = super_lines[1][1]

	for i, super_line in ipairs(super_lines) do
		for j, sub_line in ipairs(super_line) do
			if y < sub_line.y then
				break

			else
				super_i = i
				sub_i = j
			end
		end
	end

	return super_i, sub_i
end


-- @return Byte, X position and width of the glyph (if applicable).
function _mt_lc:getSubLineInfoAtX(super_i, sub_i, x, split_x)

	local super_lines = self.super_lines
	local font = self.font

	local super_t = super_lines[super_i]
	local sub_t = super_t[sub_i]

	local sub_str = sub_t.str

	-- Temporarily make X relative to start of sub-line.
	x = x - sub_t.x

	local byte, glyph_x, glyph_w = edVis.textInfoAtX(sub_str, font, x, split_x)

	return byte, glyph_x + sub_t.x, glyph_w
end


--- Get the height of a super-line by comparing its first and last sub-lines. The positions must be up to date when calling. Includes lineHeight spacing, but not paragraph spacing.
function _mt_lc:getSuperLineHeight(super_i) -- XXX test

	local super_line = self.super_lines[super_i]
	local sub_first, sub_last = super_line[1], super_line[#super_line]

	return sub_last.y + sub_last.h - sub_first.y
end


function _mt_lc:getSubLineUCharOffsetStart(super_i, sub_i)

	local super_line = self.super_lines[super_i]
	local u_count = 1

	for i = 1, sub_i - 1 do
		u_count = u_count + utf8.len(super_line[i].str)
	end

	return u_count
end


function _mt_lc:getSubLineUCharOffsetEnd(super_i, sub_i)

	local super_line = self.super_lines[super_i]
	local u_count = 0

	for i = 1, sub_i do
		u_count = u_count + utf8.len(super_line[i].str)
	end

	-- End of the super-line: add one more byte past the end.
	if sub_i >= #super_line then
		u_count = u_count + 1
	end

	return u_count
end


function _mt_lc:getSubLineUCharOffsetStartEnd(super_i, sub_i)

	local super_line = self.super_lines[super_i]
	local u_count_1 = 1
	local u_count_2

	for i = 1, sub_i - 1 do
		u_count_1 = u_count_1 + utf8.len(super_line[i].str)
	end
	u_count_2 = u_count_1 + utf8.len(super_line[sub_i].str) - 1

	-- End of the super-line: add one more byte past the end.
	if sub_i >= #super_line then
		u_count_2 = u_count_2 + 1
	end

	return u_count_1, u_count_2
end


--- Update sub-line Y offsets, beginning at the specified super-line index and continuing to the end of the super-lines array.
-- @param super_i The first super-line to check. All previous sub-lines in the container must have up-to-date Y offsets.
function _mt_lc:refreshYOffsets(super_i) 

	local super_lines = self.super_lines
	local y = 0

	-- If starting after super-line #1, assume that the previous sub-line has known-good coordinates.
	if super_i > 1 then
		local super_prev = super_lines[super_i - 1]
		local sub_prev = super_prev[#super_prev]
		y = sub_prev.y + sub_prev.h + self.paragraph_pad
	end

	for i = super_i, #super_lines do
		local super_line = super_lines[i]
		
		for j, sub_line in ipairs(super_line) do
			sub_line.y = y
			y = y + sub_line.h
		end

		y = y + self.paragraph_pad
	end
end


--- Within a line container, update a super-line's contents.
-- @param i_super Index of the super-line. If not the first super-line, then all super-lines from index 1 to this index - 1 must be populated at time of call.
-- @param str The source / input string.
function _mt_lc:updateSuperLine(i_super, str)

	local super_lines = self.super_lines
	local font = self.font

	-- Provision the super-line table.
	local super_line = super_lines[i_super] or editDisp.newSuperLine()
	super_lines[i_super] = super_line

	-- Perform optional modifications on the string.
	local work_str = str

	if self.replace_missing then
		work_str = edVis.replaceMissingGlyphs(work_str, font, "□")
	end

	if self.masked then
		work_str = edCom.getMaskedString(work_str, self.mask_glyph)

	-- Only syntax-colorize unmasked text
	elseif self.fn_colorize and self.generate_colored_text then
		local len = self:fn_colorize(work_str, self.wip_syntax_colors, self.syntax_work)
		-- Trim color table
		for i = #self.wip_syntax_colors, len + 1, -1 do
			self.wip_syntax_colors[i] = nil
		end
	end

	local final_index = 1
	if not self.wrap_mode then
		self:updateSubLine(i_super, 1, work_str, self.wip_syntax_colors, 1)

	else
		local width, wrapped = font:getWrap(work_str, self.view_w)
		local start_code_point = 1

		for i, wrapped_line in ipairs(wrapped) do
			-- Fix an edge case where font:getWrap() drops code points if the glyphs are thinner than wraplimit.
			if i < #wrapped and wrapped_line == "" then
				wrapped_line = "~"
			end
			self:updateSubLine(i_super, i, wrapped_line, self.wip_syntax_colors, start_code_point)

			start_code_point = start_code_point + utf8.len(wrapped_line)
		end
		final_index = #wrapped
	end

	-- Clear any stale sub-lines beyond the last-touched index
	for j = #super_line, final_index + 1, -1 do
		super_line[j] = nil
	end
end


-- Updates the alignment of sub-lines.
function _mt_lc:updateSuperLineAlign(line_1, line_2)

	local super_lines = self.super_lines

	line_1 = line_1 or 1
	line_2 = line_2 or #super_lines

	local align, font, width = self.align, self.font, self.view_w

	for i = line_1, line_2 do
		local super_line = super_lines[i]
		for j, sub_line in ipairs(super_line) do
			updateSubLineHorizontal(sub_line, align, font)
		end
	end
end


--- Update a sub-line's text contents and X, width and height. Does not update Y position: call refreshYOffsets() afterward.
-- @param i_super Super-line index.
-- @param i_sub Sub-line index.
-- @param str The new string to use.
function _mt_lc:updateSubLine(i_super, i_sub, str, syntax_colors, syntax_start)

	local font = self.font

	-- All sub-lines from index 1 to this index - 1 must be populated at time of call.
	local super_line = self.super_lines[i_super]

	-- Get / create sub-line table
	local sub_line = super_line[i_sub] or {}
	super_line[i_sub] = sub_line

	-- Position relative to top-left corner of the text region.
	sub_line.x = 0
	sub_line.y = 0

	-- Cached font:getWidth(self.str)
	sub_line.w = 0

	-- Cached 'math.ceil(font:getHeight() * font:getLineHeight())'
	sub_line.line_height = 0

	-- Normal string display text.
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

		sub_line.colored_text = edVis.stringToColoredText(sub_line.str, sub_line.colored_text, self.text_color, sub_line.syntax_colors)

		-- Debug
		--edVis.printColoredText(sub_line.colored_text)

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

	setmetatable(sub_line, _mt_sub)

	super_line[i_sub] = sub_line

	sub_line.h = math.ceil(font:getHeight() * font:getLineHeight())
	updateSubLineHorizontal(sub_line, self.align, font)
end


function _mt_lc:insertSuperLines(i_super, qty)
	for i = 1, qty do
		table.insert(self.super_lines, i_super + i, editDisp.newSuperLine())
	end
end


function _mt_lc:removeSuperLines(i_super, qty)
	for i = 1, qty do
		table.remove(self.super_lines, i_super)
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

	local super_lines = self.super_lines

	local line_1 = math.max(self.h_line_min, 1)
	local line_2 = math.min(self.h_line_max, #super_lines)

	if line_1 > line_2 then
		return
	end

	-- Get line offsets relative to the display sequence.
	local super_1, sub_1, byte_1, super_2, sub_2, byte_2 = editDisp.getHighlightOffsetsSuperLine(
		self.d_car_super,
		self.d_car_sub,
		self.d_car_byte,
		self.d_h_super,
		self.d_h_sub,
		self.d_h_byte
	)

	-- paint_mode:
	-- 0: Painting a single line
	-- 1: Awaiting top of multiple lines
	-- 2: Handling in-between lines and bottom of multiple lines
	-- 3: Done / fall through to 'not highlighted'
	local paint_mode = 1
	if super_1 == super_2 and sub_1 == sub_2 then
		paint_mode = 0
	end

	for i = line_1, line_2 do
		local super_line = super_lines[i]

		for j, sub_line in ipairs(super_line) do
			-- Single highlighted line
			if paint_mode == 0 and i == super_1 and j == sub_1 then
				dispUpdateHighlight(self, i, j, byte_1, byte_2)

			-- Top of multiple lines
			elseif paint_mode == 1 and i == super_1 and j == sub_1 then
				dispUpdateHighlight(self, i, j, byte_1, #sub_line.str + 2)
				paint_mode = 2

			-- Bottom of multiple lines
			elseif paint_mode == 2 and i == super_2 and j == sub_2 then
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
	for i, super_line in ipairs(self.super_lines) do
		for j, sub_line in ipairs(super_line) do
			sub_line.highlighted = false
			dispUpdateSubLineSyntaxColors(self, sub_line, -1, -1)
		end
	end	
end


function _mt_lc:updateCaretRect()
	--print("disp:updateCaretRect()")

	local font = self.font
	local super_lines = self.super_lines

	local super_line_cur = super_lines[self.d_car_super]
	local sub_line_cur = super_line_cur[self.d_car_sub]

	-- Update cached caret info
	self.caret_box_x, self.caret_box_w = edVis.getCaretXW(sub_line_cur.str, self.d_car_byte, font)

	-- Apply horizontal alignment offsetting to caret
	self.caret_box_x = applyCaretAlignOffset(self.caret_box_x, sub_line_cur.str, self.align, font)

	self.caret_box_y = sub_line_cur.y
	self.caret_box_h = font:getHeight()
end


function _mt_lc:updateFont(font)
	self.font = font
	self.font_height = font:getHeight()
	self.line_height = math.ceil(font:getHeight() * font:getLineHeight())

	self:refreshFontParams()
	-- All display lines need to be updated after calling.
end


-- * / Line container methods *


function _mt_lc:refreshFontParams()

	local font = self.font
	local em_width = font:getWidth("M")
	local line_height = font:getHeight() * font:getLineHeight()

	self.caret_line_width = math.max(1, math.ceil(em_width / 16))
	self.width_line_feed = math.max(1, math.ceil(em_width / 4))

	-- XXX Both of these probably need to be configurable.
	-- XXX I don't have a pointing device with a horizontal scrolling wheel, so I have
	-- no idea if this is a sensible value or not.
	self.wheel_scroll_x = math.ceil(1.0 * em_width)
	self.wheel_scroll_y = math.ceil(1.0 * line_height * 2)

	-- Client should refresh/clamp scrolling and ensure the caret is visible after this function is called.
end


function _mt_lc:resetCaretBlink()
	self.blink_time = self.blink_reset
end


function _mt_lc:updateCaretBlink(dt)

	-- Implement caret blinking
	self.blink_time = self.blink_time + dt
	if self.blink_time > self.blink_on + self.blink_off then
		self.blink_time = math.max(-(self.blink_on + self.blink_off), self.blink_time - (self.blink_on + self.blink_off))
	end
	if self.blink_time < self.blink_off then
		self.show_caret = true
	else
		self.show_caret = false
	end
end


return editDisp
