-- Shared code for menu widgets that have similar icon and text features.


local context = select(1, ...)


local wcIconsAndText = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local icons = context.resources.icons


local _nm_menu_icon_side = uiTable.newNamedMapV("MenuIconSide", "left", "right")


wcIconsAndText.methods = {}
local methods = wcIconsAndText.methods


function wcIconsAndText.attachMethods(self)
	uiTable.patch(self, methods, false)
end


function wcIconsAndText.setupInstance(self)
	self.show_icons = false

	self.S_icon_side = false
	self.S_icon_set_id = false
	self.S_text_align = false

	self.icon_side = "left"
	self.icon_set_id = "bureau"
	self.text_align = "left"
end


function wcIconsAndText.getIconQuad(icon_set_id, icon_id)
	if icon_id then
		local icon_set = icons[icon_set_id]
		if icon_set then
			return icon_set[icon_id]
		end
	end
end


function methods:setIconSide(side)
	uiAssert.namedMap(1, side, _nm_menu_icon_side)

	if uiTable.setDouble(self, "S_icon_side", "icon_side", side, self.skin.default_icon_side) then
		self:reshape()
	end

	return self
end


function methods:getIconSide()
	return self.S_icon_side
end


function methods:setShowIcons(enabled)
	if uiTable.set(self, "show_icons", not not enabled) then
		self:reshape()
	end

	return self
end


function methods:getShowIcons()
	return self.show_icons
end


function wcIconsAndText.refreshIconReferences(self)
	for i, item in ipairs(self.MN_items) do
		item.tq_icon = wcIconsAndText.getIconQuad(self.icon_set_id, item.icon_id)
	end
end


function methods:setIconSetID(icon_set_id)
	uiAssert.typeEval(1, icon_set_id, "string")

	if uiTable.setDouble(self, "S_icon_set_id", "icon_set_id", icon_set_id, self.skin.default_icon_set_id) then
		wcIconsAndText.refreshIconReferences(self)
	end

	return self
end


function methods:getIconSetID()
	return self.S_icon_set_id
end


function methods:setTextAlignment(align)
	uiAssert.namedMap(1, align, uiTheme.named_maps.text_align_x)

	if uiTable.setDouble(self, "S_text_align", "text_align", align, self.skin.default_text_align) then
		self:reshape()
	end

	return self
end


function methods:getTextAlignment()
	return self.S_text_align
end


function wcIconsAndText.checkShadow(self)
	uiTable.updateDouble(self, "S_icon_side", "icon_side", self.skin.default_icon_side)
	uiTable.updateDouble(self, "S_icon_set_id", "icon_set_id", self.skin.default_icon_set_id)
	uiTable.updateDouble(self, "S_text_align", "text_align", self.skin.default_text_align)
end


return wcIconsAndText
