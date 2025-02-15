-- To load: local lib = context:getLua("shared/lib")


--[[
Shared container logic.
--]]


local context = select(1, ...)


local lgcContainer = {}


function lgcContainer.keepWidgetInView(self, wid, pad_x, pad_y)
	-- [XXX 1] There should be an optional rectangle within the widget that gets priority for being in view.
	-- Examples include the caret in a text box, the selection in a menu, and the thumb in a slider bar.

	-- Get widget position relative to this container.
	local x, y = wid:getPositionInAncestor(self)
	local w, h = wid.w, wid.h

	if wid.focal_x then -- [XXX 1] Untested
		x = x + wid.focal_x
		y = y + wid.focal_y
		w = wid.focal_w
		h = wid.focal_h
	end

	local skin = self.skin

	self:scrollRectInBounds(
		x - pad_x,
		y - pad_y,
		x + w + pad_x,
		y + h + pad_y,
		false
	)
end


return lgcContainer