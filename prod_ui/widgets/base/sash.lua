--[[
A sash that allows resizing a widget in a layout.

┌──────╦──────┐
│      ║      │
│      ║      │
│  A   S   B  │
│      ║      │
│      ║      │
└──────╩──────┘

The parent container implements most of the sash's functionality. Mouse hover detection has to
happen one level above so that the sash's hover box may overlap siblings that come after it.
--]]


local context = select(1, ...)

local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "sash1",
}


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = false
	self.thimble_mode = 0

	widShared.setupViewports(self, 1)

	self:skinSetRefs()
	self:skinInstall()

	self.UI_is_sash = true

	self:reshape()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is for the sash graphic.
	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.margin)

	return true
end


function def:uiCall_destroy(inst)
	if self == inst then
		if self.parent.sash_hover == self then
			self.parent.sash_hover = false
			self.parent.cursor_hover = false
		end
	end
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


	--[===[
	render = function(self, ox, oy)
		local skin = self.skin

		love.graphics.push()

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("fill", self.vp_x, self.vp_y, self.vp_w, self.vp_h)

		love.graphics.pop()
	end,
	--]===]


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
