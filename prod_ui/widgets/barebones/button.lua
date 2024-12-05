--[[
	A barebones button. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local lgcButtonBare = context:getLua("shared/lgc_button_bare")
local lgcLabelBare = context:getLua("shared/lgc_label_bare")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {}


def.wid_buttonAction = lgcButtonBare.wid_buttonAction
def.wid_buttonAction2 = lgcButtonBare.wid_buttonAction2
def.wid_buttonAction3 = lgcButtonBare.wid_buttonAction3


def.setEnabled = lgcButtonBare.setEnabled
def.setLabel = lgcLabelBare.widSetLabel


def.uiCall_pointerHoverOn = lgcButtonBare.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButtonBare.uiCall_pointerHoverOff
def.uiCall_pointerPress = lgcButtonBare.uiCall_pointerPress
def.uiCall_pointerRelease = lgcButtonBare.uiCall_pointerReleaseActivate
def.uiCall_pointerUnpress = lgcButtonBare.uiCall_pointerUnpress
def.uiCall_thimbleAction = lgcButtonBare.uiCall_thimbleAction
def.uiCall_thimbleAction2 = lgcButtonBare.uiCall_thimbleAction2


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		lgcLabelBare.setup(self)

		-- State flags
		self.enabled = true
		self.hovered = false
		self.pressed = false
	end
end


def.render = context:getLua("shared/skn_button_bare")


return def
