-- Shared functions for widgets operating under a WIMP tree root.


local context = select(1, ...)


local wcWimp = {}


local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local wcPopUp = context:getLua("shared/wc/wc_pop_up")


function wcWimp.async_widget_destroy(self)
	self:destroy()
end


--- Destroys the UI Frame that this widget belongs to. If called in update, the removal will be handled as an async
--	action after the update loop is complete. If the widget is not within a UI Frame, then nothing happens.
-- @param self Any widget belonging to the current UI Frame, or the UI Frame itself.
-- @return Nothing.
function wcWimp.closeFrame(self)
	local frame = self:getUIFrame()
	if frame then
		if not self.context:isLocked() then
			frame:destroy()
		else
			self.context:appendAsyncAction(frame, wcWimp.async_widget_destroy, false)
		end
	end
end


--- Makes a generic context menu and registers it with the WIMP root.
function wcWimp.makePopUpMenu(self, menu_def, x, y)
	local root = self:nodeGetRoot()

	local pop_up = root:addChild("wimp/menu_pop")
	pop_up.x = x
	pop_up.y = y
	pop_up.wid_ref = self

	-- Append items to fresh menu.
	if menu_def then
		pop_up:applyMenuPrototype(menu_def)
	end

	-- Refresh dimensions and reshape
	pop_up:updateDimensions()
	pop_up:menuChangeCleanup()

	-- Reposition menu so that it's in view
	pop_up:keepInBounds()

	pop_up:menuSetDefaultSelection()

	root:assignPopUp(self, pop_up)

	local do_block
	if root.context.settings then
		do_block = pTable.resolve(root.context.settings, "wimp/pop_up_menu/block_1st_click_out")
	end

	wcPopUp.setBlocking(pop_up, do_block)

	return pop_up
end


-- XXX makePopUpList()


--- Registers a widget as a pop-up in the WIMP root. The caller needs to create and initialize the widget
-- before calling.
function wcWimp.assignPopUp(self, pop_up)
	local root = self:nodeGetRoot()

	pop_up.wid_ref = self

	root:assignPopUp(self, pop_up)
end


-- Destroy the pop-up menu if it exists in reference to this widget.
function wcWimp.checkDestroyPopUp(self)
	local root = self:nodeGetRoot()

	if root.pop_up_menu and root.pop_up_menu.wid_ref == self then
		root:destroyPopUp("concluded")
	end
end


return wcWimp
