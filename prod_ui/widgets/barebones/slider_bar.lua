--[[
	A barebones slider bar. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local lgcButtonBare = context:getLua("shared/lgc_button_bare")
local lgcLabelBare = context:getLua("shared/lgc_label_bare")
local lgcSlider = context:getLua("shared/lgc_slider")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local widShared = context:getLua("core/wid_shared")


local def = {}


-- Called when the slider state changes.
function def:wid_actionSliderChanged()

end


def.setEnabled = lgcButtonBare.setEnabled
def.setLabel = lgcLabelBare.widSetLabel


lgcSlider.setupMethods(def)


def.uiCall_pointerHoverOn = lgcButtonBare.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButtonBare.uiCall_pointerHoverOff
def.uiCall_pointerUnpress = lgcButtonBare.uiCall_pointerUnpress


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	lgcLabelBare.setup(self)
	lgcSlider.setup(self)

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false
end


-- XXX: No barebones widget should depend on reshaping.
function def:uiCall_reshapePre()
	-- The label and trough both use the widget dimensions as bounding boxes.

	self.trough_x = 0
	self.trough_y = 0
	self.trough_w = self.w
	self.trough_h = self.h

	if self.trough_vertical then
		self.thumb_x = 0
		self.thumb_w = self.w
		self.thumb_h = math.floor(math.max(1, 6 * self.context.scale))

		self.trough_h = self.trough_h - self.thumb_h
	else
		self.thumb_y = 0
		self.thumb_w = math.floor(math.max(1, 6 * self.context.scale))
		self.thumb_h = self.h

		self.trough_w = self.trough_w - self.thumb_w
	end

	local slider_pos_old = self.slider_pos
	lgcSlider.processMovedSliderPos(self)
	if self.slider_pos ~= slider_pos_old then
		self:wid_actionSliderChanged()
	end
	-- 'trough home' is not supported.

	return true
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if self.context.mouse_pressed_button == button then
				if button <= 3 then
					self:takeThimble1()
				end

				x, y = self:getRelativePosition(x, y)

				if button == 1 and self.context.mouse_pressed_button == button then
					if lgcSlider.checkMousePress(self, x, y, true) then
						self.pressed = true
					end
				end
			end
		end
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			if self.pressed then
				local x, y = self:getRelativePosition(mouse_x, mouse_y)
				lgcSlider.checkMousePress(self, x, y, true)
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


def.render = context:getLua("shared/render_button_bare").slider


return def
