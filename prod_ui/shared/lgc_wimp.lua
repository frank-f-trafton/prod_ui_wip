-- Shared functions for widgets operating under a WIMP tree root.


local context = select(1, ...)


local lgcWimp = {}


local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")


function lgcWimp.async_widget_remove(self)
	self:remove()
end


--- Destroy the UI Frame that this widget belongs to. If called in update, the removal will be handled as an async action after the update loop is complete.
-- @param self Any widget belonging to the current UI Frame, or the UI Frame itself.
-- @return Nothing.
function lgcWimp.closeFrame(self)
	local wid = self
	while wid do
		if wid.frame_type then
			if not self.context:isLocked() then
				wid:remove()
			else
				self.context:appendAsyncAction(wid, lgcWimp.async_widget_remove, false)
			end

			return
		end

		wid = wid.parent
	end
end


--- Makes a generic context menu and registers it with the WIMP root.
function lgcWimp.makePopUpMenu(self, menu_def, x, y)
	local root = self:getRootWidget()

	local pop_up = root:addChild("wimp/menu_pop")
	pop_up.x = x
	pop_up.y = y
	pop_up:initialize()
	pop_up.wid_ref = self

	-- Append items to fresh menu.
	if menu_def then
		for i, item_guide in ipairs(menu_def) do
			pop_up:appendItem(item_guide)
		end
	end

	-- Refresh dimensions and reshape
	pop_up:updateDimensions()
	pop_up:menuChangeCleanup()

	-- Reposition menu so that it's in view
	pop_up:keepInBounds()

	pop_up:menuSetDefaultSelection()

	root:sendEvent("rootCall_assignPopUp", self, pop_up)

	local do_block
	if root.context.settings then
		do_block = pTable.resolve(root.context.settings, "/wimp/pop_up_menu/block_1st_click_out")
	end

	pop_up:setBlocking(do_block)

	return pop_up
end


-- XXX makePopUpList()


--- Registers a widget as a pop-up in the WIMP root. The caller needs to create and initialize the widget
-- before calling.
function lgcWimp.assignPopUp(self, pop_up)
	local root = self:getRootWidget()

	pop_up.wid_ref = self

	root:sendEvent("rootCall_assignPopUp", self, pop_up)
end


-- Destroy the pop-up menu if it exists in reference to this widget.
function lgcWimp.checkDestroyPopUp(self)
	local root = self:getRootWidget()

	if root.pop_up_menu and root.pop_up_menu.wid_ref == self then
		root:sendEvent("rootCall_destroyPopUp", self, "concluded")
	end
end


return lgcWimp
