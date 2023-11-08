-- To load: local lib = context:getLua("shared/lib")

--[[
Shared code for single static graphics in widgets.
--]]


local context = select(1, ...)


local lgcGraphic = {}


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


function lgcGraphic.render(self, graphic, skin, color, graphic_ox, graphic_oy, ox, oy)

	--[[
	Expects: self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h
	--]]

	love.graphics.setColor(color)

	-- Calculate alignment within Viewport #2.
	local qx, qy, qw, qh = graphic.quad:getViewport()
	local tx
	if skin.quad_align_h == "left" then
		tx = 0

	elseif skin.quad_align_h == "right" then
		tx = math.floor(0.5 + self.vp2_w - qw)

	else -- "center"
		tx = math.floor(0.5 + (self.vp2_w - qw) * 0.5)
	end

	local ty
	if skin.quad_align_v == "top" then
		ty = 0

	elseif skin.quad_align_v == "bottom" then
		ty = math.floor(0.5 + self.vp2_h - qh)

	else -- "middle"
		ty = math.floor(0.5 + (self.vp2_h - qh) * 0.5)
	end

	-- XXX: Scissor to Viewport?

	uiGraphics.quadXYWH(graphic, self.vp2_x + tx + graphic_ox, self.vp2_y + ty + graphic_oy, qw, qh)
end


return lgcGraphic

