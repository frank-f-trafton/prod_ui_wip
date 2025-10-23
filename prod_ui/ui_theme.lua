-- ProdUI: Theme support functions.


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- ProdUI
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiAssert = require(REQ_PATH .. "ui_assert")
local uiGraphics = require(REQ_PATH .. "ui_graphics")
local uiRes = require(REQ_PATH .. "ui_res")
local uiTable = require(REQ_PATH .. "ui_table")


uiTheme.settings = {
	max_font_size = 256
}


uiTheme.check = {}
local check = uiTheme.check


uiTheme.change = {}
local change = uiTheme.change


local err_label = {}


function uiTheme.pushLabel(k)
	uiAssert.notNilNotNaN(1, k)

	table.insert(err_label, tostring(k))
end


function uiTheme.popLabel()
	table.remove(err_label)
end


function uiTheme.setLabel(s)
	uiAssert.typeEval(1, s, "string")

	uiTable.clearArray(err_label)
	if s then
		uiTheme.pushLabel(s)
	end
end


function uiTheme.concatLabel()
	return table.concat(err_label, " > ")
end


function uiTheme.getLabelLevel()
	return #err_label
end


function uiTheme.assertLabelLevel(n)
	if #err_label ~= n then
		error("label stack mismatch: " .. table.concat(err_label, " > "))
	end
end


function uiTheme.error(s, l)
	l = l or 1
	local label = uiTheme.concatLabel()
	uiTheme.setLabel()
	error(label .. ": " .. tostring(s), l + 1)
end


uiTheme.named_maps = {
	-- LÖVE enums
	BlendAlphaMode = uiTable.newNamedMapV("BlendAlphaMode", "alphamultiply", "premultiplied"),
	BlendMode = uiTable.newNamedMapV("BlendMode", "alpha", "replace", "screen", "add", "subtract", "multiply", "lighten", "darken"),
	DrawMode = uiTable.newNamedMapV("DrawMode", "fill", "line"),
	LineJoin = uiTable.newNamedMapV("LineJoin", "bevel", "miter", "none"),
	LineStyle = uiTable.newNamedMapV("LineStyle", "rough", "smooth"),

	-- ProdUI theme
	font_type = uiTable.newNamedMap("FontExtensionType", {[".ttf"]="vector", [".otf"]="vector", [".fnt"]="bmfont", [".png"]="imagefont"}),

	-- ProdUI skin
	bijou_side_h = uiTable.newNamedMapV("BijouSideHorizontal", "left", "right"),
	graphic_placement = uiTable.newNamedMapV("GraphicPlacement", "left", "right", "top", "bottom", "overlay"),
	label_align_h = uiTable.newNamedMapV("LabelAlignHorizontal", "left", "center", "right", "justify"),
	label_align_v = uiTable.newNamedMapV("LabelAlignVertical", "top", "middle", "bottom"),
	quad_align_h = uiTable.newNamedMapV("QuadAlignHorizontal", "left", "center", "right"),
	quad_align_v = uiTable.newNamedMapV("QuadAlignVertical", "top", "middle", "bottom"),
}
local named_maps = uiTheme.named_maps


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


function uiTheme.scaleScrollBarStyle(sbs, scale)
	change.integerScaled(sbs, "bar_size", scale, 0)
	change.integerScaled(sbs, "button_size", scale, 0)
	change.integerScaled(sbs, "thumb_size_min", scale, 0)
	change.integerScaled(sbs, "thumb_size_max", scale, 0)
end


function uiTheme.scaleSashStyle(s, scale)
	change.integerScaled(s, "breadth_half", scale, 0)
	change.integerScaled(s, "contract_x", scale, 0)
	change.integerScaled(s, "contract_y", scale, 0)
	change.integerScaled(s, "expand_x", scale, 0)
	change.integerScaled(s, "expand_y", scale, 0)
end


local function _getFontTypeFromPath(path)
	if path == "default" then
		return "vector"
	end

	local ext = named_maps.font_type[path:sub(-4)]
	local font_type = ext
	if not font_type then
		uiTheme.pushLabel(ext)
		uiTheme.error("invalid font extension")
	end

	return font_type
end


local function _getFontInfoTable(tbl, k)
	local font_info = tbl[k]
	if not font_info then
		uiTheme.error("expected font-info table")
	end
	return font_info
end


function uiTheme.checkFontInfo(theme_fonts, k)
	uiTheme.pushLabel(k)

	local font_info = _getFontInfoTable(theme_fonts, k)
	check.type(font_info, "path", "string")

	local font_type = _getFontTypeFromPath(font_info.path)
	if font_type == "vector" then
		check.type(font_info, "size", "number")

	elseif font_type == "bmfont" then
		check.type(font_info, "image_path", "nil", "string")

	elseif font_type == "imagefont" then
		check.type(font_info, "glyphs", "string")
		check.type(font_info, "extraspacing", "nil", "number")
	end

	check.type(font_info, "fallbacks", "nil", "table")
	if font_info.fallbacks then
		uiTheme.pushLabel("fallbacks")
		for i, fb in ipairs(font_info.fallbacks) do
			uiTheme.pushLabel(i)

			check.type(fb, "path", "string")
			if font_type == "vector" then
				check.type(fb, "size", "number")
			end

			uiTheme.popLabel()
		end
		uiTheme.popLabel()
	end

	uiTheme.popLabel()
end


function uiTheme.scaleFontInfo(theme_fonts, k, scale)
	uiTheme.pushLabel(k)

	local font_info = _getFontInfoTable(theme_fonts, k)

	local font_type = _getFontTypeFromPath(font_info.path)
	if font_type == "vector" then
		change.integerScaled(font_info, "size", scale, 0, uiTheme.settings.max_font_size)
	end
	-- Do not scale ImageFont extraspacing.

	if font_info.fallbacks then
		uiTheme.pushLabel("fallbacks")
		for i, fb in ipairs(font_info.fallbacks) do
			uiTheme.pushLabel(i)

			if font_type == "vector" then
				change.integerScaled(fb, "size", scale, 0, uiTheme.settings.max_font_size)
			end

			uiTheme.popLabel()
		end
		uiTheme.popLabel()
	end

	uiTheme.popLabel()
end


function uiTheme.checkIconSets(icon_set)
	uiTheme.pushLabel("icons")
	for k, v in pairs(icon_set) do
		uiTheme.pushLabel(k)
		for kk, vv in pairs(v) do
			check.quad(v, kk)
		end
		uiTheme.popLabel()
	end
	uiTheme.popLabel()
end


local function _concatVariadic(...)
	local t = {...}
	for k, v in pairs(t) do
		t[k] = tostring(v)
	end
	return table.concat(t, ", ")
end


local function _concatFromHash(t)
	return table.concat(uiTable.arrayOfHashKeys(t), ", ")
end


-- 'check' functions


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


-- @param [nm_id] The NamedMap's ID. When omitted, it is assumed to be the same as 'k'.
function check.namedMap(skin, k, nm_id)
	nm_id = nm_id or k
	if nm_id == k then
		uiTheme.pushLabel(k)
	else
		uiTheme.pushLabel(k .. " (NamedMap: " .. nm_id .. ")")
	end

	local n_map = named_maps[nm_id]
	if not n_map then
		uiTheme.error("invalid NamedMap")

	elseif not n_map[skin[k]] then
		uiTheme.error("invalid value '" .. tostring(skin[k]) .. "' for NamedMap: " .. tostring(nm_id))
	end

	uiTheme.popLabel()
	return n_map[skin[k]]
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


function check.numberOrNamedMap(skin, k, n_map, min, max)
	if type(skin[k]) == "number" then
		return check.number(skin, k, min, max)
	else
		return check.namedMap(skin, k, n_map)
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


local function _checkSashRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)

	check.slice(res, "slc_lr")
	check.slice(res, "slc_tb")
	check.colorTuple(res, "col_body")

	uiTheme.popLabel()
end


function uiTheme.checkSashStyles(sash_styles)
	for k in pairs(sash_styles) do
		check.sashStyle(sash_styles, k)
	end
end


function check.thimbleInfo(skin, k)
	uiTheme.pushLabel(k)

	local thim = skin[k]
	if type(thim) ~= "table" then
		uiTheme.error("expected thimbleInfo table")
	end
	-- Common details for drawing a rectangular thimble glow.
	check.namedMap(thim, "mode", "DrawMode")
	check.colorTuple(thim, "color")
	check.namedMap(thim, "line_style", "LineStyle")
	check.integer(thim, "line_width", 0)
	check.namedMap(thim, "line_join", "LineJoin")
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


function check.sashStyle(skin, k)
	uiTheme.pushLabel(k)

	check.type(skin, k, "table")
	local style = skin[k]

	-- Width of tall sashes; height of wide sashes.
	check.integer(style, "breadth_half", 0)

	-- Reduces the intersection box when checking for the mouse *entering* a sash.
	-- NOTE: overly large values will make the sash unclickable.
	check.integer(style, "contract_x", 0)
	check.integer(style, "contract_y", 0)

	-- Increases the intersection box when checking for the mouse *leaving* a sash.
	-- NOTES:
	-- * Overly large values will prevent the user from clicking on widgets that
	--   are descendants of the container.
	-- * The expansion does not go beyond the container's body.
	check.integer(style, "expand_x", 0)
	check.integer(style, "expand_y", 0)

	-- To apply a graphical margin to a sash mosaic, please bake the margin into the texture.

	check.type(style, "cursor_hover_h", "nil", "string")
	check.type(style, "cursor_hover_v", "nil", "string")
	check.type(style, "cursor_drag_h", "nil", "string")
	check.type(style, "cursor_drag_v", "nil", "string")

	_checkSashRes(style, "res_idle")
	_checkSashRes(style, "res_hover")
	_checkSashRes(style, "res_press")
	_checkSashRes(style, "res_disabled")

	uiTheme.popLabel()
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
	check.namedMap(quad, "blend_mode", "BlendMode")
	check.namedMap(quad, "alpha_mode", "BlendAlphaMode")

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
	check.namedMap(slice, "blend_mode", "BlendMode")
	check.namedMap(slice, "alpha_mode", "BlendAlphaMode")

	check.type(slice, "slice", "table")
	check.metatableAsType(slice, "slice", "QuadSlice", quadSlice._mt_slice)

	uiTheme.pushLabel("(QuadSlice)")

	local slc = slice.slice

	check.number(slc, "x")
	check.number(slc, "y")
	check.number(slc, "w", 0)
	check.number(slc, "h", 0)
	check.number(slc, "w1", 0)
	check.number(slc, "h1", 0)
	check.number(slc, "w2", 0)
	check.number(slc, "h2", 0)
	check.number(slc, "w3", 0)
	check.number(slc, "h3", 0)
	check.number(slc, "iw", 0)
	check.number(slc, "ih", 0)

	check.type(slc, "mirror_h", "boolean")
	check.type(slc, "mirror_v", "boolean")

	check.type(slc, "quads", "table")

	uiTheme.pushLabel("(Quads)")

	for n = 1, 9 do
		check.loveType(slc.quads, n, "Quad")
	end

	uiTheme.popLabel() -- "(Quads)"

	uiTheme.popLabel() -- "(QuadSlice)"

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


function check.getRes(skin, k)
	local res = skin[k]
	if type(res) ~= "table" then
		uiTheme.error("expected resource table.")
	end
	return res
end


-- 'change' functions


function change.numberScaled(skin, k, scale, min, max)
	uiAssert.type(1, skin, "table")
	uiAssert.notNilNotNaN(2, k)
	uiAssert.type(3, scale, "number")
	uiAssert.typeEval(4, min, "number")
	uiAssert.typeEval(5, max, "number")

	min = min or -math.huge
	max = max or math.huge

	skin[k] = math.max(min, math.min(skin[k] * scale, max))
end


function change.integerScaled(skin, k, scale, min, max)
	uiAssert.type(1, skin, "table")
	uiAssert.notNilNotNaN(2, k)
	uiAssert.type(3, scale, "number")
	uiAssert.typeEval(4, min, "number")
	uiAssert.typeEval(5, max, "number")

	min = min or -math.huge
	max = max or math.huge

	print(k, skin, skin[k])
	skin[k] = math.floor(math.max(min, math.min(skin[k] * scale, max)))
end


uiTheme.asserts = {}


function uiTheme.asserts.quad(quad)
	uiAssert.type(1, quad, "table")

	uiAssert.numberNotNaN("x", quad.x)
	uiAssert.numberNotNaN("y", quad.y)
	uiAssert.numberNotNaN("w", quad.w)
	uiAssert.numberNotNaN("h", quad.h)

	uiAssert.loveTypes("texture", quad.texture, "Canvas", "Image", "Texture")
	uiAssert.loveType("quad", quad.quad, "Quad")
	uiAssert.namedMap("blend_mode", quad.blend_mode, uiTheme.named_maps.BlendMode)
	uiAssert.namedMap("alpha_mode", quad.alpha_mode, uiTheme.named_maps.BlendAlphaMode)
end


function uiTheme.asserts.slice(slice)
	uiAssert.type(1, slice, "table")

	uiTheme.asserts.quad(slice.tex_quad)

	uiAssert.loveTypes("texture", slice.texture, "Canvas", "Image", "Texture")
	uiAssert.namedMap("blend_mode", slice.blend_mode, uiTheme.named_maps.BlendMode)
	uiAssert.namedMap("alpha_mode", slice.alpha_mode, uiTheme.named_maps.BlendAlphaMode)

	uiAssert.type("slice", slice.slice, "table")
	uiAssert.tableHasThisMetatable("slice", slice.slice, quadSlice._mt_slice)

	uiTheme.asserts.sliceInternal(slice.slice)
end


function uiTheme.asserts.sliceInternal(slc)
	uiAssert.numberNotNaN("slc.x", slc.x)
	uiAssert.numberNotNaN("slc.y", slc.y)
	uiAssert.numberNotNaN("slc.w", slc.w)
	uiAssert.numberNotNaN("slc.h", slc.h)
	uiAssert.numberNotNaN("slc.w1", slc.w1)
	uiAssert.numberNotNaN("slc.h1", slc.h1)
	uiAssert.numberNotNaN("slc.w2", slc.w2)
	uiAssert.numberNotNaN("slc.h2", slc.h2)
	uiAssert.numberNotNaN("slc.w3", slc.w3)
	uiAssert.numberNotNaN("slc.h3", slc.h3)
	uiAssert.numberNotNaN("slc.iw", slc.iw)
	uiAssert.numberNotNaN("slc.ih", slc.ih)

	uiAssert.type("slc.mirror_h", slc.mirror_h, "boolean")
	uiAssert.type("slc.mirror_v", slc.mirror_v, "boolean")

	uiTheme.asserts.sliceInternalQuads(slc.quads)
end


function uiTheme.asserts.sliceInternalQuads(quads) -- slice.slice.quads
	uiAssert.type("quads", slc.quads, "table")

	for n = 1, 9 do
		check.loveType("slc.quads[" .. n .. "]", quads[n], "Quad")
	end
end

return uiTheme
