-- t2s2: A Lua table serializer.
-- See README.md and LICENSE for more info.
-- Uses code from Serpent by Paul Kulchenko: https://github.com/pkulchenko/serpent
-- Version: 1.0.3


--[[
MIT License

Copyright (c) 2022 - 2024 RBTS
Serpent code: Copyright (c) 2012-2018 Paul Kulchenko (paul@kulchenko.com)

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
]]


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pArg = require(PATH .. "pile_arg_check")
local pTable = require(PATH .. "pile_table")


local _argType, _argEval, _evalIntGE = pArg.type, pArg.typeEval, pArg.evalIntGE
local _makeLUT, _isArrayOnly = pTable.makeLUT, pTable.isArrayOnly


M.lang = {
	err_bad_ser_key = "cannot serialize key of type: $1",
	err_bad_ser_val = "cannot serialize value of type: $1",
	err_max_bytes = "max bytes exceeded",
	err_max_depth = "max table depth exceeded",
	err_missing_pri = "missing or duplicate priority key in table: $1",
	err_priority_key_type = "'pri_keys' must be false/nil or a table",
	err_sep = "separator string must be either one comma or one semicolon",
	err_sort_type = "unsupported type to be sorted: $1",
	err_space = "space, indent and newline strings must contain only ASCII whitespace or be empty"
}
local lang = M.lang


local _sp, _lf, _ind_str, _ind_inc, _sep, _cols
local _jit_names, _missing_pri_fatal, _max_depth, _max_bytes


-- reduces mem usage when writing large tables
local _buf_step = 65536


function M.getFormatting() return _sp, _lf, _ind_str, _ind_inc, _sep, _cols end
function M.setFormatting(s, l, i, d, x, c)
	_argEval(1, s, "string")
	_argEval(2, l, "string")
	_argEval(3, i, "string")
	_argEval(4, d, "number")
	_argEval(5, x, "string")
	_argEval(6, c, "number")
	s, l, i, d, x, c = s or " ", l or "\n", i or "  ", d or 0, x or ",", c or 0
	if s:find("%S") or l:find("%S") or i:find("%S") then error(lang.err_space)
	elseif not x:find("^[,;]$") then error(lang.err_sep) end

	_sp, _lf, _ind_str, _ind_inc, _sep, _cols = s, l, i, d, x, c
end
M.setFormatting()


function M.getExpandedNames() return _jit_names end
function M.setExpandedNames(v) _jit_names = not not v end


function M.getMissingPriorityFatal() return _missing_pri_fatal end
function M.setMissingPriorityFatal(v) _missing_pri_fatal = not not v end


function M.getMaxDepth() return _max_depth end
function M.setMaxDepth(n)
	_argEval(1, n, "number")

	_max_depth = n and n
end


function M.getMaxBytes() return _max_bytes end
function M.setMaxBytes(n)
	_argEval(1, n, "number")

	_max_bytes = n and n
end


local _dummy = {}


-- https://github.com/pkulchenko/serpent/issues/36
-- 'string.format()' will use a dot or a comma for decimals, depending on the locale.
-- The Lua lexer expects dots only.
local _dotRadix, _radix_ptn
local function _dotRadixA(str) return str end
local function _dotRadixB(str) return str:gsub(_radix_ptn, ".") end
local function _updateRadixMark()
	_radix_ptn = "%" .. ("%.1f"):format(0.5):match("0([^5]+)5")
	_dotRadix = (_radix_ptn == "%.") and _dotRadixA or _dotRadixB
end
_updateRadixMark()


local _key_types = _makeLUT({"boolean", "number", "string"})
local _val_types = _makeLUT({"boolean", "number", "string", "table"})
local _reserved = _makeLUT({
	"and", "break", "do", "else", "elseif", "end", "false", "for",
	"function", "if", "in", "local", "nil", "not", "or", "repeat",
	"return", "then", "true", "until", "while"
})
local _special_numbers = {
	[tostring(1/0)] = '1/0', -- math.huge
	[tostring(-1/0)] ='-1/0', -- -math.huge
	[tostring(0/0)] = '0/0' -- NaN
}
local _type_priority = {boolean=1, number=2, string=3, table=4}
local _bool_priority = {[false]=1, [true]=2}
local _esc_common = {
	["\a"] = "\\a", ["\b"] = "\\b", ["\t"] = "\\t", ["\n"] = "\\n", ["\f"] = "\\f",
	["\v"] = "\\v", ["\r"] = "\\r", ["\""] = "\\\"", ["\\"] = "\\\\"
}


local function _indent(n)
	return _ind_str:rep(n)
end


local function _formatNumber(number)
	-- Attempt to keep precision of floating point values
	local num_s = _dotRadix(string.format("%.17g", number))

	if _special_numbers[num_s] then
		num_s = _special_numbers[num_s]
	end

	return num_s
end


local function _hof_repl(s)
	if _esc_common[s] then
		return _esc_common[s]
	else
		local b = s:byte()
		if b < 32 or b > 126 then
			return "\\" .. string.format("%03u", b)
		end
	end
end


local function _formatStringDisplay(s)
	return '"' .. s:gsub("[%z\001-\031\034\092\127]", _hof_repl) .. '"'
end


local function _sort(a, b)
	local ta, tb = type(a), type(b)

	if ta ~= tb then return _type_priority[ta] < _type_priority[tb]
	elseif ta == "boolean" then return _bool_priority[a] < _bool_priority[b]
	elseif ta == "number" or ta == "string" then return a < b
	else error(interp(lang.err_sort_type, ta)) end
end


local _mt_out = {}
_mt_out.__index = _mt_out


function _mt_out:checkBuf(force)
	if force or self.buf_c <= 0 then
		if #self.buf > 0 then
			self.rope[#self.rope + 1] = #self.buf == 1 and self.buf[1] or table.concat(self.buf)
		end
		for i = #self.buf, 1, -1 do
			self.buf[i] = nil
		end
		self.buf_c = _buf_step
	end
end


function _mt_out:append(str)
	self.bytes = self.bytes + #str
	if _max_bytes and self.bytes > _max_bytes then
		error(lang.err_max_bytes)
	end
	self.buf_c = self.buf_c - #str
	self.buf[#self.buf + 1] = str
	self:checkBuf()
end


function _mt_out:indent()
	self:append(_indent(math.max(0, self.depth + _ind_inc)))
end


function _mt_out:writeHashKey(key)
	if type(key) == "string" then
		if not _reserved[key]
		and (not _jit_names and key:match("^[%a_][%w_]*$"))
		or (_jit_names and key:match("^[%a_\128-\255][%w_\128-\255]*$"))
		then
			self:append(key)
		else
			self:append("[" .. _formatStringDisplay(key) .. "]")
		end

	elseif type(key) == "number" then
		self:append("[" .. _formatNumber(key) .. "]")

	elseif type(key) == "boolean" then
		self:append("[" .. tostring(key) .. "]")

	else
		error(interp(lang.err_bad_ser_key, type(key)))
	end
end


local function _hashWriteCode(self, tbl, k, pri_keys)
	self:indent()
	self:writeHashKey(k)
	self:append(_sp .. "=" .. _sp)
	self:writeValue(tbl[k], pri_keys)
end


function _mt_out:writeTable(tbl)
	local pri_keys = self.pri_reg[tbl] or self.pri_reg[getmetatable(tbl)] or _dummy
	if type(pri_keys) ~= "table" then
		error(lang.err_priority_key_type)
	end

	if #pri_keys == 0 and _isArrayOnly(tbl) then
		local count = 0
		self:indent()

		for i, v in ipairs(tbl) do
			self:writeValue(v, pri_keys)

			if type(v) == "table" then
				count = 0
			end

			count = count + 1
			if i < #tbl then
				self:append(_sep .. (_cols > 0 and count % _cols == 0 and "" or _sp))
				if _cols > 0 and count % _cols == 0 then
					self:append(_lf)
					self:indent()
				end
			end
		end
		self:append(_lf)
	else
		-- hash table, or array that had priority keys
		local temp = #pri_keys > 0 and {} or tbl
		if #pri_keys > 0 then
			for k, v in pairs(tbl) do
				temp[k] = true
			end
			for i, k in ipairs(pri_keys) do
				local v = tbl[k]
				temp[k] = nil

				if v ~= nil then
					_hashWriteCode(self, tbl, k, pri_keys)
					self:append((next(temp) and _sep or "") .. _lf)

				elseif _missing_pri_fatal then
					error(interp(lang.err_missing_pri, k))
				end
			end
		end

		-- sort non-priority keys
		local sorted = {}
		for k, v in pairs(temp) do
			sorted[#sorted + 1] = k
		end
		table.sort(sorted, _sort)

		for i, k in ipairs(sorted) do
			_hashWriteCode(self, tbl, k, pri_keys)
			self:append((i < #sorted and _sep or "") .. _lf)
		end
	end
end


function _mt_out:writeValue(value)
	if type(value) == "string" then
		self:append(_formatStringDisplay(value))

	elseif type(value) == "number" then
		self:append(_formatNumber(value))

	elseif type(value) == "boolean" then
		self:append(tostring(value))

	elseif type(value) == "table" then
		if self.seen[value] then
			error(lang.err_cycle)
		end
		self.seen[value] = true

		if next(value) == nil then
			self:append("{}")
		else
			self:append("{" .. _lf)
			self.depth = self.depth + 1
			if _max_depth and self.depth > _max_depth then
				error(lang.err_max_depth)
			end

			self:writeTable(value)

			self.depth = self.depth - 1
			self:indent()
			self:append("}")
		end

	else
		error(interp(lang.err_bad_ser_val, type(value)))
	end
end


function M.serialize(t, pri_reg)
	_argType(1, t, "table")
	_argEval(2, pri_reg, "table")

	_updateRadixMark()

	local self = setmetatable({
		buf = {},
		buf_c = _buf_step,
		rope = {},
		seen = {},
		pri_reg = pri_reg or _dummy,
		depth = 1,
		bytes = 0,
	}, _mt_out)

	self:append("return" .. _sp .. "{" .. _lf)
	self:writeTable(t)
	self:append("}")

	self:checkBuf(true)

	return #self.rope > 1 and table.concat(self.rope) or self.rope[1]
end


return M
