--[[
A rewrite of the label widget.
--]]


local context = select(1, ...)


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local fonts = context.resources.fonts


local _lerp = pMath.lerp


local _nm_text_align_x = uiTheme.named_maps.text_align_x
local _nm_text_align_y = uiTheme.named_maps.text_align_y


local def = {
	skin_id = "control_label1",
}


function def:setText(text)
	uiAssert.type(1, text, "string")

	self.text = text

	self:reshape()

	return self
end


function def:getText()
	return self.text
end


function def:setHorizontalAlignment(align_x)
	uiAssert.namedMap(1, align_x, _nm_text_align_x)

	self.text_align_x = align_x

	return self
end


function def:getHorizontalAlignment()
	return self.text_align_x
end


function def:setVerticalAlignment(align_y)
	uiAssert.namedMap(1, align_y, _nm_text_align_y)

	self.text_align_y = align_y

	return self
end


function def:getVerticalAlignment()
	return self.text_align_y
end


local function _updateFontReference(self)
	local id = self.font_id
	if not id then
		self.font = self.skin.default_font
	else
		local font = fonts[id]
		if not font then
			error("invalid Font ID:" .. tostring(id))
		end
		self.font = font
	end
end


function def:setFontID(id)
	uiAssert.typeEval(1, id, "string")

	self.font_id = id or false
	_updateFontReference(self)

	return self
end


function def:getFontID()
	return self.font_id
end


function def:setEnabled(enabled)
	self.enabled = not not enabled

	return self
end


function def:getEnabled()
	return self.enabled
end


function def:evt_initialize()
	self.visible = true

	widShared.setupViewports(self, 1)

	self.text = "Label"
	self.text_align_x = false
	self.text_align_y = false
	self.font_id = false

	self.font = false -- see: _updateFontReference()
	self.text_x = 0
	self.text_y = 0

	self:skinSetRefs()
	self:skinInstall()

	-- Affects visual style.
	self.enabled = true
end


function def:evt_reshapePre()
	local skin = self.skin
	local vp = self.vp
	local font = self.font

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	local align_x = _nm_text_align_x[self.text_align_x or skin.default_align_x]
	local align_y = _nm_text_align_y[self.text_align_y or skin.default_align_y]

	local text_width = font:getWidth(self.text)
	local text_height = font:getHeight()

	self.text_x = math.floor(.5 + _lerp(vp.x, vp.x + vp.w - text_width, align_x))
	self.text_y = math.floor(.5 + _lerp(vp.y, vp.y + vp.h - text_height, align_y))

	return true
end


function def:evt_destroy(targ)
	if self == targ then
		widShared.removeViewports(self, 1)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		tq_px = themeAssert.quad,

		default_font = themeAssert.font,

		default_align_x = {uiAssert.namedMap, uiTheme.named_maps.text_align_x},
		default_align_y = {uiAssert.namedMap, uiTheme.named_maps.text_align_y},

		color_active = uiAssert.loveColorTuple,
		color_disabled = uiAssert.loveColorTuple
	},


	--transform = function(scale, skin)


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		_updateFontReference(self)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function (self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local font = self.font
		local vp = self.vp

		love.graphics.push("all")

		love.graphics.setColor(self.enabled and skin.color_active or skin.color_disabled)
		--uiGraphics.intersectScissor(vp.x, vp.y, vp.w, vp.h)
		love.graphics.setScissor() -- DEBUG
		love.graphics.setFont(font)
		love.graphics.print(self.text, self.text_x, self.text_y)

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
