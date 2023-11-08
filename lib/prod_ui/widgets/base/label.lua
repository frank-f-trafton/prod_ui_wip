--[[
A plain skinned label with an optional 9-slice body.
--]]


local context = select(1, ...)


local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "logic.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "label1",
}


def.setLabel = lgcLabel.widSetLabel


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true

		widShared.setupViewport(self, 1)

		lgcLabel.setup(self)

		self:skinSetRefs()
		self:skinInstall()

		-- "enabled" affects visual style.
		self.enabled = true

		self:reshape()
	end
end


function def:uiCall_reshape()

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
	lgcLabel.reshapeLabel(self)
end


def.skinners = {
	default = {
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

			-- XXX: Debug border (viewport rectangle)
			--widDebug.debugDrawViewport(self, 1)
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy) end,
	},
}


return def
