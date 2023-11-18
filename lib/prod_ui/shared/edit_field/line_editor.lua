-- To load: local lib = context:getLua("shared/lib")


-- LineEditor core object. Provides the basic guts of a text input field.


local context = select(1, ...)


local lineEditor = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local edCom = context:getLua("shared/edit_field/ed_com")
local editDisp = context:getLua("shared/edit_field/edit_disp")
local editHist = context:getLua("shared/edit_field/edit_hist")
local seqString = require(context.conf.prod_ui_req .. "logic.struct.seq_string")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


lineEditor.code_groups = context:getLua("shared/edit_field/code_groups")
local code_groups = lineEditor.code_groups


local _mt_line_ed = {}
_mt_line_ed.__index = _mt_line_ed


-- * Public Functions *


--- Creates a new Line Editor object.
-- @return the edit_field table.
function lineEditor.new(font)

	if not font then
		error("missing argument #1 (font) for new LineEditor object.")
	end

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

	-- History container
	local hist = editHist.new()
	self.hist = hist
	hist:writeEntry(true, self.lines, self.car_line, self.car_byte, self.h_line, self.h_byte)

	-- Cached display details for rendering text, highlights, and the caret.
	-- The LineEditor is responsible for keeping this in sync with the internal state.
	self.disp = editDisp.newLineContainer(font)

	self.disp:setHighlightDirtyRange(self.car_line, self.h_line)

	-- X position hint when stepping up or down.
	self.vertical_x_hint = 0

	-- Begin control state

	-- Enable/disable specific editing actions
	self.allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.allow_cut = true
	self.allow_copy = true
	self.allow_paste = true
	self.allow_highlight = true

	self.allow_enter = true -- affects single presses of enter/return
	self.allow_line_feed = true -- affects '\n' in writeText()
	self.allow_tab = false -- affects single presses of the tab key
	self.allow_untab = false -- affects shift+tab (unindenting)
	self.tabs_to_spaces = true -- affects '\t' in writeText()

	-- When true, typing overwrites the current position instead of inserting.
	-- Exception: Replace Mode still inserts characters at the end of a line (so before a line feed character or
	-- the end of the text string).
	self.replace_mode = false

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'edCom.validateEncoding()' for options.
	self.bad_input_rule = false

	-- Should be updated with core dimensions change.
	self.page_jump_steps = 1

	-- Helps with amending vs making new history entries
	self.input_category = false

	-- Cached copy of 'lines' length in Unicode code points.
	self.u_chars = self.lines:uLen()

	-- Max number of Unicode characters (not bytes) permitted in the field.
	--self.u_chars_max = 80
	self.u_chars_max = 5000

	-- End control state

	setmetatable(self, _mt_line_ed)

	self.disp:refreshFontParams()
	self:displaySyncAll()

	return self
end


-- * / Public Functions *


-- * Support Methods *


function _mt_line_ed:getCaretOffsets() -- XXX Stay
	return self.car_line, self.car_byte, self.h_line, self.h_byte
end


function _mt_line_ed:getHighlightOffsets() -- XXX Stay
	return edCom.sortOffsets(self.car_line, self.car_byte, self.h_line, self.h_byte)
end


function _mt_line_ed:updateVertPosHint() -- XXX Stay

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
function _mt_line_ed:getCharacterDetailsAtPosition(x, y, split_x) -- XXX Stay

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
	local u_count = edCom.displaytoUCharCount(paragraph, sub_i, byte)

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


function lineEditor.huntWordBoundary(lines, line_n, byte_n, dir, hit_non_ws, first_group, stop_on_line_feed) -- XXX stay or move to util module

	--print("huntWordBoundary", "dir", dir, "hit_non_ws", hit_non_ws, "first_group", first_group, "stop_on_line_feed", stop_on_line_feed)

	-- If 'hit_non_ws' is true, this function skips over initial whitespace. 

	while true do
		--print("LOOP: huntWordBoundary")
		local line_p, byte_p, peeked = lines:offsetStep(dir, line_n, byte_n)
		--print("line_p", line_p, "byte_p", byte_p, "peeked", peeked)
		--print("^", not peeked and "nil" or peeked == 0x0a and "\\n" or utf8.char(peeked))

		local group = code_groups[peeked]

		-- Beginning or end of document
		if peeked == nil then
			--print("break: peeked == nil")
			if dir == 1 then
				line_n = #lines
				byte_n = #lines[#lines] + 1

			else
				line_n = 1
				byte_n = 1
			end

			break

		-- Hit line feed and instructed to stop, or we're past the initial whitespace and encountered
		-- our first group mismatch
		elseif (stop_on_line_feed and peeked == 0x0a) or (hit_non_ws and group ~= first_group) then
			--print("break: hit_non_ws and group ~= first_group")
			--print("hit_non_ws", hit_non_ws, "group", group, "first_group", first_group, "peeked: ", peeked)
			-- Correct right-dir offsets
			if dir == 1 then
				line_n = line_p
				byte_n = byte_p
			end

			break

		elseif group ~= "whitespace" then
			hit_non_ws = true
			first_group = code_groups[peeked] -- nil means "content" group
		end

		line_n, byte_n = line_p, byte_p
	end

	--print("return line_n", line_n, "byte_n", byte_n)

	return line_n, byte_n
end


function _mt_line_ed:updateDispHighlightRange() -- XXX Stay

	local disp = self.disp

	disp:updateHighlightDirtyRange(self.car_line, self.h_line)
	disp:updateHighlights()
	disp:setHighlightDirtyRange(self.car_line, self.h_line)
end


function _mt_line_ed:getWordRange(line_n, byte_n) -- XXX Stay

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
		line_left, byte_left = lineEditor.huntWordBoundary(lines, line_n, byte_n, -1, true, first_group, true)
		line_right, byte_right = lineEditor.huntWordBoundary(lines, line_n, byte_n, 1, true, first_group, true)
	end

	--print("line+byte left, line+byte right", line_left, byte_left, line_right, byte_right)

	return line_left, byte_left, line_right, byte_right	
end


function _mt_line_ed:getWrappedLineRange(line_n, byte_n) -- XXX Stay

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
	local d_byte, d_sub = editDisp.coreToDisplayOffsets(#line_str, byte_n, disp.paragraphs[d_para])

	-- Get first, last uChar offsets
	local u_count_1, u_count_2 = disp:getSubLineUCharOffsetStartEnd(d_para, d_sub)

	-- Convert soft-wrap code point counts in disp to byte offsets in the core/source string
	local byte_start = utf8.offset(lines[line_n], u_count_1)
	local byte_end = utf8.offset(lines[line_n], u_count_2)

	return byte_start, byte_end
end


function _mt_line_ed:highlightCleanup() -- XXX Stay
	if self:isHighlighted() then
		self:clearHighlight()
	end
end


--- Insert a string at the caret position.
-- @param text The string to insert.
-- @return Nothing.
function _mt_line_ed:insertText(text) -- XXX Stay

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
function _mt_line_ed:deleteText(copy_deleted, line_1, byte_1, line_2, byte_2) -- XXX Stay: uses line+byte offsets

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
		if string.find(self.lines[line_n], "%S", math.max(1, self.car_byte - 1)) then
			self.car_byte = 1

		else
			self.car_byte = self.car_byte + offset
		end
	end

	if self.h_line == line_n then
		if string.find(self.lines[line_n], "%S", math.max(1, self.h_byte - 1)) then
			self.h_byte = 1

		else
			self.h_byte = self.h_byte + offset
		end
	end
end


function _mt_line_ed:indent(line_n)

	self.lines:add("\t", line_n, 1)

	self.u_chars = self.u_chars + 1

	fixCaretAfterIndent(self, line_n, 1)

	self:displaySyncDeletion(line_n, line_n)
	self:displaySyncCaretOffsets()

	self:updateVertPosHint()
end


function _mt_line_ed:unindent(line_n)

	local line = self.lines[line_n]

	local offset

	if string.sub(line, 1, 1) == "\t" then
		print("line_n", line_n, "tabs codepath")
		offset = 1
		self.lines:delete(line_n, 1, line_n, 1)

	else
		print("line_n", line_n, "spaces codepath")
		local space1, space2 = string.find(line, "^[\x20]+") -- (0x20 == space)
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
end


--- Returns if the field currently has a highlighted section (not whether highlighting itself is currently active.)
function _mt_line_ed:isHighlighted() -- XXX Stay
	return not (self.h_line == self.car_line and self.h_byte == self.car_byte)
end


function _mt_line_ed:clearHighlight() -- XXX Stay

	self.h_line = self.car_line
	self.h_byte = self.car_byte

	self:displaySyncCaretOffsets()
	self:updateDispHighlightRange()
end


function _mt_line_ed:caretToLineAndByte(clear_highlight, line_n, byte_n) -- XXX Stay
	-- XXX Maybe write an equivalent client method for jumping to a line and/or uChar offset.

	line_n = math.max(1, math.min(line_n, #self.lines))
	local line = self.lines[line_n]
	byte_n = math.max(1, math.min(byte_n, #line + 1))
	local line = self.lines[line_n]

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


function _mt_line_ed:caretAndHighlightToLineAndByte(car_line_n, car_byte_n, h_line_n, h_byte_n) -- XXX Stay
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


-- * / Caret and highlight manipulation *


-- * Core-to-display synchronization *


--- Update the display container offsets to reflect the current core offsets. Also update the caret rectangle as stored in 'disp'. The display text must be current at time of call.
function _mt_line_ed:displaySyncCaretOffsets() -- XXX Stay

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
	disp.d_car_byte, disp.d_car_sub = editDisp.coreToDisplayOffsets(#car_str, self.car_byte, paragraphs[disp.d_car_para])

	disp.d_h_para = self.h_line
	disp.d_h_byte, disp.d_h_sub = editDisp.coreToDisplayOffsets(#h_str, self.h_byte, paragraphs[disp.d_h_para])

	disp:updateCaretRect()
end


function _mt_line_ed:displaySyncInsertion(line_1, line_2) -- XXX integrate into insertText directly

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


function _mt_line_ed:displaySyncDeletion(line_1, line_2) -- XXX integrate into deleteText directly

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


function _mt_line_ed:displaySyncAll(line_i) -- XXX Stay

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


function _mt_line_ed:displaySyncAlign(line_i) -- XXX Stay

	local disp = self.disp
	line_i = line_i or 1

	disp:updateParagraphAlign(line_i)
	self:updateVertPosHint()
end


-- * / Support Methods *


return lineEditor

