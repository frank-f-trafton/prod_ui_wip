-- Access through 'wid_shared.lua'.

-- ProdUI: Shared debug logic for widgets.


local context = select(1, ...)


local debug = {} -- widShared.debug


local viewport_keys = require(context.conf.prod_ui_req .. "common.viewport_keys")


local vp_colors = {
	--[[1]] {1.0, 0.0, 0.0, 1.0},
	--[[2]] {0.0, 1.0, 0.0, 1.0},
	--[[3]] {0.0, 0.0, 1.0, 1.0},
	--[[4]] {1.0, 1.0, 0.0, 1.0},
	--[[5]] {0.0, 1.0, 1.0, 1.0},
	--[[6]] {1.0, 0.0, 1.0, 1.0},
	--[[7]] {0.5, 0.5, 0.5, 1.0},
	--[[8]] {1.0, 1.0, 1.0, 1.0},
}


local function isNum(n)
	return type(n) == "number"
end


local function setupLineState()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineJoin("miter")
end


--- Draws a colored outline around a widget viewport.
-- @param self The widget.
-- @param v The viewport index.
-- @param r, g, b, a An optional color to use for the outline. If not provided, a default keyed to
-- the viewport index will be used instead (see `vp_colors`). `r` can be a table of four numbers
-- ({R, G, B, A}).
function debug.debugDrawViewport(self, v, r, g, b, a)
	love.graphics.push("all")

	if type(r) == "table" then
		love.graphics.setColor(r)

	elseif type(r) == "number" then
		love.graphics.setColor(r, g, b, a)

	else
		love.graphics.setColor(vp_colors[v])
	end

	v = viewport_keys[v]

	if isNum(self[v.x]) and isNum(self[v.y]) and isNum(self[v.w]) and isNum(self[v.h]) then
		setupLineState()
		love.graphics.rectangle("line", 0.5 + self[v.x], 0.5 + self[v.y], self[v.w] - 1, self[v.h] - 1)
	end

	love.graphics.pop()
end


function debug.countLayoutNodes(n)
	local c = 1
	if n.nodes then
		for i, child in ipairs(n.nodes) do
			c = c + debug.countLayoutNodes(child)
		end
	end
	return c
end


function debug.debugDrawLayoutNodes(node, _depth, _index)
	-- Translate to the widget's position and scroll offsets before calling.
	_index = _index or 1

	love.graphics.push("all")
	love.graphics.setScissor()

	love.graphics.setColor(1, 1, 1, 1)
	-- Don't render nodes that are infinitely wide or tall.
	if node.w ~= math.huge and node.h ~= math.huge then
		love.graphics.rectangle("line", node.x, node.y, node.w, node.h)
	end

	-- [depth:index], where depth is the layout tree level, and index is the child slot at that level.
	love.graphics.print("[" .. tostring(_depth) .. ":" .. tostring(_index) .. "]", node.x, node.y)

	if node.nodes then
		--love.graphics.translate(node.x, node.y)
		for i, child in ipairs(node.nodes) do
			debug.debugDrawLayoutNodes(child, _depth + 1, i)
		end
	end

	love.graphics.pop()
end



return debug -- widShared.debug
