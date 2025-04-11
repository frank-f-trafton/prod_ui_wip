-- ProdUI: Theme support functions.


local uiTheme = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- ProdUI
local commonMath = require(REQ_PATH .. "common.common_math")
local pTable = require(REQ_PATH .. "lib.pile_table")
local pUTF8 = require(REQ_PATH .. "lib.pile_utf8")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
local uiGraphics = require(REQ_PATH .. "ui_graphics")
local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")


local _mt_themeInst = {}
_mt_themeInst.__index = _mt_themeInst


--- Pick a resource table in a skin based on three common widget state flags: self.enabled, self.pressed and self.hovered.
-- @param self The widget instance, containing a skin table reference.
-- @param skin The skin table, or a sub-table.
-- @return The selected resource table.
function uiTheme.pickButtonResource(self, skin)
	if not self.enabled then
		return skin.res_disabled

	elseif self.pressed then
		return skin.res_pressed

	elseif self.hovered then
		return skin.res_hover

	else
		return skin.res_idle
	end
end


function uiTheme.skinnerCopyMethods(self, skinner)
	self.render = skinner.render
	self.renderLast = skinner.renderLast
	self.renderThimble = skinner.renderThimble
end


function uiTheme.skinnerClearData(self)
	self.render = nil
	self.renderLast = nil
	self.renderThimble = nil

	for k, v in pairs(self) do
		if type(k) == "string" and string.sub(k, 1, 3) == "sk_" then
			self[k] = nil
		end
	end
end


return uiTheme
