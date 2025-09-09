-- To load: local lib = context:getLua("shared/lib")


-- The new layout system.


-- TODO: remove '_depth' debug fields


local context = select(1, ...)


local widLayout = {}


local uiTable = require(context.conf.prod_ui_req .. "ui_table")


widLayout._enum_layout_base = uiTable.makeLUTV(
	"zero",
	"self",
	"viewport",
	"viewport-width",
	"viewport-height",
	"unbounded"
)


local _mt_node = {
	-- "slice", "grid", "static", "null"
	mode = "null",

	parent = false, -- parent node, if applicable.
	wid_ref = false,
	nodes = false, -- false, or array of child nodes.

	x = 0,
	y = 0,
	w = 0,
	h = 0,

	w_min = 0,
	w_max = math.huge,
	h_min = 0,
	h_max = math.huge,

	w_pref = false,
	h_pref = false,

	-- Parent original dimensions, before any splitting has occurred.
	orig_w = 0,
	orig_h = 0,

	-- Shrinks the node along its four edges.
	margin_x1 = 0,
	margin_y1 = 0,
	margin_x2 = 0,
	margin_y2 = 0,

	-- * Mode: slice

	-- "px": pixels
	-- "unit": value from 0.0 - 1.0, representing a portion of the original parent area before any slices
	-- were taken off at this level.
	slice_mode = "unit", -- "px", "unit"
	slice_scale = false, -- scales "px" values when true.
	slice_edge = "left", -- "left", "top", "right", "bottom"
	slice_amount = 0.5,

	-- Used by the divider container to mark nodes as draggable bars.
	slice_is_sash = false,

	-- * Mode: grid
	-- Number of tiles in the grid (for parents)
	grid_rows = 0,
	grid_cols = 0,

	-- Tile position, from 0 to len - 1 (for children)
	grid_x = 0,
	grid_y = 0,

	-- * Mode: static
	-- Position and dimensions.
	static_x = 0,
	static_y = 0,
	static_w = 0,
	static_h = 0,
}
_mt_node.__index = _mt_node


function _mt_node:newNode()
	self.nodes = self.nodes or {}
	local node = setmetatable({parent = self}, _mt_node)
	table.insert(self.nodes, node)
	return node
end


function _mt_node:reset()
	for k in pairs(self) do
		self[k] = nil
	end
end


function widLayout.nodeInTree(root, node)
	if node == root then
		return true

	elseif root.nodes then
		for i, child in ipairs(root.nodes) do
			if widLayout.nodeInTree(child, node) then
				return true
			end
		end
	end

	return false
end


function _mt_node:forEach(fn, ...)
	if fn(self, ...) then
		return self

	elseif self.nodes then
		for i, child in ipairs(self.nodes) do
			local rv = child:forEach(fn, ...)
			if rv then
				return rv
			end
		end
	end
end


function _mt_node:setMargin(x1, y1, x2, y2)
	local scale = context.scale

	self.margin_x1 = math.floor(x1 * scale)
	self.margin_y1 = math.floor(y1 * scale)
	self.margin_x2 = math.floor(x2 * scale)
	self.margin_y2 = math.floor(y2 * scale)
end


function _mt_node:setMarginPrescaled(x1, y1, x2, y2)
	self.margin_x1 = x1
	self.margin_y1 = y1
	self.margin_x2 = x2
	self.margin_y2 = y2
end


function _mt_node:getMargin()
	return self.margin_x1, self.margin_y1, self.margin_x2, self.margin_y2
end


-- "slice": slice_mode, slice_edge, slice_amount, [slice_scale], [slice_is_sash]
-- "grid": grid_x, grid_y
-- "static": x, y, w, h, scaled
-- "null": No arguments.
function _mt_node:setMode(mode, a, b, c, d, e)
	-- TODO: assertions

	self.mode = mode
	if mode == "slice" then
		self.slice_mode = a
		self.slice_edge = b
		self.slice_amount = c
		self.slice_scale = not not d
		self.slice_is_sash = not not e

	elseif mode == "grid" then
		self.grid_x = a
		self.grid_y = b

	elseif mode == "static" then
		self.static_x = a
		self.static_y = b
		self.static_w = c
		self.static_h = d
	end
end


-- This is a parent node setting that affects its children.
function _mt_node:setGridDimensions(rows, cols)
	-- TODO: assertions.

	self.grid_rows = rows
	self.grid_cols = cols
end


function widLayout.initializeLayoutTree(self)
	self.layout_tree = setmetatable({}, _mt_node)
end


function widLayout.resetLayout(self, to)
	local n = self.layout_tree
	if to == "zero" then
		n.x, n.y, n.w, n.h = 0, 0, 0, 0

	elseif to == "self" then
		n.x, n.y, n.w, n.h = 0, 0, self.w, self.h

	elseif to == "viewport" then
		n.x, n.y, n.w, n.h = 0, 0, self.vp_w, self.vp_h

	elseif to == "viewport-full" then
		n.x, n.y, n.w, n.h = self.vp_x, self.vp_y, self.vp_w, self.vp_h

	elseif to == "viewport-width" then
		n.x, n.y, n.w, n.h = 0, 0, self.vp_w, math.huge

	elseif to == "viewport-height" then
		n.x, n.y, n.w, n.h = 0, 0, math.huge, self.vp_h

	elseif to == "unbounded" then
		n.x, n.y, n.w, n.h = 0, 0, math.huge, math.huge

	else
		error("invalid layout base mode.")
	end
end


function _mt_node:carveEdgePixels(x_left, y_top, x_right, y_bottom)
	self.w = math.max(0, self.w - x_left - x_right)
	self.h = math.max(0, self.h - y_top - y_bottom)
	self.x = self.x + x_left
	self.y = self.y + y_top
end


function _mt_node:carveEdgeUnit(x_left, y_top, x_right, y_bottom)
	x_left = math.max(0.0, math.min(x_left, 1.0))
	y_top = math.max(0.0, math.min(y_top, 1.0))
	x_right = math.max(0.0, math.min(x_right, 1.0))
	y_bottom = math.max(0.0, math.min(y_bottom, 1.0))

	x_left = math.floor(0.5 + x_left * self.w)
	y_top = math.floor(0.5 + y_top * self.h)
	x_right = math.floor(0.5 + x_right * self.w)
	y_bottom = math.floor(0.5 + y_bottom * self.h)

	self:carveEdgePixels(x_left, y_top, x_right, y_bottom)
end


function widLayout.applySlice(slice_mode, amount, length, original_length, do_scale)
	--print("slice_mode", slice_mode, "amount", amount, "length", length, "original_length", original_length)
	local cut
	if slice_mode == "unit" then
		cut = math.floor(original_length * math.max(0, math.min(amount, 1)))

	elseif slice_mode == "px" then
		if do_scale then
			cut = math.floor(math.max(0, math.min(amount * context.scale, length)))
		else
			cut = math.floor(math.max(0, math.min(amount, length)))
		end

	else
		error("invalid 'slice_mode' enum.")
	end

	return cut, length - cut
end


widLayout.handlers = {}


widLayout.handlers["static"] = function(np, nc)
	local scale = context.scale
	nc.x = math.floor(nc.static_x * scale)
	nc.y = math.floor(nc.static_y * scale)
	nc.w = math.floor(math.max(0, nc.static_w * scale))
	nc.h = math.floor(math.max(0, nc.static_h * scale))
end


widLayout.handlers["grid"] = function(np, nc)
	if np.grid_rows > 0 and np.grid_cols > 0 then
		nc.x = np.x + math.floor(nc.grid_x * np.w / np.grid_rows)
		nc.y = np.y + math.floor(nc.grid_y * np.h / np.grid_cols)
		nc.w = math.floor(np.w / np.grid_rows)
		nc.h = math.floor(np.h / np.grid_cols)
	else
		nc.x, nc.y, nc.w, nc.h = 0, 0, 0, 0
	end
end


local function _querySliceLength(wid, nc, x_axis, cross_length)
	if wid then
		local a, b = wid:uiCall_getSliceLength(x_axis, cross_length)
		if a then
			return a, b
		end
	end
	return nc.slice_amount, nc.slice_scale
end


widLayout.handlers["slice"] = function(np, nc)
	local wid = nc.wid_ref

	if nc.slice_edge == "left" then
		nc.y = np.y
		nc.h = np.h
		local amount, scaled = _querySliceLength(wid, nc, true, nc.h)
		nc.w, np.w = widLayout.applySlice(nc.slice_mode, amount, np.w, np.orig_w, scaled)
		nc.x = np.x
		np.x = np.x + nc.w

	elseif nc.slice_edge == "right" then
		nc.y = np.y
		nc.h = np.h
		local amount, scaled = _querySliceLength(wid, nc, true, nc.h)
		nc.w, np.w = widLayout.applySlice(nc.slice_mode, amount, np.w, np.orig_w, scaled)
		nc.x = np.x + np.w

	elseif nc.slice_edge == "top" then
		nc.x = np.x
		nc.w = np.w
		local amount, scaled = _querySliceLength(wid, nc, false, nc.w)
		nc.h, np.h = widLayout.applySlice(nc.slice_mode, amount, np.h, np.orig_h, scaled)
		nc.y = np.y
		np.y = np.y + nc.h

	elseif nc.slice_edge == "bottom" then
		nc.x = np.x
		nc.w = np.w
		local amount, scaled = _querySliceLength(wid, nc, false, nc.w)
		nc.h, np.h = widLayout.applySlice(nc.slice_mode, amount, np.h, np.orig_h, scaled)
		nc.y = np.y + np.h

	else
		error("bad slice_edge enum.")
	end
end


widLayout.handlers["null"] = function(np, nc)
	-- Do nothing.
end


function widLayout.splitNode(n, _depth)
	--print("_splitNode() " .. _depth .. ": start")
	--print(n, "#nodes:", n and n.nodes and (#n.nodes))

	-- Min/max dimensions
	n.w = math.max(n.w_min, math.min(n.w, n.w_max))
	n.h = math.max(n.h_min, math.min(n.h, n.h_max))

	-- Margin reduction
	n.x = n.x + n.margin_x1
	n.y = n.y + n.margin_y1
	n.w = math.max(0, n.w - n.margin_x1 - n.margin_x2)
	n.h = math.max(0, n.h - n.margin_y1 - n.margin_y2)

	n.orig_w, n.orig_h = n.w, n.h

	if n.nodes then
		--print("old n XYWH", n.x, n.y, n.w, n.h)
		local nodes = n.nodes
		for i, n2 in ipairs(nodes) do
			local handler = widLayout.handlers[n2.mode]
			if not handler then
				error("invalid or missing layout handler: " .. tostring(n2.mode))
			end

			handler(n, n2)

			--print("new n XYWH", n.x, n.y, n.w, n.h)
			--print("new child " .. i .. " XYWH", n2.x, n2.y, n2.w, n2.h)
			widLayout.splitNode(n2, _depth + 1)
		end
	end

	--print("_splitNode() " .. _depth .. ": end")
end


function widLayout.setWidgetSizes(n, _depth)
	local wid = n.wid_ref
	if wid then
		wid.x, wid.y, wid.w, wid.h = n.x, n.y, n.w, n.h
	end
	if n.nodes then
		for i, n2 in ipairs(n.nodes) do
			widLayout.setWidgetSizes(n2, _depth + 1)
		end
	end
end


function widLayout.getPreviousSibling(node)
	local parent = node.parent
	if parent then
		for i, child in ipairs(parent.nodes) do
			if child == node then
				return i > 1 and parent.nodes[i - 1]
			end
		end
	end
end


return widLayout
