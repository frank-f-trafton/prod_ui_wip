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


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local lgcButton = context:getLua("shared/lgc_button")
local lgcLabel = context:getLua("shared/lgc_label")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local _lerp = commonMath.lerp


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
	self.can_have_thimble = true

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
	local skin = self.skin

	-- Viewport #1 is the text bounding box.
	-- Viewport #2 is the bijou drawing rectangle.

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)
	widShared.splitViewport(self, 1, 2, false, skin.bijou_spacing, (skin.bijou_side_h == "right"))
	widShared.carveViewport(self, 2, skin.box.margin)
	lgcLabel.reshapeLabel(self)

	return true
end


local check = uiTheme.check
local change = uiTheme.change


local function _checkRes(res)
	check.type(res, "quads_state", "table")
	for i in ipairs(res.quads_state) do
		check.quad(res, i)
	end
	check.colorTuple(res, "color_bijou")
	check.colorTuple(res, "color_label")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")
end


local function _changeRes(res, scale)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.labelStyle(skin, "label_style")
		check.quad(skin, "tq_px")

		-- Cursor IDs for hover and press states.
		check.type(skin, "cursor_on", "nil", "string")
		check.type(skin, "cursor_press", "nil", "string")

		-- Checkbox (quad) render size.
		check.integer(skin, "bijou_w", 0)
		check.integer(skin, "bijou_h", 0)

		-- Horizontal spacing between checkbox area and text label.
		check.integer(skin, "bijou_spacing", 0)

		-- Checkbox horizontal placement.
		check.enum(skin, "bijou_side_h")

		-- Alignment of bijou within Viewport #2.
		check.unitInterval(skin, "bijou_align_h")
		check.unitInterval(skin, "bijou_align_v")

		-- Alignment of label text within Viewport #1.
		check.enum(skin, "label_align_h")
		check.enum(skin, "label_align_v")

		_checkRes(check.getRes(skin, "res_idle"))
		_checkRes(check.getRes(skin, "res_hover"))
		_checkRes(check.getRes(skin, "res_pressed"))
		_checkRes(check.getRes(skin, "res_disabled"))
	end,


	transform = function(skin, scale)
		change.scaledInt(skin, "bijou_w", scale)
		change.scaledInt(skin, "bijou_h", scale)
		change.scaledInt(skin, "bijou_spacing", scale)

		_changeRes(check.getRes(skin, "res_idle"), scale)
		_changeRes(check.getRes(skin, "res_hover"), scale)
		_changeRes(check.getRes(skin, "res_pressed"), scale)
		_changeRes(check.getRes(skin, "res_disabled"), scale)
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
		local res = uiTheme.pickButtonResource(self, skin)
		local tex_quad = res.quads_state[self.value]

		-- bijou drawing coordinates
		local box_x = math.floor(0.5 + _lerp(self.vp2_x, self.vp2_x + self.vp2_w - skin.bijou_w, skin.bijou_align_h))
		local box_y = math.floor(0.5 + _lerp(self.vp2_y, self.vp2_y + self.vp2_h - skin.bijou_h, skin.bijou_align_v))

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
