-- ProdUI: Theme support functions.


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- ProdUI
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiAssert = require(REQ_PATH .. "ui_assert")
local uiGraphics = require(REQ_PATH .. "ui_graphics")
local uiRes = require(REQ_PATH .. "ui_res")
local uiScale = require(REQ_PATH .. "ui_scale")
local uiSchema = require(REQ_PATH .. "ui_schema")
local uiTable = require(REQ_PATH .. "ui_table")


uiTheme.settings = {
	max_font_size = 256
}


uiTheme.named_maps = {
	-- LÖVE enums
	BlendAlphaMode = uiTable.newNamedMapV("BlendAlphaMode", "alphamultiply", "premultiplied"),
	BlendMode = uiTable.newNamedMapV("BlendMode", "alpha", "replace", "screen", "add", "subtract", "multiply", "lighten", "darken"),
	DrawMode = uiTable.newNamedMapV("DrawMode", "fill", "line"),
	LineJoin = uiTable.newNamedMapV("LineJoin", "bevel", "miter", "none"),
	LineStyle = uiTable.newNamedMapV("LineStyle", "rough", "smooth"),

	-- ProdUI theme
	font_type = uiTable.newNamedMap("FontExtensionType", {[".ttf"]="vector", [".otf"]="vector", [".fnt"]="bmfont", [".png"]="imagefont"}),

	-- ProdUI skin
	bijou_side_h = uiTable.newNamedMapV("BijouSideHorizontal", "left", "right"),
	graphic_placement = uiTable.newNamedMapV("GraphicPlacement", "left", "right", "top", "bottom", "overlay"),
	label_align_h = uiTable.newNamedMapV("LabelAlignHorizontal", "left", "center", "right", "justify"),
	label_align_v = uiTable.newNamedMapV("LabelAlignVertical", "top", "middle", "bottom"),
	quad_align_h = uiTable.newNamedMapV("QuadAlignHorizontal", "left", "center", "right"),
	quad_align_v = uiTable.newNamedMapV("QuadAlignVertical", "top", "middle", "bottom"),

	-- In general
	axis_2d = uiTable.newNamedMapV("Axis2D", "x", "y"),
	text_align_x = uiTable.newNamedMap("HorizontalTextAlignment", {["left"]=0.0, ["center"]=0.5, ["right"]=1.0}),
	text_align_y = uiTable.newNamedMap("VerticalTextAlignment", {["top"]=0.0, ["middle"]=0.5, ["bottom"]=1.0})
}
local named_maps = uiTheme.named_maps


--- Pick a resource table in a skin based on three common widget state flags: self.enabled, self.pressed and self.hovered.
-- @param self The widget instance, containing a skin table reference.
-- @param skin The skin table, or a sub-table.
-- @return The selected resource table.
function uiTheme.pickButtonResource(self, skin)
	if not self.enabled then
		return skin.res_disabled

	elseif self.pressed then
		return skin.res_pressed

	elseif self.hovered then
		return skin.res_hover

	else
		return skin.res_idle
	end
end


function uiTheme.skinnerCopyMethods(self, skinner)
	self.render = skinner.render
	self.renderLast = skinner.renderLast
	self.renderThimble = skinner.renderThimble
end


function uiTheme.skinnerClearData(self)
	self.render = nil
	self.renderLast = nil
	self.renderThimble = nil

	for k, v in pairs(self) do
		if type(k) == "string" and string.sub(k, 1, 3) == "sk_" then
			self[k] = nil
		end
	end
end


return uiTheme
