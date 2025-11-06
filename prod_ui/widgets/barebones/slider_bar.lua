--[[
	A barebones slider bar. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local wcButtonBare = context:getLua("shared/wc/wc_button_bare")
local wcLabelBare = context:getLua("shared/wc/wc_label_bare")
local wcSlider = context:getLua("shared/wc/wc_slider")
local widShared = context:getLua("core/wid_shared")


local def = {}


-- Called when the slider state changes.
function def:wid_actionSliderChanged()

end


def.setEnabled = wcButtonBare.setEnabled
def.setLabel = wcLabelBare.widSetLabel


wcSlider.setupMethods(def)


def.uiCall_pointerHoverOn = wcButtonBare.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = wcButtonBare.uiCall_pointerHoverOff
def.uiCall_pointerUnpress = wcButtonBare.uiCall_pointerUnpress


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	wcLabelBare.setup(self)
	wcSlider.setup(self)

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
	wcSlider.processMovedSliderPos(self)
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
					if wcSlider.checkMousePress(self, x, y, true) then
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
				wcSlider.checkMousePress(self, x, y, true)
			end
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			return wcSlider.checkKeyPress(self, key, scancode, isrepeat)
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		if self.enabled then
			return wcSlider.mouseWheelLogic(self, x, y)
		end
	end
end


def.render = context:getLua("shared/render_button_bare").slider


return def
