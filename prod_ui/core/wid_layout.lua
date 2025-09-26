local context = select(1, ...)


local widLayout = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


local sash_styles = context.resources.sash_styles


widLayout._enum_layout_base = uiTable.makeLUTV(
	"zero",
	"self",
	"viewport",
	"viewport-width",
	"viewport-height",
	"unbounded"
)


widLayout._enum_seg_edge = uiTable.makeLUTV("left", "right", "top", "bottom")


--[[
	"grid":
		x: (integer) Tile position, from 0 to len - 1.
		y: ^
		w: (integer) Number of tiles the widget occupies.
		h: ^

	"null":
		(No parameters.)

	"remaining":
		(No paremeters.)

	"segment":
		edge: (_enum_seg_edge)
		len: (integer) The desired length of the segment. The final length may be reduced to make room for a sash.
		len_min: (integer) The preferred (not guaranteed) minimum and maximum segment length.
		len_max: ^
		sash_style (string|false/nil) When a string, this segment has a sash on the opposite edge.
		sash_x: (integer) Position and dimensions of the sash bounding box. Internal use.
		sash_y: ^
		sash_w: ^
		sash_h: ^

	"segment-unit":
		edge: (_enum_seg_edge)
		unit: (number) The desired portion of the segment, from 0.0 to 1.0. This is a percentage of the original
			parent layout space along the segment's axis.

	"static":
		x: (integer) Position and dimensions. Always scaled.
		y: ^
		w: ^
		h: ^
		relative: (boolean) Use parent node's remaining layout space (true) or the original space (false).
		flip_x: (boolean) When true, the position is against the other side of the layout space.
		flip_y: (boolean) ^
--]]


widLayout.geo_null = {mode="null"}
widLayout.geo_remaining = {mode="remaining"}


local function _initGE(self, mode)
	-- Do not call with the "null" or "remaining" modes.

	local GE = self.GE

	if GE and GE.mode == mode then
		return GE
	else
		GE = {mode=mode}
		self.GE = GE
		return GE
	end
end


widLayout.mode_setters = {
	grid = function(self, x, y, w, h)
		uiAssert.numberNotNaN(1, x)
		uiAssert.numberNotNaN(2, y)
		uiAssert.numberNotNaNEval(3, w)
		uiAssert.numberNotNaNEval(4, h)

		local GE = _initGE(self, "grid")

		GE.x = x
		GE.y = y
		GE.w = w and math.max(0, w) or 1
		GE.h = h and math.max(0, h) or 1

		return self
	end,

	null = function(self)
		self.GE = widLayout.geo_null

		return self
	end,

	remaining = function(self)
		self.GE = widLayout.geo_remaining

		return self
	end,

	segment = function(self, edge, len, sash_style, len_min, len_max)
		uiAssert.enum(1, edge, "edge", widLayout._enum_seg_edge)
		uiAssert.numberNotNaN(2, len)
		uiAssert.typeEval(3, sash_style, "string")
		uiAssert.numberNotNaNEval(4, len_min)
		uiAssert.numberNotNaNEval(5, len_max)

		local GE = _initGE(self, "segment")

		GE.edge = edge
		GE.len_min = len_min and math.max(0, len_min) or 0
		GE.len_max = len_max and math.max(0, len_max) or math.huge
		GE.len = math.max(GE.len_min, math.min(len, GE.len_max))
		GE.sash_style = sash_style or nil
		GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0 -- internal use

		return self
	end,

	["segment-unit"] = function(self, edge, unit)
		uiAssert.enum(1, edge, "edge", widLayout._enum_seg_edge)
		uiAssert.numberNotNaN(2, unit)

		local GE = _initGE(self, "segment-unit")

		GE.edge = edge
		GE.unit = math.max(0.0, math.min(unit, 1.0))

		return self
	end,

	static = function(self, x, y, w, h, relative, flip_x, flip_y)
		uiAssert.numberNotNaN(1, x)
		uiAssert.numberNotNaN(2, y)
		uiAssert.numberNotNaN(3, w)
		uiAssert.numberNotNaN(4, h)
		-- don't assert 'relative', 'flip_x' or 'flip_y'

		local GE = _initGE(self, "static")

		GE.x = x
		GE.y = y
		GE.w = math.max(0, w)
		GE.h = math.max(0, h)
		GE.relative = not not relative
		GE.flip_x = not not flip_x
		GE.flip_y = not not flip_y

		return self
	end
}


local function _calculateSegment(len, sash_half, layout_len, do_scale)
	layout_len = math.max(0, layout_len - sash_half*2)
	len = math.max(0, len - sash_half)
	local scale = do_scale and context.scale or 1.0
	local cut = math.floor(math.max(0, math.min(len * scale, layout_len)))
	return cut, layout_len - cut
end


local function _querySegmentLength(wid, GE, x_axis, cross_length)
	local a, b = wid:uiCall_getSegmentLength(x_axis, cross_length)
	if a then
		return a, b
	end
	return GE.len, true -- len, do_scale
end


local function _getSashBreadth(style_id)
	if style_id then
		local style = sash_styles[style_id]
		if not style then
			error("unprovisioned sash style: " .. style_id)
		end
		return style.breadth_half
	end
	return 0
end


function widLayout.getSashStyleTable(id)
	local style = sash_styles[id]
	if not style then
		error("unprovisioned sash style: " .. id)
	end
	return style
end


local function _calculateSegmentUnit(unit, layout_len, original_layout_len)
	unit = math.max(0, math.min(unit, 1))
	local cut = math.floor(unit * original_layout_len)
	return cut, layout_len - cut
end


widLayout.handlers = {
	-- arguments: np (parent), nc (child, to be resized), GE (child's geometry table), orig_x, orig_y, orig_w, orig_h
	grid = function(np, nc, GE)
		if np.LO_grid_rows > 0 and np.LO_grid_cols > 0 then
			nc.x = np.LO_x + math.floor(GE.x * np.LO_w / np.LO_grid_rows)
			nc.y = np.LO_y + math.floor(GE.y * np.LO_h / np.LO_grid_cols)
			nc.w = math.floor(np.LO_w / np.LO_grid_rows * GE.w)
			nc.h = math.floor(np.LO_h / np.LO_grid_cols * GE.h)
		else
			nc.x, nc.y, nc.w, nc.h = 0, 0, 0, 0
		end
	end,

	null = function()
		-- do nothing
	end,

	remaining = function(np, nc)
		nc.x, nc.y, nc.w, nc.h = np.LO_x, np.LO_y, np.LO_w, np.LO_h
	end,

	segment = function(np, nc, GE)
		local edge, sash_style = GE.edge, GE.sash_style
		local sash_half = _getSashBreadth(sash_style)
		-- NOTE: the sash box is placed on the opposite side of 'edge'.

		if edge == "left" then
			nc.y, nc.h = np.LO_y, np.LO_h
			local len, do_scale = _querySegmentLength(nc, GE, true, nc.h)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			nc.w, np.LO_w = _calculateSegment(len, sash_half, np.LO_w, do_scale)
			nc.x = np.LO_x
			np.LO_x = np.LO_x + nc.w + sash_half*2
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = nc.w, 0, sash_half*2, nc.h
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		elseif edge == "right" then
			nc.y, nc.h = np.LO_y, np.LO_h
			local len, do_scale = _querySegmentLength(nc, GE, true, nc.h)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			local old_LO_w = np.LO_w
			nc.w, np.LO_w = _calculateSegment(len, sash_half, np.LO_w, do_scale)
			nc.x = np.LO_x + old_LO_w - nc.w
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = -sash_half*2, 0, sash_half*2, nc.h
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		elseif edge == "top" then
			nc.x, nc.w = np.LO_x, np.LO_w
			local len, do_scale = _querySegmentLength(nc, GE, false, nc.w)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			nc.h, np.LO_h = _calculateSegment(len, sash_half, np.LO_h, do_scale)
			nc.y = np.LO_y
			np.LO_y = np.LO_y + nc.h + sash_half*2
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, nc.h, nc.w, sash_half * 2
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		elseif edge == "bottom" then
			nc.x, nc.w = np.LO_x, np.LO_w
			local len, do_scale = _querySegmentLength(nc, GE, false, nc.w)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			local old_LO_h = np.LO_h
			nc.h, np.LO_h = _calculateSegment(len, sash_half, np.LO_h, do_scale)
			nc.y = np.LO_y + old_LO_h - nc.h
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, -sash_half*2, nc.w, sash_half*2
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		else
			error("bad segment edge ID")
		end
	end,

	["segment-unit"] = function(np, nc, GE, orig_x, orig_y, orig_w, orig_h)
		local edge = GE.edge

		if edge == "left" then
			nc.y, nc.h = np.LO_y, np.LO_h
			nc.w, np.LO_w = _calculateSegmentUnit(GE.unit, np.LO_w, orig_w)
			nc.x = np.LO_x
			np.LO_x = np.LO_x + nc.w

		elseif edge == "right" then
			nc.y, nc.h = np.LO_y, np.LO_h
			nc.w, np.LO_w = _calculateSegmentUnit(GE.unit, np.LO_w, orig_w)
			nc.x = np.LO_x + np.LO_w

		elseif edge == "top" then
			nc.x, nc.w = np.LO_x, np.LO_w
			nc.h, np.LO_h = _calculateSegmentUnit(GE.unit, np.LO_h, orig_h)
			nc.y = np.LO_y
			np.LO_y = np.LO_y + nc.h

		elseif edge == "bottom" then
			nc.x, nc.w = np.LO_x, np.LO_w
			nc.h, np.LO_h = _calculateSegmentUnit(GE.unit, np.LO_h, orig_h)
			nc.y = np.LO_y + np.LO_h

		else
			error("bad segment edge ID")
		end
	end,

	static = function(np, nc, GE, orig_x, orig_y, orig_w, orig_h)
		local scale = context.scale

		local px, py, pw, ph
		if GE.relative then
			px, py, pw, ph = np.LO_x, np.LO_y, np.LO_w, np.LO_h
		else
			px, py, pw, ph = orig_x, orig_y, orig_w, orig_h
		end

		nc.w = math.floor(GE.w * scale)
		nc.x = math.floor(GE.x * scale)
		if GE.flip_x then
			nc.x = pw - nc.w - nc.x
		end
		nc.x = nc.x + px

		nc.h = math.floor(GE.h * scale)
		nc.y = math.floor(GE.y * scale)
		if GE.flip_y then
			nc.y = ph - nc.h - nc.y
		end
		nc.y = nc.y + py
	end,
}


local function _layoutSetBase(self, layout_base)
	uiAssert.enum(1, layout_base, "LayoutBase", widLayout._enum_layout_base)

	self.LO_base = layout_base
end


local function _layoutGetBase(self)
	return self.LO_base
end


local function _layoutSetGridDimensions(self, rows, cols)
	uiAssert.numberNotNaN(1, rows)
	uiAssert.numberNotNaN(2, cols)

	self.LO_grid_rows = rows
	self.LO_grid_cols = cols

	return self
end


local function _layoutGetGridDimensions(self, rows, cols)
	return self.LO_grid_rows, self.LO_grid_cols
end


local function _layoutSetMargin(self, x1, y1, x2, y2)
	uiAssert.numberNotNaN(1, x1)

	if y1 then
		uiAssert.numberNotNaN(2, y1)
		uiAssert.numberNotNaN(3, x2)
		uiAssert.numberNotNaN(4, y2)

		self.LO_margin_x1 = math.max(0, x1)
		self.LO_margin_y1 = math.max(0, y1)
		self.LO_margin_x2 = math.max(0, x2)
		self.LO_margin_y2 = math.max(0, y2)
	else
		self.LO_margin_x1 = math.max(0, x1)
		self.LO_margin_y1 = math.max(0, x1)
		self.LO_margin_x2 = math.max(0, x1)
		self.LO_margin_y2 = math.max(0, x1)
	end

	return self
end


local function _layoutGetMargin(self)
	return self.LO_margin_x1, self.LO_margin_y1, self.LO_margin_x2, self.LO_margin_y2
end


local function _hof_sortLayoutList(a, b)
	return a.GE_order < b.GE_order
end


local function _layoutSort(self)
	table.sort(self.LO_list, _hof_sortLayoutList)
end


function widLayout.setupContainerDef(def)
	def.layoutSetBase = _layoutSetBase
	def.layoutGetBase = _layoutGetBase
	def.layoutSetGridDimensions = _layoutSetGridDimensions
	def.layoutGetGridDimensions = _layoutGetGridDimensions
	def.layoutSetMargin = _layoutSetMargin
	def.layoutGetMargin = _layoutGetMargin
	def.layoutSort = _layoutSort
end


function widLayout.setupLayoutList(self)
	self.LO_list = {}
	self.LO_base = "self"
	self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, 0, 0
	self.LO_margin_x1, self.LO_margin_y1, self.LO_margin_x2, self.LO_margin_y2 = 0, 0, 0, 0
	self.LO_grid_rows, self.LO_grid_cols = 0, 0 -- grid layout mode
end


function widLayout.resetLayoutSpace(self)
	local to = self.LO_base

	if to == "zero" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, 0, 0

	elseif to == "self" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, self.w, self.h

	elseif to == "viewport" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, self.vp_w, self.vp_h

	elseif to == "viewport-full" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = self.vp_x, self.vp_y, self.vp_w, self.vp_h

	elseif to == "viewport-width" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, self.vp_w, math.huge

	elseif to == "viewport-height" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, math.huge, self.vp_h

	elseif to == "unbounded" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, math.huge, math.huge

	else
		error("invalid layout base mode.")
	end
end


function widLayout.applyLayout(self)
	-- check 'self.LO_list' before calling.

	--print("widLayout.applyLayout(): start")

	local scale = context.scale

	-- Margin reduction
	local mx1 = math.floor(self.LO_margin_x1 * scale)
	local my1 = math.floor(self.LO_margin_y1 * scale)
	local mx2 = math.floor(self.LO_margin_x2 * scale)
	local my2 = math.floor(self.LO_margin_y2 * scale)

	self.LO_x = self.LO_x + mx1
	self.LO_y = self.LO_y + my1
	self.LO_w = math.max(0, self.LO_w - mx1 - mx2)
	self.LO_h = math.max(0, self.LO_h - my1 - my2)

	local orig_x, orig_y, orig_w, orig_h = self.LO_x, self.LO_y, self.LO_w, self.LO_h

	for i, child in ipairs(self.LO_list) do
		local GE = child.GE
		local handler = widLayout.handlers[GE.mode]
		if not handler then
			error("invalid or missing layout handler: " .. tostring(GE.mode))
		end

		--print("old self XYWH", self.x, self.y, self.w, self.h)
		handler(self, child, GE, orig_x, orig_y, orig_w, orig_h)
		--print("new self XYWH", self.x, self.y, self.w, self.h)

		-- Outpad reduction
		local ox1 = math.floor(child.GE_outpad_x1 * scale)
		local oy1 = math.floor(child.GE_outpad_y1 * scale)
		local ox2 = math.floor(child.GE_outpad_x2 * scale)
		local oy2 = math.floor(child.GE_outpad_y2 * scale)

		child.x = child.x + ox1
		child.y = child.y + oy1
		child.w = math.max(0, child.w - ox1 - ox2)
		child.h = math.max(0, child.h - oy1 - oy2)
	end

	--print("_applyLayout(): end")
end


return widLayout
