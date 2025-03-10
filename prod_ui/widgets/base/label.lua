--[[
A plain skinned label with an optional 9-slice body.
--]]


local context = select(1, ...)


local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "label1",
}


def.reshape = widShared.reshapers.prePost


def.setLabel = lgcLabel.widSetLabel


function def:uiCall_initialize()
	self.visible = true

	widShared.setupViewports(self, 1)

	lgcLabel.setup(self)

	self:skinSetRefs()
	self:skinInstall()

	-- "enabled" affects visual style.
	self.enabled = true

	self:reshape()
end


function def:uiCall_reshapePre()
	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, self.skin.box.border)
	lgcLabel.reshapeLabel(self)

	return true
end


def.default_skinner = {
	schema = {
		main = {
			res_idle = "&res",
			res_disabled = "&res"
		},
		res = {
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
		local res = (self.enabled) and skin.res_idle or skin.res_disabled

		local slc_body = res.sl_body
		if slc_body then
			love.graphics.setColor(res.color_body)
			uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)
		end

		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
