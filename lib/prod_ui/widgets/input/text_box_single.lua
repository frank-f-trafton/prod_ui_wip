--[[

A single-line text input box.

         Viewport #1
  +-------------------------+
  |                         |

+-----------------------------+
| The quick brown fox jumps   |
+-----------------------------+

--]]


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)

local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonWimp = require(context.conf.prod_ui_req .. "logic.common_wimp")
local editBindS = context:getLua("shared/line_ed/s/edit_bind_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local keyCombo = require(context.conf.prod_ui_req .. "lib.key_combo")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lineEdSingle = context:getLua("shared/line_ed/s/line_ed_s")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


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


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		widShared.setupScroll(self)
		widShared.setupDoc(self)

		self.press_busy = false

		lgcInputS.setupInstance(self)

		-- State flags.
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin

		self.line_ed = lineEdSingle.new(skin.font)

		self:reshape()
	end
end


function def:uiCall_reshape()

	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the scissor-box boundary.

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, "margin")

	self:scrollClampViewport()

	self.update_flag = true
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		if self.enabled then
			self.hovered = true
			self:setCursorLow(self.skin.cursor_on)
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		if self.enabled then
			self.hovered = false
			self:setCursorLow()
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble()
		end

		local mx, my = self:getRelativePosition(x, y)

		if widShared.pointInViewport(self, 2, mx, my) then
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my) then
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


function def:uiCall_pointerDrag(inst, x, y, dx, dy)
	return true
end


function def:uiCall_thimbleTake(inst)

	if self == inst then
		love.keyboard.setTextInput(true)
	end
end


function def:uiCall_thimbleRelease(inst)

	if self == inst then
		love.keyboard.setTextInput(false)
	end
end


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)

	if self == inst then
		if self.enabled then
			self:wid_action()
		end
	end
end


function def:uiCall_textInput(inst, text)

	if self == inst then
		lgcInputS.textInputLogic(self, text)
	end
end



function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

	if self == inst then
		return lgcInputS.keyPressLogic(self, key, scancode, isrepeat)
	end
end


local function mouseDragLogic(self)

	local line_ed = self.line_ed

	local widget_needs_update = false

	if self.press_busy == "text-drag" then

		local context = self.context

		line_ed:resetCaretBlink()

		-- Mouse position relative to viewport #1.
		local ax, ay = self:getAbsolutePosition()
		local mx, my = self.context.mouse_x - ax - self.vp_x, self.context.mouse_y - ay - self.vp_y

		-- ...And with scroll offsets applied.
		local s_mx = mx + self.scr_x - self.align_offset
		local s_my = my + self.scr_y

		--print("s_mx", s_mx, "s_my", s_my, "scr_x", self.scr_x, "scr_y", self.scr_y)

		-- Handle drag highlight actions
		if context.cseq_presses == 1 then
			self:caretToX(false, s_mx, true)
			widget_needs_update = true

		elseif context.cseq_presses == 2 then
			self:clickDragByWord(s_mx, self.click_byte)
			widget_needs_update = true
		end
		-- cseq_presses == 3: selecting whole line (nothing to do at drag-time).

		-- Amount to drag for the update() callback (to be scaled down and multiplied by dt).
		self.mouse_drag_x = (mx < 0) and mx or (mx >= self.vp_w) and mx - self.vp_w or 0
	end

	return widget_needs_update
end


function def:uiCall_update(dt)

	local line_ed = self.line_ed

	local scr_x_old = self.scr_x

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		if mouseDragLogic(self) then
			self.update_flag = true
		end
		if self.mouse_drag_x ~= 0 then
			self:scrollDeltaH(self.mouse_drag_x * dt * 4) -- XXX style/config
			self.update_flag = true
		end
	end

	line_ed:updateCaretBlink(dt)

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x then
		self.update_flag = true
	end

	if self.update_flag then

		-- Update caret shape.
		self.caret_x = line_ed.caret_box_x
		self.caret_y = line_ed.caret_box_y
		self.caret_w = line_ed.caret_box_w
		self.caret_h = line_ed.caret_box_h

		if line_ed.replace_mode then
			self.caret_fill = "line"

		else
			self.caret_fill = "fill"
			self.caret_w = line_ed.caret_line_width
		end

		self.update_flag = false
	end
end


function def:uiCall_destroy(inst)

	if self == inst then
		-- Destroy pop-up menu if it exists in reference to this widget.
		local root = self:getTopWidgetInstance()
		if root.pop_up_menu then
			root:runStatement("rootCall_destroyPopUp", self, "concluded")
			root:runStatement("rootCall_restoreThimble", self)
		end
	end
end


def.skinners = {
	default = {
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

			love.graphics.translate(
				self.vp_x + self.align_offset - self.scr_x,
				self.vp_y - self.scr_y
			)

			-- Highlighted selection.
			if line_ed.disp_highlighted then
				love.graphics.setColor(res.color_highlight)
				love.graphics.rectangle(
					"fill",
					line_ed.highlight_x,
					line_ed.highlight_y,
					line_ed.highlight_w,
					line_ed.highlight_h
				)
			end

			-- Ghost text. XXX: alignment
			if self.ghost_text and #line_ed.line == 0 then
				love.graphics.setFont(skin.font_ghost)
				love.graphics.print(self.ghost_text, 0, 0)
			end

			-- Display Text.
			love.graphics.setColor(res.color_text)
			love.graphics.setFont(line_ed.font)
			love.graphics.print(line_ed.disp_text)

			-- Caret.
			if self == self.context.current_thimble and line_ed.caret_is_showing then
				love.graphics.setColor(skin.color_insert) -- XXX: color_replace
				love.graphics.rectangle(
					self.caret_fill,
					self.caret_x,
					self.caret_y,
					self.caret_w,
					self.caret_h
				)
			end

			love.graphics.pop()

			-- Debug renderer.
			-- [[
			love.graphics.print(
				"line: " .. line_ed.line
				.. "\n#line: " .. #line_ed.line
				.. "\ncar_byte: " .. line_ed.car_byte
				.. "\nh_byte: " .. line_ed.h_byte
				.. "\ncaret_is_showing: " .. tostring(line_ed.caret_is_showing)
				.. "\ncaret_blink_time: " .. tostring(line_ed.caret_blink_time)
				.. "\ncaret box: " .. line_ed.caret_box_x .. ", " .. line_ed.caret_box_y .. ", " .. line_ed.caret_box_w .. ", " .. line_ed.caret_box_h
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
	},
}


return def
