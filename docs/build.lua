
-- Libraries
require("src.lib.test.strict")
local inspect = require("src.lib.test.inspect")
local lxl = require("src.lib.lxl.lxl")


local xParser = lxl.newParser()


local function trimLeadingAndTrailingWhitespace(str)
	-- Also trim non-line feed whitespace directly around line feeds.
	str = str:gsub("[\09\10\11\20\32]*\n[\09\10\11\20\32]*", "\n")
	return str:match("^%s*(.-)%s*$")
end


local function isMarkdownLink(str)
	return str:match("%[(.-)%]%((.-)%)")
end


local function loadTextFile(path)
	local file, err
	file, err = io.open(path, "r")
	if not file then
		error(err)
	end

	local str
	str, err = file:read("*a")
	file:close()

	if not str then
		error(err)
	end

	return str
end


-- Right... stock Lua doesn't enumerate files.


local function makeElement(elem, id, v)
	local e2 = elem:newElement(id)
	local str = v[id]
	str = trimLeadingAndTrailingWhitespace(str)
	e2:newCharacterData(str)

	return e2
end


local lua_context_callbacks = require("raw.collections.context_callbacks")
local xml_context_callbacks = lxl.newXMLObject()


do
	local xroot = xml_context_callbacks:newElement(lua_context_callbacks.type)
	xroot:newElement("title"):newCharacterData(lua_context_callbacks.title)
	xroot:newElement("id"):newCharacterData(lua_context_callbacks.id)

	for _, v in ipairs(lua_context_callbacks.main) do
		local e1 = xroot:newElement("callback")
		local e2

		makeElement(e1, "name", v)
		makeElement(e1, "love_callback", v)
		makeElement(e1, "signature", v)
	end
end


print(xParser:toString(xml_context_callbacks))


local lua_widget_events = require("raw.collections.widget_events")
local xml_widget_events = lxl.newXMLObject()

do
	local xroot = xml_widget_events:newElement(lua_widget_events.type)
	xroot:newElement("title"):newCharacterData(lua_widget_events.title)
	xroot:newElement("id"):newCharacterData(lua_widget_events.id)

	for _, v in ipairs(lua_widget_events.main) do
		local e1 = xroot:newElement("event")
		local e2

		makeElement(e1, "name", v)
		makeElement(e1, "propagation_method", v)
		makeElement(e1, "event_origin", v)
		makeElement(e1, "description", v)
		makeElement(e1, "signature", v)

		e2 = e1:newElement("parameters")
		for _, vv in ipairs(v.parameters) do
			makeElement(e2, "name", vv)
			makeElement(e2, "type", vv)
			makeElement(e2, "description", vv)
		end

		if v.returns then
			makeElement(e1, "returns", v)
		end

		if v.example then
			makeElement(e1, "example", v)
		end

		if v.notes then
			makeElement(e1, "notes", v)
		end
	end
end


print(xParser:toString(xml_widget_events))


local lua_widget_callbacks = require("raw.collections.widget_callbacks")
local xml_widget_callbacks = lxl.newXMLObject()

do
	local xroot = xml_widget_callbacks:newElement(lua_widget_callbacks.type)
	xroot:newElement("title"):newCharacterData(lua_widget_callbacks.title)
	xroot:newElement("id"):newCharacterData(lua_widget_callbacks.id)

	for _, v in ipairs(lua_widget_callbacks.main) do
		local e1 = xroot:newElement("callback")
		local e2

		makeElement(e1, "name", v)
		makeElement(e1, "call_site", v)
		makeElement(e1, "description", v)
		makeElement(e1, "signature", v)

		e2 = e1:newElement("parameters")
		for _, vv in ipairs(v.parameters) do
			makeElement(e2, "name", vv)
			makeElement(e2, "type", vv)
			makeElement(e2, "description", vv)
		end

		if v.returns then
			makeElement(e1, "returns", v)
		end

		if v.example then
			makeElement(e1, "example", v)
		end

		if v.notes then
			makeElement(e1, "notes", v)
		end
	end
end


print(xParser:toString(xml_widget_callbacks))


local xml_menus = loadTextFile("raw/menus.xml")
local lua_menus = lxl.toTable(xml_menus)


local hParser = lxl.newParser()
hParser:setWriteXMLDeclaration(false)


local html_out = lxl.newXMLObject()

do
	local xroot = xml_context_callbacks:getRoot()
	local hroot = html_out:newElement("html")

	local hhead = hroot:newElement("head")
	local xtitle = xroot:path("title")
	local htitle = hhead:newElement("title")
	htitle:newCharacterData(xtitle.children[1]:getText())

	local hbody = hroot:newElement("body")

	local xcallback, i = xroot:find("element", "callback")
	print("xcallback", xcallback, "i", i)

	while xcallback do
		local hdiv
		hdiv = hbody:newElement("div"):newCharacterData("Name: " .. xcallback:path("name").children[1]:getText())

		hdiv = hbody:newElement("div")
		local link_str = xcallback:path("love_callback").children[1]:getText()
		local link_name, link_dest = isMarkdownLink(link_str)

		if link_name then
			hdiv:newCharacterData("LÖVE Callback: ")
			local hanchor = hdiv:newElement("a")
			hanchor:setAttribute("href", link_dest)
			hanchor:newCharacterData(link_name)
		else
			hdiv:newCharacterData("LÖVE Callback: " .. link_str)
		end

		hdiv = hbody:newElement("div"):newCharacterData("Signature: " .. xcallback:path("signature").children[1]:getText())

		xcallback, i = xroot:find("element", "callback", i + 1)
	end
end


local str_out = hParser:toString(html_out)
print(str_out)
--[[
local f_out = io.open("test_output.html", "w")
f_out:write(str_out)
f_out:close()
--]]

