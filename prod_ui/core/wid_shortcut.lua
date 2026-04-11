--[[
Stuff for keyboard shortcuts that are associated with widgets.
--]]


local context = select(1, ...)


local widShortcut = {}


local pTable = require(context.conf.prod_ui_req .. "lib.p_table")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")


local methods = {}


local methodsList = {}


-- Default shortcut handler.
function widShortcut.cb_key_shortcut(self, hot_key, hot_scan)
	local callbacks = self.KS_callbacks
	if callbacks then
		if hot_scan then
			local cb = callbacks[hot_scan]
			if cb and cb(self) then
				return true
			end
		end
		if hot_key then
			local cb = callbacks[hot_key]
			if cb and cb(self) then
				return true
			end
		end
	end
end


function widShortcut.setupDef(def)
	pTable.patch(def, methods)
end


function methods:keyShortcutSet(shortcut, callback)
	uiAssert.type(1, shortcut, "string")
	uiAssert.typeEval(2, callback, "function")

	-- TODO: validate the shortcut.

	self.KS_callbacks = self.KS_callbacks or {}
	self.KS_callbacks[shortcut] = callback or nil

	return self
end


function methods:keyShortcutGet(shortcut)
	return self.KS_callbacks and self.KS_callbacks[shortcut]
end


-- To evaluate a shortcut: self:cb_key_shortcut(hot_key, hot_scan)


function widShortcut.setupDefList(def)
	pTable.patch(def, methodsList)
end


function widShortcut.setupInstanceList(self)
	self.KS_list = {}
end


local function _checkWid(self, wid)
	context:assertWidget(wid)

	if not wid:nodeHasThisAncestor(self) then
		error("widget is not a descendant of self")
	end
end


function methodsList:keyShortcutListAdd(wid)
	_checkWid(self, wid)

	local list = self.KS_list
	table.insert(list, wid)

	return self
end


function methodsList:keyShortcutListRemove(wid)
	_checkWid(self, wid)

	local list = self.KS_list
	local count = pTable.removeValueFromArray(list, wid)
	if count == 0 then
		error("widget wasn't in self's shortcut list")
	end

	return self
end


function widShortcut.evaluateList(self, hot_key, hot_scan)
	local list = self.KS_list

	for i = #list, 1, -1 do
		local wid = list[i]
		if not wid._dead and wid:cb_key_shortcut(hot_key, hot_scan) then
			return
		end
	end
end


return widShortcut
