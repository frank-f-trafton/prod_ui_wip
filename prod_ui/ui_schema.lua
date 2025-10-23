local uiSchema = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pTable = require(REQ_PATH .. "lib.pile_table")
local pSchema = require(REQ_PATH .. "lib.pile_schema")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiTheme = require(REQ_PATH .. "ui_theme")


pTable.patch(uiSchema, pSchema)


local handlers = uiSchema.handlers


-- Handlers: LÖVE


-- Color tables, in the form of {1, 1, 1} (RGB) or {1, 1, 1, 1} (RGBA)
function handlers.loveColorTuple(k, v)
	local count = 0
	if type(v) == "table" and #v >= 3 and #v <= 4 then
		for i, c in ipairs(v) do
			if type(c) == "number" then
				count = count + 1
			end
		end
	end
	if count < 3 then
		return false, "expected color (array of 3-4 numbers)"
	end
	return true
end


-- Handlers: ProdUI


function handlers.slice(k, v)
	local ok, err = pcall(uiTheme.asserts.slice, v)
	if type(v) == "table" then
		return false, "slice validation failed: " .. err
	end
end


return uiSchema
