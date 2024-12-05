--[[
	Items for menu widgets.

	A menu contains a list of items that are presumed to be arranged sequentially along one axis.
	While you could use nested widgets in a container to fulfill the same functionality, items have
	less overhead, do not support descendants, and you can centralize some state and configuration
	in the widget that owns them.
--]]


local itemOps = {}


--- Base item metatable.
local _mt_item = {}
_mt_item.__index = _mt_item
itemOps._mt_item = _mt_item


--[[
	Tables are chained together with the __index metamethod:

	-- With a def:
	_mt_item_base <- item_def <- item_instance

	-- Without a def:
	_mt_item_base <- item_instance
--]]


local function dummy() end

_mt_item.render = dummy
_mt_item.initInstance = dummy
_mt_item.reshape = dummy


--- The default keyPressed callback for menu items. Pressing enter/return or space activates the item, if it has 'actionable' set truthy.
function _mt_item:menuCall_keyPressed(client, key, scancode, isrepeat)
	if (scancode == "return" or scancode == "kpenter")
	or (scancode == "space" and not isrepeat)
	then
		if self.actionable and self.itemAction_use then
			return self:itemAction_use(client)
		end
	end
end


--- The default pointerPress callback for menu items. It activates menu items upon click, if they have 'actionable' set truthy.
function _mt_item:menuCall_pointerPress(client, button, n_presses)
	if button == 1 and button == client.context.mouse_pressed_button then
		if self.actionable and self.itemAction_use then
			return self:itemAction_use(client)
		end
	end
end


--- Use to activate an item as the user holds the primary mouse button down over it.
function itemOps.item_menuCall_pointerDrag(self, client, button)
	if button == 1 and button == client.context.mouse_pressed_button then
		if self.actionable and self.itemAction_use then
			return self:itemAction_use(client)
		end
	end
end


--- Use to activate an item on unpress. The item must have 'actionable' set truthy.
function itemOps.item_menuCall_pointerRelease(self, client, button)
	if button == 1 and button == client.context.mouse_pressed_button then
		if self.actionable and self.itemAction_use then
			return self:itemAction_use(client)
		end
	end
end


--- Initialize an item definition table. Needs to be called before you create new items based on this def.
-- @param def The def table.
-- @return Nothing.
function itemOps.initDef(def)
	def._mt_inst = {}
	setmetatable(def._mt_inst, def._mt_inst)
	def._mt_inst.__index = def

	setmetatable(def, _mt_item)
end


-- @param item You may set up an item instance table with pre-configured fields ahead of time and pass it here. Do not share in other calls to newItem(). 'x', 'y', 'w' and 'h' default to 0 and must be set after newItem().
function itemOps.newItem(def, client, item)
	item = item or {}
	item.x, item.y, item.w, item.h = 0, 0, 16, 16

	if def then
		setmetatable(item, def._mt_inst)
		def.initInstance(def, client, item)
	else
		setmetatable(item, _mt_item)
	end

	return item
end


itemOps.def_separator = { type = "separator" }


return itemOps
