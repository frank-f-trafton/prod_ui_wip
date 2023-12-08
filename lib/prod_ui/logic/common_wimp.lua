-- Common shared functions for widgets operating under a WIMP tree root.


local commonWimp = {}


function commonWimp.async_widget_remove(self)
	self:remove()
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


function commonWimp.makePopUpMenu(self, menu_def, x, y)

	local root = self:getTopWidgetInstance()

	local pop_up = root:addChild("wimp/menu_pop")

	pop_up.x = x
	pop_up.y = y
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
	pop_up:keepInView()

	pop_up.menu:setSelectedDefault()

	root:runStatement("rootCall_assignPopUp", self, pop_up)

	return pop_up
end


-- XXX makePopUpList()


return commonWimp

