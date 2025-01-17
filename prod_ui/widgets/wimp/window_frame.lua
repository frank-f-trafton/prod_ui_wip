
--[[

wimp/window_frame: A WIMP-style window frame.

........................  <─ Resize area
.┌────────────────────┐.
.│       Window [o][x]│.  <─ Window frame header, integrated drag sensor and control buttons
.├────────────────────┤.
.│File Edit View Help │.  <─ Optional menu bar
.├────────────────────┤.
.│┌─────────────────┐^│.  <─ Content container, with optional scroll bars
.││                 │║│.
.││                 │║│.
.││                 │║│.
.││                 │║│.
.│└─────────────────┘v│.
.│<═════════════════> │.
.├────────────────────┤.
.│Condition: Green    │.  <─ Optional status bar ([XXX 13] TODO)
.└────────────────────┘.
........................

Your widgets go into the 'content' container widget. You can get a reference to this widget with:

```lua
local content = frame:findTag("frame_content")
if content then
	-- etc.
end
```

Frames support modal relationships: Frame A can be blocked until Frame B is dismissed. Compare with
root-modal frames, where only the one frame (and pop-ups) can be interacted with.

Frame-modals are harder to manage than root-modals, and should only be used when really necessary
(ie the user needs to open a prompt in one frame, while looking up information in another frame).
--]]


local context = select(1, ...)

local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local function dummy_renderThimble() end


local def = {
	skin_id = "wimp_frame",
}


def.trickle = {}


-- We need to catch mouse hover+press events that occur in the frame's resize area.
function def:ui_evaluateHover(mx, my, os_x, os_y)
	local wx, wy = self.x + os_x, self.y + os_y
	local rp = self.resize_padding
	return mx >= wx - rp and my >= wy - rp and mx < wx + self.w + rp and my < wy + self.h + rp
end


function def:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)
	local wx, wy, ww, wh = self.x + os_x, self.y + os_y, self.w, self.h
	local rp = self.resize_padding
	-- in frame + padding area
	if mx >= wx - rp and my >= wy - rp and mx < wx + ww + rp and my < wy + wh + rp then
		-- just in frame
		if mx >= wx and my >= wy and mx < wx + ww and my < wy + wh then
			return true
		-- just in padding area: allow clicking through the resize sensor with mouse buttons
		-- 2, 3, etc.
		else
			return button == 1
		end
	end
end


local function getCursorCode(a_x, a_y)
	return (a_y == 0 and a_x ~= 0) and "sizewe" -- -
	or (a_y ~= 0 and a_x == 0) and "sizens" -- |
	or ((a_y == 1 and a_x == 1) or (a_y == -1 and a_x == -1)) and "sizenwse" -- \
	or ((a_y == -1 and a_x == 1) or (a_y == 1 and a_x == -1)) and "sizenesw" -- /
	or false -- unknown

	-- [XXX 16] on Fedora 36/37 + GNOME, a different cursor design is used for diagonal resize
	-- which has four orientations (up-left, up-right, down-left, down-right) instead
	-- of just two. It looks a bit incorrect when resizing a window from the bottom-left
	-- or bottom-right corners.
end


function def:initiateResizeMode(axis_x, axis_y)
	if axis_x == 0 and axis_y == 0 then
		error("invalid resize mode (0, 0).")
	end

	self.cap_mode = "resize"
	self.cap_axis_x = axis_x
	self.cap_axis_y = axis_y

	local ax, ay = self:getAbsolutePosition()
	local mx, my = self.context.mouse_x, self.context.mouse_y

	-- Track mouse offsets for a less jarring transition to resize mode.
	self.cap_ox = 0
	self.cap_oy = 0

	if axis_x < 0 then
		self.cap_ox = ax - mx

	elseif axis_x > 0 then
		self.cap_ox = ax + self.w - mx
	end

	if axis_y < 0 then
		self.cap_oy = ay - my

	elseif axis_y > 0 then
		self.cap_oy = ay + self.h - my
	end

	--print("cap_ox", self.cap_ox, "cap_oy", self.cap_oy)

	self:captureFocus()
end


function def:setDefaultBounds()
	-- Allow container to be moved partially out of bounds, but not
	-- so much that the mouse wouldn't be able to drag it back.

	local header_h = 0
	local header = self:findTag("frame_header")
	if header then
		header_h = header.h
	end

	-- XXX: theme/scale
	self.p_bounds_x1 = -48
	self.p_bounds_x2 = -48
	self.p_bounds_y1 = -self.h + math.max(4, math.floor(header_h/4))
	self.p_bounds_y2 = -48
end


function def:setFrameTitle(text)
	local header = self:findTag("frame_header")

	if header then
		header.text = text
	end
end


function def:getFrameTitle()
	local header = self:findTag("frame_header")

	if header then
		return header.text
	end
end


--- Controls what happens when the container has both scroll bars active and the user clicks
-- on the square patch where the bars meet.
local function frame_wid_patchPressed(self, x, y, button, istouch, presses)
	-- XXX doesn't set the resize cursor. Maybe the core resize action would be better handled by a
	-- separate resize sensor.

	if button == 1 then
		local content = self:findTag("frame_content")
		if not content then
			return
		end

		if content.press_busy then
			return
		end

		local ax, ay = content:getAbsolutePosition()
		local mx, my = x - ax, y - ay

		print(mx, my)

		-- [XXX 14] support scroll bars on left or top side of container
		if content.scr_h and content.scr_h.active and content.scr_v and content.scr_v.active
		and mx >= content.vp_x + content.vp_w and my >= content.vp_y + content.vp_h then
			self:initiateResizeMode(1, 1)
		end
	end
end


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = false
		self.allow_focus_capture = true
		--self.clip_hover = false
		--self.clip_scissor = false
		self.sort_id = 3

		-- Differentiates between 2nd-gen frame containers and other stuff at the same hierarchical level.
		self.is_frame = true

		self.mouse_in_resize_zone = false

		-- Set true to draw a red box around the frame's resize area.
		--self.DEBUG_show_resize_range

		-- Link to the last widget within this tree which held the thimble.
		-- The link may become stale, so confirm the widget is still alive and within the tree before using.
		self.banked_thimble1 = false

		self.cap_mode = "idle" -- idle, drag, resize
		self.cap_axis_x = false -- -1, 0, 1
		self.cap_axis_y = false -- -1, 0, 1
		-- 0,0 is invalid.

		-- Offsets from mouse when resizing.
		self.cap_ox = 0
		self.cap_oy = 0

		-- How far past the parent bounds this widget is permitted to go.
		self.p_bounds_x1 = 0
		self.p_bounds_y1 = 0
		self.p_bounds_x2 = 0
		self.p_bounds_y2 = 0

		-- How thick the frame border should be.
		self.border_breadth = 1

		-- Content and frame controls are within this rectangle, while the frame border is outside.
		widShared.setupViewports(self, 1)

		-- Layout rectangle
		self.lp_x = 0
		self.lp_y = 0
		self.lp_w = 1
		self.lp_h = 1

		-- Used when unmaximizing as a result of dragging.
		self.cap_mouse_orig_a_x = 0
		self.cap_mouse_orig_a_y = 0

		self.maximized = false
		self.maxim_x = 0
		self.maxim_y = 0
		self.maxim_w = 128
		self.maxim_h = 128

		-- Set true to allow dragging the container by clicking on its body
		self.allow_body_drag = false -- XXX moved from container, maybe not the correct place here.

		-- Used to position frame relative to pointer when dragging.
		self.drag_ox = 0
		self.drag_oy = 0

		-- Minimum container size
		self.min_w = 64
		self.min_h = 64

		-- Maximum container size
		self.max_w = 2^16
		self.max_h = 2^16

		self:skinSetRefs()
		self:skinInstall()

		self.resize_padding = self.skin.sensor_resize_pad

		-- Layout rectangle
		uiLayout.initLayoutRectangle(self)

		-- Don't let inter-generational thimble stepping leave this widget's children.
		self.block_step_intergen = true

		-- Header (title) bar, with some controls
		local frame_header = self:addChild("wimp/frame_header")

		-- Add header to layout sequence
		frame_header.lc_func = uiLayout.fitTop

		-- Optional menu bar
		if self.make_menu_bar then
			local menu_bar = self:addChild("wimp/menu_bar")

			menu_bar.tag = "frame_menu_bar"

			menu_bar.lc_func = uiLayout.fitTop
		end

		-- Main content container
		local content = self:addChild("base/container")
		content.tag = "frame_content"
		--content.render = content.renderBlank

		content:setScrollBars(true, true)

		-- Add content to layout sequence
		content.lc_func = uiLayout.fitRemaining

		content:reshape()

		content.can_have_thimble = true

		--self:setDefaultBounds()

		self.center = widShared.centerInParent
		--print("self.center", self.center)

		self.wid_maximize = widShared.wid_maximize
		self.wid_unmaximize = widShared.wid_unmaximize
		--self.wid_patchPressed = frame_wid_patchPressed

		-- Helps with ctrl+tabbing through frames.
		self.order_id = self:bubbleEvent("rootCall_getFrameOrderID")

		-- Frame-modal widget links. Truthy-checks are used to determine if a frame is currently
		-- being blocked or is blocking another frame.
		self.ref_modal_prev = false
		self.ref_modal_next = false

		-- Table of widgets to offer keyPressed and keyReleased input.
		self.hooks_trickle_key_pressed = {}
		self.hooks_trickle_key_released = {}
		self.hooks_key_pressed = {}
		self.hooks_key_released = {}

		-- Call reshape(true) on this once you've set the initial size.
	end
end


function def:_trySettingThimble1()
	-- Check modal state before calling.

	local wid_banked = self.banked_thimble1

	if wid_banked and wid_banked.can_have_thimble and wid_banked:hasThisAncestor(self) then
		wid_banked:takeThimble1()
	else
		local content = self:findTag("frame_content")
		if content and content.can_have_thimble then
			content:takeThimble1()
		end
	end
end


function def:setModal(target)
	-- You can chain modal frames together, but only one frame may be modal to another frame at a time.
	if target.ref_modal_next then
		error("target frame already has a modal reference set (target.ref_modal_next).")

	elseif self.ref_modal_prev then
		error("this frame already has a modal reference set (self.ref_modal_prev).")
	end

	self.ref_modal_prev = target
	target.ref_modal_next = self
end


function def:clearModal()
	-- Frame-modal state must be popped last-to-first.
	if self.ref_modal_next then
		error("this frame still has a modal reference (self.ref_modal_next).")

	elseif not self.ref_modal_prev then
		error("no modal target frame to clear (self.ref_modal_prev).")
	end

	local target = self.ref_modal_prev
	self.ref_modal_prev = false
	target.ref_modal_next = false

	return target
end


function def:frameCall_close(inst)
	self:remove() -- XXX fortify against calls during update-lock

	-- Stop bubbling
	return true
end


function def.trickle:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self.ref_modal_next then
		self.context.current_hover = false
		return true
	end
end


function def:uiCall_pointerHoverMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		local axis_x = mx < 0 and -1 or mx >= self.w and 1 or 0
		local axis_y = my < 0 and -1 or my >= self.h and 1 or 0
		if not (axis_x == 0 and axis_y == 0) then
			self.mouse_in_resize_zone = true
			local cursor_id = getCursorCode(axis_x, axis_y)
			self:setCursorLow(cursor_id)
		else
			if self.mouse_in_resize_zone then
				self.mouse_in_resize_zone = false
				self:setCursorLow()
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		self.mouse_in_resize_zone = false
		self:setCursorLow()
	end
end


function def:uiCap_mouseMoved(x, y, dx, dy, istouch)
	if self.cap_mode == "resize" then
		return widShared.uiCapEvent_resize_mouseMoved(self, self.cap_axis_x, self.cap_axis_y, x, y, dx, dy, istouch)

	elseif self.cap_mode == "drag" then
		return widShared.uiCapEvent_drag_mouseMoved(self, x, y, dx, dy, istouch)
	end
end


function def:uiCap_mouseReleased(x, y, button, istouch, presses)
	if self.cap_mode == "resize" then
		return widShared.uiCapEvent_resize_mouseReleased(self, x, y, button, istouch, presses)

	elseif self.cap_mode == "drag" then
		return widShared.uiCapEvent_drag_mouseReleased(self, x, y, button, istouch, presses)
	end
end


function def:uiCall_thimble1Take(inst)
	--print("thimbleTake", self.id, inst.id)
	self.banked_thimble1 = inst
end


function def:refreshSelected(is_selected)
	local header = self:findTag("frame_header")
	if header then
		header.selected = not not is_selected
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	-- Frame-modal check
	if self.ref_modal_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_key_pressed, key, scancode, isrepeat) then
		return true
	end
end


function def.trickle:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if widShared.evaluateKeyhooks(self, self.hooks_trickle_key_pressed, key, scancode, isrepeat) then
		return true
	end
end


function def:uiCall_keyReleased(inst, key, scancode)
	-- Frame-modal check
	if self.ref_modal_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_key_released, key, scancode) then
		return true
	end
end


function def.trickle:uiCall_keyReleased(inst, key, scancode)
	if widShared.evaluateKeyhooks(self, self.hooks_key_released, key, scancode) then
		return true
	end
end


function def:uiCall_textInput(inst, text)
	-- Frame-modal check
	if self.ref_modal_next then
		return
	end
end


function def:bringToFront()
	self:reorder("last")
	self.parent:sortChildren()
end


function def.trickle:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self.ref_modal_next then
		self.context.current_pressed = false
		return true
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	--print("window-frame pointer-press", self, inst, x, y, button)
	-- Drag actions are primarily initiated by child sensors.

	-- Press events that create a pop-up menu should block propagation (return truthy)
	-- so that this and the WIMP root do not cause interference.

	local root = self:getTopWidgetInstance()

	-- Frame-modal check
	local modal_next = self.ref_modal_next
	if modal_next then
		root:setSelectedFrame(modal_next, true)
		return
	end

	root:setSelectedFrame(self, true)
	self.order_id = root:sendEvent("rootCall_getFrameOrderID")

	-- If thimble1 is not in this widget tree, move it to the container.
	local thimble1 = self.context.thimble1
	if not thimble1 or not thimble1:hasThisAncestor(self) then
		self:_trySettingThimble1()
	end

	if self == inst then
		-- If the mouse pointer is outside the frame bounds, then this is a resize action.
		local mx, my = self:getRelativePosition(x, y)
		if not (mx >= 0 and my >= 0 and mx < self.w and my < self.h) then
			local axis_x = mx < 0 and -1 or mx >= self.w and 1 or 0
			local axis_y = my < 0 and -1 or my >= self.h and 1 or 0
			if not (axis_x == 0 and axis_y == 0) then
				self:initiateResizeMode(axis_x, axis_y)
			end
		end
	end

	-- XXX: These should be initiated with callbacks from the content container.
	--[=[
	-- Callback for when the user clicks on the scroll dead-patch.
	if self.wid_patchPressed and self:wid_patchPressed(x, y, button, istouch, presses) then
		-- ...

	-- Dragging can also be started by clicking on the container body if 'allow_body_drag' is truthy.
	elseif self.allow_body_drag then
		self.cap_mode = "drag"
		self.cap_mouse_orig_a_x = x
		self.cap_mouse_orig_a_y = y
		self:captureFocus()
	end
	--]=]
end


function def:uiCall_reshape()
	-- (parent should be the WIMP root widget.)
	local parent = self.parent
	local wimp_res = self.context.resources.wimp

	-- Refit if maximized and parent dimensions changed.
	if self.maximized then
		self.x = parent.vp2_x
		self.y = parent.vp2_y
		if self.w ~= parent.vp2_w or self.h ~= parent.vp2_h then
			self.w = parent.vp2_w
			self.h = parent.vp2_h
		end
	end

	widShared.enforceLimitedDimensions(self)

	-- Update viewport, then components.
	self.vp_x = self.border_breadth
	self.vp_y = self.border_breadth
	self.vp_w = self.w - self.border_breadth*2
	self.vp_h = self.h - self.border_breadth*2

	uiLayout.resetLayoutPort(self, 1)

	local header = self:findTag("frame_header")
	local menu_bar = self:findTag("frame_menu_bar")
	local content = self:findTag("frame_content")

	if header then
		header.h = header.condensed and wimp_res.frame_header_height_condensed or wimp_res.frame_header_height_norm
		uiLayout.fitTop(self, header)
	end

	if menu_bar then
		menu_bar:resize()
		uiLayout.fitTop(self, menu_bar)
	end

	if content then
		uiLayout.fitRemaining(self, content)
		content:updateContentClipScissor()
	end

	-- Needs to happen after shaping the header bar, as the header height factors into the default bounds.
	self:setDefaultBounds()

	-- Hacky way of not interfering with resize actions. Call keepInBounds* before exiting the resize mode.
	if self.cap_mode ~= "resize" then
		--widShared.keepInBoundsPort2(self)
		widShared.keepInBoundsExtended(self, 2, self.p_bounds_x1, self.p_bounds_x2, self.p_bounds_y1, self.p_bounds_y2)
	end

	-- The rest should take care of themselves with their own reshape calls.
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Clean up any existing frame-modal connection. Note that this function will raise an error if another frame
		-- is still blocking this frame.
		if self.ref_modal_prev then
			local target = self:clearModal()

			-- Clean up the target's focus a bit.
			--[[
			local root = self:getTopWidgetInstance()
			root:setSelectedFrame(target, true)

			target:reorder("last")
			target.parent:sortChildren()

			target:_trySettingThimble1()
			--]]
		end

		-- Clean up root-level modal level, if applicable.
		local root = self:getTopWidgetInstance()
		if self == root.modals[#root.modals] then
			root:sendEvent("rootCall_clearModalFrame", self)
		end
	end
end


def.skinners = {
	default = {
		install = function(self, skinner, skin)
			uiTheme.skinnerCopyMethods(self, skinner)
		end,


		remove = function(self, skinner, skin)
			uiTheme.skinnerClearData(self)
		end,


		render = function(self, ox, oy)
			local skin = self.skin
			local slc_body = skin.slc_body

			love.graphics.setColor(skin.color_body)
			uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

			if self.DEBUG_show_resize_range then
				local rp = self.resize_padding
				love.graphics.push("all")

				love.graphics.setScissor()
				love.graphics.setColor(0.8, 0.1, 0.2, 0.8)

				love.graphics.setLineWidth(1)
				love.graphics.setLineJoin("miter")
				love.graphics.setLineStyle("rough")

				love.graphics.rectangle("line", 0.5 - rp, 0.5 - rp, self.w + rp*2 - 1, self.h + rp*2 - 1)

				love.graphics.pop()
			end
		end,
	},
}


return def
