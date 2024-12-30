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

Scientific notation is not supported; use a plain text box instead.
Fractional parts are not supported for hexadecimal, octal and binary.
--]]


local context = select(1, ...)


local utf8 = require("utf8")


local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local edComS = context:getLua("shared/line_ed/s/ed_com_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lgcMenu = context:getLua("shared/lgc_menu")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local pileTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


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


def.arrange = lgcMenu.arrangeListVerticalTB


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast


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


-- (integer == decimal with no fractional part)
local _enum_value_mode = {
	decimal = 10,
	integer = 10,
	hexadecimal = 16,
	octal = 8,
	binary = 2
}


-- string characters for various base conversions (0-9, a-z)
local _nums = {}
for i = 0, 9 do
	_nums[i] = string.char(i + 48)
end
for i = 10, 36 do -- a-z
	_nums[i] = string.char(i + 87)
end


-- Blocks various non-numeric strings, while allowing partially complete input
-- (like a single '-' when negative numbers are enabled).
function def:fn_check()
	local value_mode = self.value_mode
	local ptn

	if value_mode == "integer" then
		if self.value_min < 0 then
			if self.value_max < 0 then -- integer, mandatory negative
				ptn = "%-%d*"
			else -- integer, optional negative
				ptn = "%-?%d*"
			end
		else -- integer, no negative
			ptn = "%d*"
		end

	elseif value_mode == "decimal" then
		if self.value_min < 0 then
			if self.value_max < 0 then -- decimal, mandatory negative
				ptn = "%-%d*%.?%d*"
			else -- decimal, optional negative
				ptn = "%-?%d*%.?%d*"
			end
		else -- decimal, no negative
			ptn = "%d*%.?%d*"
		end

	elseif value_mode == "hexadecimal" then
		if self.value_min < 0 then
			if self.value_max < 0 then -- hexadecimal, mandatory negative
				ptn = "%-%x*"
			else -- hexadecimal, optional negative
				ptn = "%-?%x*"
			end
		else -- hexadecimal, no negative
			ptn = "%x*"
		end

	elseif value_mode == "octal" then
		if self.value_min < 0 then
			if self.value_max < 0 then -- octal, mandatory negative
				ptn = "%-[0-7]*"
			else -- octal, optional negative
				ptn = "%-?[0-7]*"
			end
		else -- octal, no negative
			ptn = "[0-7]*"
		end

	elseif value_mode == "binary" then
		if self.value_min < 0 then
			if self.value_max < 0 then -- binary, mandatory negative
				ptn = "%-[0-1]*"
			else -- binary, optional negative
				ptn = "%-?[0-1]*"
			end
		else -- binary, no negative
			ptn = "[0-1]*"
		end
	end

	if not ptn then
		error("couldn't match 'value_mode' to a search pattern")
	end

	local s = self.line_ed.line
	return s:match(ptn) == s
end


local jit = jit
local function _baseToString(n, base)
	assert(base >= 2 and base <= 36, "unsupported base")

	-- Fractional parts are supported only for base 10.
	-- TODO: test usage of table.concat()
	if base == 10 then
		return tostring(n)
	end

	local s = ""
	local n2 = math.abs(n)
	while n2 >= 1 do
		s = _nums[n2 % base] .. s
		n2 = math.floor(n2 / base)
	end
	s = (n < 0 and "-" or "") .. s
	if s == "" then
		s = "0"
	end
	return s
end


-- @param self The widget.
-- @param v The new numeric value, or false.
-- @param write_history true to force a history update to ledger entry #2.
-- @param update_text true to update the lineEdS text.
-- @param preserve_caret true to (try to) keep the text input caret in the same place as before.
local function _setValue(self, v, write_history, update_text, preserve_caret)
	if v then
		v = math.max(self.value_min, math.min(v, self.value_max))
		if self.value_mode ~= "decimal" then
			v = math.floor(v)
		end
		self.value = v
	else
		self.value = false
	end

	local line_ed = self.line_ed
	local old_len = utf8.len(line_ed.line)
	local old_car_u = edComS.utf8LenPlusOne(line_ed.line, line_ed.car_byte)

	if update_text then
		if v then
			local s = _baseToString(math.abs(v), _enum_value_mode[self.value_mode])

			-- leading, trailing zeros
			local s1, s2, s3 = s:match("(.*)(%.?)(.*)")
			s = string.rep("0", math.max(0, self.digit_pad1 - #s1)) .. s
			if #s2 > 0 then
				s = s .. string.rep("0", math.max(0, self.digit_pad2 - #s3))
			end

			-- comma for fractional part
			if self.fractional_comma then
				s = s:gsub("%.", ",")
			end

			-- minus
			if v < 0 then
				s = "-" .. s
			end

			self:replaceText(s)
		else
			self:replaceText("")
		end
	end

	if preserve_caret then
		local delta = utf8.len(line_ed.line) - old_len
		local max_car_u = utf8.len(line_ed.line) + 1
		line_ed:caretToByte(utf8.offset(line_ed.line, old_car_u + delta) or max_car_u)
		line_ed:clearHighlight()
		line_ed:syncDisplayCaretHighlight()
	end
	line_ed:clearHighlight()

	lgcInputS.updateCaretShape(self)
	self:updateDocumentDimensions()
	self:scrollGetCaretInBounds(true)

	if write_history then
		line_ed.hist:moveToEntry(2)
		editHistS.writeEntry(line_ed, false)
	end
end


-- codepath for value changes through key up/down, pageup/pagedown and mouse clicks
local function _callback(self, cb, reps)
	if self.value then
		_setValue(self, (cb(self, self.value, reps)), true, true, true)
	else
		self:setValueToDefault()
	end
end


-- codepath for value changes through direct text input, copy+paste, etc.
-- @param hist_changed If true, the action was a direct undo/redo, so we shouldn't meddle with the ledger.
local function _textInputValue(self, hist_changed)
	local line_ed = self.line_ed
	local s = line_ed.line
	if self.fractional_comma then
		s = s:gsub(",", ".")
	end

	local v = tonumber(s, _enum_value_mode[self.value_mode]) or false
	print("self.value", self.value, "v", v)
	if v ~= nil and self.value ~= v then
		_setValue(self, v, false, true, true)
		if not hist_changed then
			line_ed.hist:moveToEntry(2)
		end
	end
end


function def:getValueMode()
	return self.value_mode
end


function def:setValueMode(mode)
	uiShared.enum(1, mode, "ValueMode", _enum_value_mode)

	self.value_mode = mode
end


-- To get the internal or display text:
-- self:getText()
-- self:getDisplayText()


function def:getDefaultValue()
	return self.value_default
end


function def:setDefaultValue(v)
	uiShared.numberNotNaN(1, v)

	self.value_default = v
end


function def:getValue()
	return self.value
end


function def:setValue(v)
	uiShared.numberNotNaN(1, v)

	local line_ed = self.line_ed

	_setValue(self, v, false, true)
	line_ed.hist:clearAll()
	line_ed.hist:moveToEntry(1)
	editHistS.writeLockedFirst(line_ed)
end


function def:setValueToDefault()
	local line_ed = self.line_ed

	_setValue(self, self.value_default, false, true)

	line_ed.hist:clearAll()
	line_ed.hist:moveToEntry(1)
	editHistS.writeLockedFirst(line_ed)
end


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupScroll(self)
		widShared.setupDoc(self)
		widShared.setupViewports(self, 3)

		lgcInputS.setupInstance(self)

		-- The internal value.
		self.value_default = 0
		self.value = false
		self.value_min = 0
		self.value_max = 999999

		self.value_mode = "decimal"

		-- when true, use ',' to mark the fractional part
		self.fractional_comma = false

		-- padding of digits before and after the fractional part
		self.digit_pad1 = 0
		self.digit_pad2 = 0
		-- maximum digits in the fractional part
		self.fractional_max = 2^15

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

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin

		self.line_ed = lineEdS.new(skin.font)

		-- special history configuration
		self.line_ed.hist:setLockedFirst(true)
		self.line_ed.hist:setMaxEntries(2)
		editHistS.writeLockedFirst(self.line_ed)

		self:setTextAlignment(skin.text_align)

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

	self:updateDocumentDimensions()
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

		-- Forget history state when the user nagivates away from the NumberBox.
		local line_ed = self.line_ed
		local hist = line_ed.hist
		if hist.pos == 2 then
			line_ed.hist:clearAll()
			line_ed.hist:moveToEntry(1)
			editHistS.writeLockedFirst(line_ed)
		end
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		commonWimp.checkDestroyPopUp(self)
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
			local ok, hist_changed = lgcInputS.keyPressLogic(self, key, scancode, isrepeat)
			if ok then
				_textInputValue(self, hist_changed)
			end
			return ok
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		if lgcInputS.textInputLogic(self, text) then
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

		self.btn_hov = widShared.pointInViewport(self, 3, mx, my) and 1
			or widShared.pointInViewport(self, 4, mx, my) and 2
			or false
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self:setCursorLow()

			self.btn_hov = false
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
			self.btn_rep = false
			self.btn_hov = false
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my) then
				return true
			end

		-- Clicked on increment button:
		elseif widShared.pointInViewport(self, 3, mx, my) then
			local value_old = self.value
			if button == 1 then
				self.btn_rep = 1
				self.btn_hov = 1
				_callback(self, self.wid_incrementButton, 1)
				return true
			end

		-- Clicking on decrement button:
		elseif widShared.pointInViewport(self, 4, mx, my) then
			local value_old = self.value
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
				local value_old = self.value
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

			-- debug
			--love.graphics.setScissor()

			-- Text editor component.
			local color_caret = self.replace_mode and res.color_caret_replace or res.color_caret_insert
			lgcInputS.draw(
				self,
				res.color_highlight,
				skin.font_ghost,
				res.color_text,
				line_ed.font,
				color_caret
			)

			love.graphics.pop()

			-- Debug
			--[[
			widDebug.debugDrawViewport(self, 1)
			widDebug.debugDrawViewport(self, 2)
			widDebug.debugDrawViewport(self, 3)
			widDebug.debugDrawViewport(self, 4)
			--]]

			--[=====[
			-- Debug: show internal state
			love.graphics.push("all")
			love.graphics.setScissor()
			love.graphics.print(
				"value_default: " .. tostring(self.value_default)
				.. "\nvalue: " .. tostring(self.value)
				.. "\nvalue_min: " .. tostring(self.value_min)
				.. "\nvalue_max: " .. tostring(self.value_max)
				.. "\nfractional_comma: " .. tostring(self.fractional_comma)
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
			love.graphics.print("History state:", 256, 216)

			for i, entry in ipairs(line_ed.hist.ledger) do
				if i == line_ed.hist.pos then
					love.graphics.setColor(1, 1, 0, 1)
				else
					love.graphics.setColor(1, 1, 1, 1)
				end
				love.graphics.print(i .. " c: " .. entry.car_byte .. " h: " .. entry.h_byte .. "line: |" .. entry.line .. "|", 256, yy)
				yy = yy + hh
			end
			--]]

			love.graphics.pop()
			--]=====]
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
