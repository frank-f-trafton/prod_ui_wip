--[[
A skinned button which activates on click-down (without repeat events).

(No relation to Immediate Mode GUIs.)
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


wcButton.setupDefImmediate(def)


def.setLabel = wcLabel.widSetLabel


function def:evt_initialize()
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


function def:evt_reshapePre()
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


function def:evt_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 2)
	end
end


return def
