-- ***Under construction***
-- This widget doesn't work yet.


--[[
A sash that allows resizing a widget in a layout.

┌──────╦──────┐
│      ║      │
│      ║      │
│  A   S   B  │
│      ║      │
│      ║      │
└──────╩──────┘

This widget acts as a sensor for containers which implement sash functionality.
It doesn't do much on its own, besides rendering and mouse hover detection.
--]]


local context = select(1, ...)

local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "sash1",
}


function def:uiCall_pointerHover(inst, x, y, dx, dy)
	if self == inst then

	end
end


function def:uiCall_pointerHoverOff(inst, x, y, dx, dy)
	if self == inst then

	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then

	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then

	end
end


function def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)
	if self == inst then

	end
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 0

	widShared.setupViewports(self, 1)

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self:reshape()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the sash graphic.
	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	return true
end


local check, change = uiTheme.check, uiTheme.change


def.default_skinner = {
	--validate = function(skin) -- TODO
	--transform = function(skin, scale) -- TODO


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

		love.graphics.push()

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("fill", self.vp_x, self.vp_y, self.vp_w, self.vp_h)

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
