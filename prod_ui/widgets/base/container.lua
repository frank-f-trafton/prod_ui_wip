--[[
	A generic container that holds other widgets, with built-in support for scroll bars,
	viewport clipping and layouts.

	For a pared-down container, see: 'base/container_simple.lua'

	┌┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┬┈┐
	│`````````````````````│^│    [`] == Viewport 2
	│`:::::::::::::::::::`├┈┤    [:] == Viewport 1
	│`:                 :`│ │
	│`:                 :`│ │
	│`:                 :`│ │
	│`:::::::::::::::::::`├┈┤
	│`````````````````````│v│
	├┈┬┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┬┈┼┈┤
	│<│                 │>│ │    <- Optional scroll bars
	└┈┴┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┴┈┴┈┘
--]]


local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "container1",
	click_repeat_oob = true, -- Helps with integrated scroll bar buttons
}


widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


--- Override to make something happen when the user clicks on blank space (no widgets, no embedded controls) in the container.
function def:wid_pressed(x, y, button, istouch, presses)

end


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = false
		self.allow_focus_capture = false

		-- When true, doc_w and doc_h are set to the combined dimensions of the container's direct descendants.
		self.auto_doc_update = true

		widShared.setupDoc(self)
		widShared.setupScroll(self)
		widShared.setupViewports(self, 2)
		widShared.setupMinMaxDimensions(self)

		-- Layout sequence
		uiLayout.initLayoutSequence(self)

		-- Layout mode for containers.
		-- false: no effect
		-- "auto": re-apply layout whenever uiCall_reshape() is fired.
		-- "resize": re-apply layout whenever uiCall_reshape() is fired, but only if the container dimensions have changed.
		self.layout_mode = false

		-- Used with "resize" layout_mode.
		self.lc_w_old = self.w
		self.lc_h_old = self.h

		-- false: pointer-drag not active
		-- "h": dragging horizontal thumb
		-- "v": dragging vertical thumb
		-- "h1", "h2", "v1", "v2": pressing on a less/more button
		self.press_busy = false

		self:updateContentClipScissor()

		self:scrollClampViewport()

		self:skinSetRefs()
		self:skinInstall()
	end
end


-- Needs to be reachable from WIMP window-frames.
function def:updateContentClipScissor()
	widShared.setClipScissorToViewport(self, 2)
	widShared.setClipHoverToViewport(self, 2)
end


function def:keepWidgetInView(wid)
	-- [XXX 1] There should be an optional rectangle within the widget that gets priority for being in view.
	-- Examples include the caret in a text box, the selection in a menu, and the thumb in a slider bar.

	-- Get widget position relative to this container.
	local x, y = wid:getPositionInAncestor(self)
	local w, h = wid.w, wid.h

	if wid.focal_x then -- [XXX 1] Untested
		x = x + wid.focal_x
		y = y + wid.focal_y
		w = wid.focal_w
		h = wid.focal_h
	end

	local skin = self.skin

	self:scrollRectInBounds(
		x - skin.in_view_pad_x,
		y - skin.in_view_pad_y,
		x + w + skin.in_view_pad_x,
		y + h + skin.in_view_pad_y,
		false
	)
end


function def:uiCall_reshape()
	local skin = self.skin

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	for k, v in pairs(skin) do
		print("", k, v)
	end
	widShared.carveViewport(self, 1, skin.box.border)
	commonScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, skin.box.margin)

	self:updateContentClipScissor()

	-- Layout handling.
	local layout_mode = self.layout_mode
	if layout_mode == "auto"
	or layout_mode == "resize" and self.lc_w_old ~= self.w or self.lc_h_old ~= self.h
	then
		uiLayout.resetLayoutPort(self, 1)
		uiLayout.applyLayout(self)
	end

	self.lc_w_old = self.w
	self.lc_h_old = self.h

	-- Optional: auto-update document dimensions.
	if self.auto_doc_update then
		self.doc_w, self.doc_h = widShared.getCombinedChildrenDimensions(self)
	end

	-- Update scroll bar state.
	self:scrollClampViewport()
	commonScroll.updateScrollBarShapes(self)
	commonScroll.updateScrollState(self)
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		mouse_x, mouse_y = self:getRelativePosition(mouse_x, mouse_y)
		commonScroll.widgetProcessHover(self, mouse_x, mouse_y)
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		commonScroll.widgetClearHover(self)
	end
end



function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		local handled = false

		-- Check for pressing on scroll bar components.
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config
			handled = commonScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Scroll bars were not activated: take thimble1
		if (button == 1 or button == 2) and not handled then
			if self.can_have_thimble then
				self:takeThimble1()
			end
			self:wid_pressed(x, y, button, istouch, presses)
		end
	end
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config

			commonScroll.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 then
			commonScroll.widgetClearPress(self)

			self.press_busy = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	-- Catch wheel events from descendants that did not block it.
	local caught = widShared.checkScrollWheelScroll(self, x, y)
	commonScroll.updateScrollBarShapes(self)

	-- Stop bubbling if the view scrolled.
	return caught
end


-- Catch focus step actions so that we can ensure the hosted widget is in view.
-- @param keep_in_view When true, viewport scrolls to ensure the widget is visible within the viewport.
function def:uiCall_thimble1Take(inst, keep_in_view)
	if inst ~= self then -- don't try to center the container itself
		if keep_in_view == "widget_in_view" then
			self:keepWidgetInView(inst)
			commonScroll.updateScrollBarShapes(self)
		end
	end
end


function def:uiCall_update(dt)
	dt = math.min(dt, 1.0)
	if commonScroll.press_busy_codes[self.press_busy] then
		local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
		local button_step = 350 -- [XXX 6] style/config
		commonScroll.widgetDragLogic(self, mx, my, button_step*dt)
	end

	self:scrollUpdate(dt)
	commonScroll.updateScrollState(self)
	commonScroll.updateScrollBarShapes(self)
end

-- Debug
--local OOPS = 0


-- Debug renderer.
--[=[
function def:render()

	-- [XXX 7] Debug: test cascading graphics state.
	--[[
	OOPS = OOPS + math.pi/512
	local hx, hy = math.floor(self.w/2), math.floor(self.h/2)
	love.graphics.translate(hx, hy)
	love.graphics.scale(1, math.sin(OOPS / 32))
	love.graphics.translate(-hx, -hy)
	--]]

end
--]=]


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
		--render = function(self, ox, oy)


		renderLast = function(self, ox, oy)
			local skin = self.skin

			-- Draw the embedded scroll bars, if present and active.
			local data_scroll = skin.data_scroll

			local scr_h = self.scr_h
			local scr_v = self.scr_v

			if scr_h and scr_h.active then
				self.impl_scroll_bar.draw(data_scroll, self.scr_h, 0, 0)
			end
			if scr_v and scr_v.active then
				self.impl_scroll_bar.draw(data_scroll, self.scr_v, 0, 0)
			end

			-- XXX Debug...
			--[=[
			love.graphics.push("all")

			love.graphics.setLineStyle("smooth")
			love.graphics.setLineWidth(2)
			love.graphics.setLineJoin("miter")

			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("line", self.vp_x, self.vp_y, self.vp_w, self.vp_h)

			love.graphics.setColor(0, 1, 0, 1)
			love.graphics.rectangle("line", self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)

			love.graphics.setColor(0, 0, 1, 1)
			love.graphics.rectangle("line", -self.scr_x, -self.scr_y, self.doc_w, self.doc_h)

			if self.DEBUG == "dimensions" then -- XXX debug cleanup
				love.graphics.setColor(0,0,0,0.6)
				love.graphics.rectangle("fill", 0, 0, 160, 256)
				love.graphics.setColor(1,1,1,1)
				love.graphics.print(
					"scr_x: " .. self.scr_x .. "\nscr_y: " .. self.scr_y
					.. "\nscr_fx: " .. self.scr_fx .. "\nscr_fy: " .. self.scr_fy
					.. "\nscr_tx: " .. self.scr_tx .. "\nscr_ty: " .. self.scr_ty
					.. "\ndoc_w: " .. self.doc_w .. "\ndoc_h: " .. self.doc_h
					.. "\nw: " .. self.w .. "\nh: " .. self.h
					--.. "\nscr_v.pos: " .. self.scr_v.pos .. "\n^len: " .. self.scr_v.len .. "\n^max: " .. self.scr_v.max
				)
			end

			love.graphics.pop("all")
			--]=]
		end,

		-- Don't highlight when holding the UI thimble.
		renderThimble = widShared.dummy,
	},
}


return def

