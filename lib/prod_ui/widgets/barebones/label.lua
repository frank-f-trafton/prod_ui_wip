--[[
	A barebones label. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local lgcLabelBare = context:getLua("shared/lgc_label_bare")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {}


def.setLabel = lgcLabelBare.widSetLabel


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true

		lgcLabelBare.setup(self)

		-- "enabled" affects the rendered color.
		self.enabled = true
	end
end


def.render = function(self, ox, oy)

	local r, g, b, a
	if self.enabled then
		r, g, b, a = 1, 1, 1, 1

	else
		r, g, b, a = 0.5, 0.5, 0.5, 1
	end

	lgcLabelBare.render(self, self.context.resources.fonts.internal, r, g, b, a)
end


return def
