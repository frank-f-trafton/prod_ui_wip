-- ProdUI: Theme support functions.


--[[
Resource Tagging:

Fields beginning with an asterisk (self["*foobar"]) contain strings that indicate where a
particular resource can be found within the theme instance's table hierarchy. The reference
is assigned to a copy of the field without the leading asterisk:

self["*foobar"] = "path/to/foobar"
self.foobar = <resource pulled in from `resources.path.to.foobar`>

self["*bazbop"] = {"multiple/paths", "to/various", "textures/used"}
self.bazbop = <array containing three resources>

This is used when refreshing the contents of skin tables or widget instances.

Fields beginning with a dollar sign (self["$foobar"]) contain numbers which are automatically
scaled:

self["$foobar"] = 32
self.foobar = <math.floor(32 * theme.scale)>

self["$bazbop"] = {32, 64}
self.bazbop = <{math.floor(32 * theme.scale), math.floor(64 * theme.scale)}>
--]]


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- LÖVE Supplemental
local utf8 = require("utf8")


-- ProdUI
local pUTF8 = require(REQ_PATH .. "lib.pile_utf8")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiGraphics = require(REQ_PATH .. "ui_graphics")
local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")
local utilTable = require(REQ_PATH .. "logic.util_table")


function uiTheme.dummyFunc() end


local _mt_themeInst = {}
_mt_themeInst.__index = _mt_themeInst


local _mt_themeDataPack = {}
_mt_themeDataPack.__index = _mt_themeDataPack


local _mt_box_style = {}
_mt_box_style.__index = _mt_box_style


--- Create a new theme instance.
-- @param scale (1.0) UI scaling factor.
-- @return A theme instance table, which should be assigned to context.resources.
function uiTheme.newThemeInstance(scale)
	scale = scale or 1.0

	uiTheme.assertScale(1, scale, false)
	scale = uiRes.clamp(scale, 0.1, 10.0)

	local self = setmetatable({}, _mt_themeInst)

	self.scale = scale

	--[[
	The main `skins` table has weak references (both keys and values). This allows the theming
	system to manage temporary SkinDef patches without the need for additional bookkeeping when
	they are no longer referenced by anything. A secondary table, `skins_preserve`, prevents certain
	SkinDefs from being removed by the garbage collector. All SkinDefs loaded from disk are marked
	to be preserved.

	SkinDefs in `self.skins` but not in `self.skins_preserve` may disappear at any time, including
	while iterating over `self.skins` with pairs(). According to the Lua Users Wiki, this is safe
	behavior (unlike adding new keys to a table, which can lead to other keys not being iterated).

	http://lua-users.org/wiki/TablesTutorial (See: "Inside a pairs loop, ...")
	https://lua-l.lua.narkive.com/NmABQ5pO/iterating-weak-tables#post2
	--]]

	self.skins = setmetatable({}, {__mode = "kv"})
	self.skins_preserve = {}

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


--- Load or refresh a resource at tbl.<id> using a drill-string stored in tbl[<"?id">],
--  where '?' is one of a handful of single-byte UTF-8 symbols.
-- @param tbl The table to update (typically a skin definition or widget instance).
-- @param id String ID of the field to load or refresh (with the leading symbol).
function _mt_themeInst:applyResource(tbl, id)
	local symbol = string.sub(id, 1, 1)

	print("applyResource()", id)

	-- Pull in resources from the main theme table.
	if symbol == "*" then
		if type(tbl[id]) == "table" then
			local t2 = {}
			for i, s in ipairs(tbl[id]) do
				t2[i] = self:drillS(s)
			end
			tbl[id:sub(2)] = t2
		else
			tbl[id:sub(2)] = self:drillS(tbl[id])
		end

	-- Scale and floor numbers.
	elseif symbol == "$" then
		if type(tbl[id]) == "table" then
			local t2 = {}
			for i, n in ipairs(tbl[id]) do
				t2[i] = math.floor(n * self.scale)
			end
			tbl[id:sub(2)] = t2
		else
			tbl[id:sub(2)] = math.floor(tbl[id] * self.scale)
		end

	-- Invalid.
	else
		if not pUTF8.check(symbol) then
			symbol = "(Byte: " .. tostring(tonumber(symbol) .. ")")
		end

		error("invalid resource processor symbol: " .. symbol)
	end
end
_mt_themeDataPack.applyResource = _mt_themeInst.applyResource


--- Shortcut to make a new 9-Slice definition.
function uiTheme.newSlice(x,y, w1,h1, w2,h2, w3,h3, iw,ih)
	return quadSlice.newSlice(x,y, w1,h1, w2,h2, w3,h3, iw,ih)
end


--- Creates a new SkinDef table. Call from within SkinDef files to create the base table, and call in
--  user code to create extensions of existing registered skins.
-- @param extends String ID or the actual table of a skin that you wish to extend, or false/nil to
-- create this skin from scratch. If extending, the base skin must already be registered with the theming
-- system.
-- @param skin A pre-filled table to use for the SkinDef. This table must not be shared among other SkinDefs.
-- @return The new skin table.
function _mt_themeInst:newSkinDef(extends, skin)
	-- WARNING: Avoid making very deep __index chains.

	skin = skin or {}

	-- Root SkinDef.
	if not extends then
		-- (Nothing to do.)

	-- Extend based on string ID or existing skin table. The target skin must already be
	-- registered in the resources table. (Otherwise, the theming system won't be able to
	-- manage changes.)
	elseif type(extends) == "string" then
		local extends_tbl = self.skins[extends]
		if not extends_tbl then
			error("skin table not found in the theme registry. ID: " .. tostring(extends))
		end
		skin.__index = extends_tbl
		setmetatable(skin, skin)

	elseif type(extends) == "table" then
		if not self.skins[extends] then
			error("skin table not found in the theme registry. Address: " .. tostring(extends))
		end
		skin.__index = extends
		setmetatable(skin, skin)

	else
		uiShared.errBadType(1, extends, "false/nil/string/table")
	end

	return skin
end


--- Register a SkinDef table to the theming system.
-- @param skin The SkinDef table to assign.
-- @param id The SkinDef ID to use. Must be a string, a number or a table. If it is a table, then it must be
-- the SkinDef table (skin == id).
-- @param preserve When true, the SkinDef is added to a table which prevents it from being automatically
-- garbage-collected. (Use false for SkinDefs which will only be used for a single widget in an ad hoc manner.)
function _mt_themeInst:registerSkinDef(skin, id, preserve)
	-- Assertions
	-- [[
	if type(skin) ~= "table" then uiShared.errBadType(1, skin, "table")
	elseif type(id) ~= "string" and type(id) ~= "number" and type(id) ~= "table" then uiShared.errBadType(2, skin, "string/number/table") end
	--]]

	if type(id) == "table" and skin ~= id then
		error("when registering a table-based ID, its table reference must match the skin table (skin == id).")
	end

	if self.skins[id] then
		error("a skin is already registered with this ID: " .. tostring(id))
	end

	self.skins[id] = skin

	if preserve then
		self.skins_preserve[id] = skin
	end
end


--- Wrapper for loading a SkinDef from a file.
-- @param id The ID to use for the skin. Must not have already been registered.
-- @param path Path to the file containing the SkinDef.
-- @return The loaded SkinDef.
function _mt_themeInst:loadSkinDef(id, path)
	local def = uiRes.loadLuaFile(path, self, REQ_PATH)

	if type(def) ~= "table" then
		error("bad type for skin def (expected table, got " .. type(def) .. ") at path: " .. path)
	end

	-- SkinDefs loaded from disk are always set to preserve.
	self:registerSkinDef(def, id, true)

	self:refreshSkinDef(def)

	return def
end



local temp_remove = {}
--- Remove a SkinDef from the theme registry.
-- @param id ID of the SkinDef to remove.
function _mt_themeInst:removeSkinDef(id) -- XXX Untested
	--[[
	The library user must:

	-> *Completely* uninstall the SkinDef from all widgets.
	-> *Completely* uninstall any SkinDefs which extend *this* SkinDef from all widgets.
	-> *Completely* remove extension SkinDefs of this SkinDef, deepest first.

	Any de-skinned widgets which require a skin must have replacements ASAP.
	--]]

	-- Store all SkinDefs in a temporary table so that they are not removed by the garbage collector
	-- while this function works.
	for k, v in pairs(self.skins) do
		temp_remove[k] = v
	end

	local skin = self.skins[id]
	if not skin then
		error("SkinDef not found. ID: " .. tostring(id))
	end

	-- Removing a SkinDef which is extended by other SkinDefs is forbidden.
	for k, v in pairs(self.skins) do
		if v.__index == skin then
			error("cannot remove a SkinDef which is extended by other SkinDefs.")
		end
	end

	self.skins[id] = nil
	self.skins_preserve[id] = nil

	-- Free up the temp table.
	for k in pairs(temp_remove) do
		temp_remove[k] = nil
	end
end


local temp = {}
function _mt_themeInst:refreshSkinDef(skin)
	if #temp > 0 then
		error("internal scratchspace table is corrupt.")
	end

	-- Bad things happen if you add new fields to a table while iterating over it with pairs().
	-- Build a temporary list of fields that need attention.
	for k, v in pairs(skin) do
		if type(k) == "string" then
			local symbol = k:sub(1, 1)
			if symbol == "*" or symbol == "$" then
				temp[#temp + 1] = k
			end
		end
	end

	for i = #temp, 1, -1 do
		self:applyResource(skin, temp[i])
		temp[i] = nil
	end

	-- Apply box measurements directly to the SkinDef.
	local box = rawget(skin, "box")
	if box then
		if type(box) ~= "table" then
			error("expected type 'table' for SkinDef box style.")
		else
			if box.border_x1 then
				box:copyBorder(skin)
			end
			if box.margin_x1 then
				box:copyMargin(skin)
			end
		end
	end

	-- Recursively apply to all tables with string keys beginning with 'res_' or '>'.
	-- These subtables must not be shared (ie if one such table appears twice in some SkinDefs,
	-- then it will be updated twice, even though it really only needed to be processed once).
	for k, v in pairs(skin) do
		if type(k) == "string" and type(v) == "table" and string.sub(k, 1, 2) == ">" or string.sub(k, 1, 4) == "res_" then
			self:refreshSkinDef(v)
		end
	end
end


--- Pick a resource table in a skin based on three common widget state flags: self.enabled, self.pressed and self.hovered.
-- @param self The widget instance, containing a skin table reference.
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


--- Creates a new Box Style table.
-- @return The new Box Style table.
function uiTheme.newBoxStyle()
	--[[
	Fields:
	sl_body_id: The ID of a 9-Slice texture which should be rendered with the box.
	Used to unify the look of panels and context menus. Not all boxes include this
	field.

	outpad_*: The intended amount of outer padding around the box. Sometimes used
	by the layout system. Does not affect the widget's width and height directly.
	Similar to "margin" in HTML/CSS.

	border_*: A border that starts at the widget's edge and grows inward. Usually
	precludes scroll bars, and may be used to designate a widget's draggable edges.
	Similar to "border" in HTML/CSS.

	margin_*: Inner padding which begins at the border and grows inward.
	Similar to "padding" in HTML/CSS.
	--]]

	return setmetatable({}, _mt_box_style)
end


local function _assertBoxVar(box, id, expected)
	if type(box[id]) ~= expected then
		error("Box Style: bad type for requested field: " .. id .. " (expected " .. expected .. ", got " .. type(box[id]) .. ")")
	end
end


function _mt_box_style:getBodyID()
	_assertBoxVar(self, "sl_body_id", "string")

	return self.sl_body_id
end


function _mt_box_style:getOutpad()
	_assertBoxVar(self, "outpad_x1", "number")
	_assertBoxVar(self, "outpad_x2", "number")
	_assertBoxVar(self, "outpad_y1", "number")
	_assertBoxVar(self, "outpad_y2", "number")

	return self.outpad_x1, self.outpad_x2, self.outpad_y1, self.outpad_y2
end


function _mt_box_style:copyOutpad(wid)
	wid.outpad_x1, wid.outpad_x2, wid.outpad_y1, wid.outpad_y2 = self:getOutpad()
end


function _mt_box_style:getBorder()
	_assertBoxVar(self, "border_x1", "number")
	_assertBoxVar(self, "border_x2", "number")
	_assertBoxVar(self, "border_y1", "number")
	_assertBoxVar(self, "border_y2", "number")

	return self.border_x1, self.border_x2, self.border_y1, self.border_y2
end


function _mt_box_style:copyBorder(wid)
	wid.border_x1, wid.border_x2, wid.border_y1, wid.border_y2 = self:getBorder()
end


function _mt_box_style:getMargin()
	_assertBoxVar(self, "margin_x1", "number")
	_assertBoxVar(self, "margin_x2", "number")
	_assertBoxVar(self, "margin_y1", "number")
	_assertBoxVar(self, "margin_y2", "number")

	return self.margin_x1, self.margin_x2, self.margin_y1, self.margin_y2
end


function _mt_box_style:copyMargin(wid)
	wid.margin_x1, wid.margin_x2, wid.margin_y1, wid.margin_y2 = self:getMargin()
end


--- Check that a Box Style has the expected fields, raising a Lua error if any expected info is missing.
-- @param box The Box Style table to check.
-- @param has_body_id The box must have a Body ID string. (NOTE: does not confirm that the texture exists.)
-- @param has_outpad The box must have Outpad numbers.
-- @param has_border The box must have Border numbers.
-- @param has_margin The box must have Margin numbers.
function _mt_box_style:validate(has_body_id, has_outpad, has_border, has_margin)
	if has_body_id then
		self:getBodyID()
	end

	if has_outpad then
		self:getOutpad()
	end

	if has_border then
		self:getBorder()
	end

	if has_margin then
		self:getMargin()
	end
end


return uiTheme
