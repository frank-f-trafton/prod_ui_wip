
--[[

wimp/window_frame: A WIMP-style window frame.

........................  <─ Resize area
.┌────────────────────┐.
.│      Window  [o][x]│.  <─ Window frame header, drag sensor and control buttons
.├────────────────────┤.
.│```````````````````^│.  <- '`': Viewport #1
.│`                 `║│.
.│`                 `║│.
.│`                 `║│.
.│`                 `║│.
.│```````````````````v│.
.│<═════════════════> │.  <─ Optional scroll bars
.└────────────────────┘.
........................

Window Frames support modal relationships: Frame A can be blocked until Frame B is dismissed. Compare
with root-modal state, where only the one Window Frame (and pop-ups) can be interacted with.

Frame-modals are harder to manage than root-modals, and should only be used when really necessary
(ie the user needs to open a prompt in one frame, while looking up information in another frame).
--]]


local context = select(1, ...)

local commonFrame = require(context.conf.prod_ui_req .. "common.common_frame")
local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local lgcContainer = context:getLua("shared/lgc_container")
local lgcUIFrame = context:getLua("shared/lgc_ui_frame")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local _lerp = commonMath.lerp


local _header_sizes = pTable.makeLUT({"small", "normal", "large"})


local def = {
	skin_id = "wimp_frame",

	default_settings = {
		allow_close = true,
		allow_drag_move = true,
		allow_maximize = true, -- depends on 'allow_resize' being true
		allow_resize = true,
		frame_render_shadow = false,
		header_visible = true,
		header_button_side = "right", -- "left", "right"
		header_show_close_button = true,
		header_show_max_button = true,
		header_text = "",
		header_size = "normal" -- enum: `_header_sizes`
	},
}


def.trickle = {}


widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


def.center = widShared.centerInParent
def.wid_maximize = widShared.wid_maximize
def.wid_unmaximize = widShared.wid_unmaximize
--def.wid_patchPressed = frame_wid_patchPressed


local function _newSensor(id)
	return {x=0, y=0, w=0, h=0, enabled=false, id=id}
end


-- We need to catch mouse hover+press events that occur in the frame's resize area.
function def:ui_evaluateHover(mx, my, os_x, os_y)
	local wx, wy = self.x + os_x, self.y + os_y
	local rp = not self.maximized and self.allow_resize and self.skin.sensor_resize_pad or 0
	return mx >= wx - rp and my >= wy - rp and mx < wx + self.w + rp and my < wy + self.h + rp
end


function def:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)
	local wx, wy, ww, wh = self.x + os_x, self.y + os_y, self.w, self.h
	local rp = not self.maximized and self.allow_resize and self.skin.sensor_resize_pad or 0
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


function def:setHeaderVisible(enabled)
	self:writeSetting("header_visible", not not enabled)
	self:reshape(true)
end


function def:getHeaderVisible()
	return self.header_visible
end


function def:setHeaderSize(size)
	size = size and size
	if size and not _header_sizes[size] then
		error("invalid header size.")
	end

	if self.header_size ~= size then
		local sx, sy = self:scrollGetXY()
		--local vp_y_old = self.vp_y
		self:writeSetting("header_size", size)
		self:reshape(true)
		self:scrollHV(sx, sy, true)
		--print("vp_y_old", vp_y_old, "self.vp_y", self.vp_y)
		--widShared.scrollDeltaV(self, vp_y_old - self.vp_y, true)
	end
end


function def:getHeaderSize()
	return self.header_size
end


-- (Resizable by the user.)
function def:setResizable(enabled)
	self:writeSetting("allow_resize", not not enabled)
	self.b_max.enabled = self.allow_resize and self.allow_maximize and true or false
end


function def:getResizable()
	return self.allow_resize
end


function def:setDraggable(enabled)
	self:writeSetting("allow_drag_move", not not enabled)
end


function def:getDraggable()
	return self.allow_drag_move
end


function def:setCloseControlVisibility(visible)
	self:writeSetting("header_show_close_button", not not visible)
	self:reshape()
end


function def:getCloseControlVisibility()
	return self.header_show_close_button
end


function def:setMaximizeControlVisibility(visible)
	self:writeSetting("header_show_max_button", not not visible)
	self:reshape()
end


function def:getMaximizeControlVisibility()
	return self.header_show_max_button
end


function def:setCloseEnabled(enabled)
	self:writeSetting("allow_close", not not enabled)
	self.b_close.enabled = self.allow_close
end


function def:getCloseEnabled()
	return self.allow_close
end


function def:setMaximizeEnabled(enabled)
	self:writeSetting("allow_maximize", not not enabled)
	self.b_max.enabled = self.allow_resize and self.allow_maximize and true or false
end


function def:getMaximizeEnabled()
	return self.allow_maximize
end


function def:setAlwaysOnTop(enabled)
	self.always_on_top = not not enabled
	self.sort_id = self.always_on_top and 3 or 4
	self.parent:sortChildren()
end


function def:getAlwaysOnTop()
	return self.always_on_top
end


function def:setFrameTitle(text)
	uiShared.type1(1, text, "string", "nil")

	self:writeSetting("header_text", text)
end


function def:getFrameTitle()
	return self.header_text
end


function def:setFrameSelectable(enabled)
	if not enabled and self.context.root.selected_frame == self then
		self.context.root:setSelectedFrame(false)
	end

	self.frame_is_selectable = not not enabled
	self.can_have_thimble = self.frame_is_selectable
end


function def:getFrameSelectable()
	return self.frame_is_selectable
end


function def:setDefaultBounds()
	-- Allow the Window Frame to be moved partially out of bounds, but not
	-- so much that the mouse wouldn't be able to drag it back.

	local header_h = self.vp5_h

	-- XXX: theme/scale
	self.p_bounds_x1 = -48
	self.p_bounds_x2 = -48
	self.p_bounds_y1 = -self.h + math.max(4, math.floor(header_h/4))
	self.p_bounds_y2 = -48
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

	self.press_busy = "resize"
	self.adjust_axis_x = axis_x
	self.adjust_axis_y = axis_y

	local ax, ay = self:getAbsolutePosition()
	local mx, my = self.context.mouse_x, self.context.mouse_y

	-- Track mouse offsets for a less jarring transition to resize mode.
	self.adjust_ox = axis_x < 0 and ax - mx or axis_x > 0 and ax + self.w - mx or 0
	self.adjust_oy = axis_y < 0 and ay - my or axis_y > 0 and ay + self.h - my or 0

	--print("adjust_ox", self.adjust_ox, "adjust_oy", self.adjust_oy)
end


--[===[
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
		if self.allow_resize then
			if content.press_busy then
				return
			end

			local ax, ay = content:getAbsolutePosition()
			local mx, my = x - ax, y - ay

			-- [XXX 14] support scroll bars on left or top side of container
			if content.scr_h and content.scr_h.active and content.scr_v and content.scr_v.active
			and mx >= content.vp_x + content.vp_w and my >= content.vp_y + content.vp_h then
				self:initiateResizeMode(1, 1)
			end
		end
	end
end
--]===]


function def:uiCall_initialize(unselectable, always_on_top)
	self.visible = true
	self.allow_hover = true

	-- When false:
	-- * No widget in the frame should be capable of taking the thimble.
	--   (Otherwise, why not just make it selectable?)
	-- * The frame should never be made modal, or be part of a modal chain.
	self.frame_is_selectable = not unselectable

	self.can_have_thimble = self.frame_is_selectable
	self.always_on_top = not not always_on_top
	self.sort_id = self.always_on_top and 4 or 3

	self.auto_doc_update = true
	self.auto_layout = false
	self.halt_reshape = false

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 6)
	widShared.setupMinMaxDimensions(self)
	uiLayout.initLayoutSequence(self)

	self.frame_type = "window"

	self.hover_zone = false -- false, "button-close", "button-size"
	self.mouse_in_resize_zone = false

	-- Helps to distinguish double-clicks on the frame header.
	self.cseq_header = false

	-- Set true to draw a red box around the frame's resize area.
	--self.DEBUG_show_resize_range

	-- Link to the last widget within this tree that held thimble1.
	-- The link may become stale, so confirm the widget is still alive and within the tree before using.
	self.banked_thimble1 = self

	self.press_busy = false -- false, "drag", "resize", "button-close", "button-size"

	self.b_close = _newSensor("button-close")
	self.b_max = _newSensor("button-size")

	-- Valid while resizing. (0,0) is an error.
	self.adjust_axis_x = 0 -- -1, 0, 1
	self.adjust_axis_y = 0 -- -1, 0, 1

	-- Offsets from mouse when resizing.
	self.adjust_ox = 0
	self.adjust_oy = 0

	-- How far past the parent bounds this widget is permitted to go.
	self.p_bounds_x1 = 0
	self.p_bounds_y1 = 0
	self.p_bounds_x2 = 0
	self.p_bounds_y2 = 0

	-- Used when unmaximizing as a result of dragging.
	self.adjust_mouse_orig_a_x = 0
	self.adjust_mouse_orig_a_y = 0

	self.maximized = false
	self.maxim_x = 0
	self.maxim_y = 0
	self.maxim_w = 128
	self.maxim_h = 128

	-- Set true to allow dragging the Window Frame by clicking on its body
	--self.allow_body_drag = false

	-- Used to position frame relative to pointer when dragging.
	self.drag_ox = 0
	self.drag_oy = 0

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()

	-- Potentially shortened version of 'text' for display.
	self.header_text_disp = ""

	-- Text offsetting
	self.header_text_ox = 0
	self.header_text_oy = 0

	self.needs_update = true

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

	-- If the frame contents are scrolling, then set the scroll position after reshaping.
	-- For example, to scroll to the top-left:
	-- frame:scrollHV(0, 0)
end


function def:_trySettingThimble1()
	-- Check modal state before calling.

	local wid_banked = self.banked_thimble1

	if wid_banked and wid_banked.can_have_thimble and wid_banked:isInLineage(self) then
		wid_banked:takeThimble1()
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


function def:closeFrame(force)
	-- XXX fortify against calls during update-lock
	print("self.allow_close", self.allow_close, "force", force)
	if self.allow_close or force then
		self:remove()
		return true
	end

	return false
end


function def:frameCall_close(force)
	self:closeFrame(force)
	return true
end


function def.trickle:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self.ref_modal_next then
		self.context.current_hover = false
		return true
	end
end


local function _getCursorAxisInfo(self, mx, my)
	-- Check that (mx,my) is outside of Viewport #3 before calling.
	local diag = self.skin.sensor_resize_diagonal
	local axis_x = mx < self.vp3_x + diag and -1 or mx >= self.vp3_x + self.vp3_w - diag and 1 or 0
	local axis_y = my < self.vp3_y + diag and -1 or my >= self.vp3_y + self.vp3_h - diag and 1 or 0

	return axis_x, axis_y
end


local function _pointInSensor(sen, x, y)
	return x >= sen.x and x < sen.x + sen.w and y >= sen.y and y < sen.y + sen.h
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		commonScroll.widgetProcessHover(self, mx, my)

		if mx >= 0 and mx < self.w and my >= 0 and my < self.h then
			self.hover_zone = self.header_show_close_button and _pointInSensor(self.b_close, mx, my) and "button-close"
				or self.header_show_max_button and _pointInSensor(self.b_max, mx, my) and "button-size"
				or false
		else
			self.hover_zone = false
		end

		-- Resize sensors
		if not self.maximized
		and self.allow_resize
		and not (mx >= self.vp3_x and my >= self.vp3_y and mx < self.vp3_x + self.vp3_w and my < self.vp3_y + self.vp3_h)
		then
			local axis_x, axis_y = _getCursorAxisInfo(self, mx, my)
			if not (axis_x == 0 and axis_y == 0) then
				self.mouse_in_resize_zone = true
				self.cursor_hover = getCursorCode(axis_x, axis_y)
			end
		else
			if self.mouse_in_resize_zone then
				self.mouse_in_resize_zone = false
				self.cursor_hover = nil
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		commonScroll.widgetClearHover(self)

		self.hover_zone = false
		self.mouse_in_resize_zone = false
		self.cursor_hover = nil
	end
end


function def:uiCall_thimble1Take(inst, keep_in_view)
	--print("thimbleTake", self.id, inst.id)
	self.banked_thimble1 = inst

	if inst ~= self then -- don't try to center the Window Frame itself
		if keep_in_view == "widget_in_view" then
			local skin = self.skin
			lgcContainer.keepWidgetInView(self, inst, skin.in_view_pad_x, skin.in_view_pad_y)
			commonScroll.updateScrollBarShapes(self)
		end
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
	self:reorder(math.huge)
	self.parent:sortChildren()
end


function def.trickle:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self.ref_modal_next then
		self.context.current_pressed = false
		return true
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	-- Press events that create a pop-up menu should block propagation (return truthy)
	-- so that this and the WIMP root do not cause interference.

	local root = self:getRootWidget()

	-- Frame-modal check
	local modal_next = self.ref_modal_next
	if modal_next then
		root:setSelectedFrame(modal_next, true)
		return
	end

	if self.frame_is_selectable then
		root:setSelectedFrame(self, true)

		-- If thimble1 is not in this widget tree, move it to the Window Frame.
		local thimble1 = self.context.thimble1
		if not thimble1 or not thimble1:isInLineage(self) then
			self:_trySettingThimble1()
		end
	end

	local handled = false
	if self == inst then
		local mx, my = self:getRelativePosition(x, y)

		if button == 1 and self.context.mouse_pressed_button == button then
			-- Check for pressing on scroll bar components.
			local fixed_step = 24 -- [XXX 2] style/config
			handled = commonScroll.widgetScrollPress(self, x, y, fixed_step)

			if not handled and self.header_visible then
				if self.hover_zone == "button-close" then
					self.press_busy = self.allow_close and "button-close" or "button-disabled"
					self.cseq_header = false
					handled = true

				elseif self.hover_zone == "button-size" then
					self.press_busy = (self.allow_resize and self.allow_maximize) and "button-size" or "button-disabled"
					self.cseq_header = false
					handled = true

				elseif not widShared.pointInViewport(self, 5, mx, my) then
					self.cseq_header = false

				else
					handled = true

					-- Maximize
					if self.allow_resize
					and self.allow_maximize
					and self.cseq_header
					and self.context.cseq_button == 1
					and self.context.cseq_presses % 2 == 0
					then
						if self.wid_maximize and self.wid_unmaximize then
							if not self.maximized then
								self:wid_maximize()
							else
								self:wid_unmaximize()
							end

							self:reshape(true)
						end

					elseif self.allow_drag_move then
						-- Drag (reposition) action
						self.press_busy = "drag"

						self.drag_ox, self.drag_oy = -mx, -my

						self.adjust_mouse_orig_a_x = x
						self.adjust_mouse_orig_a_y = y

						self.drag_dc_fix_x = x
						self.drag_dc_fix_y = y
					end

					self.cseq_header = true
				end
			end
		end

		-- We did not interact with the header or scroll bars.
		if not handled then
			-- If the pointer is within Viewport #2, then have the Window Frame try to take thimble1.
			if mx >= self.vp2_x and my >= self.vp2_y and mx < self.vp2_x + self.vp2_w and self.y < self.vp2_y + self.vp2_h then
				self:tryTakeThimble1()

			-- If the mouse pointer is outside of Viewport #3, then this is a resize action.
			elseif self.allow_resize
			and not (mx >= self.vp3_x and my >= self.vp3_y and mx < self.vp3_x + self.vp3_w and my < self.vp3_y + self.vp3_h)
			then
				local axis_x, axis_y = _getCursorAxisInfo(self, mx, my)
				if not (axis_x == 0 and axis_y == 0) then
					self:initiateResizeMode(axis_x, axis_y)
				end
			end
		end
	end

	-- TODO: Figure out what to do with this stuff.
	--[=[
	-- Callback for when the user clicks on the scroll dead-patch.
	if self.wid_patchPressed and self:wid_patchPressed(x, y, button, istouch, presses) then
		-- ...

	-- Dragging can also be started by clicking on the Window Frame body if 'allow_body_drag' is true.
	elseif self.allow_body_drag then
		self.press_busy = "drag"
		self.adjust_mouse_orig_a_x = x
		self.adjust_mouse_orig_a_y = y
		--self:captureFocus()
	end
	--]=]
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config

			commonScroll.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.press_busy == "resize" then
			commonFrame.mouseMovedResize(self, self.adjust_axis_x, self.adjust_axis_y, mouse_x, mouse_y, mouse_dx, mouse_dy)

		elseif self.press_busy == "drag" then
			commonFrame.mouseMovedDrag(self, mouse_x, mouse_y, mouse_dx, mouse_dy)
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 and self.context.mouse_pressed_button == button then
			if self.press_busy == "resize" or self.press_busy == "drag" then
				-- Hack: clamp frame to parent. This isn't handled while resizing because the
				-- width and height can go haywire when resizing against the bounds of the
				-- screen (see the 'p_bounds_*' fields).
				widShared.keepInBoundsExtended(self, 2, self.p_bounds_x1, self.p_bounds_x2, self.p_bounds_y1, self.p_bounds_y2)

			elseif x >= self.x and y >= self.y and x < self.x + self.w and y < self.y + self.h then
				local mx, my = self:getRelativePosition(x, y)
				if self.press_busy == "button-close" and _pointInSensor(self.b_close, mx, my) then
					self:remove()

				elseif self.press_busy == "button-size"
				and self.allow_resize
				and _pointInSensor(self.b_max, mx, my)
				then
					if self.wid_maximize and self.wid_unmaximize then
						if not self.maximized then
							self:wid_maximize()
						else
							self:wid_unmaximize()
						end

						self:reshape(true)
					end

				elseif self.press_busy == "button-disabled" then
					self.cseq_header = false
				end
			end

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


local function _getHeaderSkinTable(self)
	local skin = self.skin
	local h_size = self.header_size
	return h_size == "small" and skin.res_small or h_size == "large" and skin.res_large or skin.res_normal
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

	if self.needs_update then
		local skin = self.skin
		local res = _getHeaderSkinTable(self)
		local font = res.header_font

		-- Refresh the text string. Shorten to the first line feed, if applicable.
		self.header_text_disp = self.header_text and string.match(self.header_text, "^([^\n]*)\n*") or ""

		-- align text
		-- [XXX 12] Centered text can be cut off by the control buttons.
		local text_w = font:getWidth(self.header_text_disp)
		local text_h = font:getHeight()

		self.header_text_ox = math.floor(0.5 + _lerp(self.vp3_x, self.vp3_x + self.vp3_w - text_w, skin.header_text_align_h))

		if self.header_button_side == "right" and self.header_text_ox + text_w >= self.vp6_w then
			self.header_text_ox = self.vp6_w - text_w

		elseif self.header_button_side == "left" and self.header_text_ox < self.vp6_x then
			self.header_text_ox = self.vp6_x
		end

		self.header_text_ox = math.max(0, self.header_text_ox)
		self.header_text_oy = math.floor(0.5 + _lerp(self.vp6_y, self.vp6_y + self.vp6_h - text_h, skin.header_text_align_v))

		self.needs_update = false
	end

	--print(self.scr_fx, self.scr_fy)
end


local function _measureButtonShortenPort(self, sensor, skin, res, right, w, h)
	local bx, by, bw, bh
	by = math.floor(0.5 + _lerp(self.vp6_y, self.vp6_y + self.vp6_h - h, res.button_align_v))
	bw = w
	bh = h

	if right then
		bx = self.vp6_x + self.vp6_w - w
	else -- left
		bx = self.vp6_x
		self.vp6_x = self.vp6_x + w + res.button_pad_w
	end
	self.vp6_w = math.max(0, self.vp6_w - w - res.button_pad_w)

	sensor.x, sensor.y, sensor.w, sensor.h = bx, by, bw, bh
end


function def:uiCall_reshape()
	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars, header bar, etc.) from the content.
	-- self.w, self.h, excluding viewport #3, is the outer frame border. This area is considered an inward extension
	-- of the invisible resize zone surrounding the frame.
	-- Viewport #3, excluding #4, is the inner frame border. This area does nothing when clicked.
	-- Viewport #4 is the area for all other elements.
	-- Viewport #5 is the header area.
	-- Viewport #6 is a subsection of the header area for rendering the frame title.

	local skin = self.skin
	local res = _getHeaderSkinTable(self)

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

	widShared.resetViewport(self, 3)
	widShared.carveViewport(self, 3, skin.box.border)
	widShared.copyViewport(self, 3, 4)
	widShared.carveViewport(self, 4, skin.box.margin)

	-- Update sensor enabled state
	self.b_close.enabled = self.allow_close
	self.b_max.enabled = self.allow_resize and self.allow_maximize and true or false

	-- Header setup
	if not self.header_visible then
		self.vp5_x, self.vp5_y, self.vp5_w, self.vp5_h = 0, 0, 0, 0
		self.vp6_x, self.vp6_y, self.vp6_w, self.vp6_h = 0, 0, 0, 0
	else
		self.vp5_h = res.header_h
		local vx, vy, vw, vh = widShared.getViewportXYWH(self, res.viewport_fit)
		self.vp5_x, self.vp5_y, self.vp5_w = vx, vy, vw

		widShared.copyViewport(self, 5, 6)

		local button_h = math.min(res.button_h, self.vp5_h)
		local right = self.header_button_side == "right"

		-- The first bit of padding for buttons
		if self.header_show_close_button or self.header_show_max_button then
			self.vp6_w = self.vp6_w - res.button_pad_w
			if not right then
				self.vp6_x = self.vp6_x + res.button_pad_w
			end
		end

		if self.header_show_close_button then
			_measureButtonShortenPort(self, self.b_close, skin, res, right, res.button_w, button_h)
		end

		if self.header_show_max_button then
			_measureButtonShortenPort(self, self.b_max, skin, res, right, res.button_w, button_h)
		end
	end

	self.needs_update = true

	-- The rest
	widShared.copyViewport(self, 4, 1)
	self.vp_y = self.vp_y + self.vp5_h
	self.vp_h = self.vp_h - self.vp5_h

	widShared.carveViewport(self, 1, skin.box.border2)

	commonScroll.arrangeScrollBars(self)

	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 2, skin.box.margin2)

	widShared.setClipScissorToViewport(self, 2)
	widShared.setClipHoverToViewport(self, 2)

	if self.auto_layout then
		uiLayout.resetLayoutPort(self, 1)
		uiLayout.applyLayout(self)
	end

	uiLayout.resetLayoutPortFull(self, 4)
	uiLayout.discardTop(self, self.vp5_y - self.vp4_y + self.vp5_h)

	if self.auto_doc_update then
		self.doc_w, self.doc_h = widShared.getCombinedChildrenDimensions(self)
	end

	self:scrollClampViewport()
	commonScroll.updateScrollBarShapes(self)
	commonScroll.updateScrollState(self)

	-- Needs to happen after shaping the header bar, as the header height factors into the default bounds.
	self:setDefaultBounds()

	-- Hacky way of not interfering with the user resizing the frame. Call keepInBounds* before exiting the resize mode.
	if self.press_busy ~= "resize" then
		widShared.keepInBoundsExtended(self, 2, self.p_bounds_x1, self.p_bounds_x2, self.p_bounds_y1, self.p_bounds_y2)
	end

	return self.halt_reshape
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Clean up any existing frame-modal connection. Note that this function will raise an error if another frame
		-- is still blocking this frame.
		if self.ref_modal_prev then
			local target = self:clearModal()

			-- Clean up the target's focus a bit.
			--[[
			local root = self:getRootWidget()
			root:setSelectedFrame(target, true)

			target:reorder(math.huge)
			target.parent:sortChildren()

			target:_trySettingThimble1()
			--]]
		end

		-- Clean up root-level modal level, if applicable.
		local root = self:getRootWidget()
		if self == root.modals[#root.modals] then
			root:sendEvent("rootCall_clearModalFrame", self)
		end
	end
end


local function _getHeaderSensorResource(self, btn, res)
	return not btn.enabled and res.res_btn_disabled
		or self.press_busy == btn.id and res.res_btn_pressed
		or self.hover_zone == btn.id and res.res_btn_hover
		or res.res_btn_idle
end


def.default_skinner = {
	schema = {
		main = {
			header_text_align_h = "unit-interval",
			header_text_align_v = "unit-interval",
			in_view_pad_x = "scaled-int",
			in_view_pad_y = "scaled-int",
			sensor_resize_pad = "scaled-int",
			shadow_extrude = "scaled-int",
			res_normal = "&res",
			res_small = "&res",
			res_large = "&res"
		},
		res = {
			header_h = "scaled-int",
			button_pad_w = "scaled-int",
			button_w = "scaled-int",
			button_h = "scaled-int",
			button_align_v = "unit-interval",
		}
	},


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	render = function(self, ox, oy)
		local skin = self.skin

		-- Window shadow
		if self.frame_render_shadow then
			love.graphics.setColor(skin.color_shadow)
			uiGraphics.drawSlice(skin.slc_shadow,
				-skin.shadow_extrude,
				-skin.shadow_extrude,
				self.w + skin.shadow_extrude * 2,
				self.h + skin.shadow_extrude * 2
			)
		end

		-- Window body
		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(skin.slc_body, 0, 0, self.w, self.h)

		-- Window header
		if self.header_visible then
			local res = _getHeaderSkinTable(self)
			local res2 = self.parent.selected_frame == self and res.res_selected or res.res_unselected
			local slc_header_body = res.header_slc_body
			love.graphics.setColor(res2.col_header_fill)
			uiGraphics.drawSlice(slc_header_body, self.vp5_x, self.vp5_y, self.vp5_w, self.vp5_h)

			if self.header_text then
				local font = res.header_font

				love.graphics.setColor(res2.col_header_text)
				love.graphics.setFont(font)

				local sx, sy, sw, sh = love.graphics.getScissor()
				uiGraphics.intersectScissor(ox + self.x + self.vp6_x, oy + self.y + self.vp6_y, self.vp6_w, self.vp6_h)

				love.graphics.print(self.header_text_disp, self.header_text_ox, self.header_text_oy)

				love.graphics.setScissor(sx, sy, sw, sh)
			end

			-- Header buttons
			local sx, sy, sw, sh = love.graphics.getScissor()
			love.graphics.setScissor(ox + self.x + self.vp5_x, oy + self.y + self.vp5_y, self.vp5_w, self.vp5_h)

			if self.header_show_close_button then
				local b_close = self.b_close
				local res_b = _getHeaderSensorResource(self, b_close, res)

				love.graphics.setColor(res_b.color_body)
				uiGraphics.drawSlice(res_b.slice, b_close.x, b_close.y, b_close.w, b_close.h)
				love.graphics.setColor(res_b.color_quad)

				local graphic = res.btn_close.graphic
				local _, _, qw, qh = graphic.quad:getViewport()

				local box_x = math.floor(0.5 + _lerp(b_close.x, b_close.x + b_close.w - graphic.w, skin.sensor_tex_align_h))
				local box_y = math.floor(0.5 + _lerp(b_close.y, b_close.y + b_close.h - graphic.h, skin.sensor_tex_align_v))

				uiGraphics.quadXYWH(
					res.btn_close.graphic,
					box_x + res_b.label_ox,
					box_y + res_b.label_oy,
					qw, qh)
			end

			if self.header_show_max_button then
				local b_max = self.b_max
				local btn_size = res.btn_size
				local res_b = _getHeaderSensorResource(self, b_max, res)

				love.graphics.setColor(res_b.color_body)
				uiGraphics.drawSlice(res_b.slice, b_max.x, b_max.y, b_max.w, b_max.h)
				love.graphics.setColor(res_b.color_quad)

				local graphic = self.maximized and btn_size.graphic_unmax or btn_size.graphic_max

				local _, _, qw, qh = graphic.quad:getViewport()

				local box_x = math.floor(0.5 + _lerp(b_max.x, b_max.x + b_max.w - graphic.w, skin.sensor_tex_align_h))
				local box_y = math.floor(0.5 + _lerp(b_max.y, b_max.y + b_max.h - graphic.h, skin.sensor_tex_align_v))

				uiGraphics.quadXYWH(
					graphic,
					box_x + res_b.label_ox,
					box_y + res_b.label_oy,
					qw, qh)
			end

			love.graphics.setScissor(sx, sy, sw, sh)
		end

		if self.DEBUG_show_resize_range then
			local rp = skin.sensor_resize_pad
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

	renderLast = function(self, ox, oy)
		commonScroll.drawScrollBarsHV(self, self.skin.data_scroll)
	end,

	-- Don't highlight when holding the UI thimble.
	renderThimble = widShared.dummy
}


return def
