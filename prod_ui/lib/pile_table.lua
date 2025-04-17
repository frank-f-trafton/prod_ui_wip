-- PILE Table Helpers v1.1.5 (modified)
-- (C) 2024 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local M = {}


M.lang = {}
local lang = M.lang


local ipairs, pairs, type = ipairs, pairs, type


function M.isArray(t)
	local c = 0
	for k, v in pairs(t) do
		if type(k) == "number" and math.floor(k) == k and k >= 1 then
			if k > #t then
				return false
			end
			c = c + 1
		end
	end
	return c == #t
end


function M.isArrayOnly(t)
	local c = 0
	for k, v in pairs(t) do
		if type(k) ~= "number" or math.floor(k) ~= k or k < 1 or k > #t then
			return false
		end
		c = c + 1
	end
	return c == #t
end


function M.makeLUT(t)
	local lut = {}
	for i, v in ipairs(t) do
		lut[v] = true
	end
	return lut
end


function M.makeLUTV(...)
	local lut = {}
	for i = 1, select("#", ...) do
		lut[select(i, ...)] = true
	end
	return lut
end



lang.err_dupe = "duplicate values in source table"
function M.invertLUT(t)
	local lut = {}
	for k, v in pairs(t) do
		if lut[v] then
			error(lang.err_dupe)
		end
		lut[v] = k
	end
	return lut
end


lang.err_i_empty = "table element at index 'i' is nil"
lang.err_j_empty = "table element at index 'j' is nil"
function M.moveElement(t, i, j)
	if t[i] == nil then error(lang.err_i_empty)
	elseif t[j] == nil then error(lang.err_j_empty) end

	if i ~= j then
		table.insert(t, j, table.remove(t, i))
	end
end


function M.swapElements(t, i, j)
	if t[i] == nil then error(lang.err_i_empty)
	elseif t[j] == nil then error(lang.err_j_empty) end

	t[i], t[j] = t[j], t[i]
end


function M.cloneArray(t)
	local b = {}
	for i, v in ipairs(t) do
		b[i] = v
	end
	return b
end


local function _deepCopy(dst, src, _depth)
	--print("_deepCopy: start", _depth)
	for k, v in pairs(src) do
		dst[k] = type(v) == "table" and _deepCopy({}, v, _depth + 1) or v
	end
	--print("_deepCopy: end", _depth)
	return dst
end


-- Does not handle tables as keys (t = {[{true}] = "foo"}).
-- Does not handle cycles.
-- Multiple appearances of the same table in src will generate unique tables in dst.
function M.deepCopy(t)
	return _deepCopy({}, t, 1)
end


function M.clear(t)
	for k in pairs(t) do
		t[k] = nil
	end
end


function M.assignIfNil(t, f, ...)
	if t[f] == nil then
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if v ~= nil then
				t[f] = v
				break
			end
		end
	end
end


function M.assignIfNilOrFalse(t, f, ...)
	if not t[f] then
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if v then
				t[f] = v
				break
			end
		end
	end
end



return M
