-- A single-line text input box.

--[[
         Viewport #1
  ╔═════════════════════════╗
  ║                         ║

┌─────────────────────────────┐
│ The quick brown fox jumps   │
└─────────────────────────────┘

--]]


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)


-- ProdUI
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local wcInputS = context:getLua("shared/wc/wc_input_s")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcWimp = context:getLua("shared/wc/wc_wimp")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "text_box_s1",
}


-- Override to make something happen when the user presses 'return' or 'kpenter' while the
-- widget is active and has keyboard focus. Return true to halt further processing
-- (specifically, the logic to check if users typed literal newlines via 'return' and 'kpenter').
def.wid_action = uiDummy.func -- args: (self)


widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text boxes.


wcInputS.setupDef(def)


def.updateAlignOffset = wcInputS.method_updateAlignOffset -- XXX: method doesn't exist.
def.pop_up_proto = wcInputS.pop_up_proto


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)

	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)

	self.press_busy = false

	-- State flags.
	self.enabled = true
	self.hovered = false

	wcInputS.setupInstance(self, "single")

	self:skinSetRefs()
	self:skinInstall()

	self.LE:updateDisplayText()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)
	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	self:scrollClampViewport()

	editWidS.generalUpdate(self, true, true, false, true)

	return true
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true
			self.cursor_hover = self.skin.cursor_on
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
		end
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

		if self.vp2:pointOverlap(mx, my) then
			-- Propagation is halted when a context menu is created.
			if wcInputS.mousePressLogic(self, button, mx, my, had_thimble1_before) then
				return true
			end
		end
	end

	-- Allow propagation so that the root widget can destroy pop-up menus.
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			self.press_busy = false
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
		wcInputS.thimble1Take(self)
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		wcInputS.thimble1Release(self)
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		return wcInputS.textInputLogic(self, text)
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if self == inst then
		if self.enabled then
			if (scancode == "return" or scancode == "kpenter") and self:wid_action() then
				return true
			else
				return wcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
			end
		end
	end
end


function def:uiCall_update(dt)
	editWid.updateCaretBlink(self, dt)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local do_update

	if self.press_busy == "text-drag" then
		if wcInputS.mouseDragLogic(self) then
			do_update = true
		end
		if widShared.dragToScroll(self, dt) then
			do_update = true
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		do_update = true
	end

	if do_update then
		editWidS.generalUpdate(self, true, false, false, true)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		wcWimp.checkDestroyPopUp(self)

		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	slice = themeAssert.slice,

	color_body = uiAssert.loveColorTuple,
	color_text = uiAssert.loveColorTuple,
	color_highlight = uiAssert.loveColorTuple,
	color_highlight_active = uiAssert.loveColorTuple,
	color_caret_insert = uiAssert.loveColorTuple,
	color_caret_replace = uiAssert.loveColorTuple,
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		font = themeAssert.font,
		font_ghost = themeAssert.font,

		cursor_on = {uiAssert.types, "nil", "string"},
		text_align = {uiAssert.oneOf, "left", "center", "right"},
		text_align_v = {uiAssert.numberRange, 0.0, 1.0}, -- used by text input code

		res_idle = md_res,
		res_hover = md_res,
		res_disabled = md_res
	},


	--transform = function(scale, skin)


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		self.LE:setFont(self.skin.font)
		if self.LE_text_batch then
			self.LE_text_batch:setFont(self.skin.font)
		end
		self.LE:updateDisplayText()
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
		local res = uiTheme.pickButtonResource(self, skin)
		local LE = self.LE

		love.graphics.push("all")

		-- Body.
		local slc_body = res.slice
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

		uiGraphics.intersectScissor(
			ox + self.x + vp2.x,
			oy + self.y + vp2.y,
			vp2.w,
			vp2.h
		)

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.LE_align_oy - self.scr_y)

		-- Text editor component.
		local color_caret = self.LE_replace_mode and res.color_caret_replace or res.color_caret_insert

		local is_active = self == self.context.thimble1
		local col_highlight = is_active and res.color_highlight_active or res.color_highlight

		wcInputS.draw(
			self,
			col_highlight,
			skin.font_ghost,
			res.color_text,
			LE.font,
			self.context.window_focus and color_caret
		)

		love.graphics.pop()

		-- Debug renderer
		--[[
		love.graphics.print(
			"line: " .. LE.line
			.. "\n#line: " .. #LE.line
			.. "\ncb: " .. LE.cb
			.. "\nhb: " .. LE.hb
			.. "\nLE_caret_showing: " .. tostring(self.LE_caret_showing)
			.. "\nLE_caret_blink_time: " .. tostring(self.LE_caret_blink_time)
			.. "\ncaret box: " .. LE.caret_box_x .. ", " .. LE.caret_box_y .. ", " .. LE.caret_box_w .. ", " .. LE.caret_box_h
			.. "\nscr_fx: " .. self.scr_fx .. ", scr_fy: " .. self.scr_fy
			--.. "\ndoc_w: " .. self.doc_w
			.. "\ninput_category: " .. tostring(self.LE_input_category)
			,
			0, 64
		)

		local yy, hh = 240, LE.font:getHeight()
		love.graphics.print("History state:", 0, 216)

		for i, entry in ipairs(self.LE_hist.ledger) do
			love.graphics.print(i .. " c: " .. entry.cb .. " h: " .. entry.hb .. "line: " .. entry.line, 0, yy)
			yy = yy + hh
		end

		local vp = self.vp

		love.graphics.print(
			"LE_click_byte: " .. self.LE_click_byte
			.. "\nLE_align_ox: " .. self.LE_align_ox
			.. "\nscr: " .. self.scr_x .. ", " .. self.scr_y
			.. "\nvp #1: " .. vp.x .. ", " .. vp.y .. ", " .. vp.w .. ", " .. vp.h
			.. "\ndoc: " .. self.doc_w .. ", " .. self.doc_h
			,
			0, 448
		)
		--]]
	end,
}


return def
