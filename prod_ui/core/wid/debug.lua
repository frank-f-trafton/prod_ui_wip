-- Access through 'wid_shared.lua'.

-- ProdUI: Shared debug logic for widgets.


local context = select(1, ...)


local debug = {} -- widShared.debug


local viewport_keys = context:getLua("core/viewport_keys")


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
		love.graphics.setLineWidth(1)
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineJoin("miter")
		love.graphics.rectangle("line", 0.5 + self[v.x], 0.5 + self[v.y], self[v.w] - 1, self[v.h] - 1)
	end

	love.graphics.pop()
end


function debug.debugDrawLayoutNodes(wid)
	-- Translate to the widget's position and scroll offsets before calling.

	if not wid.lo_list then
		return
	end

	love.graphics.push("all")
	love.graphics.setScissor()

	if wid.lo_w > 0 and wid.lo_h > 0 then
		love.graphics.setColor(0.75, 0.75, 1, 0.5)
		love.graphics.setLineWidth(2)
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineJoin("miter")
		love.graphics.rectangle("fill", wid.lo_x, wid.lo_y, wid.lo_w, wid.lo_h)
	end

	-- TODO: grid stuff in parent

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)

	for i, child in ipairs(wid.children) do
		if child.ge_mode ~= "null" then
			love.graphics.rectangle("line", child.x, child.y, child.w, child.h)
			love.graphics.setColor(0, 0, 0, 0.5)
			love.graphics.print(child.ge_mode, child.x + 2, child.y + 2)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(child.ge_mode, child.x, child.y)
		end
	end

	love.graphics.pop()
end


return debug -- widShared.debug
