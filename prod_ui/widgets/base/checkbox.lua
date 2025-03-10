--[[
	A skinned checkbox.
--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local lgcLabel = context:getLua("shared/lgc_label")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "checkbox1",
}


def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setChecked = lgcButton.setChecked
def.setLabel = lgcLabel.widSetLabel


def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_pointerPress = lgcButton.uiCall_pointerPress
def.uiCall_pointerRelease = lgcButton.uiCall_pointerReleaseCheck
def.uiCall_pointerUnpress = lgcButton.uiCall_pointerUnpress
def.uiCall_thimbleAction = lgcButton.uiCall_thimbleActionCheck
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupViewports(self, 2)

	lgcLabel.setup(self)

	-- Checkbox state.
	self.checked = false

	-- [XXX 8] (Optional) image associated with the button.
	--self.graphic = <tq>

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapeInner2()
	-- Viewport #1 is the text bounding box.
	-- Viewport #2 is the bijou drawing rectangle.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)
	widShared.splitViewport(self, 1, 2, false, skin.bijou_spacing, (skin.bijou_side == "right"))
	widShared.carveViewport(self, 2, skin.box.margin)
	lgcLabel.reshapeLabel(self)
end


return def
