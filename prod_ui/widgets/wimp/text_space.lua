local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")


local def = {
	skin_id = "text_space1",
}


function def:setFontID(id)
	local skin = self.skin

	if not skin.fonts[id] then
		error("invalid font ID.")
	end

	self.font_id = id

	self:reshape()

	return self
end


function def:getFontID()
	return self.font_id
end


function def:setSpacing(space)
	uiAssert.numberNotNaN(1, space)

	self.space = math.max(space, 0.0)

	self:reshape()

	return self
end


function def:getSpacing()
	return self.space
end


function def:evt_initialize()
	self.font_id = "p"
	self.space = 1.0

	self:skinSetRefs()
	self:skinInstall()
end


function def:evt_getGrowAxisLength(x_axis, cross_length)
	if not x_axis then
		local font = self.skin.fonts[self.font_id]
		return math.floor(self.space * font:getHeight() * font:getLineHeight()), false
	end
end


function def:evt_reshapePre()
	local skin = self.skin

	local font = skin.fonts[self.font_id]

end


def.default_skinner = {
	--validate = uiSchema.newKeysX {} -- TODO
	--transform = function(scale, skin) -- TODO


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)
	--render = function(self, ox, oy)
	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def