-- ProdUI: Theme support functions.


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


uiTheme.skinCheck = {}
local skinCheck = uiTheme.skinCheck


function skinCheck.exact(skin, k, ...)
	for i = 1, select("#", ...) do
		if skin[k] == select(i, ...) then
			return
		end
	end
	error("exact test failed")
end


function skinCheck.box(skin, t, k)
	if type(skin[k]) == "table" then
		-- Check types of populated fields...

		return
	end

	error("expected theme box")
end


function skinCheck.labelStyle(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected theme label style")
end


function skinCheck.scrollBarData(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected theme scroll bar data")
end


function skinCheck.scrollBarStyle(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected theme scroll bar style")
end


function skinCheck.font(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected font")
end


function skinCheck.iconData(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected IconData")
end


function skinCheck.thimbleInfo(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected thimbleInfo table")
end


function skinCheck.quad(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected resource quad")
end


function skinCheck.slice(skin, k)
	if type(skin[k]) == "table" then
		-- TODO

		return
	end

	error("expected resource slice")
end


function skinCheck.type(skin, k, ...)
	local typ = type(skin[k])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error("bad type")
end


function skinCheck.typeEval(skin, k, ...)
	if not skin[k] then
		return
	end
	local typ = type(skin[k])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error("bad type")
end


-- @param [enum_t] A specific enum table. Leave nil to use uiTheme's table of common enums.
function skinCheck.enum(skin, k, enum_t)
	local enum = enum_t or enums[k]
	if not enum then
		error("invalid enum table")
	end
	if skin[k] ~= nil then
		return enum[skin[k]]
	end
	error("missing enum: " .. tostring(k), 2)
end


function skinCheck.numberOrEnum(skin, k, enum_t, min, max)
	if skinCheck.numberEval(skin, k, min, max) then
		return
	end
	skinCheck.enum(skin, k, enum_t)
end


function skinCheck.numberOrExact(skin, k, min, max, ...)
	if skinCheck.numberEval(skin, k, min, max) then
		return
	end
	skinCheck.exact(skin, k, ...)
end


function skinCheck.integerOrExact(skin, k, min, max, ...)
	if skinCheck.integerEval(skin, k, min, max) then
		return
	end
	skinCheck.exact(skin, k, ...)
end



function skinCheck.number(skin, k, min, max)
	local n = skin[k]
	if type(n) ~= "number" then
		error("expected number")
	end
	if min and n < min then
		error("number is below the minimum")
	end
	if max and n > max then
		error("number is above the maximum")
	end
end


function skinCheck.numberEval(skin, k, min, max)
	local n = skin[k]
	if not n then
		return
	end
	if type(n) ~= "number" then
		error("expected number")
	end
	if min and n < min then
		error("number is below the minimum")
	end
	if max and n > max then
		error("number is above the maximum")
	end
	return true
end


function skinCheck.integer(skin, k, min, max)
	local n = skin[k]
	if type(n) ~= "number" or math.floor(n) ~= n then
		error("expected integer")
	end
	if min and n < min then
		error("integer is below the minimum")
	end
	if max and n > max then
		error("integer is above the maximum")
	end
end


function skinCheck.integerEval(skin, k, min, max)
	local n = skin[k]
	if not n then
		return
	end
	if type(n) ~= "number" or math.floor(n) ~= n then
		error("expected integer")
	end
	if min and n < min then
		error("integer is below the minimum")
	end
	if max and n > max then
		error("integer is above the maximum")
	end
	return true
end


function skinCheck.unitInterval(skin, k)
	local n = skin[k]
	if type(n) ~= "number" or n < 0.0 or n > 1.0 then
		error("expected number between 0.0 and 1.0")
	end
end


function skinCheck.colorTuple(skin, k)
	local c = skin[k]
	if type(c) ~= "table" then
		error("expected table")
	end
	if #c < 3 or #c > 4 then
		error("expected 3-4 array items")
	end
	for i, n in ipairs(c) do
		if type(n) ~= "number" then
			error("index #" .. i .. ": expected number")
		end
	end
end


function skinCheck.getRes(skin, k)
	local res = skin[k]
	if type(res) ~= "table" then
		error("missing resource table: " .. tostring(k))
	end
	return res
end


function skinCheck.sashState(skin)
	skinCheck.slice(skin, "slc_sash_lr")
	skinCheck.slice(skin, "slc_sash_tb")

	skinCheck.integer(skin, "sash_breadth")

	-- Reduces the intersection box when checking for the mouse *entering* a sash.
	-- NOTE: overly large values will make the sash unclickable.
	skinCheck.integer(skin, "sash_contract_x")
	skinCheck.integer(skin, "sash_contract_y")

	-- Increases the intersection box when checking for the mouse *leaving* a sash.
	-- NOTES:
	-- * Overly large values will prevent the user from clicking on widgets that
	--   are descendants of the divider.
	-- * The expansion does not go beyond the divider's body.
	skinCheck.integer(skin, "sash_expand_x")
	skinCheck.integer(skin, "sash_expand_y")

	skinCheck.type(skin, "cursor_sash_hover_h", "nil", "string")
	skinCheck.type(skin, "cursor_sash_hover_v", "nil", "string")
	skinCheck.type(skin, "cursor_sash_drag_h", "nil", "string")
	skinCheck.type(skin, "cursor_sash_drag_v", "nil", "string")
end


uiTheme.skinChange = {}
local skinChange = uiTheme.skinChange


function skinChange.numberScaled(skin, k, scale)
	skin[k] = skin[k] * scale
end


function skinChange.integerScaled(skin, k, scale)
	skin[k] = math.floor(skin[k] * scale)
end


return uiTheme
