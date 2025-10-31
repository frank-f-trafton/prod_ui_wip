local uiSchema = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pTable = require(REQ_PATH .. "lib.pile_table")
local pSchema = require(REQ_PATH .. "lib.pile_schema")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiAssert = require(REQ_PATH .. "ui_assert")


pTable.patch(uiSchema, pSchema)


return uiSchema
