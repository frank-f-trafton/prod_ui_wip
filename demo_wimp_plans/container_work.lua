
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")


local plan = {
	container_type = "base/container"
}


function plan.make(panel)
	--title("Widget Containers")

	panel:setScrollBars(false, false)

	-- Base container
	local ctnr = panel:addChild("base/container")
	ctnr.x = 0
	ctnr.y = 0
	ctnr.w = 160
	ctnr.h = 160
	ctnr:initialize()
	ctnr:register("static")
	ctnr:setScrollBars(true, true)

	ctnr:reshape()

	local btn = ctnr:addChild("base/button")
	btn.x = 0
	btn.y = 0
	btn.w = 256
	btn.h = 256
	btn:initialize()
	btn:register("static")
	btn:setLabel("Button in container")


	-- Simple container
	local cntr_s = panel:addChild("base/container_simple")
	cntr_s.x, cntr_s.y, cntr_s.w, cntr_s.h = 400, 16, 64, 64
	cntr_s.usr_text = "<Simple Container>"
	cntr_s.wid_pressed = function()
		cntr_s.usr_text = "I've been clicked!"
	end
	cntr_s.render = function(self, ox, oy)
		love.graphics.push("all")

		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.rectangle("fill", 0, 0, self.w - 1, self.h - 1)

		love.graphics.setColor(1, 1, 1, 1)
		local font = self.context.resources.fonts.internal
		love.graphics.setFont(font)
		love.graphics.printf(cntr_s.usr_text, 0, 0, self.w, "center")

		love.graphics.pop()
	end
	cntr_s:initialize()
	cntr_s:register("static")
end


return plan
