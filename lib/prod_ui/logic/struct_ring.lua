-- XXX: Untested.
-- A generic ring buffer container.
-- Use case: rolling message logs.


local structRing = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local _mt_ring = {}
_mt_ring.__index = _mt_ring


-- * API *


--- Makes a new ring buffer.
-- @param max (0) The initial maximum entries.
-- @return The ring buffer table.
function structRing.new(max)

	local self = setmetatable({}, _mt_ring)

	-- The structure owner is responsible for managing the contents of `self.buf`.
	-- Never introduce gaps into the buffer contents. Nil entries are used to determine
	-- if the ring buffer has wrapped around. If you must erase an entry, set it to
	-- false or use some sort of dummy data / table.
	self.buf = {}

	-- Which index is considered the "last." 0 means the buffer is empty.
	self.last = 0

	-- How big the ring buffer can get before overwriting old entries.
	-- Use ring:setMax() to change it after creation.
	self.max = max or 0

	return self
end


-- * Methods *


-- Sets the max items for the ring buffer. The buffer contents are reordered, cutting excess items if the new max is smaller.
-- @param max The new maximum.
function _mt_ring:setMax(max)

	-- XXX: Assertions.

	-- Build a list of buffer items to rearrange.
	local temp = {}
	local i, tbl
	for j = 1, max do
		i, tbl = self:getPrev(i)
		temp[j] = tbl

		if not i then
			break
		end
	end

	self.max = max

	-- Clear and rewrite the whole buffer list.
	for i = #self.buf, 1, -1 do
		self.buf[i] = nil
	end
	for j = #temp, 1, -1 do
		table.insert(self.buf, temp[j])
	end

	self.last = #self.buf
end


-- Move the "last" marker forward by one. After calling, if `max` is greater than zero, the caller must ensure that there
-- is a non-nil value in `ring.buf[ring.last]`.
function _mt_ring:advanceLast()

	if self.max <= 0 then
		self.last = 0

	else
		self.last = self.last + 1
		if self.last > self.max then
			self.last = 1
		end
	end

	-- If `ring.last` > 0 and there is nothing in the last slot, assign something ASAP.
end


-- Gets the "first" position in the buffer.
function _mt_ring:getFirst()

	if self.max <= 0 then
		return 0
	end

	return (self.last % math.max(self.last, self.max)) + 1
end


-- Gets the previous item and index in the ring buffer.
-- @param i (last) The index to read. Pass nothing / nil to pick the last item in the buffer.
-- return index and table of the previous item. Exceptions: 1) If the buffer is empty, returns nil; 2) If this is
-- the first item, the returned index is nil.
function _mt_ring:getPrev(i)

	-- XXX: Assertions, flooring

	if self.max == 0 then
		return
	end

	i = i and i - 1 or self.last
	if i < 1 then
		i = self.max
	end

	return (i ~= self:getFirst() and i), self.buf[i]
end


-- Gets the next item and index in the ring buffer.
-- @param i (first) The index to read. Pass nothing / nil to pick the first item in the buffer.
-- @return index and table of the next item. Exceptions: 1) If the buffer is empty, returns nil; 2) If this is
-- the last item, the returned index is nil.
function _mt_ring:getNext(i)

	-- Usage example:
	--[[
	local i, item = ring:getNext()
	while item do
		-- (Work on 'item')

		i, item = ring:getNext(i)
	end
	--]]

	-- XXX: Assertions, flooring

	if self.max <= 0 then
		return
	end

	i = i and i + 1 or self:getFirst()
	if i > self.max then
		i = 1
	end

	return (i ~= self.last and i), self.buf[i]
end


return structRing
