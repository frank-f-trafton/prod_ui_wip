
-- XXX: Under construction. Combination of `wimp/dropdown_box.lua` and `input/text_box_single.lua`.
-- XXX: Support commas for decimal place indicator
--[[

A single-line text box with controls for incrementing and decrementing numeric values.

┌─────────────────┬───┐
│ ═╗              │ + │ -- Increment value (or press up-arrow)
│  ║              ├───┤
│ ═╩═             │ - │ -- Decrement value (or press down-arrow)
└─────────────────┴───┘

Important: The internal value can be boolean false when the text input is empty or partially complete (-.).
--]]


local context = select(1, ...)


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonWimp = require(context.conf.prod_ui_req .. "logic.common_wimp")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lineEdSingle = context:getLua("shared/line_ed/s/line_ed_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "logic.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "number_box1",
}


def.click_repeat_oob = true -- for the inc/dec buttons


widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text inputs.


lgcInputS.setupDef(def)


def.scrollGetCaretInBounds = lgcInputS.method_scrollGetCaretInBounds
def.updateDocumentDimensions = lgcInputS.method_updateDocumentDimensions
def.updateAlignOffset = lgcInputS.method_updateAlignOffset
def.pop_up_def = lgcInputS.pop_up_def


def.arrange = commonMenu.arrangeListVerticalTB


def.movePrev = commonMenu.widgetMovePrev
def.moveNext = commonMenu.widgetMoveNext
def.moveFirst = commonMenu.widgetMoveFirst
def.moveLast = commonMenu.widgetMoveLast


-- Called when the user presses 'enter'
def.wid_action = uiShared.dummyFunc


-- For partial input.
local function _decimalStringOK(s)
	return s:match("%-?%d*%.?%d*") == s
end


-- For assigned input -- must be a full number.
local function _decimalStringOKFull(s)
	return s:match("%-?%d*%.?%d*") == s and s ~= "-" and s ~= "." and s ~= "-."
end


local function _checkDecimal(self)
	return _decimalStringOK(self.line_ed.line)
end


--- Callback for a change in the NumberBox state.
function def:wid_inputChanged(text)
	-- ...
end


--- Callbacks that control the amount of addition and subtraction of the internal value.
-- @param v The current value
-- @param r Number of iterations for held buttons (ie mouse-repeat)
-- @return The new value to assign.
function def:wid_incrementButton(v, r) return v + 1 end
function def:wid_decrementButton(v, r) return v - 1 end
function def:wid_incrementArrowKey(v, r) return v + 1 end
function def:wid_decrementArrowKey(v, r) return v - 1 end
function def:wid_incrementPageKey(v, r) return v + 10 end
function def:wid_decrementPageKey(v, r) return v - 10 end


--- Gets the internal numeric value.
function def:getInternalValue()
	return self.value
end


--- Gets the internal text string (which may not correspond exactly to the internal value).
function def:getInternalText()
	return self.line_ed.line
end


--- Gets the display text string (which may not correspond exactly to the internal value, and which may be modified
--  to show different characters from the internal text).
function def:getDisplayText()
	return self.line_ed.disp_text
end


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)
		widShared.setupViewport(self, 3)

		widShared.setupScroll(self)
		widShared.setupDoc(self)

		lgcInputS.setupInstance(self)

		-- The internal value.
		self.value_default = 0
		self.value = self.value_default
		self.value_min = -math.huge
		self.value_max = math.huge
		-- XXX: formatting support (rigid increments, decimals, etc.)

		-- repeat mouse-press state
		self.repeat_btn = 1 -- -1 for decrement, 1 for increment

		-- repeat key state
		self.rep_sc = false
		self.rep_sc_count = 0

		-- State flags
		self.enabled = true
		self.hovered = false

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin

		self.line_ed = lineEdSingle.new(skin.font)

		self:reshape()
	end
end


function def:uiCall_reshape()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.
	-- Viewport #3 is the increment button.
	-- Viewport #4 is the decrement button.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")

	local button_spacing = (skin.button_spacing == "auto") and self.vp_h or skin.button_spacing
	widShared.partitionViewport(self, 1, 3, button_spacing, skin.button_placement, false)
	if skin.button_alignment == "vertical" then
		widShared.partitionViewport(self, 3, 4, self.vp3_h / 2, "bottom", false)
	else
		widShared.partitionViewport(self, 3, 4, self.vp3_w / 2, "left", false)
	end

	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, "margin")
end


function def:uiCall_update(dt)
	local line_ed = self.line_ed
	local scr_x_old = self.scr_x

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		local needs_update, mouse_drag_x = lgcInputS.mouseDragLogic(self)
		if needs_update then
			self.update_flag = true
		end
		if mouse_drag_x ~= 0 then
			self:scrollDeltaH(mouse_drag_x * dt * 4) -- XXX style/config
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
		lgcInputS.updateCaretShape(self)
		self.update_flag = false
	end
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
			--self:wid_action() -- XXX
		end
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		commonWimp.checkDestroyPopUp(self)
	end
end


local function _num2Str(n)
	local fmt = math.floor(n) == n and "%d" or "%f"
	local s = string.format(fmt, n)
	if s:find("%.") then
		s = s:match("(.-)[0]*$")
	end
	return s
end


-- @return true if the new text was accepted, false if it was rejected by the format check.
function def:setText(text)
	local line_ed = self.line_ed

	if type(text) == "number" then
		text = _num2Str(text)
	end
	if type(text) ~= "string" then
		error("argument #1: expected string or number")
	end

	-- Reject invalid input.
	if not _decimalStringOK(text) then
		return false
	end

	line_ed:deleteText(false, 1, #line_ed.line)
	line_ed:insertText(text)
	line_ed.input_category = false
	line_ed.hist:clearAll()

	if line_ed.allow_highlight then
		self:highlightAll()
	end

	self.value = tonumber(text) or false

	self.update_flag = true
	return true
end


local function _valueTextUpdate(self, value_old)
	if self.value ~= false and type(self.value) ~= "number" then
		error("expected false or number value from callback function, got " .. type(self))
	end

	if value_old ~= self.value then
		local line_ed = self.line_ed

		line_ed:deleteText(false, 1, #line_ed.line)
		if self.value ~= false then
			line_ed:insertText(_num2Str(self.value))
		end
		line_ed.input_category = false
		line_ed.hist:clearAll()

		if line_ed.allow_highlight then
			self:highlightAll()
		end

		self.update_flag = true
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if isrepeat then
			if self.rep_sc ~= scancode then
				self.rep_sc_count = 0
			end
			self.rep_sc = scancode
			self.rep_sc_count = self.rep_sc_count + 1
		end

		local value_old = self.value

		if key == "return" or key == "kpenter" then
			self:wid_action()
			return true

		elseif scancode == "up" then
			self.value = self:wid_incrementArrowKey(self.value, self.rep_sc_count + 1)
			_valueTextUpdate(self, value_old)
			return true

		elseif scancode == "down" then
			self.value = self:wid_decrementArrowKey(self.value, self.rep_sc_count + 1)
			_valueTextUpdate(self, value_old)
			return true

		elseif scancode == "pageup" then
			self.value = self:wid_incrementPageKey(self.value, self.rep_sc_count + 1)
			_valueTextUpdate(self, value_old)
			return true

		elseif scancode == "pagedown" then
			self.value = self:wid_decrementPageKey(self.value, self.rep_sc_count + 1)
			_valueTextUpdate(self, value_old)
			return true

		-- Standard text box controls (caret navigation, etc.)
		else
			local rv = lgcInputS.keyPressLogic(self, key, scancode, isrepeat)
			self.value = tonumber(self.line_ed.line) or false
			return rv
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		if lgcInputS.textInputLogic(self, text, _checkDecimal) then
			self.value = tonumber(self.line_ed.line) or false
		end
	end
end



function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst
	and self.enabled
	then
		self.hovered = true
	end
end


function def:uiCall_pointerHoverMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst
	and self.enabled
	then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		if widShared.pointInViewport(self, 1, mx, my) then
			self:setCursorLow(self.skin.cursor_on)
		else
			self:setCursorLow()
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

		-- Clicking the text area:
		if widShared.pointInViewport(self, 1, mx, my) then
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my) then
				return true
			end

		-- Clicked on increment button:
		elseif widShared.pointInViewport(self, 3, mx, my) then
			local value_old = self.value
			if button == 1 then
				self.repeat_btn = 1
				self.value = self:wid_incrementButton(self.value, 1)
				_valueTextUpdate(self, value_old)
				return true
			end

		-- Clicking on decrement button:
		elseif widShared.pointInViewport(self, 4, mx, my) then
			local value_old = self.value
			if button == 1 then
				self.repeat_btn = -1
				self.value = self:wid_decrementButton(self.value, 1)
				_valueTextUpdate(self, value_old)
				return true
			end
		end
	end
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				local value_old = self.value
				if button == 1 then
					if self.repeat_btn == 1 then
						self.value = self:wid_incrementButton(self.value, reps + 1)
						_valueTextUpdate(self, value_old)
						return true
					else -- repeat_btn == -1
						self.value = self:wid_decrementButton(self.value, reps + 1)
						_valueTextUpdate(self, value_old)
						return true
					end
				end
			end
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			self.press_busy = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		-- XXX: Increment/decrement?
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
			--local font = skin.font
			local line_ed = self.line_ed

			local res
			if self.enabled then
				res = (self.wid_drawer) and skin.res_pressed or skin.res_idle
			else
				res = skin.res_disabled
			end

			love.graphics.push("all")

			-- Back panel body.
			love.graphics.setColor(res.color_body)
			uiGraphics.drawSlice(res.slice, 0, 0, self.w, self.h)

			-- Increment and decrement buttons.
			love.graphics.setColor(1, 1, 1, 1)
			uiGraphics.drawSlice(res.slc_button_up, self.vp3_x, self.vp3_y, self.vp3_w, self.vp3_h)
			uiGraphics.drawSlice(res.slc_button_down, self.vp4_x, self.vp4_y, self.vp4_w, self.vp4_h)
			uiGraphics.quadShrinkOrCenterXYWH(skin.tq_inc, self.vp3_x + res.deco_ox, self.vp3_y + res.deco_oy, self.vp3_w, self.vp3_h)
			uiGraphics.quadShrinkOrCenterXYWH(skin.tq_dec, self.vp4_x + res.deco_ox, self.vp4_y + res.deco_oy, self.vp4_w, self.vp4_h)

			-- Crop item text.
			uiGraphics.intersectScissor(
				ox + self.x + self.vp2_x,
				oy + self.y + self.vp2_y,
				self.vp2_w,
				self.vp2_h
			)

			-- Text editor component.
			lgcInputS.draw(
				self,
				res.color_highlight,
				skin.font_ghost,
				res.color_text,
				line_ed.font,
				(not self.wid_drawer) and skin.color_insert or false -- Don't draw caret if drawer is pulled out. It's annoying.
				-- XXX: color_replace
			)

			love.graphics.pop()

			-- Debug
			--[[
			widDebug.debugDrawViewport(self, 1)
			widDebug.debugDrawViewport(self, 2)
			widDebug.debugDrawViewport(self, 3)
			widDebug.debugDrawViewport(self, 4)
			--]]
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
