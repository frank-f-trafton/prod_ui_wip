-- To load: local lib = context:getLua("shared/lib")


--[[
Loads and caches LÖVE Font objects, and also sets up fallback chains.

This file is local to the ProdUI context that loads it.

TODO: Need to support loading ImageFonts and BMFonts.
--]]


local fontCache = {}


local context = select(1, ...)


local resourceCollection = require(context.conf.prod_ui_req .. "core.res.collection")


-- The keys are:
-- TrueType: 'path .. ":" .. size'
-- ImageFont: 'path .. ":img"'
-- BMFont: 'path .. ":bmf"'
function fontCache.hash(path, size_or_type)
	return path .. ":" .. size_or_type
end


function fontCache.unhash(hash)
	local id, size_or_type = hash:match("(.-):(.+)")
	if not id then
		error("failed to unhash: " .. tostring(hash))
	end
	return id, size_or_type
end


fontCache.cb_look = function(self, path_id)
	local path, size_or_type = fontCache.unhash(path_id)
	print("cb_look", "path", path, "size_or_type", size_or_type)

	return love.filesystem.getInfo(path, "file")
end


fontCache.cb_lookFirst = function(self, id)
	local path, size_or_type = fontCache.unhash(id)

	print("lookFirst", id, path, size_or_type)

	return path == "default"
end


fontCache.cb_load = function(self, path_id)
	local path, size_or_type = fontCache.unhash(path_id)

	return {love.graphics.newFont(path, tonumber(size_or_type))}
end


-- Handles LÖVE's built-in font.
fontCache.cb_loadFirst = function(self, id)
	local path, size_or_type = fontCache.unhash(id)

	return {love.graphics.newFont(tonumber(size_or_type))}
end


fontCache.cb_missing = function(self, id)
	error("missing font. ID: " .. tostring(id))
end


-- NOTE: The IDs include file extensions, unless they point to the built-in LÖVE font ("default").
local raw_fonts


function fontCache.setupRawFontsCollection(font_paths)
	raw_fonts = resourceCollection.new()

	raw_fonts.cb_look = fontCache.cb_look
	raw_fonts.cb_lookFirst = fontCache.cb_lookFirst
	raw_fonts.cb_load = fontCache.cb_load
	raw_fonts.cb_loadFirst = fontCache.cb_loadFirst
	raw_fonts.cb_missing = fontCache.cb_missing

	for i, v in ipairs(font_paths) do
		table.insert(raw_fonts.paths, v)
	end
end


function fontCache.clearRawFontsCollection()
	raw_fonts = nil
end


function fontCache.instantiateFont(info)
	local id = fontCache.hash(info.path, info.size)

	local font = raw_fonts:get(id)[1]

	-- Ensure that fallbacks are loaded. The assignments happen later.
	if info.fallbacks then
		for i, v in ipairs(info.fallbacks) do
			local hashed = fontCache.hash(v.path, v.size)
			raw_fonts:get(hashed)
		end
	end

	return font
end


-- Run after all relevant fonts have been loaded.
function fontCache.assignFallbacks()
	for k, list in pairs(raw_fonts.cache) do
		list[1]:setFallbacks(unpack(list, 2))
	end
end


return fontCache
