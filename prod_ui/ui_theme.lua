-- ProdUI: Theme supportfunctions.


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- ProdUI
local commonMath = require(REQ_PATH .. "common.common_math")
local pTable = require(REQ_PATH .. "lib.pile_table")
local pUTF8 = require(REQ_PATH .. "lib.pile_utf8")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiGraphics = require(REQ_PATH .. "ui_graphics")
local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")


local _makeLUTV = pTable.makeLUTV


uiTheme.enums = {
	bijou_side_h = _makeLUTV("left", "right"),

	graphic_placement = _makeLUTV("left", "right", "top", "bottom", "overlay"),

	label_align_h = _makeLUTV("left", "center", "right", "justify"),
	label_align_v = _makeLUTV("top", "middle", "bottom"),

	quad_align_h = _makeLUTV("left", "center", "right"),
	quad_align_v = _makeLUTV("top", "middle", "bottom"),

	text_align_OLD = _makeLUTV("left", "center", "right")
}
local enums = uiTheme.enums


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


uiTheme.check = {}
local check = uiTheme.check


local function _hdr(k)
	return "(key: " .. tostring(k) .. "): "
end


local function _concatFromVarArgs(...)
	local temp = {...}
	for i, v in ipairs(temp) do
		temp[i] = tostring(v)
	end
	return table.concat(temp, ", ")
end


local function _concatFromHash(t)
	local temp = {}
	for k in pairs(t) do
		table.insert(temp, k)
	end
	return table.concat(temp, ", ")
end


function check.exact(skin, k, ...)
	for i = 1, select("#", ...) do
		if skin[k] == select(i, ...) then
			return
		end
	end
	error(_hdr(k) .. "expected one of: " .. _concatFromVarArgs(...) .. ". Got: " .. tostring(skin[k]))
end


function check.type(skin, k, ...)
	local typ = type(skin[k])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(_hdr(k) .. "expected one of these types: " .. _concatFromVarArgs(...) .. ". Got: " .. typ)
end


function check.typeEval(skin, k, ...)
	if not skin[k] then
		return
	end
	local typ = type(skin[k])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(_hdr(k) .. "expected false/nil or one of these types: " .. _concatFromVarArgs(...) .. ". Got: " .. typ)
end


-- @param [enum_t] A specific enum table. Leave nil to use uiTheme's table of common enums.
function check.enum(skin, k, enum_t)
	local enum = enum_t or enums[k]
	if not enum then
		error("invalid enum table")
	end
	if enum[skin[k]] then
		return enum[skin[k]]
	end
	error(_hdr(k) .. "expected enum value: " .. _concatFromHash(enum) .. ". Got: " .. tostring(skin[k]))
end


function check.number(skin, k, min, max)
	local n = skin[k]
	if type(n) ~= "number" then
		error(_hdr(k) .. "expected number")

	elseif min and n < min then
		error(_hdr(k) .. "number is below the minimum")

	elseif max and n > max then
		error(_hdr(k) .. "number is above the maximum")
	end
end


function check.numberEval(skin, k, min, max)
	if skin[k] then
		check.number(skin, k, min, max)
	end
end


function check.numberOrEnum(skin, k, enum_t, min, max)
	if type(skin[k]) == "number" then
		check.number(skin, k, min, max)
		return
	end
	check.enum(skin, k, enum_t)
end


function check.numberOrExact(skin, k, min, max, ...)
	if type(skin[k]) == "number" then
		check.number(skin, k, min, max)
		return
	end
	check.exact(skin, k, ...)
end


function check.integer(skin, k, min, max)
	local n = skin[k]
	if type(n) ~= "number" or math.floor(n) ~= n then
		error(_hdr(k) .. "expected integer")

	elseif min and n < min then
		error(_hdr(k) .. "integer is below the minimum")

	elseif max and n > max then
		error(_hdr(k) .. "integer is above the maximum")
	end
end


function check.integerEval(skin, k, min, max)
	if skin[k] then
		check.integer(skin, k, min, max)
	end
end


function check.integerOrExact(skin, k, min, max, ...)
	if type(skin[k]) == "number" then
		check.integer(skin, k, min, max)
		return
	end
	check.exact(skin, k, ...)
end


function check.unitInterval(skin, k)
	local n = skin[k]
	if type(n) ~= "number" or n < 0.0 or n > 1.0 then
		error(_hdr(k) .. "expected number between 0.0 and 1.0")
	end
end


function check.box(skin, k)
	if type(skin[k]) == "table" then
		-- Check types of populated fields...

		return
	end

	error(_hdr(k) .. "expected theme box")
end


function check.labelStyle(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected theme label style")
end


function check.scrollBarData(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected theme scroll bar data")
end


function check.scrollBarStyle(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected theme scroll bar style")
end


function check.font(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected font")
end


function check.iconData(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected IconData")
end


function check.thimbleInfo(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected thimbleInfo table")
end


function check.quad(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected resource quad")
end


function check.slice(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error(_hdr(k) .. "expected resource slice")
end


function check.colorTuple(skin, k)
	local c = skin[k]
	if type(c) ~= "table" then
		error(_hdr(k) .. "expected table (of colors)")

	elseif #c < 3 or #c > 4 then
		error(_hdr(k) .. "expected 3-4 array items (colors)")
	end
	for i, n in ipairs(c) do
		if type(n) ~= "number" then
			error(_hdr(k) .. "index #" .. i .. ": expected number (for color)")
		end
	end
end


function check.sashState(skin)
	check.slice(skin, "slc_sash_lr")
	check.slice(skin, "slc_sash_tb")

	check.integer(skin, "sash_breadth")

	-- Reduces the intersection box when checking for the mouse *entering* a sash.
	-- NOTE: overly large values will make the sash unclickable.
	check.integer(skin, "sash_contract_x")
	check.integer(skin, "sash_contract_y")

	-- Increases the intersection box when checking for the mouse *leaving* a sash.
	-- NOTES:
	-- * Overly large values will prevent the user from clicking on widgets that
	--   are descendants of the divider.
	-- * The expansion does not go beyond the divider's body.
	check.integer(skin, "sash_expand_x")
	check.integer(skin, "sash_expand_y")

	check.type(skin, "cursor_sash_hover_h", "nil", "string")
	check.type(skin, "cursor_sash_hover_v", "nil", "string")
	check.type(skin, "cursor_sash_drag_h", "nil", "string")
	check.type(skin, "cursor_sash_drag_v", "nil", "string")
end


function check.getRes(skin, k)
	local res = skin[k]
	if type(res) ~= "table" then
		error(_hdr(k) .. "expected resource table.")
	end
	return res
end


uiTheme.change = {}
local change = uiTheme.change


function change.numberScaled(skin, k, scale)
	skin[k] = skin[k] * scale
end


function change.integerScaled(skin, k, scale)
	skin[k] = math.floor(skin[k] * scale)
end


return uiTheme
