local uiDummy = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pTable = require(PATH .. "lib.pile_table")


uiDummy.func = function() end
uiDummy.table = setmetatable({}, pTable.mt_restrict)


return uiDummy
