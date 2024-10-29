-- XXX: Under construction. Combination of `wimp/dropdown_box.lua` and `input/text_box_single.lua`.
-- XXX: Support commas for decimal place indicator
--[[

A single-line text box with controls for incrementing and decrementing numeric values.

┌─────────────────┬───┐
│ ═╗              │ + │ -- Increment value (or press up-arrow)
│  ║              ├───┤
│ ═╩═             │ - │ -- Decrement value (or press down-arrow)
└─────────────────┴───┘

Important: The internal value can be boolean false when the text input is empty or partially complete.
--]]


-- XXX TODO: hex, octal, binary numbers


local context = select(1, ...)


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonWimp = require(context.conf.prod_ui_req .. "logic.common_wimp")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
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


-- [comma][minus][decimal]
local _ptn_in = {
	[false] = {
		[false] = {
			[false] = "%d*",
			[true] = "%d*%.?%d*"
		}, [true] = {
			[false] = "%-?%d*",
			[true] = "%-?%d*%.?%d*"
		}
	}, [true] = {
		[false] = {
			[false] = "%d*",
			[true] = "%d*,?%d*"
		}, [true] = {
			[false] = "%-?%d*",
			[true] = "%-?%d*,?%d*"
		}
	}
}


-- For partial input.
local function _decimalStringOK(s, comma, minus, decimal)
	return s:match(_ptn_in[comma][minus][decimal]) == s
end


local function _checkDecimal(self)
	return _decimalStringOK(self.line_ed.line, not not self.decimal_comma, self.value_min < 0, not not self.allow_decimal)
end


local function _num2Str(n, comma)
	local fmt = math.floor(n) == n and "%d" or "%f"
	local s = string.format(fmt, n)
	if comma then
		s = s:gsub("%.", ",")
	end
	if s:find("[%.,]") then
		-- clip trailing zeros after decimal point
		s = s:match("(.-)[0]*$")
	end
	return s
end


--- Gets the internal numeric value.
function def:getValue()
	return self.value
end


-- To get the internal or display text:
-- self:getText()
-- self:getDisplayText()


function def:setValueToDefault()
	self:setValue(self.value_default)
end


function def:setDefaultValue(v)
	if type(v) ~= "number" then error("argument #1: expected string or number")
	elseif v ~= v then error("value cannot be NaN") end

	self.value_default = v
end


-- @return true if the new value was accepted, false if it was rejected by the format check, nil if the input value is already set.
function def:setValue(v)
	if type(v) ~= "number" then error("argument #1: expected string or number")
	elseif v ~= v then error("value cannot be NaN") end

	v = math.max(self.value_min, math.min(v, self.value_max))

	local text = _num2Str(v, self.decimal_comma)

	-- reject invalid input
	if not _decimalStringOK(text, not not self.decimal_comma, self.value_min < 0, not not self.allow_decimal) then
		return false
	end

	if self.value ~= v then
		self.value = v

		local line_ed = self.line_ed

		self:replaceText(text)
		line_ed.hist:clearAll()
		self.input_category = false
		self:caretLast(true)
		lgcInputS.updateCaretShape(self)

		return true
	end
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
		self.value = false
		self.value_min = 0
		self.value_max = 999999

		-- when false, rejects input with decimal points
		self.allow_decimal = true

		-- when true, use ',' for the decimal point
		self.decimal_comma = false

		-- padding of digits before and after the decimal point
		self.digit_pad1 = 0
		self.digit_pad2 = 0
		self.decimals_max = 2^15

		-- repeat mouse-press state
		self.repeat_btn = false -- false for inactive, -1 for decrement, 1 for increment

		-- repeat key state
		self.rep_sc = false
		self.rep_sc_count = 0

		-- State flags
		self.enabled = true
		self.hovered = false

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin

		self.line_ed = lineEdS.new(skin.font)
		self.line_ed.align = self:setTextAlignment(skin.text_align)

		self:setValueToDefault()
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

	self:scrollClampViewport()
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


function def:uiCall_destroy(inst)
	if self == inst then
		commonWimp.checkDestroyPopUp(self)
	end
end


local function _callback(self, cb, reps)
	if self.value then
		self:setValue(cb(self, self.value, reps))
	else
		self:setValueToDefault()
	end
end


-- @return The new value (or false if the string doesn't convert to a number), and a boolean indicating if the value
--  has been clamped.
local function _str2Num(s, comma, v_min, v_max)
	if comma then
		s = s:gsub(",", ".")
	end
	local v = tonumber(s)
	local v_old = v
	if v then
		v = math.max(v_min, math.min(v, v_max))
	end
	return v or false, v ~= v_old
end


local function _textInputValue(self)
	local clamped
	self.value, clamped = _str2Num(self.line_ed.line, self.decimal_comma, self.value_min, self.value_max)
	-- If the value was modified, then we have to rewrite the input box text.
	if clamped then
		self:setValue(self.value)
	end
end


--[[
* Remember the old line_ed string
* Reject the new line_ed string if:
  * decimal points are disabled and a point/comma appears in the new string
  * it doesn't convert to a number
  * the number is out of bounds
--]]


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
			_callback(self, self.wid_incrementArrowKey, self.rep_sc_count + 1)
			return true

		elseif scancode == "down" then
			_callback(self, self.wid_decrementArrowKey, self.rep_sc_count + 1)
			return true

		elseif scancode == "pageup" then
			_callback(self, self.wid_incrementPageKey, self.rep_sc_count + 1)
			return true

		elseif scancode == "pagedown" then
			_callback(self, self.wid_decrementPageKey, self.rep_sc_count + 1)
			return true

		-- Standard text box controls (caret navigation, backspace, etc.)
		else
			local rv = lgcInputS.keyPressLogic(self, key, scancode, isrepeat, _checkDecimal)
			_textInputValue(self)
			return rv
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		if lgcInputS.textInputLogic(self, text, _checkDecimal) then
			_textInputValue(self)
			return true
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
			self.repeat_btn = false
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my) then
				return true
			end

		-- Clicked on increment button:
		elseif widShared.pointInViewport(self, 3, mx, my) then
			local value_old = self.value
			if button == 1 then
				self.repeat_btn = 1
				_callback(self, self.wid_incrementButton, 1)
				return true
			end

		-- Clicking on decrement button:
		elseif widShared.pointInViewport(self, 4, mx, my) then
			local value_old = self.value
			if button == 1 then
				self.repeat_btn = -1
				_callback(self, self.wid_decrementButton, 1)
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
						_callback(self, self.wid_incrementButton, reps + 1)
						return true
					elseif self.repeat_btn == -1 then
						_callback(self, self.wid_decrementButton, reps + 1)
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

			-- Debug: show internal state
			love.graphics.push("all")
			love.graphics.setScissor()
			love.graphics.print(
				"value_default: " .. tostring(self.value_default)
				.. "\nvalue: " .. tostring(self.value)
				.. "\nvalue_min: " .. tostring(self.value_min)
				.. "\nvalue_max: " .. tostring(self.value_max)
				.. "\nallow_decimal: " .. tostring(self.allow_decimal)
				.. "\ndecimal_comma: " .. tostring(self.decimal_comma)
				, 0, 64
			)


			-- Debug renderer
			-- [[
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
				0, 256
			)

			local yy, hh = 240, line_ed.font:getHeight()
			love.graphics.print("History state:", 0, 216)

			for i, entry in ipairs(line_ed.hist.ledger) do
				love.graphics.print(i .. " c: " .. entry.car_byte .. " h: " .. entry.h_byte .. "line: " .. entry.line, 0, yy)
				yy = yy + hh
			end
			--]]

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
