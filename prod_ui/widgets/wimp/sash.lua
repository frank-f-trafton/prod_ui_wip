
-- XXX: Under construction.

-- wimp/sash: drag to resize two adjoined widgets.

--[[
Horizontal split:

     Widgets
    │      │
    v      v
┌───────┬───────┐
│       ┆       │
│   A   ┆   B   │
│       ┆       │
│       ┆       │
└───────┴───────┘
        ^
        │
      Sash
  Drag to resize


Vertical split:

┌────────────┐
│     A      │
│            │
├┄┄┄┄┄┄┄┄┄┄┄┄┤
│     B      │
│            │
└────────────┘
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


local def = {}


function def:uiCall_create(inst)
	if self == inst then
		-- XXX: SkinDef.
		self.visible = false
		self.allow_hover = true

		self.vertical = false
	end
end


--function def:uiCall_reshape()


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and button == 1
	and self.context.mouse_pressed_button == button
	then
		-- XXX
	end

	-- return nil
end


-- Debug visualizer
function def:render(os_x, os_y)
	love.graphics.setScissor()

	love.graphics.setColor(1.0, 0.0, 0.0, 1.0)

	love.graphics.setLineWidth(1)
	love.graphics.setLineJoin("miter")
	love.graphics.setLineStyle("rough")

	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)
end


return def
