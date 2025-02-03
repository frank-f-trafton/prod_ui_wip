-- WIP: copy of base/slider_bar.lua


--[[
A radial dial.

Click and drag up/down to adjust the dial position.

                    ┌─────────┐
                    │  ┌───┐  │
  Min position-->   │ ┌┘   └┐ │
                    │    ---│ │  <-- Dial, at position 0.0
  Max position -->  │ └┐   ┌┘ │
                    │  └───┘  │
                    └─────────┘
--]]


local context = select(1, ...)


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local lgcButton = context:getLua("shared/lgc_button")
local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local _lerp = commonMath.lerp


local def = {
	skin_id = "dial1",
}


function def:wid_actionDialChanged()
	print("Dial changed.", self.dial_pos, self.dial_min, "/", self.dial_max)
end


-- NOTE: The primary button action is activated by keyboard input only.
def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setLabel = lgcLabel.widSetLabel


local function _roundPos(self)
	local mode = self.round_policy

	if mode == "none" then
		return

	elseif mode == "floor" then
		self.dial_pos = math.floor(self.dial_pos)

	elseif mode == "ceil" then
		self.dial_pos = math.ceil(self.dial_pos)

	elseif mode == "nearest" then
		self.dial_pos = math.floor(0.5 + self.dial_pos)

	else
		error("invalid round mode: " .. tostring(mode))
	end
end


local function _clampPos(self)
	self.dial_pos = math.max(self.dial_min, math.min(self.dial_pos, self.dial_max))
end


local function _processMovedDialPos(self)
	_roundPos(self)
	_clampPos(self)
end


function def:setDialAllowChanges(enabled)
	self.dial_allow_changes = not not enabled
end


function def:setDialPosition(pos)
	uiShared.numberNotNaN(1, pos)

	-- Does not check `self.enabled` or `self.dial_allow_changes`.

	local pos_old = self.dial_pos

	self.dial_pos = pos

	_processMovedDialPos(self)

	if self.dial_pos ~= pos_old then
		self:wid_actionDialChanged()
	end
end


function def:setDialParameters(pos, min, max, home, rnd)
	local pos_old = self.dial_pos

	self.dial_pos = pos or self.dial_pos
	self.dial_min = min or self.dial_min
	self.dial_max = max or self.dial_max
	self.dial_home = home or self.dial_home
	self.round_policy = rnd or self.round_policy

	_processMovedDialPos(self)
	if self.dial_pos ~= pos_old then
		self:wid_actionDialChanged()
	end
end


function def:setDialMax(max)
	uiShared.numberNotNaN(1, max)

	-- Does not check `self.enabled` or `self.dial_allow_changes`.

	local pos_old = self.dial_pos

	self.dial_max = max

	_processMovedDialPos(self)

	if self.dial_pos ~= pos_old then
		self:wid_actionDialChanged()
	end
end



def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_thimbleAction = lgcButton.uiCall_thimbleAction -- TODO: plug into widget
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2 -- TODO: plug into widget


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupViewports(self, 2)

	lgcLabel.setup(self)

	-- Stuff copied from lgcSlider.setup().

	-- When false, the dial control should not respond to user input.
	-- This field does not prevent API calls from modifying the dial state. Nor does it affect
	-- the status of the parent widget as a whole (as in, it may still be capable of holding
	-- the UI thimble).
	self.dial_allow_changes = true

	-- Dial value state.
	self.dial_pos = 0
	self.dial_min = 0
	self.dial_max = 0
	self.dial_home = 0 -- "home" position, usually zero.

	self.round_policy = "none" -- "none", "floor", "ceil", "nearest"

	--self.clockwise = true
	--self.radian_rotate = -math.pi / 2
	self.radian_rotate = 0
	self.radian_min = -math.pi * 0.75
	self.radian_max = math.pi * 0.75

	-- Lighten the "used" side of the trough.
	self.show_use_line = true

	self.press_busy = false -- false, "adjusting"

	-- State flags
	self.enabled = true
	self.hovered = false

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshape()
	-- Viewport #1 is the label bounding box.
	-- Viewport #2 defines the trough bounding box (stored in self.trough_x|y|w|h).
	-- Border applies to viewports: 1, 2
	-- Margin applies to viewports: 1

	local skin = self.skin

	widShared.resetViewport(self, 2)
	widShared.carveViewport(self, 2, skin.box.border)
	widShared.partitionViewport(self, 2, 1, skin.label_spacing, skin.label_placement, true)
	widShared.carveViewport(self, 1, skin.box.margin)

	lgcLabel.reshapeLabel(self)
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and self.context.mouse_pressed_button == button then
		if button <= 3 then
			self:takeThimble1()
		end

		if button == 1 then
			self.press_busy = "adjusting"
			self:setCursorHigh(self.skin.cursor_press)

			-- NOTE: The primary button action is keyboard-only (via thimble code in the root widget).

		elseif button == 2 then
			-- Secondary action.
			self:wid_buttonAction2()

		elseif button == 3 then
			-- Tertiary action.
			self:wid_buttonAction3()
		end
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst
	and self.enabled
	and self.press_busy == "adjusting"
	and self.context.mouse_pressed_button == 1
	then
		local pos_old = self.dial_pos

		self.dial_pos = self.dial_pos + mouse_dy / 4
		_processMovedDialPos(self)

		if self.dial_pos ~= pos_old then
			self:wid_actionDialChanged()
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst
	and button == 1
	and button == self.context.mouse_pressed_button
	then
		self.press_busy = false
		self:setCursorHigh()
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			local additive = 1
			local dir
			local pos_old = self.dial_pos
			if scancode == "up" then
				dir = -1

			elseif scancode == "pageup" then
				dir = -1
				additive = additive * 10

			elseif scancode == "down" then
				dir = 1

			elseif scancode == "pagedown" then
				dir = 1
				additive = additive * 10
			end

			if dir then
				self.dial_pos = self.dial_pos + dir * additive
				_processMovedDialPos(self)
				if self.dial_pos ~= pos_old then
					self:wid_actionDialChanged()
				end
				return true
			end
		end
	end
end


function def:uiCall_update(dt)
	--print("press_busy", self.press_busy, "pos", self.dial_pos)
	--self.radian_rotate = self.radian_rotate + dt
end


def.default_skinner = {
	schema = {
		label_spacing = "scaled-int",
		trough_breadth = "scaled-int",
		trough_breadth2 = "scaled-int",

		res_idle = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},

		res_hover = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},

		res_pressed = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},

		res_disabled = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},
	},


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

		love.graphics.setColor(1, 1, 1, 1)

		local cx = self.vp_x + math.floor(self.vp_w / 2)
		local cy = self.vp_y + math.floor(self.vp_h / 2)
		local radius = math.floor(self.vp_w/2)

		love.graphics.push("all")

		love.graphics.translate(cx + 0.5, cy+ 0.5)
		love.graphics.rotate(self.radian_rotate)

		-- WIP: Trough
		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
		love.graphics.arc("line", "open", 0, 0, radius, self.radian_min, self.radian_max, 64)

		-- WIP: Dial
		local rot = _lerp(self.radian_min, self.radian_max, (self.dial_pos - self.dial_min) / self.dial_max)
		love.graphics.rotate(rot)

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.line(0, 0, radius, 0)

		love.graphics.pop()

		-- Optional label
		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,
}

return def
