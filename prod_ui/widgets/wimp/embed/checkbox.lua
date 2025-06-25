-- WIP

--[[
	Embedded checkbox.
--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
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
	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, self.skin.box.border)
end


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.quad(res, "quad_checked")
	check.quad(res, "quad_unchecked")
	check.colorTuple(res, "color_bijou")

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.quad(skin, "tq_px")

		-- Cursor IDs for hover and press states.
		check.type(skin, "cursor_on", "nil", "string")
		check.type(skin, "cursor_press", "nil", "string")

		-- Checkbox (quad) render size.
		check.integer(skin, "bijou_w", 0)
		check.integer(skin, "bijou_h", 0)

		-- Alignment of bijou within Viewport #1.
		check.unitInterval(skin, "bijou_align_h")
		check.unitInterval(skin, "bijou_align_v")

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_hover")
		_checkRes(skin, "res_pressed")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "bijou_w", scale)
		change.integerScaled(skin, "bijou_h", scale)
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
		local res = uiTheme.pickButtonResource(self, skin)
		local tex_quad = self.checked and res.quad_checked or res.quad_unchecked

		-- bijou drawing coordinates
		local box_x = math.floor(0.5 + _lerp(self.vp_x, self.vp_x + self.vp_w - skin.bijou_w, skin.bijou_align_h))
		local box_y = math.floor(0.5 + _lerp(self.vp_y, self.vp_y + self.vp_h - skin.bijou_h, skin.bijou_align_v))

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
