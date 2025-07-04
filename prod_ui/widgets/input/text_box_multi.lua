-- A multi-line text input box.

--[[
         Viewport #1
  ╔═══════════════════════╗
  ║                       ║

┌───────────────────────────┬─┐
│ ......................... │^│
│ .The quick brown fox    . ├─┤
│ .jumps over the lazy    . │ │
│ .dog.|                  . │ │
│ .                       . │ │
│ .                       . │ │
│ .                       . │ │
│ ......................... ├─┤
│                           │v│  ═══╗
├─┬───────────────────────┬─┼─┤     ╠═ Optional scroll bars
│<│                       │>│ │  ═══╝
└─┴───────────────────────┴─┴─┘

--]]


local context = select(1, ...)


-- LÖVE 12 compatibility
local love_major, love_minor = love.getVersion()


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)


-- ProdUI

local editBindM = context:getLua("shared/line_ed/m/edit_bind_m")
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcInputM = context:getLua("shared/lgc_input_m")
local lgcMenu = context:getLua("shared/lgc_menu")
local lgcScroll = context:getLua("shared/lgc_scroll")
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "text_box_m1",
	renderThimble = uiShared.dummyFunc
}


lgcInputM.setupDef(def)


widShared.scrollSetMethods(def)
def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")
def.pop_up_def = lgcInputM.pop_up_def


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)

	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)

	self.press_busy = false

	-- State flags (WIP)
	self.enabled = true

	lgcInputM.setupInstance(self)

	self:skinSetRefs()
	self:skinInstall()

	local skin = self.skin

	self.line_ed = lineEdM.new(skin.font)

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

	-- Caret fill mode and color table
	self.caret_fill = "fill"

	-- Tick this whenever something related to the text box needs to be cached again.
	-- lineEditor itself should immediately apply its own state changes.
	self.update_flag = true

	-- The caret rect dimensions for drawing.
	self.caret_x = 0
	self.caret_y = 0
	self.caret_w = 0
	self.caret_h = 0

	self.text_object = uiGraphics.newTextBatch(skin.font)

	self.illuminate_current_line = true

	-- Used to update viewport scrolling as a result of dragging the mouse in update().
	self.mouse_drag_x = 0
	self.mouse_drag_y = 0

	-- Position offsets when clicking the mouse.
	-- These are only valid when a mouse action is in progress.
	self.click_line = 1
	self.click_byte = 1

	editFuncM.updateCaretShape(self)
end


--- Call after changing alignment, then update the alignment of all sub-lines.
function def:updateAlignOffset()
	local align = self.line_ed.disp.align

	if align == "left" then
		self.align_offset = 0

	elseif align == "center" then
		self.align_offset = (self.doc_w < self.vp_w) and math.floor(0.5 + self.vp_w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.align_offset = (self.doc_w < self.vp_w) and self.vp_w or self.doc_w
	end
end


function def:scrollGetCaretInBounds(immediate)
	local disp = self.line_ed.disp

	--print("scrollGetCaretInBounds() BEFORE", self.scr_tx, self.scr_ty)

	-- Get the extended caret rectangle.
	local car_x1 = self.align_offset + disp.caret_box_x - self.caret_extend_x
	local car_y1 = disp.caret_box_y - self.caret_extend_y
	local car_x2 = self.align_offset + disp.caret_box_x + disp.caret_box_w + self.caret_extend_x
	local car_y2 = disp.caret_box_y + disp.caret_box_h + self.caret_extend_y

	-- Clamp the scroll target.
	self.scr_tx = math.max(car_x2 - self.vp_w, math.min(self.scr_tx, car_x1))
	self.scr_ty = math.max(car_y2 - self.vp_h, math.min(self.scr_ty, car_y1))

	if immediate then
		self.scr_fx = self.scr_tx
		self.scr_fy = self.scr_ty
		self.scr_x = math.floor(0.5 + self.scr_fx)
		self.scr_y = math.floor(0.5 + self.scr_fy)
	end

	--print("car_x1", car_x1, "car_y1", car_y1, "car_x2", car_x2, "car_y2", car_y2)
	--print("scr tx ty", self.scr_tx, self.scr_ty)

--[[
	print("BEFORE",
		"scr_x", self.scr_x, "scr_y", self.scr_y, "scr_tx", self.scr_tx, "scr_ty", self.scr_ty,
		"vp_x", self.vp_x, "vp_y", self.vp_y, "vp_w", self.vp_w, "vp_h", self.vp_h,
		"vp2_x", self.vp2_x, "vp2_y", self.vp2_y, "vp2_w", self.vp2_w, "vp2_h", self.vp2_h)
--]]
	self:scrollClampViewport()

--[[
	print("AFTER",
		"scr_x", self.scr_x, "scr_y", self.scr_y, "scr_tx", self.scr_tx, "scr_ty", self.scr_ty,
		"vp_x", self.vp_x, "vp_y", self.vp_y, "vp_w", self.vp_w, "vp_h", self.vp_h,
		"vp2_x", self.vp2_x, "vp2_y", self.vp2_y, "vp2_w", self.vp2_w, "vp2_h", self.vp2_h)
--]]
	--print("scrollGetCaretInBounds() AFTER", self.scr_tx, self.scr_ty)
	--print("doc_w", self.doc_w, "doc_h", self.doc_h)
	--print("vp xywh", self.vp_x, self.vp_y, self.vp_w, self.vp_h)
end


function def:updateDocumentDimensions()
	local disp = self.line_ed.disp

	disp.view_w = self.vp_w

	self.doc_h = disp:getDocumentHeight()

	local x1, x2 = disp:getDocumentXBoundaries()
	self.doc_w = (x2 - x1)

	self:updateAlignOffset()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the scrollable region.
	-- Viewport #2 includes margins and excludes borders.

	local skin = self.skin

	local line_ed = self.line_ed
	local disp = line_ed.disp

	widShared.resetViewport(self, 1)

	widShared.carveViewport(self, 1, skin.box.border)
	lgcScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	widShared.carveViewport(self, 1, skin.box.margin)

	self:scrollClampViewport()
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)

	line_ed:displaySyncAll()

	self:updateDocumentDimensions()

	local font = disp.font
	self.line_ed.page_jump_steps = math.max(1, math.floor(self.vp_h / (font:getHeight() * font:getLineHeight())))

	self.update_flag = true

	return true
end


--- Updates cached display state.
function def:cacheUpdate()
	local line_ed = self.line_ed
	local lines = line_ed.lines
	local disp = line_ed.disp

	local skin = self.skin

	self:updateDocumentDimensions()

	editFuncM.updateCaretShape(self)

	if line_ed.replace_mode then
		self.caret_fill = "line"
	else
		self.caret_fill = "fill"
		self.caret_w = disp.caret_line_width
	end

	-- Find the first visible display paragraph (or rather, one before it) to cut down on rendering.
	local y_pos = self.scr_y - self.vp_y -- XXX should this be viewport #2? Or does the viewport offset matter at all?

	-- XXX default to 1?
	--self.vis_para_top
	for i, paragraph in ipairs(disp.paragraphs) do
		local sub_one = paragraph[1]
		if sub_one.y > y_pos then
			self.vis_para_top = math.max(1, i - 1)
			break
		end
	end

	-- Find the last display paragraph (or one after it) as well.
	self.vis_para_bot = #disp.paragraphs
	for i = self.vis_para_top, #disp.paragraphs do
		local paragraph = disp.paragraphs[i]
		local sub_last = paragraph[#paragraph]
		if sub_last.y + sub_last.h > y_pos + self.vp2_h then
			self.vis_para_bot = i
			break
		end
	end

	--print("cacheUpdate", "self.vis_para_top", self.vis_para_top, "self.vis_para_bot", self.vis_para_bot)

	-- Update the text object, if applicable
	if self.text_object then
		local text_object = self.text_object

		text_object:clear()

		if disp.font ~= text_object:getFont() then
			text_object:setFont(disp.font)
		end

		for i = self.vis_para_top, self.vis_para_bot do
			local paragraph = disp.paragraphs[i]
			for j, sub_line in ipairs(paragraph) do

				-- [BUG] [UPGRADE] Adding empty or whitespace-only strings can crash LÖVE 11.4.
				-- These workarounds shouldn't be necessary in LÖVE 12.
				if #sub_line.str > 0 and string.find(sub_line.str, "%S") then
					text_object:add(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
				end
			end
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local ax, ay = self:getAbsolutePosition()
		mouse_x = mouse_x - ax
		mouse_y = mouse_y - ay

		lgcScroll.widgetProcessHover(self, mouse_x, mouse_y)

		if mouse_x >= self.vp2_x and mouse_x < self.vp2_x + self.vp2_w
		and mouse_y >= self.vp2_y and mouse_y < self.vp2_y + self.vp2_h
		then
			self.cursor_hover = self.skin.cursor_on
		else
			self.cursor_hover = nil
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		lgcScroll.widgetClearHover(self)

		self.cursor_hover = nil
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble1()
		end

		local mouse_x, mouse_y = self:getRelativePosition(x, y)
		local handled = false

		-- Check for pressing on scroll bar components.
		if button == 1 then
			local fixed_step = 24 -- XXX style/config

			handled = lgcScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Successful mouse interaction with scroll bars should break any existing click-sequence.
		if handled then
			self.context:forceClickSequence(false, button, 1)

		elseif widShared.pointInViewport(self, 2, mouse_x, mouse_y) then
			local context = self.context
			local line_ed = self.line_ed
			local disp = line_ed.disp

			disp:resetCaretBlink()

			if button == 1 then
				self.press_busy = "text-drag"

				-- Apply scroll + margin offsets
				local mouse_sx = mouse_x + self.scr_x - self.vp_x - self.align_offset
				local mouse_sy = mouse_y + self.scr_y - self.vp_y

				local core_line, core_byte = line_ed:getCharacterDetailsAtPosition(mouse_sx, mouse_sy, true)

				if context.cseq_button == 1 then
					-- Not the same line+byte position as last click: force single-click mode.
					if context.cseq_presses > 1  and (core_line ~= self.click_line or core_byte ~= self.click_byte) then
						context:forceClickSequence(self, button, 1)
						-- XXX Causes 'cseq_presses' to go from 3 to 1. Not a huge deal but worth checking over.
					end

					if context.cseq_presses == 1 then
						self:caretToXY(true, mouse_sx, mouse_sy, true)
						--self:scrollGetCaretInBounds() -- Helpful, or distracting?

						self.click_line = line_ed.car_line
						self.click_byte = line_ed.car_byte

						self.update_flag = true

					elseif context.cseq_presses == 2 then
						self.click_line = line_ed.car_line
						self.click_byte = line_ed.car_byte

						-- Highlight group from highlight position to mouse position
						self:highlightCurrentWord()

						self.update_flag = true

					elseif context.cseq_presses == 3 then
						self.click_line = line_ed.car_line
						self.click_byte = line_ed.car_byte

						--- Highlight sub-lines from highlight position to mouse position
						--line_ed:highlightCurrentLine()
						self:highlightCurrentWrappedLine()

						self.update_flag = true
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
	end

	-- Allow propagation so that the root widget can destroy pop-up menus.
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- XXX style/config

			lgcScroll.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			lgcScroll.widgetClearPress(self)

			self.press_busy = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	-- Catch wheel events from descendants that did not block it.

	local wheel_scale = self.context.settings.wimp.navigation.mouse_wheel_move_size_v

	self.scr_tx = self.scr_tx - x * wheel_scale
	self.scr_ty = self.scr_ty - y * wheel_scale
	-- XXX add support for non-animated, immediate scroll-to

	self:scrollClampViewport()
	lgcScroll.updateScrollBarShapes(self)

	-- Stop bubbling
	return true
end


function def:uiCall_thimble1Take(inst)
	if self == inst then
		love.keyboard.setTextInput(true)
		self.line_ed.disp:resetCaretBlink()
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		love.keyboard.setTextInput(false)
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		local line_ed = self.line_ed
		local disp = line_ed.disp

		if line_ed.allow_input then

			local hist = line_ed.hist

			disp:resetCaretBlink()

			local old_line, old_byte, old_h_line, old_h_byte = line_ed:getCaretOffsets()

			local suppress_replace = false
			if line_ed.replace_mode then
				-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
				if line_ed.car_byte < #line_ed.lines[#line_ed.lines] + 1 then
					line_ed.input_category = false
				end

				-- Replace mode should not overwrite line feeds.
				local line = line_ed.lines[line_ed.car_line]
				if line_ed.car_byte > #line then
					suppress_replace = true
				end
			end

			local written = self:writeText(text, suppress_replace)
			self.update_flag = true

			local no_ws = string.find(written, "%S")
			local entry = hist:getEntry()
			local do_advance = true

			if (entry and entry.car_line == old_line and entry.car_byte == old_byte)
			and ((line_ed.input_category == "typing" and no_ws) or (line_ed.input_category == "typing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHistM.doctorCurrentCaretOffsets(line_ed.hist, old_line, old_byte, old_h_line, old_h_byte)
			end
			editHistM.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "typing" or "typing-ws"

			self:updateDocumentDimensions()
			self:scrollGetCaretInBounds(true)
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if self == inst then
		local line_ed = self.line_ed
		local disp = line_ed.disp
		local hist = line_ed.hist

		disp:resetCaretBlink()

		local input_intercepted = false

		if scancode == "application" then
			-- Locate caret in UI space
			local ax, ay = self:getAbsolutePosition()
			local caret_x = ax + self.vp_x - self.scr_x + disp.caret_box_x + self.align_offset
			local caret_y = ay + self.vp_y - self.scr_y + disp.caret_box_y + disp.caret_box_h

			lgcMenu.widgetConfigureMenuItems(self, self.pop_up_def)

			local root = self:getRootWidget()
			local lgcWimp = self.context:getLua("shared/lgc_wimp")
			local pop_up = lgcWimp.makePopUpMenu(self, self.pop_up_def, caret_x, caret_y)
			pop_up:tryTakeThimble2()

			-- Halt propagation
			return true
		end

		if input_intercepted then
			return true
		end

		local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()

		-- (LÖVE 12) if this key should behave differently when NumLock is disabled, swap out the scancode and key constant.
		if love_major >= 12 and keyMgr.scan_numlock[scancode] and not love.keyboard.isModifierActive("numlock") then
			scancode = keyMgr.scan_numlock[scancode]
			key = love.keyboard.getKeyFromScancode(scancode)
		end

		local bind_action = editBindM[hot_scan] or editBindM[hot_key]

		if bind_action then
			-- NOTE: most history ledger changes are handled in executeBoundAction().
			local ok, update_scroll, caret_in_view, write_history = self:executeBoundAction(bind_action)

			if ok then
				if update_scroll then
					self.update_flag = true
				end

				self:updateDocumentDimensions() -- XXX WIP
				self:scrollGetCaretInBounds(true) -- XXX WIP

				-- Stop event propagation
				return true
			end
		end
	end
end


--- Updates selection based on the position of the mouse and the number of repeat mouse-clicks.
local function mouseDragLogic(self)
	local context = self.context
	local line_ed = self.line_ed
	local disp = line_ed.disp

	local widget_needs_update = false

	disp:resetCaretBlink()

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


function def:uiCall_update(dt)
	local line_ed = self.line_ed
	local disp = line_ed.disp

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		if mouseDragLogic(self) then
			self.update_flag = true
		end
		if self.mouse_drag_x ~= 0 or self.mouse_drag_y ~= 0 then
			self:scrollDeltaHV(self.mouse_drag_x * dt * 4, self.mouse_drag_y * dt * 4) -- XXX style/config
			self.update_flag = true
		end
	end

	disp:updateCaretBlink(dt)


	if lgcScroll.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self.context.mouse_x, self.context.mouse_y
			local ax, ay = self:getAbsolutePosition()
			local button_step = 350 -- XXX style/config
			lgcScroll.widgetDragLogic(self, mx - ax, my - ay, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		self.update_flag = true
	end

	-- Update scroll bar registers and thumb position
	local scr_h = self.scr_h
	if scr_h then
		lgcScroll.updateRegisters(scr_h, math.floor(0.5 + self.scr_x), self.vp_w, self.doc_w)

		self.scr_h:updateThumb()
	end

	local scr_v = self.scr_v
	if scr_v then
		lgcScroll.updateRegisters(scr_v, math.floor(0.5 + self.scr_y), self.vp_h, self.doc_h)

		self.scr_v:updateThumb()
	end

	lgcScroll.updateScrollBarShapes(self)

	-- Update cache if necessary.
	if self.update_flag then
		self:cacheUpdate()
		self.update_flag = false
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Destroy pop-up menu if it exists in reference to this widget.
		local root = self:getRootWidget()
		if root.pop_up_menu and root.pop_up_menu.wid_ref == self then
			root:sendEvent("rootCall_destroyPopUp", self, "concluded")
		end
	end
end


def.default_skinner = {
	--validate = function(skin) -- TODO
	--transform = function(skin, scale) -- TODO


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin

		local line_ed = self.line_ed
		local lines = line_ed.lines
		local disp = line_ed.disp
		local font = disp.font

		local res = line_ed.allow_input and skin.res_readwrite or skin.res_readonly
		local has_thimble = self == self.context.thimble1

		-- XXX Debug renderer.
		--[[
		love.graphics.setColor(0, 0, 0, 0.90)
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		love.graphics.setColor(1, 1, 1, 1)
		local yy = 0
		for i, line in ipairs(self.line_ed.lines) do
			love.graphics.print(i .. ": " .. line, 16, yy)
			yy = yy + self.line_ed.disp.font:getHeight()
		end
		--]]

		local scx, scy, scw, sch = love.graphics.getScissor()
		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		--[[
		print("ox, oy", ox, oy)
		print("xy", self.x, self.y)
		print("vp", self.vp_x, self.vp_y, self.vp_w, self.vp_h)
		print("vp2", self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)
		--]]

		--print("render", "self.vis_para_top", self.vis_para_top, "self.vis_para_bot", self.vis_para_bot)

		-- Draw background body
		love.graphics.setColor(res.color_body)
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		-- ^ Variant with less overdraw?
		--love.graphics.rectangle("fill", disp.vp2_x, disp.vp2_y, disp.vp2_w, disp.vp2_h)

		-- Draw current paragraph illumination, if applicable.
		if self.illuminate_current_line then
			love.graphics.setColor(res.color_current_line_illuminate)
			local paragraph = disp.paragraphs[disp.d_car_para]
			local para_y = paragraph[1].y

			local last_sub = paragraph[#paragraph]
			local para_h = last_sub.y + last_sub.h - para_y

			love.graphics.rectangle("fill", self.vp2_x, self.vp_y - self.scr_y + para_y, self.vp2_w, para_h)
		end

		love.graphics.push()

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.vp_x + self.align_offset - self.scr_x, self.vp_y - self.scr_y)

		-- Draw highlight rectangles.
		if line_ed:isHighlighted() then
			local is_active = self:hasAnyThimble()
			local col_highlight = is_active and res.color_highlight_active or res.color_highlight
			love.graphics.setColor(col_highlight)

			for i = self.vis_para_top, self.vis_para_bot do
				local paragraph = disp.paragraphs[i]
				for j, sub_line in ipairs(paragraph) do
					if sub_line.highlighted then
						love.graphics.rectangle("fill", sub_line.x + sub_line.h_x, sub_line.y + sub_line.h_y, sub_line.h_w, sub_line.h_h)
					end
				end
			end
		end

		-- Draw ghost text, if applicable.
		-- XXX: center and right ghost text alignment modes aren't working correctly.
		if self.ghost_text and lines:isEmpty() then
			local align = self.ghost_text_align or disp.align

			love.graphics.setFont(skin.font_ghost)

			local gx, gy
			if align == "left" then
				gx, gy = 0, 0

			elseif align == "center" then
				gx, gy = math.floor(-font:getWidth(self.ghost_text) / 2), 0

			elseif align == "right" then
				gx, gy = math.floor(-font:getWidth(self.ghost_text)), 0
			end

			if disp.wrap_mode then
				love.graphics.printf(self.ghost_text, -self.align_offset, 0, self.vp_w, align)

			else
				love.graphics.print(self.ghost_text, gx, gy)
			end
		end

		-- Draw the main text.
		love.graphics.setColor(res.color_text)

		if self.text_object then
			love.graphics.draw(self.text_object)
		else
			love.graphics.setFont(skin.font)

			for i = self.vis_para_top, self.vis_para_bot do
				local paragraph = disp.paragraphs[i]
				for j, sub_line in ipairs(paragraph) do
					love.graphics.print(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
				end
			end
		end

		-- Draw the caret.
		if self.context.window_focus and has_thimble and disp.caret_is_showing then
			love.graphics.setColor(res.color_insert) -- XXX: color_replace
			love.graphics.rectangle(self.caret_fill, self.caret_x, self.caret_y, self.caret_w, self.caret_h)
		end

		love.graphics.setScissor(scx, scy, scw, sch)

		love.graphics.pop()

		lgcScroll.drawScrollBarsHV(self, skin.data_scroll)

		-- DEBUG: draw history state
		--[[
		love.graphics.push("all")

		love.graphics.pop()
		--]]

		--print("text box scr xy", self.scr_x, self.scr_y, "fx fy", self.scr_fx, self.scr_fy, "tx ty", self.scr_tx, self.scr_ty)
		--print("disp.caret_box_xywh", disp.caret_box_x, disp.caret_box_y, disp.caret_box_w, disp.caret_box_h)

		-- DEBUG: show editor details.
		--[[
		love.graphics.push("all")
		love.graphics.setScissor()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(
			"car_line:" .. line_ed.car_line .. "\n" ..
			"car_byte:" .. line_ed.car_byte .. "\n" ..
			"h_line:" .. line_ed.h_line .. "\n" ..
			"h_byte:" .. line_ed.h_byte,
			200, 200
		)
		love.graphics.pop()
		--]]


		--[[
		-- Old history debug-print
		love.graphics.push("all")

		local hist_x = 8
		local hist_y = 400
		qp:reset()
		qp:setOrigin(hist_x, hist_y)
		qp:print2("HISTORY STATE. i_cat:", wid_text_box.input_category)

		hist_y = qp:getYOrigin() + qp:getYPosition()

		for i, entry in ipairs(wid_text_box.line_ed.hist.ledger) do
			qp:reset()
			qp:setOrigin(hist_x, hist_y)

			if i == wid_text_box.line_ed.hist.pos then
				love.graphics.setColor(1, 1, 1, 1)
			else
				love.graphics.setColor(0.8, 0.8, 0.8, 1)
			end

			qp:print2("cl: ", entry.car_line)
			qp:print2("cb: ", entry.car_byte)
			qp:print2("hl: ", entry.h_line)
			qp:print2("hb: ", entry.h_byte)
			qp:down()

			for j, line in ipairs(entry.lines) do
				-- No point in printing hundreds (or thousands) of lines which can't be seen.
				if j > 10 then
					break
				end

				qp:print3(j, ": ", line)
			end

			hist_x = hist_x + 128
		end

		love.graphics.pop()
		--]]
	end,
}


return def
