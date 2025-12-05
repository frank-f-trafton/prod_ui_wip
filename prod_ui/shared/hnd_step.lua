local context = select(1, ...)


-- Step handlers.


local hndStep = {}


local pTree = require(context.conf.prod_ui_req .. "lib.pile_tree")


local _nodeGetSiblings = pTree.nodeGetSiblings


function hndStep.linear(self, start, delta, wrap)
	local seq = _nodeGetSiblings(self)

	start = start or self:nodeAssertIndex(seq)
	if start < 1 or start > #seq then
		error("start position is out of bounds.")
	end

	local i = start + delta
	local next_wid = seq[(i-1) % #seq + 1]

	while next_wid do
		if next_wid:canTakeThimble(1) then
			return next_wid
		end
		i = i + delta
		if wrap then
			i = (i-1) % #seq + 1
		end
		if i == start then
			return
		end
		next_wid = seq[i]
	end
end


local function _getGen2Ancestor(wid)
	if not wid.parent then
		return false
	end

	while wid.parent.parent do
		wid = wid.parent
	end

	return wid
end


function hndStep.intergenerationalNext(wid)
	local g2 = _getGen2Ancestor(wid)
	if not g2 then
		return
	end

	local i = 0
	while i <= 2 do
		local nxt = wid:nodeGetNext()

		-- reached the tree's end, or otherwise landed on a second-gen node
		if not nxt or not nxt.parent or not nxt.parent.parent then
			nxt = g2
			i = i + 1
		end

		if nxt:canTakeThimble(1) then
			return nxt
		else
			wid = nxt
		end
	end
end


function hndStep.intergenerationalPrevious(wid)
	local g2 = _getGen2Ancestor(wid)
	if not g2 then
		return
	end

	local i = 0
	while i <= 2 do
		local prv
		if wid.parent and wid.parent.parent then
			prv = wid:nodeGetPrevious()
		else
			prv = g2:nodeGetVeryLast()
			i = i + 1
		end

		if not prv then
			break

		elseif prv:canTakeThimble(1) then
			return prv

		else
			wid = prv
		end
	end
end


--- Look for a widget which can hold the thimble which is close to 'self'.
-- @param px Initial search X position within parent space (ie 'self.x', 'self.x + self.w').
-- @param py Initial search Y position within parent space.
-- @param dx (1, 0 or -1) Search X direction. Discards widgets "behind" the vector.
-- @param dy (1, 0 or -1) Search Y direction.
-- @param wrap When true, search is run twice, the second time from the edge of the container.
function hndStep.proximity(self, px, py, dx, dy, wrap)
	--[[
		NOTE: The wrapping behavior will break on layouts where children are placed outside
		of the container's bounding box. (When wrapping, the target XY coordinate is moved
		to the edge of the container, so if a widget is outside of it, then it will be
		discarded from the search.)
	--]]

	local wid = false
	local dist_closest = math.huge

	local siblings = _nodeGetSiblings(self) -- asserts 'self' has a parent / is not the root.
	local parent = self.parent

	local i = 1
	local looped = false

	while true do
		local sibling = siblings[i]

		if not sibling then
			if not wrap or looped then
				break
			else
				looped = true
				i = 1
				sibling = siblings[i]

				if wrap then
					px = (dx == 1) and 0 or (dx == -1) and parent.w or px
					py = (dy == 1) and 0 or (dy == -1) and parent.h or py
				end
			end
		end

		if self ~= sibling and sibling:canTakeThimble(1) then
			local sx = math.max(sibling.x, math.min(px, sibling.x + sibling.w))
			local sy = math.max(sibling.y, math.min(py, sibling.y + sibling.h))

			local dist = math.abs(x - sx) + math.abs(y - sy)

			-- Discard widgets "behind" the vector.
			if (dx == 1 and sx <= x) or (dx == -1 and sx >= x)
			or (dy == 1 and sy <= y) or (dy == -1 and sy >= y)
			then
				-- ...

			elseif not wid or dist < dist_closest then
				wid = sibling
				dist_closest = dist
			end
		end

		i = i + 1
	end

	return wid
end


function hndStep.byIndex(self, index)
	local seq = _nodeGetSiblings(self)
	if index < 1 or index > #seq then
		error("step index is out of bounds.")
	end
	return seq[index]
end


hndStep.named = {}


hndStep.named["$next"] = function(self)
	return hndStep.linear(self, nil, 1, false) or "!step_failed"
end
hndStep.named["$next_or_unhost"] = function(self)
	return hndStep.linear(self, nil, 1, false) or "!step_unhost"
end


hndStep.named["$next_wrap"] = function(self)
	return hndStep.linear(self, nil, 1, true) or "!step_failed"
end
hndStep.named["$next_wrap_or_unhost"] = function(self)
	return hndStep.linear(self, nil, 1, true) or "!step_unhost"
end


hndStep.named["$previous"] = function(self)
	return hndStep.linear(self, nil, -1, false) or "!step_failed"
end
hndStep.named["$previous_or_unhost"] = function(self)
	return hndStep.linear(self, nil, -1, false) or "!step_unhost"
end


hndStep.named["$previous_wrap"] = function(self)
	return hndStep.linear(self, nil, -1, true) or "!step_failed"
end
hndStep.named["$previous_wrap_or_unhost"] = function(self)
	return hndStep.linear(self, nil, -1, true) or "!step_unhost"
end


hndStep.named["$intergen_next"] = function(self)
	return hndStep.intergenerationalNext(self) or "!step_failed"
end
hndStep.named["$intergen_next_or_unhost"] = function(self)
	return hndStep.intergenerationalNext(self) or "!step_unhost"
end


hndStep.named["$intergen_previous"] = function(self)
	return hndStep.intergenerationalPrevious(self) or "!step_failed"
end
hndStep.named["$intergen_previous_or_unhost"] = function(self)
	return hndStep.intergenerationalPrevious(self) or "!step_unhost"
end


hndStep.named["$prox_left"] = function(self)
	return hndStep.proximity(self, self.x, self.y + self.h/2, -1, 0, false) or "!step_failed"
end
hndStep.named["$prox_left_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x, self.y + self.h/2, -1, 0, false) or "!step_unhost"
end


hndStep.named["$prox_left_wrap"] = function(self)
	return hndStep.proximity(self, self.x, self.y + self.h/2, -1, 0, true) or "!step_failed"
end
hndStep.named["$prox_left_wrap_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x, self.y + self.h/2, -1, 0, true) or "!step_unhost"
end


hndStep.named["$prox_right"] = function(self)
	return hndStep.proximity(self, self.x + self.w, self.y + self.h/2, 1, 0, false) or "!step_failed"
end
hndStep.named["$prox_right_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x + self.w, self.y + self.h/2, 1, 0, false) or "!step_unhost"
end


hndStep.named["$prox_right_wrap"] = function(self)
	return hndStep.proximity(self, self.x + self.w, self.y + self.h/2, 1, 0, true) or "!step_failed"
end
hndStep.named["$prox_right_wrap_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x + self.w, self.y + self.h/2, 1, 0, true) or "!step_unhost"
end


hndStep.named["$prox_up"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y, 0, -1, false) or "!step_failed"
end
hndStep.named["$prox_up_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y, 0, -1, false) or "!step_unhost"
end


hndStep.named["$prox_up_wrap"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y, 0, -1, true) or "!step_failed"
end
hndStep.named["$prox_up_wrap_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y, 0, -1, true) or "!step_unhost"
end


hndStep.named["$prox_down"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y + self.h, 0, 1, false) or "!step_failed"
end
hndStep.named["$prox_down_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y + self.h, 0, 1, false) or "!step_unhost"
end


hndStep.named["$prox_down_wrap"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y + self.h, 0, 1, true) or "!step_failed"
end
hndStep.named["$prox_down_wrap_or_unhost"] = function(self)
	return hndStep.proximity(self, self.x + self.w/2, self.y + self.h, 0, 1, true) or "!step_unhost"
end


return hndStep
