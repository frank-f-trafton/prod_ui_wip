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
local widShared = context:getLua("core/wid_shared")


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


function def:uiCall_pointerHover(inst, x, y, dx, dy)
	if self == inst then
		if self.enabled then
			if self.aux_pressed then
				self.hovered = false
				self.cursor_hover = nil
			else
				self.hovered = true
				if self.aux_enabled then
					self.cursor_hover = self.skin.cursor_on
				else
					local mx, my = self:getRelativePosition(x, y)
					if self.vp3:pointOverlap(mx, my) then
						self.cursor_hover = nil
					else
						self.cursor_hover = self.skin.cursor_on
					end
				end
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, x, y, dx, dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
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
						if not self.vp3:pointOverlap(mx, my) then
							self.pressed = true
							self.cursor_press = self.skin.cursor_press

						-- aux button part (sticky)
						elseif self.aux_enabled and not self.aux_pressed then
							self.pressed = true
							self.aux_pressed = true
							self.cursor_press = nil
							self.cursor_hover = nil

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


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					if not self.aux_pressed then
						self.pressed = false
						self.cursor_press = nil
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
					if not self.aux_pressed and not self.vp3:pointOverlap(mx, my) then
						self:wid_buttonAction()
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
	self.thimble_mode = 1

	widShared.setupViewports(self, 3)

	lgcLabel.setup(self)

	-- [XXX 8] (Optional) graphic associated with the button.
	--self.graphic = <tq>

	-- Aux button state.
	self.aux_enabled = true
	self.aux_pressed = false

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false

	self:skinSetRefs()
	self:skinInstall()

	self:reshape()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the main text bounding box.
	-- Viewport #2 is the main graphic drawing rectangle.
	-- Viewport #3 is the aux bounding box.

	local skin = self.skin
	local vp, vp2, vp3 = self.vp, self.vp2, self.vp3

	vp:set(0, 0, self.w, self.h)
	vp:reduceSideDelta(skin.box.border)
	vp:splitOrOverlay(vp2, skin.graphic_placement, skin.graphic_spacing)
	vp2:reduceSideDelta(skin.box.margin)

	local aux_sz
	if skin.aux_size == "auto" then
		if skin.aux_placement == "right" or skin.aux_placement == "left" then
			aux_sz = vp2.h
		else -- "top", "bottom"
			aux_sz = vp2.w
		end
	else
		aux_sz = skin.aux_size
	end

	vp:split(vp3, skin.aux_placement, aux_sz)

	lgcLabel.reshapeLabel(self)

	return true
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 3)
	end
end


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.slice(res, "slice")
	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_label")
	check.colorTuple(res, "color_aux_icon")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.labelStyle(skin, "label_style")
		check.quad(skin, "tq_px")

		-- Cursor IDs for hover and press states.
		check.type(skin, "cursor_on", "nil", "string")
		check.type(skin, "cursor_press", "nil", "string")

		-- Alignment of label text in Viewport #1.
		check.enum(skin, "label_align_h")
		check.enum(skin, "label_align_v")

		-- A default graphic to use if the widget doesn't provide one.
		-- TODO
		-- graphic

		-- Icon to show in the aux part of the button.
		check.quad(skin, "tq_aux_glyph")
		check.exact(skin, "aux_placement", "left", "right", "top", "bottom")

		-- Aux part size (width for 'left' and 'right' placement; height for 'top' and 'bottom' placement)
		-- "auto": size is based on Viewport #2
		-- "auto": size is based on Viewport #2
		check.numberOrExact(skin, "aux_size", 0, nil, "auto")

		-- Quad (graphic) alignment within Viewport #2.
		check.enum(skin, "quad_align_h")
		check.enum(skin, "quad_align_v")

		-- Placement of graphic in relation to text labels.
		check.enum(skin, "graphic_placement")

		-- How much space to assign the graphic when not using "overlay" placement.
		check.number(skin, "graphic_spacing", 0, nil, nil)

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_hover")
		_checkRes(skin, "res_pressed")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "aux_size", scale)
		change.integerScaled(skin, "graphic_spacing", scale)

		_changeRes(skin, "res_idle", scale)
		_changeRes(skin, "res_hover", scale)
		_changeRes(skin, "res_pressed", scale)
		_changeRes(skin, "res_disabled", scale)
	end,


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
		local vp3 = self.vp3
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
		if     skin.aux_placement == "left"   then vx, vy, vw, vh = vp3.x + vp3.w - 1, vp3.y, 1, vp3.h - 1
		elseif skin.aux_placement == "right"  then vx, vy, vw, vh = vp3.x, vp3.y, 1, vp3.h
		elseif skin.aux_placement == "top"    then vx, vy, vw, vh = vp3.x, vp3.y + vp3.h - 1, vp3.w - 1, 1
		elseif skin.aux_placement == "bottom" then vx, vy, vw, vh = vp3.x, vp3.y, vp3.w - 1, 1 end
		uiGraphics.quadXYWH(tq_px, vx + res.label_ox, vy + res.label_oy, vw, vh)

		-- aux part icon
		local aux_color = self.aux_enabled and res.color_aux_icon or skin.res_disabled.color_aux_icon
		love.graphics.setColor(aux_color)
		uiGraphics.quadShrinkOrCenterXYWH(
			skin.tq_aux_glyph,
			vp3.x + res.label_ox,
			vp3.y + res.label_oy,
			vp3.w,
			vp3.h
		)

		love.graphics.pop()

		local graphic = self.graphic or skin.graphic
		if graphic then
			lgcGraphic.render(self, graphic, skin, res.color_quad, res.label_ox, res.label_oy, ox, oy)
		end

		if self.label_mode then
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
