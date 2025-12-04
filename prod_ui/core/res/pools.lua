--[[
Pooled resources.
--]]


local context = select(1, ...)


local pools = {}


local pPool = require(context.conf.prod_ui_req .. "lib.pile_pool")
local pRect = require(context.conf.prod_ui_req .. "lib.pile_rectangle")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


local function _poppingArraySmall(r)
	if not r then
		return {}
	end
	return r
end


local function _pushingArraySmall(r)
	if type(r) ~= "table" then
		error("expected table")
	end
	local len = #r
	-- don't push and clean large arrays
	if len > 100 then
		return
	end
	for i = #r, 1, -1 do
		r[i] = nil
	end
	return r
end


-- Small array: 'widget.nodes'
pools.nodes = pPool.new(_poppingArraySmall, _pushingArraySmall, math.huge) -- test

-- Small array: 'widget.LO_list'
--pools.LO_list = pPool.new(_poppingArraySmall, _pushingArraySmall, math.huge) -- test


local function _poppingViewport(vp)
	if not vp then
		return {x=0, y=0, w=0, h=0}
	end
	return vp
end


local function _pushingViewport(vp)
	if type(vp) ~= "table" then
		error("expected table")
	end
	vp.x, vp.y, vp.w, vp.h = 0, 0, 0, 0
	return vp
end


local _mt_rect = {}
_mt_rect.__index = _mt_rect
_mt_rect.__newindex = uiTable.mt_restrict.__newindex
for k, v in pairs(pRect) do
	_mt_rect[k] = v
end


local function _poppingRectangle(o)
	if not o then
		return setmetatable({x=0, y=0, w=0, h=0}, _mt_rect)
	end
	return o
end


local function _pushingRectangle(o)
	if type(o) ~= "table" or getmetatable(o) ~= _mt_rect then
		error("expected table (Rectangle)")
	end
	o.x, o.y, o.w, o.h = 0, 0, 0, 0

	return o
end


-- Struct: generic rectangles (x, y, w, h)
pools.rect = pPool.new(_poppingRectangle, _pushingRectangle, 256)


local function _poppingStaticLayout(lo)
	if not lo then
		return {
			-- TODO
		}
	end

	return lo
end


local function _pushingStaticLayout(lo)
	-- TODO
	return lo
end


-- Struct: static layout nodes
--pools.LO_static = pPool.new(_poppingStaticLayout, _pushingStaticLayout, math.huge)


-- LÖVE Quads, TextBatches, etc.


return pools
