-- ProdUI: Shared debug logic for widgets.


local widDebug = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local widShared = require(REQ_PATH .. "wid_shared")


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
function widDebug.debugDrawViewport(self, v, r, g, b, a)

	love.graphics.push("all")

	if type(r) == "table" then
		love.graphics.setColor(r)

	elseif type(r) == "number" then
		love.graphics.setColor(r, g, b, a)

	else
		love.graphics.setColor(vp_colors[v])
	end

	v = widShared.vp_keys[v]

	if isNum(self[v.x]) and isNum(self[v.y]) and isNum(self[v.w]) and isNum(self[v.h]) then
		setupLineState()
		love.graphics.rectangle("line", 0.5 + self[v.x], 0.5 + self[v.y], self[v.w] - 1, self[v.h] - 1)
	end

	love.graphics.pop()
end


return widDebug

