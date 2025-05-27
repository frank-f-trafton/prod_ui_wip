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


local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local editActS = context:getLua("shared/line_ed/s/edit_act_s")
local editBindS = context:getLua("shared/line_ed/s/edit_bind_s")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local editWrapS = context:getLua("shared/line_ed/s/edit_wrap_s")
local itemOps = require(context.conf.prod_ui_req .. "common.item_ops")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcMenu = context:getLua("shared/lgc_menu")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = context:getLua("core/wid_shared")


-- LÖVE 12 compatibility.
local love_major, love_minor = love.getVersion()


-- Widget def configuration.
function lgcInputS.setupDef(def)
	for k, v in pairs(editMethodsS) do
		def[k] = v
	end
end


function lgcInputS.setupInstance(self)
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

	-- Allows '\n' as text input (including pasting from the clipboard).
	-- Single-line input treats line feeds like any other character. For example, 'home' and 'end' will not
	-- stop at line feeds.
	-- In the external display string, line feed code points (0xa) are replaced with U+23CE (⏎).
	self.allow_line_feed = false

	-- Allows typing a line feed by pressing enter/return. `self.allow_line_feed` must be true.
	-- Note that this may override other uses of enter/return in the owning widget.
	self.allow_enter_line_feed = false

	self.allow_tab = false -- affects single presses of the tab key
	self.allow_untab = false -- affects shift+tab (unindenting)
	self.tabs_to_spaces = false -- affects '\t' in writeText()

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.u_chars_max = math.huge

	-- Helps with amending vs making new history entries.
	self.input_category = false

	-- When these fields are true, the widget should…
	-- * Select all text upon receiving the thimble
	self.select_all_on_thimble1_take = false

	-- * Deselect all text upon releasing the thimble (the caret is moved to the first position).
	self.deselect_all_on_thimble1_release = false

	-- * Clear history when deselected
	self.clear_history_on_deselect = false

	-- * Clear the input category when deselected (forcing a new history entry to be made upon the
	-- next user text input event). ('clear_history_on_deselect' also does this.)
	self.clear_input_category_on_deselect = true

	-- Caret position and dimensions. Based on 'line_ed.caret_box_*'.
	self.caret_x = 0
	self.caret_y = 0
	self.caret_w = 0
	self.caret_h = 0

	self.caret_fill = "line"

	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.caret_extend_x = 0
	self.caret_extend_y = 0

	-- Used to update viewport scrolling as a result of dragging the mouse in update().
	self.mouse_drag_x = 0

	-- Position offset when clicking the mouse.
	-- This is only valid when a mouse action is in progress.
	self.click_byte = 1

	self.align = "left" -- "left", "center", "right"

	-- How far to offset the line X position depending on the alignment.
	self.align_offset = 0

	-- string: display this text when the input box is empty.
	-- false: disabled.
	self.ghost_text = false

	-- false: use content text alignment.
	-- "left", "center", "right", "justify"
	self.ghost_text_align = false

	self.caret_is_showing = true
	self.caret_blink_time = 0

	-- XXX: skin or some other config system
	self.caret_blink_reset = -0.5
	self.caret_blink_on = 0.5
	self.caret_blink_off = 0.5

	--[[
	'self.fn_check': a function that can reject changes made to the text.
	* Arguments: self (the widget)
	* Returns: false/nil if the new text should be backed out, any other value otherwise.
	--]]

	self.line_ed = lineEdS.new()
end


function lgcInputS.updateCaretBlink(self, dt)
	self.caret_blink_time = self.caret_blink_time + dt
	if self.caret_blink_time > self.caret_blink_on + self.caret_blink_off then
		self.caret_blink_time = math.max(-(self.caret_blink_on + self.caret_blink_off), self.caret_blink_time - (self.caret_blink_on + self.caret_blink_off))
	end

	self.caret_is_showing = self.caret_blink_time < self.caret_blink_off
end


function lgcInputS.cb_action(self, item_t)
	return editWrapS.wrapAction(self, item_t.func)
end


-- @return true if event propagation should halt.
function lgcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
	local line_ed = self.line_ed

	local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()

	editFuncS.resetCaretBlink(self)

	-- pop-up menu (undo, etc.)
	if scancode == "application" or (shift_down and scancode == "f10") then
		-- Locate caret in UI space
		local ax, ay = self:getAbsolutePosition()
		local caret_x = ax + self.vp_x - self.scr_x + line_ed.caret_box_x + self.align_offset
		local caret_y = ay + self.vp_y - self.scr_y + line_ed.caret_box_y + line_ed.caret_box_h

		lgcMenu.widgetConfigureMenuItems(self, self.pop_up_def)

		local pop_up = commonWimp.makePopUpMenu(self, self.pop_up_def, caret_x, caret_y)
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
		-- XXX: cleanup (just do a return) once the old debug stuff is removed below.
		local r1, r2 = editWrapS.wrapAction(self, bound_func)
		if r1 then
			-- Stop event propagation
			return r1, r2
		end
	end


	-- XXX: This is old debug functionality that should be moved elsewhere.
	--[[
	elseif scancode == "f6" then
		-- XXX: debug: left align

	elseif scancode == "f7" then
		-- XXX: debug: center align

	elseif scancode == "f8" then
		-- XXX: debug: right align

	elseif scancode == "f9" then
		-- XXX: masking (for passwords)

	elseif scancode == "f10" then
		-- XXX: debug: colorization test
	--]]
end


-- @return true if the input was accepted, false if it was rejected or input is not allowed
function lgcInputS.textInputLogic(self, text)
	local line_ed = self.line_ed

	if self.allow_input then
		editFuncS.resetCaretBlink(self)

		local hist = line_ed.hist
		local old_car, old_h = line_ed.car_byte, line_ed.h_byte
		local written = editFuncS.writeText(self, text, false)

		if written then
			if self.replace_mode then
				-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
				if line_ed.car_byte < #line_ed.line + 1 then
					self.input_category = false
				end
			end

			if hist.enabled then
				local non_ws = written:find("%S")
				local entry = hist:getEntry()
				local do_advance = true

				if (entry and entry.car_byte == old_car)
				and ((self.input_category == "typing" and non_ws) or (self.input_category == "typing-ws"))
				then
					do_advance = false
				end

				if do_advance then
					editHistS.doctorCurrentCaretOffsets(hist, old_car, old_h)
				end
				editHistS.writeEntry(line_ed, do_advance)
				self.input_category = non_ws and "typing" or "typing-ws"
			end

			editFuncS.updateCaretShape(self)
			self:updateDocumentDimensions()
			self:scrollGetCaretInBounds(true)

			return true
		end
	end
end


function lgcInputS.caretToX(self, clear_highlight, x, split_x)
	local line_ed = self.line_ed
	local byte = line_ed:getCharacterDetailsAtPosition(x, split_x)

	line_ed:caretToByte(byte)

	if clear_highlight then
		line_ed:clearHighlight()
	end
	line_ed:syncDisplayCaretHighlight()
end


-- @param mouse_x, mouse_y Mouse position relative to widget top-left.
-- @return true if event propagation should be halted.
function lgcInputS.mousePressLogic(self, button, mouse_x, mouse_y, had_thimble1_before)
	local line_ed = self.line_ed
	local context = self.context

	editFuncS.resetCaretBlink(self)

	if button == 1 then
		-- WIP: this isn't quite right.
		-- [[
		if not had_thimble1_before and self.select_all_on_thimble1_take then
			return
		end
		--]]

		self.press_busy = "text-drag"

		-- Apply scroll + margin offsets
		local mouse_sx = mouse_x + self.scr_x - self.vp_x - self.align_offset

		local core_byte = line_ed:getCharacterDetailsAtPosition(mouse_sx, true)

		if context.cseq_button == 1 then
			-- Not the same byte position as last click: force single-click mode.
			if context.cseq_presses > 1  and core_byte ~= self.click_byte then
				context:forceClickSequence(self, button, 1)
				-- XXX Causes 'cseq_presses' to go from 3 to 1. Not a huge deal but worth checking over.
			end

			if context.cseq_presses == 1 then
				lgcInputS.caretToX(self, true, mouse_sx, true)

				self.click_byte = line_ed.car_byte
				editFuncS.updateCaretShape(self)

			elseif context.cseq_presses == 2 then
				self.click_byte = line_ed.car_byte

				-- Highlight group from highlight position to mouse position.
				self:highlightCurrentWord()
				editFuncS.updateCaretShape(self)

			elseif context.cseq_presses == 3 then
				self.click_byte = line_ed.car_byte

				--- Highlight everything.
				self:highlightAll()
				editFuncS.updateCaretShape(self)
			end
		end

	elseif button == 2 then
		local root = self:getRootWidget()
		lgcMenu.widgetConfigureMenuItems(self, self.pop_up_def)

		--print("thimble1, thimble2", self.context.thimble1, self.context.thimble2)

		local ax, ay = self:getAbsolutePosition()
		local pop_up = commonWimp.makePopUpMenu(self, self.pop_up_def, ax + mouse_x, ay + mouse_y)
		root:sendEvent("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

		pop_up:tryTakeThimble2()

		-- Halt propagation
		return true
	end
end


function lgcInputS.clickDragByWord(self, x, origin_byte)
	local line_ed = self.line_ed

	local drag_byte = line_ed:getCharacterDetailsAtPosition(x, true)

	-- Expand ranges to cover full words
	local db1, db2 = line_ed:getWordRange(drag_byte)
	local cb1, cb2 = line_ed:getWordRange(origin_byte)

	-- Merge the two ranges.
	local mb1, mb2 = math.min(cb1, db1), math.max(cb2, db2)
	if origin_byte < drag_byte then
		mb1, mb2 = mb2, mb1
	end

	line_ed:caretToByte(mb1)
	line_ed:highlightToByte(mb2)
	line_ed:syncDisplayCaretHighlight()
end


-- Used in uiCall_update(). Before calling, check that text-drag state is active.
function lgcInputS.mouseDragLogic(self)
	local context = self.context
	local line_ed = self.line_ed

	editFuncS.resetCaretBlink(self)

	-- Mouse position relative to viewport #1.
	local ax, ay = self:getAbsolutePosition()
	local mx, my = self.context.mouse_x - ax - self.vp_x, self.context.mouse_y - ay - self.vp_y

	-- ...And with scroll offsets applied.
	local s_mx = mx + self.scr_x - self.align_offset
	local s_my = my + self.scr_y

	--print("s_mx", s_mx, "s_my", s_my, "scr_x", self.scr_x, "scr_y", self.scr_y)

	-- Handle drag highlight actions.
	if context.cseq_presses == 1 then
		lgcInputS.caretToX(self, false, s_mx, true)
		editFuncS.updateCaretShape(self)

	elseif context.cseq_presses == 2 then
		lgcInputS.clickDragByWord(self, s_mx, self.click_byte)
		editFuncS.updateCaretShape(self)
	end
	-- cseq_presses == 3: selecting whole line (nothing to do at drag-time).

	-- Amount to drag for the update() callback (to be scaled down and multiplied by dt).
	return (mx < 0) and mx or (mx >= self.vp_w) and mx - self.vp_w or 0
end


function lgcInputS.thimble1Take(self)
	editFuncS.resetCaretBlink(self)

	if self.select_all_on_thimble1_take then
		self:highlightAll()
		editFuncS.updateCaretShape(self)
	end
end


function lgcInputS.thimble1Release(self)
	love.keyboard.setTextInput(false)
	if self.deselect_all_on_thimble1_release then
		self:caretFirst(true)
		editFuncS.updateCaretShape(self)
	end
	if self.clear_history_on_deselect then
		editHistS.wipeEntries(self)
	end
	if self.clear_input_category_on_deselect then
		self:resetInputCategory()
	end
end


function lgcInputS.reshapeUpdate(self)
	self.line_ed:updateDisplayText()
	self:updateDocumentDimensions()
	editFuncS.updateCaretShape(self)
	--self:scrollClampViewport()
	--self:scrollGetCaretInBounds(true)
end



function lgcInputS.method_scrollGetCaretInBounds(self, immediate)
	local line_ed = self.line_ed

	-- get the extended caret rectangle
	local car_x1 = self.align_offset + line_ed.caret_box_x - self.caret_extend_x
	local car_y1 = line_ed.caret_box_y - self.caret_extend_y
	local car_x2 = self.align_offset + line_ed.caret_box_x + math.max(line_ed.caret_box_w, line_ed.caret_box_w_edge) + self.caret_extend_x
	local car_y2 = line_ed.caret_box_y + line_ed.caret_box_h + self.caret_extend_y

	--print("self.scr_tx", self.scr_tx, "car_x1", car_x1, "car_x2", car_x2)
	--print("self.scr_ty", self.scr_ty, "car_y1", car_y1, "car_y2", car_y2)

	widShared.scrollRectInBounds(self, car_x1, car_y1, car_x2, car_y2, immediate)
end


function lgcInputS.method_updateDocumentDimensions(self)
	local line_ed = self.line_ed
	local font = line_ed.font

	-- The document width is the larger of: 1) viewport width, 2) text width (plus an empty caret slot).
	-- When alignment is center or right and the text is smaller than the viewport, the text, caret,
	-- etc. are transposed.
	self.doc_w = math.max(self.vp_w, line_ed.disp_text_w)
	self.doc_h = math.floor(font:getHeight() * font:getLineHeight())

	local align = self.align
	if align == "left" then
		self.align_offset = 0

	elseif align == "center" then
		self.align_offset = math.max(0, (self.vp_w - line_ed.disp_text_w) * .5)

	else -- align == "right"
		self.align_offset = math.max(0, self.vp_w - line_ed.disp_text_w)
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

	local line_ed = self.line_ed

	love.graphics.translate(
		self.vp_x + self.align_offset - self.scr_x,
		self.vp_y - self.scr_y
	)

	-- Highlighted selection.
	if color_highlight and line_ed.disp_highlighted then
		love.graphics.setColor(color_highlight)
		love.graphics.rectangle(
			"fill",
			line_ed.highlight_x,
			line_ed.highlight_y,
			line_ed.highlight_w,
			line_ed.highlight_h
		)
	end

	-- Ghost text. XXX: alignment
	if font_ghost and self.ghost_text and #line_ed.line == 0 then
		love.graphics.setFont(font_ghost)
		love.graphics.print(self.ghost_text, 0, 0)
	end

	-- Display Text.
	if color_text then
		love.graphics.setColor(color_text)
		love.graphics.setFont(font)
		love.graphics.print(line_ed.disp_text)
	end

	-- Caret.
	if color_caret and self.caret_is_showing and self:hasAnyThimble() then
		love.graphics.setColor(color_caret)
		love.graphics.rectangle(
			self.caret_fill,
			self.caret_x,
			self.caret_y,
			self.caret_w,
			self.caret_h
		)
	end
end


-- Configuration functions for pop-up menu items.


function lgcInputS.configItem_undo(item, client)
	item.selectable = true
	local hist = client.line_ed.hist
	item.actionable = (hist.enabled and hist.pos > 1)
end


function lgcInputS.configItem_redo(item, client)
	item.selectable = true
	local hist = client.line_ed.hist
	item.actionable = (hist.enabled and hist.pos < #hist.ledger)
end


function lgcInputS.configItem_cutCopyDelete(item, client)
	item.selectable = true
	item.actionable = client.line_ed:isHighlighted()
end


function lgcInputS.configItem_paste(item, client)
	item.selectable = true
	item.actionable = true
end


function lgcInputS.configItem_selectAll(item, client)
	item.selectable = true
	item.actionable = (#client.line_ed.line > 0)
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
	itemOps.def_separator,
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
	itemOps.def_separator,
	{
		type = "command",
		text = "Select All",
		callback = lgcInputS.cb_action,
		func = editActS.selectAll,
		config = lgcInputS.configItem_selectAll,
	},
}


return lgcInputS
