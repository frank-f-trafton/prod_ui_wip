-- ProdUI: Theme support functions.


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local commonMath = require(REQ_PATH .. "common.common_math")
local pTable = require(REQ_PATH .. "lib.pile_table")
local pUTF8 = require(REQ_PATH .. "lib.pile_utf8")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiGraphics = require(REQ_PATH .. "ui_graphics")
local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")
local utilTable = require(REQ_PATH .. "common.util_table")


local _drill = utilTable.drill


function uiTheme.dummyFunc() end


-- Cache of loaded fonts, where the keys are:
-- TrueType: 'path .. ":" .. size'
-- ImageFont: 'path .. ":ImageFont"'
-- BMFont: 'path .. ":BMFont"
local _fonts = setmetatable({}, {__mode="kv"})


local function _fontHash(path, tag)
	return path .. ":" .. tag
end


local _mt_themeInst = {}
_mt_themeInst.__index = _mt_themeInst


local _mt_themeDataPack = {}
_mt_themeDataPack.__index = _mt_themeDataPack



--- Create a new theme instance.
-- @return A theme instance table, which should be assigned to 'context.resources'.
function uiTheme.newThemeInstance(scale)
	scale = scale or 1.0

	--uiTheme.assertScale(1, scale, false) -- deleted
	scale = commonMath.clamp(scale, 0.1, 10.0)

	return setmetatable({
		scale = scale,

		skinners = {},
		skins = {},
		fonts = {},
		tex_defs = {},
		tex_quads = {},
		tex_slices = {},
	}, _mt_themeInst)
end


function _mt_themeInst:reset()
	for k, v in pairs(self) do
		pTable.clear(v)
	end
end


function _mt_themeInst:loadFont(id, v)

end



function uiTheme.newThemeDataPack()
	return setmetatable({}, _mt_themeDataPack)
end


--- Gets a top-level resource field, raising a Lua error if the value is nil.
-- @param field The field ID to check.
-- @return The field value.
function _mt_themeInst:get(field)
	local ret = self[field]
	if ret == nil then
		error("theme resource look-up failed. Field: " .. tostring(field))
	end

	return ret
end
_mt_themeDataPack.get = _mt_themeInst.get


--- Shortcut to make a new 9-Slice definition.
function uiTheme.newSlice(x,y, w1,h1, w2,h2, w3,h3, iw,ih)
	return quadSlice.newSlice(x,y, w1,h1, w2,h2, w3,h3, iw,ih)
end


--- Registers a SkinDef table to the theming system and creates a SkinInstance.
-- @param skin_def The SkinDef table to assign.
-- @param id The SkinDef ID to use. It must be a string, a number or a table, and it cannot already be registerd.
--	If the value is a table, then it must be the SkinDef table (skin_def == id).
function _mt_themeInst:registerSkinDef(skin_def, id)
	uiShared.type1(1, skin_def, "table")
	uiShared.type(1, id, "string", "number", "table")

	if type(id) == "table" and skin_def ~= id then
		error("when using a table as the ID, it must be the same table as the SkinDef (skin_def == id).")
	end

	if self.skins[id] then
		error("a SkinDef is already registered with this ID: " .. tostring(id))
	end

	local skin_inst = setmetatable({}, skin_def)
	self.skins[id] = skin_inst
	self:refreshSkinDefInstance(id)
end


--- Wrapper for loading a SkinDef from a file.
-- @param id The ID to use for the skin. Must not have already been registered.
-- @param path Path to the file containing the SkinDef.
-- @return The loaded SkinDef.
function _mt_themeInst:loadSkinDef(id, path)
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
function _mt_themeInst:loadSkinDefs(base_path, recursive, id_prepend)
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
		return false, _drill(self, "/", v:sub(2))
	end,
	["#"] = function(self, v)
		return true, _drill(self, "/", v:sub(2))
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
local function _skinDeepCopy(theme_inst, inst, def, schema_root, schema_table, _depth)
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
			inst[k] = _skinDeepCopy(theme_inst, {}, v, schema_root or _dummy_schema, tbl, _depth + 1)

		elseif type(v) == "table" then
			inst[k] = _skinDeepCopy(theme_inst, {}, v, schema_root or _dummy_schema, schema_table[k] or _dummy_schema, _depth + 1)

		else
			--print("***", "k", k, "v", v)
			-- Pull in resources from the main theme table
			local stop_processing
			local ref_handler = _ref_handlers[symbol]
			if ref_handler then
				--print(">>> do lookup")
				stop_processing, inst[k] = ref_handler(theme_inst, v)
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
					inst[k] = func(theme_inst, inst[k])
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
	local skin_inst = self.skins[id]
	if not skin_inst then
		error("no skin loaded with ID: " .. tostring(id))
	end
	local skin_def = getmetatable(skin_inst)
	if not skin_def then
		error("missing SkinDef for ID: " .. tostring(id))
	end

	return skin_def, skin_inst
end


function _mt_themeInst:refreshSkinDefInstance(id)
	local skin_def, skin_inst = _getSkinTables(self, id)

	local skinner = self.skinners[skin_def.skinner_id]
	if not skinner then
		error("missing skinner (the implementation). Skinner ID: " .. tostring(skin_def.skinner_id) .. ", requesting skin: " .. tostring(id))
	end
	local schema = skinner.schema or _dummy_schema
	local main = schema and schema.main or schema

	_skinDeepCopy(self, skin_inst, skin_def, schema, main, 1)
end


function _mt_themeInst:cloneSkinDef(skin_def_id)
	local skin_def = _getSkinTables(self, skin_def_id)
	local clone_def = pTable.deepCopy(skin_def)

	self:registerSkinDef(clone_def, clone_def)

	return clone_def
end


--- Remove a SkinDef from the theme registry.
-- @param id ID of the SkinDef to remove.
function _mt_themeInst:removeSkinDef(id) -- XXX Untested
	--[[
	The library user must *completely* uninstall the skin from all widgets.
	Any de-skinned widgets which require a skin must have replacements ASAP.
	--]]

	local skin = self.skins[id]
	if not skin then
		error("Skin not found. ID: " .. tostring(id))
	end

	self.skins[id] = nil
end


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


-- Workaround for Font:setFallbacks() not accepting a table of Fonts.
local MAX_FALLBACKS = 16


function uiTheme.setFontFallbacks(font, f1, f2, f3, f4, f5, f6, f7, f8, f9, fa, fb, fc, fd, fe, ff)
	if ff then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9, fa, fb, fc, fd, fe, ff)
	elseif fe then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9, fa, fb, fc, fd, fe)
	elseif fd then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9, fa, fb, fc, fd)
	elseif fc then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9, fa, fb, fc)
	elseif fb then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9, fa, fb)
	elseif fa then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9, fa)
	elseif f9 then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8, f9)
	elseif f8 then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7, f8)
	elseif f7 then font:setFallbacks(f1, f2, f3, f4, f5, f6, f7)
	elseif f6 then font:setFallbacks(f1, f2, f3, f4, f5, f6)
	elseif f5 then font:setFallbacks(f1, f2, f3, f4, f5)
	elseif f4 then font:setFallbacks(f1, f2, f3, f4)
	elseif f3 then font:setFallbacks(f1, f2, f3)
	elseif f2 then font:setFallbacks(f1, f2)
	elseif f1 then font:setFallbacks(f1)
	else font:setFallbacks() end
end


function uiTheme.instantiateFont(v)
	uiShared.type(1, v, "number", "table")

	if type(v) == "number" then
		local cached = _fonts[v]
		if cached then
			return cached
		end

		local font = love.graphics.newFont(v)
		_fonts[v] = font
		return font
	else -- table
		local path, size = v[1], v[2]
		assert(type(path) == "string", "path: expected string.")
		assert(type(size) == "number", "font size: expected number.")

		if #v > 2 + MAX_FALLBACKS*2 then
			error("max font fallbacks exceeded.")
		end

		local id = _fontHash(path, size)

		local font
		local cached = _fonts[id]
		if cached then
			font = cached
		else
			font = love.graphics.newFont(path, size)
			_fonts[id] = font
		end

		if #v > 2 then
			local fb = {}
			for i = 3, math.max(#v, 8), 2 do
				local path2, size2 = v[i], v[i + 1]
				local id2 = _fontHash(path2, size2)
				if not _fonts[id2] then
					_fonts[id2] = love.graphics.newFont(path2, size2)
				end
				fb[#fb + 1] = _fonts[id2]
			end
			uiTheme.setFontFallbacks(font,
				fb[3], fb[4], fb[5], fb[6], fb[7], fb[8], fb[9], fb[10],
				fb[11], fb[12], fb[13], fb[14], fb[15], fb[16], fb[17], fb[18],
				fb[19], fb[20], fb[21], fb[22], fb[23], fb[24], fb[25], fb[26],
				fb[27], fb[28], fb[29], fb[30], fb[31], fb[32], fb[33], fb[34]
			)
		end

		return font
	end
end


return uiTheme
