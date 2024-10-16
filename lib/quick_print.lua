-- QuickPrint: A text drawing library for LÖVE.
-- Version: 1.1.0
-- Supported LÖVE versions: 11.4, 11.5
-- See LICENSE, README.md and the demos for more info.


local quickPrint = {}


local utf8 = require("utf8")


local _mt_qp = {}
_mt_qp.__index = _mt_qp


-- Override these (either here or in individual qp instances) to change printing behavior.
-- For example, you could write a wrapper that first prints a black drop-shadow version of the text.
_mt_qp._love_print = love.graphics.print
_mt_qp._love_printf = love.graphics.printf
_mt_qp._text_add = nil
_mt_qp._text_addf = nil


quickPrint.aux_db = {}
quickPrint._mt_aux_db = {__mode = "k"}
setmetatable(quickPrint.aux_db, quickPrint._mt_aux_db)


local enum_align = {["left"] = true, ["center"] = true, ["right"] = true, ["justify"] = true}
local enum_v_align = {["top"] = true, ["middle"] = true, ["true-middle"] = true, ["baseline"] = true, ["bottom"] = true}


local function errType(arg_n, val, expected)
	error("argument #" .. arg_n .. " bad type (expected " .. expected .. ", got: " .. type(val) .. ")", 3)
end


local function errEnumAlign(arg_n, val)
	error("argument #" .. arg_n .. ": invalid horizontal align enum: " .. tostring(val), 3)
end


local function errEnumVAlign(arg_n, val)
	error("argument #" .. arg_n .. ": invalid vertical align enum: " .. tostring(val), 3)
end


local function getVAlignOffset(font, aux, v_align)
	-- value for "top" and invalid enums
	local ret = 0

	if v_align == "true-middle" then
		ret = -math.floor(aux.sy * (aux.height / 2) + 0.5)

	elseif v_align == "middle" then
		ret = -math.floor(aux.sy * (aux.baseline - (aux.baseline - aux.ascent)) / 2 + 0.5)

	elseif v_align == "baseline" then
		ret = -math.floor(aux.sy * (aux.baseline) + 0.5)

	elseif v_align == "bottom" then
		ret = -aux.sy * aux.height
	end

	-- multiply the result with self.sy
	return ret
end


local function plainWrite(self, str, font, aux)
	local text_width = font:getWidth(str)
	local align = self.align
	local scale_x = self.sx * aux.sx
	local scale_y = self.sy * aux.sy

	if font ~= self.line_font then
		self:clearKerningMemory()
	end

	-- handle tab placement
	if self.tabs then
		local tab_x = self.tabs[self.tab_i]

		if type(tab_x) == "table" then
			align = tab_x.align or align
			tab_x = tab_x.x
		end

		if tab_x then
			if align == "left" or align == "justify" then
				self.x = math.max(self.x, tab_x)

			elseif align == "center" then
				self.x = math.max(self.x, tab_x - math.floor(text_width*scale_x/2))

			elseif align == "right" then
				self.x = math.max(self.x, tab_x - text_width*scale_x)
			end

			self:clearKerningMemory()
		end
	end

	if #str > 0 then
		-- apply plain alignment relative to cursor X

		-- check kerning, if applicable
		-- NOTE: The kerning offset may be incorrect if you switched between incompatible fonts from the last print operation.
		-- You can eliminate the kerning check by calling self:clearKerningMemory() between writes.
		if self.last_glyph then
			self.x = self.x + font:getKerning(self.last_glyph, utf8.codepoint(str, 1))
		end

		local px = self.origin_x + self.x + aux.ox
		local py = self.origin_y + self.y + aux.oy

		py = py + getVAlignOffset(font, aux, self.v_align) * self.sy

		-- NOTE: plainWrite() on its own does not move the cursor down to the next line, even if the string contains '\n'.
		if self.text_object then
			if self._text_add then
				self._text_add(self.text_object, str, px, py, 0, scale_x, scale_y, 0, 0, 0, 0)
			else
				self.text_object:add(str, px, py, 0, scale_x, scale_y, 0, 0, 0, 0)
			end
		else
			self._love_print(str, px, py, 0, scale_x, scale_y, 0, 0, 0, 0)
		end
	end

	-- update kerning info for next write on this line
	-- may be cleared by advanceTab()
	if #str > 0 then
		self.last_glyph = utf8.codepoint(str, utf8.offset(str, -1))
	end

	self.x = math.ceil(self.x + text_width * scale_x)
	self:advanceTab()
end


local function formattedPrintLogic(self, text, align, font, aux, px, py)
	local scale_x = self.sx * aux.sx
	local scale_y = self.sy * aux.sy
	local scaled_w = math.ceil(self.ref_w / math.max(scale_x, 0.0000001)) -- avoid div/0
	py = py + getVAlignOffset(font, aux, self.v_align) * self.sy

	px = px + aux.ox
	py = py + aux.oy

	if self.text_object then
		if self._text_addf then
			self.text_addf(self.text_object, text, scaled_w, align, px, py, 0, scale_x, scale_y, 0, 0, 0, 0)
		else
			self.text_object:addf(text, scaled_w, align, px, py, 0, scale_x, scale_y, 0, 0, 0, 0)
		end
	else
		self._love_printf(text, px, py, scaled_w, align, 0, scale_x, scale_y, 0, 0, 0, 0)
	end
end


function quickPrint.new(ref_w, ref_h)
	ref_w = ref_w or math.huge
	ref_h = ref_h or math.huge
	if type(ref_w) ~= "number" then errType(1, ref_w, "number/nil")
	elseif type(ref_h) ~= "number" then errType(2, ref_h, "number/nil") end

	local self = {}

	self.origin_x = 0
	self.origin_y = 0
	self.ref_w = ref_w or math.huge
	self.ref_h = ref_h or math.huge
	-- 'ref_h' does nothing, but is provided in case it helps with assigning scissor boxes
	-- or placement against a bottom boundary.

	self.x, self.y = 0, 0
	self.sx, self.sy = 1, 1
	self.pad_v = 0

	self.last_glyph = false
	self.line_font = false

	self.default_align = "left" -- "left", "center", "right", "justify"
	self.align = self.default_align

	self.default_v_align = "top" -- "top", "middle", "true-middle", "baseline", "bottom"
	self.v_align = self.default_v_align

	-- applies to: qp:print*(), qp:write*(), qp:writefSingle()
	self.tab_i = 1
	self.tabs = false

	self.text_object = false

	return setmetatable(self, _mt_qp)
end


function quickPrint.registerFont(font)
	if type(font) ~= "userdata" then errType(1, font, "userdata (LÖVE Font)") end

	local entry = {
		height = font:getHeight(),
		ascent = font:getAscent(),
		descent = font:getDescent(),
		baseline = font:getBaseline(),

		-- font scale, multiplied with 'qp.sx' and 'qp.sy'
		sx = 1.0,
		sy = 1.0,

		-- font offset, in pixels (not scaled by 'aux.sx' and 'aux.sy')
		ox = 0,
		oy = 0
		}

	-- overwrites any existing entry
	quickPrint.aux_db[font] = entry

	return entry
end


function quickPrint.getAux(font)
	-- 'font' is type-checked by quickPrint.registerFont()

	local aux = quickPrint.aux_db[font]
	if not aux then
		aux = quickPrint.registerFont(font)
	end

	return aux
end


function _mt_qp:getFont()
	return self.text_object and self.text_object:getFont() or love.graphics.getFont()
end


function _mt_qp:setTextObject(text_object)
	if text_object and type(text_object) ~= "userdata" then errType(1, text_object, "false/nil or userdata (LÖVE Text Object)") end

	self.text_object = text_object or false
end


function _mt_qp:getTextObject()
	return self.text_object or nil
end


function _mt_qp:setTabs(tabs)
	if tabs and type(tabs) ~= "table" then errType(1, tabs, "table or false/nil") end

	self.tabs = tabs or false
end


function _mt_qp:getTabs()
	return self.tabs or nil
end


function _mt_qp:setAlign(align)
	if not enum_align[align] then errEnumAlign(1, align) end

	self.align = align
end


function _mt_qp:getAlign()
	return self.align
end


function _mt_qp:setDefaultAlign(align)
	if not enum_align[align] then errEnumAlign(1, align) end

	self.default_align = align
end


function _mt_qp:getDefaultAlign()
	return self.default_align
end


function _mt_qp:setVAlign(v_align)
	if not enum_v_align[v_align] then errEnumVAlign(1, v_align) end

	self.v_align = v_align
end


function _mt_qp:getVAlign()
	return self.v_align
end


function _mt_qp:setDefaultVAlign(v_align)
	if not enum_v_align[v_align] then errEnumVAlign(1, v_align) end

	self.default_v_align = v_align
end


function _mt_qp:getDefaultVAlign()
	return self.default_v_align
end


function _mt_qp:advanceX(width)
	if type(width) ~= "number" then errType(1, width, "number") end

	-- Cursor X advance is generally only useful with left alignment. The other align modes are intended to
	-- be used with virtual tab stops.

	self.x = math.ceil(self.x + width)

	self:clearKerningMemory()
end


function _mt_qp:advanceXStr(str)
	if type(str) ~= "string" then errType(1, str, "string") end

	local font = self:getFont()
	local width = font:getWidth(str)

	self.x = math.ceil(self.x + width)

	self:clearKerningMemory()
end


function _mt_qp:setXMin(x_min)
	if type(x_min) ~= "number" then errType(1, x_min, "number") end

	self.x = math.max(self.x, x_min)

	self:clearKerningMemory()
end


function _mt_qp:advanceXCoarse(coarse_x, margin)
	margin = margin or 0
	if type(coarse_x) ~= "number" then errType(1, coarse_x, "number")
	elseif type(margin) ~= "number" then errType(2, margin, "nil/number") end

	self.x = math.max(self.x, math.floor(((self.x + margin + coarse_x) / coarse_x)) * coarse_x)

	self:clearKerningMemory()
end


function _mt_qp:advanceTab()
	if self.tabs then
		local tab_x = self.tabs[self.tab_i]
		if type(tab_x) == "table" then
			tab_x = tab_x.x
		end
		if tab_x and self.x < tab_x then
			self.x = tab_x
			self:clearKerningMemory()
		end

		self.tab_i = self.tab_i + 1
	end
end


function _mt_qp:setTabIndex(i)
	if type(i) ~= "number" then errType(1, i, "number") end

	-- does not check if a 'tabs' table is currently populated, or that the index has an entry
	self.tab_i = i
end


function _mt_qp:getTabIndex()
	local i = self.tab_i
	return (i == math.huge and false or i)
end


function _mt_qp:setPosition(x, y)
	if type(x) ~= "number" then errType(1, x, "number")
	elseif type(y) ~= "number" then errType(2, y, "number") end

	self.x, self.y = x, y

	self.tab_i = math.huge -- invalidate tab stop state
	self:clearKerningMemory()
end


function _mt_qp:setXPosition(x)
	if type(x) ~= "number" then errType(1, x, "number") end

	self.x = x

	self.tab_i = math.huge
	self:clearKerningMemory()
end


function _mt_qp:setYPosition(y)
	if type(y) ~= "number" then errType(1, y, "number") end

	self.y = y

	-- does not invalidate tab stop state
	-- does not clear kerning memory
end


function _mt_qp:getPosition()
	return self.x, self.y
end


function _mt_qp:getXPosition()
	return self.x
end


function _mt_qp:getYPosition()
	return self.y
end


function _mt_qp:movePosition(dx, dy)
	if type(dx) ~= "number" then errType(1, dx, "number")
	elseif type(dy) ~= "number" then errType(2, dy, "number") end

	self.x, self.y = self.x + dx, self.y + dy

	self.tab_i = math.huge
	self:clearKerningMemory()
end


function _mt_qp:moveXPosition(dx)
	if type(dx) ~= "number" then errType(1, dx, "number") end

	self.x = self.x + dx

	self.tab_i = math.huge
	self:clearKerningMemory()
end


function _mt_qp:moveYPosition(dy)
	if type(dy) ~= "number" then errType(1, dy, "number") end

	self.y = self.y + dy

	-- Does not invalidate tab stop state.
	-- Does not clear kerning memory.
end


function _mt_qp:setOrigin(origin_x, origin_y)
	if type(origin_x) ~= "number" then errType(1, origin_x, "number")
	elseif type(origin_y) ~= "number" then errType(2, origin_y, "number") end

	self.origin_x, self.origin_y = origin_x, origin_y
	self.x, self.y = 0, 0

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:setXOrigin(origin_x)
	if type(origin_x) ~= "number" then errType(1, origin_x, "number") end

	self.origin_x = origin_x
	self.x, self.y = 0, 0

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:setYOrigin(origin_y)
	if type(origin_y) ~= "number" then errType(1, origin_y, "number") end

	self.origin_y = origin_y
	self.x, self.y = 0, 0

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:getOrigin()
	return self.origin_x, self.origin_y
end


function _mt_qp:getXOrigin()
	return self.origin_x
end


function _mt_qp:getYOrigin()
	return self.origin_y
end


function _mt_qp:moveOrigin(dx, dy)
	if type(dx) ~= "number" then errType(1, dx, "number")
	elseif type(dy) ~= "number" then errType(2, dy, "number") end

	self.origin_x, self.origin_y = self.origin_x + dx, self.origin_y + dy
	self.x, self.y = 0, 0

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:setReferenceDimensions(ref_w, ref_h)
	if type(ref_w) ~= "number" then errType(1, ref_w, "number or nil") end
	if type(ref_h) ~= "number" then errType(2, ref_h, "number or nil") end

	self.ref_w, self.ref_h = ref_w, ref_h

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:getReferenceDimensions()
	return self.ref_w, self.ref_h
end


function _mt_qp:setReferenceWidth(ref_w)
	if type(ref_w) ~= "number" then errType(1, ref_w, "number") end

	self.ref_w = ref_w

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:getReferenceWidth()
	return self.ref_w
end


function _mt_qp:setReferenceHeight(ref_h)
	if type(ref_h) ~= "number" then errType(1, ref_h, "number") end

	self.ref_h = ref_h

	self.tab_i = 1
	self:clearKerningMemory()
end


function _mt_qp:getReferenceHeight()
	return self.ref_h
end


function _mt_qp:setScale(sx, sy)
	if type(sx) ~= "number" then errType(1, sx, "number")
	elseif type(sy) ~= "number" and sy ~= nil then errType(2, sy, "number or nil") end

	self.sx = sx
	self.sy = sy or sx
end


function _mt_qp:getScale()
	return self.sx, self.sy
end


function _mt_qp:setVerticalPadding(pad_v)
	if type(pad_v) ~= "number" then errType(1, pad_v, "number") end

	self.pad_v = pad_v
end


function _mt_qp:getVerticalPadding()
	return self.pad_v
end


function _mt_qp:reset()
	self.x, self.y = 0, 0

	self.tab_i = 1
	self:clearKerningMemory()
	self.align = self.default_align
	self.v_align = self.default_v_align
end


function _mt_qp:down(qty)
	if type(qty) ~= "number" and qty ~= nil then errType(1, pad_v, "number or nil") end

	qty = qty or 1

	if qty > 0 then
		local font = self:getFont()
		local aux = quickPrint.getAux(font)
		local scale_y = self.sy * aux.sy
		self.x = 0
		self.y = math.ceil(self.y + self.pad_v + (qty * (font:getHeight() * font:getLineHeight() * scale_y)))

		self.tab_i = 1
		self:clearKerningMemory()
	end
end


function _mt_qp:clearKerningMemory()
	self.last_glyph = false
	self.line_font = false
end


function _mt_qp:write(...)
	local font = self:getFont()
	local aux = quickPrint.getAux(font)

	for i = 1, select("#", ...) do
		plainWrite(self, tostring(select(i, ...)), font, aux)
	end
end


function _mt_qp:writeSeq(tbl)
	if type(tbl) ~= "table" then errType(1, tbl, "table") end

	local font = self:getFont()
	local aux = quickPrint.getAux(font)

	for i = 1, #tbl do
		plainWrite(self, tostring(tbl[i]), font, aux)
	end
end


function _mt_qp:print(...)
	self:clearKerningMemory()
	local font = self:getFont()
	local aux = quickPrint.getAux(font)

	for i = 1, select("#", ...) do
		plainWrite(self, tostring(select(i, ...)), font, aux)
	end

	self:down()
end


function _mt_qp:printSeq(tbl)
	if type(tbl) ~= "table" then errType(1, tbl, "table") end

	self:clearKerningMemory()
	local font = self:getFont()
	local aux = quickPrint.getAux(font)

	for i = 1, #tbl do
		plainWrite(self, tostring(tbl[i]), font, aux)
	end

	self:down()
end


function _mt_qp:writefSingle(text, align)
	if type(text) ~= "string" and type(text) ~= "table" then errType(1, text, "string or table")
	elseif align and not enum_align[align] then errEnumAlign(2, align) end

	local font = self:getFont()
	local aux = quickPrint.getAux(font)

	self:clearKerningMemory()
	self.x = 0

	-- collect tab stop info
	local tab_i
	local tab_t
	local tab_x
	if self.tabs then
		tab_i = self.tab_i
		tab_t = self.tabs[tab_i]
		tab_x = type(tab_t) == "number" and tab_t or nil
	end

	-- align priority: 1) function argument, 2) tab align, 3) self.align
	if type(tab_t) == "table" then
		align = align or tab_t.align
		tab_x = tab_t.x
	end

	align = align or self.align

	if tab_x then
		if align == "left" then
			self.x = math.floor(tab_x)

		elseif align == "center" then
			self.x = math.floor(tab_x - self.ref_w/2)

		elseif align == "right" then
			self.x = math.floor(tab_x - self.ref_w)
		end
	end

	formattedPrintLogic(self, text, align, font, aux, self.origin_x + self.x, self.origin_y + self.y)
	self:advanceTab()
end


function _mt_qp:printfSingle(text, align)
	if type(text) ~= "string" and type(text) ~= "table" then errType(1, text, "string or table")
	elseif align and not enum_align[align] then errEnumAlign(2, align) end

	-- tab stops are not taken into account
	align = align or self.align

	self:writefSingle(text, align)
	self:down()
end


function _mt_qp:printf(text, align)
	-- PERF NOTE: This function needs to make a temporary table to determine how far down to move the Y cursor.
	if type(text) ~= "string" and type(text) ~= "table" then errType(1, text, "string or table")
	elseif align and not enum_align[align] then errEnumAlign(2, align) end

	-- tab stops are not taken into account
	align = align or self.align
	local font = self:getFont()
	local aux = quickPrint.getAux(font)

	self:clearKerningMemory()
	self.x = 0
	formattedPrintLogic(self, text, align, font, aux, self.origin_x + self.x, self.origin_y + self.y)

	local scale_x = self.sx * aux.sx
	local scaled_w = math.ceil(self.ref_w / math.max(scale_x, 0.0000001)) -- avoid div/0
	local wid, wrap_t = font:getWrap(text, scaled_w)

	-- getWrap() accounts for '\n' embedded in strings, and it also handles coloredtext sequences
	self:down(#wrap_t)
end


return quickPrint
