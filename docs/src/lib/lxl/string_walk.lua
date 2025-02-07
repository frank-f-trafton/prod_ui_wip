-- stringWalk v2.1.2
-- https://www.github.com/rabbitboots/string_walk


--[[
Copyright (c) 2022 - 2024 RBTS

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


local stringWalk = {}


stringWalk.lang = {
	arg_bad_int = "argument #$1: expected integer.",
	arg_bad_type = "argument #$1: bad type (expected $2, got $3)",
	bytes_lt_1 = "the number of bytes to read must be at least 1.",
	err_st_bound = "state assertion: bad number for '$1'",
	err_st_non_int = "state assertion: non-integer for '$1'",
	err_st_type = "state assertion: bad type for '$1'",
	err_stack_empty = "tried to pop an empty stack",
	errmsg_terse = "parsing failed",
	fail_assert = "assertion failed",
	fail_req = "required method call failed",
	fail_byte_req = "required byte() search failed",
	fail_find_req = "required find() search failed",
	fail_lit_req = "required literal() search failed",
	fail_match_req = "required match() search failed",
	fail_ws_req = "required whitespace not found",
	line_info_unk = "Unknown",
	msg_line = "line $1: ",
	msg_line_char = "line $1, character $2: ",
	msg_index = "index #$1: ",
	warn = "[WARNING]"
}
local lang = stringWalk.lang


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pArg = require(PATH .. "pile_arg_check")
local interp = require(PATH .. "pile_interp")


local _argType, _argInt = pArg.type, pArg.int


stringWalk.ws1 = "[^\t\f\v\r\n\32]" -- "%S"
stringWalk.ws2 = "^[\t\f\v\r\n\32]" -- "^%s"
stringWalk.ws3 = "[\t\f\v\r\n\32]" -- "%s"
stringWalk.ptn_code = "^[%z\1-\127\194-\244][\128-\191]*"


local _mt_walk = {}
_mt_walk.__index = _mt_walk


-- Checks the reader object internal state.
local function _ok(W)
	if type(W._st) ~= "table" then
		error(interp(lang.err_st_type, "_st (stack)"), 2)

	elseif type(W.S) ~= "string" then
		error(interp(lang.err_st_type, "S"), 2)

	elseif type(W.I) ~= "number" then
		error(interp(lang.state_assert_type, "I"), 2)

	elseif W.I ~= math.floor(W.I) then
		error(interp(lang.err_st_non_int, "I"), 2)

	elseif W.I < 1 then
		error(interp(lang.err_st_bound, "I"), 2)
	end
	-- 'I' being beyond #S is considered 'eos'
end


function stringWalk.countLineChar(s, i, j, ln, cn)
	-- on the first call, j, ln, cn == 1, 1, 1

	-- count line feeds
	while true do
		local n = s:match("\r?\n()", j)
		if not n or n > i then
			break
		end
		cn, ln, j = 1, ln + 1, n
	end

	-- count characters (UTF-8 non-continuation bytes)
	while true do
		local n = s:find("[^\128-\191]", j)
		if not n or n >= i then
			break
		end
		j, cn = n + 1, cn + 1
	end

	return ln, cn
end


local function _baseInfo(W)
	local s, i
	local fr1 = W._st[1]
	if fr1 then
		s, i = fr1[1], fr1[2]
	else
		s, i = W.S, W.I
	end
	return s, i
end


-- This function should avoid causing Lua errors.
local function _getPosInfo(W)
	local s, i = _baseInfo(W)
	if W._bmode then
		return lang.msg_index, i

	elseif not W._ln then
		return ""
	end

	local ln, cn
	if type(s) ~= "string" or type(i) ~= "number" then
		local unk = lang.line_info_unk
		ln, cn = unk, unk
	else
		ln, cn = stringWalk.countLineChar(s, i, 1, 1, 1)
	end

	if not W._cn then
		return lang.msg_line, ln
	end

	return lang.msg_line_char, ln, cn
end


function _mt_walk.push(W, s)
	table.insert(W._st, {W.S, W.I})
	W.S, W.I = s, 1
end


function _mt_walk.pop(W)
	if #W._st == 0 then error(lang.err_stack_empty) end
	local fr = table.remove(W._st)
	W.S, W.I = fr[1], fr[2]
end


function _mt_walk.popAll(W)
	while #W._st > 0 do
		W:pop()
	end
end


function stringWalk.new(s)
	if s ~= nil then _argType(1, s, "string") end

	local W = {
		S = s or "",
		I = 1,
		_st = {}, -- stack
		_terse = false, -- terse mode
		_bmode = false, -- byte mode
		_ln = true, -- show line num
		_cn = true -- show char num
	}

	return setmetatable(W, _mt_walk)
end


function _mt_walk.newString(W, s)
	_argType(1, s, "string")

	W:popAll()
	W.S, W.I = s, 1
end


function _mt_walk.reset(W)
	W:popAll()
	W.I = 1

	_ok(W)
end


function _mt_walk.setTerseMode(W, enabled)
	W._terse = not not enabled
end


function _mt_walk.setByteMode(W, enabled)
	W._bmode = not not enabled
end


function _mt_walk.setLineCharDisplay(W, line, char)
	W._ln = not not line
	W._cn = not not char
end


function _mt_walk.find(W, ptn)
	_ok(W)

	local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r = W.S:find(ptn, W.I)
	if a then
		W.I = b + 1
	end
	return a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r
end


function _mt_walk.findReq(W, ptn, plain, err)
	return W:req(W.find, err or lang.fail_find_req, ptn, plain)
end


function _mt_walk.plain(W, ptn)
	_ok(W)

	local a,b = W.S:find(ptn, W.I, true)
	if a then
		W.I = b + 1
	end
	return a,b
end


function _mt_walk.plainReq(W, ptn, err)
	return W:req(W.plain, err or lang.fail_find_req, ptn)
end


function _mt_walk.lit(W, s)
	_ok(W)

	local ok = W.S:sub(W.I, W.I + #s - 1) == s
	if ok then
		W.I = W.I + #s
		return s
	end
end


function _mt_walk.litReq(W, s, err)
	return W:req(W.lit, err or lang.fail_lit_req, s)
end


function _mt_walk.match(W, ptn)
	_ok(W)

	local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r = W:find(ptn)
	-- Behave like string.match()
	if a and not c then
		c = W.S:sub(a, b)
	end
	return c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r
end


function _mt_walk.matchReq(W, ptn, err)
	return W:req(W.match, err or lang.fail_match_req, ptn)
end


local function _seek(W, n)
	W.I = math.max(1, math.min(n, #W.S + 1))
	return W.I
end


function _mt_walk.seek(W, n)
	_ok(W)
	n = n or 1
	_argInt(1, n)

	return _seek(W, n or 1)
end


function _mt_walk.step(W, n)
	_ok(W)
	n = n or 1
	_argInt(1, n)

	return _seek(W, W.I + n)
end


function _mt_walk.peek(W, n)
	_ok(W)
	n = n or 1
	_argInt(1, n)
	if n < 1 then error(lang.bytes_lt_1) end

	return W.S:sub(W.I, W.I + n-1)
end


function _mt_walk.bytes(W, n)
	_ok(W)
	n = n or 1
	_argInt(1, n)
	if n < 1 then error(lang.bytes_lt_1) end

	if W.I + n - 1 <= #W.S then
		local rv = W.S:sub(W.I, W.I + n - 1)
		W.I = W.I + n
		return rv
	end
end


function _mt_walk.bytesReq(W, n, err)
	return W:req(W.bytes, err or lang.fail_byte_req, n)
end


function _mt_walk.ws(W)
	_ok(W)

	local old_pos = W.I
	local i = W.S:find(stringWalk.ws1, W.I)

	W.I = i or #W.S + 1

	return W.I ~= old_pos
end


function _mt_walk.wsReq(W, err)
	return W:req(W.ws, err or lang.fail_ws_req)
end


function _mt_walk.wsNext(W)
	_ok(W)

	if W.S:find(stringWalk.ws2, W.I) then
		return
	end

	local i = W.S:find(stringWalk.ws3, W.I + 1)
	W.I = i or #W.S + 1
end


function _mt_walk.isEOS(W)
	_ok(W)

	return W.I > #W.S
end


function _mt_walk.goEOS(W)
	W.I = #W.S + 1
end


function _mt_walk.error(W, s, level)
	if W._terse then
		error(lang.errmsg_terse)
	end

	local msg_str, a, b = _getPosInfo(W)
	error(interp(msg_str, a, b) .. tostring(s), tonumber(level) or 2)
end


function _mt_walk.warn(W, ...)
	if W._terse then
		return
	end

	local msg_str, a, b = _getPosInfo(W)
	io.write(lang.warn .. " " .. interp(msg_str, a, b))
	print(...)
end


function _mt_walk.getLineCharNumbers(W)
	_ok(W)

	local s, i = _baseInfo(W)
	local ln, cn = stringWalk.countLineChar(s, i, 1, 1, 1)
	return ln, cn
end


function _mt_walk.getIndex(W)
	_ok(W)

	return W.I
end


function _mt_walk._status(W)
	_ok(W)
	local ln, cn = W:getLineCharNumbers()
	print("BYTE: " .. tostring(W.I) .. "/" .. tostring(#W.S) .. " LINE: " .. ln .. " CHAR: " .. cn)
	for i, fr in ipairs(W._st) do
		print("  STACK #" .. i .. ": BYTE: " .. fr[2] .. "/" .. #fr[1])
	end
end


function _mt_walk.req(W, fn, err, ...)
	_ok(W)

	local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r = fn(W, ...)
	if not a then
		W:error(err or lang.fail_req, 3)
	end
	return a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r
end


function _mt_walk.assert(W, eval, err)
	if not eval then
		W:error(err or lang.fail_assert, 3)
	end
	return eval
end


return stringWalk
