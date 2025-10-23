local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local _lerp = pMath.lerp


local _nm_align = uiTable.newNamedMapV("TextAlign", "left", "center", "right", "justify")
local _nm_size_mode = uiTable.newNamedMapV("SizeMode", "h", "v")


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
	uiAssert.type(1, text, "string")

	self.text = text
end


function def:getText()
	return self.text
end


function def:setURL(url)
	uiAssert.type(1, url, "string")

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
	uiAssert.namedMap(1, align, _nm_align)

	self.align = align
end


function def:getAlign()
	return self.align
end


function def:setVerticalAlign(v)
	uiAssert.type(1, v, "number")

	self.align_v = math.max(0, math.min(v, 1))
end


function def:getVerticalAlign()
	return self.align_v
end


function def:setAutoSize(mode)
	uiAssert.namedMapEval(1, mode, _nm_size_mode)

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


function def:uiCall_getSegmentLength(x_axis, cross_length)
	if not x_axis and self.auto_size == "v" then
		_determineTextDimensions(self, cross_length)
		local border = self.skin.box.border
		return self.text_h + border.y1 + border.y2, false
	end
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the text bounding box. It may exceed the widget's dimensions, depending on the text
	-- and auto_size mode.
	-- Viewport #2 is the border.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	self.text_w, self.text_h = false, false

	vp2:set(0, 0, self.w, self.h)
	vp2:reduceT(skin.box.border)

	if not self.text_w then
		_determineTextDimensions(self, self.w)
	end

	vp.w, vp.h = self.text_w, self.text_h

	vp.x = vp2.x
	vp.y = math.floor(0.5 + _lerp(vp2.y, vp2.y + vp2.h, self.align_v))

	--print("TextBlock dimensions: ", self.w, self.h)
	--print("TextBlock parent dimensions: ", self.parent.w, self.parent.h)
	--print(self.parent.id)
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 2)
	end
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
		local vp, vp2 = self.vp, self.vp2
		local font = skin.fonts[self.font_id]
		local color = skin.color

		love.graphics.setFont(font)
		love.graphics.setColor(color)

		uiGraphics.intersectScissor(
			ox + self.x + vp2.x,
			oy + self.y + vp2.y,
			vp2.w,
			vp2.h
		)

		if self.wrap then
			love.graphics.printf(self.text, vp.x, vp.y, vp.w, self.align)

		elseif self.align == "left" then
			love.graphics.print(self.text, vp.x, vp.y)

		elseif self.align == "center" then
			love.graphics.print(self.text, vp.x + math.floor((vp2.w - vp.w) * 0.5), vp.y)

		else -- self.align == "right"
			love.graphics.print(self.text, vp.x + vp2.w - vp.w, vp.y)
		end

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def