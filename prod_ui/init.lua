local REQ_PATH = ... and ((...) .. ".") or ""


local M = {}


M.assert = require(REQ_PATH .. "ui_assert")
M.context = require(REQ_PATH .. "ui_context")
M.dummy = require(REQ_PATH .. "ui_dummy")
M.graphics = require(REQ_PATH .. "ui_graphics")
M.keyboard = require(REQ_PATH .. "ui_keyboard")
M.load = require(REQ_PATH .. "ui_load")
M.pop_up_menu = require(REQ_PATH .. "ui_pop_up_menu")
M.res = require(REQ_PATH .. "ui_res")
M.schema = require(REQ_PATH .. "ui_schema")
M.table = require(REQ_PATH .. "ui_table")
M.theme = require(REQ_PATH .. "ui_theme")


return M
