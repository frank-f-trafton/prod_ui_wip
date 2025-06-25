local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local _lerp = pMath.lerp


local _enum_align = uiShared.makeLUTV("left", "center", "right", "justify")
local _enum_size_mode = uiShared.makeLUTV("h", "v")


local def = {
	skin_id = "text_block1",
}


local function _openURL(self)
	love.system.openURL(self.url)
end


def.wid_buttonAction = _openURL
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = _openURL


def.setEnabled = lgcButton.setEnabled


def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_pointerPress = lgcButton.uiCall_pointerPress
def.uiCall_pointerRelease = lgcButton.uiCall_pointerReleaseActivate
def.uiCall_pointerUnpress = lgcButton.uiCall_pointerUnpress
def.uiCall_thimbleAction = lgcButton.uiCall_thimbleAction
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2


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


function def:setURL(url)
	uiShared.type1(1, url, "string")

	self.url = url or false

	if self.url then
		self.cursor_hover = self.skin.cursor_on
		self.cursor_press = self.skin.cursor_press
	else
		self.cursor_hover = nil
		self.cursor_press = nil
	end

	self.allow_hover = not not self.url

	if self.context.thimble1 == self or self.context.thimble2 == self then
		self:releaseThimble2()
		self:releaseThimble1()
	end

	self.thimble_mode = self.url and 1 or 0
end


function def:getURL()
	return self.url
end


function def:setAlign(align)
	uiShared.enum(1, align, "Alignment", _enum_align)

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
	uiShared.enumEval(1, mode, "SizeMode", _enum_size_mode)

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
	self.allow_hover = false
	self.thimble_mode = 0

	widShared.setupViewports(self, 2)

	self.text = ""
	self.url = false

	self.font_id = "p"
	self.align = "left" -- "left", "center", "right"
	self.align_v = 0.0 -- (0.0 - 1.0)
	self.auto_size = false -- false, "h", "v"
	self.wrap = false -- only valid when auto_size is "v"

	-- Determined while reshaping.
	self.text_w = false
	self.text_h = false

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self.cursor_hover = false
end


-- Viewport #1 is the text bounding box. It may exceed the widget's dimensions, depending on the text
-- and auto_size mode.
-- Viewport #2 is the border.


function def:uiCall_reshapePre()
	widShared.resetViewport(self, 1)
	self.text_w, self.text_h = false, false
end


local function _determineTextDimensions(self, wrap_limit)
	--[[
	The text dimensions may be requested at multiple points during reshaping. Stuff the work
	into this function, and only execute it once per reshape event.
	--]]

	local skin = self.skin
	local font = skin.fonts[self.font_id]
	if not font then
		error("missing or invalid font. ID: " .. tostring(self.font_id))
	end

	if not self.wrap then
		self.text_w = font:getWidth(self.text)
		self.text_h = font:getHeight() * (1 + textUtil.countStringPatterns(self.text, "\n", true))
	else
		local lines
		local border = skin.box.border
		self.text_w, lines = font:getWrap(self.text, wrap_limit - border.x1 - border.x2)
		self.text_h = font:getHeight() * #lines
	end
end


function def:uiCall_getSliceLength(x_axis, cross_length)
	if not x_axis and self.auto_size == "v" then
		_determineTextDimensions(self, cross_length)
		local border = self.skin.box.border
		return self.text_h + border.y1 + border.y2, false
	end
end


function def:uiCall_reshapePost()
	local skin = self.skin

	widShared.resetViewport(self, 2)
	widShared.carveViewport(self, 2, skin.box.border)

	if not self.text_w then
		_determineTextDimensions(self, self.w)
	end

	self.vp_w, self.vp_h = self.text_w, self.text_h

	self.vp_x = self.vp2_x
	self.vp_y = math.floor(0.5 + _lerp(self.vp2_y, self.vp2_y + self.vp2_h, self.align_v))

	--print("TextBlock dimensions: ", self.w, self.h)
	--print("TextBlock parent dimensions: ", self.parent.w, self.parent.h)
	--print(self.parent.id)
end


def.default_skinner = {
	--validate = function(skin) -- TODO
	--transform = function(skin, scale) -- TODO


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)

	render = function(self, ox, oy)
		love.graphics.push("all")

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

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def