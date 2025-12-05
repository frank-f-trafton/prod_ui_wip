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


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcButton = context:getLua("shared/wc/wc_button")
local wcGraphic = context:getLua("shared/wc/wc_graphic")
local wcLabel = context:getLua("shared/wc/wc_label")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "button_split1",
}


def.wid_buttonAction = wcButton.wid_buttonAction
def.wid_buttonAction2 = wcButton.wid_buttonAction2
def.wid_buttonAction3 = wcButton.wid_buttonAction3
def.wid_buttonActionAux = function(self) end


def.setEnabled = wcButton.setEnabled
def.setLabel = wcLabel.widSetLabel


function def:setAuxEnabled(enabled)
	self.aux_enabled = not not enabled
end


function def:evt_pointerHover(inst, x, y, dx, dy)
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
					if self.vp2:pointOverlap(mx, my) then
						self.cursor_hover = nil
					else
						self.cursor_hover = self.skin.cursor_on
					end
				end
			end
		end
	end
end


function def:evt_pointerHoverOff(inst, x, y, dx, dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
		end
	end
end


function def:evt_pointerPress(inst, x, y, button, istouch, presses)
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
						if not self.vp2:pointOverlap(mx, my) then
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


function def:evt_pointerUnpress(inst, x, y, button, istouch, presses)
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


function def:evt_pointerRelease(inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					local mx, my = self:getRelativePosition(x, y)
					-- main button part
					if not self.aux_pressed and not self.vp2:pointOverlap(mx, my) then
						self:wid_buttonAction()
					end
				end
			end
		end
	end
end


def.evt_thimbleAction = wcButton.evt_thimbleAction
def.evt_thimbleAction2 = wcButton.evt_thimbleAction2


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 3)

	wcLabel.setup(self)

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
end


function def:evt_reshapePre()
	-- Viewport #1 is the text bounding box.
	-- Viewport #2 is the aux bounding box (for clicking).
	-- Viewport #3 is the aux bounding box (for placement of the graphic).

	local skin = self.skin
	local vp, vp2, vp3 = self.vp, self.vp2, self.vp3

	vp:set(0, 0, self.w, self.h)

	-- determine the aux button size
	local aux_sz
	if skin.aux_size == "auto" then
		if skin.aux_placement == "right" or skin.aux_placement == "left" then
			aux_sz = self.h
		else -- "top", "bottom"
			aux_sz = self.w
		end
	else
		aux_sz = skin.aux_size
	end

	vp:split(vp2, skin.aux_placement, aux_sz)
	vp2:copy(vp3)
	vp:reduceT(skin.box.border)
	vp3:reduceT(skin.box.margin)

	wcLabel.reshapeLabel(self)

	return true
end


function def:evt_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 3)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	slice = themeAssert.slice,

	color_body = uiAssert.loveColorTuple,
	color_label = uiAssert.loveColorTuple,
	color_aux_icon = uiAssert.loveColorTuple,

	label_ox = uiAssert.integer,
	label_oy = uiAssert.integer
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		label_style = themeAssert.labelStyle,
		tq_px = themeAssert.quad,

		-- Cursor IDs for hover and press states.
		cursor_on = {uiAssert.types, "nil", "string"},
		cursor_press = {uiAssert.types, "nil", "string"},

		-- Alignment of label text in Viewport #1.
		label_align_h = {uiAssert.namedMap, uiTheme.named_maps.label_align_h},
		label_align_v = {uiAssert.namedMap, uiTheme.named_maps.label_align_v},

		-- A default graphic to use if the widget doesn't provide one.
		-- TODO
		-- graphic

		-- Icon to show in the aux part of the button.
		tq_aux_glyph = themeAssert.quad,
		aux_placement = {uiAssert.oneOf, "left", "right", "top", "bottom"},

		-- Aux part size (width for 'left' and 'right' placement; height for 'top' and 'bottom' placement)
		-- "auto": size is based on Viewport #2
		aux_size = {uiAssert.numberGEOrOneOf, 0, "auto"},

		-- Quad (graphic) alignment within Viewport #2.
		quad_align_h = {uiAssert.namedMap, uiTheme.named_maps.quad_align_h},
		quad_align_v = {uiAssert.namedMap, uiTheme.named_maps.quad_align_v},

		-- Placement of graphic in relation to text labels.
		graphic_placement = {uiAssert.namedMap, uiTheme.named_maps.graphic_placement},

		-- How much space to assign the graphic when not using "overlay" placement.
		graphic_spacing = {uiAssert.numberGE, 0},

		res_idle = md_res,
		res_hover = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "aux_size")
		uiScale.fieldInteger(scale, skin, "graphic_spacing")

		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "label_ox")
			uiScale.fieldInteger(scale, res, "label_oy")
		end

		_changeRes(scale, skin.res_idle)
		_changeRes(scale, skin.res_hover)
		_changeRes(scale, skin.res_pressed)
		_changeRes(scale, skin.res_disabled)
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
		local vp2, vp3 = self.vp2, self.vp3
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
		if     skin.aux_placement == "left"   then vx, vy, vw, vh = vp2.x + vp2.w - 1, vp3.y, 1, vp3.h - 1
		elseif skin.aux_placement == "right"  then vx, vy, vw, vh = vp2.x, vp3.y, 1, vp3.h
		elseif skin.aux_placement == "top"    then vx, vy, vw, vh = vp3.x, vp2.y + vp2.h - 1, vp3.w - 1, 1
		elseif skin.aux_placement == "bottom" then vx, vy, vw, vh = vp3.x, vp2.y, vp3.w - 1, 1 end
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
			wcGraphic.render(self, graphic, skin, res.color_quad, res.label_ox, res.label_oy, ox, oy)
		end

		if self.label_mode then
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
