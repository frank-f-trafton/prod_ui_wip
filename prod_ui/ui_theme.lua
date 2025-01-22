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


function uiTheme.dummyFunc() end


local _mt_themeInst = {}
_mt_themeInst.__index = _mt_themeInst


local _mt_themeDataPack = {}
_mt_themeDataPack.__index = _mt_themeDataPack


local _mt_box_style = {}
_mt_box_style.__index = _mt_box_style
uiTheme._mt_box_style = _mt_box_style


--- Create a new theme instance.
-- @param scale (1.0) UI scaling factor.
-- @return A theme instance table, which should be assigned to context.resources.
function uiTheme.newThemeInstance(scale)
	scale = scale or 1.0

	uiTheme.assertScale(1, scale, false)
	scale = commonMath.clamp(scale, 0.1, 10.0)

	local self = setmetatable({}, _mt_themeInst)

	self.scale = scale

	self.skinners = {}
	self.skins = {}

	return self
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


--- Gets a resource within in a hierarchy of tables. Raises a Lua error if the value is nil or if the table path
--  is invalid.
-- @param ... Varargs list of fields to check.
-- @return The field value.
function _mt_themeInst:drill(...)
	local len = select("#", ...)

	local ret, bad_index = utilTable.tryDrillV(self, ...)
	if ret ~= nil then
		return ret
	end

	if bad_index then
		error("resource drill failed on index #" .. bad_index .. ". Fields: " .. utilTable.concatVarargs(...))
	else
		error("resource drill failed: final value is nil. Fields: " .. utilTable.concatVarargs(...))
	end
end
_mt_themeDataPack.drill = _mt_themeInst.drill


--- Gets a resources within a hierarchy of tables. The path to the resource is stored as a single string with a
--  forward slash (/) between chunks. Raises a Lua error if the value is nil or if the table path is invalid.
-- @param str The string containing the fields to check.
-- @return The field value.
function _mt_themeInst:drillS(str)
	local ret, bad_index = utilTable.tryDrillS(self, "/", str)
	if ret ~= nil then
		return ret
	end

	if bad_index then
		error("resource drill failed on index #" .. bad_index .. ". Fields: " .. str)
	else
		error("resource drill failed: final value is nil. Fields: " .. str)
	end
end
_mt_themeDataPack.drillS = _mt_themeInst.drillS


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


local _schema_commands = {
	["scaled-int"] = function(self, v)
		return math.floor(v * self.scale)
	end,
	["unit-interval"] = function(self, v)
		return math.max(0, math.min(v, 1))
	end
}


local _dummy_schema = {}


local function _skinDeepCopy(theme_inst, inst, def, schema, _depth)
	print("_skinDeepCopy: start", _depth)

	--[[
	setmetatable(inst, inst)
	inst.__index = def
	--]]

	for k, v in pairs(def) do
		if type(v) == "table" then
			inst[k] = _skinDeepCopy(theme_inst, {}, v, schema[k] or _dummy_schema, _depth + 1)
		else
			local symbol
			if type(k) == "string" then
				symbol = k:sub(1, 1)
				print("***", "k", k, "symbol", symbol, "v", v)
				-- Pull in resources from the main theme table
				if type(v) == "string" and v:sub(1, 1) == "*" then
					print(">>> do lookup")
					inst[k] = theme_inst:drillS(v:sub(2))
					print(">>> value is now: ", tostring(inst[k]))
				else
					print(">>> direct copy")
					inst[k] = v
				end
			else
				inst[k] = v
			end

			if schema[k] then
				local command = schema[k]
				local func = _schema_commands[command]
				if func then
					print("schema command", command, "inst[k]", inst[k])
					inst[k] = func(theme_inst, inst[k])
				else
					error("unhandled schema command: " .. tostring(command))
				end
			end
		end
	end
	print("_skinDeepCopy: end", _depth)
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

	_skinDeepCopy(self, skin_inst, skin_def, skinner.schema or _dummy_schema, 1)
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


--- Checks a scale number for issues (not a number, zero or negative value, etc.)
-- @param arg_n The argument number.
-- @param scale The scale number to check.
-- @param integral When true, the scale value must be an integer (math.floor(scale) == scale).
-- @return Nothing. Raises a Lua error if there's a problem.
function uiTheme.assertScale(arg_n, scale, integral)
	if type(scale) ~= "number" then
		error("argument #" .. arg_n .. ": expected number, got " .. type(scale), 2)

	elseif integral and math.floor(scale) ~= scale then
		error("argument #" .. arg_n .. ": scale must be an integer.", 2)

	elseif scale <= 0 then
		error("argument #" .. arg_n .. ": scale must be greater than zero.", 2)
	end
end


return uiTheme
