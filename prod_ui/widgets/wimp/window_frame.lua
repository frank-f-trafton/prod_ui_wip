local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local lgcContainer = context:getLua("shared/lgc_container")
local lgcKeyHooks = context:getLua("shared/lgc_key_hooks")
local lgcUIFrame = context:getLua("shared/lgc_ui_frame")
local lgcWindowFrame = context:getLua("shared/lgc_window_frame")
local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local _lerp = pMath.lerp


local _enum_header_sizes = uiShared.makeLUTV("small", "normal", "large")


local def = {
	skin_id = "window_frame1",
	trickle = {},

	default_settings = {
		allow_close = true,
		allow_drag_move = true,
		allow_maximize = true, -- depends on 'allow_resize' being true
		allow_resize = true,
		header_visible = true,
		header_button_side = "right", -- "left", "right"
		header_show_close_button = true,
		header_show_max_button = true,
		header_text = "",
		header_size = "normal" -- _enum_header_sizes
	}
}


def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


widShared.scrollSetMethods(def)
lgcUIFrame.definitionSetup(def)
lgcContainer.setupMethods(def)


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
	local old_visible = not not self.header_visible
	enabled = not not enabled
	self:writeSetting("header_visible", enabled)
	if old_visible ~= self.header_visible then
		local sx, sy = self:scrollGetXY()
		self:reshape()
		self:scrollHV(sx, sy, true)
	end
end


function def:getHeaderVisible()
	return self.header_visible
end


function def:setHeaderSize(size)
	size = size and size
	uiShared.enumEval(1, size, "HeaderSize", _enum_header_sizes)

	if self.header_size ~= size then
		local sx, sy = self:scrollGetXY()
		--local vp_y_old = self.vp_y
		self:writeSetting("header_size", size)
		self:reshape()
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


function def:setWindowViewLevel(view_level)
	if not lgcUIFrame.view_levels[view_level] then
		error("invalid view level.")
	end

	self.view_level = view_level
	self.sort_id = lgcUIFrame.view_levels[view_level]
	self.context.root:sortG2()
end


function def:getWindowViewLevel()
	return self.view_level
end


function def:setFrameTitle(text)
	uiShared.type1(1, text, "string", "nil")

	self:writeSetting("header_text", text)
end


function def:getFrameTitle()
	return self.header_text
end


function def:bringWindowToFront()
	self:reorder(math.huge)
	self.context.root:sortG2()
end


function def:_refreshWorkspaceState()
	-- Become active
	if not self.workspace or self.workspace == self.context.root.workspace then
		local assign = not self.frame_hidden
		self.visible = assign
		self.allow_hover = assign
		self.sort_id = lgcUIFrame.view_levels[self.view_level]
	-- Become inactive
	else
		self.visible = false
		self.allow_hover = false
		self.sort_id = 1
	end
end


function def:setFrameWorkspace(workspace)
	workspace = workspace or false

	if workspace and workspace.frame_type ~= "workspace" then
		error("argument #1: expected a Workspace widget.")
	end

	self.workspace = workspace

	lgcUIFrame.assertFrameBlockWorkspaces(self)

	self:_refreshWorkspaceState()
	self.context.root:sortG2()
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


function def:setFrameBlock(target)
	uiShared.type1(1, target, "table")

	if not target.frame_type or (target.frame_type ~= "window" and target.frame_type ~= "workspace") then
		error("target must be a UI Frame of type 'window' or 'workspace'.")

	-- You can chain blocked frames together, but only one frame may block another frame at a time.
	elseif target.ref_block_next then
		error("target frame already has a blocking reference set (target.ref_block_next).")

	elseif self.ref_block_prev then
		error("this frame already has a blocking reference set (self.ref_block_prev).")
	end

	self.ref_block_prev = target
	target.ref_block_next = self
end


function def:clearFrameBlock()
	-- Frame-blocking state must be popped last-to-first.
	if self.ref_block_next then
		error("this frame still has a blocking reference (self.ref_block_next).")

	elseif not self.ref_block_prev then
		error("no blocking target frame to clear (self.ref_block_prev).")
	end

	local target = self.ref_block_prev
	self.ref_block_prev = false
	target.ref_block_next = false

	return target
end


function def:closeFrame(force)
	-- XXX fortify against calls during update-lock
	--print("self.allow_close", self.allow_close, "force", force)
	if self.allow_close or force then
		self:remove()
		return true
	end

	return false
end


function def:uiCall_initialize(unselectable, view_level)
	-- UI Frame
	self.frame_type = "window"
	lgcUIFrame.instanceSetup(self, unselectable)
	self.view_level = view_level or "normal"
	self.sort_id = lgcUIFrame.view_levels[self.view_level]

	-- If associated with a Workspace, a Window Frame is only active if that Workspace is also active.
	-- Window Frames associated with the root are always active.
	self.workspace = false

	self.visible = true
	self.allow_hover = true

	self.scroll_range_mode = "zero"
	self.halt_reshape = false

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 6)

	self.layout_base = "viewport"
	widLayout.initializeLayoutTree(self)

	lgcContainer.sashStateSetup(self)
	lgcKeyHooks.setupInstance(self)

	self.hover_zone = false -- false, "button-close", "button-size"
	self.mouse_in_resize_zone = false

	-- Helps with double-clicks on the frame header.
	self.cseq_header = false

	-- Set true to draw a red box around the frame's resize area.
	--self.DEBUG_show_resize_range

	self.press_busy = false -- false, "drag", "resize", "button-close", "button-size", "sash"

	self.b_close = _newSensor("button-close")
	self.b_max = _newSensor("button-size")

	-- Valid while resizing. (0,0) is an error.
	self.adjust_axis_x = 0 -- -1, 0, 1
	self.adjust_axis_y = 0 -- -1, 0, 1

	-- Offsets from mouse when resizing.
	self.adjust_ox = 0
	self.adjust_oy = 0

	-- How far past the parent bounds this Window Frame is permitted to go.
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

	-- Potentially shortened version of 'text' for display.
	self.header_text_disp = ""

	-- Text offsetting
	self.header_text_ox = 0
	self.header_text_oy = 0

	self.needs_update = true

	-- Frame-blocking widget links.
	self.ref_block_prev = false
	self.ref_block_next = false

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:frameCall_close(force)
	self:closeFrame(force)
	return true
end


def.trickle.uiCall_pointerHoverOn = lgcUIFrame.logic_tricklePointerHoverOn


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


function def.trickle:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		-- Because this widget accepts hover events outside of its boundaries (for resizing), we need to confirm
		-- that the mouse cursor actually is within the Window Frame area before checking scroll bar hover.
		if mx >= self.x and my >= self.y and mx < self.x + self.w and my < self.y + self.h then
			commonScroll.widgetProcessHover(self, mx, my)
		end

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

	if not self.mouse_in_resize_zone
	and not self.hover_zone
	and lgcContainer.sashHoverLogic(self, mouse_x, mouse_y)
	then
		return true
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


def.uiCall_thimble1Take = lgcUIFrame.logic_thimble1Take
def.trickle.uiCall_keyPressed = lgcUIFrame.logic_trickleKeyPressed
def.uiCall_keyPressed = lgcUIFrame.logic_keyPressed
def.trickle.uiCall_keyReleased = lgcUIFrame.logic_trickleKeyReleased
def.uiCall_keyReleased = lgcUIFrame.logic_keyReleased
def.trickle.uiCall_textInput = lgcUIFrame.logic_trickleTextInput
def.trickle.uiCall_pointerPress = lgcUIFrame.logic_tricklePointerPress


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if lgcUIFrame.pointerPressLogicFirst(self) then
		return
	end

	if self == inst then
		local mx, my = self:getRelativePosition(x, y)
		local handled = false

		if button == 1 and self.context.mouse_pressed_button == button then
			-- Check for pressing on scroll bar components.
			-- Since this widget can accept mouse events that are out of bounds, we must
			-- perform an additional intersection check.
			if mx >= 0 and my >= 0 and mx < self.w and my < self.h then
				local fixed_step = 24 -- [XXX 2] style/config
				handled = commonScroll.widgetScrollPress(self, x, y, fixed_step)
			end

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

							self:reshape()
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
			if mx >= self.vp2_x and my >= self.vp2_y and mx < self.vp2_x + self.vp2_w and my < self.vp2_y + self.vp2_h then
				self:tryTakeThimble1()

			-- Outside of viewport #3: treat as a resize action.
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


def.uiCall_pointerPressRepeat = lgcUIFrame.logic_pointerPressRepeat


function def.trickle:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.press_busy == "resize" then
			lgcWindowFrame.mouseMovedResize(self, self.adjust_axis_x, self.adjust_axis_y, mouse_x, mouse_y, mouse_dx, mouse_dy)

		elseif self.press_busy == "drag" then
			lgcWindowFrame.mouseMovedDrag(self, mouse_x, mouse_y, mouse_dx, mouse_dy)
		end
	end

	if lgcContainer.sashDragLogic(self, mouse_x, mouse_y) then
		return true
	end
end


function def.trickle:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
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

						self:reshape()
					end

				elseif self.press_busy == "button-disabled" then
					self.cseq_header = false
				end
			end

			commonScroll.widgetClearPress(self)
			self.press_busy = false
		end
	end

	if lgcContainer.sashUnpressLogic(self) then
		return true
	end
end


def.trickle.uiCall_pointerWheel = lgcUIFrame.logic_tricklePointerWheel
def.uiCall_pointerWheel = lgcUIFrame.logic_pointerWheel


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


function def:uiCall_reshapePre()
	print("window_frame: uiCall_reshapePre")
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

	-- Refit if maximized and parent dimensions changed.
	if self.maximized then
		self.x = parent.vp2_x
		self.y = parent.vp2_y
		if self.w ~= parent.vp2_w or self.h ~= parent.vp2_h then
			self.w = parent.vp2_w
			self.h = parent.vp2_h
		end
	end

	widShared.clampDimensions(self)

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

	-- Needs to happen after shaping the header bar, as the header height factors into the default bounds.
	self:setDefaultBounds()

	-- Hacky way of not interfering with the user resizing the frame. Call keepInBounds* before exiting the resize mode.
	if self.press_busy ~= "resize" then
		widShared.keepInBoundsExtended(self, 2, self.p_bounds_x1, self.p_bounds_x2, self.p_bounds_y1, self.p_bounds_y2)
	end

	widLayout.resetLayout(self, self.layout_base)

	widShared.updateDoc(self)

	self:scrollClampViewport()
	commonScroll.updateScrollBarShapes(self)
	commonScroll.updateScrollState(self)

	--return self.halt_reshape -- ?
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Clean up any existing frame-blocking connection. Note that this function will raise an error if another frame
		-- is still blocking this frame.
		if self.ref_block_prev then
			local target = self:clearFrameBlock()

			-- Clean up the target's focus a bit.
			--[[
			local root = self:getRootWidget()
			root:setSelectedFrame(target, true)

			target:reorder(math.huge)
			target.parent:sortChildren()

			lgcUIFrame.tryUnbankingThimble1(target)
			--]]
		end

		-- Clean up modal level, if applicable.
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


local check, change = uiTheme.check, uiTheme.change


local function _checkResSelection(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.colorTuple(res, "col_header_fill")
	check.colorTuple(res, "col_header_text")

	uiTheme.popLabel()
end


local function _checkResBtnClose(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.quad(res, "graphic")

	uiTheme.popLabel()
end


local function _checkResBtnSize(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.quad(res, "graphic")
	check.quad(res, "graphic_max")
	check.quad(res, "graphic_unmax")

	uiTheme.popLabel()
end


local function _checkResBtnState(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.slice(res, "slice")
	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_quad")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")

	uiTheme.popLabel()
end


local function _checkResTopLevel(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)

	-- Which rectangle to use for fitting the header.
	-- false: 'self.w', 'self.h'
	-- number: a corresponding viewport.
	check.integerOrExact(res, "viewport_fit", 1, nil, nil, false)

	check.box(res, "header_box")
	check.slice(res, "header_slc_body")
	check.loveType(res, "header_font", "Font")
	check.integer(res, "header_h", 0)
	check.integer(res, "button_pad_w", 0)
	check.integer(res, "button_w", 0)
	check.integer(res, "button_h", 0)

	-- From 0 (top) to 1 (bottom)
	check.unitInterval(res, "button_align_v")

	_checkResSelection(res, "res_selected")
	_checkResSelection(res, "res_unselected")

	_checkResBtnClose(res, "btn_close")
	_checkResBtnSize(res, "btn_size")

	_checkResBtnState(res, "res_btn_idle")
	_checkResBtnState(res, "res_btn_hover")
	_checkResBtnState(res, "res_btn_pressed")
	_checkResBtnState(res, "res_btn_disabled")

	uiTheme.popLabel()
end


local function _changeResBtnState(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)

	uiTheme.popLabel()
end


local function _changeResTopLevel(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "header_h", scale)
	change.integerScaled(res, "button_pad_w", scale)
	change.integerScaled(res, "button_w", scale)
	change.integerScaled(res, "button_h", scale)

	_changeResBtnState(res, "res_btn_idle", scale)
	_changeResBtnState(res, "res_btn_hover", scale)
	_changeResBtnState(res, "res_btn_pressed", scale)
	_changeResBtnState(res, "res_btn_disabled", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		-- settings
		-- TODO
		-- /settings

		check.box(skin, "box")
		check.scrollBarData(skin, "data_scroll")
		check.scrollBarStyle(skin, "scr_style")

		-- Padding when scrolling to put a widget into view.
		check.integer(skin, "in_view_pad_x", 0)
		check.integer(skin, "in_view_pad_y", 0)

		check.slice(skin, "slc_body")
		check.slice(skin, "slc_shadow")

		check.unitInterval(skin, "header_text_align_h")
		check.unitInterval(skin, "header_text_align_v")

		-- How many pixels to extend / pad resize sensors.
		check.integer(skin, "sensor_resize_pad", 0)

		-- How much to extend the diagonal parts of the resize area.
		check.integer(skin, "sensor_resize_diagonal", 0)

		-- How far to allow resizing a widget outside the bounds of its parent.
		-- Used to prevent stretching frames too far outside the LÖVE application window.
		check.integer(skin, "frame_outbound_limit", 1)

		check.integer(skin, "shadow_extrude", 0)

		-- Alignment of textures within control sensors
		-- 0.0: left, 0.5: middle, 1.0: right
		check.unitInterval(skin, "sensor_tex_align_h")

		-- 0.0: top, 0.5: middle, 1.0: bottom
		check.unitInterval(skin, "sensor_tex_align_v")

		check.colorTuple(skin, "color_body")
		check.colorTuple(skin, "color_shadow")

		check.sashState(skin)

		_checkResTopLevel(skin, "res_normal")
		_checkResTopLevel(skin, "res_small")
		_checkResTopLevel(skin, "res_large")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "in_view_pad_x", scale)
		change.integerScaled(skin, "in_view_pad_y", scale)
		change.integerScaled(skin, "sensor_resize_pad", scale)
		--change.integerScaled(skin, "shadow_extrude", scale)

		_changeResTopLevel(skin, "res_normal", scale)
		_changeResTopLevel(skin, "res_small", scale)
		_changeResTopLevel(skin, "res_large", scale)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	render = function(self, ox, oy)
		local skin = self.skin
		local root = self.context.root

		love.graphics.push("all")

		-- Window shadow
		local render_shadow = self.context.settings.wimp.window_frame.render_shadow
		if render_shadow == "all" or render_shadow == "active" and self == root.selected_frame then
			love.graphics.setColor(skin.color_shadow)
			uiGraphics.drawSlice(skin.slc_shadow,
				-skin.shadow_extrude,
				-skin.shadow_extrude,
				self.w + skin.shadow_extrude * 2,
				self.h + skin.shadow_extrude * 2
			)
		end

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		-- Window body
		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(skin.slc_body, 0, 0, self.w, self.h)

		-- Window header
		if self.header_visible then
			local res = _getHeaderSkinTable(self)
			local res2 = root.selected_frame == self and res.res_selected or res.res_unselected
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
			uiGraphics.intersectScissor(ox + self.x + self.vp5_x, oy + self.y + self.vp5_y, self.vp5_w, self.vp5_h)

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

		love.graphics.pop()

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
		love.graphics.push("all")
		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)
		commonScroll.drawScrollBarsHV(self, self.skin.data_scroll)
		love.graphics.pop()
	end,

	-- Don't highlight when holding the UI thimble.
	renderThimble = widShared.dummy
}


return def
