-- PILE UTF-8 v1.1.3
-- (C) 2024 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local floor, char, concat, type = math.floor, string.char, table.concat, type


local lang = {
	arg_start_end_oob = "start index is greater than end index",
	byte_nil = "byte #$1 is nil",
	byte_cont_oob = "continuation byte #$1 ($2) is out of range (0x80 - 0xbf)",
	cp_oob = "code point is out of bounds",
	err_invalid = "invalid UTF-8 encoding",
	err_iter_codes = "index $1: $2",
	err_surrogate = "invalid code point (in surrogate range)",
	len_mismatch = "$1-byte length mismatch. Got: $2, must be in this range: $3 - $4",
	len_unknown = "unknown UTF-8 byte length marker",
	str_i_oob = "string index is out of bounds",
	trailing_1st = "trailing byte (2nd, 3rd or 4th) receieved as 1st",
	var_i_err = "argument $1: $2"
}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pArg = require(PATH .. "pile_arg_check")


local _argType1, _argInt, _argIntRange = pArg.type, pArg.int, pArg.intRange


local check_surrogates = true


local function getCheckSurrogates() return check_surrogates end
local function setCheckSurrogates(v) check_surrogates = not not v end


local function _0x(n) return ("0x%x"):format(n) end


-- Verifies code point length against allowed UTF-8 byte ranges (1, 2, 3, 4).
local min_max = {{0x0, 0x7f}, {0x80, 0x7ff}, {0x800, 0xffff}, {0x10000, 0x10ffff}}


local function _length(b)
	-- Byte length marker. Returns number on success, string on failure
	return b < 0x80 and 1
	or b >= 0xc0 and b < 0xe0 and 2
	or b >= 0xe0 and b < 0xf0 and 3
	or b >= 0xf0 and b < 0xf8 and 4
	or b >= 0x80 and b < 0xbf and "trailing_1st"
	or "len_unknown"
end


local function _cont(b, pos)
	-- Checks bytes 2-4 in a multi-byte code point
	-- Do not call on the first byte
	if not b then
		return true, interp(lang.byte_nil, pos)

	-- Verify "following" byte mark
	elseif b < 0x80 or b >= 0xc0 then
		return true, interp(lang.byte_cont_oob, pos, _0x(b))
	end
end


local function step(s, i)
	_argType1(1, s, "string")
	_argIntRange(2, i, 0, #s)

	while i < #s do
		i = i + 1
		if type(_length(s:byte(i))) == "number" then
			return i
		end
	end
end


local function stepBack(s, i)
	_argType1(1, s, "string")
	_argIntRange(2, i, 1, #s + 1)

	while i > 1 do
		i = i - 1
		if type(_length(s:byte(i))) == "number" then
			return i
		end
	end
end


local function _checkCode(c, len)
	if check_surrogates and c >= 0xd800 and c <= 0xdfff then
		return true, lang.err_surrogate
	end

	if c < 0 or c > 0x10ffff then
		return true, lang.cp_oob
	end

	-- Look for too-long or too-short values based on the byte count.
	-- (Only applicable if known to have originated from a UTF-8 sequence.)
	if len then
		local range = min_max[len]
		if c < range[1] or c > range[2] then
			return true, interp(lang.len_mismatch, len, _0x(c), _0x(range[1]), _0x(range[2]))
		end
	end
end


local function _codeFromStr(s, i)
	local b1 = s:byte(i)
	local len = _length(b1)
	local c, err, msg
	if type(len) == "string" then
		return nil, lang[len] or "?"

	elseif len == 1 then
		c = b1

	elseif len == 2 then
		local b2 = s:byte(i + 1)
		err, msg = _cont(b2, 2, 2) if err then return nil, msg end
		c = (b1 - 0xc0) * 0x40 + (b2 - 0x80)

	elseif len == 3 then
		local b2, b3 = s:byte(i + 1, i + 2)
		err, msg = _cont(b2, 2, 3) if err then return nil, msg end
		err, msg = _cont(b3, 3, 3) if err then return nil, msg end
		c = (b1 - 0xe0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)

	elseif len == 4 then
		local b2, b3, b4 = s:byte(i + 1, i + 3)
		err, msg = _cont(b2, 2, 4) if err then return nil, msg end
		err, msg = _cont(b3, 3, 4) if err then return nil, msg end
		err, msg = _cont(b4, 4, 4) if err then return nil, msg end
		c = (b1 - 0xf0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
	end

	err, msg = _checkCode(c, len)
	if err then
		return nil, msg
	end

	return c, len
end


local function check(s, i, j)
	_argType1(1, s, "string")
	i = i or (#s > 0 and 1 or 0)
	j = j or #s

	local n = 0

	if #s == 0 and i == 0 and j == 0 then
		return n
	end

	_argIntRange(2, i, 1, #s)
	_argIntRange(3, j, 1, #s)
	if i > j then error(lang.arg_start_end_oob) end

	while i <= j do
		local c, len = _codeFromStr(s, i)
		if not c then
			return nil, len, i -- len: error string
		end
		i = i + len
		n = n + 1
	end

	return n
end


local function scrub(s, repl)
	_argType1(1, s, "string")
	_argType1(2, repl, "string")

	local t, i = {}, 1

	while i <= #s do
		local j, _, bad_i = check(s, i)
		if not j then
			t[#t + 1] = s:sub(i, bad_i - 1)
			t[#t + 1] = repl
			i = step(s, bad_i)
		else
			t[#t + 1] = s:sub(i)
			break
		end
	end

	return concat(t)
end


local function codeFromString(s, i)
	_argType1(1, s, "string")
	i = i == nil and 1 or i
	_argInt(2, i, "number")
	if i < 1 or i > #s then error(interp(lang.str_i_oob)) end

	local c, len = _codeFromStr(s, i)

	if not c then
		return nil, len -- error string
	end

	return c, s:sub(i, i + len - 1)
end


local function stringFromCode(c)
	_argInt(1, c)

	local err, msg = _checkCode(c, nil)
	if err then
		return nil, msg

	elseif c < 0x80 then
		return char(c)

	elseif c < 0x800 then
		return char(
			0xc0 + floor(c / 0x40),
			0x80 + (c % 0x40)
		)

	elseif c < 0x10000 then
		return char(
			0xe0 + floor(c / 0x1000),
			0x80 + floor( (c % 0x1000) / 0x40),
			0x80 + (c % 0x40)
		)

	elseif c <= 0x10ffff then
		return char(
			0xf0 + floor(c / 0x40000),
			0x80 + floor((c % 0x40000) / 0x1000),
			0x80 + floor((c % 0x1000) / 0x40),
			0x80 + (c % 0x40)
		)
	end
end


local function _codes(s, i)
	if i > #s then
		return
	end
	local c, s2 = codeFromString(s, i)
	if not c then
		error(interp(lang.err_iter_codes, i, s2))
	end
	return i + #s2, c, s2
end


local function codes(s)
	_argType1(1, s, "string")

	return _codes, s, 1
end


local function concatCodes(...)
	local t = {...}
	for i = 1, #t do
		local s, err = stringFromCode(t[i])
		if not s then
			error(interp(lang.var_i_err, i, err))
		end
		t[i] = s
	end
	return concat(t)
end


return {
	lang = lang,
	getCheckSurrogates = getCheckSurrogates,
	setCheckSurrogates = setCheckSurrogates,
	step = step,
	stepBack = stepBack,
	check = check,
	scrub = scrub,
	codeFromString = codeFromString,
	stringFromCode = stringFromCode,
	codes = codes,
	concatCodes = concatCodes
}
