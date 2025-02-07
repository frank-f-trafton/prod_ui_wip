**Version:** 2.0.5

# Lua XML Library

A non-validating XML 1.0 processor for Lua 5.1 - 5.4.


# Features:

* Checks XML 1.0 well-formedness (syntax errors)
* UTF-8, UTF-16 encoding
* Namespace 1.0, 1.1 mapping


## Not Supported:

* Does not validate XML documents (that is, check them against a DTD)
* Does not support ignoring syntax errors (like HTML)
* All PEReferences in the DTD Internal Subset are skipped; non-validating processors are not required to handle them.
* Does not directly serialize DOCTYPE (see *Serializing DOCTYPE*)
* No XML 1.1 features


# Example

```lua
-- example1.lua
local lxl = require("path.to.lxl")

local xml_obj = lxl.toTable([=[
<foobar>
 <elem1 a1="Hello" a2="World">Some text.</elem1>
 <empty/>
</foobar>
]=]
)

xml_obj:pruneNodes("comment", "pi")
xml_obj:mergeCharacterData()
xml_obj:pruneSpace()

local root = xml_obj:getRoot()

local e1 = root:find("element", "elem1")

if e1 then
	for k, v in pairs(e1.attr) do
		print(k, v)
	end
end
-- Output (the order may vary):
--[[
a1	Hello
a2	World
--]]


print(lxl.toString(xml_obj))
-- Output:
--[[
<?xml version="1.0" encoding="UTF-8"?>
<foobar>
 <elem1 a1="Hello" a2="World">Some text.</elem1>
 <empty/>
</foobar>
--]]
```


# Files

These files are required:

* `lxl.lua`: The main interface
* `lxl_in.lua`: String-to-table conversion logic
* `lxl_out.lua`: Table-to-string conversion logic
* `lxl_namespace.lua`: XML Namespace logic
* `lxl_shared.lua`: Common data and utility functions
* `lxl_struct.lua`: XML object structures
* Support files:
  * `pile_arg_check.lua`
  * `pile_interp.lua`
  * `pile_table.lua`
  * `pile_utf8.lua`
  * `pile_utf8_conv.lua`
  * `string_proc.lua`
  * `string_walk.lua`


All files beginning with `example` or `test` may be removed.


# API: lxl.lua

## lxl.newParser

Makes a new xmlParser object.

`local parser = lxl.newParser()`

**Returns:** An xmlParser with default settings.


## lxl.toTable

Converts an XML string to an xmlObject (a nested table), with default parser settings.

`local xml_obj = lxl.toTable(str)`

* `str`: The XML string to convert.

**Returns:** An xmlObject.


## lxl.toString

Converts an xmlObject (nested table) to an XML string, with default parser settings.

`local str = lxl.toString(xml_obj)`

* `xml_obj`: The xmlObject to convert.

**Returns:** An XML string.


## lxl.newXMLObject

Creates a new xmlObject with no nodes.

`local xml_obj = lxl.newXMLObject()`

**Returns:** The new xmlObject.


## lxl.load

Loads an XML file from disk and converts it to an xmlObject using the default parser settings.

`local xml_obj = lxl.load(path)`

* `path`: The file path.

**Returns:** The xmlObject.

**Notes:**

* This function is intended for use from the console and the Lua interactive prompt. If your host application provides its own functions to load files (like LÖVE's `love.filesystem`), then you should use those instead.


# API: xmlParser

## xmlParser:setCheckCharacters

*Default: true*

When true, the xmlParser checks incoming XML strings for UTF-8 encoding issues and for code points that are forbidden by the XML spec.

`xmlParser:setCheckCharacters(enabled)`

* `enabled`: `true` to enable character checking, `false/nil` to disable it.

**Notes:**

* This setting is **required** by the spec. You should only disable it if you experience poor performance, or if you are able to check the file ahead of time with an XML linter.


## xmlParser:getCheckCharacters

Gets the setting for checking the encoding of incoming XML strings.

`local enabled = xmlParser:getCheckCharacters()`

**Returns:** `true` if the setting is enabled, `false` otherwise.


## xmlParser:setNamespaceMode

*Default: nil*

Sets the xmlParser's XML Namespace mode.

`xmlParser:setNamespaceVersion(mode)`

* `mode`: `nil` for no namespace functionality while parsing, or the XML Namespace version string (`1.0`, `1.1`).

**Notes:**

* This setting is copied to any xmlObjects created by the xmlParser. (See: *xmlObject:setNamespaceMode*)


## xmlParser:getNamespaceMode

Gets the parser's current XML Namespace mode.

`local version = xmlParser:getNamespaceMode()`

**Returns:** `nil` (namespace state is not active while parsing), `1.0` or `1.1`.


## xmlParser:setCollectComments

*Default: true*

Makes the xmlParser collect or discard XML comments.

`xmlParser:setCollectComments(enabled)`

* `enabled`: `true` to collect comments and attach them to the xmlObject output, `false/nil` to discard them.


## xmlParser:getCollectComments

Gets the current state for collecting comments.

`local enabled = xmlParser:getCollectComments()`

* `enabled`: `true` (comments are collected) or `false`


## xmlParser:setCollectProcessingInstructions

*Default: true*

Makes the xmlParser collect or discard XML processing instructions.

`xmlParser:setCollectProcessingInstructions(enabled)`

* `enabled`: `true` to collect PIs and attach them to the xmlObject output, `false/nil` to discard them.


## xmlParser:getCollectProcessingInstructions

Gets the current state for collecting processing instructions.

`local enabled = xmlParser:getCollectProcessingInstructions()`

* `enabled`: `true` (PIs are collected) or `false`


## xmlParser:setNormalizeLineEndings

*Default: true*

When true, the xmlParser converts instances of `\r\n` and `\r` to just `\n` before processing the document.

`xmlParser:setNormalizeLineEndings(enabled)`

* `enabled`: `true` to normalize newlines, `false/nil` to skip this step.

**Notes:**

* This step is **required** by the XML spec. You should only disable line ending normalization if your application already guarantees that the incoming strings have had this transformation applied.


## xmlParser:getNormalizeLineEndings

Gets the xmlParser state for normalizing line endings.

`local enabled = xmlParser:getNormalizeLineEndings()`

**Returns:** `true` if the parser normalizes line endings, `false` if not.


## xmlParser:setCheckEncodingMismatch

*Default: true*

Makes the xmlParser raise an error if the perceived encoding (based on checking the first few bytes of the document) does not match the encoding declaration in the XML declaration.

In other words: if the xmlParser sees `<?xml version="1.0" encoding="UTF-8" …?>` but the actual encoding is UTF-16, then it raises an error.

`xmlParser:setCheckEncodingMismatch(enabled)`

* `enabled`: `true` (mismatches raise errors) or `false/nil`


## xmlParser:getCheckEncodingMismatch

Gets the current state for encoding mismatches.

`local enabled = xmlParser:getCheckEncodingMismatch()`

**Returns:** `true` (mismatches raise errors) or `false`


## xmlParser:setMaxEntityBytes

*Default: math.huge*

Sets the maximum number of bytes to read from the replacement text of General Entities. When this amount is exceeded, the xmlParser raises a Lua error.

`xmlParser:setMaxEntityBytes(n)`

* `n`: The number of bytes to read. Use `math.huge` to disable the feature.

**Notes:**

* This is a [Billion laughs attack](https://en.wikipedia.org/wiki/Billion_laughs_attack) mitigation.

* Predefined Entities do not contribute to the count. Otherwise, all other replacement text is included: any yet-to-be-processed markup that is nested within a just-expanded general entity will contribute to the total.


## xmlParser:getMaxEntityBytes

Gets the current max entity bytes number.

`local n = xmlParser:getMaxEntityBytes()`

**Returns:** The max entity bytes number.


## xmlParser:setRejectDoctype

*Default: false*

Makes the xmlParser raise an error upon encountering `<!DOCTYPE>`. Some formats based on XML forbid this tag.

`xmlParser:setRejectDoctype(enabled)`

* `enabled`: `true` to reject the DOCTYPE, `false/nil` to accept and parse it (in a non-validating manner).


## xmlParser:getRejectDoctype

Gets the current state for rejecting `<!DOCTYPE>`.

`local rejecting = xmlParser:getRejectDoctype()`

**Returns:** `true` (`<!DOCTYPE>` is being rejected) or `false`.


## xmlParser:setRejectInternalSubset

*Default: false*

Makes the xmlParser raise an error upon encountering a DTD internal subset (the bit that's enclosed in square brackets) within the DOCTYPE.

`xmlParser:setRejectInternalSubset(enabled)`

* `enabled`: `true` to reject DOCTYPEs containing internal subsets, `false/nil` to accept and parse it.

**Notes:**

* Some XML documents contain a harmless DOCTYPE tag that just specifies the root element name, like `<!DOCTYPE foobar>`. This has no effect in a non-validating processor.


## xmlParser:getRejectInternalSubset

Gets the current state for rejecting documents with an internal subset.

`local rejecting = xmlParser:getRejectInternalSubset()`

**Returns:** `true` if internal subsets are being rejected, `false` if not.


## xmlParser:setCopyDocType

*Default: false*

When true, if a `<!DOCTYPE…>` tag is present, the xmlParser stores a substring copy in `xmlObject.doctype_str`.

`xmlParser:setCopyDocType(enabled)`

* `enabled`: `true` to store `<!DOCTYPE>` substrings, `false/nil` otherwise.


## xmlParser:getCopyDocType

Gets the current state for making a copy of the `<!DOCTYPE…>` tag.

`local enabled = xmlParser:getCopyDocType()`

**Returns:** `true` (copy the substring) or `false` (don't).


## xmlParser:setRejectUnexpandedEntities

*Default: false*

When true, halts processing when an Unexpanded entity node would be created and added to the tree. *(See API: Unexp for more info.)*

`xmlParser:setRejectUnexpandedEntities(enabled)`

* `enabled`: `true` to halt on Unexpanded Entities, `false/nil` to attach them to the output tree.


## xmlParser:getRejectUnexpandedEntities

Gets the current state for rejecting Unexpanded Entities.

`local enabled = xmlParser:getRejectUnexpandedEntities()`

**Returns:** `true` (Unexpanded Entities are rejected) or `false` (they are included in the tree).


## xmlParser:setWarnDuplicateEntityDeclarations

*Default: false*

When true, prints a warning to the console when multiple `<!ENTITY…>` declarations with the same name are encountered.

`xmlParser:setWarnDuplicateEntityDeclarations(enabled)`

* `enabled`: `true` to warn about duplicate entity declarations, `false/nil` otherwise.

**Notes:**

* When duplicate entity declarations appear in the internal subset, only the first-encountered declaration is registered.


## xmlParser:getWarnDuplicateEntityDeclarations

Gets the current state for warning about duplicate entity declarations.

`local enabled = xmlParser:getWarnDuplicateEntityDeclarations()`

**Returns:** `true` (warnings are issued to the console) or `false`.


## xmlParser:setWriteXMLDeclaration

*Default: true*

Sets whether the XML declaration is written when serializing out an xmlObject.

`xmlParser:setWriteXMLDeclaration(enabled)`

* `enabled`: `true` to write out the XML declaration, `false/nil` to skip it.


## xmlParser:getWriteXMLDeclaration

Gets the current setting for writing out XML declarations.

`local enabled = xmlParser:getWriteXMLDeclaration()`

**Returns:** `true` (XML declarations are written out) or `false`.


## xmlParser:setWriteDocType

*Default: false*

Sets whether the xmlParser writes a DOCTYPE tag when serializing out an xmlObject.

`xmlParser:setWriteDocType(enabled)`

* `enabled`: `true` to serialize DOCTYPE, `false/nil` otherwise.

**Notes:**

xmlParsers and xmlObjects don't fully track DOCTYPE state. Instead, if `xml_object.doctype_str` is a string, then its contents are inserted before the root element.


## xmlParser:getWriteDocType

Gets the current setting for writing out the DOCTYPE tag.

`local enabled = xmlParser:getWriteDocType()`

**Returns:** `true` (DOCTYPE is being written) or `false`.


## xmlParser:setWritePretty

*Default: true*

Sets the xmlParser state for pretty-printing (added line endings and indentations when serializing out).

`xmlParser:setWritePretty(enabled)`

* `enabled`: `true` to insert line endings and indentations, `false/nil` otherwise.


## xmlParser:getWritePretty

Gets the xmlParser state for pretty-printing.

`local enabled = xmlParser:getWritePretty()`

* `enabled`: `true` (pretty-printing is active) or `false`.


## xmlParser:setWriteIndent

*Default: " ", 1*

Sets the indentation character and quantity for pretty-printing.

`xmlParser:setWriteIndent(ch, [qty])`

* `ch`: The whitespace character to use: ` ` or `\t`.

* `[qty]`: *(1)* The number of `ch` characters to write per indentation level.


## xmlParser:getWriteIndent

Gets the indentation character and quantity for pretty-printing.

`local ch, qty = xmlParser:getWriteIndent()`

**Returns:** The whitespace character (` ` or `\t`) and the number of `ch` characters to write per indentation level.


## xmlParser:setWriteBigEndian

*Default: false (lttle endian)*

Sets the endianness for serialized output when the encoding is UTF-16.

`xmlParser:setWriteBigEndian(enabled)`

* `enabled`: `true` to order bytes as big endian, `false/nil` to order as little endian.


## xmlParser:getWriteBigEndian

Gets the setting for UTF-16 endianness.

`local enabled = xmlParser:getWriteBigEndian()`

**Returns:** `true` (the serialized UTF-16 output is big endian) or `false` (little endian)


## xmlParser:toTable

Converts an XML string to an xmlObject node tree.

`local xml_obj = xmlParser:toTable(str)`

* `str`: The XML string to convert.

**Returns:** An xmlObject.


## xmlParser:toString

Converts an xmlObject to an XML string.

`xmlParser:toString(xml_obj)`

* `xml_obj`: The xmlObject to convert.

**Returns:** An XML string.

**Notes:**

* The string encoding is controlled by the xmlObject's encoding setting. See: *xmlObject:setXMLEncoding*


# API: Tree Nodes

All nodes in an xmlObject tree share a set of basic navigation methods.

## Node:getSiblings

Gets the `children` table in which this node is placed.

`local siblings = Node:getSiblings()`

**Returns:** The table of siblings, or `nil` if the node is the xmlObject (which does not have a parent).


## Node:next

Gets the node's next sibling.

`local sibling = Node:next()`

**Returns:** The node's next sibling, or `nil` if either the node does not have siblings or it is the last sibling in the table.


## Node:prev

Gets the node's previous sibling.

`local sibling = Node:prev()`

**Returns:** The node's previous sibling, or `nil` if either the node does not have siblings or it is the first sibling in the table.


## Node:descend

Gets the node's first child.

`local child_no_1 = Node:descend()`

**Returns:** The node's first child, or `nil` if the node has no children.


## Node:ascend

Gets the node's parent.

`local parent = Node:ascend()`

**Returns:** The node's parent, or `nil` if the node does not have a parent.


## Node:top

Gets the root node (the xmlObject, not the XML root element).

`local xml_obj = Node:top()`

**Returns:** The root node in the tree.


## Node:path

Looks for an element based on a path string. **Paths are not namespace-aware.**

`local resolved = Node:path(path)`

* `path`: The path string.

**Returns:** The resolved node, or `nil` if the node could not be found.

**Notes:**

* The path string contains element names separated by forward slashes. The call `Node:path("foo/bar/baz")` would look for a child of `Node` named `foo`, and then a grandchild named `bar`, and finally a great-grandchild named `baz`. For each generation, the first matching name is selected.

* Paths starting with a forward slash are absolute, always starting from the root xmlObject node (*not* the root element). In this case, the first name in the path must match the root element name. `Node:path("/myroot/foo")`

* As a special case, a single forward slash will select the xmlObject node. `Node:path("/")` is equivalent to `Node:top()`.

* `..` may be used to move up one level, though attempting to go above the xmlObject node will fail. `Node:path("../goback")`

* Only elements and the xmlObject root are eligible for selection, but `Node:path()` can be called by any node object that is attached to the tree. This includes comments and PIs from within the internal subset.


## Node:find

Looks for a node among the calling node's children.

`local result = Node:find(id, [name], [i])`

* `id`: The node's ID tag (type): `cdata`, `comment`, `doctype`, `element`, `pi`, `unexp`, `xml_object`.

* `[name]`: The node's name, if applicable. Pass nothing or `nil` for node types which do not have a name (see notes).

* `i`: *(1)* Index of the first child to check.

**Returns:** A node that matches the search criteria, plus the node's sibling index, or `nil` if there was no match.

**Notes:**

* **This method is not namespace-aware.** See `Node:findNS()` for finding namespaced elements.

* The search does not include grandchildren, great-grandchildren, etc.

* Searches for `cdata`, `comment` and `xml_object` must use `nil` for the name, because these node types do not have names.


## Node:findNS

Looks for a namespaced element among the calling node's children.

`local result = Node:findNS(ns_uri, ns_local, [i])`

* `ns_uri`: The namespace URI (*not* the prefix).

* `ns_local`: The local name.

* `i`: *(1)* Index of the first child to check.

**Returns:** A node that matches the search criteria, plus the node's sibling index, or `nil` if there was no match.

**Notes:**

* The search includes namespaced element nodes only, as XML Namespaces do not apply to any other node type.

* This method always returns `nil` when no namespace mode is set.


## Node:destroy

"Destroys" the node and all of its descendants.

`Node:destroy()`

**Notes:**

* The following occurs when destroying a node:
  * (If applicable) Destroy all descendants recursively
  * (If applicable) Remove node from parent's list of siblings
  * Unset metatable
  * Erase all table contents


# API: xmlObject

xmlObjects represent a document as a tree of nodes. They can be created from a string (`xml.toTable()`, `xmlParser:toTable()`) or by API calls (`xml.newXMLObject()`).


## xmlObject:setXMLVersion

Sets the XML declaration version string.

`xmlObject:setXMLVersion(v)`

* `v`: The XML declaration version string. Use `nil` to clear the value.

**Notes:**

* When not set, assume the default value is `1.0`.


## xmlObject:getXMLVersion

Gets the XML declaration version string.

`local v = xmlObject:setXMLVersion()`

**Returns:** The XML declaration version string, or `nil` if it was not set.


## xmlObject:setXMLEncoding

Sets the XML declaration encoding string.

`xmlObject:setXMLEncoding(e)`

* `e`: The XML declaration encoding string: `UTF-8`, `UTF-16`, or `nil` to clear the value.

**Notes:**

* When not set, assume the default value is `UTF-8`.

* A value of `UTF-16` makes `xmlParser:toString()` encode the output as UTF-16. The endianness is controlled by `xmlParser:setWriteBigEndian()`.


## xmlObject:getXMLEncoding

Gets the XML declaration encoding string.

`local e = xmlObject:getXMLEncoding()`

**Returns:** The XML declaration encoding string, or `nil` if it was not set.


## xmlObject:setXMLStandalone

Sets the XML declaration standalone string.

`xmlObject:setXMLStandalone(s)`

* `s`: The XML declaration standalone string: 'yes', 'no', or pass in `nil` to clear the value.


## xmlObject:getXMLStandalone

Gets the XML declaration standalone string.

`local s = xmlObject:getXMLStandalone()`

**Returns:** The XML declaration standalone string, or `nil` if it was not set.

**Notes:**

* When not set, assume the default value is `no`.


## xmlObject:setNamespaceMode

*Default: nil*

Sets the xmlObject's namespace mode.

`xmlObject:setNamespaceMode(mode)`

* `mode`: The XML Namespace mode string (`1.0`, `1.1`), or `nil` to disable namespace features.


## xmlObject:getNamespaceMode

Gets the xmlObject's current XML Namespace mode.

`local mode = xmlObject:getNamespaceMode()`

**Returns:** The namespace mode: `1.0`, `1.1`, or `nil` (disabled).


## xmlObject:checkNamespaceState

Checks the namespace state of the xmlObject node tree, raising an error if any problems are found.

`xmlObject:checkNamespaceState()`

**Notes:**

* This method does nothing when namespace mode is inactive. Otherwise, it performs the same checks as xmlParser when loading a string. See *Invalid Namespace State* for more info.


## xmlObject:getRoot

Gets the document root element. If the xmlObject does not have any elements, raises a Lua error.

`local root = xmlObject:getRoot()`

**Returns:** The root element.


## xmlObject:getDocType

Gets the DocType node. If the xmlObject does not have a DocType node, returns `nil`.

`local dt = xmlObject:getDocType()`

**Returns:** The DocType node, or `nil` if it wasn't found.


## xmlObject:pruneNodes

Removes nodes of a specified type from the xmlObject tree. Nodes that can contain children (`element`, `doctype`, `xml_object`) cannot be pruned, but their descendants will be checked.

`xmlObject:pruneNodes(...)`

* `...`: The list of node IDs to remove: `cdata`, `comment`, `pi`, `unexp`


## xmlObject:mergeCharacterData

Merges all adjacent CharacterData nodes in the xmlObject tree.

`xmlObject:mergeCharacterData()`

**Notes:**

* Comment nodes will prevent text before and after the node from being merged.

* All affected CharacterData nodes will have their `cd_sect` flag reset to `false`.


## xmlObject:pruneSpace

Deletes all CharacterData nodes which contain only whitespace characters (`\r\n\t\32`).

`xmlObject:pruneSpace(xml_space)`

* `xml_space` When true, do not delete CharacterData nodes where the special attribute `xml:space="preserve"` is in effect.

**Notes:**

* This includes CharacterData nodes marked as CDATA Sections (`cd_sect`).


## xmlObject:newComment

Adds a new comment node, outside of the Document root element.

`local comment = xmlObject:newComment(text, [i])`

* `text`: The comment text.

* `[i]`: *(#children + 1)* Where to insert the comment in the xmlObject's array of children.

**Returns:** A new comment node.


## xmlObject:newProcessingInstruction

Adds a new processing instruction, outside of the Document root element.

`local pi = xmlObject:newProcessingInstruction(name, text, [i])`

* `name`: The processing instruction Target.

* `text`: The processing instruction text body.

* `[i]`: *(#children + 1)* Where to insert the processing instruction in the xmlObject's array of children.

**Returns:** A new processing instruction node.


## xmlObject:newElement

Adds a new element.

`local element = xmlObject:newElement(name, [i])`

* `name`: The element name.

* `[i]`: *(#children + 1)* Where to insert the element in the xmlObject's array of children.

**Returns:** A new element, attached directly to the xmlObject.

**Notes:**

* Attaching more than one top-level element is forbidden by the XML spec.


# API: Element

## Element:getName

Gets the element's Name.

`local name = Element:getName()`

**Returns:** The element's Name.


## Element:setName

Sets the element's Name.

`Element:setName(name)`

* `name`: The name to set.


## Element:getAttribute

Gets an attribute value.

`local val = Element:getAttribute(key)`

* `key`: The attribute Name.

**Returns:** The attribute value, or `nil` if the attribute was not found.


## Element:setAttribute

Sets an attribute value.

`Element:setAttribute(key, value)`

* `key`: The attribute Name.

* `value`: The value to set. Pass `nil` to delete the attribute. Otherwise, this must be a string.


## Element:getNamespace

Gets the element's current namespace mapping.

`local ns_uri = Element:getNamespace()`

**Returns:** The namespace URI associated with this element, or `nil` if there isn't one.

**Notes:**

* This method always returns `nil` when no namespace mode is set.


## Element:getNamespaceAttribute

Gets an attribute that is mapped to a namespace.

`local value, prefix = Element:getNamespaceAttribute(ns_uri, ns_local)`

* `ns_uri`: The namespace URI.

* `ns_local`: The namespace local part.

**Returns:** The attribute value (or `nil` if it's not populated for this namespace), and the prefix (if bound at this scope).

**Notes:**

* This method is unreliable if two attributes with the same local name but different prefixes resolve to the same namespace. Such a state is forbidden by the XML Namespace spec.

* If multiple prefixes are mapped to the URI, then there is no defined order as to which prefix is selected and returned by this method.

* The default namespace is never used with attributes; unprefixed attributes do not belong to a namespace.

* This method always returns `nil` when no namespace mode is set.


## Element:getStableAttributesOrder

Gets a stable order of attribute keys using a simple string sort.

`local order = Element:getStableAttributesOrder()`

**Returns:** An array of keys that correspond to the attributes table.


## Element:getXMLSpecialAttribute

Looks for a special XML attribute in the element and its ancestors, up to the root element. Intended for checking `xml:space` and `xml:lang`.

`Element:getXMLSpecialAttribute(local_name)`

* `local_name`: The second part of the attribute name, after the colon. (`space`, `lang`)

**Returns:** The attribute value and the element in which it was found, or `nil` if there was no match.


## Element:getNamespaceDeclarations

Returns a table containing all namespace declarations from this element and its ancestors.

`local decl = Element:getNamespaceDeclarations([_decl])`

* `[_decl]`: An optional existing table. Used internally to cut down on garbage generation. Note that the table's contents are deleted.

**Returns:** A table of all active namespace declarations for this element.

**Notes:**

* This method always returns an empty table when no namespace mode is set.


## Element:GetNamespaceBinding

Gets a bound prefix for a namespace URI.

`local ns_prefix = Element:GetNamespaceBinding(ns_uri)`

* `ns_uri`: The namespace URI to check.

**Returns:** A bound prefix for the namespace URI, or `nil` if there is no binding at this scope.

**Notes:**

* If multiple prefixes are mapped to the namespace URI, then there is no defined order as to which prefix is selected and returned by this method.

* This method does not consider the predefined prefixes `xml` and `xmlns`.

* This method always returns `nil` when no namespace mode is set.


## Element:newComment

Adds a new comment node.

`local comment = Element:newComment(text, [i])`

* `text`: The comment text.

* `[i]`: *(#children + 1)* Where to insert the comment in the node's array of children.

**Returns:** A new comment node.


## Element:newProcessingInstruction

Adds a processing instruction node.

`local pi = Element:newProcessingInstruction(name, text, [i])`

* `name`: The processing instruction Target.

* `text`: The processing instruction text body.

* `[i]`: *(#children + 1)* Where to insert the processing instruction in the node's array of children.

**Returns:** A new processing instruction node.


## Element:newElement

Adds a new element.

`local element = Element:newElement(name, [i])`

* `name`: The element name.

* `[i]`: *(#children + 1)* Where to insert the element in the node's array of children.

**Returns:** A new element, attached directly to the calling element.


## Element:newCharacterData

Adds a new CharacterData (text) node.

`local char_data = Element:newCharacterData(text, [i])`

* `text`: The CharacterData's text.

* `[cd_sect]`: *(nil)* `true` if this CharacterData node should be serialized out as a CDATA Section.

* `[i]`: *(#children + 1)* Where to insert the CharacterData in the node's array of children.

**Returns:** A new CharacterData, attached directly to the calling element.

**Notes:**

* When xmlParsers convert a string to an xmlObject, they will turn CDATA sections into CharacterData nodes with `cd_sect` set to true.


# API: CharacterData

CharacterData nodes are the document's non-markup text content.


## CharacterData:setText

Sets the CharacterData's text.

`CharacterData:setText(text)`

* `text`: The text to assign.


## CharacterData:getText

Gets the CharacterData's text.

`local text = CharacterData:getText()`

**Returns:** The CharacterData text.


## CharacterData:setCDSect

Sets the CharacterData's `cd_sect` flag. This is a hint to the serializer to output CharacterData in CDATA section form: `<![CDATA[...]]>`

`CharacterData:setCDSect(enabled)`

* `enabled`: `true` to enable CDATA Section output for this node, `false/nil` to not.

**Notes:**

* A CharacterNode's `cd_sect` flag is reset when `xmlObject:mergeCharacterData()` combines text from other nodes.

* The substring `]]>` cannot appear within a CDATA section. If this substring is encountered when serializing, the CDATA section will end, `]]>` will be escaped as `]]&gt;`, and a new CDATA section will begin.


## CharacterData:getCDSect

Gets the CharacterData's `cd_sect` flag.

`local enabled = CharacterData:getCDSect()`

**Returns:** `true` (this node would be serialized as a CDATA Section) or `false`.


# API: Comment

## Comment:getText

Gets the comment's text.

`local text = Comment:getText()`

**Returns:** The comment text.


## Comment:setText

Sets the comment's text.

`Comment:setText(text)`

* `text`: The text to assign.

**Notes:**

* XML comments are not allowed to contain the substring `--` or to end with `-`.


# API: PI (Processing Instruction)


## PI:setTarget

Sets the PI's target (name).

`PI:setTarget(target)`

* `target`: The target to assign.


## PI:getTarget

Gets the PI's target (name).

`local target = PI:getTarget()`.

**Returns:** The PI's target.


## PI:setText

Sets the PI's text.

`PI:setText(text)`

* `text`: The text to assign.

**Notes:**

* XML processing instructions cannot contain the substring `?>`.


## PI:getText

Gets the PI's text.

`local text = PI:getText()`

**Returns:** The PI text.


# API: DOCTYPE

Holds the DOCTYPE Name, along with comments and PIs that are found in the DTD Internal Subset.

This node does not fully represent the DOCTYPE and DTD internal subset, and it is not included when serializing out. (For more info, see: *Serializing DOCTYPE*)

There is almost no reason to create this node manually, so no creation method is attached to the xmlObject.


# API: Unexp (Unexpanded Entity Reference)

A general entity reference (`&foobar;`) that could not be expanded into its replacement text. Unexpanded references are not part of the core XML spec, but they do have an entry in the XML InfoSet.

Normally, an undeclared entity reference halts processing. These nodes can appear in the output when the following conditions are met:

* The `standalone` property is `no` or was not set
* A PEReference is encountered in the DTD internal subset and not read (this processor skips all PEReferences; for more info, see §4.4.8 Included as PE)
* Later, a general entity reference is encountered in the document content, and the XML processor did not collect a declaration that defines it

You will not encounter unexpanded references in a document that lacks a DTD internal subset, or if `standalone` is `yes`, or if the internal subset contains no PEReferences. You will also not see them within attribute values, where failing to dereference a general entity is always an error.

This object addresses the requirement in §4.4.3 to inform the application that an entity was recognized but not dereferenced.

You can halt on all unexpanded entities with `xmlParser:setRejectUnexpandedEntities(true)`.


## Unexp:getName

Gets the unexpanded entity's name. (If the reference is `&foo;`, then the name would be `foo`.)

`local name = Unexp:getName()`

**Returns:** The unexpanded entity's name.


## Unexp:setName

Sets the unexpanded entity's name.

`Unexp:setName(name)`

* `name`: The name to assign.


# Appendix

## Usage Tips

* If you don't need the DTD internal subset, disable it.

* If you don't need XML Namespaces, leave the namespace mode off.


## Terminology

* The term *URI* is used in place of *namespace name* because there are already too many things in the XML spec with the word *name* in their names.

* *PEReference* is used in place of parameter entity reference.


## Handling of PEReferences

(This section originates from a pile of miscellaneous comments for the function *sym.PEReference()* in *lxl_in.lua*.)

As a non-validating processor, we are not obligated to process entity declarations within the replacement text of a PEReference. (See: *Well-formedness constraint: Entity Declared*) In practice, this means that LXL never expands PEReferences.

Unless `standalone` is `yes`, we are not required to process declarations after the first PEReference that is ignored in the internal subset (see: *§4.4.8 Included as PE*).

In the DTD internal subset, PEReferences cannot appear inside of markup declarations. (No nesting, basically.) This rule doesn't apply in the case of external subsets, which we don't touch because this is non-validating. (See: *Well-formedness constraint: PEs in Internal Subset*)

There is a rule to expand PEReferences when they appear in the text of an EntityValue (see: *§4.4.5 Included in Literal*). In the internal subset, this rule never comes into play because it is overridden by *Well-formedness constraint: PEs in Internal Subset*.

The text of *Well-formedness constraint: In DTD* is a little misleading. It says that PEReferences must not appear outside of the DTD. What it means is that substrings like `%foobar;` just won't be recognized as PEReferences elsewhere.

If you read Tim Bray's annotated version of the spec, be sure to cross reference it with the latest edition.


## Serializing DOCTYPE

This library does not fully capture the state of the DOCTYPE tag, and it does not serialize out the `doctype` node (which just contains the DOCTYPE name, and any comments or PIs found within the DTD internal subset). That said, the following methods are provided for collecting the DOCTYPE substring from a document and writing it out.

### Collecting DOCTYPE with xmlParser

Call `xmlParser:setCopyDocType(true)`. If the incoming document contains a DOCTYPE tag, then its substring will be assigned to `xml_object.doctype_str`.


### Writing DOCTYPE with xmlObject

Call `xmlParser:setWriteDocType(true)`. If `xml_object.doctype_str` is a string, then its contents will be inserted before the root element when serializing out. Note that the well-formedness of `doctype_str` is not verified at all.


## Invalid Namespace State

When an xmlParser is configured to handle XML Namespaces, while converting a string to an xmlObject, it will halt when it encounters a namespace-related problem.

The namespace state is invalid when:

* Entity names, processing instruction targets, or notation declaration names contain `:`

* An element or attribute name contains more than one `:`, or the prefix or local parts of a QName are empty (`:bar`, `foo:`)

* Any prefix used in an element or attribute name is not declared in the current scope

* A namespace declaration attempts to bind the namespace `http://www.w3.org/XML/1998/namespace` to any prefix other than `xml`

* A namespace declaration attempts to bind the namespace `http://www.w3.org/2000/xmlns/`

* (XML Namespaces 1.0) A namespace declaration undeclares a prefixed namespace with an empty string

* An element contains duplicate namespaced attributes which resolve to the same URI + local name pair

The situation is different when manipulating an xmlObject node tree. The namespace state in elements is not cached (attempts to do so resulted in brittle code), and the tree's namespace state can be rendered invalid by just renaming an element. You can call `xmlObject:checkNamespaceState()` after changing the tree to perform the same checks as the parser.


# References

* W3C: [Extensible Markup Language (XML) 1.0 (Fifth Edition)](https://www.w3.org/TR/REC-xml/)

* Tim Bray: [The Annotated XML Specification](https://www.xml.com/axml/axml.html)

* W3C: [XML Information Set (Second Edition)](https://www.w3.org/TR/xml-infoset)

* W3C: [Namespaces in XML 1.0 (Third Edition)](https://www.w3.org/TR/REC-xml-names/)

* W3C: [Namespaces in XML 1.1 (Second Edition)](https://www.w3.org/TR/2006/REC-xml-names11-20060816/)


# License (MIT)

```
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
```
