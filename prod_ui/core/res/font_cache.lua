--[[
Loads and caches LÖVE Font data, creates Font objects, and assigns fallbacks.

This file is local to the ProdUI context that loads it.

TODO: Cannot specify multiple texture pages as arguments when creating BMFonts
with love.graphics.newFont()
--]]


local fontCache = {}


local context = select(1, ...)


local pPath = require(context.conf.prod_ui_req .. "lib.pile_path")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")


local font_store = {}
local font_objects = {}


local _info1 = {} -- For love.filesystem.getInfo().


local function _loadAndMakeFont(font_info)
	local path = context:interpolatePath(font_info.path)

	if path == "default" then
		if not font_objects["default"] then
			font_objects["default"] = {}
		end
		local size = font_info.size
		if not font_objects["default"][size] then
			font_objects["default"][size] = love.graphics.newFont(size)
		end
		return font_objects["default"][size]
	end

	if not font_store[path] then
		local info_file = uiRes.assertGetInfo(path, "file", _info1)
		local ext = pPath.getExtension(path)
		if ext == ".ttf" or ext == ".otf" then
			font_store[path] = {
				font_type = "vector",
				data = love.filesystem.newFileData(path),
				rasterizers = {}
			}

		elseif ext == ".png" then
			font_store[path] = {
				font_type = "image",
				data = love.image.newImageData(path)
			}

		elseif ext == ".fnt" then
			local image_path
			if font_info.image_path then
				image_path = context:interpolatePath(font_info.image_path)
			else
				image_path = path:sub(1, -5) .. "_0.png"
			end

			local info_image = uiRes.assertGetInfo(image_path, "file", _info1)
			if not info_image then
				error("couldn't locate BMFont image file: " .. tostring(image_path))
			end

			font_store[path] = {
				font_type = "bmf",
				data = love.filesystem.newFileData(path),
				image_data = love.filesystem.newImageData(image_path)
			}

		else
			error("expected Font path to end in '.ttf', '.otf', '.png' or '.fnt'.")
		end
	end
	local font_data = font_store[path]
	if not font_data then
		error("font data is not loaded for: " .. tostring(path))
	end

	local font_type = font_data.font_type
	if font_type == "vector" then
		local size = font_info.size
		if not font_objects[path] then
			font_objects[path] = {}
		end
		if not font_objects[path][size] then
			local rasterizer = love.font.newTrueTypeRasterizer(font_data.data, size)
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
	_loadAndMakeFont(font_info)
	if font_info.fallbacks then
		for i, info2 in ipairs(font_info.fallbacks) do
			_loadAndMakeFont(info2)
		end
	end
end


local function _checkLoadedFontObject(path, size)
	path = context:interpolatePath(path)

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
		target_font:setFallbacks(unpack(list))
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
	_clear(font_objects)
end


return fontCache
