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
│ .                       . ├─┤
│ ......................... │v│  ═══╗
├─┬───────────────────────┬─┼─┤     ╠═ Optional scroll bars
│<│                       │>│ │  ═══╝
└─┴───────────────────────┴─┴─┘

--]]


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)


-- ProdUI
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editHistM = context:getLua("shared/line_ed/m/edit_hist_m")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcInputM = context:getLua("shared/lgc_input_m")
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


def.scrollGetCaretInBounds = lgcInputM.method_scrollGetCaretInBounds
def.updateDocumentDimensions = lgcInputM.method_updateDocumentDimensions


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
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the scrollable region.
	-- Viewport #2 includes margins and excludes borders.

	local skin = self.skin
	local line_ed = self.line_ed

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

	lgcInputM.updatePageJumpSteps(self, line_ed.font)

	self.update_flag = true

	return true
end


--- Updates cached display state.
function def:cacheUpdate()
	local line_ed = self.line_ed
	local lines = line_ed.lines

	local skin = self.skin

	self:updateDocumentDimensions()

	editFuncM.updateCaretShape(self)
	editFuncM.updateVisibleParagraphs(self)

	if self.text_object then
		editFuncM.updateTextBatch(self)
	end
end


function def:uiCall_pointerHover(inst, mx, my, dx, dy)
	if self == inst then
		mx, my = self:getRelativePosition(mx, my)

		lgcScroll.widgetProcessHover(self, mx, my)

		if widShared.pointInViewport(self, 2, mx, my) then
			self.cursor_hover = self.skin.cursor_on
		else
			self.cursor_hover = nil
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mx, my, dx, dy)
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

		local mx, my = self:getRelativePosition(x, y)
		local handled = false

		-- Check for pressing on scroll bar components.
		if button == 1 then
			local fixed_step = 24 -- XXX style/config

			handled = lgcScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Successful mouse interaction with scroll bars should break any existing click-sequence.
		if handled then
			self.context:forceClickSequence(false, button, 1)

		elseif widShared.pointInViewport(self, 2, mx, my) then
			if lgcInputM.mousePressLogic(self, x, y, button, istouch, presses) then
				-- Propagation is halted when a context menu is created.
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

	lgcInputM.mouseWheelLogic(self, x, y)

	-- stop bubbling
	return true
end


function def:uiCall_thimble1Take(inst)
	if self == inst then
		love.keyboard.setTextInput(true)
		lgcInputM.resetCaretBlink(self.line_ed)
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		love.keyboard.setTextInput(false)
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		lgcInputM.textInputLogic(self, text)
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if self == inst then
		return lgcInputM.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
	end
end


function def:uiCall_update(dt)
	local line_ed = self.line_ed

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		if lgcInputM.mouseDragLogic(self) then
			self.update_flag = true
		end
		if widShared.dragToScroll(self, dt) then
			self.update_flag = true
		end
	end

	lgcInputM.updateCaretBlink(line_ed, dt)

	if lgcScroll.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
			local button_step = 350 -- XXX style/config
			lgcScroll.widgetDragLogic(self, mx, my, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		self.update_flag = true
	end

	-- update scroll bar registers and thumb position
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)

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
		self.line_ed:setFont(self.skin.font)
		self.text_object:setFont(self.skin.font)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
		self.line_ed:setFont()
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin

		local line_ed = self.line_ed
		local lines = line_ed.lines
		local font = line_ed.font

		local res = self.allow_input and skin.res_readwrite or skin.res_readonly
		local has_thimble = self == self.context.thimble1

		-- XXX Debug renderer.
		--[[
		love.graphics.setColor(0, 0, 0, 0.90)
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		love.graphics.setColor(1, 1, 1, 1)
		local yy = 0
		for i, line in ipairs(self.line_ed.lines) do
			love.graphics.print(i .. ": " .. line, 16, yy)
			yy = yy + self.line_ed.font:getHeight()
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
		--love.graphics.rectangle("fill", self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)

		love.graphics.push()

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.vp_x + self.align_offset - self.scr_x, self.vp_y - self.scr_y)

		-- Draw highlight rectangles.
		if line_ed:isHighlighted() then
			local is_active = self:hasAnyThimble()
			local col_highlight = is_active and res.color_highlight_active or res.color_highlight
			love.graphics.setColor(col_highlight)

			for i = self.vis_para_top, self.vis_para_bot do
				local paragraph = line_ed.paragraphs[i]
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
			local align = self.ghost_text_align or line_ed.align

			love.graphics.setFont(skin.font_ghost)

			local gx, gy
			if align == "left" then
				gx, gy = 0, 0

			elseif align == "center" then
				gx, gy = math.floor(-font:getWidth(self.ghost_text) / 2), 0

			elseif align == "right" then
				gx, gy = math.floor(-font:getWidth(self.ghost_text)), 0
			end

			if line_ed.wrap_mode then
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
				local paragraph = line_ed.paragraphs[i]
				for j, sub_line in ipairs(paragraph) do
					love.graphics.print(sub_line.colored_text or sub_line.str, sub_line.x, sub_line.y)
				end
			end
		end

		-- Draw the caret.
		if self.context.window_focus and has_thimble and line_ed.caret_is_showing then
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
		--print("line_ed.caret_box_xywh", line_ed.caret_box_x, line_ed.caret_box_y, line_ed.caret_box_w, line_ed.caret_box_h)

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
