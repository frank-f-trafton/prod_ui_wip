-- Helpers for writing WIMP pop up menu definitions (wimp/menu_pop).


local popUpMenuPrototype = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiAssert = require(REQ_PATH .. "ui_assert")
local uiTable = require(REQ_PATH .. "ui_table")


local P = {}
popUpMenuPrototype.P = P


local _keys_command = uiTable.makeLUTV(
	"text",
	"text_shortcut",
	"key_mnemonic",
	"key_shortcut",
	"icon_id",
	"callback",
	"config",
	"actionable"
)


local _keys_group = uiTable.makeLUTV(
	"text",
	"key_mnemonic",
	"icon_id",
	"group_def",
	"config",
	"actionable"
)


--key_mnemonic
function P.command(info)
	uiAssert.type1(1, info, "table")

	uiAssert.fieldType1(info, "info", "text", "string")
	uiAssert.fieldTypeEval1(info, "info", "text_shortcut", "string")
	uiAssert.fieldTypeEval1(info, "info", "key_mnemonic", "string")
	uiAssert.fieldTypeEval1(info, "info", "key_shortcut", "string")
	uiAssert.fieldTypeEval1(info, "info", "icon_id", "string")
	uiAssert.fieldTypeEval1(info, "info", "callback", "function")
	uiAssert.fieldTypeEval1(info, "info", "config", "function")
	uiAssert.fieldTypeEval1(info, "info", "actionable", "boolean")

	for k in pairs(info) do
		if not _keys_command[k] then
			error("invalid field for commands: " .. tostring(k))
		end
	end

	return {
		type = "command",
		text = info.text,
		text_shortcut = info.text_shortcut or nil,
		key_mnemonic = info.key_mnemonic or nil,
		key_shortcut = info.key_shortcut or nil,
		icon_id = info.icon_id or nil,
		callback = info.callback or nil,
		config = info.config or nil,
		actionable = info.actionable or nil
	}
end


function P.group(info)
	uiAssert.type1(1, info, "table")

	uiAssert.fieldType1(info, "info", "text", "string")
	uiAssert.fieldTypeEval1(info, "info", "key_mnemonic", "string")
	uiAssert.fieldTypeEval1(info, "info", "icon_id", "string")
	uiAssert.fieldTypeEval1(info, "info", "group_def", "table")
	uiAssert.fieldTypeEval1(info, "info", "config", "function")

	for k in pairs(info) do
		if not _keys_group[k] then
			error("invalid field for groups: " .. tostring(k))
		end
	end

	return {
		type = "group",
		text = info.text,
		key_mnemonic = info.key_mnemonic or nil,
		icon_id = info.icon_id or nil,
		group_def = info.group_def or nil,
		config = info.config or nil
	}
end


function P.separator()
	return {
		type="separator"
	}
end


function popUpMenuPrototype.configurePrototype(self, array)
	for i, tbl in ipairs(array) do
		if tbl.config then
			tbl.actionable = tbl.config(self)
		end
	end
end


return popUpMenuPrototype
