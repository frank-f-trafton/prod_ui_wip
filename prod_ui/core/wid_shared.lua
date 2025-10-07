-- To load: local lib = context:getLua("shared/lib")


local context = select(1, ...)


local widShared = {}


widShared.debug = context:getLua("core/wid/debug")


local pools = context:getLua("core/res/pools")
local pRect = require(context.conf.prod_ui_req .. "lib.pile_rectangle")


local _viewport_keys = context:getLua("core/wid/viewport_keys")
widShared.viewport_keys = _viewport_keys


function widShared.dummy() end


function widShared.getViewportFromIndex(self, n)
	local name = _viewport_keys[n]
	if not name then
		error("invalid viewport index: " .. tostring(n))
	end
	return self[name] -- can be nil
end


--- Gets the XYWH values of a widget viewport, or (0, 0) and the widget's dimensions if no viewport index is specified.
-- @param self The widget.
-- @param vp The viewport table, or nil.
-- @param rel_zero When true, reports the viewport's position as (0, 0). This is desirable in some cases involving
--	Viewport #1 and scrolling. This argument has no effect when 'vp' is nil.
-- @return The viewport / widget position and dimensions.
function widShared.getViewportXYWH(self, vp, rel_zero)
	if vp then
		if rel_zero then
			return 0, 0, vp.w, vp.h
		else
			return vp.x, vp.y, vp.w, vp.h
		end
	else
		return 0, 0, self.w, self.h
	end
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

	local pvp2 = parent.vp2

	self.x = math.max(-self.w - self.p_bounds_x1 + pvp2.x, math.min(self.x, pvp2.w + self.p_bounds_x2))
	self.y = math.max(-self.h - self.p_bounds_y1 + pvp2.y, math.min(self.y, pvp2.h + self.p_bounds_y2))
end
--]]


-- Use to keep a widget within the bounds of its parent.
-- TODO: document spill-out behavior.
-- @param self The widget.
-- @param vp The viewport to use. Leave `nil` to use the parent's width and height.
function widShared.keepInBoundsOfParent(self, vp)
	local parent = self.parent
	if not parent then
		return
	end

	local px, py, pw, ph = widShared.getViewportXYWH(parent, vp) -- TODO: rel_zero?

	self.x = math.max(px, math.min(self.x, pw - self.w))
	self.y = math.max(py, math.min(self.y, ph - self.h))
end


-- Use to keep a widget partially within the bounds of a parent (ie window frames).
-- TODO: document spill-out behavior.
-- @param self The widget.
-- @param vp The viewport to use. Leave `nil` to use the parent's width and height.
-- @param x1, x2, y1, y2 How much of the widget must remain within the parent's boundaries on each side.
function widShared.keepInBoundsExtended(self, vp, x1, x2, y1, y2)
	local parent = self.parent
	if not parent then
		return
	end

	local px, py, pw, ph = widShared.getViewportXYWH(parent, vp) -- TODO: rel_zero?

	print("px", px, "py", py, "pw", pw, "ph", ph)

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
	local pvp2 = parent.vp2

	self.x = pvp2.x
	self.y = pvp2.y
	self.w = pvp2.w
	self.h = pvp2.h

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
	-- The widget must have a parent.
	local parent = self.parent
	local pvp2 = parent.vp2

	self.x = self.maxim_x or 64
	self.y = self.maxim_y or 64
	self.w = self.maxim_w or pvp2.w - 64
	self.h = self.maxim_h or pvp2.h - 64

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
	if self.x < pvp2.x then
		self.x = pvp2.x
	end
	if self.y < pvp2.y then
		self.y = pvp2.y
	end
	if self.x + self.w > pvp2.x + pvp2.w then
		self.x = pvp2.x + pvp2.w - self.w
	end
	if self.y + self.h > pvp2.y + pvp2.h then
		self.y = pvp2.y + pvp2.h - self.h
	end
	if self.w > pvp2.w then
		self.w = pvp2.w
	end
	if self.h > pvp2.h then
		self.h = pvp2.h
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
	local vp = self.vp
	self.scr_fx = math.max(-vp.x, math.min(self.scr_fx, -vp.x + self.doc_w - vp.w))
	self.scr_fy = math.max(-vp.y, math.min(self.scr_fy, -vp.y + self.doc_h - vp.h))

	self.scr_x = math.floor(0.5 + self.scr_fx)
	self.scr_y = math.floor(0.5 + self.scr_fy)

	self.scr_tx = math.max(-vp.x, math.min(self.scr_tx, -vp.x + self.doc_w - vp.w))
	self.scr_ty = math.max(-vp.y, math.min(self.scr_ty, -vp.y + self.doc_h - vp.h))
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
	local vp = self.vp

	-- Clamp the scroll target.
	self.scr_tx = math.max(x2 - vp.x - vp.w, math.min(self.scr_tx, x1 - vp.x))

	if immediate then
		self.scr_fx = self.scr_tx
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollYInBounds(self, y1, y2, immediate)
	local vp = self.vp

	-- Clamp the scroll target.
	self.scr_ty = math.max(y2 - vp.y - vp.h, math.min(self.scr_ty, y1 - vp.y))

	if immediate then
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollRectInBounds(self, x1, y1, x2, y2, immediate)
	local vp = self.vp

	-- Clamp the scroll target.
	self.scr_tx = math.max(x2 - vp.x - vp.w, math.min(self.scr_tx, x1 - vp.x))
	self.scr_ty = math.max(y2 - vp.y - vp.h, math.min(self.scr_ty, y1 - vp.y))

	if immediate then
		self.scr_fx = self.scr_tx
		self.scr_fy = self.scr_ty
	end

	widShared.scrollClampViewport(self)
end


function widShared.scrollH(self, x, immediate)
	self.scr_tx = -self.vp.x + x
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
	self.scr_ty = -self.vp.y + y
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
	local vp = self.vp

	self.scr_tx = -vp.x + x
	self.scr_ty = -vp.y + y
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
	local vp = self.vp

	return self.scr_x + vp.x, self.scr_y + vp.y
end


function widShared.scrollGetX(self)
	return self.scr_x + self.vp.x
end


function widShared.scrollGetY(self)
	return self.scr_y + self.vp.y
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
	Keyhooks are a way to apply non-hardcoded keyboard shortcuts to widgets (typically UI Frames or the root widget).

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
	-- TODO --return pRectangle.getCombinedDimensions(self.children)
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
function widShared.setClipHoverToViewport(self, vp)
	self.clip_hover = "manual"
	self.clip_hover_x = vp.x
	self.clip_hover_y = vp.y
	self.clip_hover_w = vp.w
	self.clip_hover_h = vp.h
end


--- Common setup code for setting a widget's scissor-box to match a viewport.
function widShared.setClipScissorToViewport(self, vp)
	self.clip_scissor = "manual"
	self.clip_scissor_x = vp.x
	self.clip_scissor_y = vp.y
	self.clip_scissor_w = vp.w
	self.clip_scissor_h = vp.h
end


--- Implements generic "drag-to-scroll" handling in update.
-- @param self The widget to scroll.
-- @param dt The frame's delta time.
-- @return true if the widget was scrolled, otherwise nil.
function widShared.dragToScroll(self, dt)
	local vp = self.vp
	local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)

	-- Mouse position relative to viewport #1.
	mx = mx - vp.x
	my = my - vp.y

	-- Drag-to-scroll
	local mouse_drag_x = (mx < 0) and mx or (mx >= vp.w) and mx - vp.w or 0
	local mouse_drag_y = (my < 0) and my or (my >= vp.h) and my - vp.h or 0

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


function widShared.updateDoc(self)
	-- For containers of widgets.
	if self.scroll_range_mode == "auto" then
		self.doc_w, self.doc_h = widShared.getCombinedChildrenDimensions(self)

	elseif self.scroll_range_mode == "zero" then
		self.doc_w, self.doc_h = 0, 0
	end
end


--- Assigns viewport fields to a widget.
-- @param self The widget.
-- @param n The number of viewports to assign.
function widShared.setupViewports(self, n)
	for i = 1, n do
		self[_viewport_keys[i]] = pools.rect:pop()
	end
end


function widShared.removeViewports(self, n)
	for i = n, 1, -1 do
		local k = _viewport_keys[i]
		self[k] = pools.rect:push(self[k])
	end
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
	-- TODO: properly handle horizontal scrolling.

	local vp = self.vp

	if (y > 0 and self.scr_y > -vp.y)
	or (y < 0 and self.scr_y < self.doc_h - vp.y - vp.h)
	then
		local old_scr_tx, old_scr_ty = self.scr_tx, self.scr_ty

		local wheel_scale = self.context.settings.wimp.navigation.mouse_wheel_move_size_v
		self:scrollDeltaHV(-x * wheel_scale, -y * wheel_scale)

		return self.scr_ty ~= self.scr_y or old_scr_tx ~= self.scr_tx or old_scr_ty ~= self.scr_ty
	end
end


function widShared.getSortLaneEdge(seq, lane, side)
	if side == "first" then
		for i = 1, #seq do
			local comp = seq[i]
			if comp.sort_id >= lane then
				return i
			end
		end

	elseif side == "last" then
		for i = #seq, 1, -1 do
			local comp = seq[i]
			if comp.sort_id <= lane then
				return i + 1
			end
		end

	else
		error("invalid 'side' argument (must be 'first' or 'last').")
	end
end


return widShared
