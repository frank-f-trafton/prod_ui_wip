--[[
Widget Component: Text Input (Single-Line)

Usage:

* Run 'wcContainer.setupDef()' on the widget definition.

* Run 'wcContainer.setupInstance()' on the widget instance during creation.
--]]


--[[
Widgets using this system are not compatible with the following callbacks:

* evt_thimbleAction: interferes with typing space bar and enter.
Instead, check for enter (or space) in the widget's 'evt_keyPressed' callback.

Example:
----
if (scancode == "return" or scancode == "kpenter") and self:wid_action() then
	return true
else
	return wcInputS.keyPressLogic(self, key, scancode, isrepeat)
end
----

* evt_thimbleAction2: interferes with the pop-up menu (undo, etc.)
--]]


local context = select(1, ...)


local wcInputS = {}


-- LÖVE Supplemental
local utf8 = require("utf8")


local edCom = context:getLua("shared/line_ed/ed_com")
local editAct = context:getLua("shared/line_ed/edit_act")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local numLockMap = require(context.conf.prod_ui_req .. "data.keyboard.num_lock_map")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local structHistory = context:getLua("shared/struct_history")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiKeyboard = require(context.conf.prod_ui_req .. "ui_keyboard")
local uiPopUpMenu = require(context.conf.prod_ui_req .. "ui_pop_up_menu")
local wcWimp = context:getLua("shared/wc/wc_wimp")
local widShared = context:getLua("core/wid_shared")


-- LÖVE 12 compatibility.
local love_major, love_minor = love.getVersion()


-- Widget def configuration.
function wcInputS.setupDef(def)
	pTable.patch(def, editMethodsS, true)
end


function wcInputS.setupInstance(self, commands)
	self.LE_commands = editAct[commands]
	if not self.LE_commands then
		error("invalid 'commands' ID")
	end

	-- When true, typing overwrites the current position instead of inserting.
	self.LE_replace_mode = false

	-- When false, cannot enable Replace Mode.
	self.LE_allow_replace = true

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'textUtil.sanitize()' for options.
	self.LE_bad_input_rule = false

	-- Enable/disable specific editing actions.
	self.LE_allow_input = true -- prevents editing actions; does not affect navigation, highlighting and copying.
	self.LE_allow_cut = true
	self.LE_allow_copy = true
	self.LE_allow_paste = true
	self.LE_allow_highlight = true

	-- Allows '\n' as text input (whether by hitting enter or pasting from the clipboard).
	-- Single-line input treats line feeds like any other character. For example, 'home' and 'end' will not
	-- stop at line feeds.
	-- In the external display string, line feed code points (0xa) are replaced with U+23CE (⏎).
	-- Note that enter key events may be intercepted by widget logic before the text input code gets a
	-- chance to consider it.
	self.LE_allow_line_feed = false

	-- 'LE_allow_tab' and 'LE_allow_untab' are not supported in the single-line code.
	-- You can paste in tabs, however.

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.LE_u_chars_max = 5000

	-- Helps with amending vs making new history entries.
	self.LE_input_category = false

	-- When these fields are true, the widget should…
	-- * Select all text upon receiving the thimble
	self.LE_select_all_on_thimble1_take = false

	-- * Deselect all text upon releasing the thimble (the caret is moved to the first position).
	self.LE_deselect_all_on_thimble1_release = false

	-- * Clear history when deselected
	self.LE_clear_history_on_deselect = false

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

	-- Byte offset when clicking the mouse.
	-- This is only valid when a mouse action is in progress.
	self.LE_click_byte = 1

	-- How far to offset the line X position depending on the alignment.
	self.LE_align_ox = 0

	-- How far to offset text vertically. (See 'text_align_v' in widget skins.)
	self.LE_align_oy = 0

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
function wcInputS.textInputLogic(self, text)
	local LE = self.LE

	if self.LE_allow_input then
		local hist = self.LE_hist

		editWid.resetCaretBlink(self)

		local xcb, xhb = LE:getCaretOffsets() -- old offsets

		local clear_input_category = false

		if self.LE_replace_mode then
			-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
			if xcb < #LE.line + 1 then
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
function wcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
	local LE = self.LE

	local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()

	editWid.resetCaretBlink(self)

	-- pop-up menu (undo, etc.)
	if scancode == "application" or (shift_down and scancode == "f10") then
		-- Locate caret in UI space
		local ax, ay = self:getAbsolutePosition()
		local vp = self.vp
		local caret_x = ax + vp.x - self.scr_x + LE.caret_box_x + self.LE_align_ox
		local caret_y = ay + vp.y - self.scr_y + LE.caret_box_y + LE.caret_box_h + self.LE_align_oy

		self.pop_up_proto:configure(self)

		local pop_up = wcWimp.makePopUpMenu(self, self.pop_up_proto, caret_x, caret_y)
		pop_up:tryTakeThimble2()

		-- Halt propagation
		return true
	end

	-- (LÖVE 12) if this key should behave differently when NumLock is disabled, swap out the scancode and key constant.
	if love_major >= 12 and numLockMap[scancode] and not love.keyboard.isModifierActive("numlock") then
		scancode = numLockMap[scancode]
		key = love.keyboard.getKeyFromScancode(scancode)
	end

	local id = uiKeyboard.keyStringsInKeyBinds(context.settings.wimp.text_input.commands, hot_key, hot_scan)
	if id then
		local bound_func = self.LE_commands[id]

		if bound_func then
			return editWidS.wrapAction(self, bound_func)
		end
	end
end


local function _caretToX(self, clear_highlight, x, split_x)
	local LE = self.LE

	local byte = LE:getCharacterDetailsAtPosition(x, split_x)

	LE:moveCaret(byte, clear_highlight)
end


local function _clickDragByWord(self, x, origin_byte)
	local LE = self.LE

	-- Don't leak masked info.
	if LE.masked then
		LE:moveCaretAndHighlight(#LE.line + 1, 1)
	else
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
end


-- @param mx, my Mouse position relative to widget top-left.
-- @return true if event propagation should be halted.
function wcInputS.mousePressLogic(self, button, mx, my, had_thimble1_before)
	local LE = self.LE

	editWid.resetCaretBlink(self)

	if button == 1 then
		if not had_thimble1_before and self.LE_select_all_on_thimble1_take then
			return
		end

		self.press_busy = "text-drag"

		-- apply offsets
		local msx = mx + self.scr_x - self.LE_align_ox

		local core_byte = LE:getCharacterDetailsAtPosition(msx, true)

		if context.cseq_button == 1 then
			-- Not the same byte position as last click: force single-click mode.
			if context.cseq_presses > 1  and core_byte ~= self.LE_click_byte then
				context:forceClickSequence(self, button, 1)
			end

			if context.cseq_presses == 1 then
				local _, shift_down, _, _ = context.key_mgr:getModState()
				_caretToX(self, not shift_down, msx, true)

				self.LE_click_byte = LE.cb


			elseif context.cseq_presses == 2 then
				self.LE_click_byte = LE.cb

				-- Highlight group from highlight position to mouse position.
				self:highlightCurrentWord()

			elseif context.cseq_presses == 3 then
				self.LE_click_byte = LE.cb

				context:forceClickSequence(false, false, 0)

				--- Highlight everything.
				self:highlightAll()
			end
		end

	elseif button == 2 then
		local root = self:nodeGetRoot()
		self.pop_up_proto:configure(self)

		--print("thimble1, thimble2", self.context.thimble1, self.context.thimble2)

		local ax, ay = self:getAbsolutePosition()
		local pop_up = wcWimp.makePopUpMenu(self, self.pop_up_proto, ax + mx, ay + my)
		root:eventSend("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

		pop_up:tryTakeThimble2()

		-- Halt propagation
		return true
	end
end


-- Used in evt_update(). Before calling, check that text-drag state is active.
function wcInputS.mouseDragLogic(self)
	local context = self.context
	local LE = self.LE

	local widget_needs_update = false

	editWid.resetCaretBlink(self)

	-- relative mouse position
	local mx, _ = self:getRelativePosition(context.mouse_x, context.mouse_y)

	-- ...And with offsets applied.
	local msx = mx + self.scr_x - self.LE_align_ox

	-- Handle drag highlight actions.
	if context.cseq_presses == 1 then
		_caretToX(self, false, msx, true)
		widget_needs_update = true

	elseif context.cseq_presses == 2 then
		_clickDragByWord(self, msx, self.LE_click_byte)
		widget_needs_update = true
	end

	-- cseq_presses == 3: selecting whole line (nothing to do at drag-time).

	return widget_needs_update
end


function wcInputS.thimble1Take(self)
	editWid.resetCaretBlink(self)

	if self.LE_select_all_on_thimble1_take then
		self:highlightAll()
	end
end


function wcInputS.thimble1Release(self)
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
function wcInputS.draw(self, color_highlight, font_ghost, color_text, font, color_caret)
	-- Call after setting up the text area scissor box and scrolling, within `love.graphics.push("all")` and `pop()`.

	local LE = self.LE

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


function wcInputS.cb_action(self, command_id)
	local command = self.LE_commands[command_id]
	if command then
		return editWidS.wrapAction(self, command)
	end
end


-- Configuration functions for pop-up menu items.


function wcInputS.configProto_undo(client)
	local hist = client.LE_hist
	return client.LE_allow_input and hist.enabled and hist.pos > 1
end


function wcInputS.configProto_redo(client)
	local hist = client.LE_hist
	return client.LE_allow_input and hist.enabled and hist.pos < #hist.ledger
end


function wcInputS.configProto_cut(client)
	return client.LE_allow_input and client.LE_allow_cut and client.LE:isHighlighted()
end


function wcInputS.configProto_copy(client)
	return client.LE_allow_input and client.LE_allow_copy and client.LE:isHighlighted()
end


function wcInputS.configProto_delete(client)
	return client.LE_allow_input and client.LE:isHighlighted()
end


function wcInputS.configProto_paste(client)
	return client.LE_allow_input and client.LE_allow_paste and true or false
end


function wcInputS.configProto_selectAll(client)
	return #client.LE.line > 0
end


-- The default pop-up menu definition.
-- [XXX 17] Add key mnemonics and shortcuts for text box pop-up menu
do
	local P = uiPopUpMenu.P

	wcInputS.pop_up_proto = P.prototype {
		P.command()
			:setText("Undo")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "undo") end)
			:setConfig(wcInputS.configProto_undo),

		P.command()
			:setText("Redo")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "redo") end)
			:setConfig(wcInputS.configProto_redo),

		P.separator(),

		P.command()
			:setText("Cut")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "cut") end)
			:setConfig(wcInputS.configProto_cut),

		P.command()
			:setText("Copy")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "copy") end)
			:setConfig(wcInputS.configProto_copy),

		P.command()
			:setText("Paste")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "paste") end)
			:setConfig(wcInputS.configProto_paste),

		P.command()
			:setText("Delete")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "delete-highlighted") end)
			:setConfig(wcInputS.configProto_delete),

		P.separator(),

		P.command()
			:setText("Select All")
			:setCallback(function(client, item) return wcInputS.cb_action(client, "select-all") end)
			:setConfig(wcInputS.configProto_selectAll),
	}
end


return wcInputS
