-- WIP: copy of base/slider_bar.lua

--[[
base/slider_radial: A dial slider.
--]]

--[[
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

local lgcButton = context:getLua("shared/lgc_button")
local lgcLabel = context:getLua("shared/lgc_label")
local lgcSlider = context:getLua("shared/lgc_slider")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "slider_radial1",
}


-- Called when the slider state changes.
function def:wid_actionSliderChanged()
	--print("Slider changed.", self.slider_pos, "/", self.slider_max)
	--print(self.trough_x, self.trough_y, self.trough_w, self.trough_h)
	--print(self.thumb_x, self.thumb_y, self.thumb_w, self.thumb_h)
end


-- NOTE: The primary button action is activated by keyboard input only.
def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setLabel = lgcLabel.widSetLabel


lgcSlider.setupMethods(def)


def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_pointerUnpress = lgcButton.uiCall_pointerUnpress
def.uiCall_thimbleAction = lgcButton.uiCall_thimbleAction -- TODO: plug into widget
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2 -- TODO: plug into widget


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewports(self, 2)

		lgcLabel.setup(self)

		-- Stuff copied from lgcSlider.setup().

		-- When false, the slider control should not respond to user input.
		-- This field does not prevent self:setSlider() from modifying the slider state. Nor does it
		-- affect the status of the parent widget as a whole (as in, it may still be capable of holding
		-- the UI thimble).
		self.slider_allow_changes = true

		-- Slider value state.
		-- Internally, the slider position ranges from 0 to 'slider_max' in a linear fashion.
		self.slider_pos = 0
		self.slider_min = 0
		self.slider_max = 0
		self.slider_def = 0 -- default
		self.slider_home = 0 -- "home" position, usually zero.

		self.round_policy = "none" -- "none", "floor", "ceil", "nearest"

		self.clockwise = true
		self.home_radian = 0

		-- Lighten the "used" side of the trough.
		self.show_use_line = true

		-- State flags
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()
	end
end


local function _roundPos(self)
	local mode = self.round_policy

	if mode == "none" then
		return

	elseif mode == "floor" then
		self.slider_pos = math.floor(self.slider_pos)

	elseif mode == "ceil" then
		self.slider_pos = math.ceil(self.slider_pos)

	elseif mode == "nearest" then
		self.slider_pos = math.floor(0.5 + self.slider_pos)

	else
		error("invalid round mode: " .. tostring(mode))
	end
end


local function _clampPos(self)
	self.slider_pos = math.max(self.slider_min, math.min(self.slider_pos, self.slider_max))
end


local function _processMovedSliderPos(self)
	_roundPos(self)
	_clampPos(self)
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

	local slider_pos_old = self.slider_pos
	_processMovedSliderPos(self)
	if self.slider_pos ~= slider_pos_old then
		self:wid_actionSliderChanged()
	end
	--lgcSlider.updateTroughHome(self)

	lgcLabel.reshapeLabel(self)
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if self.context.mouse_pressed_button == button then
				if button <= 3 then
					self:takeThimble1()
				end

				if button == 1 then
					local mx, my = self:getRelativePosition(x, y)
					-- WIP
					--[[
					if lgcSlider.checkMousePress(self, x, y, self.skin.trough_click_anywhere) then
						self.pressed = true
					end
					--]]
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
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			if self.pressed then
				if self.context.mouse_pressed_button == 1 then
					-- WIP
					--[[
					local x, y = self:getRelativePosition(mouse_x, mouse_y)
					lgcSlider.checkMousePress(self, x, y, self.skin.trough_click_anywhere)
					--]]
				end
			end
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			-- WIP
			--[[
			return lgcSlider.checkKeyPress(self, key, scancode, isrepeat)
			--]]
		end
	end
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

		-- WIP: Trough
		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
		love.graphics.arc("line", "open", cx, cy, radius, 0, math.pi, 64)

		-- WIP: Dial
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.line(cx, cy, cx + radius, cy)

		-- Optional label
		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,
}

return def
