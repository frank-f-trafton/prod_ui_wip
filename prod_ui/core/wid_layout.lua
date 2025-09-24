local context = select(1, ...)


local widLayout = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


widLayout._enum_layout_base = uiTable.makeLUTV(
	"zero",
	"self",
	"viewport",
	"viewport-width",
	"viewport-height",
	"unbounded"
)

-- "px": pixels
-- "unit": value from 0.0 - 1.0, representing a portion of the original parent area before any segments
-- were assigned at this level.
widLayout._enum_seg_mode = uiTable.makeLUTV("px", "unit")

widLayout._enum_seg_edge = uiTable.makeLUTV("left", "right", "top", "bottom")


--[[
	"grid":
	ge_a grid_x: (integer) Tile position, from 0 to len - 1.
	ge_b grid_y: (integer)
	ge_c grid_w: (integer) Number of tiles the widget occupies.
	ge_d grid_h: (integer)

	"null":
	No parameters used.

	"remaining":
	No paremeters used.

	"segment":
	ge_a seg_mode: (_enum_seg_mode)
	ge_b seg_edge: (_enum_seg_edge)
	ge_c seg_amount: (number) an integer >= 0 for "px" seg_mode, 0-1 for "unit" seg_mode.
	ge_d seg_scale: (boolean) When true and seg_mode is "px", seg_amount is scaled.
		Not used with "unit" seg_mode. Pixel segments should be scaled in most cases, except when
		direct measurements of already-scaled entities are used to determine the segment length.
	ge_e seg_sash: (boolean) When true, supported containers provide a sash sensor for resizing the
		widget. The sash appears on the opposite side of 'seg_edge', and it is expected that the
		sashed side will be facing a "remaining" widget. Part of the widget segment and the
		remaining layout space are subtracted to make room for the sash sensor.
	ge_f seg_sash_half: (number >= 0) half the width of tall sashes; half the height of wide sashes.

	"static":
	ge_a static_x: (integer) Position and dimensions. Always scaled.
	ge_b static_y: (integer)
	ge_c static_w: (integer)
	ge_d static_h: (integer)
	ge_e static_rel: (boolean) Use parent node's remaining layout space (true) or the original space (false).
	ge_f static_flip_x: (boolean) When true, the position is against the other side of the layout space.
	ge_g static_flip_y: (boolean)
--]]


widLayout.mode_setters = {
	grid = function(self, grid_x, grid_y, grid_w, grid_h)
		uiAssert.numberNotNaN(1, grid_x)
		uiAssert.numberNotNaN(2, grid_y)
		grid_w = grid_w or 1
		uiAssert.numberNotNaN(3, grid_w)
		grid_h = grid_h or 1
		uiAssert.numberNotNaN(4, grid_h)

		self.ge_mode = "grid"
		self.ge_a = grid_x
		self.ge_b = grid_y
		self.ge_c = grid_w
		self.ge_d = grid_h

		self.ge_e, self.ge_f, self.ge_g = nil

		return self
	end,

	null = function(self)
		self.ge_mode = "null"

		self.ge_a, self.ge_b, self.ge_c, self.ge_d, self.ge_e, self.ge_f, self.ge_g = nil

		return self
	end,

	remaining = function(self)
		self.ge_mode = "remaining"

		self.ge_a, self.ge_b, self.ge_c, self.ge_d, self.ge_e, self.ge_f, self.ge_g = nil

		return self
	end,

	segment = function(self, seg_mode, seg_edge, seg_amount, seg_scale, seg_sash, seg_sash_half)
		uiAssert.enum(1, seg_mode, "seg_mode", widLayout._enum_seg_mode)
		uiAssert.enum(2, seg_edge, "seg_edge", widLayout._enum_seg_edge)
		uiAssert.numberNotNaN(3, seg_amount)
		-- don't assert 'seg_scale' or 'seg_sash'
		if seg_sash then
			uiAssert.numberNotNaN(6, seg_sash_half)
		end

		self.ge_mode = "segment"
		self.ge_a = seg_mode
		self.ge_b = seg_edge
		self.ge_c = seg_mode == "px" and math.floor(math.max(0, seg_amount)) or math.max(0, math.min(seg_amount, 1))
		self.ge_d = not not seg_scale
		self.ge_e = not not seg_sash
		self.ge_f = seg_sash and math.max(0, seg_sash_half) or 0

		self.ge_g = nil

		return self
	end,

	static = function(self, static_x, static_y, static_w, static_h, static_rel, static_flip_x, static_flip_y)
		uiAssert.numberNotNaN(1, static_x)
		uiAssert.numberNotNaN(2, static_y)
		uiAssert.numberNotNaN(3, static_w)
		uiAssert.numberNotNaN(4, static_h)
		-- don't assert 'static_rel', 'static_flip_x' or 'static_flip_y'

		self.ge_mode = "static"

		self.ge_a = static_x
		self.ge_b = static_y
		self.ge_c = math.max(0, static_w)
		self.ge_d = math.max(0, static_h)

		self.ge_e = not not static_rel
		self.ge_f = not not static_flip_x
		self.ge_g = not not static_flip_y

		return self
	end
}


local function _calculateSegment(mode, amount, do_scale, sash_half, length, orig_length)
	-- 'sash_half' should be scaled.

	--print("mode", mode, "amount", amount, "do_scale", do_scale, "sash_half", sash_half, "length", length, "orig_length", orig_length)
	local cut
	if mode == "px" then
		local scale = do_scale and context.scale or 1.0
		cut = math.floor(math.max(0, math.min(amount * scale, length) - sash_half))

	elseif mode == "unit" then
		local norm_sash_half = sash_half > 0 and (1 / sash_half) or 0
		cut = math.floor(orig_length * math.max(0, math.min(amount, 1 - norm_sash_half)))

	else
		error("invalid 'seg_mode' enum.")
	end

	print("cut", cut, "length - cut", length - cut)

	return cut, length - cut
end


local function _querySegmentLength(wid, x_axis, cross_length)
	local a, b = wid:uiCall_getSegmentLength(x_axis, cross_length)
	if a then
		return a, b
	end
	return wid.ge_c, wid.ge_d -- seg_amount, seg_scale
end


widLayout.handlers = {
	grid = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		local grid_x, grid_y, grid_w, grid_h = nc.ge_a, nc.ge_b, nc.ge_c, nc.ge_d

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
		local seg_mode, seg_edge, seg_sash_half = nc.ge_a, nc.ge_b, nc.ge_f

		if seg_edge == "left" then
			nc.y = np.lo_y
			nc.h = np.lo_h
			local amount, do_scale = _querySegmentLength(nc, true, nc.h)
			nc.w, np.lo_w = _calculateSegment(seg_mode, amount, do_scale, seg_sash_half, np.lo_w, orig_w)
			nc.x = np.lo_x
			np.lo_x = np.lo_x + nc.w

		elseif seg_edge == "right" then
			nc.y = np.lo_y
			nc.h = np.lo_h
			local amount, do_scale = _querySegmentLength(nc, true, nc.h)
			nc.w, np.lo_w = _calculateSegment(seg_mode, amount, do_scale, seg_sash_half, np.lo_w, orig_w)
			nc.x = np.lo_x + np.lo_w

		elseif seg_edge == "top" then
			nc.x = np.lo_x
			nc.w = np.lo_w
			local amount, do_scale = _querySegmentLength(nc, false, nc.w)
			nc.h, np.lo_h = _calculateSegment(seg_mode, amount, do_scale, seg_sash_half, np.lo_h, orig_h)
			nc.y = np.lo_y
			np.lo_y = np.lo_y + nc.h

		elseif seg_edge == "bottom" then
			nc.x = np.lo_x
			nc.w = np.lo_w
			local amount, do_scale = _querySegmentLength(nc, false, nc.w)
			nc.h, np.lo_h = _calculateSegment(seg_mode, amount, do_scale, seg_sash_half, np.lo_h, orig_h)
			nc.y = np.lo_y + np.lo_h

		else
			error("bad segment edge enum.")
		end
	end,

	static = function(np, nc, orig_x, orig_y, orig_w, orig_h)
		local scale = context.scale
		local static_x, static_y, static_w, static_h = nc.ge_a, nc.ge_b, nc.ge_c, nc.ge_d
		local static_rel, static_flip_x, static_flip_y = nc.ge_e, nc.ge_f, nc.ge_g

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
	return a.ge_order < b.ge_order
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
	--print(n, "#nodes:", n and n.nodes and (#n.nodes))

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
		local handler = widLayout.handlers[child.ge_mode]
		if not handler then
			error("invalid or missing layout handler: " .. tostring(child.ge_mode))
		end

		--print("old self XYWH", self.x, self.y, self.w, self.h)
		handler(self, child, orig_x, orig_y, orig_w, orig_h)
		--print("new self XYWH", self.x, self.y, self.w, self.h)

		-- Outpad reduction
		local ox1 = math.floor(child.ge_outpad_x1 * scale)
		local oy1 = math.floor(child.ge_outpad_y1 * scale)
		local ox2 = math.floor(child.ge_outpad_x2 * scale)
		local oy2 = math.floor(child.ge_outpad_y2 * scale)

		child.x = child.x + ox1
		child.y = child.y + oy1
		child.w = math.max(0, child.w - ox1 - ox2)
		child.h = math.max(0, child.h - oy1 - oy2)
	end

	--print("_applyLayout() " .. _depth .. ": end")
end


return widLayout
