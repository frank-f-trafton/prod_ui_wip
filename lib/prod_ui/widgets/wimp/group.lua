
-- XXX: Under construction.

--[[
A widget container with a label and outline / perimeter.


     Label text
         |
         v
+--- Some Group ---+  --\
|         [BUTTON] |    |
| [Button]         |    >-- Perimeter
|          [Btn]   |    |
+------------------+  --/

--]]


local context = select(1, ...)


local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "group1",
}


function def:setText(text)
	self.text = text
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true

		self.text = ""

		self.enabled = true

		self:skinSetRefs()
		self:skinInstall()
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


		--refresh = function(self, skinner, skin)
		--update = function(self, skinner, skin, dt)


		render = function(self, ox, oy)

			local skin = self.skin
			local font = skin.font

			--[[
			local res
			if self.enabled then
				res = (self.wid_drawer) and skin.res_pressed or skin.res_idle

			else
				res = skin.res_disabled
			end
			--]]

			love.graphics.push("all")

			-- Perimeter outline.
			if skin.show_perimeter then
				love.graphics.setColor(skin.color_perimeter)
				uiGraphics.drawSlice(skin.slc_perimeter_a, 0, 0, self.w, self.h) -- XXX: unfinished.
				uiGraphics.drawSlice(skin.slc_perimeter_b, 0, 0, self.w, self.h)
				uiGraphics.drawSlice(skin.slc_perimeter_c, 0, 0, self.w, self.h)
			end

			-- Text.
			if self.text ~= "" then
				love.graphics.setColor(skin.color_text)
				love.graphics.print(self.text) -- XXX: placement.
			end

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
