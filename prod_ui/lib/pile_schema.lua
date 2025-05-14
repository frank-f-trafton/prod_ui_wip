-- PILE Schema v0.0.0 (prerelease)
-- (C) 2025 PILE Contributors
-- License: MIT or MIT-0
-- (Not yet added to the official repository.)


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pArg = require(PATH .. "pile_arg_check")
local interp = require(PATH .. "pile_interp")


M.lang = {
	bad_fn = "expected function. Index: $1",
	bad_id_type = "expected string for ID handler. Key: $1",
	bad_len = "exact length: expected nil/false or number",
	bad_max_len = "maximum length: expected number",
	bad_min_len = "minimum length: expected number",
	bad_ptn = "expected string for pattern. Index: $1",
	bad_req_key = "expected nil or boolean for 'required' in key: $1",
	bad_t_ref = "expected reference '$1' to lead to a table. (Key: '$2')",
	bad_t_type = "expected table at index $1",
	mismatch_len = "bad sequence length (expected $1, got $2)",
	mismatch_max_len = "sequence length ($1) is greater than the maximum ($2)",
	mismatch_min_len = "sequence length ($1) is under the minimum ($2)",
	missing_handler = "missing handler (or bad type) for key: $1",
	missing_sub = "no sub-schema table with key: $1",
	req_key_missing = "missing required key: $1",
	unhandled_key = "unhandled key: $1"
}
local lang = M.lang


local _mt_pro = {}
_mt_pro.__index = _mt_pro


function M.newProcessor(schema, handlers, name)
	pArg.type1(1, schema, "table")
	pArg.type1(2, handlers, "table")
	pArg.typeEval1(3, name, "string")

	return setmetatable({
		schema=schema,
		handlers=handlers,
		name=name or "Schema"
	}, _mt_pro)
end


local function _checkID(id, k)
	if type(id) ~= "string" then
		error(interp(lang.bad_id_type, k))
	end
end


local function _checkTable(t, i)
	if type(t) ~= "table" then
		error(interp(lang.bad_t_type, i))
	end
end


function _mt_pro:error(s, l)
	l = l or 1
	error(s, l + 1)
end


function _mt_pro:_formatError(key_stack, s)
	error(self.name .. ": " .. table.concat(key_stack, ".") .. ": " .. s, 2)
end


function _mt_pro:_handler(tbl, id, k, v, opts, key_stack)
	--[[DBG]] print("_handler: start (depth " .. #key_stack .. ")")
	--[[DBG]] print("", "id", id, "k", k, "v", v)
	local schema, handlers = self.schema, self.handlers
	if type(id) == "string" and id:sub(1, 1) == "&" then
		if type(tbl[k]) ~= "table" then
			self:_formatError(key_stack, interp(lang.bad_t_ref, id, k))
		else
			table.insert(key_stack, tostring(k))
			self:_comp(tbl[k], id:sub(2), key_stack)
			table.remove(key_stack)
		end
	else
		if not handlers[id] or type(handlers[id]) ~= "function" then
			self:_formatError(key_stack, interp(lang.missing_handler, k))
		else
			local ok, err = handlers[id](tbl, k, v, opts)
			if not ok then
				self:_formatError(key_stack, tostring(err))
			end
		end
	end
	--[[DBG]] print("_handler: end (depth " .. #key_stack .. ")")
end


function _mt_pro:_comp(tbl, sub_id, key_stack)
	--[[DBG]] print("_comp: start (depth " .. #key_stack .. ")")
	--[[DBG]] print("", "sub_id", sub_id)
	local schema, handlers = self.schema, self.handlers
	local sub = schema[sub_id]
	if not sub then
		self:_formatError(key_stack, interp(lang.missing_sub, sub_id))
	else
		local pending = {}
		for k in pairs(tbl) do
			pending[k] = true
		end

		if sub.keys then
			for k, opts in pairs(sub.keys) do
				local id, required = opts.id, opts.required
				_checkID(id, k)
				if required ~= nil and type(required) ~= "boolean" then
					error(interp(lang.bad_req_key, k))
				end

				if required and not pending[k] then
					self:_formatError(key_stack, interp(lang.req_key_missing, k))

				elseif pending[k] then
					self:_handler(tbl, id, k, tbl[k], opts, key_stack)
					pending[k] = nil
				end
			end
		end

		if sub.sequence then
			local opts = sub.sequence
			_checkTable(opts, "(sequence)")
			local id, len, min_len, max_len = opts.id, opts.length, opts.minimum_length or 0, opts.maximum_length or math.huge
			_checkID(id, "(sequence)")

			if len and type(len) ~= "number" then
				error(lang.bad_len)

			elseif type(min_len) ~= "number" then
				error(lang.bad_min_len)

			elseif type(max_len) ~= "number" then
				error(lang.bad_max_len)
			end

			if len and #tbl ~= len then
				self:_formatError(key_stack, interp(lang.mismatch_len, len, #tbl))

			elseif #tbl > max_len then
				self:_formatError(key_stack, interp(lang.mismatch_max_len, #tbl, max_len))

			elseif #tbl < min_len then
				self:_formatError(key_stack, interp(lang.mismatch_min_len, #tbl, min_len))
			end

			for i, v in ipairs(tbl) do
				if pending[i] then
					self:_handler(tbl, id, i, v, opts, key_stack)
					pending[i] = nil
				end
			end
		end

		if sub.patterns then
			for i, opts in ipairs(sub.patterns) do
				_checkTable(opts, i)
				_checkID(opts.id, i)
				if type(opts.pattern) ~= "string" then
					error(interp(lang.bad_ptn, i))
				end
			end

			for k in pairs(pending) do
				if type(k) == "string" then
					for i, opts in ipairs(sub.patterns) do
						local id, ptn = opts.id, opts.pattern
						if k:match(ptn) then
							self:_handler(tbl, id, k, tbl[k], opts, key_stack)
							pending[k] = nil
						end
					end
				end
			end
		end

		if sub.functions then
			for i, opts in ipairs(sub.functions) do
				_checkTable(opts, i)
				_checkID(opts.id, i)
				if type(opts.func) ~= "function" then
					error(interp(lang.bad_fn, i))
				end
			end

			for k in pairs(pending) do
				for i, opts in ipairs(sub.functions) do
					local id, fn = opts.id, opts.func
					if fn(k, tbl[k], opts) then
						self:_handler(tbl, id, k, tbl[k], opts, key_stack)
						pending[k] = nil
					end
				end
			end
		end

		if sub.any then
			local opts = sub.any
			_checkTable(opts, "(any)")
			local id = opts.id
			_checkID(id, "(any)")

			for k in pairs(pending) do
				self:_handler(tbl, id, k, tbl[k], opts, key_stack)
				pending[k] = nil
			end
		end

		for k in pairs(pending) do
			self:_formatError(key_stack, interp(lang.unhandled_key, k))
		end
	end
	--[[DBG]] print("_comp: end (depth " .. #key_stack .. ")")
end


function _mt_pro:compare(tbl, name_for_errors)
	pArg.type1(1, tbl, "table")
	pArg.typeEval1(2, name_for_errors, "string")

	name_for_errors = name_for_errors or "(table)"
	self:_comp(tbl, "main", {name_for_errors})
end


return M
