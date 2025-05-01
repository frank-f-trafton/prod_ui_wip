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
	return (a:match("^(.-)/?$") .. (a ~= "" and "/" or "") .. b):match("^(.-)/?$")
end


function pPath.getExtension(path)
	return path:match("%..-$")
end


function pPath.splitPathAndExtension(path)
	local a, b = path:match("^(.*)(%..-)$")
	if a then
		return a, b
	else
		return path, ""
	end
end


return pPath
