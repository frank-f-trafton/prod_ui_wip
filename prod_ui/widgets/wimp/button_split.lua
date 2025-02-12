--[[
A button with a main part and a secondary part which performs a different action (typically opening a pop-up menu).

 Main button part
       │
       v
┌────────────┬───┐
│ New        │ v │  <--- Auxiliary button part
└───┬────────┴───┤
    │ Dog        │
    │ Cat        │
    │ Hamster    │  <--- Pop-up menu, created by hitting the aux part
    │ Turtle     │
    │ Houseplant │
    └────────────┘
--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local lgcGraphic = context:getLua("shared/lgc_graphic")
local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "button_split1",
}


def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3
def.wid_buttonActionAux = function(self) end


def.setEnabled = lgcButton.setEnabled
def.setLabel = lgcLabel.widSetLabel


function def:setAuxEnabled(enabled)
	self.aux_enabled = not not enabled
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			if not self.aux_pressed then
				self.hovered = true
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			if not self.aux_pressed then
				self.hovered = false
			end
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					if not self.aux_pressed then
						local mx, my = self:getRelativePosition(x, y)
						-- main button part
						if not widShared.pointInViewport(self, 3, mx, my) then
							self.pressed = true

						-- aux button part (sticky)
						elseif self.aux_enabled and not self.aux_pressed then
							self.pressed = true
							self.aux_pressed = true

							-- Press action
							self:wid_buttonActionAux()

							-- Halt propagation (to prevent snatching the thimble
							-- from the newly-made pop-up menu).
							return true
						end
					end

				elseif not self.aux_pressed then
					if button == 2 then
						-- Instant second action.
						self:wid_buttonAction2()

					elseif button == 3 then
						-- Instant tertiary action.
						self:wid_buttonAction3()
					end
				end
			end
		end
	end
end


function def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					local mx, my = self:getRelativePosition(x, y)
					-- main button part
					if not self.aux_pressed and not widShared.pointInViewport(self, 3, mx, my) then
						self.pressed = false
						self:wid_buttonAction()
					end
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
					if not self.aux_pressed then
						self.pressed = false
					end
				end
			end
		end
	end
end


def.uiCall_thimbleAction = lgcButton.uiCall_thimbleAction
def.uiCall_thimbleAction2 = lgcButton.uiCall_thimbleAction2


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupViewports(self, 3)

	lgcLabel.setup(self)

	-- [XXX 8] (Optional) graphic associated with the button.
	--self.graphic = <tq>

	-- Aux button state
	self.aux_enabled = true
	self.aux_pressed = false

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self.cursor_hover = self.skin.cursor_on
	self.cursor_press = self.skin.cursor_press

	self:reshape()
end


function def:uiCall_reshape()
	-- Viewport #1 is the main text bounding box.
	-- Viewport #2 is the main graphic drawing rectangle.
	-- Viewport #3 is the aux bounding box.

	local skin = self.skin

	local aux_sz
	if skin.aux_size == "auto" then
		if skin.aux_placement == "right" or skin.aux_placement == "left" then
			aux_sz = self.vp2_h
		else -- "top", "bottom"
			aux_sz = self.vp2_w
		end
	else
		aux_sz = skin.aux_size
	end

	widShared.resetViewport(self, 1)
	widShared.partitionViewport(self, 1, 3, aux_sz, skin.aux_placement, false) -- no "overlay"
	widShared.carveViewport(self, 1, skin.box.border)
	widShared.partitionViewport(self, 1, 2, skin.graphic_spacing, skin.graphic_placement, true)
	widShared.carveViewport(self, 2, skin.box.margin)
	lgcLabel.reshapeLabel(self)
end


def.default_skinner = {
	schema = {
		main = {
			aux_size = "scaled-int",
			graphic_spacing = "scaled-int",
			res_idle = "&res",
			res_hover = "&res",
			res_pressed = "&res",
			res_disabled = "&res"
		},
		res = {
			label_ox = "scaled-int",
			label_oy = "scaled-int"
		}
	},


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
		local res = uiTheme.pickButtonResource(self, skin)

		local slc_body = res.slice
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

		local tq_px = skin.tq_px

		-- draw a line between the main and aux parts of the button
		love.graphics.push("all")

		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
		-- (get coordinates for the line)
		local vx, vy, vw, vh
		if     skin.aux_placement == "left"   then vx, vy, vw, vh = self.vp3_x + self.vp3_w - 1, self.vp3_y, 1, self.vp3_h - 1
		elseif skin.aux_placement == "right"  then vx, vy, vw, vh = self.vp3_x, self.vp3_y, 1, self.vp3_h
		elseif skin.aux_placement == "top"    then vx, vy, vw, vh = self.vp3_x, self.vp3_y + self.vp3_h - 1, self.vp3_w - 1, 1
		elseif skin.aux_placement == "bottom" then vx, vy, vw, vh = self.vp3_x, self.vp3_y, self.vp3_w - 1, 1 end
		uiGraphics.quadXYWH(tq_px, vx + res.label_ox, vy + res.label_oy, vw, vh)

		-- aux part icon
		local aux_color = self.aux_enabled and res.color_aux_icon or skin.res_disabled.color_aux_icon
		love.graphics.setColor(aux_color)
		uiGraphics.quadShrinkOrCenterXYWH(
			skin.tq_aux_glyph,
			self.vp3_x + res.label_ox,
			self.vp3_y + res.label_oy,
			self.vp3_w,
			self.vp3_h
		)

		love.graphics.pop()

		local graphic = self.graphic or skin.graphic
		if graphic then
			lgcGraphic.render(self, graphic, skin, res.color_quad, res.label_ox, res.label_oy, ox, oy)
		end

		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end

		-- XXX: Debug border (viewport rectangle)
		--[[
		local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
		widDebug.debugDrawViewport(self, 1)
		widDebug.debugDrawViewport(self, 2)
		widDebug.debugDrawViewport(self, 3)
		--]]
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
