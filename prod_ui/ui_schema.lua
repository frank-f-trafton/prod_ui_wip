local uiSchema = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pTable = require(REQ_PATH .. "lib.pile_table")
local pSchema = require(REQ_PATH .. "lib.pile_schema")


pTable.patch(uiSchema, pSchema)


-- Handlers: LÖVE
-- TODO


-- Handlers: ProdUI
-- TODO


return uiSchema
