--[[
	A skinned radio button.
	Within a group of radio buttons, up to one button may be active at a time.
--]]


local context = select(1, ...)


local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcButton = context:getLua("shared/wc/wc_button")
local wcLabel = context:getLua("shared/wc/wc_label")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "radio1",

	user_callbacks = {} -- modified by wcButton
}


wcButton.setupDefRadioButton(def)


def.setLabel = wcLabel.widSetLabel


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)

	wcLabel.setup(self)

	-- Identifier.
	self.is_radio_button = true

	-- The group that this radio button belongs to. The default is an empty string.
	-- Group scope is among siblings.
	self.radio_group = ""

	-- Radio button state.
	self.checked = false

	-- Cursor IDs for hover and press states.
	self.cursor_on = "hand"
	self.cursor_press = "hand"

	-- [XXX 8] (Optional) image associated with the button.
	--self.graphic = <tq>

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	-- Placement of a single visual element.
	--self.bijou_side_h = "left" -- left (default), right

	self:skinSetRefs()
	self:skinInstall()
end


function def:evt_getGrowAxisLength(x_axis, cross_length)
	if not x_axis then
		return self.skin.default_height, true
	end
end


function def:evt_reshapePre()
	-- Viewport #1 is the text bounding box.
	-- Viewport #2 is the bijou drawing rectangle.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)
	vp:split(vp2, skin.bijou_side_h, skin.bijou_spacing)
	vp2:reduceT(skin.box.margin)

	wcLabel.reshapeLabel(self)

	return true
end


function def:evt_destroy(targ)
	if self == targ then
		widShared.removeViewports(self, 2)
	end
end


return def
