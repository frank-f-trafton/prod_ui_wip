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


local lgcScroll = context:getLua("shared/lgc_scroll")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcContainer = context:getLua("shared/wc/wc_container")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "container1",
	trickle = {}
}


def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


widLayout.setupContainerDef(def)
widShared.scrollSetMethods(def)
wcContainer.setupMethods(def)


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true

	self.scroll_range_mode = "zero"

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)
	wcContainer.setupSashState(self)
	widLayout.setupLayoutList(self)

	self:layoutSetBase("viewport")

	self.press_busy = false

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	--print("container: uiCall_reshapePre")

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	lgcScroll.arrangeScrollBars(self)

	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	widShared.setClipScissorToViewport(self, vp2)
	widShared.setClipHoverToViewport(self, vp2)

	widLayout.resetLayoutSpace(self)
end


function def:uiCall_reshapePost()
	--print("container: uiCall_reshapePost")

	widShared.updateDoc(self)

	self:scrollClampViewport()
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)
end


function def.trickle:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	return wcContainer.sashHoverLogic(self, mouse_x, mouse_y)
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		lgcScroll.widgetProcessHover(self, mx, my)
	end
end


function def.trickle:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	wcContainer.sashHoverOffLogic(self)
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		lgcScroll.widgetClearHover(self)
	end
end


function def.trickle:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if wcContainer.sashPressLogic(self, x, y, button) then
		return true
	end
end


function def.trickle:uiCall_pointerDrag(inst, x, y, dx, dy)
	if wcContainer.sashDragLogic(self, x, y) then
		return true
	end
end


function def.trickle:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if wcContainer.sashUnpressLogic(self) then
		return true
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		local handled = false

		-- Check for pressing on scroll bar components.
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config
			handled = lgcScroll.widgetScrollPress(self, x, y, fixed_step)
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

			lgcScroll.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 then
			lgcScroll.widgetClearPress(self)

			self.press_busy = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	-- Catch wheel events from descendants that did not block it.
	local caught = widShared.checkScrollWheelScroll(self, x, y)
	lgcScroll.updateScrollBarShapes(self)

	-- Stop bubbling if the view scrolled.
	return caught
end


-- Catch focus step actions so that we can ensure the hosted widget is in view.
-- @param keep_in_view When true, viewport scrolls to ensure the widget is visible within the viewport.
function def:uiCall_thimble1Take(inst, keep_in_view)
	if inst ~= self then -- don't try to center the container itself
		if keep_in_view == "widget_in_view" then
			local skin = self.skin
			wcContainer.keepWidgetInView(self, inst, skin.in_view_pad_x, skin.in_view_pad_y)
			lgcScroll.updateScrollBarShapes(self)
		end
	end
end


function def:uiCall_update(dt)
	dt = math.min(dt, 1.0)
	if lgcScroll.press_busy_codes[self.press_busy] then
		local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
		local button_step = 350 -- [XXX 6] style/config
		lgcScroll.widgetDragLogic(self, mx, my, button_step*dt)
	end

	self:scrollUpdate(dt)
	lgcScroll.updateScrollState(self)
	lgcScroll.updateScrollBarShapes(self)
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		data_scroll = themeAssert.scrollBarData,
		scr_style = themeAssert.scrollBarStyle,

		color_body = uiAssert.loveColorTuple,
		slc_body = themeAssert.slice,

		-- Padding when scrolling to put a widget into view.
		in_view_pad_x = {uiAssert.type, "number"},
		in_view_pad_y = {uiAssert.type, "number"}
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "in_view_pad_x")
		uiScale.fieldInteger(scale, skin, "in_view_pad_y")

		-- TODO
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
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
		love.graphics.push("all")
		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		wcContainer.renderSashes(self)

		lgcScroll.drawScrollBarsHV(self, self.skin.data_scroll)

		love.graphics.pop()

		-- XXX Debug...
		--[=[
		local vp, vp2 = self.vp, self.vp2

		love.graphics.push("all")

		love.graphics.setLineStyle("smooth")
		love.graphics.setLineWidth(2)
		love.graphics.setLineJoin("miter")

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("line", vp.x, vp.y, vp.w, vp.h)

		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.rectangle("line", vp2.x, vp2.y, vp2.w, vp2.h)

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

