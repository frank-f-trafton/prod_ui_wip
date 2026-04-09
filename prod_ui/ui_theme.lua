-- ProdUI: Theme support functions.


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- ProdUI
local pPath =  require(REQ_PATH .. "lib.p_path")
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


local _info = {} -- for love.filesystem.getInfo()
local _blank_env = {} -- For setfenv()


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


local themes_max = 100


local function _ensurePathEndsInSlash(path)
	if path:sub(-1) ~= "/" then
		path = path .. "/"
	end
	return path
end


local function _assignIfString(v)
	if type(v) == "string" then
		return v
	end
end


function uiTheme.getThemeInfo(themes_path, id)
	uiAssert.type(1, themes_path, "string")
	uiAssert.type(2, id, "string")

	themes_path = _ensurePathEndsInSlash(themes_path)

	local path = themes_path .. id .. "_INFO.lua"
	if not love.filesystem.getInfo(path, _info) then
		return nil, "no file at: " .. path
	end

	local ret = uiRes.loadLuaFile(path, _blank_env)

	return {
		name = _assignIfString(ret.name),
		authors = _assignIfString(ret.authors),
		url = _assignIfString(ret.url),
		license = _assignIfString(ret.license),
		present_to_user = not not ret.present_to_user,
		description = _assignIfString(ret.description)
	}
end


-- Gets a list of themes.
function uiTheme.enumerateThemes(themes_path)
	uiAssert.type(1, themes_path, "string")

	themes_path = _ensurePathEndsInSlash(themes_path)

	local fs_items = love.filesystem.getDirectoryItems(themes_path)
	local theme_ids = {}

	for i, fs_name in ipairs(fs_items) do
		local info = love.filesystem.getInfo(themes_path .. fs_name, _info)
		if info then
			if info.type == "file" then
				local main, ext = pPath.splitPathAndExtension(fs_name)
				if ext == ".lua" and not main:match("_INFO$") then
					table.insert(theme_ids, main)
				end

			elseif info.type == "directory" then
				table.insert(theme_ids, fs_name)
			end
		end
	end

	table.sort(theme_ids)
	return theme_ids
end


function uiTheme.loadTheme(themes_path, id)
	uiAssert.type(1, themes_path, "string")
	uiAssert.type(2, id, "string")

	themes_path = _ensurePathEndsInSlash(themes_path)

	local id_orig = id
	local theme_hash, theme_ids = {}, {}
	local theme

	local i = 0
	while true do
		i = i + 1
		if i > themes_max then
			error("exceeded maximum allowed theme patches (" .. tostring(themes_max) .. ").")

		elseif theme_hash[id] then
			error("circular theme reference. ID: " .. tostring(id))
		end
		theme_hash[id] = true
		table.insert(theme_ids, id)

		local path_theme2 = themes_path .. id
		local theme2 = uiRes.loadLuaFileOrDirectoryAsTable(path_theme2, _blank_env, uiRes.dir_handler_lua_blank_env)
		local theme_info = uiTable.assertResolve(theme2, "info/theme_info")
		local next_id = theme_info.patches

		if theme then
			uiTable.deepPatch(theme2, theme, true)
		end
		theme = theme2

		if not next_id then
			break
		end
		id = next_id
	end

	if not theme then
		error("failed to load theme: " .. tostring(id_orig))
	end

	theme.info.theme_ids = theme_ids

	return theme
end


return uiTheme
