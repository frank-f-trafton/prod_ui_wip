-- WIP

--[[
	Embedded checkbox.
--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
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
	skin_id = "checkbox_emb1",
}


def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setChecked = lgcButton.setChecked


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
	self.thimble_mode = 1

	widShared.setupViewports(self, 1)

	-- Checkbox state.
	self.checked = false

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self:reshape()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the checkbox rectangle.

	local vp = self.vp

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(self.skin.box.border)
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 1)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	quad_checked = themeAssert.quad,
	quad_unchecked = themeAssert.quad,

	color_bijou = uiAssert.loveColorTuple
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		tq_px = themeAssert.quad,

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Checkbox (quad) render size.
		bijou_w = {uiAssert.integer, 0},
		bijou_h = {uiAssert.integer, 0},

		-- Alignment of bijou within Viewport #1.
		bijou_align_h = {uiAssert.numberRange, 0.0, 1.0},
		bijou_align_v = {uiAssert.numberRange, 0.0, 1.0},

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "bijou_w")
		uiScale.fieldInteger(scale, skin, "bijou_h")
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp = self.vp
		local res = uiTheme.pickButtonResource(self, skin)
		local tex_quad = self.checked and res.quad_checked or res.quad_unchecked

		-- bijou drawing coordinates
		local box_x = math.floor(0.5 + _lerp(vp.x, vp.x + vp.w - skin.bijou_w, skin.bijou_align_h))
		local box_y = math.floor(0.5 + _lerp(vp.y, vp.y + vp.h - skin.bijou_h, skin.bijou_align_v))

		-- draw bijou
		-- XXX: Scissor to Viewport #1?
		love.graphics.setColor(res.color_bijou)
		uiGraphics.quadXYWH(tex_quad, box_x, box_y, skin.bijou_w, skin.bijou_h)

		-- XXX: Debug border (viewport rectangle)
		--[[
		widDebug.debugDrawViewport(self, 1)
		widDebug.debugDrawViewport(self, 2)
		--]]

		-- old debugging
		--[[
		love.graphics.push("all")
		love.graphics.setColor(1, 1, 1, 1)
		local rect_mode = self.checked and "fill" or "line"
		love.graphics.rectangle(rect_mode, 0, 0, self.w - 1, self.h - 1)
		love.graphics.pop()
		--]]
	end,
}


return def
