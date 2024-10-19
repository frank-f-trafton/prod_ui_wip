--[[
A barebones sticky button. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local lgcButtonBare = context:getLua("shared/lgc_button_bare")
local lgcLabelBare = context:getLua("shared/lgc_label_bare")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {}


def.wid_buttonAction = lgcButtonBare.wid_buttonAction
def.wid_buttonAction2 = lgcButtonBare.wid_buttonAction2
def.wid_buttonAction3 = lgcButtonBare.wid_buttonAction3


def.setEnabled = lgcButtonBare.setEnabledSticky
def.setPressed = lgcButtonBare.setPressedSticky
def.setLabel = lgcLabelBare.widSetLabel


def.uiCall_pointerHoverOn = lgcButtonBare.uiCall_pointerHoverOnSticky
def.uiCall_pointerHoverOff = lgcButtonBare.uiCall_pointerHoverOff
def.uiCall_pointerPress = lgcButtonBare.uiCall_pointerPressSticky
def.uiCall_thimbleAction = lgcButtonBare.uiCall_thimbleActionSticky
def.uiCall_thimbleAction2 = lgcButtonBare.uiCall_thimbleAction2


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		lgcLabelBare.setup(self)

		-- (Optional) If true, click-repeat actions can fire if the pointer is outside the widget bounds.
		-- If false/nil, the pointer must be in range.
		--self.click_repeat_oob = false

		-- [XXX 8] (Optional) image associated with the button.
		--self.graphic = <tq>

		-- State flags
		self.enabled = true
		self.hovered = false
		self.pressed = false
	end
end


def.render = context:getLua("shared/skn_button_bare")


return def
