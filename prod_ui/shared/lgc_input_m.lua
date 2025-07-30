--[[
Shared widget logic for multi-line text input.
--]]


local context = select(1, ...)


local lgcInputM = {}


local edComM = context:getLua("shared/line_ed/m/ed_com_m")
local editActM = context:getLua("shared/line_ed/m/edit_act_m")
local editBindM = context:getLua("shared/line_ed/m/edit_bind_m")
local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editMethodsM = context:getLua("shared/line_ed/m/edit_methods_m")
local editWidM = context:getLua("shared/line_ed/m/edit_wid_m")
local editWrapM = context:getLua("shared/line_ed/m/edit_wrap_m")
local lgcMenu = context:getLua("shared/lgc_menu")
local lgcScroll = context:getLua("shared/lgc_scroll")
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local structHistory = context:getLua("shared/struct_history")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
--local widShared = context:getLua("core/wid_shared")


-- LÖVE 12 compatibility
local love_major, love_minor = love.getVersion()


local _dummy_font = love.graphics.newFont(12)


-- Widget def configuration.
function lgcInputM.setupDef(def)
	pTable.patch(def, editMethodsM, true)
end


function lgcInputM.setupInstance(self)
	-- How far to offset the line X position depending on the alignment.
	self.align_offset = 0

	-- Ghost text appears when the field is empty.
	-- This is not part of the lineEditor core, and so it is not drawn through
	-- the seqString or displayLine sub-objects.
	self.ghost_text = false

	-- false: use content text alignment.
	-- "left", "center", "right", "justify"
	self.ghost_text_align = false

	-- The first and last visible display paragraphs. Used as boundaries for text rendering.
	-- Update whenever you scroll vertically or modify the text.
	self.vis_para_top = 1
	self.vis_para_bot = 1

	-- Caret state
	self.caret_fill = "fill"

	-- The caret rect dimensions for drawing.
	self.caret_x = 0
	self.caret_y = 0
	self.caret_w = 0
	self.caret_h = 0

	self.caret_is_showing = true
	self.caret_blink_time = 0

	-- XXX: skin or some other config system
	self.caret_blink_reset = -0.5
	self.caret_blink_on = 0.5
	self.caret_blink_off = 0.5

	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.caret_extend_x = 0
	self.caret_extend_y = 0

	-- Position offsets when clicking the mouse.
	-- These are only valid when a mouse action is in progress.
	self.click_line = 1
	self.click_byte = 1

	self.text_object = uiGraphics.newTextBatch(_dummy_font)

	self.line_ed = lineEdM.new()

	-- History state.
	self.hist = structHistory.new()
	editFuncM.writeHistoryEntry(self, true)

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


function lgcInputM.textInputLogic(self, text)
	local line_ed = self.line_ed

	if self.allow_input then
		local hist = self.hist

		editWidM.resetCaretBlink(self)

		local xcl, xcb, xhl, xhb = line_ed:getCaretOffsets() -- old offsets

		local suppress_replace = false
		if self.replace_mode then
			-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
			if line_ed.cb < #line_ed.lines[#line_ed.lines] + 1 then
				self.input_category = false
			end

			-- Replace mode should not overwrite line feeds.
			local line = line_ed.lines[line_ed.cl]
			if line_ed.cb > #line then
				suppress_replace = true
			end
		end

		local written = editFuncM.writeText(self, text, suppress_replace)

		editWidM.generalUpdate(self, true, true, true, true, true)

		if written then
			local no_ws = written:find("%S")
			local entry = hist:getEntry()
			local do_advance = true

			if (entry and entry.cl == xcl and entry.cb == xcb)
			and ((self.input_category == "typing" and no_ws) or (self.input_category == "typing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editFuncM.doctorHistoryCaretOffsets(self, xcl, xcb, xhl, xhb)
			end
			editFuncM.writeHistoryEntry(self, do_advance)
			self.input_category = no_ws and "typing" or "typing-ws"
		end
	end
end


function lgcInputM.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
	local line_ed = self.line_ed

	local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()

	editWidM.resetCaretBlink(self)

	-- pop-up menu (undo, etc.)
	if scancode == "application" or (shift_down and scancode == "f10") then
		-- Locate caret in UI space
		local ax, ay = self:getAbsolutePosition()
		local caret_x = ax + self.vp_x - self.scr_x + line_ed.caret_box_x + self.align_offset
		local caret_y = ay + self.vp_y - self.scr_y + line_ed.caret_box_y + line_ed.caret_box_h

		lgcMenu.widgetConfigureMenuItems(self, self.pop_up_def)

		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		local pop_up = lgcWimp.makePopUpMenu(self, self.pop_up_def, caret_x, caret_y)
		pop_up:tryTakeThimble2()

		-- Halt propagation
		return true
	end

	-- (LÖVE 12) if this key should behave differently when NumLock is disabled, swap out the scancode and key constant.
	if love_major >= 12 and keyMgr.scan_numlock[scancode] and not love.keyboard.isModifierActive("numlock") then
		scancode = keyMgr.scan_numlock[scancode]
		key = love.keyboard.getKeyFromScancode(scancode)
	end

	local bound_func = editBindM[hot_scan] or editBindM[hot_key]

	if bound_func then
		return editWrapM.wrapAction(self, bound_func)
	end
end


local function _caretToXY(self, clear_highlight, x, y, split_x)
	local line_ed = self.line_ed

	local cl, cb = line_ed:getCharacterDetailsAtPosition(x, y, split_x)
	line_ed:moveCaret(cl, cb, clear_highlight, true)
end


local function _clickDragByWord(self, x, y, origin_line, origin_byte)
	local line_ed = self.line_ed

	local drag_line, drag_byte = line_ed:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full words
	local dl1, db1, dl2, db2 = line_ed:getWordRange(drag_line, drag_byte)
	local cl1, cb1, cl2, cb2 = line_ed:getWordRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edComM.mergeRanges(dl1, db1, dl2, db2, cl1, cb1, cl2, cb2)

	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		line_ed:moveCaretAndHighlight(ml1, mb1, ml2, mb2, true)
	else
		line_ed:moveCaretAndHighlight(ml2, mb2, ml1, mb1, true)
	end
end


local function _clickDragByLine(self, x, y, origin_line, origin_byte)
	local line_ed = self.line_ed

	local drag_line, drag_byte = line_ed:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full (wrapped) lines
	local drag_first, drag_last = line_ed:getWrappedLineRange(drag_line, drag_byte)
	local click_first, click_last = line_ed:getWrappedLineRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edComM.mergeRanges(
		drag_line, drag_first, drag_line, drag_last,
		origin_line, click_first, origin_line, click_last
	)
	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		line_ed:moveCaretAndHighlight(ml1, mb1, ml2, mb2, true)
	else
		line_ed:moveCaretAndHighlight(ml2, mb2, ml1, mb1, true)
	end
end


function lgcInputM.mousePressLogic(self, x, y, button, istouch, presses)
	local line_ed = self.line_ed

	editWidM.resetCaretBlink(self)
	local mx, my = self:getRelativePosition(x, y)

	if button == 1 then
		self.press_busy = "text-drag"

		-- apply offsets
		local msx = mx + self.scr_x - self.align_offset
		local msy = my + self.scr_y

		local core_line, core_byte = line_ed:getCharacterDetailsAtPosition(msx, msy, true)

		if context.cseq_button == 1 then
			-- Not the same line+byte position as last click: force single-click mode.
			if context.cseq_presses > 1  and (core_line ~= self.click_line or core_byte ~= self.click_byte) then
				context:forceClickSequence(self, button, 1)
				-- XXX Causes 'cseq_presses' to go from 3 to 1. Not a huge deal but worth checking over.
			end

			if context.cseq_presses == 1 then
				local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()
				_caretToXY(self, not shift_down, msx, msy, true)
				--self:scrollGetCaretInBounds() -- Helpful, or distracting?

				self.click_line = line_ed.cl
				self.click_byte = line_ed.cb

			elseif context.cseq_presses == 2 then
				self.click_line = line_ed.cl
				self.click_byte = line_ed.cb

				-- Highlight group from highlight position to mouse position
				self:highlightCurrentWord()

			elseif context.cseq_presses == 3 then
				self.click_line = line_ed.cl
				self.click_byte = line_ed.cb

				--- Highlight sub-lines from highlight position to mouse position
				--line_ed:highlightCurrentLine()
				self:highlightCurrentWrappedLine()
			end
		end

	elseif button == 2 then
		lgcMenu.widgetConfigureMenuItems(self, self.pop_up_def)

		local root = self:getRootWidget()

		--print("text_box: thimble1, thimble2", self.context.thimble1, self.context.thimble2)
		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		local pop_up = lgcWimp.makePopUpMenu(self, self.pop_up_def, x, y)
		root:sendEvent("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

		pop_up:tryTakeThimble2()

		-- Halt propagation
		return true
	end
end


--- Updates selection based on the position of the mouse and the number of repeat mouse-clicks.
function lgcInputM.mouseDragLogic(self)
	local context = self.context
	local line_ed = self.line_ed

	local widget_needs_update = false

	editWidM.resetCaretBlink(self)

	-- relative mouse position
	local mx, my = self:getRelativePosition(context.mouse_x, context.mouse_y)

	-- ...and with offsets applied
	local s_mx = mx + self.scr_x - self.align_offset
	local s_my = my + self.scr_y

	--print("s_mx", s_mx, "s_my", s_my, "scr_x", self.scr_x, "scr_y", self.scr_y)

	-- Handle drag highlight actions
	if context.cseq_presses == 1 then
		_caretToXY(self, false, s_mx, s_my, true)
		widget_needs_update = true

	elseif context.cseq_presses == 2 then
		_clickDragByWord(self, s_mx, s_my, self.click_line, self.click_byte)
		widget_needs_update = true

	elseif context.cseq_presses == 3 then
		_clickDragByLine(self, s_mx, s_my, self.click_line, self.click_byte)
		widget_needs_update = true
	end

	return widget_needs_update
end


function lgcInputM.mouseWheelLogic(self, x, y)
	local wheel_scale = self.context.settings.wimp.navigation.mouse_wheel_move_size_v

	self.scr_tx = self.scr_tx - x * wheel_scale
	self.scr_ty = self.scr_ty - y * wheel_scale
	-- XXX add support for non-animated, immediate scroll-to

	self:scrollClampViewport()
	lgcScroll.updateScrollBarShapes(self)
end


function lgcInputM.cb_action(self, item_t)
	return editWrapM.wrapAction(self, item_t.func)
end


-- Configuration functions for pop-up menu items.


function lgcInputM.configItem_undo(item, client)
	item.selectable = true
	item.actionable = (client.hist.pos > 1)
end


function lgcInputM.configItem_redo(item, client)
	item.selectable = true
	item.actionable = (client.hist.pos < #client.hist.ledger)
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
