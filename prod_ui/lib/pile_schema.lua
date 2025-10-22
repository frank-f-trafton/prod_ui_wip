-- PILE Schema v1.310
-- (C) 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pArg = require(PATH .. "pile_arg_check")
local pTable = require(PATH .. "pile_table")


local ipairs, pairs, type = ipairs, pairs, type
local _pArg_type, _pArg_typeEval = pArg.type, pArg.typeEval


M.lang = {
	bad_ref_type = "expected reference to be a table, function, or string. Key: $1",
	bad_ref_fn = "expected function as element [1] in opts table",
	bad_t_ref = "expected reference '$1' to lead to a table. (Key: '$2')",
	invalid_md_mode = "invalid Model mode: $1",
	mismatch_len = "bad array length (expected $1, got $2)",
	mismatch_max_len = "array length ($1) is greater than the maximum ($2)",
	mismatch_min_len = "array length ($1) is under the minimum ($2)",
	missing_handler = "missing Handler (or bad type) for key: $1",
	missing_md = "missing model: $1",
	missing_opts = "missing 'opts' table (this Handler doesn't support short form notation)",
	missing_sub_t = "Handler Reference is missing a sub-table: $1",
	unhandled_k = "unhandled key: $1"
}
local lang = M.lang


local function _unpackRef(k, v)
	local ref, opts
	-- model reference
	if type(v) == "string" then
		ref = v

	-- standalone handler
	elseif type(v) == "function" then
		ref, opts = v, false

	-- handler with options
	elseif type(v) == "table" then
		ref, opts = v[1], v
		if type(ref) ~= "function" then
			error(lang.bad_ref_fn)
		end

	else
		error(interp(lang.bad_ref_type, k))
	end

	return ref, opts
end


local function _doModel(vd, vs, md_id, tbl)
	local md = vd.models[md_id]
	if not md then
		vd:_failure(vs, interp(lang.missing_md, md_id))
	else
		md:validate(vd, vs, tbl)
	end
end


local function _doRef(vd, vs, tbl, k, v, ref, opts)
	table.insert(vs.ks, tostring(k))

	-- model reference
	if type(ref) == "string" then
		if type(v) ~= "table" then
			vd:_failure(vs, interp(lang.bad_t_ref, ref, k))
		else
			_doModel(vd, vs, ref, tbl[k])
		end

	-- handler
	elseif type(ref) == "function" then
		local ok, err = ref(k, v, opts, vd.user, tbl)
		if ok ~= true then
			vd:_failure(vs, tostring(err))
		end

	else
		vd:_failure(vs, interp(lang.missing_handler, k))
	end

	table.remove(vs.ks)
end


local function _assertNoPend(vd, vs, pend)
	for k in pairs(pend) do
		vd:_failure(vs, interp(lang.unhandled_k, k))
	end
end


local function _modelTestArrayOptions(vd, vs, md, len)
	local arr_len, arr_min, arr_max = md.len, md.min, md.max

	if arr_len and len ~= arr_len then
		vd:_failure(vs, interp(lang.mismatch_len, arr_len, len))

	elseif arr_min and len < arr_min then
		vd:_failure(vs, interp(lang.mismatch_min_len, len, arr_min))

	elseif arr_max and len > arr_max then
		vd:_failure(vs, interp(lang.mismatch_max_len, len, arr_max))

	else
		return true
	end
end


local function _modelDoMetatable(vd, vs, md, tbl)
	_doRef(vd, vs, tbl, nil, getmetatable(tbl), _unpackRef("(metatable)", md.metatable))
end


local function _modelCheckMetatable(self)
	_unpackRef("(Metatable)", self.metatable)
end


local function _modelCheckKeys(keys)
	_pArg_type("(Keys table)", keys, "table")

	for k, v in pairs(keys) do
		_unpackRef(k, v)
	end
end


local function _modelCheckArray(self)
	local L = pArg.L
	L[1] = "(Array)"
	L[2] = "len"; _pArg_typeEval(L, self.len, "number")
	L[2] = "min"; _pArg_typeEval(L, self.min, "number")
	L[2] = "max"; _pArg_typeEval(L, self.max, "number")

	_unpackRef("(Array)", self.ref)
end


local function _modelCheckAll(self)
	_unpackRef("(All)", self.ref)
end


local _mt_md = {
	keys = {
		check = function(self)
			_modelCheckKeys(self)
		end,

		validate = function(self, vd, vs, tbl)
			for k, ref in pairs(self) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
			end
		end
	},

	keysX = {
		check = function(self)
			_modelCheckKeys(self)
		end,

		validate = function(self, vd, vs, tbl)
			local pend = pTable.copy(tbl)
			for k, ref in pairs(self) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
				pend[k] = nil
			end
			_assertNoPend(vd, vs, pend)
		end
	},

	keysM = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckKeys(self.keys)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			for k, ref in pairs(self.keys) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
			end
		end
	},

	keysMX = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckKeys(self.keys)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			local pend = pTable.copy(tbl)
			for k, ref in pairs(self.keys) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
				pend[k] = nil
			end
			_assertNoPend(vd, vs, pend)
		end
	},

	array = {
		check = function(self)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
				end
			end
		end
	},

	arrayX = {
		check = function(self)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			local pend = pTable.copy(tbl)
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
					pend[i] = nil
				end
				_assertNoPend(vd, vs, pend)
			end
		end
	},

	arrayM = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
				end
			end
		end
	},

	arrayMX = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			local pend = pTable.copy(tbl)
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
					pend[i] = nil
				end
				_assertNoPend(vd, vs, pend)
			end
		end
	},

	mixed = {
		check = function(self)
			_modelCheckKeys(self.keys)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			local keys = self.keys
			for k, ref in pairs(keys) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
			end
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					if not keys[i] then
						_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
					end
				end
			end
		end
	},

	mixedX = {
		check = function(self)
			_modelCheckKeys(self.keys)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			local pend = pTable.copy(tbl)
			local keys = self.keys
			for k, ref in pairs(keys) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
				pend[k] = nil
			end
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					if not keys[i] then
						_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
						pend[i] = nil
					end
				end
				_assertNoPend(vd, vs, pend)
			end
		end
	},

	mixedM = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckKeys(self.keys)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			local keys = self.keys
			for k, ref in pairs(keys) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
			end
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					if not keys[i] then
						_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
					end
				end
			end
		end
	},

	mixedMX = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckKeys(self.keys)
			_modelCheckArray(self)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			local pend = pTable.copy(tbl)
			local keys = self.keys
			for k, ref in pairs(keys) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
				pend[k] = nil
			end
			if _modelTestArrayOptions(vd, vs, self, #tbl) then
				for i, v in ipairs(tbl) do
					if not keys[i] then
						_doRef(vd, vs, tbl, i, v, _unpackRef("(array)", self.ref))
						pend[i] = nil
					end
				end
				_assertNoPend(vd, vs, pend)
			end
		end
	},

	all = {
		check = function(self)
			_modelCheckAll(self)
		end,

		validate = function(self, vd, vs, tbl)
			local ref = self.ref
			for k in pairs(tbl) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
			end
		end
	},

	allM = {
		check = function(self)
			_modelCheckMetatable(self)
			_modelCheckAll(self)
		end,

		validate = function(self, vd, vs, tbl)
			_modelDoMetatable(vd, vs, self, tbl)
			local ref = self.ref
			for k in pairs(tbl) do
				_doRef(vd, vs, tbl, k, tbl[k], _unpackRef(k, ref))
			end
		end
	}
}


for k, v in pairs(_mt_md) do
	v.__index = v
end


local function _bindMT(t, id)
	_pArg_type(1, t, "table")

	local mt = _mt_md[id]

	if not mt then
		error(interp(lang.invalid_md_mode, id))
	end

	setmetatable(t, mt)
	t:check()

	return t
end


M.models = {
	keys = function(t) return _bindMT(t, "keys") end,
	keysX = function(t) return _bindMT(t, "keysX") end,
	keysM = function(t) return _bindMT(t, "keysM") end,
	keysMX = function(t) return _bindMT(t, "keysMX") end,
	array = function(t) return _bindMT(t, "array") end,
	arrayX = function(t) return _bindMT(t, "arrayX") end,
	arrayM = function(t) return _bindMT(t, "arrayM") end,
	arrayMX = function(t) return _bindMT(t, "arrayMX") end,
	mixed = function(t) return _bindMT(t, "mixed") end,
	mixedX = function(t) return _bindMT(t, "mixedX") end,
	mixedM = function(t) return _bindMT(t, "mixedM") end,
	mixedMX = function(t) return _bindMT(t, "mixedMX") end,
	all = function(t) return _bindMT(t, "all") end,
	allM = function(t) return _bindMT(t, "allM") end
}


M.handlers = {
	types = function(k, v, opts)
		M.assertOpts(opts)

		for i = 2, #opts do
			if type(v) == opts[i] then
				return true
			end
		end

		return false, "expected type: " .. pTable.safeTableConcat(opts, ", ", 2)
	end,

	number = function(k, v, opts)
		if type(v) ~= "number" then
			return false, "expected number"
		end

		local min, max = -math.huge, math.huge
		if opts then
			min = opts.min or min
			max = opts.max or max
		end

		if v < min or v > max then
			return false, "number is out of range"
		end

		return true
	end,

	numberEval = function(k, v, opts)
		if v then
			return M.handlers.number(k, v, opts)
		end

		return true
	end,

	integer = function(k, v, opts)
		if type(v) ~= "number" or math.floor(v) ~= v then
			return false, "expected integer"
		end

		local min, max = -math.huge, math.huge
		if opts then
			min = opts.min or min
			max = opts.max or max
		end

		if v < min or v > max then
			return false, "integer is out of range"
		end

		return true
	end,

	integerEval = function(k, v, opts)
		if v then
			return M.handlers.integer(k, v, opts)
		end

		return true
	end,

	string = function(k, v, opts)
		if type(v) ~= "string" then
			return false, "expected string"
		end

		if opts and opts[2] then
			for i = 2, #opts do
				if v:match(opts[i]) then
					return true
				end
			end

			return false, "string failed pattern match"
		end

		return true
	end,

	stringEval = function(k, v, opts)
		if v then
			return M.handlers.string(k, v, opts)
		end

		return true
	end,

	table = function(k, v) return M.simpleTypeCheck("table", v) end,
	tableEval = function(k, v) return M.simpleTypeCheck("table", v, true) end,
	["function"] = function(k, v) return M.simpleTypeCheck("function", v) end,
	functionEval = function(k, v) return M.simpleTypeCheck("function", v, true) end,
	userdata = function(k, v) return M.simpleTypeCheck("userdata", v) end,
	userdataEval = function(k, v) return M.simpleTypeCheck("userdata", v, true) end,
	cdata = function(k, v) return M.simpleTypeCheck("cdata", v) end, -- LuaJIT
	cdataEval = function(k, v) return M.simpleTypeCheck("cdata", v, true) end, -- LuaJIT
	thread = function(k, v) return M.simpleTypeCheck("thread", v) end,
	threadEval = function(k, v) return M.simpleTypeCheck("thread", v, true) end,
	boolean = function(k, v) return M.simpleTypeCheck("boolean", v) end,
	booleanEval = function(k, v) return M.simpleTypeCheck("boolean", v, true) end,
	["nil"] = function(k, v) return M.simpleTypeCheck("nil", v) end,

	notNil = function(k, v)
		if v == nil then
			return false, "expected non-nil value"
		end

		return true
	end,

	notFalseNotNil = function(k, v)
		if not v then
			return false, "expected non-false, non-nil value"
		end

		return true
	end,

	notFalseNotNilNotNan = function(k, v)
		if not v or v ~= v then
			return false, "expected non-false, non-nil, non-NaN value"
		end

		return true
	end,

	this = function(k, v, opts)
		M.assertOpts(opts)

		local here = opts[2]

		if v == here then
			return true
		end

		return false, "expected: " .. tostring(here)
	end,

	oneOf = function(k, v, opts)
		M.assertOpts(opts)

		for i = 2, #opts do
			if v == opts[i] then
				return true
			end
		end

		return false, "expected one of: " .. pTable.safeTableConcat(opts, ", ", 2)
	end,

	enum = function(k, v, opts)
		M.assertOpts(opts)
		local enum = M.assertOptsSub(opts, 2)

		if enum[v] then
			return true
		end

		return false, "invalid " .. pTable.safeGetEnumName(enum)
	end,

	enumEval = function(k, v, opts)
		M.assertOpts(opts)
		local enum = M.assertOptsSub(opts, 2)

		if v or enum[v] then
			return true
		end

		return false, "expected false/nil or " .. pTable.safeGetEnumName(enum)
	end,

	choice = function(k, v, opts, user)
		M.assertOpts(opts)

		local errors = {}
		for i = 2, #opts do
			local ref2, opts2 = _unpackRef("(choice)", opts[i])
			local ok, err = ref2(k, v, opts2, user)
			if ok then
				return true
			end
			table.insert(errors, "#" .. i - 1 .. ": " .. err)
		end

		return false, "multi-choice failed. Errors: " .. pTable.safeTableConcat(errors, "; ")
	end,

	pass = function() return true end,
	fail = function(k) return false, "rejected key" end,
}


local _mt_vd = {}
_mt_vd.__index = _mt_vd


function M.newValidator(name, models)
	_pArg_typeEval(1, name, "string")
	_pArg_typeEval(2, models, "table")

	return setmetatable({
		models = models or {},
		name = name or "Unnamed",
		user = false,
	}, _mt_vd)
end


function M.assertOpts(opts)
	if type(opts) ~= "table" then
		error(interp(lang.missing_opts))
	end
end


function M.assertOptsSub(opts, k)
	local tt = opts[k]
	if type(tt) ~= "table" then
		error(interp(lang.missing_sub_t, k))
	end
	return tt
end


function M.simpleTypeCheck(typ, v, eval)
	if eval and not v then
		return true
	end

	if type(v) ~= typ then
		return false, "expected " .. typ
	end

	return true
end


function _mt_vd:setName(name)
	_pArg_type(1, name, "string")

	self.name = name

	return self
end


function _mt_vd:getName()
	return self.name
end


function _mt_vd:setModel(id, md)
	_pArg_type(1, id, "string")
	_pArg_typeEval(2, md, "table")

	if md then
		md:check()
		self.models[id] = md
	else
		self.models[id] = nil
	end

	return self
end


function _mt_vd:getModel(id)
	return self.models[id]
end


function _mt_vd:setUserTable(user)
	_pArg_typeEval(1, user, "table")

	self.user = user or false

	return self
end


function _mt_vd:getUserTable()
	return self.user
end


function _mt_vd:validate(tbl, model_id, fatal)
	_pArg_type(1, tbl, "table")
	_pArg_typeEval(2, model_id, "string")

	model_id = model_id or "main"

	local vs = {
		fatal = fatal,
		msg = false,
		ks = {self.name}
	}

	_doModel(self, vs, model_id, tbl)

	local msg = vs.msg
	if msg then
		return false, msg
	end

	return true
end


function _mt_vd:_failure(vs, str)
	str = table.concat(vs.ks, " > ") .. ": " .. str

	if vs.fatal then
		error(str)
	else
		vs.msg = vs.msg or {}
		table.insert(vs.msg, str)
	end
end


return M