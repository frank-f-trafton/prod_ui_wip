--[[

A single-line text box with controls for incrementing and decrementing numeric values.
Fractional values are not supported.

┌─────────────────┬───┐
│ ═╗              │ + │ -- Increment value (or press up-arrow)
│  ║              ├───┤
│ ═╩═             │ - │ -- Decrement value (or press down-arrow)
└─────────────────┴───┘

Important: The value can be boolean false when the text input is empty or partially complete.

Scientific notation is not supported; use a plain text box instead.
--]]


local context = select(1, ...)


local utf8 = require("utf8")


local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local lgcInputS = context:getLua("shared/lgc_input_s")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "number_box1",
}


widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text inputs.


lgcInputS.setupDef(def)


def.updateAlignOffset = lgcInputS.method_updateAlignOffset
def.pop_up_def = lgcInputS.pop_up_def


-- Called when the user presses 'enter'. Return true to halt the logic that checks for
-- typing literal newlines with the enter key.
def.wid_action = uiDummy.func


--- Callback for a change in the NumberBox state.
function def:wid_inputChanged(text)
	-- ...
end


--- Callbacks that control the amount of addition and subtraction of the value.
-- @param v The current value
-- @param radix The current radix, or base. (10 for decimal, 16 for hex, etc.)
-- @param reps Number of iterations for held buttons (ie mouse-repeat)
-- @return The new value to assign.
function def:wid_incrementButton(v, radix, reps) return v + 1 end
function def:wid_decrementButton(v, radix, reps) return v - 1 end
function def:wid_incrementArrowKey(v, radix, reps) return v + 1 end
function def:wid_decrementArrowKey(v, radix, reps) return v - 1 end
function def:wid_incrementPageKey(v, radix, reps) return v + radix end
function def:wid_decrementPageKey(v, radix, reps) return v - radix end


local _enum_value_mode = {
	octal = 8,
	decimal = 10,
	hexadecimal = 16
}


local _specifiers = {
	octal = "%o",
	decimal = "%u",
	hexadecimal = "%x"
}


local function _getValueString(v, mode)
	return (v < 0 and "-" or "") .. string.format(_specifiers[mode], math.abs(v))
end


local function _valueFromText(s, value_mode)
	return tonumber(s, _enum_value_mode[value_mode]) or false
end


local function _processValue(v, value_mode, min, max)
	v = math.max(min, math.min(v, max))
	v = math.floor(v)

	return v
end


-- @param history_action True: reset history and move to ledger entry #1.
local function _setTextFromValue(self, v, preserve_caret, history_action)
	--print("_setTextFromValue(): start")
	local LE = self.LE
	local old_len = utf8.len(LE.line)
	local old_car_u = edComS.utf8LenPlusOne(LE.line, LE.cb)

	if v then
		local s = _getValueString(v, self.value_mode)
		self:replaceText(s)
	else
		self:replaceText("")
	end

	--print("_setTextFromValue(): preserve_caret", preserve_caret)
	if preserve_caret then
		local delta = utf8.len(LE.line) - old_len
		local max_car_u = utf8.len(LE.line) + 1

		LE:moveCaret(utf8.offset(LE.line, old_car_u + delta) or max_car_u, true)
		editWid.updateCaretShape(self)

		self:scrollGetCaretInBounds(true)
	end

	local hist = self.LE_hist
	if history_action then
		hist:clearAll()
		editFuncS.writeHistoryLockedFirst(self)
	end
	--print("_setTextFromValue(): end")
end


function def:setValue(v, preserve_caret)
	_setTextFromValue(self, v, preserve_caret, true)
end


--- Checks the form of a numeric string (but not the range, padding, etc.)
local function _stringFormCheck(s, vmode)
	local negative, whole

	if vmode == "decimal" then
		negative, whole = s:match("^(%-?)(%d*)$")

	elseif vmode == "hexadecimal" then
		negative, whole = s:match("^(%-?)(%x*)$")

	elseif vmode == "octal" then
		negative, whole = s:match("^(%-?)([0-7]*)$")

	else
		error("invalid value mode.")
	end

	return negative, whole
end


-- Blocks various non-numeric strings.
function def:fn_check()
	local LE = self.LE
	local s = LE.line
	local vmode = self.value_mode

	--print("fn_check() start")
	--print("fn_check() s", s)

	-- Some special cases for incomplete input:
	if s == "" then
		self.value = false
		return true

	elseif s == "-" and self.value_min < 0 then
		self.value = false
		return true
	end

	-- Check the initial string form.
	local negative, whole = _stringFormCheck(s, vmode)

	--print("fn_check() negative", negative, "whole", whole)
	if not negative then
		--print("fn_check() end (form check failed)")
		return false
	end

	-- Don't allow more than one leading zero, and only if no other digits are present.
	local whole_zeros, whole_rest = whole:match("^(0*)(.*)")
	if whole_zeros then
		if #whole_rest > 0 and #whole_zeros > 0 then
			return false

		elseif #whole_zeros > 1 then
			return false
		end
	end

	-- Convert to a number, apply min/max range and flooring.
	local v = _valueFromText(s, vmode)
	if not v then
		--print("fn_check() end (re-convert to number failed)")
		return false
	end
	local v2 = v
	v = _processValue(v, self.value_mode, self.value_min, self.value_max)

	-- If the value was clamped or floored, recreate the string and chunks.
	local v_changed
	if v ~= v2 then
		local s2 = _getValueString(v, vmode)
		negative, whole = _stringFormCheck(s2, vmode)
		v_changed = true
	end

	-- Reform the string.
	local s3 = negative .. whole

	--print("s", s, "s3", s3)

	if v_changed or s ~= s3 then
		local old_caret = LE.cb
		LE:deleteText(false, 1, #self.LE.line)
		LE:insertText(s3)
		LE:moveCaret(old_caret, true)
	end

	-- Update the cached value.
	self.value = v

	--print("fn_check() end (accepted)")
	return true
end


-- codepath for value changes through key up/down, pageup/pagedown and mouse clicks
local function _callback(self, cb, reps)
	--print("_callback(): start")
	--print("_callback(): self.value", self.value)
	if self.value then
		_setTextFromValue(self, cb(self, self.value, _enum_value_mode[self.value_mode], reps), true, false)
	else
		_setTextFromValue(self, self.value_default, true, false)
	end

	editWid.resetCaretBlink(self)
	--print("_callback(): end")
end


function def:setValueMode(mode)
	uiAssert.enum(1, mode, "ValueMode", _enum_value_mode)

	self.value_mode = mode
end


function def:getValueMode()
	return self.value_mode
end


-- To get the internal text:
-- self:getText()


function def:setDefaultValue(v)
	uiAssert.numberNotNaN(1, v)

	self.value_default = v
end


function def:getDefaultValue()
	return self.value_default
end


function def:getValue()
	return self.value
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)
	widShared.setupViewports(self, 3)

	-- Settings for the input value.
	-- 'self.value' is cached whenever there is a change to the text (via 'fn_check').
	-- It is false if the text cannot be interpreted as a number.
	self.value = false
	self.value_min = -99999
	self.value_max = 99999
	self.value_default = 0
	self.value_mode = "decimal"

	-- hover and repeat-press state for inc/dec sensors
	-- false for N/A, 1 for increment, 2 for decrement
	self.btn_hov = false
	self.btn_rep = false

	-- repeat key state
	self.rep_sc = false
	self.rep_sc_count = 0

	-- State flags
	self.enabled = true
	self.hovered = false

	lgcInputS.setupInstance(self, "single")

	self:skinSetRefs()
	self:skinInstall()

	-- special history configuration
	local hist = self.LE_hist
	hist:setLockedFirst(true)
	hist:setMaxEntries(2)

	self:setValue(self.value_default, true)

	hist:clearAll()
	editFuncS.writeHistoryLockedFirst(self)

	self:setTextAlignment(self.skin.text_align)

	self:reshape()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.
	-- Viewport #3 is the increment button.
	-- Viewport #4 is the decrement button.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	local button_spacing = (skin.button_spacing == "auto") and self.vp_h or skin.button_spacing
	widShared.partitionViewport(self, 1, 3, button_spacing, skin.button_placement, false)
	if skin.button_alignment == "vertical" then
		widShared.partitionViewport(self, 3, 4, self.vp3_h / 2, "bottom", false)
	else
		widShared.partitionViewport(self, 3, 4, self.vp3_w / 2, "left", false)
	end

	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, skin.box.margin)

	editWidS.updateDocumentDimensions(self)
	self:scrollClampViewport()

	editWidS.generalUpdate(self, true, true, false, true)

	return true
end


function def:uiCall_update(dt)
	editWid.updateCaretBlink(self, dt)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local do_update

	if self.press_busy == "text-drag" then
		if lgcInputS.mouseDragLogic(self) then
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

		-- Forget history state when the user nagivates away from the NumberBox.
		local hist = self.LE_hist
		hist:clearAll()
		editFuncS.writeHistoryLockedFirst(self)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		lgcWimp.checkDestroyPopUp(self)
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if self == inst then
		if isrepeat then
			if self.rep_sc ~= scancode then
				self.rep_sc_count = 0
			end
			self.rep_sc = scancode
			self.rep_sc_count = self.rep_sc_count + 1
		end

		if (key == "return" or key == "kpenter") and self:wid_action() then
			editWid.resetCaretBlink(self)
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
			local ok, hist_changed = lgcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
			return ok
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		if lgcInputS.textInputLogic(self, text) then
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


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst
	and self.enabled
	then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		if widShared.pointInViewport(self, 1, mx, my) then
			self.cursor_hover = self.skin.cursor_on
		else
			self.cursor_hover = nil
		end

		self.btn_hov = widShared.pointInViewport(self, 3, mx, my) and 1
			or widShared.pointInViewport(self, 4, mx, my) and 2
			or false
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil

			self.btn_hov = false
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

		-- Clicking the text area:
		if widShared.pointInViewport(self, 1, mx, my) then
			self.btn_rep = false
			self.btn_hov = false
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my, had_thimble1_before) then
				return true
			end

		-- Clicked on increment button:
		elseif widShared.pointInViewport(self, 3, mx, my) then
			if button == 1 then
				self.btn_rep = 1
				self.btn_hov = 1
				_callback(self, self.wid_incrementButton, 1)
				return true
			end

		-- Clicking on decrement button:
		elseif widShared.pointInViewport(self, 4, mx, my) then
			if button == 1 then
				self.btn_rep = 2
				self.btn_hov = 2
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
				if button == 1 then
					if self.btn_rep == 1 then
						_callback(self, self.wid_incrementButton, reps + 1)
						return true

					elseif self.btn_rep == 2 then
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
			self.btn_rep = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		-- XXX: Increment/decrement?
	end
end


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.slice(res, "slice")
	check.slice(res, "slc_button_inc")
	check.slice(res, "slc_button_dec")
	check.quad(res, "tq_inc")
	check.quad(res, "tq_dec")

	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_text")
	check.colorTuple(res, "color_highlight")
	check.colorTuple(res, "color_highlight_active")
	check.colorTuple(res, "color_caret_insert")
	check.colorTuple(res, "color_caret_replace")

	check.integer(res, "deco_ox")
	check.integer(res, "deco_oy")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "deco_ox", scale)
	change.integerScaled(res, "deco_oy", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.loveType(skin, "font", "Font")
		check.loveType(skin, "font_ghost", "Font")

		check.type(skin, "cursor_on", "nil", "string")
		check.exact(skin, "text_align", "left", "center", "right")

		-- Horizontal size of the increment and decrement buttons.
		-- "auto": use Viewport #1's height.
		check.numberOrExact(skin, "button_spacing", 0, nil, "auto")

		-- Inc/dec button positioning
		check.exact(skin, "button_placement", "left", "right")
		check.exact(skin, "button_alignment", "horizontal", "vertical")

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_hover")
		_checkRes(skin, "res_pressed")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "button_spacing", scale)

		_changeRes(skin, "res_idle", scale)
		_changeRes(skin, "res_hover", scale)
		_changeRes(skin, "res_pressed", scale)
		_changeRes(skin, "res_disabled", scale)
	end,


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
		local LE = self.LE

		-- b1: increment sensor, b2: decrement sensor
		local res, res_b1, res_b2
		if self.enabled then
			res = self.hovered and skin.res_hover or skin.res_idle
			res_b1 = self.btn_rep == 1 and skin.res_pressed or self.btn_hov == 1 and skin.res_hover or skin.res_idle
			res_b2 = self.btn_rep == 2 and skin.res_pressed or self.btn_hov == 2 and skin.res_hover or skin.res_idle
		else
			res = skin.res_disabled
			res_b1 = skin.res_disabled
			res_b2 = skin.res_disabled
		end

		love.graphics.push("all")

		-- Back panel body.
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(res.slice, 0, 0, self.w, self.h)

		-- Increment and decrement buttons.
		love.graphics.setColor(1, 1, 1, 1)
		uiGraphics.drawSlice(res_b1.slc_button_inc, self.vp3_x, self.vp3_y, self.vp3_w, self.vp3_h)
		uiGraphics.drawSlice(res_b2.slc_button_dec, self.vp4_x, self.vp4_y, self.vp4_w, self.vp4_h)
		uiGraphics.quadShrinkOrCenterXYWH(res_b1.tq_inc, self.vp3_x + res_b1.deco_ox, self.vp3_y + res_b1.deco_oy, self.vp3_w, self.vp3_h)
		uiGraphics.quadShrinkOrCenterXYWH(res_b2.tq_dec, self.vp4_x + res_b2.deco_ox, self.vp4_y + res_b2.deco_oy, self.vp4_w, self.vp4_h)

		-- Crop text and caret
		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.LE_align_oy - self.scr_y)

		-- debug
		--love.graphics.setScissor()

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

		--[=====[
		-- Debug: show internal state
		love.graphics.push("all")
		love.graphics.setScissor()
		love.graphics.print(
			"value_default: " .. tostring(self.value_default)
			.. "\nvalue: " .. tostring(self.value)
			.. "\nvalue_min: " .. tostring(self.value_min)
			.. "\nvalue_max: " .. tostring(self.value_max)
			, 0, 64
		)


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
			,
			0, 256
		)

		local yy, hh = 240, LE.font:getHeight()
		love.graphics.print("History state:", 256, 216)

		for i, entry in ipairs(self.LE_hist.ledger) do
			if i == self.LE_hist.pos then
				love.graphics.setColor(1, 1, 0, 1)
			else
				love.graphics.setColor(1, 1, 1, 1)
			end
			love.graphics.print(i .. " c: " .. entry.cb .. " h: " .. entry.hb .. "line: |" .. entry.line .. "|", 256, yy)
			yy = yy + hh
		end
		--]]

		love.graphics.pop()
		--]=====]
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
