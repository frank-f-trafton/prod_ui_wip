-- Common shared functions for widgets operating under a WIMP tree root.


local commonWimp = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local utilTable = require(REQ_PATH .. "util_table")


function commonWimp.async_widget_remove(self)
	self:remove()
end


-- Gets the WIMP Window Frame that a widget belongs to.
-- @param self Any widget descendent of a window frame, or the window frame itself.
-- @return The Window Frame, or nil if a frame was not found.
function commonWimp.getFrame(self)
	local wid = self
	while wid do
		if wid.is_frame then
			return wid
		end
		wid = wid.parent
	end
end


--- Destroy the window frame that this widget belongs to. If called in update, the removal will be handled as an async action after the update loop is complete.
-- @param self Any widget belonging to the current window frame, or the window frame itself.
-- @return Nothing.
function commonWimp.closeWindowFrame(self)
	local wid = self
	while wid do
		if wid.is_frame then
			if not self.context:isLocked() then
				wid:remove()
			else
				self.context:appendAsyncAction(wid, commonWimp.async_widget_remove, false)
			end

			return
		end

		wid = wid.parent
	end
end


--- Makes a generic context menu and registers it with the WIMP root.
function commonWimp.makePopUpMenu(self, menu_def, x, y)
	local root = self:getRootWidget()

	local pop_up = root:addChild("wimp/menu_pop")
	pop_up.x = x
	pop_up.y = y
	pop_up:initialize()
	pop_up.wid_ref = self

	-- Append items to fresh menu.
	if menu_def then
		for i, item_guide in ipairs(menu_def) do
			pop_up:appendItem(item_guide.type, item_guide)
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
		do_block = utilTable.tryDrill(root.context.settings, "/", "wimp/pop_up_menu/block_1st_click_out")
	end

	pop_up:setBlocking(do_block)

	return pop_up
end


-- XXX makePopUpList()


--- Registers a widget as a pop-up in the WIMP root. The caller needs to create and initialize the widget
-- before calling.
function commonWimp.assignPopUp(self, pop_up)
	local root = self:getRootWidget()

	pop_up.wid_ref = self

	root:sendEvent("rootCall_assignPopUp", self, pop_up)
end


-- Destroy the pop-up menu if it exists in reference to this widget.
function commonWimp.checkDestroyPopUp(self)
	local root = self:getRootWidget()

	if root.pop_up_menu and root.pop_up_menu.wid_ref == self then
		root:sendEvent("rootCall_destroyPopUp", self, "concluded")
	end
end


return commonWimp
