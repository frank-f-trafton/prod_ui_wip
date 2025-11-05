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

local lgcSlider = context:getLua("shared/lgc_slider")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcButton = context:getLua("shared/wc/wc_button")
local wcLabel = context:getLua("shared/wc/wc_label")
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
def.wid_buttonAction = wcButton.wid_buttonAction
def.wid_buttonAction2 = wcButton.wid_buttonAction2
def.wid_buttonAction3 = wcButton.wid_buttonAction3


def.setEnabled = wcButton.setEnabled
def.setLabel = wcLabel.widSetLabel


lgcSlider.setupMethods(def)


def.uiCall_pointerHoverOn = wcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = wcButton.uiCall_pointerHoverOff
def.uiCall_pointerUnpress = wcButton.uiCall_pointerUnpress
def.uiCall_thimbleAction = wcButton.uiCall_thimbleAction -- TODO: plug into widget
def.uiCall_thimbleAction2 = wcButton.uiCall_thimbleAction2 -- TODO: plug into widget


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)

	wcLabel.setup(self)
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
	local vp, vp2 = self.vp, self.vp2

	vp2:set(0, 0, self.w, self.h)
	vp2:reduceT(skin.box.border)
	vp2:splitOrOverlay(vp, skin.label_placement, skin.label_spacing)
	vp:reduceT(skin.box.margin)

	lgcSlider.reshapeSliderComponent(self, vp2.x, vp2.y, vp2.w, vp2.h, skin.thumb_w, skin.thumb_h)

	local slider_pos_old = self.slider_pos
	lgcSlider.processMovedSliderPos(self)
	if self.slider_pos ~= slider_pos_old then
		self:wid_actionSliderChanged()
	end
	lgcSlider.updateTroughHome(self)

	wcLabel.reshapeLabel(self)

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


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	tq_thumb = themeAssert.quad,
	sl_trough_active = themeAssert.slice,
	sl_trough_empty = themeAssert.slice,
	color_label = uiAssert.loveColorTuple,
	label_ox = uiAssert.integer,
	label_oy = uiAssert.integer
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		label_style = themeAssert.labelStyle,
		tq_px = themeAssert.quad,

		-- Label placement and spacing.
		label_spacing = {uiAssert.integerGE, 0},
		label_placement = {uiAssert.oneOf, "left", "right", "top", "bottom", "overlay"},

		-- For the empty part.
		trough_breadth = {uiAssert.integerGE, 0},

		-- For the in-use part.
		trough_breadth2 = {uiAssert.integerGE, 0},

		-- When true, engage thumb-moving state even if the user clicked outside of the trough area.
		trough_click_anywhere = {uiAssert.types, "nil", "boolean"},

		-- Thumb visual dimensions. The size may be reduced if it does not fit into the trough.
		thumb_w = {uiAssert.integerGE, 0},
		thumb_h = {uiAssert.integerGE, 0},

		-- Thumb visual offsets.
		thumb_ox = uiAssert.integer,
		thumb_oy = uiAssert.integer,

		-- Adjusts the visual length of the trough line. Positive extends, negative reduces.
		trough_ext = uiAssert.integer,

		-- Cursor IDs for hover and press states (when over the trough area).
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Label config.
		label_align_h = {uiAssert.namedMap, uiTheme.named_maps.label_align_h},
		label_align_v = {uiAssert.namedMap, uiTheme.named_maps.label_align_v},

		--[[
		TODO: an old WIP note:

		quads:
		slider_trough_tick_minor
		slider_trough_tick_major
		--]]

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "label_spacing")
		uiScale.fieldInteger(scale, skin, "trough_breadth")
		uiScale.fieldInteger(scale, skin, "trough_breadth2")
		uiScale.fieldInteger(scale, skin, "thumb_w")
		uiScale.fieldInteger(scale, skin, "thumb_h")
		uiScale.fieldInteger(scale, skin, "thumb_ox")
		uiScale.fieldInteger(scale, skin, "thumb_oy")
		uiScale.fieldInteger(scale, skin, "trough_ext")

		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "label_ox")
			uiScale.fieldInteger(scale, res, "label_oy")
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
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,
}

return def
