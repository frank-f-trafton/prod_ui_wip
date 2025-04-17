-- PILE Path (beta)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base

local pPath = {}


function pPath.interpolate(s, sym)
	return s:gsub("%%(.-)%%", sym)
end


function pPath.stripEdgeSlashes(s)
	return s:match("^/*(.-)/*$")
end


function pPath.join(a, b)
	a, b = pPath.stripEdgeSlashes(a), pPath.stripEdgeSlashes(b)
	if a == "" then
		return b
	end
	return a .. "/" .. b
end


return pPath
