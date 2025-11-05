--[[
A skinned button that activates on click-down, and which remains pressed until external code restores it.
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcButton = context:getLua("shared/wc/wc_button")
local wcLabel = context:getLua("shared/wc/wc_label")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "button1",
}


def.wid_buttonAction = wcButton.wid_buttonAction
def.wid_buttonAction2 = wcButton.wid_buttonAction2
def.wid_buttonAction3 = wcButton.wid_buttonAction3


def.setEnabled = wcButton.setEnabledSticky
def.setPressed = wcButton.setPressedSticky
def.setLabel = wcLabel.widSetLabel


def.uiCall_pointerHoverOn = wcButton.uiCall_pointerHoverOnSticky
def.uiCall_pointerHoverOff = wcButton.uiCall_pointerHoverOff
def.uiCall_pointerPress = wcButton.uiCall_pointerPressSticky
def.uiCall_thimbleAction = wcButton.uiCall_thimbleActionSticky
def.uiCall_thimbleAction2 = wcButton.uiCall_thimbleAction2


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)

	wcLabel.setup(self)

	-- [XXX 8] (Optional) image associated with the button.
	--self.graphic = <tq>

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self:reshape()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the text bounding box.
	-- Viewport #2 is the graphic drawing rectangle.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)
	vp:splitOrOverlay(vp2, skin.graphic_placement, skin.graphic_spacing)

	vp2:reduceT(skin.box.margin)

	wcLabel.reshapeLabel(self)

	return true
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 2)
	end
end


return def
