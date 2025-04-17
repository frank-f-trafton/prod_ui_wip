-- To load: local lib = context:getLua("shared/lib")


--[[
Loads and caches LÖVE Font objects.

This file is local to the ProdUI context that loads it.

TODO: Need to support loading ImageFonts and BMFonts.
--]]


local fontCache = {}


local context = select(1, ...)


local pPath = require(context.conf.prod_ui_req .. "lib.pile_path")
--local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


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


--- Sets up a Font object and caches it, or returns an existing cached Font.
-- @param paths Array of paths to check (not applicable for LÖVE's default font, but include it anyways).
-- @param stem The name of the font (such that joining the path and stem make a full path), or "default" to
--	use LÖVE's built-in font.
-- @param size_or_type The size for TrueType fonts, or "bmf" or "img" for BMFonts and ImageFonts, respectively.
-- @param fallbacks Table of fallbacks to load, if applicable. (Assignment of fallbacks is handled later.)
-- @param cache A temporary table of instantiated fonts.
-- @return The Font object.
function fontCache.instantiateFont(paths, stem, size_or_type, fallbacks, cache)
	local id = fontCache.hash(stem, size_or_type)

	if cache[id] then
		return cache[id][1]
	end

	local font
	if stem == "default" then
		font = love.graphics.newFont(size_or_type)
	else
		for _, path in ipairs(paths) do
			local full_path = pPath.join(path, stem)
			if love.filesystem.getInfo(full_path, "file") then
				font = love.graphics.newFont(full_path, size_or_type)
				break
			end
		end
	end

	if font then
		cache[id] = {font}

		-- Ensure that fallbacks are loaded. The assignments happen later.
		if fallbacks then
			for _, v in ipairs(fallbacks) do
				local font2 = fontCache.instantiateFont(paths, v.path, v.size, false, cache)
				table.insert(cache[id], font2)
			end
		end

		return font
	end

	for i, v in ipairs(paths) do
		print("!", i, v)
	end
	error("unable to locate font: " .. stem)
end


-- Run after all relevant fonts have been loaded.
function fontCache.assignFallbacks(cache)
	for hashed_id, font_list in pairs(cache) do
		font_list[1]:setFallbacks(unpack(font_list, 2))
	end
end


return fontCache
