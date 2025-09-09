local uiTable = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pTable = require(REQ_PATH .. "lib.pile_table")


pTable.patch(uiTable, pTable)


return uiTable
