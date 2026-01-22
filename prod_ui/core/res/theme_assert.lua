local context = select(1, ...)


local themeAssert = {}


local uiTable = require(context.conf.prod_ui_req .. "ui_table")


-- ie "*foo/bar/baz" -> "foo/bar", "baz"
local function _splitResPath(s, guide)
	if type(s) ~= "string" then
		error("argument #1: expected resource path string (got type: " .. type(s) ..")")

	elseif guide then
		if type(guide) ~= "string" then
			error("argument #2: bad type (expected false/nil or string)")

		elseif (#s < #guide or guide ~= s:sub(1, #guide)) then
			error("expected resource path (" .. s .. ") to begin with: " .. guide)
		end
	end

	local part1, part2 = s:match("^%*(.-)/([^/]+)$")
	if not part1 then
		error("failed to split the resource path string: " .. s)
	end
	return part1, part2
end


-- @param [path_guide] When provided, 'v' must contain 'path_guide' as an exact substring, beginning at index 1.
function themeAssert.linkedResource(n, v, path_guide)
	local part1, part2 = _splitResPath(v)
	local resource_table = uiTable.assertResolve(context.resources, part1)

	if not resource_table[part2] then
		error("missing resource from '" .. pName.get(resource_table) .. "': " .. tostring(v), 2)
	end
end


function themeAssert.linkedResourceEval(n, v, path_guide)
	if v then
		themeAssert.linkedResource(n, v, path_guide)
	end
end


local function _assertLinkedResource(collection_id, label, v, eval)
	if not eval or (eval and v) then
		local part1, part2 = _splitResPath(v)
		if part1 ~= collection_id then
			error("expected this leading path: " .. collection_id)
		end
		if not context.resources[collection_id][part2] then
			error("unprovisioned " .. label .. " resource: " .. tostring(v))
		end
	end
end


function themeAssert.texture(n, v)
	_assertLinkedResource("textures", "Texture", v)
end


function themeAssert.textureEval(n, v)
	_assertLinkedResource("textures", "Texture", v, true)
end


function themeAssert.quad(n, v)
	_assertLinkedResource("quads", "Quad", v)
end


function themeAssert.quadEval(n, v)
	_assertLinkedResource("quads", "Quad", v, true)
end


function themeAssert.slice(n, v)
	_assertLinkedResource("slices", "Slice", v)
end


function themeAssert.sliceEval(n, v)
	_assertLinkedResource("slices", "Slice", v, true)
end


function themeAssert.font(n, v)
	_assertLinkedResource("fonts", "Font", v)
end


function themeAssert.fontEval(n, v)
	_assertLinkedResource("fonts", "Font", v, true)
end


function themeAssert.box(n, v)
	_assertLinkedResource("boxes", "Box", v)
end


function themeAssert.boxEval(n, v)
	_assertLinkedResource("boxes", "Box", v, true)
end


function themeAssert.icon(n, v)
	_assertLinkedResource("icons", "Icon", v)
end


function themeAssert.iconEval(n, v)
	_assertLinkedResource("icons", "Icon", v, true)
end


function themeAssert.info(n, v)
	_assertLinkedResource("info", "InfoTable", v)
end


function themeAssert.infoEval(n, v)
	_assertLinkedResource("info", "InfoTable", v, true)
end


function themeAssert.labelStyle(n, v)
	_assertLinkedResource("labels", "LabelStyle", v)
end


function themeAssert.labelStyleEval(n, v)
	_assertLinkedResource("labels", "LabelStyle", v, true)
end


function themeAssert.pipeStyle(n, v)
	_assertLinkedResource("pipe_styles", "PipeStyle", v)
end


function themeAssert.sashStyle(n, v)
	_assertLinkedResource("sash_styles", "SashStyle", v)
end


function themeAssert.sashStyleEval(n, v)
	_assertLinkedResource("sash_styles", "SashStyle", v, true)
end


function themeAssert.scrollBarData(n, v)
	_assertLinkedResource("scroll_bar_data", "ScrollBarData", v)
end


function themeAssert.scrollBarDataEval(n, v)
	_assertLinkedResource("scroll_bar_data", "ScrollBarData", v, true)
end


function themeAssert.scrollBarStyle(n, v)
	_assertLinkedResource("scroll_bar_styles", "ScrollBarStyle", v)
end


function themeAssert.scrollBarStyleEval(n, v)
	_assertLinkedResource("scroll_bar_styles", "ScrollBarStyle", v, true)
end


return themeAssert
