-- To load: local lib = context:getLua("shared/lib")


-- The new layout system.


-- TODO: remove '_depth' debug fields


local context = select(1, ...)


local widLayout = {}


local viewport_keys = require(context.conf.prod_ui_req .. "common.viewport_keys")


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

	-- For widgets that support dynamic sizing.
	flow = false, -- "x", "y", false

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

	-- "px": unscaled pixels
	-- "unit": value from 0.0 - 1.0, representing a portion of the original parent area before any slices
	-- were taken off at this level.
	-- "ask": Query the client widget for a pixel value; fall back to 'slice_amount' as a pixel value otherwise.
	slice_mode = "unit", -- "px", "unit", "ask"
	slice_edge = "left", -- "left", "top", "right", "bottom"
	slice_amount = 0.5,

	-- Used by the divider container to mark nodes as draggable bars.
	slice_sash = false,

	-- * Mode: grid
	-- Number of tiles in the grid (for parents)
	grid_rows = 0,
	grid_cols = 0,

	-- Tile position, from 0 to len - 1 (for children)
	grid_x = 0,
	grid_y = 0,

	-- * Mode: static
	-- Position and dimensions. X and Y are wrapped with a modulo, so negative values will place the node on the far end.
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
	self.margin_x1 = x1
	self.margin_y1 = y1
	self.margin_x2 = x2
	self.margin_y2 = y2
end


-- "slice": slice_mode, slice_edge, slice_amount, [slice_sash]
-- "grid": grid_x, grid_y
-- "static": x, y, w, h
-- "null": No arguments.
function _mt_node:setMode(mode, a, b, c, d)
	-- TODO: assertions

	self.mode = mode
	if mode == "slice" then
		self.slice_mode = a
		self.slice_edge = b
		self.slice_amount = c
		self.slice_sash = d or false

	elseif mode == "grid" then
		self.grid_x = a
		self.grid_y = b

	elseif mode == "static" then
		self.x = a
		self.y = b
		self.w = c
		self.h = d
	end
end


-- This is a parent node setting that affects its children.
function _mt_node:setGridDimensions(rows, cols)
	-- TODO: assertions.

	self.grid_rows = rows
	self.grid_cols = cols
end


function _mt_node:getMargin()
	return self.margin_x1, self.margin_y1, self.margin_x2, self.margin_y2
end


function widLayout.initializeLayoutTree(self)
	self.layout_tree = setmetatable({}, _mt_node)
end


function widLayout.resetLayout(self, to, v)
	local n = self.layout_tree
	if to == "zero" then
		n.x, n.y, n.w, n.h = 0, 0, 0, 0

	elseif to == "self" then
		n.x, n.y, n.w, n.h = 0, 0, self.w, self.h

	elseif to == "viewport" then
		v = viewport_keys[v]
		n.x, n.y, n.w, n.h = 0, 0, self[v.w], self[v.h]

	elseif to == "viewport-full" then
		v = viewport_keys[v]
		n.x, n.y, n.w, n.h = self[v.x], self[v.y], self[v.w], self[v.h]
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


function widLayout.applySlice(slice_mode, amount, length, original_length)
	local cut
	if slice_mode == "unit" then
		cut = math.floor(original_length * math.max(0, math.min(amount, 1)))

	elseif slice_mode == "px" then
		cut = math.floor(math.max(0, math.min(amount, length)))

	else
		error("invalid 'slice_mode' enum.")
	end

	return cut, length - cut
end


widLayout.handlers = {}


widLayout.handlers["static"] = function(np, nc)
	nc.x = np.w > 0 and np.x + (nc.static_x % np.w) or 0
	nc.y = np.h > 0 and np.y + (nc.static_y % np.h) or 0
	nc.w = nc.static_w
	nc.h = nc.static_h
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


widLayout.handlers["slice"] = function(np, nc)
	local wid = nc.wid_ref

	if nc.slice_edge == "left" then
		nc.y = np.y
		nc.h = np.h
		local amount = wid and wid:uiCall_getSliceLength(true, nc.h) or nc.slice_amount
		nc.w, np.w = widLayout.applySlice(nc.slice_mode, amount, np.w, np.orig_w)
		nc.x = np.x
		np.x = np.x + nc.w

	elseif nc.slice_edge == "right" then
		nc.y = np.y
		nc.h = np.h
		local amount = wid and wid:uiCall_getSliceLength(true, nc.h) or nc.slice_amount
		nc.w, np.w = widLayout.applySlice(nc.slice_mode, amount, np.w, np.orig_w)
		nc.x = np.x + np.w

	elseif nc.slice_edge == "top" then
		nc.x = np.x
		nc.w = np.w
		local amount = wid and wid:uiCall_getSliceLength(false, nc.w) or nc.slice_amount
		nc.h, np.h = widLayout.applySlice(nc.slice_mode, amount, np.h, np.orig_h)
		nc.y = np.y
		np.y = np.y + nc.h

	elseif nc.slice_edge == "bottom" then
		nc.x = np.x
		nc.w = np.w
		local amount = wid and wid:uiCall_getSliceLength(false, nc.w) or nc.slice_amount
		nc.h, np.h = widLayout.applySlice(nc.slice_mode, amount, np.h, np.orig_h)
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
