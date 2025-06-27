-- PILE Path v1.1.8
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base

local M = {}


function M.getExtension(path)
	return (path:match("/?([^/]-)$"):match("%.[^%.]-$")) or ""
end


function M.join(a, b)
	return (a:match("^/*(.*)$"):match("^(.-)/*$") .. (a ~= "" and "/" or "") .. b:match("^/*(.*)$")):match("^(.-)/*$")
end


function M.splitPathAndExtension(path)
	local e = M.getExtension(path)
	return path:sub(1, -(#e + 1)), e
end


return M
