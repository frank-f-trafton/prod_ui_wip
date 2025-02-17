--[[

A single-line text input box.

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

local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local editBindS = context:getLua("shared/line_ed/s/edit_bind_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "text_box_s1",
}


-- Override to make something happen when the user presses 'return' or 'kpenter' while the
-- widget is active and has keyboard focus.
def.wid_action = uiShared.dummyFunc -- args: (self)


widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text boxes.


lgcInputS.setupDef(def)


def.scrollGetCaretInBounds = lgcInputS.method_scrollGetCaretInBounds
def.updateDocumentDimensions = lgcInputS.method_updateDocumentDimensions
def.updateAlignOffset = lgcInputS.method_updateAlignOffset
def.pop_up_def = lgcInputS.pop_up_def


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupViewports(self, 2)

	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)

	self.press_busy = false

	lgcInputS.setupInstance(self)

	-- Highlights all text whenever this widget gets the thimble.
	self.select_all_on_thimble1_take = false

	-- Unhighlights all upon releasing the thimble (moving the caret to the first position).
	self.deselect_all_on_thimble1_release = false

	-- State flags.
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self.cursor_hover = self.skin.cursor_on

	self.line_ed = lineEdS.new(self.skin.font)

	lgcInputS.updateCaretShape(self)

	self:reshape()
end


function def:uiCall_reshape()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)
	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, skin.box.margin)

	self:scrollClampViewport()
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
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


function def:uiCall_thimble1Take(inst)
	if self == inst then
		love.keyboard.setTextInput(true)
		lgcInputS.resetCaretBlink(self)
		if self.select_all_on_thimble1_take then
			self:highlightAll()
			lgcInputS.updateCaretShape(self)
		end
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		love.keyboard.setTextInput(false)
		if self.deselect_all_on_thimble1_release then
			self:caretFirst(true)
			lgcInputS.updateCaretShape(self)
		end
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
			if scancode == "return" or scancode == "kpenter" then
				self:wid_action()
				return true
			else
				return lgcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
			end
		end
	end
end


function def:uiCall_update(dt)
	local line_ed = self.line_ed

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		local mouse_drag_x = lgcInputS.mouseDragLogic(self)
		if mouse_drag_x ~= 0 then
			self:scrollDeltaH(mouse_drag_x * dt * 4) -- XXX style/config
		end
	end

	lgcInputS.updateCaretBlink(self, dt)

	self:scrollUpdate(dt)
end


function def:uiCall_destroy(inst)
	if self == inst then
		commonWimp.checkDestroyPopUp(self)
	end
end


def.default_skinner = {
	--schema = {},


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local res = uiTheme.pickButtonResource(self, skin)
		local line_ed = self.line_ed

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
		local color_caret = self.replace_mode and res.color_caret_replace or res.color_caret_insert

		local is_active = self == self.context.thimble1
		local col_highlight = is_active and res.color_highlight_active or res.color_highlight

		lgcInputS.draw(
			self,
			col_highlight,
			skin.font_ghost,
			res.color_text,
			line_ed.font,
			self.context.window_focus and color_caret
		)

		love.graphics.pop()

		-- Debug (viewports)
		--[[
		widDebug.debugDrawViewport(self, 1)
		widDebug.debugDrawViewport(self, 2)
		--]]

		-- Debug renderer
		--[[
		love.graphics.print(
			"line: " .. line_ed.line
			.. "\n#line: " .. #line_ed.line
			.. "\ncar_byte: " .. line_ed.car_byte
			.. "\nh_byte: " .. line_ed.h_byte
			.. "\ncaret_is_showing: " .. tostring(self.caret_is_showing)
			.. "\ncaret_blink_time: " .. tostring(self.caret_blink_time)
			.. "\ncaret box: " .. line_ed.caret_box_x .. ", " .. line_ed.caret_box_y .. ", " .. line_ed.caret_box_w .. ", " .. line_ed.caret_box_h
			.. "\nscr_fx: " .. self.scr_fx .. ", scr_fy: " .. self.scr_fy
			--.. "\ndoc_w: " .. self.doc_w
			,
			0, 64
		)

		local yy, hh = 240, line_ed.font:getHeight()
		love.graphics.print("History state:", 0, 216)

		for i, entry in ipairs(line_ed.hist.ledger) do
			love.graphics.print(i .. " c: " .. entry.car_byte .. " h: " .. entry.h_byte .. "line: " .. entry.line, 0, yy)
			yy = yy + hh
		end
		--]]
	end,
}


return def
