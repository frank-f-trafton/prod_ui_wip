local context = select(1, ...)


-- Window frame utility functions.


local lgcWindowFrame = {}


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local widShared = context:getLua("core/wid_shared")


-- @param dir 1 for right and bottom calculations, -1 for left and top calculations, 0 to return the old values.
local function _resize(dir, x, w, min_w, target)
	target = math.floor(0.5 + target)
	if dir == -1 then
		local old_x = x
		local new_x = math.min(target, x + w - min_w)
		return new_x, w + (old_x - new_x)

	elseif dir == 1 then
		return x, math.max(min_w, target - x)

	else -- dir == 0
		return x, w
	end
end


function lgcWindowFrame.mouseMovedResize(self, axis_x, axis_y, x, y, dx, dy, istouch)
	local mx, my = x, y
	local old_w, old_h = self.w, self.h

	-- Get mouse position in parent's space
	local ax, ay = self.parent:getRelativePosition(mx, my)

	-- Crop mouse position to a range slightly larger than the parent rectangle.
	-- Prevents stretching frames far beyond the LÖVE window.
	local outbound_limit = self.context.resources.wimp.window_frames.frame_outbound_limit
	mx = math.max(-outbound_limit, math.min(mx, self.parent.w + outbound_limit))
	my = math.max(-outbound_limit, math.min(my, self.parent.h + outbound_limit))

	--[[
	print(
		"x", x, "y", y,
		"ax", ax, "ay", ay,
		"mx", mx, "my", my,
		"self.adjust_ox", self.adjust_ox, "self.adjust_oy", self.adjust_oy
	)
	--]]

	-- Resize the container.
	self.x, self.w = _resize(axis_x, self.x, self.w, self.min_w, mx + self.adjust_ox)
	self.y, self.h = _resize(axis_y, self.y, self.h, self.min_h, my + self.adjust_oy)

	if old_w ~= self.w or old_h ~= self.h then
		self:reshape()
	end
end


function lgcWindowFrame.mouseMovedDrag(self, x, y, dx, dy, istouch)
	--[[
	Relies on the following fields:
	self.drag_ox
	self.drag_oy
	--]]

	local old_x, old_y = self.context.mouse_x, self.context.mouse_y

	if self.maximized and self.allow_resize and self.allow_maximize then
		-- Unmaximize only if the mouse has wandered a bit from its original click-point.
		if self.context.mouse_x < self.adjust_mouse_orig_a_x - 32
		or self.context.mouse_x >= self.adjust_mouse_orig_a_x + 32
		or self.context.mouse_y < self.adjust_mouse_orig_a_y - 32
		or self.context.mouse_y >= self.adjust_mouse_orig_a_y + 32
		then
			-- If unmaximizing as a result of the pointer dragging the top bar, tweak the
			-- container's XY position so that it looks like the mouse pointer has gripped
			-- the window.

			local a_x, a_y = self:getAbsolutePosition()
			local mouse_rel_x = self.context.mouse_x - a_x
			local mouse_rel_y = self.context.mouse_y - a_y

			-- 0.0 == left or top, 1.0 == bottom or right
			local lerp_x = commonMath.lerp(0, self.w, mouse_rel_x / self.w) / self.w
			local lerp_y = commonMath.lerp(0, self.h, mouse_rel_y / self.h) / self.h

			self:wid_unmaximize()
			self:reshape()

			-- Would need adjustments if dragging elsewhere (not along the top bar)
			-- unmaximizes the window.
			self.drag_ox = math.floor(0.5 - lerp_x * self.w)
			self.drag_oy = -self.adjust_mouse_orig_a_y
		end
	end

	if not self.maximized then
		-- Update self's position
		local parent = self.parent
		if parent then
			local pa_x, pa_y = parent:getAbsolutePosition()

			self.x = self.context.mouse_x - pa_x + self.drag_ox
			self.y = self.context.mouse_y - pa_y + self.drag_oy
		end

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


return lgcWindowFrame
