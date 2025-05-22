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


local err_label = {}


function uiTheme.pushLabel(k)
	uiShared.notNilNotNaN(1, k)

	table.insert(err_label, tostring(k))
end


function uiTheme.popLabel()
	table.remove(err_label)
end


function uiTheme.setLabel(s)
	uiShared.typeEval(1, s, "string")

	pTable.clearArray(err_label)
	if s then
		uiTheme.pushLabel(s)
	end
end


function uiTheme.concatLabel()
	return table.concat(err_label, " > ")
end


function uiTheme.assertLabelEmpty()
	if #err_label > 0 then
		error("the label stack is not empty: " .. table.concat(err_label, " > "))
	end
end



function uiTheme.error(s, l)
	l = l or 1
	local label = uiTheme.concatLabel()
	uiTheme.setLabel()
	error(label .. ": " .. tostring(s), l + 1)
end


uiTheme.enums = {
	-- ProdUI skin enums
	bijou_side_h = _makeLUTV("left", "right"),
	graphic_placement = _makeLUTV("left", "right", "top", "bottom", "overlay"),
	label_align_h = _makeLUTV("left", "center", "right", "justify"),
	label_align_v = _makeLUTV("top", "middle", "bottom"),
	quad_align_h = _makeLUTV("left", "center", "right"),
	quad_align_v = _makeLUTV("top", "middle", "bottom"),
	text_align_OLD = _makeLUTV("left", "center", "right"),

	-- LÖVE enums
	BlendAlphaMode = _makeLUTV("alphamultiply", "premultiplied"),
	BlendMode = _makeLUTV("alpha", "replace", "screen", "add", "subtract", "multiply", "lighten", "darken"),
	DrawMode = _makeLUTV("fill", "line"),
	LineJoin = _makeLUTV("bevel", "miter", "none"),
	LineStyle = _makeLUTV("rough", "smooth")
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


function uiTheme.scaleBox(box, scale)
	for k, v in pairs(box) do
		for k2, v2 in pairs(v) do
			if type(v2) == "number" then
				v[k2] = math.max(0, math.floor(v2 * scale))
			end
		end
	end
end


uiTheme.check = {}
local check = uiTheme.check


local function _concatVariadic(...)
	local t = {...}
	pTable.toStringAll(t)
	return table.concat(t, ", ")
end


local function _concatFromHash(t)
	return table.concat(pTable.arrayOfHashKeys(t), ", ")
end


function check.eval(fn, skin, k, ...)
	if skin[k] then
		return fn(skin, k, ...)
	end
end


function check.exact(skin, k, ...)
	uiTheme.pushLabel(k)

	local v = skin[k]
	for i = 1, select("#", ...) do
		if v == select(i, ...) then
			uiTheme.popLabel()
			return v
		end
	end

	uiTheme.error("expected one of: " .. _concatVariadic(...) .. ". Got: " .. tostring(skin[k]))
end


function check.type(skin, k, ...)
	uiTheme.pushLabel(k)

	local typ = type(skin[k])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			uiTheme.popLabel()
			return skin[k]
		end
	end

	uiTheme.error("expected one of these types: " .. _concatVariadic(...) .. ". Got: " .. typ)
end


function check.loveType(skin, k, ...)
	uiTheme.pushLabel(k)

	local object = skin[k]
	if type(object) == "userdata" then
		local love_typ = object:type()
		for i = 1, select("#", ...) do
			if love_typ == select(i, ...) then
				uiTheme.popLabel()
				return object
			end
		end
		uiTheme.error("expected LÖVE object of type: " .. _concatVariadic(...) .. ". Got: " .. love_typ)
	end

	uiTheme.error("expected userdata (LÖVE object). Got: " .. type(object))
end


function check.loveTypeOf(skin, k, ...)
	uiTheme.pushLabel(k)
	local object = skin[k]

	if type(object) == "userdata" then
		for i = 1, select("#", ...) do
			if object:typeOf(select(i, ...)) then
				uiTheme.popLabel()
				return object
			end
		end
		uiTheme.error("expected LÖVE object with one of these types in its hierarchy: " .. _concatVariadic(...))
	end

	uiTheme.error("expected userdata (LÖVE object). Got: " .. type(object))
end


-- @param [enum_id] The enum table's ID. When omitted, it is assumed to be the same as 'k'.
function check.enum(skin, k, enum_id)
	enum_id = enum_id or k
	if enum_id == k then
		uiTheme.pushLabel(k)
	else
		uiTheme.pushLabel(k .. " (enum: " .. enum_id .. ")")
	end

	local enum = enums[enum_id]
	if not enum then
		uiTheme.error("invalid enum table")

	elseif not enum[skin[k]] then
		uiTheme.error("invalid value '" .. tostring(skin[k]) .. "' for enum: " .. tostring(enum_id))
	end

	uiTheme.popLabel()
	return enum[skin[k]]
end


function check.number(skin, k, min, max)
	uiTheme.pushLabel(k)

	local n = skin[k]
	if type(n) ~= "number" then
		uiTheme.error("expected number")

	elseif min and n < min then
		uiTheme.error("number is below the minimum")

	elseif max and n > max then
		uiTheme.error("number is above the maximum")
	end

	uiTheme.popLabel()
	return n
end


function check.integer(skin, k, min, max)
	uiTheme.pushLabel(k)

	local n = skin[k]
	if type(n) ~= "number" or math.floor(n) ~= n then
		uiTheme.error("expected integer")

	elseif min and n < min then
		uiTheme.error("integer is below the minimum")

	elseif max and n > max then
		uiTheme.error("integer is above the maximum")
	end

	uiTheme.popLabel()
	return n
end


function check.unitInterval(skin, k)
	uiTheme.pushLabel(k)

	local n = skin[k]
	if type(n) ~= "number" or n < 0.0 or n > 1.0 then
		uiTheme.error("expected number between 0.0 and 1.0")
	end

	uiTheme.popLabel()
	return n
end


function check.numberOrEnum(skin, k, enum_t, min, max)
	if type(skin[k]) == "number" then
		return check.number(skin, k, min, max)
	else
		return check.enum(skin, k, enum_t)
	end
end


function check.numberOrExact(skin, k, min, max, ...)
	if type(skin[k]) == "number" then
		return check.number(skin, k, min, max)
	else
		return check.exact(skin, k, ...)
	end
end


function check.integerOrExact(skin, k, min, max, ...)
	if type(skin[k]) == "number" then
		return check.integer(skin, k, min, max)
	else
		return check.exact(skin, k, ...)
	end
end


function check.box(skin, k)
	uiTheme.pushLabel(k)

	local box = skin[k]
	if type(box) ~= "table" then
		uiTheme.error("expected theme box")
	end

	for k, tbl in pairs(box) do
		check.number(tbl, "x1")
		check.number(tbl, "x2")
		check.number(tbl, "y1")
		check.number(tbl, "y2")
	end

	uiTheme.popLabel()
	return box
end


function check.labelStyle(skin, k)
	uiTheme.pushLabel(k)

	local label = skin[k]
	if type(label) ~= "table" then
		uiTheme.error("expected theme label style")
	end

	check.loveType(label, "font", "Font")
	if label.ul_color then
		check.colorTuple(label, "ul_color")
	end
	check.number(label, "ul_h", 0)

	uiTheme.popLabel()
	return label
end


local function _scrollBarDataShared(tbl, k)
	local res = check.type(tbl, k, "table")
	uiTheme.pushLabel(k)

	check.slice(res, "slice")
	check.colorTuple(res, "col_body")
	check.colorTuple(res, "col_symbol")

	uiTheme.popLabel()
	return res
end


function check.scrollBarData(skin, k)
	uiTheme.pushLabel(k)

	local sbd = skin[k]
	if type(sbd) ~= "table" then
		uiTheme.error("expected theme scroll bar data")
	end
	check.quad(sbd, "tquad_pixel")
	check.quad(sbd, "tq_arrow_down")
	check.quad(sbd, "tq_arrow_up")
	check.quad(sbd, "tq_arrow_left")
	check.quad(sbd, "tq_arrow_right")

	-- This might be helpful if the buttons and trough do not fit snugly into the scroll bar's rectangular body.
	check.type(sbd, "render_body", "nil", "boolean")

	check.colorTuple(sbd, "body_color")
	check.colorTuple(sbd, "col_trough")

	-- In this implementation, the thumb and buttons share slices and colors for idle, hover and press states.
	check.type(sbd, "shared", "table")
	_scrollBarDataShared(sbd.shared, "idle")
	_scrollBarDataShared(sbd.shared, "hover")
	_scrollBarDataShared(sbd.shared, "press")
	_scrollBarDataShared(sbd.shared, "disabled")

	uiTheme.popLabel()
	return sbd
end


function check.scrollBarStyle(skin, k)
	uiTheme.pushLabel(k)

	local sbs = skin[k]
	if type(sbs) ~= "table" then
		uiTheme.error("expected theme scroll bar style")
	end

	check.eval(check.type, sbs, "has_buttons", "boolean")
	check.eval(check.type, sbs, "trough_enabled", "boolean")
	check.eval(check.type, sbs, "thumb_enabled", "boolean")

	check.integer(sbs, "bar_size", 0)
	check.integer(sbs, "button_size", 0)
	check.integer(sbs, "thumb_size_min", 0)
	check.integer(sbs, "thumb_size_max", 0)

	check.eval(check.type, sbs, "v_near_side", "boolean")
	check.eval(check.type, sbs, "v_auto_hide", "boolean")

	check.eval(check.type, sbs, "v_button1_enabled", "boolean")
	check.exact(sbs, "v_button1_mode", "pend-pend", "pend-cont", "cont")
	check.eval(check.type, sbs, "v_button2_enabled", "boolean")
	check.exact(sbs, "v_button2_mode", "pend-pend", "pend-cont", "cont")

	check.eval(check.type, sbs, "h_near_side", "boolean")
	check.eval(check.type, sbs, "h_auto_hide", "boolean")

	check.eval(check.type, sbs, "h_button1_enabled", "boolean")
	check.exact(sbs, "h_button1_mode", "pend-pend", "pend-cont", "cont")
	check.eval(check.type, sbs, "h_button2_enabled", "boolean")
	check.exact(sbs, "h_button2_mode", "pend-pend", "pend-cont", "cont")

	uiTheme.popLabel()
	return sbs
end


function check.iconData(skin, k)
	uiTheme.pushLabel(k)

	local icon = skin[k]
	if type(icon) ~= "table" then
		uiTheme.error("expected IconData")
	end
	check.integer(icon, "w")
	check.integer(icon, "h")
	check.integer(icon, "pad_x1")
	check.integer(icon, "pad_x2")
	check.integer(icon, "pad_y")

	uiTheme.popLabel()
	return icon
end


function check.thimbleInfo(skin, k)
	uiTheme.pushLabel(k)

	local thim = skin[k]
	if type(thim) ~= "table" then
		uiTheme.error("expected thimbleInfo table")
	end
	-- Common details for drawing a rectangular thimble glow.
	check.enum(thim, "mode", "DrawMode")
	check.colorTuple(thim, "color")
	check.enum(thim, "line_style", "LineStyle")
	check.integer(thim, "line_width", 0)
	check.enum(thim, "line_join", "LineJoin")
	check.number(thim, "corner_rx", 0)
	check.number(thim, "corner_ry", 0)

	-- Pushes the thimble outline out from the widget rectangle.
	-- This is overridden if the widget contains 'self.thimble_x(|y|w|h)'.
	check.integer(thim, "outline_pad", 0)

	if thim.segments then
		check.number(thim, "segments", 0)
	end

	uiTheme.popLabel()
	return thim
end


function check.quad(skin, k)
	uiTheme.pushLabel(k)

	local quad = skin[k]
	if type(quad) ~= "table" then
		uiTheme.error("expected resource quad")
	end

	check.number(quad, "x")
	check.number(quad, "y")
	check.number(quad, "w")
	check.number(quad, "h")
	check.loveType(quad, "texture", "Canvas", "Image", "Texture")
	check.loveType(quad, "quad", "Quad")
	check.enum(quad, "blend_mode", "BlendMode")
	check.enum(quad, "alpha_mode", "BlendAlphaMode")

	uiTheme.popLabel()
	return quad
end


function check.metatableAsType(skin, k, id, ...)
	uiTheme.pushLabel(k)

	local tbl = skin[k]
	if type(tbl) == "table" then
		local mt = getmetatable(tbl)
		for i = 1, select("#", ...) do
			if mt == select(i, ...) then
				uiTheme.popLabel()
				return tbl
			end
		end

	end

	uiTheme.error("expected " .. id)
end


function check.slice(skin, k)
	uiTheme.pushLabel(k)

	local slice = skin[k]
	if type(slice) ~= "table" then
		uiTheme.error("expected resource slice")
	end
	check.quad(slice, "tex_quad")
	check.loveType(slice, "texture", "Canvas", "Image", "Texture")
	check.enum(slice, "blend_mode", "BlendMode")
	check.enum(slice, "alpha_mode", "BlendAlphaMode")
	check.metatableAsType(slice, "slice", "QuadSlice", quadSlice._mt_slice)
	-- TODO: write a validation function for QuadSlices within quad_slice.lua,
	-- and then call it here.

	uiTheme.popLabel()
end


-- Color tables, in the form of {1, 1, 1} (RGB) or {1, 1, 1, 1} (RGBA)
function check.colorTuple(skin, k)
	uiTheme.pushLabel(k)

	local c = skin[k]
	if type(c) == "table" and #c >= 3 and #c <= 4 then
		for i, n in ipairs(c) do
			if type(n) ~= "number" then
				uiTheme.error("index #" .. i .. ": expected number (for color)")
			end
		end

		uiTheme.popLabel()
		return c
	end

	uiTheme.error("expected table (of colors) with 3-4 array items")
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
		uiTheme.error("expected resource table.")
	end
	return res
end


uiTheme.change = {}
local change = uiTheme.change


function change.numberScaled(skin, k, scale)
	uiShared.type1(1, skin, "table")
	uiShared.notNilNotNaN(2, k)
	uiShared.type1(3, scale, "number")

	skin[k] = skin[k] * scale
end


function change.integerScaled(skin, k, scale)
	uiShared.type1(1, skin, "table")
	uiShared.notNilNotNaN(2, k)
	uiShared.type1(3, scale, "number")

	skin[k] = math.floor(skin[k] * scale)
end


return uiTheme
