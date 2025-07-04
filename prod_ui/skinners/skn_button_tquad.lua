-- Renders just a graphic / quad with no label.


local context = select(1, ...)


local lgcGraphic = context:getLua("shared/lgc_graphic")
local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.slice(res, "slice")
	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_quad")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)

	uiTheme.popLabel()
end


return {
	validate = function(skin)
		check.box(skin, "box")
		check.labelStyle(skin, "label_style")

		-- Cursor IDs for hover and press states.
		check.type(skin, "cursor_on", "nil", "string")
		check.type(skin, "cursor_press", "nil", "string")

		-- A default graphic to use if the widget doesn't provide one.
		-- TODO
		-- graphic

		-- Quad (graphic) alignment within Viewport #1.
		check.enum(skin, "quad_align_h")
		check.enum(skin, "quad_align_v")

		-- Placement of graphic in relation to text labels.
		check.enum(skin, "graphic_placement")

		-- Additional spacing between graphic and label.
		check.number(skin, "graphic_spacing", 0, nil, nil)

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_hover")
		_checkRes(skin, "res_pressed")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "graphic_spacing", scale)

		_changeRes(skin, "res_idle", scale)
		_changeRes(skin, "res_hover", scale)
		_changeRes(skin, "res_pressed", scale)
		_changeRes(skin, "res_disabled", scale)
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
			lgcGraphic.render(self, graphic, skin, res.color_quad, res.label_ox, res.label_oy, ox, oy)
		end
	end,

	--renderLast
	--renderThimble
}