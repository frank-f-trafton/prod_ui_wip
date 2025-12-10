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
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcInputM = context:getLua("shared/wc/wc_input_m")
local wcScrollBar = context:getLua("shared/wc/wc_scroll_bar")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "text_script1",
	renderThimble = uiDummy.func
}


wcInputM.setupDef(def)


widShared.scrollSetMethods(def)
def.setScrollBars = wcScrollBar.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")
def.pop_up_proto = wcInputM.pop_up_proto


local _nm_illuminate_mode = uiTable.newNamedMapV("IlluminateMode", "never", "always", "no-highlight")


function def:setIlluminateCurrentLine(mode)
	uiAssert.namedMap(1, mode, _nm_illuminate_mode)

	self.illuminate_current_line = mode

	return self
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)
	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)

	self.press_busy = false

	-- State flags (WIP)
	self.enabled = true

	wcInputM.setupInstance(self, "script")

	self.illuminate_current_line = "always"

	self:skinSetRefs()
	self:skinInstall()
end


function def:evt_reshapePre()
	-- Viewport #1 is the scrollable region.
	-- Viewport #2 includes margins and excludes borders.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	wcScrollBar.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	self:scrollClampViewport()
	wcScrollBar.updateScrollState(self)

	editWidM.updateDuringReshape(self)

	return true
end


function def:evt_pointerHover(targ, mx, my, dx, dy)
	if self == targ then
		mx, my = self:getRelativePosition(mx, my)

		wcScrollBar.widgetProcessHover(self, mx, my)

		if self.vp2:pointOverlap(mx, my) then
			self.cursor_hover = self.skin.cursor_on
		else
			self.cursor_hover = nil
		end
	end
end


function def:evt_pointerHoverOff(targ, mx, my, dx, dy)
	if self == targ then
		wcScrollBar.widgetClearHover(self)

		self.cursor_hover = nil
	end
end


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ
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

			handled = wcScrollBar.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Successful mouse interaction with scroll bars should break any existing click-sequence.
		if handled then
			self.context:forceClickSequence(false, button, 1)

		elseif self.vp2:pointOverlap(mx, my) then
			-- Propagation is halted when a context menu is created.
			if wcInputM.mousePressLogic(self, button, mx, my, had_thimble1_before) then
				return true
			end
		end
	end

	-- Allow propagation so that the root widget can destroy pop-up menus.
end


function def:evt_pointerPressRepeat(targ, x, y, button, istouch, reps)
	if self == targ then
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- XXX style/config

			wcScrollBar.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function def:evt_pointerUnpress(targ, x, y, button, istouch, presses)
	if self == targ then
		if button == 1 and button == self.context.mouse_pressed_button then
			wcScrollBar.widgetClearPress(self)

			self.press_busy = false
		end
	end
end


function def:evt_pointerWheel(targ, x, y)
	if self == targ then
		if widShared.checkScrollWheelScroll(self, x, y) then
			return true
		end
	end
end


function def:evt_thimbleTopTake(targ)
	if self == targ then
		love.keyboard.setTextInput(true)
	end
end


function def:evt_thimbleTopRelease(targ)
	if self == targ then
		love.keyboard.setTextInput(false)
	end
end


function def:evt_thimble1Take(targ)
	if self == targ then
		wcInputM.thimble1Take(self)
	end
end


function def:evt_thimble1Release(targ)
	if self == targ then
		wcInputM.thimble1Release(self)
	end
end


function def:evt_textInput(targ, text)
	if self == targ then
		wcInputM.textInputLogic(self, text)
	end
end


function def:evt_keyPressed(targ, key, scancode, isrepeat, hot_key, hot_scan)
	if self == targ then
		return wcInputM.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
	end
end


function def:evt_update(dt)
	editWid.updateCaretBlink(self, dt)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local do_update

	if self.press_busy == "text-drag" then
		if wcInputM.mouseDragLogic(self) then
			do_update = true
		end
		if widShared.dragToScroll(self, dt) then
			do_update = true
		end
	end

	if wcScrollBar.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
			local button_step = 350 -- XXX style/config
			wcScrollBar.widgetDragLogic(self, mx, my, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		do_update = true
	end

	-- update scroll bar registers and thumb position
	wcScrollBar.updateScrollBarShapes(self)
	wcScrollBar.updateScrollState(self)

	if do_update then
		editWidM.generalUpdate(self, true, false, false, true, true)
	end
end


function def:evt_destroy(targ)
	if self == targ then
		-- Destroy pop-up menu if it exists in reference to this widget.
		local root = self:nodeGetRoot()
		if root.pop_up_menu and root.pop_up_menu.wid_ref == self then
			root:destroyPopUp("concluded")
		end

		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	color_body = uiAssert.loveColorTuple,
	color_current_line_illuminate = uiAssert.loveColorTuple,
	color_highlight = uiAssert.loveColorTuple,
	color_highlight_active = uiAssert.loveColorTuple,
	color_text = uiAssert.loveColorTuple,
	color_readonly = uiAssert.loveColorTuple,
	color_ghost_text = uiAssert.loveColorTuple,
	color_insert = uiAssert.loveColorTuple,
	color_replace = uiAssert.loveColorTuple,
	color_margin = uiAssert.loveColorTuple,
	color_margin_line_numbers = uiAssert.loveColorTuple
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		data_scroll = themeAssert.scrollBarData,
		scr_style = themeAssert.scrollBarStyle,
		font = themeAssert.font,
		font_ghost = themeAssert.font,

		cursor_on = {uiAssert.types, "nil", "string"},
		paragraph_pad = {uiAssert.integerGE, 0},

		res_readwrite = md_res,
		res_readonly = md_res
	},


	--transform = function(scale, skin)


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
		local vp, vp2 = self.vp, self.vp2
		local LE = self.LE
		local lines = LE.lines
		local font = LE.font

		local res = self.LE_allow_input and skin.res_readwrite or skin.res_readonly
		local has_thimble = self == self.context.thimble1

		local scx, scy, scw, sch = love.graphics.getScissor()
		uiGraphics.intersectScissor(
			ox + self.x + vp2.x,
			oy + self.y + vp2.y,
			vp2.w,
			vp2.h
		)

		-- Draw background body
		love.graphics.setColor(res.color_body)
		-- TODO: replace with a texture slice.
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		-- ^ Variant with less overdraw?
		--love.graphics.rectangle("fill", vp2.x, vp2.y, vp2.w, vp2.h)

		-- Draw current paragraph illumination, if applicable.
		if self.illuminate_current_line == "always"
		or (self.illuminate_current_line == "no-highlight" and not LE:isHighlighted())
		then
			love.graphics.setColor(res.color_current_line_illuminate)
			local paragraph = LE.paragraphs[LE.dcp]
			local para_y = paragraph[1].y

			local last_sub = paragraph[#paragraph]
			local para_h = last_sub.y + last_sub.h - para_y

			love.graphics.rectangle("fill", vp2.x, -self.scr_y + para_y, vp2.w, para_h)
		end

		love.graphics.push()

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.scr_y)

		local col_highlight = self:hasAnyThimble() and res.color_highlight_active or res.color_highlight
		local color_caret = self.context.window_focus and res.color_insert -- XXX and color_replace
		wcInputM.draw(self, col_highlight, skin.font_ghost, res.color_text, skin.font, color_caret)

		love.graphics.setScissor(scx, scy, scw, sch)

		love.graphics.pop()

		wcScrollBar.drawScrollBarsHV(self, skin.data_scroll)
	end,
}


return def
