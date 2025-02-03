
-- XXX: Under construction.

-- wimp/sash: Drag to resize a widget along one side.

--[[
┌─────┐╷
│     │┆ Sash on widget's right side
│ Wid │┆ <->
│     │┆
└─────┘╵
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "sash1",
}


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true

	widShared.setupViewports(self, 1)

	self.enabled = true
	self.hovered = false
	self.pressed = false

	-- attachment details
	self.att_ref = false
	self.att_side = "right" -- "left", "right", "top", "bottom"

	-- length of the attached widget at start of drag state
	self.att_len = 0

	-- mouse cursor absolute position at start of drag state
	self.att_ax, self.att_ay = 0, 0

	self:skinSetRefs()
	self:skinInstall()
end


function def:getAttachedWidget()
	return self.att_ref
end


-- @param wid The widget to attach, or false/nil to remove any attached widget. The widget to attach must not be in a dying or dead state.
function def:setAttachedWidget(wid)
	uiShared.typeEval1(1, wid, "table")

	if not wid then
		self.att_ref = false
		return

	elseif wid._dead then
		error("attempted to attach a dead or dying widget")
	end

	self.att_ref = wid
end


function def:getSide()
	return self.att_side
end


function def:setSide(side)
	if side ~= "left" and side ~= "right" and side ~= "top" and side ~= "bottom" then
		error("invalid 'side' argument")
	end
	self.att_side = side
end


function def:uiCall_reshape()
	-- Viewport #1 is the drag sensor region.

	local skin = self.skin
	widShared.resetViewport(self, 1)
	local marg = math.floor(skin.sensor_margin / 2)
	if self.att_side == "right" or self.att_side == "left" then
		self.w = skin.breadth
		self.vp_x = self.vp_x + marg
		self.vp_w = math.max(0, self.vp_w - marg)
	else
		self.h = skin.breadth
		self.vp_y = self.vp_y + marg
		self.vp_h = math.max(0, self.vp_h - marg)
	end

	-- The layout system is responsible for placement of sashes.
end



function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true

			local mx, my = self:getRelativePosition(mouse_x, mouse_y)
			if widShared.pointInViewport(self, 1, mx, my) then
				local skin = self.skin
				self:setCursorLow(self.vertical and skin.cursor_v or skin.cursor_h)
			else
				self:setCursorLow()
			end
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
				local mx, my = self:getRelativePosition(x, y)
				if widShared.pointInViewport(self, 1, mx, my) then
					local att = self.att_ref
					if att and not att._dead then
						self.pressed = true
						self.att_ax, self.att_ay = x, y
						if self.att_side == "right" or self.att_side == "left" then
							self.att_len = att.w
						else -- "top", "bottom"
							self.att_len = att.h
						end
						local skin = self.skin
						self:setCursorHigh(self.vertical and skin.cursor_v or skin.cursor_h)
					end
				end
			end
		end
	end
end


function def:uiCall_pointerDrag(inst, x, y, dx, dy)
	if self == inst then
		if self.enabled then
			if self.pressed then
				if self.context.mouse_pressed_button == 1 then
					local att = self.att_ref
					if att and not att._dead then
						if self.att_side == "right" then
							att.w = self.att_len + (x - self.att_ax)

						elseif self.att_side == "left" then
							att.w = self.att_len - (x - self.att_ax)

						elseif self.att_side == "top" then
							att.h = self.att_len + (y - self.att_ay)

						elseif self.att_side == "bottom" then
							att.h = self.att_len - (y - self.att_ay)

						else
							error("invalid attachment side")
						end

						-- XXX WIP. The container might need to mediate the resizing behavior.
						att.w = math.max(0, math.min(att.w, att.parent.vp_w))
						att.h = math.max(0, math.min(att.h, att.parent.vp_h))

						-- Reshape the parent container and all descendants.
						att.parent:reshape(true)
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
					self.pressed = false
					self:setCursorHigh()
				end
			end
		end
	end
end


def.default_skinner = {
	schema = {
		breadth = "scaled-int",
		sensor_margin = "scaled-int"
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
		local tq_px = skin.tq_px
		local side = self.att_side
		local slc = (side == "left" or side == "right") and skin.slc_lr or skin.slc_tb

		love.graphics.setColor(skin.color)
		uiGraphics.drawSlice(slc, 0, 0, self.w, self.h)
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
