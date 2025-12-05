--[[
A stepper button.


Horizontal layout:

            vp1
    ╔══════════════════╗
    ║                  ║

┌───┬──────────────────┬───┐
│ < │  Selection Text  │ > │
└───┴──────────────────┴───┘

║   ║                  ║   ║
╚═══╝                  ╚═══╝
 vp2                    vp3



Vertical layout:

          ┌───────┐  ══╗
          │   ^   │    ║ vp2
     ╔══  ├───────┤  ══╝
     ║    │       │
 vp1 ║    │ Text  │
     ║    │       │
     ╚══  ├───────┤  ══╗
          │   v   │    ║ vp3
          └───────┘  ══╝
--]]


local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcButton = context:getLua("shared/wc/wc_button")
local wcLabel = context:getLua("shared/wc/wc_label")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "stepper1",
}


--- Called when the stepper value changes.
-- @param index The current index.
function def:wid_stepperChanged(index)

end


-- NOTE: The primary button action is activated by keyboard input only. Click-activated
-- secondary and tertiary actions do not consider the location of the mouse cursor.
def.wid_buttonAction = wcButton.wid_buttonAction
def.wid_buttonAction2 = wcButton.wid_buttonAction2
def.wid_buttonAction3 = wcButton.wid_buttonAction3


def.setEnabled = wcButton.setEnabled
def.setLabel = wcLabel.widSetLabel


function def:setOrientation(orientation)
	local old_orientation = self.vertical

	if orientation == "horizontal" then
		self.vertical = false

	elseif orientation == "vertical" then
		self.vertical = true

	else
		error("invalid orientation: " .. tostring(orientation))
	end

	if old_orientation ~= self.vertical then
		self:reshape()
	end
end


def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
def.evt_thimbleAction = wcButton.evt_thimbleAction
def.evt_thimbleAction2 = wcButton.evt_thimbleAction2


local function wrapSetLabel(self)
	if self.index == 0 then
		self:setLabel("", "single")
	else
		local option = self.options[self.index]
		local label_text = (type(option) == "string" and option or type(option) == "table" and option.text)
		label_text = label_text or ""

		self:setLabel(label_text, "single")
	end
end


--- Adds an option to the stepper. If the stepper options array is empty, then this option is selected as the current index.
-- @param option The option data to use. Can either be a string (which will be used as the label text when selected) or
-- a table (where tbl.text is used for the label text).
-- @param i (#options + 1) where to insert the option in the array. Must be between 1 and #options + 1. If not specified, the option will be added to the end of the array.
-- @return The index of the newly-added option.
function def:insertOption(option, i)
	uiAssert.types(1, option, "string", "table")
	uiAssert.integerRangeEval(2, i, 1, #self.options + 1)

	i = i or #self.options + 1

	local old_len = #self.options

	table.insert(self.options, i, option)

	-- Array was empty: select this option.
	if old_len == 0 then
		self:setIndex(1)

	-- Increment the current index if the option was inserted before it.
	elseif self.index >= i then
		self.index = self.index + 1
	end

	return i
end


--- Removes an option from the stepper. If this removes the last option, then the index is set to zero.
-- @param i *(#options)* Index of the option to remove in the array. Must be between 1 and #options. If not specified, the last option in the array will be removed.
-- @return The removed option value.
function def:removeOption(i)
	uiAssert.integerRangeEval(1, i, 1, #self.options)

	i = i or #self.options

	local removed_option = table.remove(self.options, i)

	-- Array is now empty:
	if #self.options == 0 then
		self:setIndex(0)

	-- Decrement index if the removed option came before it.
	elseif self.index > i then
		self.index = self.index - 1

	-- The current option was deleted:
	elseif i == self.index then
		-- Deleted the last option:
		if i > #self.options then
			self:setIndex(#self.options)

		-- Deleted an option that isn't the last:
		else
			self:stepIndex(0)
		end
	end

	return removed_option
end


--- Sets the stepper index.
-- @param index The new index number. The value is clamped between 1 and the number of options, or is set to zero if there are no options specified. Must not be NaN.
-- @return The new index, which may be different than the index requested.
function def:setIndex(index)
	uiAssert.numberNotNaN(1, index)

	index = math.floor(index)

	local old_index = self.index

	-- Empty options list
	if #self.options == 0 then
		self.index = 0
		wrapSetLabel(self)
	else
		self.index = math.max(1, math.min(index, #self.options))
		local option = self.options[self.index]
		wrapSetLabel(self)
	end

	if old_index ~= self.index then
		self:wid_stepperChanged(self.index)
	end

	return self.index
end


--- Increments the stepper index.
-- @param delta The amount to increment or decrement, expected to be -1, 0 or 1. The final index value will wrap around, or be set to zero if there are no options specified. Must not be NaN.
-- @return The new index, which may be different than the index requested.
function def:stepIndex(delta)
	uiAssert.numberNotNaN(1, delta)

	delta = math.floor(delta)

	local old_index = self.index

	-- Empty options list
	if #self.options == 0 then
		self.index = 0
		wrapSetLabel(self)
	else
		self.index = self.index + delta
		if self.index < 1 then
			self.index = #self.options

		elseif self.index > #self.options then
			self.index = 1
		end

		wrapSetLabel(self)
	end

	if old_index ~= self.index then
		self:wid_stepperChanged(self.index)
	end

	return self.index
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 3)

	wcLabel.setup(self)

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	-- Stepper orientation. Controls placement of the buttons and the quad graphics
	-- used (left/right or up/down).
	self.vertical = false

	-- Which button is currently pressed, if any.
	self.b_pressing = false -- false, "prev", "next"

	-- Enabled state for the 'prev' and 'next' buttons.
	self.b_prev_enabled = true
	self.b_next_enabled = true

	-- An array of strings which represent each selectable option.
	self.options = {}

	-- The current selection. It should be 0 if there are no options.
	self.index = 0

	self:skinSetRefs()
	self:skinInstall()

	self.cursor_press = self.skin.cursor_press

	self:reshape()
end


function def:evt_reshapePre()
	-- Viewport #1 is the label bounding box.
	-- Viewport #2 is the "prev" button component.
	-- Viewport #3 is the "next" button component.

	local skin = self.skin
	local vp, vp2, vp3 = self.vp, self.vp2, self.vp3

	vp:set(0, 0, self.w, self.h)

	if self.vertical then
		vp:split(vp2, "top", skin.prev_spacing)
		vp:split(vp3, "bottom", skin.next_spacing)
	else
		vp:split(vp2, "left", skin.prev_spacing)
		vp:split(vp3, "right", skin.next_spacing)
	end

	vp:reduceT(skin.box.border)
	vp:reduceT(skin.box.margin)

	wcLabel.reshapeLabel(self)

	return true
end


function def:evt_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					self.pressed = true

					x, y = self:getRelativePosition(x, y)

					if self.b_prev_enabled and self.vp2:pointOverlap(x, y) then
						self.b_pressing = "prev"
						self:stepIndex(-1)

					elseif self.b_next_enabled and self.vp3:pointOverlap(x, y) then

						self.b_pressing = "next"
						self:stepIndex(1)
					end

				elseif button == 2 then
					-- Instant second action.
					self:wid_buttonAction2()

				elseif button == 3 then
					-- Instant tertiary action.
					self:wid_buttonAction3()
				end
			end
		end
	end
end


function def:evt_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					x, y = self:getRelativePosition(x, y)

					if self.b_pressing == "prev" and self.vp2:pointOverlap(x, y) then
						self:stepIndex(-1)

					elseif self.b_pressing == "next" and self.vp3:pointOverlap(x, y) then
						self:stepIndex(1)
					end
				end
			end
		end
	end
end


function def:evt_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false

					self.b_pressing = false
				end
			end
		end
	end
end


function def:evt_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			local key_prev, key_next
			if self.vertical then
				key_prev, key_next = "up", "down"
			else
				key_prev, key_next = "left", "right"
			end

			if self.b_prev_enabled and (scancode == key_prev) then
				self:stepIndex(-1)

			elseif self.b_next_enabled and (scancode == key_next) then
				self:stepIndex(1)
			end
		end
	end
end


function def:evt_pointerWheel(inst, x, y)
	if self == inst then
		if self.enabled then
			if self.b_prev_enabled and y > 0 then
				self:stepIndex(-1)

			elseif self.b_next_enabled and y < 0 then
				self:stepIndex(1)
			end
		end
	end
end


function def:evt_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 3)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	sl_body = themeAssert.slice,
	sl_button = themeAssert.slice,
	sl_button_up = themeAssert.slice,

	tq_left = themeAssert.quad,
	tq_right = themeAssert.quad,
	tq_up = themeAssert.quad,
	tq_down = themeAssert.quad,

	color_body = uiAssert.loveColorTuple,
	color_label = uiAssert.loveColorTuple,

	button_ox = uiAssert.integer,
	button_oy = uiAssert.integer,
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		label_style = themeAssert.labelStyle,
		tq_px = themeAssert.quad,

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Alignment of label text in Viewport #1.
		label_align_h = {uiAssert.namedMap, uiTheme.named_maps.label_align_h},
		label_align_v = {uiAssert.namedMap, uiTheme.named_maps.label_align_v},

		-- Alignment of the 'prev' and 'next' arrow (or plus/minus, etc.) graphics within Viewports #2 and #3.
		gfx_prev_align_h = {uiAssert.oneOf, "left", "center", "right"},
		gfx_prev_align_v = {uiAssert.oneOf, "top", "middle", "bottom"},
		gfx_next_align_h = {uiAssert.oneOf, "left", "center", "right"},
		gfx_next_align_v = {uiAssert.oneOf, "top", "middle", "bottom"},

		-- How much space to assign the next+prev buttons when not using "overlay" placement.
		prev_spacing = {uiAssert.integerGE, 0},
		next_spacing = {uiAssert.integerGE, 0},

		-- Arrow quad mappings:
		--
		-- Orientation    Prev   Next
		-- ---------------------------
		-- Horizontal     left   right
		-- Vertical       up     down

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "prev_spacing")
		uiScale.fieldInteger(scale, skin, "next_spacing")

		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "button_ox")
			uiScale.fieldInteger(scale, res, "button_oy")
		end

		_changeRes(scale, skin.res_idle)
		_changeRes(scale, skin.res_hover)
		_changeRes(scale, skin.res_pressed)
		_changeRes(scale, skin.res_disabled)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function (self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp2, vp3 = self.vp2, self.vp3
		local res = uiTheme.pickButtonResource(self, skin)

		local sl_body = res.sl_body
		local sl_button

		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(sl_body, 0, 0, self.w, self.h)

		local tq_prev, tq_next
		if self.vertical then
			tq_prev, tq_next = res.tq_up, res.tq_down
		else
			tq_prev, tq_next = res.tq_left, res.tq_right
		end

		-- XXX WIP
		local button_ox, button_oy
		if self.b_pressing == "prev" then
			button_ox, button_oy = res.button_ox, res.button_oy
			sl_button = res.sl_button
		else
			button_ox, button_oy = 0, 0
			sl_button = res.sl_button_up
		end
		uiGraphics.drawSlice(sl_button, vp2.x, vp2.y, vp2.w, vp2.h)
		uiGraphics.quadShrinkOrCenterXYWH(tq_prev, vp2.x + button_ox, vp2.y + button_oy, vp2.w, vp2.h)

		if self.b_pressing == "next" then
			button_ox, button_oy = res.button_ox, res.button_oy
			sl_button = res.sl_button
		else
			button_ox, button_oy = 0, 0
			sl_button = res.sl_button_up
		end
		uiGraphics.drawSlice(sl_button, vp3.x, vp3.y, vp3.w, vp3.h)
		uiGraphics.quadShrinkOrCenterXYWH(tq_next, vp3.x + button_ox, vp3.y + button_oy, vp3.w, vp3.h)

		if self.label_mode then
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, 0, 0, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
