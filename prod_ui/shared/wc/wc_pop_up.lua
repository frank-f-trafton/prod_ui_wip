--[[
Widget Component: Pop Up

Usage:

* Run 'wcContainer.setupInstance()' on the widget instance during creation.
--]]


local context = select(1, ...)


local wcPopUp = {}


local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")


function wcPopUp.blocking_ui_evaluateHover(self, mx, my, os_x, os_y)
	return true
end


function wcPopUp.blocking_ui_evaluatePress(self, mx, my, os_x, os_y, button, istouch, presses)
	return true
end


function wcPopUp.setupInstance(self)
	self.is_blocking_clicks = false
end


function wcPopUp.setBlocking(self, enabled)
	if enabled then
		self.is_blocking_clicks = true
		self.ui_evaluateHover = wcPopUp.blocking_ui_evaluateHover
		self.ui_evaluatePress = wcPopUp.blocking_ui_evaluatePress
	else
		self.is_blocking_clicks = false
		self.ui_evaluateHover = nil
		self.ui_evaluatePress = nil
	end
end


function wcPopUp.checkBlocking(self)
	local root = self:nodeGetRoot()
	local do_block
	if root.context.settings then
		do_block = pTable.resolve(root.context.settings, "wimp/pop_up_menu/block_1st_click_out")
	end
	wcPopUp.setBlocking(self, do_block)
end


return wcPopUp
