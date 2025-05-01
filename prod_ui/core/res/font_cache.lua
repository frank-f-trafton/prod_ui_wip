-- To load: local lib = context:getLua("shared/lib")


--[[
Loads and caches LÖVE Font data, sets up Font objects, and assigns fallbacks.

This file is local to the ProdUI context that loads it.

TODO: Cannot specify multiple texture pages as arguments when creating BMFonts
with love.graphics.newFont()
--]]



local fontCache = {}


local context = select(1, ...)


local pPath = require(context.conf.prod_ui_req .. "lib.pile_path")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")
local vPath = context:getLua("core/res/v_path")


local font_store = {}
local font_objects = {}


local _info1 = {} -- For love.filesystem.getInfo().


--- Checks that the data for a font is loaded, raising an error if the files cannot be found.
-- @param path The path to the main font file (.ttf, .otf, .png, .fnt).
-- @param image_id (.fnt only) Path to the texture page for BMFonts.
-- @return true if the data is loaded, false if a file couldn't be located on disk.
local function _checkData(paths, id, image_id)
	-- LÖVE's built-in font is always loaded.
	if id == "default" then
		return true
	end

	local ext = pPath.getExtension(id)

	local info_file, file_path = vPath.getInfo(paths, id, "file", _info1)
	if not info_file then
		error("couldn't locate font data file: " .. tostring(id))
	end

	if ext == ".ttf" or ext == ".otf" then
		if not font_store[id] then
			font_store[id] = {
				font_type = "vector",
				data = love.filesystem.newFileData(file_path),
				rasterizers = {}
			}
		end

	elseif ext == ".png" then
		if not font_store[id] then
			font_store[id] = {
				font_type = "image",
				data = love.image.newImageData(file_path)
			}
		end

	elseif ext == ".fnt" then
		if not font_store[id] then
			image_id = image_id or id:sub(1, -5) .. "_0.png"
			local info_image, image_path = vPath.getInfo(paths, image_id, "file", _info1)
			if not info_image then
				error("couldn't locate BMFont image file: " .. tostring(image_id))
			end

			font_store[id] = {
				font_type = "bmf",
				data = love.filesystem.newFileData(image_path),
				image_data = love.filesystem.newImageData(image_path)
			}
		end

	else
		error("expected Font path to end in '.ttf', '.otf', '.png' or '.fnt'.")
	end

	return true
end


function fontCache.checkData(paths, font_info)
	_checkData(paths, font_info.path, font_info.image_path)
	if font_info.fallbacks then
		for j, info2 in ipairs(font_info.fallbacks) do
			_checkData(paths, info2.path, info2.image_path)
		end
	end
end


local function _createFontObject(font_info)
	-- First, check for LÖVE's built-in Font.
	local path = font_info.path

	if path == "default" then
		if not font_objects["default"] then
			font_objects["default"] = {}
		end
		local size = font_info.size
		if not font_objects["default"][size] then
			font_objects["default"][size] = love.graphics.newFont(size)

			return font_objects["default"][size]
		end
	end

	-- Other Fonts.
	local font_data = font_store[font_info.path]
	if not font_data then
		error("font data is not loaded for: " .. tostring(font_info.path))
	end

	local font_type = font_data.font_type
	if font_type == "vector" then
		local size = font_info.size
		if not font_objects[path] then
			font_objects[path] = {}
		end
		if not font_objects[path][size] then
			local rasterizer = love.graphics.newTrueTypeRasterizer(font_data.data, size)
			font_objects[path][size] = love.graphics.newFont(rasterizer)
		end

		return font_objects[path][size]

	elseif font_type == "image" then
		if not font_objects[path] then
			font_objects[path] = love.graphics.newImageFont(font_data.data, font_info.glyphs, font_info.extraspacing)
		end

		return font_objects[path]

	elseif font_type == "bmf" then
		if not font_objects[path] then
			font_objects[path] = love.graphics.newFont(font_data.data, font_data.image_data)
		end

		return font_objects[path]
	end

	error("invalid font type: " .. tostring(font_type))
end


function fontCache.createFontObjects(font_info)
	_createFontObject(font_info)
	if font_info.fallbacks then
		for i, info2 in ipairs(font_info.fallbacks) do
			_createFontObject(info2)
		end
	end
end


local function _checkLoadedFontObject(path, size)
	local font = font_objects[path]
	if type(font) == "table" then
		font = font[size]
	end
	if not font then
		error("missing font object. Path: " .. tostring(path))
	end
	return font
end


function fontCache.setFallbacks(font_info)
	local target_font = _checkLoadedFontObject(font_info.path, font_info.size)
	if font_info.fallbacks then
		local list = {}
		for i, fallback_info in ipairs(font_info.fallbacks) do
			table.insert(list, _checkLoadedFontObject(fallback_info.path, font_info.size))
		end
		target_font:setFallbacks(list)
	end
end


function fontCache.getFont(font_info)
	return _checkLoadedFontObject(font_info.path, font_info.size)
end


local function _clear(t)
	for k in pairs(t) do
		t[k] = nil
	end
end


function fontCache.clear()
	_clear(font_store)
end


return fontCache
