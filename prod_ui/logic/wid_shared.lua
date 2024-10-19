-- ProdUI: Shared widget logic.


local widShared = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local eventHandlers = require(REQ_PATH .. "event_handlers")
local intersect = require(REQ_PATH .. "intersect")


-- A common dummy function for widgets.
function widShared.dummy()
	-- n/a
end


-- Viewport key lookup.
local vp_keys = {
	--[[1]] {x = "vp_x", y = "vp_y", w = "vp_w", h = "vp_h"},
	--[[2]] {x = "vp2_x", y = "vp2_y", w = "vp2_w", h = "vp2_h"},
	--[[3]] {x = "vp3_x", y = "vp3_y", w = "vp3_w", h = "vp3_h"},
	--[[4]] {x = "vp4_x", y = "vp4_y", w = "vp4_w", h = "vp4_h"},
	--[[5]] {x = "vp5_x", y = "vp5_y", w = "vp5_w", h = "vp5_h"},
	--[[6]] {x = "vp6_x", y = "vp6_y", w = "vp6_w", h = "vp6_h"},
	--[[7]] {x = "vp7_x", y = "vp7_y", w = "vp7_w", h = "vp7_h"},
	--[[8]] {x = "vp8_x", y = "vp8_y", w = "vp8_w", h = "vp8_h"},
}
widShared.vp_keys = vp_keys


local edge_keys = {
	border = {x1 = "border_x1", x2 = "border_x2", y1 = "border_y1", y2 = "border_y2"},
	margin = {x1 = "margin_x1", x2 = "margin_x2", y1 = "margin_y1", y2 = "margin_y2"},
}
widShared.edge_keys = edge_keys


local function getWidgetBox(self, v)
	if v then
		v = vp_keys[v]
		return self[v.x], self[v.y], self[v.w], self[v.h]
	else
		return 0, 0, self.w, self.h
	end
end


-- Widget must have 'min_w', 'min_h', 'max_w' and 'max_h' fields for these functions to work.
-- Both need to be greater than 0 to prevent issues (divide by zero, etc.)


function widShared.enforceLimitedDimensions(self)
	self.w = math.max(self.min_w, math.min(self.w, self.max_w))
	self.h = math.max(self.min_h, math.min(self.h, self.max_h))
end


--[[
function widShared.keepInBounds(self)
	local parent = self.parent
	if not parent then
		return
	end

	self.x = math.max(-self.w - self.p_bounds_x1, math.min(self.x, parent.w + self.p_bounds_x2))
	self.y = math.max(-self.h - self.p_bounds_y1, math.min(self.y, parent.h + self.p_bounds_y2))
end
--]]


--[[
function widShared.keepInBoundsPort2(self)
	local parent = self.parent
	if not parent then
		return
	end

	self.x = math.max(-self.w - self.p_bounds_x1 + parent.vp2_x, math.min(self.x, parent.vp2_w + self.p_bounds_x2))
	self.y = math.max(-self.h - self.p_bounds_y1 + parent.vp2_y, math.min(self.y, parent.vp2_h + self.p_bounds_y2))
end
--]]


-- Use to keep a widget within the bounds of its parent.
-- TODO: document spill-out behavior.
-- @param self The widget.
-- @param v The viewport box to use. Leave `nil` to use the parent's width and height.
function widShared.keepInBoundsOfParent(self, v)
	local parent = self.parent
	if not parent then
		return
	end

	local px, py, pw, ph = getWidgetBox(parent, v)

	self.x = math.max(px, math.min(self.x, pw - self.w))
	self.y = math.max(py, math.min(self.y, ph - self.h))
end


-- Use to keep a widget partially within the bounds of a parent (ie window frames).
-- TODO: document spill-out behavior.
-- @param self The widget.
-- @param v The viewport box to use. Leave `nil` to use the parent's width and height.
-- @param x1, x2, y1, y2 How much of the widget must remain within the parent's boundaries on each side.
function widShared.keepInBoundsExtended(self, v, x1, x2, y1, y2)
	local parent = self.parent
	if not parent then
		return
	end

	local px, py, pw, ph = getWidgetBox(parent, v)

	self.x = math.max(-self.w - x1 + px, math.min(self.x, pw + x2))
	self.y = math.max(-self.h - y1 + py, math.min(self.y, ph + y2))
end


-- @param self The widget to resize.
-- @param mx Mouse position within the parent widget space.
local function resizeLeft(self, mx)
	mx = math.floor(0.5 + mx)

	local old_x = self.x

	self.x = math.min(mx, self.x + self.w - self.min_w)
	self.w = self.w + (old_x - self.x)
end


local function resizeRight(self, mx)
	mx = math.floor(0.5 + mx)

	self.w = math.max(self.min_w, mx - self.x)
end


local function resizeTop(self, my)
	my = math.floor(0.5 + my)

	local old_y = self.y

	self.y = math.min(my, self.y + self.h - self.min_h)
	self.h = self.h + (old_y - self.y)
end


local function resizeBottom(self, my)
	my = math.floor(0.5 + my)
	self.h = math.max(self.min_h, my - self.y)
end


function widShared.uiCapEvent_resize_mouseMoved(self, axis_x, axis_y, x, y, dx, dy, istouch)
	-- Update mouse position
	self.context.mouse_x = x
	self.context.mouse_y = y

	local old_w, old_h = self.w, self.h

	-- Get mouse position in parent's space
	local ax, ay = self.parent:getAbsolutePosition()
	local mx, my = x - ax, y - ay

	-- Crop mouse position to a range slightly bigger than the parent rectangle.
	-- This prevents stretching frames far beyond the LÖVE window (though if you want that behavior,
	-- you can comment out or delete the block below). -- XXX Yeah, this probably should be configurable.
	-- [[
	mx = math.max(-32, math.min(mx, self.parent.w + 32))
	my = math.max(-32, math.min(my, self.parent.h + 32))
	--]]

	--[[
	print(
		"x", x, "y", y,
		"ax", ax, "ay", ay,
		"mx", mx, "my", my,
		"self.cap_ox", self.cap_ox, "self.cap_oy", self.cap_oy
	)
	--]]

	-- Resize the container.
	if axis_x > 0 then
		resizeRight(self, mx + self.cap_ox)

	elseif axis_x < 0 then
		resizeLeft(self, mx + self.cap_ox)
	end

	if axis_y > 0 then
		resizeBottom(self, my + self.cap_oy)

	elseif axis_y < 0 then
		resizeTop(self, my + self.cap_oy)
	end

	-- Resize self, contents, sensors
	if old_w ~= self.w or old_h ~= self.h then
		self:reshape(true)
	end

	return false
end


function widShared.uiCapEvent_resize_mouseReleased(self, x, y, button, istouch, presses)
	if button == 1 and self.context.mouse_pressed_button == button then
		self.cap_mode = "idle"
		self:uncaptureFocus()

		local context = self.context
		eventHandlers.mousemoved(context, context.mouse_x, context.mouse_y, 0, 0, false)

		-- Hack: clamp frame to parent. This isn't handled while resizing because the
		-- width and height can go haywire when resizing against the bounds of the
		-- screen (see the 'p_bounds_*' fields).
		--widShared.keepInBoundsPort2(self)
		widShared.keepInBoundsExtended(self, 2, self.p_bounds_x1, self.p_bounds_x2, self.p_bounds_y1, self.p_bounds_y2)

		-- mousereleased cleanup
		return false
	end

	return true
end


function widShared.uiCapEvent_drag_mouseMoved(self, x, y, dx, dy, istouch)
	--[[
	Relies on the following fields:
	self.drag_ox
	self.drag_oy
	--]]

	local old_x, old_y = self.context.mouse_x, self.context.mouse_y

	-- Update mouse position
	self.context.mouse_x = x
	self.context.mouse_y = y

	if self.maximized then
		-- Unmaximize only if the mouse has wandered a bit from its original click-point.
		if self.context.mouse_x < self.cap_mouse_orig_a_x - 32
		or self.context.mouse_x >= self.cap_mouse_orig_a_x + 32
		or self.context.mouse_y < self.cap_mouse_orig_a_y - 32
		or self.context.mouse_y >= self.cap_mouse_orig_a_y + 32
		then
			-- If unmaximizing as a result of the pointer dragging the top bar, tweak the
			-- container's XY position so that it looks like the mouse pointer has gripped
			-- the window.

			local a_x, a_y = self:getAbsolutePosition()
			local mouse_rel_x = self.context.mouse_x - a_x
			local mouse_rel_y = self.context.mouse_y - a_y

			-- 0.0 == left or top, 1.0 == bottom or right
			local lerp_x = intersect.lerp(0, self.w, mouse_rel_x / self.w) / self.w
			local lerp_y = intersect.lerp(0, self.h, mouse_rel_y / self.h) / self.h

			self:wid_unmaximize()
			self:reshape(true)

			-- Would need adjustments if dragging elsewhere (not along the top bar)
			-- unmaximizes the window.
			self.drag_ox = math.floor(0.5 - lerp_x * self.w)
			self.drag_oy = -self.cap_mouse_orig_a_y
		end
	end

	if not self.maximized then
		-- Update self's position
		-- We could use dx and dy here, but if the mouse leaves the window and
		-- enters from another location, the window will not teleport with the pointer.
		-- Whether you want this behavior or not is a matter of personal preference.
		--[[
		self.x = self.x + dx
		self.y = self.y + dy
		--]]

		local parent = self.parent
		if parent then
			local pa_x, pa_y = parent:getAbsolutePosition()

			--[[
			self.drag_ox = a_x - x
			self.drag_oy = a_y - y
			--]]

			self.x = self.context.mouse_x - pa_x + self.drag_ox
			self.y = self.context.mouse_y - pa_y + self.drag_oy
		end

		--widShared.keepInBoundsPort2(self)
		widShared.keepInBoundsExtended(self, 2, self.p_bounds_x1, self.p_bounds_x2, self.p_bounds_y1, self.p_bounds_y2)
	end

	-- Tweak to fix accidental maximizes from double-clicks.
	if self.drag_dc_fix_x then
		local fix_pad = self.context.cseq_range
		if x < self.drag_dc_fix_x - fix_pad or x > self.drag_dc_fix_x + fix_pad
		or y < self.drag_dc_fix_y - fix_pad or y > self.drag_dc_fix_y + fix_pad
		then
			self.context:forceClickSequence(false, 1, 1)
		end
	end
end


function widShared.uiCapEvent_drag_mouseReleased(self, x, y, button, istouch, presses)
	if button == 1 and self.context.mouse_pressed_button == button then
		self.cap_mode = "idle"
		self:uncaptureFocus()

		local context = self.context
		eventHandlers.mousemoved(context, context.mouse_x, context.mouse_y, 0, 0, false)

		-- Allow event through so that the context can clean up its mouse-released state.
		return false
	end

	return true
end


function widShared.addResizeSensor(self, pad, axis_x, axis_y)
	local sens = self:addChild("sensor_resize")

	sens.axis_x = axis_x
	sens.axis_y = axis_y
	sens.sensor_pad = pad

	sens:reshape()

	return sens
end


function widShared.centerInParent(self, hori, vert)
	local parent = self.parent
	if not parent then
		return
	end

	if hori then
		self.x = math.floor(parent.w/2 - self.w/2)
	end
	if vert then
		self.y = math.floor(parent.h/2 - self.h/2)
	end
end


function widShared.wid_maximize(self)
	-- Widget must have a parent.

	self.maxim_x = self.x
	self.maxim_y = self.y
	self.maxim_w = self.w
	self.maxim_h = self.h

	local parent = self.parent

	self.x = parent.vp2_x
	self.y = parent.vp2_y
	self.w = parent.vp2_w
	self.h = parent.vp2_h

	self.maximized = true

	-- Turn off resize sensors.
	for _, child in ipairs(self.children) do
		if child.id == "sensor_resize" then
			child.allow_hover = false
		end
	end

	-- Need to reshape after calling.
end


function widShared.wid_unmaximize(self)
	-- Widget is required to have a parent.
	local parent = self.parent

	self.x = self.maxim_x or 64
	self.y = self.maxim_y or 64
	self.w = self.maxim_w or parent.vp2_w - 64
	self.h = self.maxim_h or parent.vp2_h - 64

	-- Clamp unmaximized position + dimensions to parent contact box.
	--[[
	-- This prevents the following situation, where the user:
	* Maximizes the LÖVE window
	* Makes the prodUI container very large
	* Maximizes the prodUI container
	* Unmaximizes the LÖVE window
	* Unmaximizes the prodUI container -- which would be larger than the LÖVE window without this adjustment.
	--]]
	-- [[
	if self.x < parent.vp2_x then
		self.x = parent.vp2_x
	end
	if self.y < parent.vp2_y then
		self.y = parent.vp2_y
	end
	if self.x + self.w > parent.vp2_x + parent.vp2_w then
		self.x = parent.vp2_x + parent.vp2_w - self.w
	end
	if self.y + self.h > parent.vp2_y + parent.vp2_h then
		self.y = parent.vp2_y + parent.vp2_h - self.h
	end
	if self.w > parent.vp2_w then
		self.w = parent.vp2_w
	end
	if self.h > parent.vp2_h then
		self.h = parent.vp2_h
	end
	--]]

	self.maximized = false

	-- Turn on resize sensors.
	for _, child in ipairs(self.children) do
		if child.id == "sensor_resize" then
			child.allow_hover = true
		end
	end

	-- Need to reshape after calling.
end


function widShared.getChildrenPerimeter(self)
	local w, h = 0, 0

	for _, child in ipairs(self.children) do
		w = math.max(w, child.x + child.w)
		h = math.max(h, child.y + child.h)
	end

	return w, h
end


--[[
Scroll registers:

scr_x: Public X Scroll value. Rounded to integer.
scr_y: Public Y Scroll value. Rounded to integer.

scr_fx: Private scroll X value. Double.
scr_fy: Private scroll Y value. Double.

scr_tx: Target X scroll value. Double.
scr_ty: Target Y scroll value. Double.

The public values are provided just so that other code doesn't have to constantly round the values
when drawing or performing intersection tests.

In widgets that use the viewport system, The scroll values are offset by Viewport #1's position. The plug-in scroll
methods take this into account, but if you read the registers directly, you may find that the scroll values for
the top-left position go into the negative. To get the expected value, add viewport 1's position.
--]]


--- Calculate a scroll-to-target step for a client.
-- @param scr_p The current scroll position.
-- @param scr_t The target scroll position.
-- @param snap When scr_p is within (scr_t - snap) and (scr_t + snap), just return the target value.
-- @param spd_min The minimum scroll speed (pixels per second).
-- @param spd_mul Speed to add on top of the minimum, multiplied by distance in pixels from the target.
-- @param dt The client's delta time.
-- @return A new scroll position.
function widShared.scrollTargetUpdate(scr_p, scr_t, snap, spd_min, spd_mul, dt)
	-- If close enough to the scroll target, lock position.
	if scr_p > scr_t - snap and scr_p < scr_t + snap then
		return scr_t
	end

	local sign = (scr_p <= scr_t) and 1 or -1
	local spd = (spd_min + math.abs(scr_p - scr_t)*spd_mul) * sign

	if spd > 0 then
		return math.min(scr_p + spd*dt, scr_t)

	else
		return math.max(scr_p + spd*dt, scr_t)
	end
end


--- Viewport scroll clamping for containers and other widgets which have embedded scroll bars.
function widShared.scrollClampViewport(self)
	self.scr_fx = math.max(-self.vp_x, math.min(self.scr_fx, -self.vp_x + self.doc_w - self.vp_w))
	self.scr_fy = math.max(-self.vp_y, math.min(self.scr_fy, -self.vp_y + self.doc_h - self.vp_h))

	self.scr_x = math.floor(0.5 + self.scr_fx)
	self.scr_y = math.floor(0.5 + self.scr_fy)

	self.scr_tx = math.max(-self.vp_x, math.min(self.scr_tx, -self.vp_x + self.doc_w - self.vp_w))
	self.scr_ty = math.max(-self.vp_y, math.min(self.scr_ty, -self.vp_y + self.doc_h - self.vp_h))
end


function widShared.scrollUpdate(self, dt)
	self.scr_fx = widShared.scrollTargetUpdate(self.scr_fx, self.scr_tx, 1, 800, 8.0, dt) -- XXX config
	self.scr_fy = widShared.scrollTargetUpdate(self.scr_fy, self.scr_ty, 1, 800, 8.0, dt) -- XXX config

	self.scr_x = math.floor(0.5 + self.scr_fx)
	self.scr_y = math.floor(0.5 + self.scr_fy)
end


function widShared.scrollXInBounds(self, x1, x2, immediate)
	-- Clamp the scroll target.
	self.scr_tx = math.max(x2 - self.vp_x - self.vp_w, math.min(self.scr_tx, x1 - self.vp_x))

	if immediate then
		self.scr_fx = self.scr_tx
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollYInBounds(self, y1, y2, immediate)
	-- Clamp the scroll target.
	self.scr_ty = math.max(y2 - self.vp_y - self.vp_h, math.min(self.scr_ty, y1 - self.vp_y))

	if immediate then
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollRectInBounds(self, x1, y1, x2, y2, immediate)
	-- Clamp the scroll target.
	self.scr_tx = math.max(x2 - self.vp_x - self.vp_w, math.min(self.scr_tx, x1 - self.vp_x))
	self.scr_ty = math.max(y2 - self.vp_y - self.vp_h, math.min(self.scr_ty, y1 - self.vp_y))

	if immediate then
		self.scr_fx = self.scr_tx
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollH(self, x, immediate)
	self.scr_tx = -self.vp_x + x
	if immediate then
		self.scr_fx = self.scr_tx
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollDeltaH(self, dx, immediate)
	self.scr_tx = self.scr_tx + dx
	if immediate then
		self.scr_fx = self.scr_tx
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollV(self, y, immediate)
	self.scr_ty = -self.vp_y + y
	if immediate then
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollDeltaV(self, dy, immediate)
	self.scr_ty = self.scr_ty + dy
	if immediate then
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollHV(self, x, y, immediate)
	self.scr_tx = -self.vp_x + x
	self.scr_ty = -self.vp_y + y
	if immediate then
		self.scr_fx = self.scr_tx
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollDeltaHV(self, dx, dy, immediate)
	self.scr_tx = self.scr_tx + dx
	self.scr_ty = self.scr_ty + dy
	if immediate then
		self.scr_fx = self.scr_tx
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollSetMethods(self)
	self.scrollClampViewport = widShared.scrollClampViewport
	self.scrollUpdate = widShared.scrollUpdate

	self.scrollXInBounds = widShared.scrollXInBounds
	self.scrollYInBounds = widShared.scrollYInBounds
	self.scrollRectInBounds = widShared.scrollRectInBounds

	self.scrollH = widShared.scrollH
	self.scrollDeltaH = widShared.scrollDeltaH

	self.scrollV = widShared.scrollV
	self.scrollDeltaV = widShared.scrollDeltaV

	self.scrollHV = widShared.scrollHV
	self.scrollDeltaHV = widShared.scrollDeltaHV
end


-- * Widget chaining *


--[[
	Functions to set up and traverse widgets as doubly-linked lists, independent of the tree hierarchy.
--]]


function widShared.chainLink(from, to)
	from.chain_next = to
	to.chain_prev = from
end


function widShared.chainUnlink(self)
	local temp_next = self.chain_next or false
	local temp_prev = self.chain_prev or false

	if temp_prev then
		temp_prev.chain_next = temp_next
	end
	if temp_next then
		temp_next.chain_prev = temp_prev
	end

	self.chain_next = false
	self.chain_prev = false
end


--- Given a widget chain and mouse coordinates, find the first intersection with a widget capable of
--  being assigned the context hover and press state.
-- @param self A widget that is part of a chain.
-- @param mouse_x Mouse X position in UI space.
-- @param mouse_y Mouse Y position in UI space.
-- @return The first widget that intersects with the position, or nil if no intersection was detected.
function widShared.checkChainPointerOverlap(self, mouse_x, mouse_y)
	-- NOTE: The chain order should roughly match the order of widgets in the tree, or else you'll end
	-- up grabbing widgets that are behind other widgets.

	-- NOTE: Deeply-nested widgets will be trouble because each call to getAbsolutePosition() has to travel
	-- all the way up to the widget root.

	-- Start at the end of the chain.
	local wid = self
	while wid.chain_next do
		wid = wid.chain_next
	end
	while wid do
		if wid.allow_hover then
			local ax, ay = wid:getAbsolutePosition()
			local mx = mouse_x - ax
			local my = mouse_y - ay

			if mouse_x >= ax and mouse_x < ax + wid.w and mouse_y >= ay and mouse_y < ay + wid.h then
				return wid
			end
		end

		wid = wid.chain_prev
	end

	return nil
end


--- Given a widget in a chain, remove all widgets after this one.
function widShared.chainRemovePost(self)
	local wid = self

	while wid.chain_next do
		wid = wid.chain_next
	end

	while wid ~= self do
		local wid_prev = wid.chain_prev
		wid:remove()
		wid = wid_prev
	end

	self.chain_next = false
end


function widShared.chainHasThisWidgetRight(wid_in, wid_check)
	local wid = wid_in.chain_next
	while wid do
		if wid == wid_check then
			return true
		end
		wid = wid.chain_next
	end

	return wid_in == wid_check
end


function widShared.chainHasThisWidget(wid_in, wid_check)
	local wid = wid_in.chain_next
	while wid do
		if wid == wid_check then
			return true
		end
		wid = wid.chain_next
	end

	wid = wid_in.chain_prev
	while wid do
		if wid == wid_check then
			return true
		end
		wid = wid.chain_prev
	end

	return wid_in == wid_check
end


-- * Thimble banking *


function widShared.initThimbleBank(self, enabled)
	self.do_thimble_bank = not not enabled
	self.banked_thimble = "empty"
end


function widShared.clearThimbleBank(self)
	self.banked_thimble = "empty"
end


--- Try and set a banked thimble reference within this widget, to potentially be restored at a later time. The banked widget is pulled from 'current_thimble' in the context.
-- @param self The widget with the reference bank.
-- @param force When true, the bank is always set. When false, it is set only if it is currently empty.
-- @return Nothing.
function widShared.setThimbleBank(self) -- tryAssignBankedThimble(self)
	--[[
	Things you may want to check before calling, depending on the desired behavior:
	* self.context.current_thimble ~= self
	* self.context.current_thimble ~= false
	* self.banked_thimble ~= "empty"
	--]]

	--print("setThimbleBank", "do_thimble_bank", self.do_thimble_bank, "banked_thimble", self.banked_thimble)

	if not self.do_thimble_bank then
		error("thimble bank not enabled for this widget at time of call.")
	end

	self.banked_thimble = self.context.current_thimble or "nothing"
end


--- Try to restore the old thimble state.
function widShared.restoreThimbleBank(self) --tryRestoreBankedThimble(self)
	--print("restoreThimbleBank", "do_thimble_bank", self.do_thimble_bank, "banked_thimble", self.banked_thimble)

	if not self.do_thimble_bank then
		error("thimble bank not enabled for this widget at time of call.")
	end

	if self.banked_thimble ~= "empty" then
		-- Restore to nothing
		if self.banked_thimble == "nothing" then
			--print("restore to nothing")
			self.context:clearThimble()

		elseif not self._dead then
			self.banked_thimble:tryTakeThimble()
			--print("restore to:", self.banked_thimble)
		end
	end

	self.banked_thimble = "empty"
end


-- * Keyhooks *


--[[
	Keyhooks are a way to apply non-hardcoded keyboard shortcuts to branches of widgets or the tree root.

	Keyhook callbacks:

	love.keypressed -> self.hooks_key_pressed
	love.keyreleased -> self.hooks_key_released

	Each keyhook entry is a table containing the following:

	hook.wid: The widget associated with the hook.
	hook.func(wid, hook, <callback arguments>): A function that takes the widget and the hook table as its arguments,
	followed by the standard arguments provided by the LÖVE callback. See source comments for parameter lists.

	Keyhooks are evaluated in reverse order, so the most recently added hooks get priority. You should not
	add or remove keyhooks during the evaluation loop.
--]]


function widShared.evaluateKeyhooks(keyhooks, a, b, c)
	-- keyPressed: widShared.evaluateKeyhooks(self.hooks_key_pressed, key, scancode, isrepeat)
	-- keyReleased: widShared.evaluateKeyhooks(self.hooks_key_released, key, scancode)

	for i = #keyhooks, 1, -1 do
		local tbl = keyhooks[i]
		local wid = tbl.wid
		local res

		if not wid._dead then
			res = tbl.func(wid, tbl, a, b, c)

			if res then
				return res
			end
		end
	end
end


-- * <Unsorted> *


--- Get the combined dimensions of a widget's direct children. This function assumes that all children have X and Y positions >= 0.
-- @self The widget whose children will be scanned.
-- @return Combined width and height of children.
function widShared.getCombinedChildrenDimensions(self)
	local dw, dh = 0, 0

	for i, child in ipairs(self.children) do
		dw = math.max(dw, child.x + child.w)
		dh = math.max(dh, child.y + child.h)
	end

	return dw, dh
end


--- Common setup code for setting a widget's hover-clip to match a viewport.
-- @param self The widget to modify.
-- @param v The viewport index.
function widShared.setClipHoverToViewport(self, v)
	v = vp_keys[v]

	self.clip_hover = "manual"
	self.clip_hover_x = self[v.x]
	self.clip_hover_y = self[v.y]
	self.clip_hover_w = self[v.w]
	self.clip_hover_h = self[v.h]
end


--- Common setup code for setting a widget's scissor-box to match a viewport.
function widShared.setClipScissorToViewport(self, v)
	v = vp_keys[v]

	self.clip_scissor = "manual"
	self.clip_scissor_x = self[v.x]
	self.clip_scissor_y = self[v.y]
	self.clip_scissor_w = self[v.w]
	self.clip_scissor_h = self[v.h]
end


--- Implements generic "drag-to-scroll" handling in update.
-- @param self The widget to scroll.
-- @param dt The frame's delta time.
-- @return true if the widget was scrolled, otherwise nil.
function widShared.dragToScroll(self, dt)
	local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)

	-- Mouse position relative to viewport #1.
	mx = mx - self.vp_x
	my = my - self.vp_y

	-- Drag-to-scroll
	local mouse_drag_x = (mx < 0) and mx or (mx >= self.vp_w) and mx - self.vp_w or 0
	local mouse_drag_y = (my < 0) and my or (my >= self.vp_h) and my - self.vp_h or 0

	if mouse_drag_x ~= 0 or mouse_drag_y ~= 0 then
		-- XXX style/config
		self:scrollDeltaHV(
			mouse_drag_x * dt * 4,
			mouse_drag_y * dt * 4,
			true
		)
		return true
	end
end


--- Assigns scroll registers to the widget. These offsets affect the widget's children, and may be used to position
--  components such as menus.
-- @param self The widget to set up.
-- @return Nothing.
function widShared.setupScroll(self)
	-- Integral / external-facing.
	-- The base widget metatable contains default / dummy values for these as well.
	self.scr_x = 0
	self.scr_y = 0

	-- Floating point / internal
	self.scr_fx = 0
	self.scr_fy = 0

	-- Scrolling target
	self.scr_tx = 0
	self.scr_ty = 0
end


--- Assigns document width and height fields to the widget. These represent the scrollable area of a container,
--  margins excluded.
-- @param self The widget to set up.
-- @return Nothing.
function widShared.setupDoc(self)
	self.doc_w = 0
	self.doc_h = 0
end


--- Assigns viewport fields to a widget.
-- @param self The widget.
-- @param v Index of the viewport fields to assign.
function widShared.setupViewport(self, v)
	v = vp_keys[v]

	self[v.x] = 0
	self[v.y] = 0
	self[v.w] = 0
	self[v.h] = 0
end



--- Carve an edge out of a viewport.
-- @param self The widget.
-- @param v Viewport index to modify.
-- @param e Edge ID.
function widShared.carveViewport(self, v, e)
	v, e = vp_keys[v], edge_keys[e]
	local vx, vy, vw, vh = v.x, v.y, v.w, v.h
	local skin = self.skin

	self[vx] = self[vx] + skin[e.x1]
	self[vy] = self[vy] + skin[e.y1]
	self[vw] = math.max(0, self[vw] - skin[e.x1] - skin[e.x2])
	self[vh] = math.max(0, self[vh] - skin[e.y1] - skin[e.y2])
end


--- Copies the values of one viewport to another.
-- @param self The widget to modify.
-- @param a Index of the viewport to copy from.
-- @param b Indext of the viewport to overwrite.
function widShared.copyViewport(self, a, b)
	a, b = vp_keys[a], vp_keys[b]

	self[b.x] = self[a.x]
	self[b.y] = self[a.y]
	self[b.w] = self[a.w]
	self[b.h] = self[a.h]
end


function widShared.resetViewport(self, v)
	v = vp_keys[v]

	self[v.x] = 0
	self[v.y] = 0
	self[v.w] = math.max(0, self.w)
	self[v.h] = math.max(0, self.h)
end


--- Point-in-rectangle test.
function widShared.pointInRect(self, px, py, rx, ry, rw, rh)
	return px >= rx and px < rx + rw and py >= ry and py < ry + rh
end


--- Assigns minimum and maximum dimension fields. Usage depends on the widget. (See:
--  widShared.enforceLimitedDimensions().)
function widShared.setupMinMaxDimensions(self)
	self.min_w = 64
	self.min_h = 64
	self.max_w = 2^16
	self.max_h = 2^16
end


--- Get scroll position relative to the document.
function widShared.getDocumentScroll(self)
	return self.vp_x + self.scr_x, self.vp_y + self.scr_y
end


--[[
Scroll wheel plug-in functions.
(Positive Y == rolling wheel upward.)
Only scroll if we are not at the edge of the scrollable area. Otherwise, the wheel
event should bubble up.

XXX support mapping single-dimensional wheel to horizontal scroll motion
XXX support horizontal wheels
-- [XXX 4] add support for non-animated, immediate scroll-to
--]]


function widShared.checkScrollWheelScroll(self, x, y)
	if (y > 0 and self.scr_y > -self.vp_y)
	or (y < 0 and self.scr_y < self.doc_h - self.vp_y - self.vp_h)
	then
		local old_scr_tx, old_scr_ty = self.scr_tx, self.scr_ty

		-- [XXX 3] style/theme integration
		self:scrollDeltaHV(
			-x * self.context.mouse_wheel_scale,
			-y * self.context.mouse_wheel_scale
		)

		return old_scr_tx ~= self.scr_tx or old_scr_ty ~= self.scr_ty
	end
end


--- Splits a viewport on one axis, overwriting a second viewport with the removed part.
-- @param self The widget.
-- @param a Index of the viewport to split.
-- @param b Index of the viewport to assign the remainder to.
-- @param vertical `true` to split the viewport vertically, false to split horizontally.
-- @param amount The desired length of the first viewport.
-- @param far `true` to place Viewport B on the "far" end (right for horizontal, bottom for vertical).
function widShared.splitViewport(self, a, b, vertical, amount, far)
	a, b = vp_keys[a], vp_keys[b]
	local v1x, v1y, v1w, v1h, v2x, v2y, v2w, v2h

	if vertical then
		v1x, v1y, v1w, v1h = a.y, a.x, a.h, a.w
		v2x, v2y, v2w, v2h = b.y, b.x, b.h, b.w
	else
		v1x, v1y, v1w, v1h = a.x, a.y, a.w, a.h
		v2x, v2y, v2w, v2h = b.x, b.y, b.w, b.h
	end

	self[v1w] = math.max(0, self[v1w] - amount)
	self[v2y] = self[v1y]

	self[v2w] = math.max(0, amount)
	self[v2h] = self[v1h]

	if far then
		self[v2x] = self[v1x] + self[v1w]
	else
		self[v2x] = self[v1x]
		self[v1x] = self[v2x] + self[v2w]
	end
end


--- Higher-level wrapper for splitViewport.
-- @param self The widget.
-- @param a Index of the Viewport to split.
-- @param b Index of the Viewport which will be assigned the remainder.
-- @param space How much space to allot to viewport B.
-- @param place Where Viewport B should be placed. "left", "right", "top", "bottom", or "overlay" (default).
-- @param allow_overlay When true, invalid values for 'place' become "overlay". When false, "overlay" and invalid
--	values for 'place' raise an error.
function widShared.partitionViewport(self, a, b, space, place, allow_overlay)
	if place == "left" or place == "right" then
		widShared.splitViewport(self, a, b, false, space, (place == "right"))

	elseif place == "top" or place == "bottom" then
		widShared.splitViewport(self, a, b, true, space, (place == "bottom"))

	-- Default:
	elseif allow_overlay then -- "overlay" -- viewports occupy the same area
		-- NOTE: 'space' is not used in this path.
		widShared.copyViewport(self, a, b)

	elseif place == "overlay" then
		error("'overlay' placement is not allowed in this codepath")

	else
		error("invalid placement string")
	end
end


function widShared.pointInViewport(self, v, x, y)
	v = vp_keys[v]
	local vx, vy, vw, vh = self[v.x], self[v.y], self[v.w], self[v.h]

	return x >= vx and x < vx + vw and y >= vy and y < vy + vh
end


return widShared
