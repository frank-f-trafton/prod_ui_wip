local uiScale = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pScale = require(REQ_PATH .. "lib.pile_scale")
local pTable = require(REQ_PATH .. "lib.pile_table")


pTable.patch(uiScale, pScale)


return uiScale
