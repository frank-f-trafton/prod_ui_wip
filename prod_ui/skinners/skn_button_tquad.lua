-- Renders just a graphic / quad with no label.


local context = select(1, ...)


local themeAssert = context:getLua("core/res/theme_assert")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcGraphic = context:getLua("shared/wc/wc_graphic")


local md_res = uiSchema.newKeysX {
	slice = themeAssert.slice,

	color_body = uiAssert.loveColorTuple,
	color_quad = uiAssert.loveColorTuple,

	graphic_ox = uiAssert.integer,
	graphic_oy = uiAssert.integer
}


return {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- A default graphic to use if the widget doesn't provide one.
		-- TODO
		-- graphic

		default_height = {uiAssert.numberGE, 0}, -- unscaled

		-- Quad (graphic) alignment within Viewport #1.
		quad_align_h = {uiAssert.namedMap, uiTheme.named_maps.quad_align_h},
		quad_align_v = {uiAssert.namedMap, uiTheme.named_maps.quad_align_v},

		graphic_placement = {uiAssert.namedMap, uiTheme.named_maps.graphic_placement},
		graphic_spacing = {uiAssert.numberGE, 0},

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "graphic_spacing")

		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "graphic_ox")
			uiScale.fieldInteger(scale, res, "graphic_oy")
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
	--update


	render = function(self, ox, oy)
		local skin = self.skin
		local res = uiTheme.pickButtonResource(self, skin)
		local slc_body = res.slice
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

		local graphic = self.graphic or skin.graphic
		if graphic then
			wcGraphic.render(self, graphic, skin, res.color_quad, res.graphic_ox, res.graphic_oy, ox, oy)
		end
	end,

	--renderLast
	--renderThimble
}