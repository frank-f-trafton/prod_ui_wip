-- PILE Schema v1.315
-- (C) 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pAssert = require(PATH .. "pile_assert")


local ipairs, pairs, type = ipairs, pairs, type
local unpack = rawget(_G, "unpack") or table.unpack or error("couldn't find 'unpack' function")


M.lang = {
	bad_ref_type = "$1: (validator) expected reference to be a table, function, or string",
	bad_ref_fn = "$1: (validator) expected function or string ('sub', 'sub-eval') as element [1] in 'opts' table",
	invalid_md = "(validator) invalid Model",
	mismatch_len = "bad array length (expected $1, got $2)",
	mismatch_max_len = "array length ($1) is greater than the maximum ($2)",
	mismatch_min_len = "array length ($1) is under the minimum ($2)",
	missing_handler = "$1: missing Handler (or bad type)",
	msg_max = "(maximum message size reached)",
	unhandled_k = "unhandled key: $1"
}
local lang = M.lang


-- forward declarations
local _validateModel


local _default_max_msg = 500
M.max_messages = _default_max_msg -- must be at least 1


local _mt_md = {}


local function _assertModel(md)
	if getmetatable(md) ~= _mt_md then
		error(lang.invalid_md)
	end
end


local function _failure(state, err)
	if state.fatal then
		error(table.concat(state.labels, " > ") .. ": " .. tostring(err))

	elseif not state.messages[M.max_messages] then
		table.insert(state.messages, table.concat(state.labels, " > ") .. ": " .. tostring(err))
	end
end


local function _unpackRef(k, v)
	local ref, opts

	-- "short form" sub-model
	if getmetatable(v) == _mt_md then
		return "sub", v

	-- "short form" handler
	elseif type(v) == "function" then
		return v, false

	-- "long form" table
	elseif type(v) == "table" then
		ref, opts = v[1], v

		-- sub-model
		if ref == "sub" or ref == "sub-eval" then
			_assertModel(opts[2])
			return ref, opts[2]

		-- handler
		elseif type(ref) ~= "function" then
			error(interp(lang.bad_ref_fn, k))
		end

		return ref, opts

	-- invalid
	else
		error(interp(lang.bad_ref_type, k))
	end
end


local function _doRef(state, k, v, ref, opts)
	table.insert(state.labels, tostring(k))

	-- sub-models
	if ref == "sub" then
		_validateModel(state, opts, v)

	elseif ref == "sub-eval" then
		if v then
			_validateModel(state, opts, v)
		end

	-- handlers
	elseif type(ref) == "function" then
		local ok, err
		if type(opts) == "table" then
			ok, err = pcall(ref, nil, v, unpack(opts, 2))
		else
			ok, err = pcall(ref, nil, v)
		end

		if not ok then
			_failure(state, err)
		end

	-- invalid
	else
		_failure(state, interp(lang.missing_handler, k))
	end

	table.remove(state.labels)
end


_validateModel = function(state, md, tbl)
	_assertModel(md)

	local metatable, keys, array, remaining = md.metatable, md.keys, md.array, md.remaining

	if metatable then
		_doRef(state, nil, getmetatable(tbl), _unpackRef("(metatable)", metatable))
	end

	local pend = {}
	for k in pairs(tbl) do
		pend[k] = true
	end

	if keys then
		for k, ref in pairs(keys) do
			_doRef(state, k, tbl[k], _unpackRef(k, ref))
			pend[k] = nil
		end
	end

	if array then
		local len, arr_len, arr_min, arr_max = #tbl, md.array_len, md.array_min, md.array_max

		if arr_len and len ~= arr_len then
			_failure(state, interp(lang.mismatch_len, arr_len, len))

		elseif arr_min and len < arr_min then
			_failure(state, interp(lang.mismatch_min_len, len, arr_min))

		elseif arr_max and len > arr_max then
			_failure(state, interp(lang.mismatch_max_len, len, arr_max))

		else
			for i, v in ipairs(tbl) do
				if pend[i] then
					_doRef(state, i, v, _unpackRef("ref (Array)", array))
					pend[i] = nil
				end
			end
		end
	end

	if remaining then
		for k in pairs(pend) do
			_doRef(state, k, tbl[k], _unpackRef(k, remaining))
			pend[k] = nil
		end
	end

	if md.reject_unhandled and next(pend) then
		for k in pairs(pend) do
			_failure(state, interp(lang.unhandled_k, k))
		end
	end
end


function M.setMaxMessages(n)
	pAssert.integerGEEval(1, n, 1)

	M.max_messages = n or _default_max_msg
end


function M.getMaxMessages()
	return M.max_messages
end


function M.checkModel(md)
	pAssert.type(1, md, "table")

	pAssert.typeEval("(Model).reject_unhandled", md.reject_unhandled, "boolean")
	pAssert.typeEval("(Model).array_len", md.array_len, "number")
	pAssert.typeEval("(Model).array_min", md.array_min, "number")
	pAssert.typeEval("(Model).array_max", md.array_max, "number")

	if getmetatable(md) ~= _mt_md then
		error("wrong or missing 'model' metatable")
	end

	pAssert.typeEval("(Model).keys", md.keys, "table")

	if md.metatable then
		_unpackRef("(Model).metatable", md.metatable)
	end

	if md.keys then
		for k, v in pairs(md.keys) do
			_unpackRef(k, v)
		end
	end

	if md.array then
		_unpackRef("(Model).array", md.array)
	end

	if md.remaining then
		_unpackRef("(Model).remaining", md.remaining)
	end
end


function M.newModel(md)
	pAssert.tableWithoutMetatable(1, md)

	setmetatable(md, _mt_md)
	M.checkModel(md)

	return md
end


function M.newKeysX(keys)
	return M.newModel {
		reject_unhandled = true,
		keys = keys
	}
end


function M.validate(model, tbl, name, fatal)
	pAssert.typeEval(1, model, "table")
	_assertModel(model)
	pAssert.type(2, tbl, "table")
	pAssert.typeEval(3, name, "string")
	-- don't check 'fatal'

	local state = {
		labels = {name or nil},
		messages = {},
		fatal = not not fatal
	}

	_validateModel(state, model, tbl)

	if state.messages[1] then
		if #state.messages >= M.max_messages then
			table.insert(state.messages, lang.msg_max)
		end
		return false, table.concat(state.messages, "\n")
	end

	return true
end


return M
