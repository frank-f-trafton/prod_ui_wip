
local context = select(1, ...)

print(type(context), context)
for k, v in pairs(context) do
	print("context", k, v)
end
for k, v in pairs(getmetatable(context)) do
	print("_mt_context", k, v)
end


local lgcGraphic = context:getLua("shared/lgc_graphic")
local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")


return {
	schema = {
		graphic_spacing = "scaled-int",

		res_idle = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},

		res_hover = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},

		res_pressed = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		},

		res_disabled = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		}
	},


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
			lgcGraphic.render(self, graphic, skin, res.color_quad, res.label_ox, res.label_oy, ox, oy)
		end

		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end

		-- XXX: Debug border (viewport rectangle)
		--widDebug.debugDrawViewport(self, 1)
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}
