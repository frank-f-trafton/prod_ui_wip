--[[
	A skinned, multi-state checkbox.

	States are represented as an integer in 'self.value', from 1 to 'self.value_max'. The default
	max value is 3, because it is assumed that this widget will most likely be used to implement
	tri-state checkboxes.

	The skin must provide graphics for each state; the default skins include graphics for three
	states. For any states which do not have a graphic, the widget will debug-print 'self.value'
	using the theme's internal font.
--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local lgcLabel = context:getLua("shared/lgc_label")
local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local _lerp = pMath.lerp


local def = {
	skin_id = "checkbox_multi1",
}


def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setValue = lgcButton.setValue
def.setMaxValue = lgcButton.setMaxValue
def.rollValue = lgcButton.rollValue
def.setLabel = lgcLabel.widSetLabel


def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_pointerPress = lgcButton.uiCall_pointerPress
def.uiCall_pointerRelease = lgcButton.uiCall_pointerReleaseCheckMulti
def.uiCall_pointerUnpress = lgcButton.uiCall_pointerUnpress
def.uiCall_thimbleAction = lgcButton.uiCall_thimbleActionCheckMulti
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 2)

	lgcLabel.setup(self)

	self.value = 1
	self.value_max = 3

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
	vp:split(vp2, skin.bijou_side_h, skin.bijou_spacing)

	vp2:reduceT(skin.box.margin)

	lgcLabel.reshapeLabel(self)

	return true
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res_quads_state = uiSchema.newModel {
	array = themeAssert.quad
}


local md_res = uiSchema.newKeysX {
	quads_state = md_res_quads_state,

	color_bijou = uiAssert.loveColorTuple,
	color_label = uiAssert.loveColorTuple,

	label_ox = uiAssert.int,
	label_oy = uiAssert.int
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		label_style = themeAssert.labelStyle,
		tq_px = themeAssert.quad,

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Checkbox (quad) render size.
		bijou_w = {uiAssert.numberGE, 0},
		bijou_h = {uiAssert.numberGE, 0},

		-- Horizontal spacing between checkbox area and text label.
		bijou_spacing = {uiAssert.numberGE, 0},

		-- Checkbox horizontal placement.
		bijou_side_h = {uiAssert.namedMap, uiTheme.named_maps.bijou_side_h},

		-- Alignment of bijou within Viewport #2.
		bijou_align_h = {uiAssert.numberRange, 0.0, 1.0},
		bijou_align_v = {uiAssert.numberRange, 0.0, 1.0},

		-- Alignment of label text within Viewport #1.
		label_align_h = {uiAssert.namedMap, uiTheme.named_maps.label_align_h},
		label_align_v = {uiAssert.numberRange, 0.0, 1.0},

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "bijou_w")
		uiScale.fieldInteger(scale, skin, "bijou_h")
		uiScale.fieldInteger(scale, skin, "bijou_spacing")

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


	--refresh = function (self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp2 = self.vp2
		local res = uiTheme.pickButtonResource(self, skin)
		local tex_quad = res.quads_state[self.value]

		-- bijou drawing coordinates
		local box_x = math.floor(0.5 + _lerp(vp2.x, vp2.x + vp2.w - skin.bijou_w, skin.bijou_align_h))
		local box_y = math.floor(0.5 + _lerp(vp2.y, vp2.y + vp2.h - skin.bijou_h, skin.bijou_align_v))

		-- Draw the bijou.
		-- XXX: Scissor to Viewport #2?

		if tex_quad then
			love.graphics.setColor(res.color_bijou)
			uiGraphics.quadXYWH(tex_quad, box_x, box_y, skin.bijou_w, skin.bijou_h)
		else
			-- Debug-print state values that do not have a matching quad.
			love.graphics.push("all")

			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.setFont(self.context.resources.fonts.internal)
			love.graphics.print(tostring(self.value), box_x, box_y)

			love.graphics.pop()
		end

		-- Draw the text label.
		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,
}


return def
