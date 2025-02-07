-- Common functions and data for the XML library.


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


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


local shared = {}


local jit_tracing
do
	local jit = rawget(_G, "jit")
	jit_tracing = jit and jit.status() or false
end


local pUTF8 = require(PATH .. "pile_utf8")


shared.lang = {
	-- lxl.lua
	err_bad_ns_mode = "bad value for Namespace Mode (must be nil, '1.0' or '1.1')",
	err_bad_indent = "argument #1: expected space or tab character",
	err_load_fail = "failed to read file: $1",

	-- lxl_in.lua
	err_int_empty_stack = "internal failure: stack is empty",
	err_int_top_mismatch = "internal failure: top element doesn't match table to be popped",
	xml_circ_entity_ref = "internal general entities cannot contain recursive references to themselves (whether direct or indirect)",
	err_max_repl_text = "exceeded max size for text from entity references",
	err_xml_fail = "processing XML failed",
	xml_ch_ref_bad_num = "invalid number in character reference",
	xml_ch_ref_fail = "failed to parse character reference (&#;)",
	xml_ch_ref_bad_cp = "character reference (&#;) contains an invalid code point for XML",
	xml_ent_ref_fail = "failed to parse Reference (&;)",
	xml_unparsed_in_ref = "unparsed entites cannot be used in entity references (&;)",
	xml_ent_ref_bad_name = "invalid Name in EntityRef",
	xml_ent_ref_bad_chars = "invalid characters within EntityRef Name",
	xml_undef_ent_ref = "undefined Entity Reference",
	xml_unhandled_ext_ref = "unhandled external Entity Reference",
	xml_attrib_lt = "Attribute Values cannot contain '<'",
	xml_attrib_entity_undecl = "custom general entity references in attribute values must be declared in the internal subset",
	xml_attrib_unclosed = "unclosed Attribute Value string",
	xml_cdata_no_rsb_rsb_gt = "Character Data outside of CDATA sections must not contain ']]>' in literal form",
	xml_unclosed_comment = "unclosed XML comment",
	xml_invalid_pi_target = "invalid or missing Processing Instruction Target",
	xml_pi_target_no_xml = "PITargets cannot begin with any case variation of the substring 'XML'",
	xml_unclosed_pi = "unclosed Processing Instruction tag",
	xml_unclosed_cdsect = "unclosed CDATA Section",
	xml_decl_bad_ver = "invalid or missing VersionInfo for XML Declaration",
	xml_decl_enc_mismatch = "mismatch between the XML Declaration encoding and the document's encoding",
	xml_decl_unclosed = "unclosed XML Declaration",
	xml_reject_doctype = "the XML processor is configured to reject DOCTYPE tags",
	xml_expected_doctype_name = "expected Name for DOCTYPE.",
	xml_reject_int_subset = "the XML processor is configured to reject DTD internal subsets",
	xml_int_subset_fail = "failed to parse DOCTYPE internal subset",
	xml_int_subset_unclosed = "expected closing ']' for DOCTYPE internal subset",
	xml_unclosed_doctype = "expected closing '>' for DOCTYPE",
	xml_sta_missing_eq = "missing '=' for standalone declaration",
	xml_bad_sta = "invalid value for standalone declaration",
	xml_element_unclosed = "expected name for element start/empty tag",
	xml_invalid_attr = "invalid attribute",
	xml_dupe_attr = "duplicate attribute name in element",
	xml_element_unclosed = "missing closing bracket for element start/empty tag",
	xml_etag_bad_open = "invalid or missing opening bracket for end tag",
	xml_etag_bad_name = "expected Name for closing element tag",
	xml_tag_name_mismatch = "name mismatch between start and end tag",
	xml_etag_unclosed = "unclosed End Tag, or invalid characters in element name",
	xml_att_list_decl_ws = "expected whitespace in attribute-list declaration",
	xml_att_list_bad_name = "missing or invalid name for attribute-list declaration",
	xml_att_def_bad_att_type = "expected attribute type in attribute definition",
	xml_att_def_bad_att_val = "expected attribute value in attribute default declaration",
	xml_att_def_unclosed = "expected closing bracket for Attribute-List Declaration",
	xml_reject_unexp_ent = "the XML Processor is configured to reject unexpanded Entity References",
	xml_geref_unbalanced = "general entity reference didn't match the 'content' production rule. (Make sure the replacement text has balanced content.)",
	xml_peref_unclosed = "unclosed PEReference (%;)",
	xml_peref_missing_name = "missing name for PEReference",
	xml_peref_int_subset = "parameter entity references are not allowed within markup declarations",
	xml_peref_bad_name = "invalid Name in PEReference (%;)",
	xml_peref_bad_ch = "invalid characters within PEReference name",
	xml_edecl_sp = "expected whitespace in entity declaration",
	xml_edecl_pedef_bad_name = "failed to read EntityDecl > PEDecl > Name",
	xml_edecl_bad_pedef = "failed to read EntityDecl > PEDecl > PEDef",
	xml_edecl_warn_dupe_pedef = "duplicate Parameter Entity Type Declaration: $1",
	xml_edecl_gedef_bad_name = "failed to read EntityDecl > GEDecl > Name",
	xml_edecl_gedef_bad_entdef = "failed to read EntityDecl > GEDecl > EntityDef",
	xml_edecl_invalid_predefined_decl = "invalid declaration for predefined entity: $1",
	xml_edecl_warn_dupe_gedef = "duplicate General Entity Type Declaration: $1",
	xml_edecl_unclosed = "missing closing bracket for EntityDecl",
	xml_exid_sp = "expected whitespace in ExternalID",
	xml_exid_system_bad_syslit = "failed to parse SystemLiteral in SYSTEM External ID",
	xml_exid_public_bad_pubid = "failed to parse PubidLiteral in PUBLIC External ID",
	xml_exid_public_bad_syslit = "failed to parse SystemLiteral in PUBLIC External ID",
	xml_ndata_sp = "expected whitespace in notation data declaration",
	xml_ndata_bad_name = "invalid or missing name for notation data declaration",
	xml_encdecl_bad = "invalid or missing value for encoding declaration",
	xml_notdecl_sp = "expected whitespace in Notation Declaration",
	xml_notdecl_bad_name = "failed to read Name in Notation Declaration",
	xml_notdecl_bad_exid = "missing or invalid ExternalID / PublicID in notation declaration",
	xml_notdecl_unclosed = "missing closing bracket for Notation Declaration",
	xml_u16_u8_fail = "conversion from UTF-16 to UTF-8 failed: $1",
	xml_u16_missing_bom = "missing Byte Order Mark (required for UTF-16 XML)",
	xml_int_stack_leftover = "internal corruption: stack contains leftover entries",
	xml_trailing_content = "unhandled trailing content after the root element",

	-- lxl_namespace.lua
	err_ns_empty_ns_uri = "encountered empty Namespace URI",
	err_ns_empty_prefix = "empty namespace prefix",
	err_ns_empty_local = "empty local name",
	err_ns_colon_local = "encountered additional colon in local name",
	err_ns_undef_ns = "undefined namespace URI",
	err_ns_dupe_attr = "duplicate namespaced attributes (URI + local name) in one element",
	err_ns_bad_xml_pre = "the prefix 'xml' can only be bound to 'http://www.w3.org/XML/1998/namespace'",
	err_ns_invalid_xmlns_pre = "the prefix 'xmlns' cannot be bound",
	err_ns_predef_def = "attempted to declare a predefined namespace URI as the default namespace",
	err_ns_invalid_colon = "Namespace mode: colons are prohibited in Entity Names, Notation Names and Processing Instruction Targets",
	err_ns_elem_xmlns = "Namespace mode: element names cannot be prefixed with 'xmlns'",
	err_ns_bad_xml_bind = "prefixes other than 'xml' cannot be bound to 'http://www.w3.org/XML/1998/namespace'",
	err_ns_bad_xmlns_bind = "prefixes other than 'xmlns' cannot be bound to 'http://www.w3.org/2000/xmlns/'",

	-- lxl_out.lua
	xml_out_1root = "only one root element is allowed per XML document",
	xml_out_bad_node = "invalid xmlObject node ID",
	xml_out_expect_xml_obj = "expected 'xml_object' table",
	xml_out_bad_decl = "failed to parse XML Declaration fields: $1",
	xml_out_0root = "no root element found",
	xml_out_u16_conv_fail = "Conversion to UTF-16 failed: $1",

	-- lxl_shared.lua
	err_assert_fail = "type assertion failed (expected type $1, got $2)",
	err_unsup_unicode1 = "unsupported Unicode character at position: $1 (byte #$2)",
	err_unsup_unicode2 = "unsupported Unicode character",
	xml_com_2hyphens = "XML comments cannot contain embedded double-hyphens ('--')",
	xml_com_spear = "XML comments cannot end with an embedded '-' (such that the tag ends with '--->')",
	xml_name_1cp = "XML Name must contain at least one code point",
	xml_name_bad_c1 = "invalid first character in XML Name",
	xml_name_bad_cx = "invalid character in XML Name",
	xml_pi_reserved = "PI Targets cannot match any case variation of 'xml'",
	xml_pi_bad_text = "PI Text cannot contain the substring '?>'",
	xml_u8_err = "UTF-8 decoding error",
	xml_unsup_ver = "unsupported XML version: $1",
	xml_unsup_enc = "unsupported encoding: $1",
	xml_unsup_sta = "invalid standalone value: $1",

	-- lxl_struct.lua
	struct_bad_self = "bad 'self' value (should be a table, got $1)",
	struct_insert_oob = "insertion index is out of bounds",
	struct_invalid_path = "invalid path",
	struct_2root = "attempted to create multiple root document nodes",
	struct_doctype_wrong_parent = "DocType nodes can only be attached to xmlObjects",
	struct_ns1_undeclare_prefix = "cannot undeclare prefixed namespace declarations in XML Namespaces 1.0",
	struct_bad_xml_ver = "invalid or unsupported XML Version",
	struct_bad_xml_enc = "invalid or unsupported XML Encoding",
	struct_bad_xml_sta = "invalid XML Standalone value",
	struct_bad_ns_mode = "argument #1: expected nil, '1.0' or '1.1' for namespace mode",
	struct_missing_xml_obj = "xmlObject root element not found"
}
local lang = shared.lang


local interp = require(PATH .. "pile_interp")
local _argType = require(PATH .. "pile_arg_check").type
local pTable = require(PATH .. "pile_table")


local _makeLUT, _invertLUT = pTable.makeLUT, pTable.invertLUT


function shared._assertType(v, e)
	if type(v) ~= e then
		error(interp(lang.err_assert_fail, e, type(v)))
	end
end


function shared._genericAssert(f, v)
	local ok, err = f(v)
	if not ok then
		error(err)
	end
end


function shared._assertXMLName(text)
	shared._genericAssert(shared.validateXMLName, text)
end


function shared.assertCharacters(s, with_counters)
	local ok, i, byte = shared.checkXMLCharacters(s)
	if not ok then
		if with_counters then
			error(interp(lang.err_unsup_unicode1, i, byte))
		else
			error(interp(lang.err_unsup_unicode2))
		end
	end
end


function shared._assertPITarget(pi_target)
	shared._genericAssert(shared.validatePITarget, pi_target)
end


function shared._assertPIText(text)
	shared._genericAssert(shared.checkPIText, text)
end


function shared._assertCommentText(text)
	shared._genericAssert(shared.checkXMLCommentText, text)
end


function shared.checkRangeLUT(lut, value)
	-- Checks if a value is within one of a series of ranges.
	for i = 1, #lut, 2 do
		if value < lut[i] then
			return

		elseif value <= lut[i + 1] then
			return true
		end
	end
end


shared.lut_supported_encodings = _makeLUT({"UTF-8", "UTF-16"})


shared.lut_default_entities = {lt = "<", gt = ">", amp = "&", quot = "\"", apos = "'"}
shared.lut_default_rev = _invertLUT(shared.lut_default_entities)


-- Valid code points and code point ranges for an XML document as a whole.
-- https://www.w3.org/TR/xml/#charsets
-- https://en.wikipedia.org/wiki/Valid_characters_in_XML
shared.lut_xml_unicode = {
	0x0009, 0x0009,
	0x000a, 0x000a,
	0x000d, 0x000d,
	0x0020, 0xd7ff,
	0xe000, 0xfffd,
	0x10000, 0x10ffff,
}


-- Valid code points for the start of a name
shared.lut_name_start_char = {
	(":"):byte(), (":"):byte(),
	("A"):byte(), ("Z"):byte(),
	("_"):byte(), ("_"):byte(),
	("a"):byte(), ("z"):byte(),
	0xC0, 0xD6,
	0xD8, 0xF6,
	0xF8, 0x2FF,
	0x370, 0x37D,
	0x37F, 0x1FFF,
	0x200C, 0x200D,
	0x2070, 0x218F,
	0x2C00, 0x2FEF,
	0x3001, 0xD7FF,
	0xF900, 0xFDCF,
	0xFDF0, 0xFFFD,
	0x10000, 0xEFFFF,
}


-- Valid code points for names. (This is in addition to lut_name_start_char.)
shared.lut_name_char = {
	("-"):byte(), ("-"):byte(),
	("."):byte(), ("."):byte(),
	("0"):byte(), ("9"):byte(),
	0xB7, 0xB7,
	0x0300, 0x036F,
	0x203F, 0x2040,
}


shared.lut_pubid_char = {}


-- Strings for various byte order marks and XML Declarations.
shared.bom_utf8 = string.char(0xEF, 0xBB, 0xBF) -- U+FEFF
shared.bom_utf16_be = string.char(0xFE, 0xFF) -- U+FEFF
shared.bom_utf16_le = string.char(0xFF, 0xFE) -- U+FEFF
shared.decl_utf16_le = string.char(0x3C, 0x00, 0x3F, 0x00, 0x78, 0x00, 0x6D, 0x00, 0x6C, 0x00) -- <?xml
shared.decl_utf16_be = string.char(0x00, 0x3C, 0x00, 0x3F, 0x00, 0x78, 0x00, 0x6D, 0x00, 0x6C) -- <?xml


function shared.checkXMLCharacters(s)
	-- n: code point count, b: byte index

	if jit_tracing then
		local n, b = 1, 1
		local codeFromString = pUTF8.codeFromString
		local checkRangeLUT = shared.checkRangeLUT
		local lut = shared.lut_xml_unicode
		while b <= #s do
			local code, u8_seq = codeFromString(s, b)
			if not code or not checkRangeLUT(lut, code) then
				return nil, n, b
			end
			n = n + 1
			b = b + #u8_seq
		end
		return true
	else
		-- Based on:
		-- https://github.com/kikito/utf8_validator.lua
		-- Modified to check valid XML code points (see production [2] Char)
		local n, b, len = 1, 1, #s
		while b <= len do
			if s:find("^[\9\10\13\32-\127]", b) then
				b = b + 1

			elseif s:find("^[\194-\223][\128-\191]", b)
				then b = b + 2

			elseif not s:find("^\239\191[\190-\191]", b) -- 0xfffe (239 191 190), 0xffff (239 191 191)
				and (s:find("^\224[\160-\191][\128-\191]", b)
				or s:find("^[\225-\236][\128-\191][\128-\191]", b)
				or s:find("^\237[\128-\159][\128-\191]", b)
				or s:find("^[\238-\239][\128-\191][\128-\191]", b))
				then b = b + 3

			elseif s:find("^\240[\144-\191][\128-\191][\128-\191]", b)
				or s:find("^[\241-\243][\128-\191][\128-\191][\128-\191]", b)
				or s:find("^\244[\128-\143][\128-\191][\128-\191]", b)
				then
				b = b + 4

			else
				return nil, n, b
			end
			n = n + 1
		end
		return true
	end
end


function shared.validateXMLName(name)
	local i = 1
	if #name == 0 then

		return nil, lang.xml_name_1cp
	end
	while i <= #name do
		local u8_code, u8_str = pUTF8.codeFromString(name, i)
		if not u8_code then
			return nil, lang.xml_u8_err
		end

		if not shared.checkRangeLUT(shared.lut_name_start_char, u8_code) then
			if i == 1 then
				return nil, lang.xml_name_bad_c1

			elseif not shared.checkRangeLUT(shared.lut_name_char, u8_code) then
				return nil, lang.xml_name_bad_cx
			end
		end

		i = i + #u8_str
	end
	return true
end


function shared.validatePITarget(pi_target)
	local ok, err = shared.validateXMLName(pi_target)
	if ok and pi_target:find("^[Xx][Mm][Ll]$") then
		return nil, lang.xml_pi_reserved
	end
	return ok, err
end


function shared.checkPIText(text)
	if text:find("?>", 1, true) then
		return nil, lang.xml_pi_bad_text
	end
	return true
end


function shared.checkXMLCommentText(str)
	if str:find("--", 1, true) then
		-- (Reason: for compatibility with SGML.)
		return nil, lang.xml_com_2hyphens

	elseif str:sub(-1) == "-" then
		return nil, lang.xml_com_spear
	end

	return true
end


function shared.checkXMLDecl(version, encoding, standalone)
	if version ~= "1.0" then
		return nil, interp(lang.xml_unsup_ver, tostring(version))

	elseif encoding and not shared.lut_supported_encodings[encoding] then
		return nil, interp(lang.xml_unsup_enc, tostring(encoding))

	elseif standalone and standalone ~= "yes" and standalone ~= "no" then
		return nil, interp(lang.xml_unsup_sta, tostring(standalone))
	end

	return true
end


local function _sortString(a, b)
	return a < b
end


function shared.orderedKeys(keys)
	local t = {}
	for k, v in pairs(keys) do
		table.insert(t, k)
	end
	table.sort(t, _sortString)
	return t
end


return shared
