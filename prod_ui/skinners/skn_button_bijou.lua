local context = select(1, ...)


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local themeAssert = context:getLua("core/res/theme_assert")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcLabel = context:getLua("shared/wc/wc_label")


local _lerp = pMath.lerp


local md_res = uiSchema.newKeysX {
	quad_checked = themeAssert.quad,
	quad_unchecked = themeAssert.quad,

	color_bijou = uiAssert.loveColorTuple,
	color_label = uiAssert.loveColorTuple,

	label_ox = uiAssert.integer,
	label_oy = uiAssert.integer
}


return {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		label_style = themeAssert.labelStyle,
		tq_px = themeAssert.quad,

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Checkbox (quad) render size.
		bijou_w = uiAssert.integer,
		bijou_h = uiAssert.integer,

		-- Horizontal spacing between checkbox area and text label.
		bijou_spacing = uiAssert.integer,

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
		local tex_quad = self.checked and res.quad_checked or res.quad_unchecked

		-- bijou drawing coordinates
		local box_x = math.floor(0.5 + _lerp(vp2.x, vp2.x + vp2.w - skin.bijou_w, skin.bijou_align_h))
		local box_y = math.floor(0.5 + _lerp(vp2.y, vp2.y + vp2.h - skin.bijou_h, skin.bijou_align_v))

		-- draw bijou
		-- XXX: Scissor to Viewport #2?
		love.graphics.setColor(res.color_bijou)
		uiGraphics.quadXYWH(tex_quad, box_x, box_y, skin.bijou_w, skin.bijou_h)

		-- Draw the text label.
		if self.label_mode then
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end
}
