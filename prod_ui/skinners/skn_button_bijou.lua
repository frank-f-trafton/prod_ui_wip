local context = select(1, ...)


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local lgcLabel = context:getLua("shared/lgc_label")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")


local _lerp = commonMath.lerp
local _makeLUTV = pTable.makeLUTV
local check = uiTheme.check
local change = uiTheme.change


local function _checkRes(res)
	check.quad(res, "quad_checked")
	check.quad(res, "quad_unchecked")
	check.colorTuple(res, "color_bijou")
	check.colorTuple(res, "color_label")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")
end


local function _changeRes(res, scale)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)
end


return {
	validate = function(skin)
		check.box(skin, "box")
		check.labelStyle(skin, "label_style")
		check.quad(skin, "tq_px")

		-- Cursor IDs for hover and press states.
		check.type(skin, "cursor_on", "nil", "string")
		check.type(skin, "cursor_press", "nil", "string")

		-- Checkbox (quad) render size.
		check.integer(skin, "bijou_w")
		check.integer(skin, "bijou_h")

		-- Horizontal spacing between checkbox area and text label.
		check.integer(skin, "bijou_spacing")

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
		change.integerScaled(skin, "bijou_w", scale)
		change.integerScaled(skin, "bijou_h", scale)
		change.integerScaled(skin, "bijou_spacing", scale)

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
		local tex_quad = self.checked and res.quad_checked or res.quad_unchecked

		-- bijou drawing coordinates
		local box_x = math.floor(0.5 + _lerp(self.vp2_x, self.vp2_x + self.vp2_w - skin.bijou_w, skin.bijou_align_h))
		local box_y = math.floor(0.5 + _lerp(self.vp2_y, self.vp2_y + self.vp2_h - skin.bijou_h, skin.bijou_align_v))

		-- draw bijou
		-- XXX: Scissor to Viewport #2?
		love.graphics.setColor(res.color_bijou)
		uiGraphics.quadXYWH(tex_quad, box_x, box_y, skin.bijou_w, skin.bijou_h)

		-- Draw the text label.
		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end
}
