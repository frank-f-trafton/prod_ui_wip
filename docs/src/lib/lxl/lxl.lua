-- Lua XML Library v2.0.5
-- https://github.com/rabbitboots/lxl


--[[
MIT License

Copyright (c) 2022 - 2025 RBTS

Code from github.com/kikito/utf8_validator.lua:
Copyright (c) 2013 Enrique García Cota + Adam Baldwin + hanzao + Equi 4 Software

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


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local lxl = {}


local interp = require(PATH .. "pile_interp")
local namespace = require(PATH .. "lxl_namespace")
local shared = require(PATH .. "lxl_shared")
local struct = require(PATH .. "lxl_struct")
local xIn = require(PATH .. "lxl_in")
local xOut = require(PATH .. "lxl_out")


local lang = shared.lang
local _argType = require(PATH .. "pile_arg_check").type


local _mt_parser = {}
_mt_parser.__index = _mt_parser


function lxl.newParser()
	return setmetatable({
		-- reading in
		check_characters = true,
		check_encoding_mismatch = true,
		collect_comments = true,
		collect_pi = true,
		copy_doctype = false,
		max_entity_bytes = math.huge,
		namespace_mode = nil, -- nil, "1.0", "1.1"
		normalize_line_endings = true,
		reject_doctype = false,
		reject_internal_subset = false,
		reject_unexp_ent = false,
		warn_dupe_decl = false,

		-- writing out
		out_big_endian = false,
		out_doc_type = false,
		out_indent_ch = " ",
		out_indent_qty = 1,
		out_pretty = true,
		out_xml_decl = true
	}, _mt_parser)
end


function _mt_parser:setCheckCharacters(v)
	self.check_characters = not not v
end


function _mt_parser:getCheckCharacters()
	return self.check_characters
end


function _mt_parser:setNamespaceMode(v)
	if v ~= nil and v ~= "1.0" and v ~= "1.1" then
		error(lang.err_bad_ns_mode)
	end
	self.namespace_mode = v
end


function _mt_parser:getNamespaceMode()
	return self.namespace_mode
end


function _mt_parser:setCollectComments(enabled)
	self.collect_comments = not not enabled
end


function _mt_parser:getCollectComments()
	return self.collect_comments
end


function _mt_parser:setCollectProcessingInstructions(enabled)
	self.collect_pi = not not enabled
end


function _mt_parser:getCollectProcessingInstructions()
	return self.collect_pi
end


function _mt_parser:setNormalizeLineEndings(enabled)
	self.normalize_line_endings = not not enabled
end


function _mt_parser:getNormalizeLineEndings()
	return self.normalize_line_endings
end


function _mt_parser:setCheckEncodingMismatch(enabled)
	self.check_encoding_mismatch = not not enabled
end


function _mt_parser:getCheckEncodingMismatch()
	return self.check_encoding_mismatch
end


function _mt_parser:setMaxEntityBytes(n)
	_argType(1, n, "number")

	self.max_entity_bytes = n
end


function _mt_parser:getMaxEntityBytes()
	return self.max_entity_bytes
end


function _mt_parser:setRejectDoctype(enabled)
	self.reject_doctype = not not enabled
end


function _mt_parser:getRejectDoctype()
	return self.reject_doctype
end


function _mt_parser:setRejectInternalSubset(enabled)
	self.reject_internal_subset = not not enabled
end


function _mt_parser:getRejectInternalSubset()
	return self.reject_internal_subset
end


function _mt_parser:setCopyDocType(enabled)
	self.copy_doctype = not not enabled
end


function _mt_parser:getCopyDocType()
	return self.copy_doctype
end


function _mt_parser:setRejectUnexpandedEntities(enabled)
	self.reject_unexp_ent = not not enabled
end


function _mt_parser:getRejectUnexpandedEntities()
	return self.reject_unexp_ent
end


function _mt_parser:setWarnDuplicateEntityDeclarations(enabled)
	self.warn_dupe_decl = not not enabled
end


function _mt_parser:getWarnDuplicateEntityDeclarations()
	return self.warn_dupe_decl
end


function _mt_parser:setWriteXMLDeclaration(enabled)
	self.out_xml_decl = not not enabled
end


function _mt_parser:getWriteXMLDeclaration()
	return self.out_xml_decl
end


function _mt_parser:setWriteDocType(enabled)
	self.out_doc_type = not not enabled
end


function _mt_parser:getWriteDocType()
	return self.out_doc_type
end


function _mt_parser:setWritePretty(enabled)
	self.out_pretty = not not enabled
end


function _mt_parser:getWritePretty()
	return self.out_pretty
end


function _mt_parser:setWriteIndent(ch, qty)
	if ch ~= " " and ch ~= "\t" then
		error(lang.err_bad_indent)
	end
	_argType(2, qty, "nil", "number")
	qty = qty or 1
	qty = math.max(1, math.floor(qty))

	self.out_indent_ch = ch
	self.out_indent_qty = qty
end


function _mt_parser:getWriteIndent()
	return self.out_indent_ch, self.out_indent_qty
end


function _mt_parser:setWriteBigEndian(enabled)
	self.out_big_endian = not not enabled
end


function _mt_parser:getWriteBigEndian()
	return self.out_big_endian
end


function _mt_parser:toTable(str)
	_argType(1, str, "string")

	return xIn.parse(str, self)
end


function _mt_parser:toString(xml_obj)
	_argType(1, xml_obj, "table")

	return xOut.parse(xml_obj, self)
end


function lxl.toTable(str)
	_argType(1, str, "string")

	local parser = lxl.newParser()
	return parser:toTable(str)
end


function lxl.toString(xml_obj)
	_argType(1, xml_obj, "table")

	local parser = lxl.newParser()
	return parser:toString(xml_obj)
end


function lxl.newXMLObject()
	return struct.newXMLObject()
end


local _mode_all = (_VERSION == "Lua 5.1" or _VERSION == "Lua 5.2") and "*a" or "a"


function lxl.load(path)
	_argType(1, path, "string")

	local f, err = io.open(path, "r")
	if not f then
		error(err)
	end
	local s = f:read(_mode_all)
	f:close()
	if not s then
		error(lang.err_load_fail)
	end
	return lxl.toTable(s)
end


return lxl
