--[[
Pooled resources.
--]]


local context = select(1, ...)


local pools = {}


local pPool = require(context.conf.prod_ui_req .. "lib.pile_pool")


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


-- Small array: 'widget.children'
pools.children = pPool.new(_poppingArraySmall, _pushingArraySmall, math.huge) -- test

-- Small array: 'widget.lo_list'
--pools.lo_list = pPool.new(_poppingArraySmall, _pushingArraySmall, math.huge) -- test


-- Small array: 'widget.viewports'
--pools.viewports = pPool.new(_poppingArraySmall, _pushingArraySmall, math.huge) -- test


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


-- Struct: 'widget.viewports[*]'
--pools.vp = pPool.new(_poppingViewport, _pushingViewport, math.huge)


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
--pools.lo_static = pPool.new(_poppingStaticLayout, _pushingStaticLayout, math.huge)


-- LÖVE Quads, TextBatches, etc.


return pools
