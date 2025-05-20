-- WIP

--[[
	Embedded checkbox.
--]]


local context = select(1, ...)


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local lgcButton = context:getLua("shared/lgc_button")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local _lerp = commonMath.lerp


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
	self.can_have_thimble = true

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


def.default_skinner = {
	skin_validation = {
		main = {
			keys_required = {
				skinner_id = {id="exact", value="wimp/embed/checkbox"},
				box = "theme-box",
				tq_px = "resource-quad",

				-- Cursor IDs for hover and press states.
				cursor_on = "hand",
				cursor_press = "hand",

				-- Checkbox (quad) render size.
				bijou_w = "integer",
				bijou_h = "integer",

				-- Alignment of bijou within Viewport #1.
				bijou_align_h = "unit-interval",
				bijou_align_v = "unit-interval",

				res_idle = "&res",
				res_hover = "&res",
				res_pressed = "&res",
				res_disabled = "&res"
			}
		},

		res = {
			keys_required = {
				quad_checked = "resource-quad",
				quad_unchecked = "resource-quad",

				color_bijou = "color4"
			}
		}
	},


	skin_transformation = {
		main = {
			keys = {
				bijou_w = "scaled-int",
				bijou_h = "scaled-int"
			}
		}
	},


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
