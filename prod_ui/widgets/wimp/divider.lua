--[[
	A container with support for sashes (draggable separators between widgets).

	Dividers do not support scrolling.
--]]


local context = select(1, ...)


local layout = context:getLua("core/layout")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "divider1"
}


def.reshape = widShared.reshapers.branch


-- TODO: sash thickness


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true

	widShared.setupViewports(self, 2)

	self.press_busy = false

	-- We're not using struct_tree.lua here because the nodes do not represent selectable menu items.
	self.node = layout.newRootNode()

	self:skinSetRefs()
	self:skinInstall()
end


--[[
Viewport #1 is the border.
--]]


function def:uiCall_reshapePre()
	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	local n = self.node
	if n then
		n.x, n.y, n.w, n.h = self.vp_x, self.vp_y, self.vp_w, self.vp_h
		layout.splitNode(n, 1)
		layout.setWidgetSizes(n, 1)
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		-- Try directing thimble1 to the container's UI Frame ancestor.
		if button <= 3 then
			local wid = self
			while wid do
				if wid.frame_type then
					break
				end
				wid = wid.parent
			end
			if wid then
				wid:tryTakeThimble1()
			end
		end
	end
end


def.default_skinner = {
	--schema = {},


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		if skin.slc_body then
			love.graphics.setColor(skin.color_body)
			uiGraphics.drawSlice(skin.slc_body, 0, 0, self.w, self.h)
		end
	end,


	--renderLast = function(self, ox, oy)
}


return def
