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
-- "unit": value from 0.0 - 1.0, representing a portion of the original parent area before any slices
-- were taken off at this level.
widLayout._enum_slice_mode = uiTable.makeLUTV("px", "unit")

widLayout._enum_slice_edge = uiTable.makeLUTV("left", "right", "top", "bottom")


--[[
	"grid":
	ge_a grid_x: (integer) Tile position, for children. From 0 to len - 1.
	ge_b grid_y: (integer)
	ge_c grid_w: (integer) Number of tiles the child occupies (for more granular positioning)
	ge_d grid_h: (integer)

	"null":
	No parameters used.

	"remaining":
	No paremeters used.

	"slice":
	ge_a slice_mode: (_enum_slice_mode)
	ge_b slice_edge: (_enum_slice_edge)
	ge_c slice_amount: (number) 0-1 for "unit" slice_mode, an integer for "px" slice_mode.
	ge_d slice_scale: (boolean) -- scales "px" values when true.
	ge_e slice_is_sash: (boolean) Used by the divider container to mark nodes as draggable bars.

	"static":
	ge_a static_x: (integer) Position and dimensions.
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

	slice = function(self, slice_mode, slice_edge, slice_amount, slice_scale, slice_is_sash)
		uiAssert.enum(1, slice_mode, "slice_mode", widLayout._enum_slice_mode)
		uiAssert.enum(2, slice_edge, "slice_edge", widLayout._enum_slice_edge)
		uiAssert.numberNotNaN(3, slice_amount)
		-- don't assert 'slice_scale' and 'slice_is_sash'

		self.ge_mode = "slice"
		self.ge_a = slice_mode
		self.ge_b = slice_edge
		self.ge_c = slice_amount
		self.ge_d = not not slice_scale
		self.ge_e = not not slice_is_sash

		self.ge_f, self.ge_g = nil

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


local function _calculateSlice(slice_mode, amount, length, original_length, do_scale)
	--print("slice_mode", slice_mode, "amount", amount, "length", length, "original_length", original_length)
	local cut
	if slice_mode == "unit" then
		cut = math.floor(original_length * math.max(0, math.min(amount, 1)))

	elseif slice_mode == "px" then
		local scale = do_scale and context.scale or 1.0
		cut = math.floor(math.max(0, math.min(amount * scale, length)))
	else
		error("invalid 'slice_mode' enum.")
	end

	return cut, length - cut
end


local function _querySliceLength(wid, x_axis, cross_length)
	local a, b = wid:uiCall_getSliceLength(x_axis, cross_length)
	if a then
		return a, b
	end
	return wid.ge_c, wid.ge_d -- slice_amount, slice_scale
end


widLayout.handlers = {
	grid = function(np, nc, orig_w, orig_h)
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

	null = function(np, nc, orig_w, orig_h)
		-- Do nothing.
	end,

	remaining = function(np, nc, orig_w, orig_h)
		nc.x, nc.y, nc.w, nc.h = np.lo_x, np.lo_y, np.lo_w, np.lo_h
	end,

	slice = function(np, nc, orig_w, orig_h)
		local slice_mode, slice_edge = nc.ge_a, nc.ge_b

		if slice_edge == "left" then
			nc.y = np.lo_y
			nc.h = np.lo_h
			local amount, scaled = _querySliceLength(nc, true, nc.h)
			nc.w, np.lo_w = _calculateSlice(slice_mode, amount, np.lo_w, orig_w, scaled)
			nc.x = np.lo_x
			np.lo_x = np.lo_x + nc.w

		elseif slice_edge == "right" then
			nc.y = np.lo_y
			nc.h = np.lo_h
			local amount, scaled = _querySliceLength(nc, true, nc.h)
			nc.w, np.lo_w = _calculateSlice(slice_mode, amount, np.lo_w, orig_w, scaled)
			nc.x = np.lo_x + np.lo_w

		elseif slice_edge == "top" then
			nc.x = np.lo_x
			nc.w = np.lo_w
			local amount, scaled = _querySliceLength(nc, false, nc.w)
			nc.h, np.lo_h = _calculateSlice(slice_mode, amount, np.lo_h, orig_h, scaled)
			nc.y = np.lo_y
			np.lo_y = np.lo_y + nc.h

		elseif slice_edge == "bottom" then
			nc.x = np.lo_x
			nc.w = np.lo_w
			local amount, scaled = _querySliceLength(nc, false, nc.w)
			nc.h, np.lo_h = _calculateSlice(slice_mode, amount, np.lo_h, orig_h, scaled)
			nc.y = np.lo_y + np.lo_h

		else
			error("bad slice_edge enum.")
		end
	end,

	static = function(np, nc, orig_w, orig_h)
		local scale = context.scale
		local static_x, static_y, static_w, static_h = nc.ge_a, nc.ge_b, nc.ge_c, nc.ge_d
		local static_rel, static_flip_x, static_flip_y = nc.ge_e, nc.ge_f, nc.ge_g

		local px, py, pw, ph
		if static_rel then
			px, py, pw, ph = np.lo_x, np.lo_y, np.lo_w, np.lo_h
		else
			px, py, pw, ph = 0, 0, orig_w, orig_h
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
	local orig_w, orig_h = self.lo_w, self.lo_h

	-- Margin reduction
	local mx1 = math.floor(self.lo_margin_x1 * scale)
	local my1 = math.floor(self.lo_margin_y1 * scale)
	local mx2 = math.floor(self.lo_margin_x2 * scale)
	local my2 = math.floor(self.lo_margin_y2 * scale)

	self.lo_x = self.lo_x + mx1
	self.lo_y = self.lo_y + my1
	self.lo_w = math.max(0, self.lo_w - mx1 - mx2)
	self.lo_h = math.max(0, self.lo_h - my1 - my2)

	for i, child in ipairs(self.lo_list) do
		local handler = widLayout.handlers[child.ge_mode]
		if not handler then
			error("invalid or missing layout handler: " .. tostring(child.ge_mode))
		end

		--print("old self XYWH", self.x, self.y, self.w, self.h)
		handler(self, child, orig_w, orig_h)
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
