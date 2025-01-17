-- PILE Table Helpers v1.1.5 (prerelease, needs testing)
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

return M
