local context = select(1, ...)


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local _lerp = commonMath.lerp


local _enum_align = {left=true, center=true, right=true, justify=true}
local _enum_size_mode = {h=true, v=true}


local def = {
	skin_id = "text_block1",
}


def.reshape = widShared.reshapers.prePost


function def:setFontID(id)
	local skin = self.skin

	if not skin.fonts[id] then
		error("invalid font ID.")
	end

	self.font_id = id
end


function def:getFontID()
	return self.font_id
end


function def:setText(text)
	uiShared.type1(1, text, "string")

	self.text = text
end


function def:getText()
	return self.text
end


function def:setAlign(align)
	uiShared.enum(1, align, "alignment", _enum_align)

	self.align = align
end


function def:getAlign()
	return self.align
end


function def:setVerticalAlign(v)
	uiShared.type1(1, v, "number")

	self.align_v = math.max(0, math.min(v, 1))
end


function def:getVerticalAlign()
	return self.align_v
end


function def:setAutoSize(mode)
	uiShared.enumEval(1, mode, "Size Mode", _enum_size_mode)

	self.auto_size = mode
end


function def:getAutoSize()
	return self.auto_size
end


function def:setWrapping(enabled)
	self.wrap = not not enabled
end


function def:getWrapping()
	return self.wrap
end


function def:uiCall_initialize()
	self.visible = true

	widShared.setupViewports(self, 2)

	self.text = ""

	self.font_id = "p"
	self.align = "left" -- "left", "center", "right"
	self.align_v = 0.0 -- (0.0 - 1.0)
	self.auto_size = false -- false, "h", "v"
	self.wrap = false -- only valid when auto_size is "v"

	self:skinSetRefs()
	self:skinInstall()
end


-- Viewport #1 is the text bounding box. It may exceed the widget's dimensions, depending on the text
-- and auto_size mode.
-- Viewport #2 is the border.


--[[
lp_x, lp_y, lp_w, lp_h
--]]


function def:uiCall_relayoutPre(x_axis, lw, lh)
	local skin = self.skin
	local font = skin.fonts[self.font_id]
	if not font then
		error("missing or invalid font. ID: " .. tostring(self.font_id))
	end
	local border = skin.box.border

	widShared.resetViewport(self, 1)
	self.vp_h = lh - border.x1 - border.x2
	self.vp_w = lw - border.y1 - border.y2

	if self.wrap then
		local w, lines = font:getWrap(self.text, self.vp_w)
		self.vp_h = font:getHeight() * #lines
		self.vp_w = w
	else
		self.vp_h = font:getHeight() * (1 + textUtil.countStringPatterns(self.text, "\n", true))
		self.vp_w = font:getWidth(self.text)
	end

	if self.auto_size == "h" then
		self.w = self.vp_w + border.x1 + border.x2

	elseif self.auto_size == "v" then
		self.h = self.vp_h + border.y1 + border.y2
	end
end


function def:uiCall_relayoutPost()
	local skin = self.skin

	widShared.resetViewport(self, 2)
	widShared.carveViewport(self, 2, skin.box.border)

	self.vp_x = self.vp2_x
	self.vp_y = math.floor(0.5 + _lerp(self.vp2_y, self.vp2_y + self.vp2_h, self.align_v))

	print("TextBlock dimensions: ", self.w, self.h)
	print("TextBlock parent dimensions: ", self.parent.w, self.parent.h)
	print(self.parent.id)
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
		local font = skin.fonts[self.font_id]
		local color = skin.color

		love.graphics.setFont(font)
		love.graphics.setColor(color)

		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		if self.wrap then
			love.graphics.printf(self.text, self.vp_x, self.vp_y, self.vp_w, self.align)

		elseif self.align == "left" then
			love.graphics.print(self.text, self.vp_x, self.vp_y)

		elseif self.align == "center" then
			love.graphics.print(self.text, self.vp_x + math.floor((self.vp2_w - self.vp_w) * 0.5), self.vp_y)

		else -- self.align == "right"
			love.graphics.print(self.text, self.vp_x + self.vp2_w - self.vp_w, self.vp_y)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def