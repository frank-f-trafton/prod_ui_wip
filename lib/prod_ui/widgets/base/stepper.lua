--[[
A stepper button.


Horizontal layout:

            vp1
    +------------------+
    |                  |

+---+------------------+---+
| < |  Selection Text  | > |
+---+------------------+---+

|   |                  |   |
+---+                  +---+
 vp2                    vp3



Vertical layout:

          +-------+  --+
          |   ^   |    | vp2
     +--  +-------+  --+
     |    |       |
 vp1 |    | Text  |
     |    |       |
     +--  +-------+  --+
          |   v   |    | vp3
          +-------+  --+

--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local lgcGraphic = context:getLua("shared/lgc_graphic")
local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "logic.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "stepper1",
}


--- Called when the stepper value changes.
-- @param index The current index.
function def:wid_stepperChanged(index)

end


-- NOTE: The primary button action is activated by keyboard input only. Click-activated
-- secondary and tertiary actions do not consider the location of the mouse cursor.
def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setLabel = lgcLabel.widSetLabel


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


def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_thimbleAction = lgcButton.uiCall_thimbleAction
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2


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

	-- Assertions
	-- [[
	if type(option) ~= "string" and type(option) ~= "table" then uiShared.errBadType(1, option, "string/table") end
	if i ~= nil then
		uiShared.assertNumberIntNotNaN(1, i)
		if i < 1 or i > #self.options + 1 then
			error("argument #2: index is out of range.")
		end
	end
	--]]

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

	-- Assertions
	-- [[
	if i ~= nil then
		uiShared.assertNumberIntNotNaN(1, i)
		if i < 1 or i > #self.options then
			error("argument #2: index is out of range.")
		end
	end
	--]]

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

	-- Assertions
	-- [[
	uiShared.assertNumberNotNaN(1, index)
	--]]

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

	-- Assertions
	-- [[
	uiShared.assertNumberNotNaN(1, delta)
	--]]

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


local function inViewport2(self, x, y)
	return (x >= self.vp2_x and x < self.vp2_x + self.vp2_w and y >= self.vp2_y and y < self.vp2_y + self.vp2_h)
end


local function inViewport3(self, x, y)
	return (x >= self.vp3_x and x < self.vp3_x + self.vp3_w and y >= self.vp3_y and y < self.vp3_y + self.vp3_h)
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)
		widShared.setupViewport(self, 3)

		lgcLabel.setup(self)

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

		self:reshape()
	end
end


function def:uiCall_reshape()

	-- Viewport #1 is the label bounding box.
	-- Viewport #2 is the "prev" button component.
	-- Viewport #3 is the "next" button component.

	local skin = self.skin

	widShared.resetViewport(self, 1)

	if self.vertical then
		widShared.partitionViewport(self, 1, 2, skin.prev_spacing, "top")
		widShared.partitionViewport(self, 1, 3, skin.next_spacing, "bottom")

	else
		widShared.partitionViewport(self, 1, 2, skin.prev_spacing, "left")
		widShared.partitionViewport(self, 1, 3, skin.next_spacing, "right")
	end

	widShared.carveViewport(self, 1, "border")
	widShared.carveViewport(self, 1, "margin")
	lgcLabel.reshapeLabel(self)
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble()
				end

				if button == 1 then
					self.pressed = true
					self:setCursorHigh(self.skin.cursor_press)

					x, y = self:getRelativePosition(x, y)

					if self.b_prev_enabled and inViewport2(self, x, y) then
						self.b_pressing = "prev"
						self:stepIndex(-1)

					elseif self.b_next_enabled and inViewport3(self, x, y) then

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


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)

	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					x, y = self:getRelativePosition(x, y)

					if self.b_pressing == "prev" and inViewport2(self, x, y) then
						self:stepIndex(-1)

					elseif self.b_pressing == "next" and inViewport3(self, x, y) then
						self:stepIndex(1)
					end
				end
			end
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)

	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self:setCursorHigh()

					self.b_pressing = false
				end
			end
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

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


function def:uiCall_pointerWheel(inst, x, y)

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


def.skinners = {
	default = {
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
			uiGraphics.drawSlice(sl_button, self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)
			uiGraphics.quadShrinkOrCenterXYWH(tq_prev, self.vp2_x + button_ox, self.vp2_y + button_oy, self.vp2_w, self.vp2_h)


			if self.b_pressing == "next" then
				button_ox, button_oy = res.button_ox, res.button_oy
				sl_button = res.sl_button

			else
				button_ox, button_oy = 0, 0
				sl_button = res.sl_button_up
			end
			uiGraphics.drawSlice(sl_button, self.vp3_x, self.vp3_y, self.vp3_w, self.vp3_h)
			uiGraphics.quadShrinkOrCenterXYWH(tq_next, self.vp3_x + button_ox, self.vp3_y + button_oy, self.vp3_w, self.vp3_h)

			if self.label_mode then
				lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, 0, 0, ox, oy)
			end

			-- XXX: Debug border (viewport rectangle)
			--[[
			widDebug.debugDrawViewport(self, 1)
			widDebug.debugDrawViewport(self, 2)
			widDebug.debugDrawViewport(self, 3)
			--]]
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy) end,
	},
}


return def
