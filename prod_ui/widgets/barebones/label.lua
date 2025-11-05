--[[
	A barebones label. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local wcLabelBare = context:getLua("shared/wc/wc_label_bare")


local def = {}


def.setLabel = wcLabelBare.widSetLabel


function def:uiCall_initialize()
	self.visible = true

	wcLabelBare.setup(self)

	-- "enabled" affects the rendered color.
	self.enabled = true
end


def.render = context:getLua("shared/render_button_bare").label


return def
