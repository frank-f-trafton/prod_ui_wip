-- PILE Name Registry v2.010
-- https://github.com/frank-f-trafton/pile_base


--[[
MIT License

Copyright (c) 2024 - 2025 PILE Contributors

PILE Base uses code from these libraries:

PILE Tree:
  LUIGI
  Copyright (c) 2015 airstruck
  License: MIT
  https://github.com/airstruck/luigi


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local M = {}


M.lang = {
	bad_name = "expected string or false/nil for name",
	not_allowed = "can only associate names with tables, functions, threads and userdata"
}
local lang = M.lang


M.allowed = {["function"]=true, table=true, thread=true, userdata=true}
local _allowed = M.allowed


M.names = setmetatable({}, {__mode="v"})
local names = M.names


function M.set(o, name)
	if not _allowed[type(o)] then
		error(lang.not_allowed)

	elseif name and type(name) ~= "string" then
		error(lang.bad_name)
	end

	names[o] = name or nil

	return o
end


function M.get(o)
	if not _allowed[type(o)] then
		error(lang.not_allowed)
	end

	return names[o]
end


function M.safeGet(o, fallback)
	if not _allowed[type(o)] then
		error(lang.not_allowed)
	end

	return names[o] or (fallback and tostring(fallback) or "Unknown")
end


return M
