-- WIP

--[[
	Embedded checkbox.
--]]


local context = select(1, ...)


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcButton = context:getLua("shared/wc/wc_button")
local widShared = context:getLua("core/wid_shared")


local _lerp = pMath.lerp


local def = {
	skin_id = "checkbox_emb1",
}


def.wid_buttonAction = wcButton.wid_buttonAction
def.wid_buttonAction2 = wcButton.wid_buttonAction2
def.wid_buttonAction3 = wcButton.wid_buttonAction3


def.setEnabled = wcButton.setEnabled
def.setChecked = wcButton.setChecked


def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
def.evt_pointerPress = wcButton.evt_pointerPress
def.evt_pointerRelease = wcButton.evt_pointerReleaseCheck
def.evt_pointerUnpress = wcButton.evt_pointerUnpress
def.evt_thimbleAction = wcButton.evt_thimbleActionCheck
def.evt_thimbleAction2 = wcButton.evt_thimbleAction2


function def:evt_initialize()
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


function def:evt_reshapePre()
	-- Viewport #1 is the checkbox rectangle.

	local vp = self.vp

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(self.skin.box.border)
end


function def:evt_destroy(inst)
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
