
-- ProdUI
local commonMenu = require("prod_ui.logic.common_menu")
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.logic.wid_shared")


local plan = {}


function plan.make(parent)

	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Widget Containers")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		-- Base container
		local ctnr = content:addChild("base/container")
		ctnr.x = 0
		ctnr.y = 0
		ctnr.w = 160
		ctnr.h = 160
		ctnr:setScrollBars(true, true)

		ctnr:reshape(true)

		local btn = ctnr:addChild("base/button")
		btn.x = 0
		btn.y = 0
		btn.w = 256
		btn.h = 256

		btn:setLabel("Button in container")


		-- Simple container
		local cntr_s = content:addChild("base/container_simple")
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
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
