local plan = {
	container_type = "base/container"
}


local itemOps = require("prod_ui.common.item_ops")


-- Menu item defs
local idef_sep = {}

--idef_sep.initInstance = -- ...

idef_sep.render = function(self, client, ox, oy)
	love.graphics.setLineWidth(1)
	love.graphics.line(self.x + 0.5, self.y + math.floor(self.h/2) + 0.5, self.w - 1, self.h - 1)
end
itemOps.initDef(idef_sep)


local idef_text = {}
idef_text.initInstance = function(def, client, self)
	self.text = ""
	self.text_x = 0
	self.text_y = 0
end
idef_text.reshape = function(self, client)
	local font = client.skin.font_item
	self.text_x = math.floor(0.5 + self.w/2 - font:getWidth(self.text)/2)
	self.text_y = math.floor(0.5 + self.h/2 - font:getHeight()/2)
end
idef_text.render = function(self, client, ox, oy)
	if self.multi_select then -- test...
		love.graphics.push("all")

		love.graphics.setColor(0.2, 0.2, 0.5, 1.0)
		love.graphics.setLineWidth(3)
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineJoin("miter")
		love.graphics.rectangle("line", self.x + 0.5, self.y + 0.5, self.w - 1, self.h - 1)

		love.graphics.pop()
	end
	-- (font is set by client widget ahead of time)
	love.graphics.print(self.text, self.x + self.text_x, self.y + self.text_y)
end
itemOps.initDef(idef_text)


local function testMultiSelect(self, client) -- XXX test
	self.multi_select = not self.multi_select

	print("self.multi_select", self.multi_select)
end


local function testMultiSelectClick(self, client, button, multi_presses)
	print("testMultiSelectClick", self, client, button, multi_presses)
	testMultiSelect(self, client)
end


local function testMultiSelectKey(self, client, kc, sc, isrep)
	testMultiSelect(self, client)
end


local function testMenuKeyPressed(self, key, scancode, isrepeat)
	-- Debug
	if scancode == "insert" then
		local new_item = itemOps.newItem(idef_text, self)

		new_item.x = 0
		new_item.y = 0
		new_item.w = 48--192
		new_item.h = 48

		new_item.text = "#" .. #self.items + 1--"filler entry #" .. #self.items + 1
		new_item.selectable = true
		new_item.type = "press_action"

		new_item.itemAction_use = testMultiSelectClick

		self:addItem(new_item, math.max(1, self.index))
		self:menuChangeCleanup()

		return true

	-- Debug
	elseif scancode == "delete" then
		if self.index > 0 then
			self:removeItem(self.index)
			self:menuChangeCleanup()
		end

		return true
	end

	return false
end


function plan.make(panel)
	--title("Menu Test")

	panel:setScrollBars(false, false)

	local menu1 = panel:addChild("base/menu")
	menu1.x = 16
	menu1.y = 16
	menu1.w = 400
	menu1.h = 350
	menu1.wid_keyPressed = testMenuKeyPressed
	menu1.MN_drag_select = true
	menu1:initialize()

	menu1:setScrollBars(true, true)

	menu1:reshape()
end


return plan
