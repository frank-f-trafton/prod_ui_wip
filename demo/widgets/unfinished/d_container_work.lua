local plan = {}


function plan.make(panel)
	--title("Widget Containers")

	panel:layoutSetBase("viewport-width")
		:containerSetScrollRangeMode("zero")
		:setScrollBars(false, false)

	-- Base container
	local ctnr = panel:addChild("base/container")
		:geometrySetMode("static", 0, 0, 160, 160)
		:containerSetScrollRangeMode("auto")
		:setScrollBars(true, true)
		:reshape()

	local btn = ctnr:addChild("base/button")
		:geometrySetMode("static", 0, 0, 256, 256)
		:setLabel("Button in container")

	-- Simple container
	local cntr_s = panel:addChild("base/container_simple")
		:geometrySetMode("static", 400, 16, 64, 64)

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
end


return plan
