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
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "text_box_s1",
}


-- Override to make something happen when the user presses 'return' or 'kpenter' while the
-- widget is active and has keyboard focus. Return true to halt further processing
-- (specifically, the logic to check if users typed literal newlines via 'return' and 'kpenter').
def.wid_action = uiShared.dummyFunc -- args: (self)


widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text boxes.


lgcInputS.setupDef(def)


def.updateAlignOffset = lgcInputS.method_updateAlignOffset -- XXX: method doesn't exist.
def.pop_up_def = lgcInputS.pop_up_def


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

	lgcInputS.setupInstance(self)

	self:skinSetRefs()
	self:skinInstall()

	self.LE:updateDisplayText()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)
	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, skin.box.margin)

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

		if widShared.pointInViewport(self, 2, mx, my) then
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my, had_thimble1_before) then
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
		lgcInputS.thimble1Take(self)
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		lgcInputS.thimble1Release(self)
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		return lgcInputS.textInputLogic(self, text)
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if self == inst then
		if self.enabled then
			if (scancode == "return" or scancode == "kpenter") and self:wid_action() then
				return true
			else
				return lgcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
			end
		end
	end
end


function def:uiCall_update(dt)
	local LE = self.LE

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		local mouse_drag_x = lgcInputS.mouseDragLogic(self)
		if mouse_drag_x ~= 0 then
			self:scrollDeltaH(mouse_drag_x * dt * 4) -- XXX style/config
		end
	end

	editWidS.updateCaretBlink(self, dt)

	self:scrollUpdate(dt)
end


function def:uiCall_destroy(inst)
	if self == inst then
		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		lgcWimp.checkDestroyPopUp(self)
	end
end


def.default_skinner = {
	--validate = function(skin) -- TODO
	--transform = function(skin, scale) -- TODO


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
		local res = uiTheme.pickButtonResource(self, skin)
		local LE = self.LE

		love.graphics.push("all")

		-- Body.
		local slc_body = res.slice
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		-- Text editor component.
		local color_caret = self.LE_replace_mode and res.color_caret_replace or res.color_caret_insert

		local is_active = self == self.context.thimble1
		local col_highlight = is_active and res.color_highlight_active or res.color_highlight

		lgcInputS.draw(
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
		--]]
	end,
}


return def
