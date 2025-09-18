--[[
A sash. Click and drag to resize an associated widget in a layout.

┌───╦────────────────┐
│   ║  It was the    │
│   ║ best of times, │
│ W ║ it was the     │
│   ║ worst of times,│
│   ║ it was the age │
└───╩────────────────┘

This widget depends on a parent that uses the sash code in 'shared/lgc_container.lua'. The
parent itself pulls in size data from a table in 'theme/sash_styles'. This is necessary
because the parent has to perform mouse overlap detection with expansion and compression
of the sash's bounding box.
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

	self.tall = true

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


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)

	check.slice(res, "slc_lr")
	check.slice(res, "slc_tb")
	check.colorTuple(res, "col_body")

	uiTheme.popLabel()
end


def.default_skinner = {
	-- Sash measurements are in 'theme/sash_styles'.

	validate = function(skin)
		-- The box adds a margin around the quadslice graphic.
		check.box(skin, "box")

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_hover")
		_checkRes(skin, "res_press")
		_checkRes(skin, "res_disabled")
	end,


	--transform = function(skin, scale) -- n/a


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function (self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local parent = self.parent
		local skin = self.skin

		love.graphics.push()

		local res
		if not parent.sashes_enabled then
			res = skin.res_disabled

		elseif parent.sash_hover == self then
			if parent.press_busy == "sash" then
				res = skin.res_press
			else
				res = skin.res_hover
			end
		else
			res = skin.res_idle
		end

		love.graphics.setColor(res.col_body)
		local slc = self.tall and res.slc_tb or res.slc_lr
		uiGraphics.drawSlice(slc, self.vp_x, self.vp_y, self.vp_w, self.vp_h)


		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
