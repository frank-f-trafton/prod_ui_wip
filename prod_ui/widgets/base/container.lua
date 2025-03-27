--[[
	A generic container that holds other widgets, with built-in support for scroll bars,
	viewport clipping, layouts and draggable dividers (window sashes).

	For a basic container, see: 'base/container_simple.lua'

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

	A container should not use both sashes and scrolling at the same time.
--]]


local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local lgcContainer = context:getLua("shared/lgc_container")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "container1",
	trickle = {}
}


def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


widShared.scrollSetMethods(def)
lgcContainer.setupMethods(def)


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true

	self.scroll_range_mode = "zero"

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)
	lgcContainer.sashStateSetup(self)
	widLayout.initializeLayoutTree(self)

	self.layout_base = "viewport"

	self.press_busy = false

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	print("container: uiCall_reshapePre")

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	commonScroll.arrangeScrollBars(self)

	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, skin.box.margin)

	widShared.setClipScissorToViewport(self, 2)
	widShared.setClipHoverToViewport(self, 2)

	widLayout.resetLayout(self, self.layout_base)
end


function def:uiCall_reshapePost()
	print("container: uiCall_reshapePost")

	widShared.updateDoc(self)

	self:scrollClampViewport()
	commonScroll.updateScrollBarShapes(self)
	commonScroll.updateScrollState(self)
end


function def.trickle:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	return lgcContainer.sashPointerHoverLogic(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
end


def.uiCall_pointerHover = lgcContainer.wid_uiCall_pointerHover
def.trickle.uiCall_pointerHoverOff = lgcContainer.wid_trickle_uiCall_pointerHoverOff
def.uiCall_pointerHoverOff = lgcContainer.wid_uiCall_pointerHoverOff


function def.trickle:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if lgcContainer.sash_tricklePointerPress(self, inst, x, y, button, istouch, presses) then
		return true
	end
end


function def.trickle:uiCall_pointerDrag(inst, x, y, dx, dy)
	if lgcContainer.sash_tricklePointerDrag(self, inst, x, y, dx, dy) then
		return true
	end
end


function def.trickle:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if lgcContainer.sash_pointerUnpress(self, inst, x, y, button, istouch, presses) then
		return true
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

		-- Scroll bars were not activated: try directing thimble1 to the
		-- container's UI Frame ancestor.
		if button <= 3 and not handled then
			local wid = self
			while wid do
				if wid.frame_type then
					break
				end
				wid = wid.parent
			end
			if wid then
				wid:tryTakeThimble1()
			end
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
			local skin = self.skin
			lgcContainer.keepWidgetInView(self, inst, skin.in_view_pad_x, skin.in_view_pad_y)
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


def.default_skinner = {
	schema = {
		in_view_pad_x = "scaled-int",
		in_view_pad_y = "scaled-int"
	},


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
		if skin.slc_body then
			love.graphics.setColor(skin.color_body)
			uiGraphics.drawSlice(skin.slc_body, 0, 0, self.w, self.h)
		end
	end,


	renderLast = function(self, ox, oy)
		if self.sash_hover then
			lgcContainer.renderSash(self.sash_hover, self, ox, oy)
		end

		commonScroll.drawScrollBarsHV(self, self.skin.data_scroll)

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
}


return def

