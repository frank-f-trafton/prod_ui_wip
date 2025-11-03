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
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidM = context:getLua("shared/line_ed/m/edit_wid_m")
local lgcInputM = context:getLua("shared/lgc_input_m")
local lgcScroll = context:getLua("shared/lgc_scroll")
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "text_box_m1",
	renderThimble = uiDummy.func
}


lgcInputM.setupDef(def)


widShared.scrollSetMethods(def)
def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")
def.pop_up_proto = lgcInputM.pop_up_proto


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

	lgcInputM.setupInstance(self, "multi")

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the scrollable region.
	-- Viewport #2 includes margins and excludes borders.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	lgcScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	self:scrollClampViewport()
	lgcScroll.updateScrollState(self)

	editWidM.updateDuringReshape(self)

	return true
end


function def:uiCall_pointerHover(inst, mx, my, dx, dy)
	if self == inst then
		mx, my = self:getRelativePosition(mx, my)

		lgcScroll.widgetProcessHover(self, mx, my)

		if self.vp2:pointOverlap(mx, my) then
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

		elseif self.vp2:pointOverlap(mx, my) then
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

		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	color_body = uiAssert.loveColorTuple,
	color_highlight = uiAssert.loveColorTuple,
	color_highlight_active = uiAssert.loveColorTuple,
	color_text = uiAssert.loveColorTuple,
	color_readonly = uiAssert.loveColorTuple,
	color_ghost_text = uiAssert.loveColorTuple,
	color_insert = uiAssert.loveColorTuple,
	color_replace = uiAssert.loveColorTuple,
	color_margin = uiAssert.loveColorTuple,
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
		local vp2 = self.vp2
		local LE = self.LE
		local lines = LE.lines
		local font = LE.font

		local res = self.LE_allow_input and skin.res_readwrite or skin.res_readonly
		local has_thimble = self == self.context.thimble1

		-- XXX Debug renderer.
		--[[
		love.graphics.setColor(0, 0, 0, 0.90)
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		love.graphics.setColor(1, 1, 1, 1)
		local yy = 0
		for i, line in ipairs(self.LE.lines) do
			love.graphics.print(i .. ": " .. line, 16, yy)
			yy = yy + self.LE.font:getHeight()
		end
		--]]

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

		love.graphics.push()

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.scr_y)

		local col_highlight = self:hasAnyThimble() and res.color_highlight_active or res.color_highlight
		local color_caret = self.context.window_focus and res.color_insert -- XXX and color_replace
		lgcInputM.draw(self, col_highlight, skin.font_ghost, res.color_text, skin.font, color_caret)

		love.graphics.setScissor(scx, scy, scw, sch)

		love.graphics.pop()

		lgcScroll.drawScrollBarsHV(self, skin.data_scroll)

		-- Debug: document dimensions
		--[[
		love.graphics.push("all")
		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.setLineWidth(0.5)
		love.graphics.rectangle("line", -self.scr_x, -self.scr_y, self.doc_w, self.doc_h)
		love.graphics.pop()
		--]]

		--[[
		-- Debug: history state
		local qp = self.DEBUG_qp
		if qp then
			love.graphics.push("all")
			love.graphics.setScissor()
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.setFont(self.LE.font)

			local hist = self.LE_hist

			local hist_x = 8
			local hist_y = 400
			qp:reset()
			qp:setOrigin(hist_x, hist_y)
			qp:print("History Ledger. pos: ", hist.pos, " i_cat: ", self.LE_input_category)

			hist_y = qp:getYOrigin() + qp:getYPosition()

			for i, entry in ipairs(hist.ledger) do
				qp:reset()
				qp:setOrigin(hist_x, hist_y)

				if i == hist.pos then
					love.graphics.setColor(1, 1, 1, 1)
				else
					love.graphics.setColor(0.8, 0.8, 0.8, 1)
				end

				qp:write("pos ", i, " CL ", entry.cl, " CB ", entry.cb, " HL ", entry.hl, " HB ", entry.hb)
				qp:down()

				for j, line in ipairs(entry.lines) do
					-- No point in printing hundreds (or thousands) of lines which can't be seen.
					if j > 3 then
						break
					end

					qp:print(j, ": ", line)
				end

				hist_y = hist_y + self.LE.font:getHeight() * 5
			end
			love.graphics.pop()
		end
		--]]
	end,
}


return def
