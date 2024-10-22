
-- XXX: Under construction.

-- wimp/sash: A window sash. Drag to resize two adjoined widgets.

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
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")


local def = {
	skin_id = "sash1",
}


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true

		self.vertical = false

		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()
	end
end


--function def:uiCall_reshape()


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true
			local skin = self.skin
			self:setCursorLow(self.vertical and skin.cursor_v or skin.cursor_h)
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self:setCursorLow()
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 then
			if self.context.mouse_pressed_button == button then
				self.pressed = true
				local skin = self.skin
				self:setCursorHigh(self.vertical and skin.cursor_v or skin.cursor_h)
			end
		end
	end
end


function def:uiCall_pointerDrag(inst, x, y, dx, dy)
	if self == inst then
		if self.enabled then
			if self.pressed then
				if self.context.mouse_pressed_button == 1 then
					self.x = self.x + dx
				end
			end
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self:setCursorHigh()
				end
			end
		end
	end
end


def.skinners = {
	default = {
		install = function(self, skinner, skin)
			uiTheme.skinnerCopyMethods(self, skinner)
		end,


		remove = function(self, skinner, skin)
			uiTheme.skinnerClearData(self)
		end,


		--refresh = function (self, skinner, skin)
		--update = function(self, skinner, skin, dt)


		render = function(self, ox, oy)
			local skin = self.skin
			local tq_px = skin.tq_px

			love.graphics.setColor(skin.color)
			uiGraphics.quadXYWH(tq_px, 0, 0, self.w, self.h)
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy) end,
	},
}


return def
