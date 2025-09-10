-- The prototype API for WIMP pop up menus (wimp/menu_pop).


local uiPopUpMenu = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiAssert = require(REQ_PATH .. "ui_assert")


-- forward declarations
local _mt_proto, _mt_command, _mt_group, _mt_separator


local function _setText(self, text)
	uiAssert.type1(1, text, "string")

	self.text = text

	return self
end


local function _getText(self)
	return self.text
end


local function _setTextShortcut(self, text)
	uiAssert.typeEval1(1, text, "string")

	self.text_shortcut = text or nil

	return self
end


local function _getTextShortcut(self)
	return self.text_shortcut
end


local function _setKeyMnemonic(self, text)
	uiAssert.typeEval1(1, text, "string")

	self.key_mnemonic = text or nil

	return self
end


local function _getKeyMnemonic(self)
	return self.key_mnemonic
end


local function _setKeyShortcut(self, text)
	uiAssert.typeEval1(1, text, "string")

	self.key_shortcut = text or nil

	return self
end


local function _getKeyShortcut(self)
	return self.key_shortcut
end


local function _setIconID(self, text)
	uiAssert.typeEval1(1, text, "string")

	self.icon_id = text or nil

	return self
end


local function _getIconID(self)
	return self.icon_id
end


local function _setCallback(self, fn)
	uiAssert.typeEval1(1, fn, "function")

	self.callback = fn or nil

	return self
end


local function _getCallback(self)
	return self.callback
end


local function _setConfig(self, config)
	uiAssert.typeEval1(1, config, "function")

	self.config = config

	return self
end


local function _getConfig(self)
	return self.config
end


local function _setActionable(self, enabled)
	uiAssert.typeEval1(1, enabled, "boolean")

	self.actionable = enabled

	return self
end


local function _getActionable(self)
	return self.actionable
end


local function _setGroupPrototype(self, proto)
	uiAssert.typeEval1(1, proto, "table")
	if getmetatable(proto) ~= _mt_proto then
		error("expected a pop up menu prototype (wrong metatable)")
	end

	self.group_prototype = proto

	return self
end


local function _getGroupPrototype(self)
	return self.group_prototype
end


_mt_command = {
	type = "command",
	text = "",
	text_shortcut = false,
	key_mnemonic = false,
	key_shortcut = false,
	icon_id = false,
	callback = false,
	config = false,
	actionable = true,

	setText = _setText,
	getText = _getText,
	setTextShortcut = _setTextShortcut,
	getTextShortcut = _getTextShortcut,
	setKeyMnemonic = _setKeyMnemonic,
	getKeyMnemonic = _getKeyMnemonic,
	setKeyShortcut = _setKeyShortcut,
	getKeyShortcut = _getKeyShortcut,
	setIconID = _setIconID,
	getIconID = _getIconID,
	setCallback = _setCallback,
	getCallback = _getCallback,
	setConfig = _setConfig,
	getConfig = _getConfig,
	setActionable = _setActionable,
	getActionable = _getActionable
}
_mt_command.__index = _mt_command


function uiPopUpMenu.newCommand()
	return setmetatable({}, _mt_command)
end


_mt_group = {
	type = "group",
	text = "",
	key_mnemonic = false,
	icon_id = false,
	group_prototype = false,
	config = false,
	actionable = true,

	setText = _setText,
	getText = _getText,
	setKeyMnemonic = _setKeyMnemonic,
	getKeyMnemonic = _getKeyMnemonic,
	setIconID = _setIconID,
	getIconID = _getIconID,
	setGroupPrototype = _setGroupPrototype,
	getGroupPrototype = _getGroupPrototype,
	setConfig = _setConfig,
	getConfig = _getConfig,
	setActionable = _setActionable,
	getActionable = _getActionable
}
_mt_group.__index = _mt_group


function uiPopUpMenu.newGroup()
	return setmetatable({}, _mt_group)
end


_mt_separator = {
	type = "separator"
}
_mt_separator.__index = _mt_separator


function uiPopUpMenu.newSeparator()
	return setmetatable({}, _mt_separator)
end


_mt_proto = {}
_mt_proto.__index = _mt_proto
uiPopUpMenu._mt_proto = _mt_proto


function uiPopUpMenu.assertPrototypeItems(proto)
	for i, item in ipairs(proto) do
		uiAssert.fieldType1(proto, "proto", i, "table")
		local mt = getmetatable(item)
		if mt ~= _mt_command and mt ~= _mt_group and mt ~= _mt_separator then
			error("prototype item #" .. i .. ": invalid item (wrong metatable)")
		end
	end
end


function uiPopUpMenu.newMenuPrototype(proto)
	uiAssert.typeEval1(1, proto, "table")

	proto = proto or {}

	uiPopUpMenu.assertPrototypeItems(proto)

	return setmetatable(proto, _mt_proto)
end


function _mt_proto:configure(client)
	for i, item in ipairs(self) do
		if item.config then
			item.actionable = item.config(client)
		end
	end
end


uiPopUpMenu.P = {
	command = uiPopUpMenu.newCommand,
	group = uiPopUpMenu.newGroup,
	separator = uiPopUpMenu.newSeparator,

	prototype = uiPopUpMenu.newMenuPrototype
}


return uiPopUpMenu
