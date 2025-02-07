-- LXL out: Converts an xmlObject table to an XML string.
-- (Use this module through lxl.lua)


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local xOut = {}


local interp = require(PATH .. "pile_interp")
local pUTF8Conv = require(PATH .. "pile_utf8_conv")
local shared = require(PATH .. "lxl_shared")
local struct = require(PATH .. "lxl_struct")


local lang = shared.lang


local _argType = require(PATH .. "pile_arg_check").type
local _assertXMLName = shared._assertXMLName
local _assertPITarget = shared._assertPITarget
local _assertCommentText = shared._assertCommentText


local function _checkQuote(s)
	-- return values: escape `"` T/F, enclosing quote character
	-- we never escape `'`
	local q1, q2 = s:find("'", 1, true), s:find("\"", 1, true)
	if q1 and q2 then
		return true, "\""

	elseif q1 then
		return false, "\""

	elseif q2 then
		return false, "'"

	else
		return false, "\""
	end
end


-- upvalues for xOut.escapeXMLString()
local uv_q2, uv_in_attrib


-- for xOut.escapeXMLString()
local function hof_escape(m)
	if not uv_in_attrib and m == "]]>" then
		return "]]&gt;"

	elseif (uv_q2 and m == "\"") or m == "&" or m == "<" then
		return "&" .. shared.lut_default_rev[m] .. ";"
	end
end


function xOut.escapeXMLString(s, in_attrib)
	_argType(1, s, "string")

	local enclosing_quote
	uv_q2, enclosing_quote = _checkQuote(s)
	uv_in_attrib = not not in_attrib
	return s:gsub("%]?%]?['\"<>&]", hof_escape), enclosing_quote
end


function xOut.escapeCDSect(s)
	_argType(1, s, "string")
	s = "<![CDATA[" .. s:gsub("%]%]>", "]]>]]&gt;<![CDATA[") .. "]]>"
	return s
end



local function _serializeAttrib(name, value)
	local quote
	value, quote = xOut.escapeXMLString(value, true)
	return name .. "=" .. quote .. value .. quote
end


-- Handles the STag or EmptyElemTag of an Element.
local function _elementXMLString(self)
	local seq = {"<"}
	table.insert(seq, self.name)

	-- Attributes
	if next(self.attr) then
		table.insert(seq, " ")
		local order = self:getStableAttributesOrder()
		for j, name in ipairs(order) do
			local value = self.attr[name]
			_assertXMLName(name)
			shared.assertCharacters(value)
			table.insert(seq, _serializeAttrib(name, value))
			table.insert(seq, " ")
		end
	end

	-- Snip off any trailing whitespace separators
	while seq[#seq] == " " do
		table.remove(seq)
	end
	if #self.children == 0 then
		table.insert(seq, "/")
	end
	table.insert(seq, ">")

	return table.concat(seq)
end


local function _indent(seq, level, space)
	if level > 0 and space ~= "" then
		table.insert(seq, string.rep(space, level))
	end
end


local function _hasChildElements(self)
	for i, child in ipairs(self.children) do
		if child.id == "element" then
			return true
		end
	end
end


local function _dumpTree(self, seq, _depth, newline, space, flags)
	for i, child in ipairs(self.children) do
		if child.id == "element" then
			_assertXMLName(child.name)
			if self.id == "xml_object" then
				if flags.wrote_root then
					error(lang.xml_out_1root)
				end
				flags.wrote_root = true
			end

			if self.id == "element" then
				table.insert(seq, newline)
				_indent(seq, _depth, space)
			end
			table.insert(seq, _elementXMLString(child))

			if #child.children > 0 then
				--table.insert(seq, newline)
				--_indent(seq, _depth, space)
				_dumpTree(child, seq, _depth + 1, newline, space, flags)

				-- close tag
				if _hasChildElements(child) then
					table.insert(seq, newline)
					_indent(seq, _depth, space)
				end
				table.insert(seq, "</" .. child.name .. ">")
			end

		elseif child.id == "pi" then
			_assertPITarget(child.name)
			shared.assertCharacters(child.text)
			shared._assertPIText(child.text)
			table.insert(seq, "<?" .. child.name .. " " .. child.text .. "?>" .. newline)

		elseif child.id == "cdata" then
			shared.assertCharacters(child.text)
			if child.cd_sect then
				table.insert(seq, xOut.escapeCDSect(child.text))
			else
				local value = xOut.escapeXMLString(child.text) -- cut off 2nd return value
				table.insert(seq, value)
			end

		elseif child.id == "unexp" then
			_assertXMLName(child.name)
			table.insert(seq, "&" .. child.name .. ";")

		elseif child.id == "comment" then
			shared.assertCharacters(child.text)
			_assertCommentText(child.text)

			table.insert(seq, "<!--" .. child.text .. "-->")

		elseif child.id == "doctype" then
			-- The DocType node is not serialized. This includes any comments or PIs that
			-- were picked up by the parser. For more info, check xOut.parse() and the
			-- search the README for 'doctype_str'.

		else
			error(lang.xml_out_bad_node)
		end
	end
end


function xOut.parse(xml_obj, parser)
	_argType(1, xml_obj, "table")
	if xml_obj.id ~= "xml_object" then
		error(lang.xml_out_expect_xml_obj)
	end
	_argType(2, parser, "table")

	local newline, space
	if parser.out_pretty then
		newline, space = "\n", string.rep(parser.out_indent_ch, parser.out_indent_qty)
	else
		newline, space = "", ""
	end

	local version = xml_obj.version or "1.0"
	local encoding = xml_obj.encoding or "UTF-8"
	local standalone = xml_obj.standalone or nil

	local ok, err = shared.checkXMLDecl(version, encoding, standalone)
	if not ok then
		error(interp(lang.xml_out_bad_decl, err))
	end

	local seq = {}
	if encoding == "UTF-16" then
		-- This Byte Order Mark will be converted to UTF-16 later.
		seq[#seq + 1] = shared.bom_utf8
	end

	if parser.out_xml_decl then
		table.insert(seq, "<?xml version=\"" .. version .. "\"")

		if encoding then
			table.insert(seq, " encoding=\"" .. encoding .. "\"")
		end
		if standalone then
			table.insert(seq, " standalone=\"" .. standalone .. "\"")
		end
		table.insert(seq, "?>" .. newline)
	end

	if parser.out_doc_type and type(xml_obj.doctype_str) == "string" then
		table.insert(seq, xml_obj.doctype_str .. newline)
	end

	local flags = {}
	_dumpTree(xml_obj, seq, 0, newline, space, flags)

	if not flags.wrote_root then
		error(lang.xml_out_0root)
	end

	local str = table.concat(seq)
	if encoding == "UTF-16" then
		local err_i, err
		str, err_i, err = pUTF8Conv.utf8_utf16(str, parser.out_big_endian)
		if not str then
			error(interp(lang.xml_out_u16_conv_fail, err))
		end
	end

	return str
end


return xOut
