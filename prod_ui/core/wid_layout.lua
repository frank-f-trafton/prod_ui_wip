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
	GE_a grid_x: (integer) Tile position, from 0 to len - 1.
	GE_b grid_y: ^
	GE_c grid_w: (integer) Number of tiles the widget occupies.
	GE_d grid_h: ^

	"null":
	No parameters used.

	"remaining":
	No paremeters used.

	"segment":
	GE_a seg_edge: (_enum_seg_edge)
	GE_b seg_amount: (number) An integer >= 0
	GE_c seg_sash (string|false/nil) When a string, this segment has a sash on the opposite edge. The
		string represents the sash style to use.
	GE_d sash_x (integer) Position and dimensions of the sash bounding box. Internal use.
	GE_e sash_y ^
	GE_f sash_w ^
	GE_g sash_h ^

	"segment-unit":
	GE_a seg_edge: (_enum_seg_edge)
	GE_b seg_amount: (number) A number between 0.0 and 1.0.
	GE_c seg_sash (string|false/nil) When a string, this segment has a sash on the opposite edge. The
		string represents the sash style to use.

	"static":
	GE_a static_x: (integer) Position and dimensions. Always scaled.
	GE_b static_y: ^
	GE_c static_w: ^
	GE_d static_h: ^
	GE_e static_rel: (boolean) Use parent node's remaining layout space (true) or the original space (false).
	GE_f static_flip_x: (boolean) When true, the position is against the other side of the layout space.
	GE_g static_flip_y: (boolean)
--]]


widLayout.mode_setters = {
	grid = function(self, grid_x, grid_y, grid_w, grid_h)
		uiAssert.numberNotNaN(1, grid_x)
		uiAssert.numberNotNaN(2, grid_y)
		grid_w = grid_w or 1
		uiAssert.numberNotNaN(3, grid_w)
		grid_h = grid_h or 1
		uiAssert.numberNotNaN(4, grid_h)

		self.GE_mode = "grid"
		self.GE_a = grid_x
		self.GE_b = grid_y
		self.GE_c = grid_w
		self.GE_d = grid_h

		self.GE_e, self.GE_f, self.GE_g = nil

		return self
	end,

	null = function(self)
		self.GE_mode = "null"

		self.GE_a, self.GE_b, self.GE_c, self.GE_d, self.GE_e, self.GE_f, self.GE_g = nil

		return self
	end,

	remaining = function(self)
		self.GE_mode = "remaining"

		self.GE_a, self.GE_b, self.GE_c, self.GE_d, self.GE_e, self.GE_f, self.GE_g = nil

		return self
	end,

	segment = function(self, seg_edge, seg_amount, seg_sash)
		uiAssert.enum(1, seg_edge, "seg_edge", widLayout._enum_seg_edge)
		uiAssert.numberNotNaN(2, seg_amount)
		uiAssert.typeEval(3, seg_sash, "string")

		self.GE_mode = "segment"
		self.GE_a = seg_edge
		self.GE_b = math.max(0, seg_amount)
		self.GE_c = seg_sash or nil

		self.GE_d, self.GE_e, self.GE_f, self.GE_g = 0, 0, 0, 0 -- internal use

		return self
	end,

	["segment-unit"] = function(self, seg_edge, seg_amount, seg_sash)
		uiAssert.enum(1, seg_edge, "seg_edge", widLayout._enum_seg_edge)
		uiAssert.numberNotNaN(2, seg_amount)
		uiAssert.typeEval(3, seg_sash, "string")

		self.GE_mode = "segment-unit"
		self.GE_a = seg_edge
		self.GE_b = math.max(0, math.min(seg_amount, 1))
		self.GE_c = seg_sash or nil

		self.GE_d, self.GE_e, self.GE_f, self.GE_g = nil

		return self
	end,

	static = function(self, static_x, static_y, static_w, static_h, static_rel, static_flip_x, static_flip_y)
		uiAssert.numberNotNaN(1, static_x)
		uiAssert.numberNotNaN(2, static_y)
		uiAssert.numberNotNaN(3, static_w)
		uiAssert.numberNotNaN(4, static_h)
		-- don't assert 'static_rel', 'static_flip_x' or 'static_flip_y'

		self.GE_mode = "static"

		self.GE_a = static_x
		self.GE_b = static_y
		self.GE_c = math.max(0, static_w)
		self.GE_d = math.max(0, static_h)

		self.GE_e = not not static_rel
		self.GE_f = not not static_flip_x
		self.GE_g = not not static_flip_y

		return self
	end
}


local function _calculateSegment(amount, sash_half, length, do_scale)
	local length = math.max(0, length - sash_half*2)
	amount = math.max(0, amount - sash_half)
	local scale = do_scale and context.scale or 1.0
	local cut = math.floor(math.max(0, math.min(amount * scale, length)))
	return cut, length - cut
end


local function _calculateSegmentUnit(amount, sash_half, length, orig_length)
	local norm_sash_half = sash_half > 0 and (1 / sash_half) or 0
	local cut = math.floor(orig_length * math.max(0, math.min(amount, 1 - norm_sash_half)))
	return cut, length - cut
end


local function _querySegmentLength(wid, x_axis, cross_length) -- pixel segments only.
	local a, b = wid:uiCall_getSegmentLength(x_axis, cross_length)
	if a then
		return a, b
	end
	return wid.GE_b, true -- seg_amount, do_scale
end


local function _getSashBreadth(seg_sash)
	if seg_sash then
		local sash_style = sash_styles[seg_sash]
		if not sash_style then
			error("unprovisioned sash style: " .. seg_sash)
		end
		return sash_style.breadth_half
	end
	return 0
end


function widLayout.getSashStyleTable(id)
	local sash_style = sash_styles[id]
	if not sash_style then
		error("unprovisioned sash style: " .. id)
	end
	return sash_style
end


widLayout.handlers = {
	grid = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		local grid_x, grid_y, grid_w, grid_h = nc.GE_a, nc.GE_b, nc.GE_c, nc.GE_d

		if np.lo_grid_rows > 0 and np.lo_grid_cols > 0 then
			nc.x = np.lo_x + math.floor(grid_x * np.lo_w / np.lo_grid_rows)
			nc.y = np.lo_y + math.floor(grid_y * np.lo_h / np.lo_grid_cols)
			nc.w = math.floor(np.lo_w / np.lo_grid_rows * grid_w)
			nc.h = math.floor(np.lo_h / np.lo_grid_cols * grid_h)
		else
			nc.x, nc.y, nc.w, nc.h = 0, 0, 0, 0
		end
	end,

	null = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		-- Do nothing.
	end,

	remaining = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		nc.x, nc.y, nc.w, nc.h = np.lo_x, np.lo_y, np.lo_w, np.lo_h
	end,

	segment = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		local seg_edge, seg_sash = nc.GE_a, nc.GE_c
		local sash_half = _getSashBreadth(seg_sash)
		-- GE_d, GE_e, GE_f, GE_g == sash bounding box (XYWH)
		-- NOTE: the sash box is placed on the opposite side of 'seg_edge'.

		if seg_edge == "left" then
			nc.y, nc.h = np.lo_y, np.lo_h
			local amount, do_scale = _querySegmentLength(nc, true, nc.h)
			nc.w, np.lo_w = _calculateSegment(amount, sash_half, np.lo_w, do_scale)
			nc.x = np.lo_x
			np.lo_x = np.lo_x + nc.w + sash_half*2
			if seg_sash then
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = nc.w, 0, sash_half*2, nc.h
			else
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = 0, 0, 0, 0
			end

		elseif seg_edge == "right" then
			nc.y, nc.h = np.lo_y, np.lo_h
			local amount, do_scale = _querySegmentLength(nc, true, nc.h)
			local old_lo_w = np.lo_w
			nc.w, np.lo_w = _calculateSegment(amount, sash_half, np.lo_w, do_scale)
			nc.x = np.lo_x + old_lo_w - nc.w
			if seg_sash then
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = -sash_half*2, 0, sash_half*2, nc.h
			else
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = 0, 0, 0, 0
			end

		elseif seg_edge == "top" then
			nc.x, nc.w = np.lo_x, np.lo_w
			local amount, do_scale = _querySegmentLength(nc, false, nc.w)
			nc.h, np.lo_h = _calculateSegment(amount, sash_half, np.lo_h, do_scale)
			nc.y = np.lo_y
			np.lo_y = np.lo_y + nc.h + sash_half*2
			if seg_sash then
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = 0, nc.h, nc.w, sash_half * 2
			else
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = 0, 0, 0, 0
			end

		elseif seg_edge == "bottom" then
			nc.x, nc.w = np.lo_x, np.lo_w
			local amount, do_scale = _querySegmentLength(nc, false, nc.w)
			local old_lo_h = np.lo_h
			nc.h, np.lo_h = _calculateSegment(amount, sash_half, np.lo_h, do_scale)
			nc.y = np.lo_y + old_lo_h - nc.h
			if seg_sash then
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = 0, -sash_half*2, nc.w, sash_half*2
			else
				nc.GE_d, nc.GE_e, nc.GE_f, nc.GE_g = 0, 0, 0, 0
			end

		else
			error("bad segment edge ID")
		end
	end,

	["segment-unit"] = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		local seg_edge, seg_amount, seg_sash = nc.GE_a, nc.GE_b, nc.GE_c
		local sash_half = _getSashBreadth(seg_sash)

		if seg_edge == "left" then
			nc.y, nc.h = np.lo_y, np.lo_h
			nc.w, np.lo_w = _calculateSegmentUnit(seg_amount, sash_half, np.lo_w, orig_w)
			nc.x = np.lo_x
			np.lo_x = np.lo_x + nc.w

		elseif seg_edge == "right" then
			nc.y, nc.h = np.lo_y, np.lo_h
			nc.w, np.lo_w = _calculateSegmentUnit(seg_amount, sash_half, np.lo_w, orig_w)
			nc.x = np.lo_x + np.lo_w

		elseif seg_edge == "top" then
			nc.x, nc.w = np.lo_x, np.lo_w
			nc.h, np.lo_h = _calculateSegmentUnit(seg_amount, sash_half, np.lo_h, orig_h)
			nc.y = np.lo_y
			np.lo_y = np.lo_y + nc.h

		elseif seg_edge == "bottom" then
			nc.x, nc.w = np.lo_x, np.lo_w
			nc.h, np.lo_h = _calculateSegmentUnit(seg_amount, sash_half, np.lo_h, orig_h)
			nc.y = np.lo_y + np.lo_h

		else
			error("bad segment edge ID")
		end
	end,

	static = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		local scale = context.scale
		local static_x, static_y, static_w, static_h = nc.GE_a, nc.GE_b, nc.GE_c, nc.GE_d
		local static_rel, static_flip_x, static_flip_y = nc.GE_e, nc.GE_f, nc.GE_g

		local px, py, pw, ph
		if static_rel then
			px, py, pw, ph = np.lo_x, np.lo_y, np.lo_w, np.lo_h
		else
			px, py, pw, ph = orig_x, orig_y, orig_w, orig_h
		end

		nc.w = math.floor(static_w * scale)
		nc.x = math.floor(static_x * scale)
		if static_flip_x then
			nc.x = pw - nc.w - nc.x
		end
		nc.x = nc.x + px

		nc.h = math.floor(static_h * scale)
		nc.y = math.floor(static_y * scale)
		if static_flip_y then
			nc.y = ph - nc.h - nc.y
		end
		nc.y = nc.y + py
	end,
}


local function _layoutSetBase(self, layout_base)
	uiAssert.enum(1, layout_base, "LayoutBase", widLayout._enum_layout_base)

	self.lo_base = layout_base
end


local function _layoutGetBase(self)
	return self.lo_base
end


local function _layoutSetGridDimensions(self, rows, cols)
	uiAssert.numberNotNaN(1, rows)
	uiAssert.numberNotNaN(2, cols)

	self.lo_grid_rows = rows
	self.lo_grid_cols = cols

	return self
end


local function _layoutGetGridDimensions(self, rows, cols)
	return self.lo_grid_rows, self.lo_grid_cols
end


local function _layoutSetMargin(self, x1, y1, x2, y2)
	uiAssert.numberNotNaN(1, x1)

	if y1 then
		uiAssert.numberNotNaN(2, y1)
		uiAssert.numberNotNaN(3, x2)
		uiAssert.numberNotNaN(4, y2)

		self.lo_margin_x1 = math.max(0, x1)
		self.lo_margin_y1 = math.max(0, y1)
		self.lo_margin_x2 = math.max(0, x2)
		self.lo_margin_y2 = math.max(0, y2)
	else
		self.lo_margin_x1 = math.max(0, x1)
		self.lo_margin_y1 = math.max(0, x1)
		self.lo_margin_x2 = math.max(0, x1)
		self.lo_margin_y2 = math.max(0, x1)
	end

	return self
end


local function _layoutGetMargin(self)
	return self.lo_margin_x1, self.lo_margin_y1, self.lo_margin_x2, self.lo_margin_y2
end


local function _hof_sortLayoutList(a, b)
	return a.GE_order < b.GE_order
end


local function _layoutSort(self)
	table.sort(self.lo_list, _hof_sortLayoutList)
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
	self.lo_list = {}
	self.lo_base = "self"
	self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, 0, 0
	self.lo_margin_x1, self.lo_margin_y1, self.lo_margin_x2, self.lo_margin_y2 = 0, 0, 0, 0
	self.lo_grid_rows, self.lo_grid_cols = 0, 0 -- grid layout mode
end


function widLayout.resetLayoutSpace(self)
	local to = self.lo_base

	if to == "zero" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, 0, 0

	elseif to == "self" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, self.w, self.h

	elseif to == "viewport" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, self.vp_w, self.vp_h

	elseif to == "viewport-full" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = self.vp_x, self.vp_y, self.vp_w, self.vp_h

	elseif to == "viewport-width" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, self.vp_w, math.huge

	elseif to == "viewport-height" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, math.huge, self.vp_h

	elseif to == "unbounded" then
		self.lo_x, self.lo_y, self.lo_w, self.lo_h = 0, 0, math.huge, math.huge

	else
		error("invalid layout base mode.")
	end
end


function widLayout.applyLayout(self, _depth)
	-- check 'self.lo_list' before calling.

	--print("_applyLayout() " .. _depth .. ": start")

	local scale = context.scale

	-- Margin reduction
	local mx1 = math.floor(self.lo_margin_x1 * scale)
	local my1 = math.floor(self.lo_margin_y1 * scale)
	local mx2 = math.floor(self.lo_margin_x2 * scale)
	local my2 = math.floor(self.lo_margin_y2 * scale)

	self.lo_x = self.lo_x + mx1
	self.lo_y = self.lo_y + my1
	self.lo_w = math.max(0, self.lo_w - mx1 - mx2)
	self.lo_h = math.max(0, self.lo_h - my1 - my2)

	local orig_x, orig_y, orig_w, orig_h = self.lo_x, self.lo_y, self.lo_w, self.lo_h

	for i, child in ipairs(self.lo_list) do
		local handler = widLayout.handlers[child.GE_mode]
		if not handler then
			error("invalid or missing layout handler: " .. tostring(child.GE_mode))
		end

		--print("old self XYWH", self.x, self.y, self.w, self.h)
		handler(self, child, orig_x, orig_y, orig_w, orig_h)
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

	--print("_applyLayout() " .. _depth .. ": end")
end


return widLayout
