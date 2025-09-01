-- A more advanced multi-line text input widget, with a column for line numbers (TODO) and a faint highlight for the
-- current line.

--[[

Line #s    Viewport #1
 ╔══╗╔═════════════════════╗
 ┌──┬────────────────────────┬─┐
 │ 1│ ...................... │^│
 │ 2│ .The quick brown fox . ├─┤
 │ 3│ .jumps over the lazy . │ │
 │ 4│ .dog.|               . │ │
 │ 5│ .                    . │ │
 │ 6│ .                    . │ │
 │ 7│ .                    . │ │
 │ 8│ .                    . ├─┤
 │ 9│ ...................... │v│  ═══╗
 ├─┬┴──────────────────────┬─┼─┤     ╠═ Optional scroll bars
 │<│                       │>│ │  ═══╝
 └─┴───────────────────────┴─┴─┘

--]]


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)


-- ProdUI
local editFuncM = context:getLua("shared/line_ed/m/edit_func_m")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidM = context:getLua("shared/line_ed/m/edit_wid_m")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcInputM = context:getLua("shared/lgc_input_m")
local lgcScroll = context:getLua("shared/lgc_scroll")
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "text_script1",
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

	lgcInputM.setupInstance(self, "script")

	self.illuminate_current_line = true

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the scrollable region.
	-- Viewport #2 includes margins and excludes borders.

	local skin = self.skin

	widShared.resetViewport(self, 1)

	widShared.carveViewport(self, 1, skin.box.border)
	lgcScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	widShared.carveViewport(self, 1, skin.box.margin)

	self:scrollClampViewport()
	lgcScroll.updateScrollState(self)

	editWidM.updateDuringReshape(self)

	return true
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
		local had_thimble1_before = self == self.context.thimble1
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
			-- Propagation is halted when a context menu is created.
			if lgcInputM.mousePressLogic(self, button, mx, my, had_thimble1_before) then
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
	if self == inst then
		if widShared.checkScrollWheelScroll(self, x, y) then
			return true
		end
	end
end


function def:uiCall_thimbleTopTake(inst)
	if self == inst then
		love.keyboard.setTextInput(true)
	end
end


function def:uiCall_thimbleTopRelease(inst)
	if self == inst then
		love.keyboard.setTextInput(false)
	end
end


function def:uiCall_thimble1Take(inst)
	if self == inst then
		lgcInputM.thimble1Take(self)
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		lgcInputM.thimble1Release(self)
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
	editWid.updateCaretBlink(self, dt)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local do_update

	if self.press_busy == "text-drag" then
		if lgcInputM.mouseDragLogic(self) then
			do_update = true
		end
		if widShared.dragToScroll(self, dt) then
			do_update = true
		end
	end

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
		do_update = true
	end

	-- update scroll bar registers and thumb position
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)

	if do_update then
		editWidM.generalUpdate(self, true, false, false, true, true)
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


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)

	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_current_line_illuminate")
	check.colorTuple(res, "color_highlight")
	check.colorTuple(res, "color_highlight_active")
	check.colorTuple(res, "color_text")
	check.colorTuple(res, "color_readonly")
	check.colorTuple(res, "color_ghost_text")
	check.colorTuple(res, "color_insert")
	check.colorTuple(res, "color_replace")
	check.colorTuple(res, "color_margin")
	check.colorTuple(res, "color_margin_line_numbers")

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.scrollBarData(skin, "data_scroll")
		check.scrollBarStyle(skin, "scr_style")
		check.loveType(skin, "font", "Font")
		check.loveType(skin, "font_ghost", "Font")

		check.type(skin, "cursor_on", "nil", "string")
		check.integer(skin, "paragraph_pad", 0, nil)

		_checkRes(skin, "res_readwrite")
		_checkRes(skin, "res_readonly")
	end,


	--transform = function(skin, scale)


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		self.LE:setFont(skin.font)
		if self.LE_text_batch then
			self.LE_text_batch:setFont(skin.font)
		end
		self.LE:setParagraphPadding(skin.paragraph_pad)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
		self.LE:setFont()
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin

		local LE = self.LE
		local lines = LE.lines
		local font = LE.font

		local res = self.LE_allow_input and skin.res_readwrite or skin.res_readonly
		local has_thimble = self == self.context.thimble1

		local scx, scy, scw, sch = love.graphics.getScissor()
		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		-- Draw background body
		love.graphics.setColor(res.color_body)
		-- TODO: replace with a texture slice.
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		-- ^ Variant with less overdraw?
		--love.graphics.rectangle("fill", self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)

		-- Draw current paragraph illumination, if applicable.
		if self.illuminate_current_line then
			love.graphics.setColor(res.color_current_line_illuminate)
			local paragraph = LE.paragraphs[LE.dcp]
			local para_y = paragraph[1].y

			local last_sub = paragraph[#paragraph]
			local para_h = last_sub.y + last_sub.h - para_y

			love.graphics.rectangle("fill", self.vp2_x, self.vp_y - self.scr_y + para_y, self.vp2_w, para_h)
		end

		love.graphics.push()

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.scr_y)

		local col_highlight = self:hasAnyThimble() and res.color_highlight_active or res.color_highlight
		local color_caret = self.context.window_focus and res.color_insert -- XXX and color_replace
		lgcInputM.draw(self, col_highlight, skin.font_ghost, res.color_text, skin.font, color_caret)

		love.graphics.setScissor(scx, scy, scw, sch)

		love.graphics.pop()

		lgcScroll.drawScrollBarsHV(self, skin.data_scroll)
	end,
}


return def
