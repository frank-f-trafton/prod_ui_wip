local context = select(1, ...)


local lgcPopUps = {}


local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")


function lgcPopUps.blocking_ui_evaluateHover(self, mx, my, os_x, os_y)
	return true
end


function lgcPopUps.blocking_ui_evaluatePress(self, mx, my, os_x, os_y, button, istouch, presses)
	return true
end


function lgcPopUps.setupInstance(self)
	self.is_blocking_clicks = false
end


function lgcPopUps.setBlocking(self, enabled)
	if enabled then
		self.is_blocking_clicks = true
		self.ui_evaluateHover = lgcPopUps.blocking_ui_evaluateHover
		self.ui_evaluatePress = lgcPopUps.blocking_ui_evaluatePress
	else
		self.is_blocking_clicks = false
		self.ui_evaluateHover = nil
		self.ui_evaluatePress = nil
	end
end


function lgcPopUps.checkBlocking(self)
	local root = self:getRootWidget()
	local do_block
	if root.context.settings then
		do_block = pTable.resolve(root.context.settings, "/wimp/pop_up_menu/block_1st_click_out")
	end
	self:setBlocking(do_block)
end


return lgcPopUps
