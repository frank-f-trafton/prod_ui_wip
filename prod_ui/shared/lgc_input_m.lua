--[[
Shared widget logic for multi-line text input.
--]]


local context = select(1, ...)


local lgcInputM = {}


local editActM = context:getLua("shared/line_ed/m/edit_act_m")
local editMethodsM = context:getLua("shared/line_ed/m/edit_methods_m")
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local widShared = context:getLua("core/wid_shared")


local _dummy_font = love.graphics.newFont(12)


-- Widget def configuration.
function lgcInputM.setupDef(def)
	pTable.patch(def, editMethodsM, true)
end


function lgcInputM.setupInstance(self)
	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.caret_extend_x = 0
	self.caret_extend_y = 0

	-- How far to offset the line X position depending on the alignment.
	self.align_offset = 0

	-- Ghost text appears when the field is empty.
	-- This is not part of the lineEditor core, and so it is not drawn through
	-- the seqString or displayLine sub-objects, and is not affected by glyph masking.
	self.ghost_text = false

	-- false: use content text alignment.
	-- "left", "center", "right", "justify"
	self.ghost_text_align = false

	-- The first and last visible display paragraphs. Used as boundaries for text rendering.
	-- Update whenever you scroll vertically or modify the text.
	self.vis_para_top = 1
	self.vis_para_bot = 1

	self.caret_fill = "fill"

	-- The caret rect dimensions for drawing.
	self.caret_x = 0
	self.caret_y = 0
	self.caret_w = 0
	self.caret_h = 0

	-- Tick this whenever something related to the text box needs to be cached again.
	-- lineEditor itself should immediately apply its own state changes.
	self.update_flag = true

	-- Used to update viewport scrolling as a result of dragging the mouse in update().
	self.mouse_drag_x = 0
	self.mouse_drag_y = 0

	-- Position offsets when clicking the mouse.
	-- These are only valid when a mouse action is in progress.
	self.click_line = 1
	self.click_byte = 1

	self.text_object = uiGraphics.newTextBatch(_dummy_font)

	self.line_ed = lineEdM.new()

	-- Enable/disable specific editing actions.
	self.allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.allow_cut = true
	self.allow_copy = true
	self.allow_paste = true
	self.allow_highlight = true -- XXX: Whoops, this is not checked in the mouse action code.

	-- Affects presses of enter/return and the pasting of text that includes line feeds.
	self.allow_line_feed = true

	self.allow_tab = false -- affects single presses of the tab key
	self.allow_untab = false -- affects shift+tab (unindenting)
	self.tabs_to_spaces = true -- affects '\t' in writeText()

	-- When inserting a new line, copies the leading whitespace from the previous line.
	self.auto_indent = false

	-- When true, typing overwrites the current position instead of inserting.
	-- Exception: Replace Mode still inserts characters at the end of a line (so before a line feed character or
	-- the end of the text string).
	self.replace_mode = false

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'textUtil.sanitize()' for options.
	self.bad_input_rule = false

	-- Should be updated when the core dimensions change.
	self.page_jump_steps = 1

	-- Helps with amending vs making new history entries
	self.input_category = false

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.u_chars_max = 5000
end


--- Call after changing alignment, then update the alignment of all sub-lines.
function lgcInputM.updateAlignOffset(self)
	local align = self.line_ed.align

	if align == "left" then
		self.align_offset = 0

	elseif align == "center" then
		self.align_offset = (self.doc_w < self.vp_w) and math.floor(0.5 + self.vp_w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.align_offset = (self.doc_w < self.vp_w) and self.vp_w or self.doc_w
	end
end


function lgcInputM.method_scrollGetCaretInBounds(self, immediate)
	local line_ed = self.line_ed

	-- get the extended caret rectangle
	local car_x1 = self.align_offset + line_ed.caret_box_x - self.caret_extend_x
	local car_y1 = line_ed.caret_box_y - self.caret_extend_y
	local car_x2 = self.align_offset + line_ed.caret_box_x + line_ed.caret_box_w + self.caret_extend_x
	local car_y2 = line_ed.caret_box_y + line_ed.caret_box_h + self.caret_extend_y

	widShared.scrollRectInBounds(self, car_x1, car_y1, car_x2, car_y2, immediate)
end


function lgcInputM.method_updateDocumentDimensions(self)
	local line_ed = self.line_ed

	line_ed.view_w = self.vp_w

	self.doc_h = self.line_ed:dispGetDocumentHeight()

	local x1, x2 = self.line_ed:dispGetDocumentXBoundaries()
	self.doc_w = (x2 - x1)

	lgcInputM.updateAlignOffset(self)
end


function lgcInputM.updatePageJumpSteps(self, font)
	self.page_jump_steps = math.max(1, math.floor(self.vp_h / (font:getHeight() * font:getLineHeight())))
end


--- Updates selection based on the position of the mouse and the number of repeat mouse-clicks.
function lgcInputM.mouseDragLogic(self)
	local context = self.context
	local line_ed = self.line_ed

	local widget_needs_update = false

	line_ed:dispResetCaretBlink()

	-- Relative mouse position relative to viewport #1.
	local ax, ay = self:getAbsolutePosition()
	local mx, my = context.mouse_x - ax - self.vp_x, context.mouse_y - ay - self.vp_y

	-- ...And with scroll offsets applied.
	local s_mx = mx + self.scr_x - self.align_offset
	local s_my = my + self.scr_y

	--print("s_mx", s_mx, "s_my", s_my, "scr_x", self.scr_x, "scr_y", self.scr_y)

	-- Handle drag highlight actions
	if context.cseq_presses == 1 then
		self:caretToXY(false, s_mx, s_my, true)
		widget_needs_update = true

	elseif context.cseq_presses == 2 then
		self:clickDragByWord(s_mx, s_my, self.click_line, self.click_byte)
		widget_needs_update = true

	elseif context.cseq_presses == 3 then
		self:clickDragByLine(s_mx, s_my, self.click_line, self.click_byte)
		widget_needs_update = true
	end

	-- Amount to drag for the update() callback (to be scaled down and multiplied by dt).
	self.mouse_drag_x = (mx < 0) and mx or (mx >= self.vp_w) and mx - self.vp_w or 0
	self.mouse_drag_y = (my < 0) and my or (my >= self.vp_h) and my - self.vp_h or 0

	return widget_needs_update
end


function lgcInputM.cb_action(self, item_t)
	local ok, update_viewport, caret_in_view, write_history = self:executeBoundAction(item_t.func)
	if ok then
		self.update_flag = true
	end

	self:updateDocumentDimensions(self)
	self:scrollGetCaretInBounds(true)
end


-- Configuration functions for pop-up menu items.


function lgcInputM.configItem_undo(item, client)
	item.selectable = true
	item.actionable = (client.line_ed.hist.pos > 1)
end


function lgcInputM.configItem_redo(item, client)
	item.selectable = true
	item.actionable = (client.line_ed.hist.pos < #client.line_ed.hist.ledger)
end


function lgcInputM.configItem_cutCopyDelete(item, client)
	item.selectable = true
	item.actionable = client.line_ed:isHighlighted()
end


function lgcInputM.configItem_paste(item, client)
	item.selectable = true

	-- XXX: There is an SDL function to check if the clipboard has text: https://wiki.libsdl.org/SDL_HasClipboardText
	-- I tested it here: https://github.com/rabbitboots/love/tree/12.0-development-clipboard/src/modules/system
	-- (Search 'hasclipboard' in src/modules/system.)
	-- But the SDL function didn't seem to be 100% reliable when I looked at it (and I don't recall when that
	-- was). Have to follow up on it.

	-- Something like this:
	-- item.actionable = love.system.hasClipboardText()

	item.actionable = true
end


function lgcInputM.configItem_selectAll(item, client)
	item.selectable = true
	item.actionable = (not client.line_ed.lines:isEmpty())
end


-- The default pop-up menu definition.
-- [XXX 17] Add key mnemonics and shortcuts for text box pop-up menu
lgcInputM.pop_up_def = {
	{
		type = "command",
		text = "Undo",
		callback = lgcInputM.cb_action,
		func = editActM.undo,
		config = lgcInputM.configItem_undo,
	}, {
		type = "command",
		text = "Redo",
		callback = lgcInputM.cb_action,
		func = editActM.redo,
		config = lgcInputM.configItem_redo,
	},
	{type="separator"},
	{
		type = "command",
		text = "Cut",
		callback = lgcInputM.cb_action,
		func = editActM.cut,
		config = lgcInputM.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Copy",
		callback = lgcInputM.cb_action,
		func = editActM.copy,
		config = lgcInputM.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Paste",
		callback = lgcInputM.cb_action,
		func = editActM.paste,
		config = lgcInputM.configItem_paste,
	}, {
		type = "command",
		text = "Delete",
		callback = lgcInputM.cb_action,
		func = editActM.deleteHighlighted,
		config = lgcInputM.configItem_cutCopyDelete,
	},
	{type="separator"},
	{
		type = "command",
		text = "Select All",
		callback = lgcInputM.cb_action,
		func = editActM.selectAll,
		config = lgcInputM.configItem_selectAll,
	},
}


return lgcInputM