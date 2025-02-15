-- ProdUI: Shared widget logic.


local widShared = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local commonMath = require(REQ_PATH .. "common_math")


-- A common dummy function for widgets.
function widShared.dummy() end


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


--- Gets the table keys for a widget viewport. (ie index 2 will return 'vp2_x', 'vp2_y', 'vp2_w' and 'vp2_h'.)
function widShared.getViewportKeys(self, v)
	assert(vp_keys[v], "invalid viewport index.")
	return vp_keys[v].x, vp_keys[v].y, vp_keys[v].w, vp_keys[v].h
end


--- Gets the XYWH values of a widget viewport, or (0, 0) and the widget's dimensions if no viewport index is specified.
-- @param self The widget.
-- @param v The viewport index, or `nil`.
-- @return The viewport / widget position and dimensions.
function widShared.getViewportXYWH(self, v)
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

	local px, py, pw, ph = widShared.getViewportXYWH(parent, v)

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

	local px, py, pw, ph = widShared.getViewportXYWH(parent, v)

	self.x = math.max(-self.w - x1 + px, math.min(self.x, pw + x2))
	self.y = math.max(-self.h - y1 + py, math.min(self.y, ph + y2))
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
	local nav = self.context.settings.wimp.navigation
	local spd_snap, spd_min, spd_mul = nav.scroll_snap, nav.scroll_speed_min, nav.scroll_speed_mul
	self.scr_fx = widShared.scrollTargetUpdate(self.scr_fx, self.scr_tx, spd_snap, spd_min, spd_mul, dt)
	self.scr_fy = widShared.scrollTargetUpdate(self.scr_fy, self.scr_ty, spd_snap, spd_min, spd_mul, dt)

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


function widShared.scrollGetXY(self)
	return self.scr_x + self.vp_x, self.scr_y + self.vp_y
end


function widShared.scrollGetX(self)
	return self.scr_x + self.vp_x
end


function widShared.scrollGetY(self)
	return self.scr_y + self.vp_y
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

	self.scrollGetXY = widShared.scrollGetXY
	self.scrollGetX = widShared.scrollGetX
	self.scrollGetY = widShared.scrollGetY
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


function widShared.chainHasThisWidget(self, wid_check)
	local wid = self.chain_next
	while wid do
		if wid == wid_check then
			return true
		end
		wid = wid.chain_next
	end

	wid = self.chain_prev
	while wid do
		if wid == wid_check then
			return true
		end
		wid = wid.chain_prev
	end

	return self == wid_check
end


function widShared.chainHasThisWidgetRight(self, wid_check)
	local wid = self.chain_next
	while wid do
		if wid == wid_check then
			return true
		end
		wid = wid.chain_next
	end

	return self == wid_check
end


-- * Keyhooks *


--[[
	Keyhooks are a way to apply non-hardcoded keyboard shortcuts to branches of widgets or the tree root.

	Keyhook callbacks:

	(trickle) love.keypressed -> self.hooks_trickle_key_pressed
	(trickle) love.keyreleased -> self.hooks_trickle_key_released
	(bubble, direct) love.keypressed -> self.hooks_key_pressed
	(bubble, direct) love.keyreleased -> self.hooks_key_released

	Each keyhook entry is a function that takes the widget as its first argument, followed by the standard arguments
	provided by the LÖVE callback. See source comments for parameter lists.

	Keyhooks are evaluated in reverse order, so the most recently added hook gets priority. You should not
	add or remove keyhooks during the evaluation loop.
--]]


function widShared.evaluateKeyhooks(self, keyhooks, a, b, c)
	-- keyPressed: widShared.evaluateKeyhooks(self, self.hooks_key_pressed, key, scancode, isrepeat)
	-- keyReleased: widShared.evaluateKeyhooks(self, self.hooks_key_released, key, scancode)

	for i = #keyhooks, 1, -1 do
		local func = keyhooks[i]
		if not self._dead then
			local res = func(self, a, b, c)

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
-- @param x_side, y_side Initial settings for X and Y. -1: as far left/top as possible, 1: as far right/bottom
--	as possible, 0: zero. The values should be clamped by the widget's reshape handler. Note that zero is only the
--	"top-left" if Viewport #1 is also at (0,0).
-- @return Nothing.
function widShared.setupScroll(self, x_side, y_side)
	-- Integral / external-facing.
	-- The base widget metatable contains default / dummy values for these as well.
	self.scr_x = x_side * math.huge
	self.scr_y = y_side * math.huge

	-- Floating point / internal
	self.scr_fx = x_side * math.huge
	self.scr_fy = y_side * math.huge

	-- Scrolling target
	self.scr_tx = x_side * math.huge
	self.scr_ty = y_side * math.huge
end


--- Assigns document width and height fields to the widget. These represent the scrollable area of a container,
--  margins excluded.
-- @param self The widget to set up.
-- @return Nothing.
function widShared.setupDoc(self)
	self.doc_w, self.doc_h = 0, 0
end


--- Assigns viewport fields to a widget.
-- @param self The widget.
-- @param n The number of viewports to assign, from 1 to `n`, up to `#widShared.vp_keys`.
function widShared.setupViewports(self, n)
	if n > #vp_keys then
		error("attempted to set too many viewports (max " .. #vp_keys .. ")")
	end
	for i = 1, n do
		local v = vp_keys[i]
		self[v.x], self[v.y], self[v.w], self[v.h] = 0, 0, 0, 0
	end
end


--- Carve an edge out of a viewport.
-- @param self The widget.
-- @param v Viewport index to modify.
-- @param e A table with the fields 'x1', 'y1', 'x2' and 'y2'.
function widShared.carveViewport(self, v, e)
	v = vp_keys[v]
	local vx, vy, vw, vh = v.x, v.y, v.w, v.h

	self[vx] = self[vx] + e.x1
	self[vy] = self[vy] + e.y1
	self[vw] = math.max(0, self[vw] - e.x1 - e.x2)
	self[vh] = math.max(0, self[vh] - e.y1 - e.y2)
end


--- Reduce or enlarge a viewport in place with relative numbers.
-- untested
--[[
function widShared.resizeViewportInPlace(self, v, x1, y1, x2, y2)
	v = vp_keys[v]
	local vx, vy, vw, vh = v.x, v.y, v.w, v.h

	self[vx] = self[vx] + x1
	self[vy] = self[vy] + y1
	self[vw] = self[vw] + x2 - x1
	self[vh] = self[vh] + y2 - y1
end
--]]


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


--- Assigns minimum and maximum dimension fields. Usage depends on the widget. (See:
--  widShared.enforceLimitedDimensions().)
function widShared.setupMinMaxDimensions(self)
	self.min_w = 64
	self.min_h = 64
	self.max_w = 2^16
	self.max_h = 2^16
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

		local wheel_scale = self.context.settings.wimp.navigation.mouse_wheel_move_size_v
		self:scrollDeltaHV(-x * wheel_scale, -y * wheel_scale)

		return self.scr_ty ~= self.scr_y or old_scr_tx ~= self.scr_tx or old_scr_ty ~= self.scr_ty
	end
end


--- Splits a viewport on one axis, overwriting a second viewport with the removed part.
-- @param self The widget.
-- @param a Index of the viewport to split.
-- @param b Index of the viewport to assign the remainder to.
-- @param vertical `true` to split the viewport vertically, `false` to split horizontally.
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


--- Places a viewport onto the edge of another viewport.
-- @param self The widget.
-- @param a Index of the reference viewport.
-- @param b Index of the viewport to move.
-- @param side Where Viewport B should be placed. "left", "right", "top" or "bottom".
-- @param coverage A number from 0.0 to 1.0 which controls how far in or out Viewport B is placed,
--	0.0 is behind the edge, 0.5 is in the middle, and 1.0 is ahead of it. Default: 0.5
function widShared.straddleViewport(self, a, b, side, coverage)
	a, b = vp_keys[a], vp_keys[b]
	coverage = coverage or 0.5

	if side == "left" then
		self[b.x] = self[a.x] - math.floor(self[b.w] * coverage)
		self[b.y] = self[a.y]
		self[b.h] = self[a.h]

	elseif side == "right" then
		self[b.x] = self[a.x] + self[a.w] - math.floor(self[b.w] * coverage)
		self[b.y] = self[a.y]
		self[b.h] = self[a.h]

	elseif side == "top" then
		self[b.y] = self[a.y] - math.floor(self[b.h] * coverage)
		self[b.x] = self[a.x]
		self[b.w] = self[a.w]

	elseif side == "bottom" then
		self[b.y] = self[a.y] + self[a.h] - math.floor(self[b.h] * coverage)
		self[b.x] = self[a.x]
		self[b.w] = self[a.w]

	else
		error("invalid side string")
	end
end


function widShared.pointInViewport(self, v, x, y)
	v = vp_keys[v]
	local vx, vy, vw, vh = self[v.x], self[v.y], self[v.w], self[v.h]

	return x >= vx and x < vx + vw and y >= vy and y < vy + vh
end


return widShared
