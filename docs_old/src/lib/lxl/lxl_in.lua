-- LXL in: Converts an XML string to a nested Lua table.
-- (Use this module through lxl.lua)


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local xIn = {}


local _argType = require(PATH .. "pile_arg_check").type
local interp = require(PATH .. "pile_interp")
local namespace = require(PATH .. "lxl_namespace")
local shared = require(PATH .. "lxl_shared")
local stringProc = require(PATH .. "string_proc")
local stringWalk = require(PATH .. "string_walk")
local struct = require(PATH .. "lxl_struct")
local pUTF8 = require(PATH .. "pile_utf8")
local pUTF8Conv = require(PATH .. "pile_utf8_conv")


local lang = shared.lang


-- * Parser Engine: Begin *


local sym = {}
xIn.sym = sym


local ptn_space = "\t\n\r "
local ptn_s = "^([" .. ptn_space .. "]+)"
local ptn_eq = "^["..ptn_space.."]?=["..ptn_space.."]?"
local ptn_version_info = "^[" .. ptn_space .. "]*version" .. "[" .. ptn_space .. "]*=[" .. ptn_space .. "]*(['\"])(1%.[0-9]+)(%1)"


local _grammar = stringProc.toTable


local _process = function(W, s)
	return stringProc.traverse(W, s, sym)
end


local function _stackPeek(W)
	if #W.stack == 0 then
		error(lang.err_int_empty_stack)
	end
	return W.stack[#W.stack]
end


local function _stackPush(W, v)
	W.stack[#W.stack + 1] = v
end


local function _stackPop(W, v)
	if #W.stack == 0 then
		error(lang.err_int_empty_stack)

	elseif W.stack[#W.stack] ~= v then
		error(lang.err_int_top_mismatch)
	end
	W.stack[#W.stack] = nil
end


-- Non-validating processors are allowed to stop reading entity declarations and attribute-value
-- declarations in the internal subset as soon as they skip a parameter entity reference, unless
-- standalone="yes". (§5.1)
local function _docTypeKeepGoing(W)
	return W.xml_obj.standalone == "yes" or not W.hit_pe_ref
end


local function _checkCircularReferences(W, id)
	for i, k in ipairs(W.circ) do
		if k == id then
			W:error(lang.xml_circ_entity_ref)
		end
	end
end


-- Upvalue for _nsErrHand.
-- Is set before calling namespace.checkElement(). May contain a stale reference if
-- xIn.parse() fails within a pcall.
local uv_W


local function _nsErrHand(s)
	uv_W:error(s)
end


-- When using Namespaces: Entity Names, Notations Names and PI Targets cannot contain colons
local function _nsCheckNoColon(W, s)
	if W.parser.namespace_mode then
		namespace.checkNoColon(s, _nsErrHand)
	end
end


local function _checkMaxEntityBytes(W, text)
	W.entity_bytes = W.entity_bytes + #text
	if W.entity_bytes >= W.parser.max_entity_bytes then
		-- If you hit this codepath with legitimate input, increase 'max_entity_bytes' or set it to infinity.
		W:error(lang.err_max_repl_text)
	end
end


-- [1] document ::= prolog element Misc*
local p_document = _grammar([[
	prolog element Misc*
]])
function sym.document(W)
	local r = _process(W, p_document)
	W:assert(r, lang.err_xml_fail)

	return true
end


-- [2] Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
-- Unused. From Lua, it's easier to check the whole XML string for invalid Chars before parsing.
-- Then we can just match any code point.


-- [3] S ::= (#x20 | #x9 | #xD | #xA)+
-- Lua '%s' is avoided out of concern for locale differences.
function sym.S(W)
	return W:match(ptn_s) and true
end


-- [4] NameStartChar ::= ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
function sym.NameStartChar(W)
	if W:isEOS() then return end

	local code, u8_str = pUTF8.codeFromString(W.S, W.I)
	if code and shared.checkRangeLUT(shared.lut_name_start_char, code) then
		W:step(#u8_str)
		return u8_str
	end
end


-- [4a] NameChar ::= NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
function sym.NameChar(W)
	if W:isEOS() then return end

	local code, u8_str = pUTF8.codeFromString(W.S, W.I)
	if code and (shared.checkRangeLUT(shared.lut_name_start_char, code) or shared.checkRangeLUT(shared.lut_name_char, code)) then
		W:step(#u8_str)
		return u8_str
	end
end


-- [5] Name ::= NameStartChar (NameChar)*
function sym.Name(W)
	local i = W.I
	local nsc = sym.NameStartChar(W)
	if nsc then
		while sym.NameChar(W) do end
		return W.S:sub(i, W.I - 1)
	end
end


-- For [6], [8]
function sym.x20(W)
	return W:lit(" ") and true
end


-- [6] Names ::= Name (#x20 Name)*
-- Validating processors only


-- [7] Nmtoken ::= (NameChar)+
function sym.Nmtoken(W)
	local i = W.I
	local nc = sym.NameChar(W)
	if nc then
		while sym.NameChar(W) do end
		return W.S:sub(i, W.I - 1)
	end
end


-- [8] Nmtokens ::= Nmtoken (#x20 Nmtoken)*
-- Validating processors only


-- For [9]: one-or-more of [^%&']
function sym._notpaq1(W)
	return W:match("^([^%%&']+)")
end


-- For [9]: one-or-more of [^%&"]
function sym._notpaq2(W)
	return W:match("^([^%%&\"]+)")
end


-- For [9], [10]: single-quote with no return string
function sym._q1(W)
	return W:lit("'") and true
end


-- For [9], [10]: double-quote with no return string
function sym._q2(W)
	return W:lit("\"") and true
end


-- [9] EntityValue ::= '"' ([^%&"] | PEReference | Reference)* '"'
--                   | "'" ([^%&'] | PEReference | Reference)* "'"
local p_entity_value = _grammar([[
	_q2 (_notpaq2 | PEReference | Reference)* _q2
	| _q1 (_notpaq1 | PEReference | Reference)* _q1
]])
function sym.EntityValue(W)
	-- NOTE: PEReferences always fail here (not allowed in markup declarations in the internal subset).
	W.in_entity_value = true
	local r = _process(W, p_entity_value)
	W.in_entity_value = false
	if r then
		return table.concat(r)
	end
end


-- For [10], [67]
local function _CharRef(W)
	if W:lit("&#") then
		local is_hex, str = W:matchReq("^(x?)([^;]+);", lang.xml_ch_ref_fail)
		local code = tonumber(str, (is_hex == "x" and 16 or 10))
		W:assert(code, lang.xml_ch_ref_bad_num)

		-- The code point must be compatible with the production 'Char'.
		W:assert(shared.checkRangeLUT(shared.lut_xml_unicode, code), lang.xml_ch_ref_bad_cp)

		local u8_str, err = pUTF8.stringFromCode(code)
		W:assert(u8_str, err)

		return u8_str
	end
end


-- For [10], [67]
local function _EntityRef(W)
	if W:lit("&") then
		local a, b, str = W:findReq("^([^;]+);", false, lang.xml_ent_ref_fail)

		-- Well-formedness constraint: Parsed Entity
		-- (No &references; to unparsed entities)
		local unparsed = W.xml_obj.g_entities[str]
		if unparsed and type(unparsed) == "table" and unparsed.n_data_decl then
			W:error(lang.xml_unparsed_in_ref)
		end

		-- "bypass" rule
		if W.in_entity_value then
			return "&" .. str .. ";", nil, true
		end
		W:seek(a)
		local name = W:req(sym.Name, lang.xml_ent_ref_bad_name)
		W:litReq(";", lang.xml_ent_ref_bad_chars)

		local lookup
		lookup = shared.lut_default_entities[str]
		if lookup then
			return lookup, nil, true
		end
		lookup = W.xml_obj.g_entities[str]

		-- Well-formedness constraint: Entity Declared
		if not W.hit_pe_ref or W.xml_obj.standalone == "yes" then
			W:assert(lookup, lang.xml_undef_ent_ref)
			W:assert(type(lookup) == "string", lang.xml_unhandled_ext_ref)
		end

		-- Non-Validating: ignore external entities (whose values are stored as type "table")
		lookup = type(lookup) == "string" and lookup

		-- Well-formedness constraint: No Recursion
		_checkCircularReferences(W, str)

		return lookup, str
	end
end


-- For [10]
local function _handleAttValue(W, str, rv)
	-- Implements 3.3.3 Attribute-Value Normalization
	-- https://www.w3.org/TR/REC-xml/#AVNormalize
	W:push(str)
	_checkMaxEntityBytes(W, str)
	repeat
		local chunk
		-- Text
		chunk = W:match("^([^&]+)")
		if chunk then
			-- Well-formedness constraint: No < in Attribute Values
			W:assert(not chunk:find("<", 1, true), lang.xml_attrib_lt)

			-- normalize literal appearances of white space characters (#x20, #xD, #xA, #x9)
			chunk = chunk:gsub("[\32\13\10\9]", " ")

			rv[#rv + 1] = chunk
		end

		-- CharRef
		chunk = _CharRef(W)
		if chunk then
			rv[#rv + 1] = chunk
		else
			-- Entity References
			local lookup, ref_id, direct = _EntityRef(W)
			if direct then
				rv[#rv + 1] = lookup

			elseif lookup then
				-- Well-formedness constraint: No Recursion
				_checkCircularReferences(W, ref_id)

				table.insert(W.circ, ref_id)
				_handleAttValue(W, lookup, rv)
				table.remove(W.circ)

			elseif ref_id and not lookup then
				-- This is always an error within an attribute value.
				W:error(lang.xml_attrib_entity_undecl)
			end
		end
	until W:isEOS()
	W:pop()
end


-- For [10]
local _att_v_ptn = {
	["'"] = "^([^<']-)'",
	["\""] = "^([^<\"]-)\""
}


-- [10] AttValue ::= '"' ([^<&"] | Reference)* '"'
--                   | "'" ([^<&'] | Reference)* "'"
function sym.AttValue(W)
	local q = W:lit("'") or W:lit("\"")
	if q then
		local str = W:matchReq(_att_v_ptn[q], lang.xml_attrib_unclosed)
		local rv = {}
		_handleAttValue(W, str, rv)
		local rs = table.concat(rv)
		return rs
	end
end


-- [11] SystemLiteral ::= ('"' [^"]* '"') | ("'" [^']* "'")
function sym.SystemLiteral(W)
	local _, s = W:match("^(['\"])(.-)%1")
	return s
end


-- [12] PubidLiteral ::= '"' PubidChar* '"' | "'" (PubidChar - "'")* "'"
function sym.PubidLiteral(W)
	-- PubidChar
	local _, s = W:match("^(['\"])([\32\13\10a-zA-Z0-9%-'%(%)%+,%./:=%?;!%*#@$_%%]-)%1")
	return s
end


-- [13] PubidChar ::= #x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
-- (See [12])


-- For [14]: zero-or-more of [^<&]
function sym._notla(W)
	return W:match("([^<&\"]+)")
end


-- [14] CharData ::= [^<&]* - ([^<&]* ']]>' [^<&]*)
function sym.CharData(W)
	local text = W:match("^([^<&]+)")
	if text then
		W:assert(not text:find("]]>", 1, true), lang.xml_cdata_no_rsb_rsb_gt)
		return struct.newCharacterDataInternal(_stackPeek(W), text), true
	end
end


-- [15] Comment ::= '<!--' ((Char - '-') | ('-' (Char - '-')))* '-->'
function sym.Comment(W)
	if W:lit("<!--") then
		local chunk = W:matchReq("(.-)%-%->", lang.xml_unclosed_comment)
		local ok, err = shared.checkXMLCommentText(chunk)
		W:assert(ok, err)

		if W.parser.collect_comments then
			return struct.newComment(_stackPeek(W), chunk), true
		else
			return true
		end
	end
end


-- [16] PI ::= '<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
function sym.PI(W)
	if W:lit("<?") then
		local pi_target = W:req(sym.Name, lang.xml_invalid_pi_target)
		_nsCheckNoColon(W, pi_target)
		-- (Errata S01, §2.6)
		W:assert(not pi_target:find("^[Xx][Mm][Ll]"), lang.xml_pi_target_no_xml)
		sym.S(W)
		local text = W:matchReq("(.-)%?>", lang.xml_unclosed_pi)
		if W.parser.collect_pi then
			return struct.newProcessingInstruction(_stackPeek(W), pi_target, text), true
		else
			return true
		end
	end
end


-- [17] PITarget ::= Name - (('X' | 'x') ('M' | 'm') ('L' | 'l'))
-- (See [16])


-- [18] CDSect ::= CDStart CData CDEnd
function sym.CDSect(W)
	-- CDStart
	if W:lit("<![CDATA[") then
		-- CData, CDEnd
		local cd_text = W:matchReq("(.-)%]%]>", lang.xml_unclosed_cdsect)
		return struct.newCharacterDataInternal(_stackPeek(W), cd_text, true), true
	end
end


-- [19] CDStart ::= '<![CDATA['
-- [20] CData ::= (Char* - (Char* ']]>' Char*))
-- [21] CDEnd ::= ']]>'
-- (See [18])


-- [22] prolog ::= XMLDecl? Misc* (doctypedecl Misc*)?
local p_prolog = _grammar([[
	XMLDecl? Misc* doctypedecl? Misc*
]])
function sym.prolog(W)
	return _process(W, p_prolog)
end


-- [23] XMLDecl ::= '<?xml' VersionInfo EncodingDecl? SDDecl? S? '?>'
function sym.XMLDecl(W)
	if W:lit("<?xml") then
		W.xml_obj.version = W:req(sym.VersionInfo, lang.xml_decl_bad_ver)
		W.xml_obj.encoding = sym.EncodingDecl(W)

		-- It's a fatal error for the XML Declaration's encoding field to not match the document's guessed encoding.
		-- This processor supports UTF-8 and UTF-16 only.
		-- (§4.3.3 Character Encoding in Entities)
		if W.parser.check_encoding_mismatch and W.xml_obj.encoding then
			W:assert(W.xml_obj.encoding == W.guessed_encoding, lang.xml_decl_enc_mismatch)
		end

		W.xml_obj.standalone = sym.SDDecl(W)

		sym.S(W)
		W:litReq("?>", lang.xml_decl_unclosed)
		return true
	end
end


-- [24] VersionInfo ::= S 'version' Eq ("'" VersionNum "'" | '"' VersionNum '"')
function sym.VersionInfo(W)
	-- VersionNum
	local q, chunk = W:match(ptn_version_info)
	return chunk
end


-- [25] Eq ::= S? '=' S?
function sym.Eq(W)
	return W:match(ptn_eq) and true
end


-- [26] VersionNum ::= '1.' [0-9]+
-- (See [24])


-- [27] Misc ::= Comment | PI | S
function sym.Misc(W)
	return (sym.Comment(W) or sym.PI(W) or sym.S(W)) and true
end


-- [28] doctypedecl ::= '<!DOCTYPE' S Name (S ExternalID)? S? ('[' intSubset ']' S?)? '>'
function sym.doctypedecl(W)
	local i = W.I
	if W:lit("<!DOCTYPE") then
		W:assert(not W.parser.reject_doctype, lang.xml_reject_doctype)
		sym.S(W)
		local d_name = W:req(sym.Name, lang.xml_expected_doctype_name)
		local doctype = struct.newDocType(_stackPeek(W), d_name)
		_stackPush(W, doctype)
		sym.S(W)
		doctype.external_id = sym.ExternalID(W)
		sym.S(W)
		if W:lit("[") then
			W:assert(not W.parser.reject_internal_subset, lang.xml_reject_int_subset)
			W:req(sym.intSubset, lang.xml_int_subset_fail)
			W:litReq("]", lang.xml_int_subset_unclosed)
		end
		sym.S(W)
		W:litReq(">", lang.xml_unclosed_doctype)
		if W.parser.copy_doctype then
			W.xml_obj.doctype_str = W.S:sub(i, W.I - 1)
		end
		_stackPop(W, doctype)
		return true
	end
end


-- [28a] DeclSep ::= PEReference | S
-- (See [28b])


-- [28b] intSubset ::= (markupdecl | DeclSep)*
function sym.intSubset(W)
	local r = {}
	local val
	repeat
		-- DeclSep
		val = sym.markupdecl(W) or sym.PEReference(W) or sym.S(W)
		if val and type(val) ~= true then
			r[#r + 1] = val
		end
	until not val
	return r
end


-- [29] markupdecl ::= elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment
function sym.markupdecl(W)
	W.in_markup_decl = true

	local r = sym.elementdecl(W)
		or sym.AttlistDecl(W)
		or sym.EntityDecl(W)
		or sym.NotationDecl(W)
		or sym.PI(W)
		or sym.Comment(W)

	W.in_markup_decl = false

	return r, true
end


-- [30] extSubset ::= TextDecl? extSubsetDecl
-- [31] extSubsetDecl ::= (markupdecl | conditionalSect | DeclSep)*
-- External DTD only.


-- [32] SDDecl ::= S 'standalone' Eq (("'" ('yes' | 'no') "'") | ('"' ('yes' | 'no') '"'))
function sym.SDDecl(W)
	local i = W.I
	if sym.S(W) and W:lit("standalone") then
		W:req(sym.Eq, lang.xml_sta_missing_eq)
		local quote, chunk = W:match("(['\"])(.-)%1")
		if chunk ~= "yes" and chunk ~= "no" then
			W:error(lang.xml_bad_sta)
		end
		return chunk
	end
	W:seek(i)
end


-- (Productions [33] to [38] were removed.)


-- For [39]
local function _packElement(W, name, attribs)
	-- Attribute defaults and normalization
	local defaults = W.xml_obj.attr_defaults[name]
	if defaults then
		for k, v in pairs(defaults) do
			if v.default and not attribs[k] then
				attribs[k] = v.default
			end

			-- Non-CDATA whitespace normalization (§3.3.3)
			local s = attribs[k]
			if s and v.type ~= "CDATA" then
				s = s:match("^\32*(.-)\32*$")
				s = s:gsub("\32+", "\32")
				attribs[k] = s
			end
		end
	end

	local elem = struct.newElementInternal(_stackPeek(W), name, nil, attribs)

	if W.parser.namespace_mode then
		namespace.checkElement(elem, W.parser.namespace_mode, _nsErrHand)
	end
	return elem
end


-- For [39]
local function _elementTag(W)
	local name = W:req(sym.Name, lang.xml_element_unclosed)

	-- collect Attributes
	local attribs, a_name = {}
	repeat
		sym.S(W)
		a_name = sym.Name(W)
		if a_name then
			local eq, att_val = sym.Eq(W), sym.AttValue(W)
			if not eq or not att_val then
				W:error(lang.xml_invalid_attr)

			elseif attribs[a_name] then
				W:error(lang.xml_dupe_attr)
			end
			attribs[a_name] = att_val
		end
	until not a_name
	local is_empty = false
	-- wrap up tag parsing
	sym.S(W)
	if W:lit("/>") then
		is_empty = true
	else
		W:litReq(">", lang.xml_element_unclosed)
	end
	local elem = _packElement(W, name, attribs)
	return elem, is_empty
end


-- [39] element ::= EmptyElemTag
--              | STag content ETag
function sym.element(W)
	-- STag
	-- EmptyElemTag
	if W:match("^<[^/!%?]") then
		W:step(-1)
		local elem, is_empty = _elementTag(W)
		if elem then
			if not is_empty then
				_stackPush(W, elem)
				local content = sym.content(W)

				-- ETag
				W:litReq("</", lang.xml_etag_bad_open)
				local e_tag = W:req(sym.Name, lang.xml_etag_bad_name)
				-- Well-formedness constraint: Element Type Match
				W:assert(e_tag == elem.name, lang.xml_tag_name_mismatch)

				sym.S(W)
				W:litReq(">", lang.xml_etag_unclosed)
				_stackPop(W, elem)
			end
			return elem, true
		end
	end
end


-- [40] STag ::= '<' Name (S Attribute)* S? '>'
-- [41] Attribute ::= Name Eq AttValue
-- [42] ETag ::= '</' Name S? '>'
-- (See [39])


-- [43] content ::= CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*
function sym.content(W)
	local v
	repeat
		v = sym.CharData(W)
		or sym.element(W)
		or sym.c_Reference(W)
		or sym.CDSect(W)
		or sym.PI(W)
		or sym.Comment(W)
	until not v
	return true
end


-- [44] EmptyElemTag ::= '<' Name (S Attribute)* S? '/>'
-- (See [39])


-- [45] elementdecl ::= '<!ELEMENT' S Name S contentspec S? '>'
local p_element_decl = _grammar([[
	'<!ELEMENT' S Name S contentspec S? '>'
]])
function sym.elementdecl(W)
	local r = _process(W, p_element_decl)
	if r then
		local element_decl = {
			id = "elementdecl",
			name = r[2],
			contentspec = r[3]
		}
		--[[
		As far as I can tell, a non-validating processor doesn't actually do
		anything with element declarations. If the syntax is OK, then continue on.
		--]]
		return element_decl, true
	end
end


-- [46] contentspec ::= 'EMPTY' | 'ANY' | Mixed | children
local p_content_spec = _grammar([[
	'EMPTY' | 'ANY' | Mixed | children
]])
function sym.contentspec(W)
	return _process(W, p_content_spec)
end


-- [47] children ::= (choice | seq) ('?' | '*' | '+')?
local p_children = _grammar([[
	(choice | seq) ('?' | '*' | '+')?
]])
function sym.children(W)
	return _process(W, p_children), true
end


-- [48] cp ::= (Name | choice | seq) ('?' | '*' | '+')?
local p_cp = _grammar([[
	(Name | choice | seq) ('?' | '*' | '+')?
]])
function sym.cp(W)
	return _process(W, p_cp), true
end


-- [49] choice ::= '(' S? cp ( S? '|' S? cp )+ S? ')'
local p_choice = _grammar([[
	'(' S? cp ( S? '|' S? cp )+ S? ')'
]])
function sym.choice(W)
	return _process(W, p_choice), true
end


-- [50] seq ::= '(' S? cp ( S? ',' S? cp )* S? ')'
local p_seq = _grammar([[
	'(' S? cp ( S? ',' S? cp )* S? ')'
]])
function sym.seq(W)
	return _process(W, p_seq), true
end


-- [51] Mixed ::= '(' S? '#PCDATA' (S? '|' S? Name)* S? ')*'
--                | '(' S? '#PCDATA' S? ')'
local p_mixed = _grammar([[
	'(' S? '#PCDATA' (S? '|' S? Name)* S? ')*'
	| '(' S? '#PCDATA' S? ')'
]])
function sym.Mixed(W)
	return _process(W, p_mixed), true
end


-- [52] AttlistDecl ::= '<!ATTLIST' S Name AttDef* S? '>'
function sym.AttlistDecl(W)
	if W:lit("<!ATTLIST") then
		W:req(sym.S, lang.xml_att_list_decl_ws)
		local name = W:req(sym.Name, lang.xml_att_list_bad_name)
		local defs = {}
		local def
		repeat
			def = nil
			-- AttDef
			sym.S(W)
			local a_name = sym.Name(W)
			if a_name then
				W:req(sym.S, lang.xml_att_list_decl_ws)
				-- AttType
				-- StringType
				local a_type = W:lit("CDATA") or sym.TokenizedType(W) or sym.EnumeratedType(W)
				W:assert(a_type, lang.xml_att_def_bad_att_type)
				W:req(sym.S, lang.xml_att_list_decl_ws)
				-- DefaultDecl
				local decl_keyword = W:lit("#REQUIRED") or W:lit("#IMPLIED") or W:lit("#FIXED")
				sym.S(W)
				local decl_value
				if not decl_keyword or decl_keyword == "#FIXED" then
					decl_value = sym.AttValue(W)
					W:assert(decl_value, lang.xml_att_def_bad_att_val)
				end

				sym.S(W)
				def = {type = a_type, keyword=decl_keyword, default=decl_value}
				defs[a_name] = def
			end
		until not def

		W:litReq(">", lang.xml_att_def_unclosed)

		if _docTypeKeepGoing(W) then
			-- Merge multiple Attribute-Lists for the same element.
			local existing = W.xml_obj.attr_defaults[name]
			if existing then
				for k, v in pairs(defs) do
					-- Ignore multiple attribute declarations after the first.
					if not existing[k] then
						existing[k] = v
					end
				end
			else
				W.xml_obj.attr_defaults[name] = defs
			end
		end
		return true
	end
end


-- [53] AttDef ::= S Name S AttType S DefaultDecl
-- [54] AttType ::= StringType | TokenizedType | EnumeratedType
-- [55] StringType ::= 'CDATA'
-- (See [52])


-- [56] TokenizedType ::= 'ID'
--                        | 'IDREF'
--                        | 'IDREFS'
--                        | 'ENTITY'
--                        | 'ENTITIES'
--                        | 'NMTOKEN'
--                        | 'NMTOKENS'
local p_tokenized_type = _grammar([[
	'IDREFS' | 'IDREF' | 'ID' | 'ENTITIES' | 'ENTITY' | 'NMTOKENS' | 'NMTOKEN'
]])
function sym.TokenizedType(W)
	return _process(W, p_tokenized_type)
end


-- [57] EnumeratedType ::= NotationType | Enumeration
local p_enumerated_type = _grammar([[
	NotationType | Enumeration
]])
function sym.EnumeratedType(W)
	return _process(W, p_enumerated_type), true
end


-- [58] NotationType ::= 'NOTATION' S '(' S? Name (S? '|' S? Name)* S? ')'
local p_notation_type = _grammar([[
	'NOTATION' S '(' S? Name (S? '|' S? Name)* S? ')'
]])
function sym.NotationType(W)
	return _process(W, p_notation_type), true
end


-- [59] Enumeration ::= '(' S? Nmtoken (S? '|' S? Nmtoken)* S? ')'
local p_enumeration = _grammar([[
	'(' S? Nmtoken (S? '|' S? Nmtoken)* S? ')'
]])
function sym.Enumeration(W)
	return _process(W, p_enumeration), true
end


-- [60] DefaultDecl ::= '#REQUIRED' | '#IMPLIED'
--                      | (('#FIXED' S)? AttValue)
-- (See [52])


-- [61] conditionalSect ::= includeSect | ignoreSect
-- [62] includeSect ::= '<![' S? 'INCLUDE' S? '[' extSubsetDecl ']]>'
-- [63] ignoreSect ::= '<![' S? 'IGNORE' S? '[' ignoreSectContents* ']]>'
-- [64] ignoreSectContents ::= Ignore ('<![' ignoreSectContents ']]>' Ignore)*
-- [65] Ignore ::= Char* - (Char* ('<![' | ']]>') Char*)
-- External DTD and PEReferences only.


-- [66] CharRef ::= '&#' [0-9]+ ';'
--                  | '&#x' [0-9a-fA-F]+ ';'
-- (See [67])


-- [67] Reference ::= EntityRef | CharRef
function sym.Reference(W)
	-- CharRef
	local lookup, str, direct
	lookup = _CharRef(W)
	if lookup then
		return lookup
	end
	-- EntityRef
	lookup, str, direct = _EntityRef(W)
	if str and not lookup then
		--[[
		This codepath is a special case where:
		* standalone is "no" or not declared
		* There is a DTD internal subset
		* We have skipped one or more Parameter Entity References
		--]]
		if W.parser.reject_unexp_ent then
			W:error(lang.xml_reject_unexp_ent)
		end
		local unexp_ref = struct.newUnexpandedReference(_stackPeek(W), str)
		return true

	elseif lookup then
		if direct then
			return lookup
		end

		--[[
		Things get complicated here. XML entity references support recursion, and the replacement text
		must be processed as though it were part of the document. That is, you can inject new elements
		into the string which are then parsed. The replacement text of internal general entities needs
		to match the 'content' rule, meaning that it must be "balanced"; you cannot include unbalanced
		tags or incomplete references.
		--]]
		table.insert(W.circ, str)

		-- Push the replacement text as a new frame.
		W:push(lookup)
		_checkMaxEntityBytes(W, lookup)

		-- Line and character numbers will be frozen until we deplete the stack.

		-- Run the 'content' rule on the entity text.
		sym.content(W)

		if W.I < #W.S then
			W:error(lang.xml_geref_unbalanced)
		end

		-- Now return to the previous stack level.
		W:pop()

		table.remove(W.circ)

		return true
	end
end


-- Variation of [67] that attaches the reference to the top stack table as a char-data node,
-- rather than returning a string.
-- Used when the Reference is part of the document content.
function sym.c_Reference(W)
	local ref = sym.Reference(W)
	if type(ref) == "string" then
		struct.newCharacterDataInternal(_stackPeek(W), ref)
	end
	return ref
end


-- [68] EntityRef ::= '&' Name ';'
-- (See [67])


-- [69] PEReference ::= '%' Name ';'
-- For some notes on PEReferences, see: README.md -> Appendix -> Handling of PEReferences
function sym.PEReference(W)
	if W:lit("%") then
		local a, b, chunk = W:findReq("([^;]*);", false, lang.xml_peref_unclosed)
		W:assert(#chunk > 0, lang.xml_peref_missing_name)

		-- Well-formedness constraint: PEs in Internal Subset
		W:assert(not W.in_markup_decl, lang.xml_peref_int_subset)

		W:seek(a)
		local name = W:req(sym.Name, lang.xml_peref_bad_name)
		W:litReq(";", lang.xml_peref_bad_ch)

		W.hit_pe_ref = true

		return true
	end
end


-- For [70]
-- Every valid combo for declarations of predefined entities, as seen within sym.EntityDecl().
-- Call string.lower() on the string to be compared.
-- https://www.w3.org/TR/REC-xml/#sec-predefined-ent
local _predefs = {
	lt = {"&#60;", "&#x3c;"},
	gt = {">", "&#62;", "&#x3e;"},
	amp = {"&#38;", "&#x26;"},
	apos = {"'", "&#39;", "&#x27;"},
	quot = {"\"", "&#34;", "&#x22;"}
}


-- [70] EntityDecl ::= GEDecl | PEDecl
function sym.EntityDecl(W)
	if W:lit("<!ENTITY") then
		W:req(sym.S, lang.xml_edecl_sp)
		local is_pe_decl = W:lit("%")
		if is_pe_decl then
			-- PEDecl
			W:req(sym.S, lang.xml_edecl_sp)
			local name = W:req(sym.Name, lang.xml_edecl_pedef_bad_name)
			W:req(sym.S, lang.xml_edecl_sp)
			local pe_def = W:req(sym.PEDef, lang.xml_edecl_bad_pedef)

			if _docTypeKeepGoing(W) then
				if W.xml_obj.p_entities[name] then
					if W.parser.warn_dupe_decl then
						W:warn(interp(lang.xml_edecl_warn_dupe_pedef, name))
					end
				else
					W.xml_obj.p_entities[name] = pe_def
				end
			end
		else
			-- GEDecl
			local name = W:req(sym.Name, lang.xml_edecl_gedef_bad_name)
			_nsCheckNoColon(W, name)
			W:req(sym.S, lang.xml_edecl_sp)
			local entity_def = W:req(sym.EntityDef, lang.xml_edecl_gedef_bad_entdef)

			if _docTypeKeepGoing(W) then
				--[[
				The spec permits explicitly defining the predefined entities (like &amp;) in the
				internal subset. We will accept such declarations only if they hold the correct values
				(as in, `&amp;` must resolve to `&`). We will attach the values to g_entities, but they
				will not be used because an earlier codepath already handles predefined entities.
				--]]
				local predef = _predefs[name]
				if predef then
					local ok
					local ent_lc = string.lower(entity_def)
					for i, str in ipairs(predef) do
						if str == ent_lc then
							ok = true
							break
						end
					end
					if not ok then
						W:error(interp(lang.xml_edecl_invalid_predefined_decl, name))
					end
				end

				if W.xml_obj.g_entities[name] then
					if W.parser.warn_dupe_decl then
						W:warn(interp(lang.xml_edecl_warn_dupe_gedef, name))
					end
				else
					W.xml_obj.g_entities[name] = entity_def
				end
			end
		end
		sym.S(W)
		W:litReq(">", lang.xml_edecl_unclosed)

		return true
	end
end


-- [71] GEDecl ::= '<!ENTITY' S Name S EntityDef S? '>'
-- [72] PEDecl ::= '<!ENTITY' S '%' S Name S PEDef S? '>'
-- (See [70])


-- [73] EntityDef ::= EntityValue | (ExternalID NDataDecl?)
function sym.EntityDef(W)
	local r1 = sym.EntityValue(W) or sym.ExternalID(W)
	if r1 then
		local n_data_decl
		if type(r1) == "table" and r1.id == "external_id" then
			-- The requirement to check that the notation is declared before referring to
			-- it is filed under "Validity constraint: Notation Declared," so I suppose a
			-- non-validating XML Processor doesn't need to deal with that.
			n_data_decl = sym.NDataDecl(W)
		end
		-- Differentiate internal and external entities by storing them as
		-- strings and tables, respectively.
		if type(r1) == "string" then
			return r1
		else
			-- This is an "unparsed entity" if n_data_decl is populated.
			return {id="entity_def", value=r1, n_data_decl=n_data_decl}, true
		end
	end
end


-- [74] PEDef ::= EntityValue | ExternalID
function sym.PEDef(W)
	local r = sym.EntityValue(W) or sym.ExternalID(W)
	return r, true
end


-- [75] ExternalID ::= 'SYSTEM' S SystemLiteral
--                     | 'PUBLIC' S PubidLiteral S SystemLiteral
function sym.ExternalID(W)
	if W:lit("SYSTEM") then
		local rv = {id = "external_id", type = "SYSTEM"}
		W:req(sym.S, lang.xml_exid_sp)
		rv.system_literal = W:req(sym.SystemLiteral, lang.xml_exid_system_bad_syslit)
		return rv, true

	elseif W:lit("PUBLIC") then
		local rv = {id = "external_id", type = "PUBLIC"}
		W:req(sym.S, lang.xml_exid_sp)
		rv.pub_id_literal = W:req(sym.PubidLiteral, lang.xml_exid_public_bad_pubid)
		W:req(sym.S, lang.xml_exid_sp)
		rv.system_literal = W:req(sym.SystemLiteral, lang.xml_exid_public_bad_syslit)
		return rv, true
	end
end


-- [76] NDataDecl ::= S 'NDATA' S Name
function sym.NDataDecl(W)
	local i = W.I
	if sym.S(W) and W:lit("NDATA") then
		W:req(sym.S, lang.xml_ndata_sp)
		local name = W:req(sym.Name, lang.xml_ndata_bad_name)
		return {id="n_data_decl", name=name}
	end
	W:seek(i)
end


-- [77] TextDecl ::= '<?xml' VersionInfo? EncodingDecl S? '?>'
-- [78] extParsedEnt ::= TextDecl? content
-- External DTD only.


-- (Production [79] (extPE) was removed from the spec.)


-- [80] EncodingDecl ::= S 'encoding' Eq ('"' EncName '"' | "'" EncName "'" )
function sym.EncodingDecl(W)
	local i = W.I
	if sym.S(W) and W:lit("encoding") and sym.Eq(W) then
		-- EncName
		local _, str = W:matchReq("^(['\"])([A-Za-z][A-Za-z0-9._%-]*)%1", lang.xml_encdecl_bad)
		return str
	end
	W:seek(i)
end


-- [81] EncName ::= [A-Za-z] ([A-Za-z0-9._] | '-')*
-- (See [80])


-- [82] NotationDecl ::= '<!NOTATION' S Name S (ExternalID | PublicID) S? '>'
function sym.NotationDecl(W)
	if W:lit("<!NOTATION") then
		W:req(sym.S, lang.xml_notdecl_sp)
		local name = W:req(sym.Name, lang.xml_notdecl_bad_name)
		_nsCheckNoColon(W, name)
		W:req(sym.S, lang.xml_notdecl_sp)

		-- PublicID
		local i = W.I
		if W:lit("PUBLIC") and sym.S(W) then
			local pubid_literal = sym.PubidLiteral(W)
			if pubid_literal then
				sym.S(W)
				if W:lit(">") then
					return true
				end
			end
		end
		W:seek(i)

		local value = sym.ExternalID(W)
		if not value then
			W:error(lang.xml_notdecl_bad_exid)
		end
		sym.S(W)
		W:litReq(">", lang.xml_notdecl_unclosed)
		return true
	end
end



-- [83] PublicID ::= 'PUBLIC' S PubidLiteral
-- (See [82])


-- * Parser Engine: End *


local function assertUTF16Conversion(str, big_endian)
	local err_i, err
	str, err_i, err = pUTF8Conv.utf16_utf8(str, big_endian)
	if not str then
		error(interp(lang.xml_u16_u8_fail, err))
	end
	return str
end


local function errMissingBOM()
	error(lang.xml_u16_missing_bom)
end


local function convertToUTF8(str)
	-- UTF-8
	if string.sub(str, 1, 5) == "<?xml" then
		return str, "UTF-8"

	elseif string.sub(str, 1, 3) == shared.bom_utf8 then
		return str:sub(4), "UTF-8"

	-- UTF-16
	else
		local err_i, err
		if string.sub(str, 1, 10) == shared.decl_utf16_le then
			error(lang.xml_u16_missing_bom)
			errMissingBOM()

		elseif string.sub(str, 1, 2) == shared.bom_utf16_le then
			str = assertUTF16Conversion(str, false)
			return str:sub(4), "UTF-16"

		elseif string.sub(str, 1, 10) == shared.decl_utf16_be then
			errMissingBOM()

		elseif string.sub(str, 1, 2) == shared.bom_utf16_be then
			str = assertUTF16Conversion(str, true)
			return str:sub(4), "UTF-16"
		end
	end

	-- Undetermined. Assume UTF-8.
	return str, "UTF-8"
end


-- https://www.w3.org/TR/REC-xml/#sec-line-ends
function xIn.normalizeLineEndings(s)
	return s:gsub("\r\n?", "\n")
end


function xIn.parse(str, parser)
	_argType(1, str, "string")
	_argType(2, parser, "table")

	local guessed_encoding
	str, guessed_encoding = convertToUTF8(str)

	--[[
	Only certain ranges of Unicode code points are allowed in an XML 1.0 document.
	From Lua, it's easier to check the whole incoming string before processing.
	https://www.w3.org/TR/REC-xml/#charsets
	--]]
	if parser.check_characters then
		shared.assertCharacters(str)
	end

	if parser.normalize_line_endings then
		str = xIn.normalizeLineEndings(str)
	end

	-- String Walker object
	local W = stringWalk.new(str)
	uv_W = W

	W.guessed_encoding = guessed_encoding

	-- Parser settings
	W.parser = parser

	-- The final output
	W.xml_obj = struct.newXMLObject()

	-- Copy some xmlParser settings to xmlObject
	W.xml_obj.namespace_mode = parser.namespace_mode

	-- Current working level
	W.stack = {W.xml_obj}

	-- checks for circular references when expanding replacement text
	-- used both for "Included" and "Included in Literal" rules.
	W.circ = {}

	-- used with option: max_entity_bytes
	-- excludes predefined entities ('&amp;', etc.)
	W.entity_bytes = 0

	-- state related to 'standalone'
	-- https://www.w3.org/TR/REC-xml/#proc-types
	W.hit_pe_ref = false

	-- affects dereferencing of general entities ("bypass" rule)
	W.in_entity_value = false

	-- state related to DOCTYPE markup declarations
	W.in_markup_decl = false

	local document = sym.document(W)

	if #W.stack > 1 then
		error(lang.xml_int_stack_leftover)

	elseif W.I < #W.S then
		error(lang.xml_trailing_content)
	end

	uv_W = nil

	return W.xml_obj, not W.hit_pe_ref
end


return xIn
