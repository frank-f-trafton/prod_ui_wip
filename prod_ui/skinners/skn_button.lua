local context = select(1, ...)


local themeAssert = context:getLua("core/res/theme_assert")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcGraphic = context:getLua("shared/wc/wc_graphic")
local wcLabel = context:getLua("shared/wc/wc_label")


local md_res = uiSchema.newKeysX {
	slice = themeAssert.slice,

	color_body = uiAssert.loveColorTuple,
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

		default_height = {uiAssert.numberGE, 0}, -- unscaled

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Alignment of label text in Viewport #1.
		label_align_h = {uiAssert.namedMap, uiTheme.named_maps.label_align_h},
		label_align_v = {uiAssert.namedMap, uiTheme.named_maps.label_align_v},

		-- A default graphic to use if the widget doesn't provide one.
		-- TODO
		-- graphic

		quad_align_h = {uiAssert.namedMap, uiTheme.named_maps.quad_align_h},
		quad_align_v = {uiAssert.namedMap, uiTheme.named_maps.quad_align_v},

		-- Placement of graphic in relation to text labels.
		graphic_placement = {uiAssert.namedMap, uiTheme.named_maps.graphic_placement},

		-- How much space to assign the graphic when not using "overlay" placement.
		graphic_spacing = {uiAssert.numberGE, 0},

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "graphic_spacing")

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
		local res = uiTheme.pickButtonResource(self, skin)

		local slc_body = res.slice
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

		local graphic = self.graphic or skin.graphic
		if graphic then
			wcGraphic.render(self, graphic, skin, res.color_quad, res.label_ox, res.label_oy, ox, oy)
		end

		if self.label_mode then
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}
