-- To load: local lib = context:getLua("shared/lib")


local contextResources = {}


local context = select(1, ...)


local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local utilTable = require(context.conf.prod_ui_req .. "common.util_table")


local _drill = utilTable.drill


-- Temporary cache of loaded fonts, where the keys are:
-- TrueType: 'path .. ":" .. size'
-- ImageFont: 'path .. ":ImageFont"'
-- BMFont: 'path .. ":BMFont"
local _fonts = setmetatable({}, {__mode="kv"})


local function _fontHash(path, tag)
	return path .. ":" .. tag
end


local function _interpolatePath(path, theme_path)
	if path:find("^%%theme%%") then
		return path:gsub("%%theme%%", theme_path, 1)
	end
end


local function _instantiateFont(v, theme_id)
	uiShared.type(1, v, "table")

	--[[
	'v' table format:
	v.path: The path to the font on disk, or "default" to use LÖVE's built-in font.
		The path is relative to 'prod_ui/themes'. Start the path with "%theme%" to
		point to this theme directory (like "%theme%/fonts/letters.ttf").
	v.size: The size for TrueType fonts.
	v.fallbacks: array of more tables with 'path' and 'size' fields, specifying this
		font's fallbacks.

	Note that fallbacks of fallbacks are not considered. That is, if 'A' sets 'B' as a
	fallback, and 'C' sets 'A' as a fallback, then 'C' will not pull glyph data from 'B'
	via 'A'.

	TODO: ImageFonts, BMFonts
	--]]

	local path, size, fallbacks = v.path, v.size, v.fallbacks
	assert(type(path) == "string", "path: expected string.")
	if size and type(size) ~= "number" then
		error("font size: expected number.")
	end

	path = _interpolatePath(path, theme_id)

	local id = _fontHash(path, size)

	local font
	local cached = _fonts[id]
	if cached then
		font = cached
	else
		if path == "default" then
			font = love.graphics.newFont(size)
		else
			font = love.graphics.newFont(path, size)
		end

		_fonts[id] = font
	end

	if fallbacks then
		local fb = {}
		for i, f in ipairs(fallbacks) do
			local path2, size2 = _interpolatePath(f.path, theme_id), f.size
			local id2 = _fontHash(path2, size2)
			if not _fonts[id2] then
				_fonts[id2] = love.graphics.newFont(path2, size2)
			end
			fb[#fb + 1] = _fonts[id2]
		end
		font:setFallbacks(unpack(fb))
	end

	return font
end


local methods = {}
function contextResources.attachMethods(mt)
	for k, v in pairs(methods) do
		if mt[k] then
			error("attempted to overwrite key: " .. tostring(k))
		end
		mt[k] = v
	end
end


function methods:resetResources()
	for k, v in pairs(self.resources) do
		pTable.clear(v)
	end
end


function methods:applyTheme()
	local theme = self.theme
	local resources = self.resources
	local scale = self.scale

	self:resetResources()

	pTable.clear(_fonts)
	if theme.fonts then
		for k, v in pairs(theme.fonts) do
			local font = _instantiateFont(v)
			self.resources.fonts[k] = v
		end
	end
	pTable.clear(_fonts)


	-- Textures
	local textures = uiRes.enumerate(base_path, ".lua", recursive)

	--[[
	local atlas_data = uiRes.loadLuaFile(BASE_PATH .. "tex/" .. tostring(dpi) .. "/atlas.lua")
	local atlas_tex = love.graphics.newImage(BASE_PATH .. "tex/" .. tostring(dpi) .. "/atlas.png")
	--]]

	if theme.boxes then
		for k2, v2 in pairs(theme.boxes) do
			for k, v in pairs(v2) do
				if k == "outpad" or k == "border" or k == "margin" then
					v.x1 = math.max(0, math.floor(v.x1 * scale))
					v.x2 = math.max(0, math.floor(v.x2 * scale))
					v.y1 = math.max(0, math.floor(v.y1 * scale))
					v.y2 = math.max(0, math.floor(v.y2 * scale))
				end
			end
		end
	end

	-- TODO: Icon classifications

	-- TODO: Widget label styles
end


--- Registers a SkinDef table to the theming system and creates a SkinInstance.
-- @param skin_def The SkinDef table to assign.
-- @param id The SkinDef ID to use. It must be a string, a number or a table, and it cannot already be registerd.
--  If the value is a table, then it must be the SkinDef table (skin_def == id).
function methods:registerSkinDef(skin_def, id)
	uiShared.type1(1, skin_def, "table")
	uiShared.type(1, id, "string", "number", "table")

	if type(id) == "table" and skin_def ~= id then
		error("when using a table as the ID, it must be the same table as the SkinDef (skin_def == id).")
	end

	local skins = self.resources.skins
	if skins[id] then
		error("a SkinDef is already registered with this ID: " .. tostring(id))
	end

	local skin_inst = setmetatable({}, skin_def)
	skins[id] = skin_inst
	self:refreshSkinDefInstance(id)
end


--- Wrapper for loading a SkinDef from a file.
-- @param id The ID to use for the skin. Must not have already been registered.
-- @param path Path to the file containing the SkinDef.
-- @return The loaded SkinDef.
function methods:loadSkinDef(id, path)
	local def = uiRes.loadLuaFile(path, self)

	if type(def) ~= "table" then
		error("bad type for skin def (expected table, got " .. type(def) .. ") at path: " .. path)
	end

	self:registerSkinDef(def, id)

	return def
end


--- Loads multiple SkinDefs from a directory. The SkinDef names are based on the file names with the base path and
--	file extension stripped.
-- @param base_path The file path to scan.
-- @param id_prepend An optional string to insert before the SkinDef names.
function methods:loadSkinDefs(base_path, recursive, id_prepend)
	--[[
	An example of how this method names SkinDefs:

	inst:loadSkinDefs("game/ui_skins", "xtra/")

	The file "game/ui_skins/skeleton.lua" produces "xtra/skeleton".
	The file "game/ui_skins/pads/lily.lua" produces "xtra/pads/lily".
	--]]

	id_prepend = id_prepend or ""
	local source_files = uiRes.enumerate(base_path, ".lua", recursive)

	for i, file_path in ipairs(source_files) do
		-- Use the file name without the '.lua' extension as the ID.
		local id = file_path:match("^(.-)%.lua$")
		if not id then
			error("couldn't extract ID from file path: " .. file_path)
		end
		id = id_prepend .. uiRes.stripBaseDirectoryFromPath(base_path, id)

		self:loadSkinDef(id, file_path)
	end
end


local _dummy_schema = {}


local _ref_handlers = {
	["*"] = function(self, v)
		return false, _drill(self.resources, "/", v:sub(2))
	end,
	["#"] = function(self, v)
		return true, _drill(self.resources, "/", v:sub(2))
	end,
	-- "&" is handled earlier in the function.
}


local _schema_commands = {
	["scaled-int"] = function(self, v)
		return math.floor(v * self.scale)
	end,
	["unit-interval"] = function(self, v)
		return math.max(0, math.min(v, 1))
	end
}


-- @param schema_root The topmost schema table.
-- @param schema_table The current subtable (starting with 'main' at the first level).
local function _skinDeepCopy(self, inst, def, schema_root, schema_table, _depth)
	--print("_skinDeepCopy: start", _depth)

	--[[
	setmetatable(inst, inst)
	inst.__index = def
	--]]

	for k, v in pairs(def) do
		local symbol = type(v) == "string" and v:sub(1, 1)
		if symbol == "&" then
			local tbl = schema_table[v:sub(2)]
			if not tbl then
				error("schema table lookup failed. Address: " .. tostring(v))
			end
			inst[k] = _skinDeepCopy(self, {}, v, schema_root or _dummy_schema, tbl, _depth + 1)

		elseif type(v) == "table" then
			inst[k] = _skinDeepCopy(self, {}, v, schema_root or _dummy_schema, schema_table[k] or _dummy_schema, _depth + 1)

		else
			--print("***", "k", k, "v", v)
			-- Pull in resources from the main theme table
			local stop_processing
			local ref_handler = _ref_handlers[symbol]
			if ref_handler then
				--print(">>> do lookup")
				stop_processing, inst[k] = ref_handler(self, v)
				--print(">>> value is now: ", tostring(inst[k]), "stop_processing: " .. tostring(stop_processing))
			else
				--print(">>> direct copy")
				inst[k] = v
			end

			if schema_table[k] and not stop_processing then
				local command = schema_table[k]
				local func = _schema_commands[command]
				if func then
					--print("schema command", command, "inst[k]", inst[k])
					inst[k] = func(self, inst[k])
				else
					error("unhandled schema command: " .. tostring(command))
				end
			end
		end
	end
	--print("_skinDeepCopy: end", _depth)
	return inst
end


local function _getSkinTables(self, id)
	local skin_inst = self.resources.skins[id]
	if not skin_inst then
		error("no skin loaded with ID: " .. tostring(id))
	end
	local skin_def = getmetatable(skin_inst)
	if not skin_def then
		error("missing SkinDef for ID: " .. tostring(id))
	end

	return skin_def, skin_inst
end


function methods:refreshSkinDefInstance(id)
	local skin_def, skin_inst = _getSkinTables(self, id)

	local skinner = self.resources.skinners[skin_def.skinner_id]
	if not skinner then
		error("missing skinner (the implementation). Skinner ID: " .. tostring(skin_def.skinner_id) .. ", requesting skin: " .. tostring(id))
	end
	local schema = skinner.schema or _dummy_schema
	local main = schema and schema.main or schema

	_skinDeepCopy(self, skin_inst, skin_def, schema, main, 1)
end


function methods:cloneSkinDef(skin_def_id)
	local skin_def = _getSkinTables(self, skin_def_id)
	local clone_def = pTable.deepCopy(skin_def)

	self:registerSkinDef(clone_def, clone_def)

	return clone_def
end


--- Remove a SkinDef from the theme registry.
-- @param id ID of the SkinDef to remove.
function methods:removeSkinDef(id) -- XXX Untested
	--[[
	The library user must *completely* uninstall the skin from all widgets.
	Any de-skinned widgets which require a skin must have replacements ASAP.
	--]]

	local skin = self.resources.skins[id]
	if not skin then
		error("Skin not found. ID: " .. tostring(id))
	end

	self.resources.skins[id] = nil
end


return contextResources