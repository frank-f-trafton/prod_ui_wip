--[[
TODO:

* Visible ticks with simple text labels (not "capital-L" Labels).

--]]

--[[
base/slider_bar: A horizontal or vertical slider bar.

This widget supports an optional text label, but a customized skin is required for correct placement of label and control.
--]]

--[[
Trough
  |   Thumb
  |   |
  v   v
┌──────────────┐
│ ┅┅┅┅O┅┅┅┅┅┅┅ │
└──────────────┘

  ║          ║
  ╚════╦═════╝
       ║
      VP2


┌───┐
│   │
│ ┇ │
│ ┇ │
│ O │  Vertical layout
│ ┇ │
│   │
└───┘
--]]


local context = select(1, ...)

local lgcButton = context:getLua("shared/lgc_button")
local lgcLabel = context:getLua("shared/lgc_label")
local lgcSlider = context:getLua("shared/lgc_slider")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "slider1",
}


-- Called when the slider state changes.
function def:wid_actionSliderChanged()
	--print("Slider changed.", self.slider_pos, "/", self.slider_max)
	--print(self.trough_x, self.trough_y, self.trough_w, self.trough_h)
	--print(self.thumb_x, self.thumb_y, self.thumb_w, self.thumb_h)
end


-- NOTE: The primary button action is activated by keyboard input only. Click-activated
-- secondary and tertiary actions do not account for the mouse cursor being within the
-- clickable trough area. (That is, right or middle-clicking anywhere on the widget will
-- activate actions 2 and 3, respectively).
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


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupViewports(self, 2)

	lgcLabel.setup(self)
	lgcSlider.setup(self)

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the label bounding box.
	-- Viewport #2 defines the trough bounding box (stored in self.trough_x|y|w|h).
	-- Border applies to viewports: 1, 2
	-- Margin applies to viewports: 1

	local skin = self.skin

	widShared.resetViewport(self, 2)
	widShared.carveViewport(self, 2, skin.box.border)
	widShared.partitionViewport(self, 2, 1, skin.label_spacing, skin.label_placement, true)
	widShared.carveViewport(self, 1, skin.box.margin)

	lgcSlider.reshapeSliderComponent(self, self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h, skin.thumb_w, skin.thumb_h)

	local slider_pos_old = self.slider_pos
	lgcSlider.processMovedSliderPos(self)
	if self.slider_pos ~= slider_pos_old then
		self:wid_actionSliderChanged()
	end
	lgcSlider.updateTroughHome(self)

	lgcLabel.reshapeLabel(self)

	return true
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
					if lgcSlider.checkMousePress(self, mx, my, self.skin.trough_click_anywhere) then
						self.pressed = true
					end

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
					local mx, my = self:getRelativePosition(mouse_x, mouse_y)
					lgcSlider.checkMousePress(self, mx, my, self.skin.trough_click_anywhere)
				end
			end
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			return lgcSlider.checkKeyPress(self, key, scancode, isrepeat)
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		if self.enabled then
			return lgcSlider.mouseWheelLogic(self, x, y)
		end
	end
end


local check = uiTheme.check
local change = uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.quad(res, "tq_thumb")
	check.slice(res, "sl_trough_active")
	check.slice(res, "sl_trough_empty")
	check.colorTuple(res, "color_label")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.labelStyle(skin, "label_style")
		check.quad(skin, "tq_px")

		-- Label placement and spacing.
		check.integer(skin, "label_spacing", 0)
		check.exact(skin, "label_placement", "left", "right", "top", "bottom", "overlay")

		-- For the empty part.
		check.integer(skin, "trough_breadth", 0)

		-- For the in-use part.
		check.integer(skin, "trough_breadth2", 0)

		-- When true, engage thumb-moving state even if the user clicked outside of the trough area.
		check.type(skin, "trough_click_anywhere", "nil", "boolean")

		-- Thumb visual dimensions. The size may be reduced if it does not fit into the trough.
		check.integer(skin, "thumb_w", 0)
		check.integer(skin, "thumb_h", 0)

		-- Thumb visual offsets.
		check.integer(skin, "thumb_ox", 0)
		check.integer(skin, "thumb_oy", 0)

		-- Adjusts the visual length of the trough line. Positive extends, negative reduces.
		check.integer(skin, "trough_ext")

		-- Cursor IDs for hover and press states (when over the trough area).
		check.type(skin, "cursor_on", "nil", "string")
		check.type(skin, "cursor_press", "nil", "string")

		-- Label config.
		check.enum(skin, "label_align_h")
		check.enum(skin, "label_align_v")

		--[[
		TODO: an old WIP note:

		quads:
		slider_trough_tick_minor
		slider_trough_tick_major
		--]]

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_hover")
		_checkRes(skin, "res_pressed")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "label_spacing", scale)
		change.integerScaled(skin, "trough_breadth", scale)
		change.integerScaled(skin, "trough_breadth2", scale)
		change.integerScaled(skin, "thumb_w", scale)
		change.integerScaled(skin, "thumb_h", scale)
		change.integerScaled(skin, "thumb_ox", scale)
		change.integerScaled(skin, "thumb_oy", scale)
		change.integerScaled(skin, "trough_ext", scale)

		_changeRes(skin, "res_idle", scale)
		_changeRes(skin, "res_hover", scale)
		_changeRes(skin, "res_pressed", scale)
		_changeRes(skin, "res_disabled", scale)
	end,


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

		-- Trough line
		local trough_ext = skin.trough_ext
		if self.trough_vertical then
			local trough_x1 = self.trough_x + math.floor(self.trough_w/2 - skin.trough_breadth/2 + 0.5)

			uiGraphics.drawSlice(
				res.sl_trough_empty,
				trough_x1,
				self.trough_y - trough_ext,
				skin.trough_breadth,
				self.trough_h + trough_ext * 2
			)

			if self.show_use_line then
				local trough_x1b = self.trough_x + math.floor(self.trough_w/2 - skin.trough_breadth2/2 + 0.5)
				local y1 = self.trough_y + self.trough_home
				local y2 = self.trough_y + self.thumb_y
				if y1 > y2 then
					y1, y2 = y2, y1
				end

				uiGraphics.drawSlice(
					res.sl_trough_active,
					trough_x1b,
					y1,
					skin.trough_breadth2,
					y2 - y1
				)
				--print("y1, y2", y1, y2)
			end
		else -- horizontal
			local trough_y1 = self.trough_y + math.floor(self.trough_h/2 - skin.trough_breadth/2 + 0.5)

			uiGraphics.drawSlice(
				res.sl_trough_empty,
				self.trough_x - trough_ext,
				trough_y1,
				self.trough_w + trough_ext * 2,
				skin.trough_breadth
			)

			if self.show_use_line then
				local trough_y1b = self.trough_y + math.floor(self.trough_h/2 - skin.trough_breadth2/2 + 0.5)
				local x1 = self.trough_x + self.trough_home
				local x2 = self.trough_x + self.thumb_x
				if x1 > x2 then
					x1, x2 = x2, x1
				end

				uiGraphics.drawSlice(
					res.sl_trough_active,
					x1,
					trough_y1b,
					x2 - x1,
					skin.trough_breadth2
				)
			end
		end

		-- Thumb
		uiGraphics.quadXYWH(
			res.tq_thumb,
			self.trough_x + self.thumb_x - skin.thumb_ox,
			self.trough_y + self.thumb_y - skin.thumb_oy,
			self.thumb_w,
			self.thumb_h
		)
		-- Debug
		--[[
		love.graphics.print(
			"trough: " .. self.trough_x .. ", " .. self.trough_y .. ", " .. self.trough_w .. ", " .. self.trough_h .. "\n" ..
			"thumb: " .. self.thumb_x .. ", " .. self.thumb_y .. ", " .. self.thumb_w .. ", " .. self.thumb_h .. "\n" ..
			"",
			256, 0
		)
		--]]

		-- Optional label
		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,
}

return def
