--[[
Shared widget logic for single-line text input.

Widgets using this system are not compatible with the following callbacks:

* uiCall_thimbleAction: interferes with typing space bar and enter.
Instead, check for enter (or space) in the widget's 'uiCall_keyPressed' callback.

Example:
----
if (scancode == "return" or scancode == "kpenter") and self:wid_action() then
	return true
else
	return lgcInputS.keyPressLogic(self, key, scancode, isrepeat)
end
----

* uiCall_thimbleAction2: interferes with the pop-up menu (undo, etc.)
--]]


local context = select(1, ...)


local lgcInputS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local editActS = context:getLua("shared/line_ed/s/edit_act_s")
local editBindS = context:getLua("shared/line_ed/s/edit_bind_s")
local edCom = context:getLua("shared/line_ed/ed_com")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local editWrapS = context:getLua("shared/line_ed/s/edit_wrap_s")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcMenu = context:getLua("shared/lgc_menu")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local structHistory = context:getLua("shared/struct_history")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = context:getLua("core/wid_shared")


-- LÖVE 12 compatibility.
local love_major, love_minor = love.getVersion()


-- Widget def configuration.
function lgcInputS.setupDef(def)
	pTable.patch(def, editMethodsS, true)
end


function lgcInputS.setupInstance(self)
	-- When true, typing overwrites the current position instead of inserting.
	self.LE_replace_mode = false

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'textUtil.sanitize()' for options.
	self.LE_bad_input_rule = false

	-- Enable/disable specific editing actions.
	self.LE_allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.LE_allow_cut = true
	self.LE_allow_copy = true
	self.LE_allow_paste = true
	self.LE_allow_highlight = true

	-- Allows '\n' as text input (including pasting from the clipboard).
	-- Single-line input treats line feeds like any other character. For example, 'home' and 'end' will not
	-- stop at line feeds.
	-- In the external display string, line feed code points (0xa) are replaced with U+23CE (⏎).
	self.LE_allow_line_feed = false

	-- Allows typing a line feed by pressing enter/return. `self.LE_allow_line_feed` must be true.
	-- Note that this may override other uses of enter/return in the owning widget.
	self.LE_allow_enter_line_feed = false

	self.LE_allow_tab = false -- affects single presses of the tab key
	self.LE_allow_untab = false -- affects shift+tab (unindenting)
	self.LE_tabs_to_spaces = false -- affects '\t' in writeText()

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.LE_u_chars_max = math.huge

	-- Helps with amending vs making new history entries.
	self.LE_input_category = false

	-- When these fields are true, the widget should…
	-- * Select all text upon receiving the thimble
	self.LE_select_all_on_thimble1_take = false -- TODO: add to multi-line code

	-- * Deselect all text upon releasing the thimble (the caret is moved to the first position).
	self.LE_deselect_all_on_thimble1_release = false -- TODO: add to multi-line code

	-- * Clear history when deselected
	self.LE_clear_history_on_deselect = false -- TODO: add to multi-line code

	-- * Clear the input category when deselected (forcing a new history entry to be made upon the
	-- next user text input event). ('LE_clear_history_on_deselect' also does this.)
	self.LE_clear_input_category_on_deselect = true

	-- Caret position and dimensions. Based on 'LE.caret_box_*'.
	self.LE_caret_x = 0
	self.LE_caret_y = 0
	self.LE_caret_w = 0
	self.LE_caret_h = 0

	self.LE_caret_fill = "line"

	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.LE_caret_extend_x = 0

	-- Position offset when clicking the mouse.
	-- This is only valid when a mouse action is in progress.
	self.LE_click_byte = 1

	-- How far to offset the line X position depending on the alignment.
	self.LE_align_ox = 0

	-- string: display this text when the input box is empty.
	-- false: disabled.
	self.LE_ghost_text = false

	-- false: use content text alignment.
	-- "left", "center", "right", "justify"
	self.LE_ghost_text_align = false

	self.LE_caret_showing = true
	self.LE_caret_blink_time = 0

	-- XXX: skin or some other config system
	self.LE_caret_blink_reset = -0.5
	self.LE_caret_blink_on = 0.5
	self.LE_caret_blink_off = 0.5

	self.LE_text_batch = uiGraphics.newTextBatch(edCom.dummy_font)

	--[[
	'self.fn_check': a function that can reject changes made to the text.
	* Arguments: self (the widget)
	* Returns: false/nil if the new text should be backed out, any other value otherwise.
	--]]

	self.LE = lineEdS.new()

	-- History state.
	self.LE_hist = structHistory.new()
	editFuncS.writeHistoryEntry(self, true)
end


-- @return true if the input was accepted, false if it was rejected or input is not allowed
function lgcInputS.textInputLogic(self, text)
	local LE = self.LE

	if self.LE_allow_input then
		local hist = self.LE_hist

		editWid.resetCaretBlink(self)

		local xcb, xhb = LE:getCaretOffsets() -- old offsets

		local clear_input_category = false

		if self.LE_replace_mode then
			-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
			if xcb < #LE.lines[#LE.lines] + 1 then
				clear_input_category = true
			end
		end

		local written = editFuncS.writeText(self, text, false)

		if written then
			editWidS.generalUpdate(self, true, true, true, true)

			if clear_input_category then
				self.LE_input_category = false
			end

			if hist.enabled then
				local no_ws = written:find("%S")
				local entry = hist:getEntry()
				local do_advance = true

				if (entry and entry.cb == xcb)
				and ((self.LE_input_category == "typing" and no_ws) or (self.LE_input_category == "typing-ws"))
				then
					do_advance = false
				end

				if do_advance then
					editFuncS.doctorHistoryCaretOffsets(self, xcb, xhb)
				end
				editFuncS.writeHistoryEntry(self, do_advance)
				self.LE_input_category = no_ws and "typing" or "typing-ws"
			end

			return true
		end
	end
end


-- @return true if event propagation should halt.
function lgcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
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

	local bound_func = editBindS[hot_scan] or editBindS[hot_key]

	if bound_func then
		return editWrapS.wrapAction(self, bound_func)
	end
end


local function _caretToX(self, clear_highlight, x, split_x)
	local LE = self.LE

	local byte = LE:getCharacterDetailsAtPosition(x, split_x)

	LE:moveCaret(byte, clear_highlight)
end


local function _clickDragByWord(self, x, origin_byte)
	local LE = self.LE

	local drag_byte = LE:getCharacterDetailsAtPosition(x, true)

	-- Expand ranges to cover full words
	local db1, db2 = LE:getWordRange(drag_byte)
	local cb1, cb2 = LE:getWordRange(origin_byte)

	-- Merge the two ranges.
	local mb1, mb2 = math.min(cb1, db1), math.max(cb2, db2)
	if origin_byte < drag_byte then
		mb1, mb2 = mb2, mb1
	end

	LE:moveCaretAndHighlight(mb1, mb2)
end


-- @param mouse_x, mouse_y Mouse position relative to widget top-left.
-- @return true if event propagation should be halted.
function lgcInputS.mousePressLogic(self, button, mouse_x, mouse_y, had_thimble1_before)
	local LE = self.LE
	local context = self.context

	editWid.resetCaretBlink(self)

	local ctrl_down, shift_down, alt_down, gui_down = context.key_mgr:getModState()

	if button == 1 then
		-- WIP: this isn't quite right.
		-- [[
		if not had_thimble1_before and self.LE_select_all_on_thimble1_take then
			return
		end
		--]]

		self.press_busy = "text-drag"

		-- Apply scroll + margin offsets
		local mouse_sx = mouse_x + self.scr_x - self.vp_x - self.LE_align_ox

		local core_byte = LE:getCharacterDetailsAtPosition(mouse_sx, true)

		if context.cseq_button == 1 then
			-- Not the same byte position as last click: force single-click mode.
			if context.cseq_presses > 1  and core_byte ~= self.LE_click_byte then
				context:forceClickSequence(self, button, 1)
				-- XXX Causes 'cseq_presses' to go from 3 to 1. Not a huge deal but worth checking over.
			end

			if context.cseq_presses == 1 then
				_caretToX(self, not shift_down, mouse_sx, true)

				self.LE_click_byte = LE.cb

			elseif context.cseq_presses == 2 then
				self.LE_click_byte = LE.cb

				-- Highlight group from highlight position to mouse position.
				self:highlightCurrentWord()

			elseif context.cseq_presses == 3 then
				self.LE_click_byte = LE.cb

				--- Highlight everything.
				self:highlightAll()
			end
		end

	elseif button == 2 then
		local root = self:getRootWidget()
		lgcMenu.widgetConfigureMenuItems(self, self.pop_up_def)

		--print("thimble1, thimble2", self.context.thimble1, self.context.thimble2)

		local ax, ay = self:getAbsolutePosition()
		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		local pop_up = lgcWimp.makePopUpMenu(self, self.pop_up_def, ax + mouse_x, ay + mouse_y)
		root:sendEvent("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

		pop_up:tryTakeThimble2()

		-- Halt propagation
		return true
	end
end


-- Used in uiCall_update(). Before calling, check that text-drag state is active.
function lgcInputS.mouseDragLogic(self)
	local context = self.context
	local LE = self.LE

	editWid.resetCaretBlink(self)

	-- Mouse position relative to viewport #1.
	local ax, ay = self:getAbsolutePosition()
	local mx, my = self.context.mouse_x - ax - self.vp_x, self.context.mouse_y - ay - self.vp_y

	-- ...And with scroll offsets applied.
	local s_mx = mx + self.scr_x - self.LE_align_ox
	local s_my = my + self.scr_y

	--print("s_mx", s_mx, "s_my", s_my, "scr_x", self.scr_x, "scr_y", self.scr_y)

	-- Handle drag highlight actions.
	if context.cseq_presses == 1 then
		_caretToX(self, false, s_mx, true)

	elseif context.cseq_presses == 2 then
		_clickDragByWord(self, s_mx, self.LE_click_byte)
	end
	-- cseq_presses == 3: selecting whole line (nothing to do at drag-time).

	-- Amount to drag for the update() callback (to be scaled down and multiplied by dt).
	return (mx < 0) and mx or (mx >= self.vp_w) and mx - self.vp_w or 0
end


function lgcInputS.thimble1Take(self)
	editWid.resetCaretBlink(self)

	if self.LE_select_all_on_thimble1_take then
		self:highlightAll()
	end
end


function lgcInputS.thimble1Release(self)
	love.keyboard.setTextInput(false)
	if self.LE_deselect_all_on_thimble1_release then
		self:caretFirst(true)
	end
	if self.LE_clear_history_on_deselect then
		editFuncS.wipeHistoryEntries(self)
	end
	if self.LE_clear_input_category_on_deselect then
		self:resetInputCategory()
	end
end


--- Draw the text component.
-- @param color_highlight Table of colors for the text highlight, or nil/false to not draw the highlight.
-- @param font_ghost Font to use for optional "Ghost Text", or nil/false to not draw it.
-- @param color_text Table of colors to use for the body text, or nil/false to not draw it.
-- @param font Font to use when printing the main text (required, even if printing is disabled by color_text being false).
-- @param color_caret Table of colors for the text caret, or nil/false to not draw the caret.
function lgcInputS.draw(self, color_highlight, font_ghost, color_text, font, color_caret)
	-- Call after setting up the text area scissor box, within `love.graphics.push("all")` and `pop()`.

	local LE = self.LE

	love.graphics.translate(
		self.vp_x + self.LE_align_ox - self.scr_x,
		self.vp_y - self.scr_y
	)

	-- Highlighted selection.
	if color_highlight and LE.disp_highlighted then
		love.graphics.setColor(color_highlight)
		love.graphics.rectangle(
			"fill",
			LE.highlight_x,
			LE.highlight_y,
			LE.highlight_w,
			LE.highlight_h
		)
	end

	-- Ghost text. XXX: alignment
	if font_ghost and self.LE_ghost_text and #LE.line == 0 then
		love.graphics.setFont(font_ghost)
		love.graphics.print(self.LE_ghost_text, 0, 0)
	end

	-- Display Text.
	if color_text then
		love.graphics.setColor(color_text)
		if self.LE_text_batch then
			love.graphics.draw(self.LE_text_batch)
		else
			love.graphics.setFont(font)
			love.graphics.print(LE.disp_text)
		end
	end

	-- Caret.
	if color_caret and self.LE_caret_showing and self:hasAnyThimble() then
		love.graphics.setColor(color_caret)
		love.graphics.rectangle(
			self.LE_caret_fill,
			self.LE_caret_x,
			self.LE_caret_y,
			self.LE_caret_w,
			self.LE_caret_h
		)
	end
end


function lgcInputS.cb_action(self, item_t)
	return editWrapS.wrapAction(self, item_t.func)
end


-- Configuration functions for pop-up menu items.


function lgcInputS.configItem_undo(item, client)
	item.selectable = true
	local hist = client.LE_hist
	item.actionable = (hist.enabled and hist.pos > 1)
end


function lgcInputS.configItem_redo(item, client)
	item.selectable = true
	local hist = client.LE_hist
	item.actionable = (hist.enabled and hist.pos < #hist.ledger)
end


function lgcInputS.configItem_cutCopyDelete(item, client)
	item.selectable = true
	item.actionable = client.LE:isHighlighted()
end


function lgcInputS.configItem_paste(item, client)
	item.selectable = true
	item.actionable = true
end


function lgcInputS.configItem_selectAll(item, client)
	item.selectable = true
	item.actionable = (#client.LE.line > 0)
end


-- The default pop-up menu definition.
-- [XXX 17] Add key mnemonics and shortcuts for text box pop-up menu
lgcInputS.pop_up_def = {
	{
		type = "command",
		text = "Undo",
		callback = lgcInputS.cb_action,
		func = editActS.undo,
		config = lgcInputS.configItem_undo,
	}, {
		type = "command",
		text = "Redo",
		callback = lgcInputS.cb_action,
		func = editActS.redo,
		config = lgcInputS.configItem_redo,
	},
	{type="separator"},
	{
		type = "command",
		text = "Cut",
		callback = lgcInputS.cb_action,
		func = editActS.cut,
		config = lgcInputS.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Copy",
		callback = lgcInputS.cb_action,
		func = editActS.copy,
		config = lgcInputS.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Paste",
		callback = lgcInputS.cb_action,
		func = editActS.paste,
		config = lgcInputS.configItem_paste,
	}, {
		type = "command",
		text = "Delete",
		callback = lgcInputS.cb_action,
		func = editActS.deleteHighlighted,
		config = lgcInputS.configItem_cutCopyDelete,
	},
	{type="separator"},
	{
		type = "command",
		text = "Select All",
		callback = lgcInputS.cb_action,
		func = editActS.selectAll,
		config = lgcInputS.configItem_selectAll,
	},
}


return lgcInputS
