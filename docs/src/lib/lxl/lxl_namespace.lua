-- XML Namespace logic.


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local namespace = {}


local shared = require(PATH .. "lxl_shared")


local lang = shared.lang
local interp = shared._interp


namespace.predefined = {
	xml = "http://www.w3.org/XML/1998/namespace",
	xmlns = "http://www.w3.org/2000/xmlns/"
}


function namespace.checkQName(s, err_hand)
	local i = s:find(":")
	-- unprefixed local name
	if not i then
		if #s == 0 then
			err_hand(lang.err_ns_empty_local)
		else
			return nil, s
		end
	-- "prefix:local"
	else
		if i == 1 then
			err_hand(lang.err_ns_empty_prefix)

		elseif i == #s then
			err_hand(lang.err_ns_empty_local)

		-- (NS §3 Declaring Namespaces)
		-- (NCName can't contain a colon)
		elseif s:find(":", i + 1) then
			err_hand(lang.err_ns_colon_local)

		else
			return s:sub(1, i - 1), s:sub(i + 1)
		end
	end
end


function namespace.checkNoColon(s, err_hand)
	err_hand = err_hand or _nsErrHandDefault

	if s:find(":") then
		err_hand(lang.err_ns_invalid_colon)
	end
end


local function _nsErrHandDefault(s)
	error(s)
end


function namespace.checkElement(elem, ns_mode, err_hand)
	err_hand = err_hand or _nsErrHandDefault

	-- The XML processor is not required to check that URI/IRI references are valid.

	-- check declarations
	for key, val in pairs(elem.attr) do
		local xml_prefix, local_name = namespace.checkQName(key, err_hand)
		-- default namespace
		if not xml_prefix and local_name == "xmlns" then
			-- (Namespace constraint: Reserved Prefixes and Namespace Names)
			-- The predefined URIs for 'xml' and 'xmlns' cannot be declared as the default namespace.
			for k, v in pairs(namespace.predefined) do
				if v == val then
					err_hand(lang.err_ns_predef_def)
				end
			end

		-- prefixed namespace
		elseif xml_prefix == "xmlns" then
			-- (Namespace constraint: Reserved Prefixes and Namespace Names)
			-- 'xml' may be declared, but it cannot be bound to any URI other than the predefined value.
			if local_name == "xml" and val ~= namespace.predefined["xml"] then
				err_hand(lang.err_ns_bad_xml_pre)

			-- 'xmlns' cannot be declared.
			elseif local_name == "xmlns" then
				err_hand(lang.err_ns_invalid_xmlns_pre)

			-- other prefixes may not be bound to the 'xml' predefined URI.
			elseif val == namespace.predefined["xml"] then
				err_hand(lang.err_ns_bad_xml_bind)

			-- other prefixes may not be bound to the 'xmlns' predefined URI.
			elseif val == namespace.predefined["xmlns"] then
				err_hand(lang.err_ns_bad_xmlns_bind)

			-- Mapping prefixes to empty names is an error in NS 1.0, but permitted in NS 1.1
			elseif ns_mode == "1.0" and val == "" then
				err_hand(lang.err_ns_empty_ns_uri)
			end
		end
	end

	local decl = elem:getNamespaceDeclarations()
	local dupes = {}

	-- check namespaced attributes
	for key, val in pairs(elem.attr) do
		local xml_prefix, local_name = namespace.checkQName(key, err_hand)
		if xml_prefix and local_name and xml_prefix ~= "xml" and xml_prefix ~= "xmlns" then
			if not decl[xml_prefix] then
				err_hand(lang.err_ns_undef_ns)
			end
		end

		-- an element must not contain namespaced attributes with the same URI and local name
		if xml_prefix and xml_prefix ~= "xml" and xml_prefix ~= "xmlns" then
			local combined = decl[xml_prefix] .. local_name
			if dupes[combined] then
				err_hand(lang.err_ns_dupe_attr)
			end
			dupes[combined] = true
		end
	end

	-- check element name.
	local ns_prefix, ns_local = namespace.checkQName(elem.name, err_hand)

	-- element name: no prefix-to-namespace binding
	if ns_prefix and not decl[ns_prefix] then
		err_hand(lang.err_ns_undef_ns)

	-- element name: must not be prefixed with 'xmlns'
	elseif ns_prefix == "xmlns" then
		err_hand(lang.err_ns_elem_xmlns)
	end
end


return namespace
