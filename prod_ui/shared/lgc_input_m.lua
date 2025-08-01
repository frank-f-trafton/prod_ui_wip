--[[
Shared widget logic for multi-line text input.
--]]


local context = select(1, ...)


local lgcInputM = {}


local edCom = context:getLua("shared/line_ed/ed_com")
local edComM = context:getLua("shared/line_ed/m/ed_com_m")
local editActM = context:getLua("shared/line_ed/m/edit_act_m")
local editBindM = context:getLua("shared/line_ed/m/edit_bind_m")
local editCommandM = context:getLua("shared/line_ed/m/edit_command_m")
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editMethodsM = context:getLua("shared/line_ed/m/edit_methods_m")
local editWid = context:getLua("shared/line_ed/edit_wid")
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


-- Widget def configuration.
function lgcInputM.setupDef(def)
	pTable.patch(def, editMethodsM, true)
end


function lgcInputM.setupInstance(self)
	-- How far to offset the line X position depending on the alignment.
	self.LE_align_ox = 0

	-- Ghost text appears when the field is empty.
	-- This is not part of the lineEditor core, and so it is not drawn through
	-- the seqString or displayLine sub-objects.
	self.LE_ghost_text = false

	-- false: use content text alignment.
	-- "left", "center", "right", "justify"
	self.LE_ghost_text_align = false

	-- The first and last visible display paragraphs. Used as boundaries for text rendering.
	-- Update whenever you scroll vertically or modify the text.
	self.LE_vis_para1 = 1
	self.LE_vis_para2 = 1

	-- Caret state
	self.LE_caret_fill = "fill"

	-- The caret rect dimensions for drawing.
	self.LE_caret_x = 0
	self.LE_caret_y = 0
	self.LE_caret_w = 0
	self.LE_caret_h = 0

	self.LE_caret_showing = true
	self.LE_caret_blink_time = 0

	-- XXX: skin or some other config system
	self.LE_caret_blink_reset = -0.5
	self.LE_caret_blink_on = 0.5
	self.LE_caret_blink_off = 0.5

	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.LE_caret_extend_x = 0
	self.LE_caret_extend_y = 0

	-- Position offsets when clicking the mouse.
	-- These are only valid when a mouse action is in progress.
	self.LE_click_line = 1
	self.LE_click_byte = 1

	self.LE_text_batch = uiGraphics.newTextBatch(edCom.dummy_font)

	self.LE = lineEdM.new()

	-- History state.
	self.LE_hist = structHistory.new()
	editFuncM.writeHistoryEntry(self, true)

	-- Enable/disable specific editing actions.
	self.LE_allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.LE_allow_cut = true
	self.LE_allow_copy = true
	self.LE_allow_paste = true
	self.LE_allow_highlight = true -- XXX: Whoops, this is not checked in the mouse action code.

	-- Affects presses of enter/return and the pasting of text that includes line feeds.
	self.LE_allow_line_feed = true

	self.LE_allow_tab = false -- affects single presses of the tab key
	self.LE_allow_untab = false -- affects shift+tab (unindenting)
	self.LE_tabs_to_spaces = true -- affects '\t' in writeText()

	-- When inserting a new line, copies the leading whitespace from the previous line.
	self.LE_auto_indent = false

	-- When true, typing overwrites the current position instead of inserting.
	-- Exception: Replace Mode still inserts characters at the end of a line (so before a line feed character or
	-- the end of the text string).
	self.LE_replace_mode = false

	-- When false, cannot enable Replace Mode.
	self.LE_allow_replace = true

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'textUtil.sanitize()' for options.
	self.LE_bad_input_rule = false

	-- Should be updated when the core dimensions change.
	self.LE_page_jump_steps = 1

	-- Helps with amending vs making new history entries
	self.LE_input_category = false

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.LE_u_chars_max = 5000
end


function lgcInputM.textInputLogic(self, text)
	local LE = self.LE

	if self.LE_allow_input then
		local hist = self.LE_hist

		editWid.resetCaretBlink(self)

		local xcl, xcb, xhl, xhb = LE:getCaretOffsets() -- old offsets

		local suppress_replace = false
		local clear_input_category = false

		if self.LE_replace_mode then
			-- Replace mode should not overwrite line feeds.
			local line = LE.lines[LE.cl]
			if LE.cb > #line then
				suppress_replace = true
			end

			-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
			if xcb < #LE.lines[#LE.lines] + 1 then
				clear_input_category = true
			end
		end

		local written = editFuncM.writeText(self, text, suppress_replace)

		if written then
			editWidM.generalUpdate(self, true, true, true, true, true)

			if clear_input_category then
				self.LE_input_category = false
			end

			if hist.enabled then
				local no_ws = written:find("%S")
				local entry = hist:getEntry()
				local do_advance = true

				if (entry and entry.cl == xcl and entry.cb == xcb)
				and ((self.LE_input_category == "typing" and no_ws) or (self.LE_input_category == "typing-ws"))
				then
					do_advance = false
				end

				if do_advance then
					editFuncM.doctorHistoryCaretOffsets(self, xcl, xcb, xhl, xhb)
				end
				editFuncM.writeHistoryEntry(self, do_advance)
				self.LE_input_category = no_ws and "typing" or "typing-ws"
			end

			return true
		end
	end
end


function lgcInputM.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
	local LE = self.LE

	local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()

	editWid.resetCaretBlink(self)

	-- pop-up menu (undo, etc.)
	if scancode == "application" or (shift_down and scancode == "f10") then
		-- Locate caret in UI space
		local ax, ay = self:getAbsolutePosition()
		local caret_x = ax + self.vp_x - self.scr_x + LE.caret_box_x + self.LE_align_ox
		local caret_y = ay + self.vp_y - self.scr_y + LE.caret_box_y + LE.caret_box_h

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
	local LE = self.LE

	local cl, cb = LE:getCharacterDetailsAtPosition(x, y, split_x)
	LE:moveCaret(cl, cb, clear_highlight, true)
end


local function _clickDragByWord(self, x, y, origin_line, origin_byte)
	local LE = self.LE

	local drag_line, drag_byte = LE:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full words
	local dl1, db1, dl2, db2 = LE:getWordRange(drag_line, drag_byte)
	local cl1, cb1, cl2, cb2 = LE:getWordRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edComM.mergeRanges(dl1, db1, dl2, db2, cl1, cb1, cl2, cb2)

	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		LE:moveCaretAndHighlight(ml1, mb1, ml2, mb2, true)
	else
		LE:moveCaretAndHighlight(ml2, mb2, ml1, mb1, true)
	end
end


local function _clickDragByLine(self, x, y, origin_line, origin_byte)
	local LE = self.LE

	local drag_line, drag_byte = LE:getCharacterDetailsAtPosition(x, y, true)

	-- Expand ranges to cover full (wrapped) lines
	local drag_first, drag_last = LE:getWrappedLineRange(drag_line, drag_byte)
	local click_first, click_last = LE:getWrappedLineRange(origin_line, origin_byte)

	-- Merge the two ranges
	local ml1, mb1, ml2, mb2 = edComM.mergeRanges(
		drag_line, drag_first, drag_line, drag_last,
		origin_line, click_first, origin_line, click_last
	)
	if drag_line < origin_line or (drag_line == origin_line and drag_byte < origin_byte) then
		LE:moveCaretAndHighlight(ml1, mb1, ml2, mb2, true)
	else
		LE:moveCaretAndHighlight(ml2, mb2, ml1, mb1, true)
	end
end


function lgcInputM.mousePressLogic(self, x, y, button, istouch, presses)
	local LE = self.LE

	editWid.resetCaretBlink(self)
	local mx, my = self:getRelativePosition(x, y)

	if button == 1 then
		self.press_busy = "text-drag"

		-- apply offsets
		local msx = mx + self.scr_x - self.LE_align_ox
		local msy = my + self.scr_y

		local core_line, core_byte = LE:getCharacterDetailsAtPosition(msx, msy, true)

		if context.cseq_button == 1 then
			-- Not the same line+byte position as last click: force single-click mode.
			if context.cseq_presses > 1  and (core_line ~= self.LE_click_line or core_byte ~= self.LE_click_byte) then
				context:forceClickSequence(self, button, 1)
				-- XXX Causes 'cseq_presses' to go from 3 to 1. Not a huge deal but worth checking over.
			end

			if context.cseq_presses == 1 then
				local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()
				_caretToXY(self, not shift_down, msx, msy, true)
				--self:scrollGetCaretInBounds() -- Helpful, or distracting?

				self.LE_click_line = LE.cl
				self.LE_click_byte = LE.cb

			elseif context.cseq_presses == 2 then
				self.LE_click_line = LE.cl
				self.LE_click_byte = LE.cb

				-- Highlight group from highlight position to mouse position
				self:highlightCurrentWord()

			elseif context.cseq_presses == 3 then
				self.LE_click_line = LE.cl
				self.LE_click_byte = LE.cb

				--- Highlight sub-lines from highlight position to mouse position
				--LE:highlightCurrentLine()
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
	local LE = self.LE

	local widget_needs_update = false

	editWid.resetCaretBlink(self)

	-- relative mouse position
	local mx, my = self:getRelativePosition(context.mouse_x, context.mouse_y)

	-- ...and with offsets applied
	local s_mx = mx + self.scr_x - self.LE_align_ox
	local s_my = my + self.scr_y

	--print("s_mx", s_mx, "s_my", s_my, "scr_x", self.scr_x, "scr_y", self.scr_y)

	-- Handle drag highlight actions
	if context.cseq_presses == 1 then
		_caretToXY(self, false, s_mx, s_my, true)
		widget_needs_update = true

	elseif context.cseq_presses == 2 then
		_clickDragByWord(self, s_mx, s_my, self.LE_click_line, self.LE_click_byte)
		widget_needs_update = true

	elseif context.cseq_presses == 3 then
		_clickDragByLine(self, s_mx, s_my, self.LE_click_line, self.LE_click_byte)
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


function lgcInputM.draw(self, color_highlight, font_ghost, color_text, font, color_caret)
	local LE = self.LE
	local lines = LE.lines

	-- Highlight rectangles.
	if color_highlight and LE:isHighlighted() then
		love.graphics.setColor(color_highlight)

		for i = self.LE_vis_para1, self.LE_vis_para2 do
			local paragraph = LE.paragraphs[i]
			for j, sub_line in ipairs(paragraph) do
				if sub_line.highlighted then
					love.graphics.rectangle("fill", sub_line.x + sub_line.h_x, sub_line.y + sub_line.h_y, sub_line.h_w, sub_line.h_h)
				end
			end
		end
	end

	-- Ghost text, if applicable.
	-- XXX: center and right ghost text alignment modes aren't working correctly.
	if font_ghost and self.LE_ghost_text and lines:isEmpty() then
		local align = self.LE_ghost_text_align or LE.align

		love.graphics.setFont(font_ghost)

		local gx, gy
		if align == "left" then
			gx, gy = 0, 0

		elseif align == "center" then
			gx, gy = math.floor(-font:getWidth(self.LE_ghost_text) / 2), 0

		elseif align == "right" then
			gx, gy = math.floor(-font:getWidth(self.LE_ghost_text)), 0
		end

		if LE.wrap_mode then
			love.graphics.printf(self.LE_ghost_text, -self.LE_align_ox, 0, self.vp_w, align)

		else
			love.graphics.print(self.LE_ghost_text, gx, gy)
		end
	end

	-- Main text.
	love.graphics.setColor(color_text)

	if self.LE_text_batch then
		love.graphics.draw(self.LE_text_batch)
	else
		love.graphics.setFont(font)

		for i = self.LE_vis_para1, self.LE_vis_para2 do
			local paragraph = LE.paragraphs[i]
			for j, sub_line in ipairs(paragraph) do
				love.graphics.print(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
			end
		end
	end

	-- Caret.
	if color_caret and self.LE_caret_showing and self:hasAnyThimble() then
		love.graphics.setColor(color_caret)
		love.graphics.rectangle(self.LE_caret_fill, self.LE_caret_x, self.LE_caret_y, self.LE_caret_w, self.LE_caret_h)
	end
end


function lgcInputM.cb_action(self, item_t)
	return editWrapM.wrapAction(self, item_t.func)
end


-- Configuration functions for pop-up menu items.


function lgcInputM.configItem_undo(item, client)
	item.selectable = true
	item.actionable = (client.LE_hist.pos > 1)
end


function lgcInputM.configItem_redo(item, client)
	item.selectable = true
	item.actionable = (client.LE_hist.pos < #client.LE_hist.ledger)
end


function lgcInputM.configItem_cutCopyDelete(item, client)
	item.selectable = true
	item.actionable = client.LE:isHighlighted()
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
	item.actionable = (not client.LE.lines:isEmpty())
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
