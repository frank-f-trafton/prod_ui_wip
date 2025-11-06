local context = select(1, ...)


local hndStep = context:getLua("shared/hnd_step")
local notifMgr = require(context.conf.prod_ui_req .. "lib.notif_mgr")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiKeyboard = require(context.conf.prod_ui_req .. "ui_keyboard")
local wcKeyHook = context:getLua("shared/wc/wc_key_hook")
local wcUIFrame = context:getLua("shared/wc/wc_ui_frame")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {}


def.trickle = {}


widLayout.setupContainerDef(def)


local function _printUIFrames(self)
	print("_printUIFrames()")
	local selected = self.selected_frame
	for i, child in ipairs(self.children) do
		if child.frame_type then
			local frame_title = child.frame_type == "window" and (child:getFrameTitle() or "") or "(Workspace)"
			frame_title = frame_title == "" and "(Untitled)" or frame_title
			print(i, child.order_id,
				frame_title
				.. (selected and selected == child and "(S)" or "") .. "; "
				.. (child.tag ~= "" and child.tag or "(Untagged)")
				.. "; " .. tostring(child)
				.. (child._dead and " (Dead)" or "")
			)
		else
			print(i, "(not a UI Frame)")
		end
	end
	print("-----------")
end


function def:uiCall_initialize()
	self.allow_hover = true
	self.thimble_mode = 0
	self.allow_focus_capture = false
	self.visible = true
	self.clip_hover = true

	self.sort_max = 7

	widShared.setupViewports(self, 1)

	widLayout.setupLayoutList(self)

	self.halt_reshape = false

	-- Up to one workspace can be active at a time.
	self.workspace = false

	-- One 2nd-gen frame (window frames, workspace frames) can be selected at a time.
	self.selected_frame = false

	-- Reference to the base of a pop-up menu, if active.
	self.pop_up_menu = false

	-- Stack of modal 2nd-gen Window Frames. When populated, the top modal should get exclusive access, blocking
	-- the active Workspace and all other Window Frames. The user should still be able to interact with ephemeral
	-- widgets, such as pop-ups.
	-- Workspaces should never be part of the modal stack.
	self.modals = {}

	-- Helps with ctrl+tabbing through 2nd-gen frames.
	self.frame_order_counter = 0

	-- Don't let inter-generational thimble stepping leave the 2nd-gen UI Frames.
	self.block_step_intergen = true

	-- ToolTip state.
	self.tool_tip = notifMgr.newToolTip(self.context.resources.fonts.p) -- XXX font ref needs to be refresh-able

	self.tool_tip_hover = false
	self.tool_tip_time = 0.0
	self.tool_tip_time_max = 0.2

	-- Drag-and-drop state.
	-- NOTE: this is unrelated to love.filedropped() and love.directorydropped().
	-- false/nil: Not active.
	-- table: a DropState object.
	self.drop_state = false

	wcKeyHook.setupInstance(self)
end


function def:uiCall_reshapePre()
	--print("root_wimp: uiCall_reshapePre")

	widLayout.resetLayoutSpace(self)

	return self.halt_reshape
end


function def:uiCall_reshapePost()
	--print("root_wimp: uiCall_reshapePost")

	-- Viewport #1 is the area for Workspaces and maximized Window Frames.

	self.vp:set(self.LO_x, self.LO_y, self.LO_w, self.LO_h)

	-- Handle the current active Workspace.
	local workspace = self.workspace
	if workspace then
		workspace:reshape()
	end
end


--- Clears the current pop-up menu and runs a cleanup callback on the reference widget (wid_ref). Check that
--	'self.pop_up_menu' is valid before calling.
-- @param self The root widget.
-- @param reason_code A string to pass to the wid_ref indicating the context for clearing the menu.
local function clearPopUp(self, reason_code)
	-- check 'if self.pop_up_menu' before calling.

	-- If mouse was pressing on any part of the pop-up menu chain from the base onward, blank out current_pressed in
	-- the context table.
	-- We exclude `wid_ref` which may be part of the chain (to the left of the base pop-up) because it is not
	-- being destroyed by this function.
	if self.context.current_pressed
	and widShared.chainHasThisWidgetRight(self.pop_up_menu, self.context.current_pressed)
	then
		self.context.current_pressed = false
	end

	local wid_ref = self.pop_up_menu.wid_ref

	-- Destroy nested pop-ups, then the base pop-up, then clear the root's reference to it.
	widShared.chainDestroyPost(self.pop_up_menu)
	self.pop_up_menu:destroy()
	self.pop_up_menu = false

	-- Some widgets need to perform additional cleanup when the menu disappears.
	if wid_ref.wid_popUpCleanup then
		wid_ref:wid_popUpCleanup(reason_code)
	end
end


function def.trickle:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	-- Destroy pop-up menu when clicking outside of its lateral chain.
	local cur_pres = self.context.current_pressed
	local pop_up = self.pop_up_menu
	local inst_in_pop_up
	if pop_up then
		inst_in_pop_up = widShared.chainHasThisWidget(pop_up, inst)
		if not inst_in_pop_up then
			clearPopUp(self, "concluded")
		end
	end

	-- If modal state is active:
	-- 1) Block clicking on any widget that is not part of the top modal window frame
	--    or pop-ups.
	-- 2) If the top modal frame doesn't have root selection focus, then force it.
	local modal_wid = self.modals[#self.modals]
	if modal_wid then
		if modal_wid.frame_type and self.selected_frame ~= modal_wid then
			self:setSelectedFrame(modal_wid, true)
		end
		if not inst:isInLineage(modal_wid) and not inst_in_pop_up then
			self.context.current_pressed = false
			return true
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	local context = self.context

	-- User clicked on the root widget (whether directly or because other widgets aren't clickable).
	if self == inst then
		if button <= 3 then
			-- Clicking on "nothing" should release the thimbles and deselect any frames.
			context:releaseThimbles()
			self:setSelectedFrame(false)
		end
	end
end


function def:uiCall_pointerDragDestRelease(inst, x, y, button, istouch, presses)
	-- DropState cleanup
	self.drop_state = false
end


function def.trickle:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if #self.modals == 0 then
		if widShared.evaluateKeyhooks(self, self.KH_trickle_key_pressed, key, scancode, isrepeat) then
			return true
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if #self.modals == 0 then
		if widShared.evaluateKeyhooks(self, self.KH_key_pressed, key, scancode, isrepeat) then
			return true
		end
	end

	local context = self.context

	-- Run thimble logic.
	-- Block keyboard-driven thimble actions if the mouse is currently pressed.
	if not context.current_pressed then
		-- Keypress-driven step events.
		-- Only runs when thimble1 is assigned and thimble2 is not.
		local wid_cur = not context.thimble2 and context.thimble1
		local mods = context.key_mgr.mod

		-- Tab through 2nd-gen frames.
		if scancode == "tab" and mods["ctrl"] then
			if mods["shift"] then
				self:stepSelectedFrame(1)
			else
				self:stepSelectedFrame(-1)
			end

		-- Try to close the selected Window Frame.
		elseif self.selected_frame
		and self.selected_frame.frame_type == "window"
		and uiKeyboard.keyStringsEqual(context.settings.wimp.key_bindings.close_window_frame, hot_scan, hot_key)
		then
			self.selected_frame:closeFrame(false)

		else
			-- Thimble is held:
			if wid_cur then
				-- Cycle through widgets.
				if scancode == "tab" then
					local dest_cur
					if mods["shift"] then
						dest_cur = hndStep.intergenerationalPrevious(wid_cur)
					else
						dest_cur = hndStep.intergenerationalNext(wid_cur)
					end

					--print("dest_cur", dest_cur)

					if dest_cur then
						dest_cur:takeThimble1("widget_in_view")
					else
						wid_cur:releaseThimble1()
					end

				-- Thimble action #1.
				elseif scancode == "return" or scancode == "kpenter" or (scancode == "space" and not isrepeat) then
					wid_cur:cycleEvent("uiCall_thimbleAction", wid_cur, key, scancode, isrepeat)
					context.current_pressed = false

				-- Thimble action #2.
				elseif (scancode == "application" or (mods["shift"] and scancode == "f10")) and not isrepeat then
					wid_cur:cycleEvent("uiCall_thimbleAction2", wid_cur, key, scancode, isrepeat)
					context.current_pressed = false
				end
			end
		end
	end

	return true
end


function def:uiCall_keyReleased(inst, key, scancode)
	if #self.modals == 0 then
		if widShared.evaluateKeyhooks(self, self.KH_key_released, key, scancode) then
			return true
		end
	end
end


function def.trickle:uiCall_keyReleased(inst, key, scancode)
	if #self.modals == 0 then
		if widShared.evaluateKeyhooks(self, self.KH_trickle_key_released, key, scancode) then
			return true
		end
	end
end


function def:uiCall_windowResize(w, h)
	-- XXX consider rate-limiting this (either here or in the core) to about 1/10th of a second.
	-- It fires over and over on Fedora, but pauses the main thread on Windows. Apparently, Wayland
	-- can fire it multiple times per frame.

	self.w, self.h = w, h

	-- Reshape self and descendants
	self:reshape()
end


function def:rootCall_getFrameOrderID()
	self.frame_order_counter = self.frame_order_counter + 1
	return self.frame_order_counter
end


function def:setActiveWorkspace(inst)
	if inst and inst.frame_type ~= "workspace" then
		error("argument #1: expected a Workspace widget or false.")
	end

	self.workspace = inst or false
	if inst then
		inst.sort_id = 2
	end

	inst:reshape()

	for i, wid_g2 in ipairs(self.children) do
		if wid_g2 ~= inst then
			local frame_type = wid_g2.frame_type
			if frame_type == "workspace" then
				wid_g2.sort_id = 1

			elseif frame_type == "window" then
				wid_g2:_refreshWorkspaceState()
			end
		end
	end

	self:sortG2()
end


function def:sortG2()
	self:sortChildren()

	-- G2 Widgets with a sort_id of 1 are asleep.
	local start_index
	for i, child in ipairs(self.children) do
		child.awake = child.sort_id > 1
		if child.sort_id > 1 and not start_index then
			start_index = i
		end
	end

	self.draw_first = start_index or 1
end



--- Select a UI Frame to have root focus.
-- @param set_new_order When true, assign a new top order_id to the UI Frame. This may be desired when clicking on a
--	UI Frame, and not when cycling through them with ctrl+tab or ctrl+shift+tab.
function def:setSelectedFrame(inst, set_new_order)
	if inst then
		if inst.parent ~= self then
			error("can only select among children of the root widget.")

		elseif not inst.frame_is_selectable then
			error("cannot select this G2 widget.")

		elseif inst.frame_type == "window" and inst.workspace and inst.workspace ~= self.context.root.workspace then
			error("cannot select a Window Frame whose Workspace is inactive.")

		elseif inst.frame_hidden then
			error("cannot select a UI Frame that is hidden.")

		elseif not inst.awake then
			error("cannot select a widget that is asleep.")
		end
	end

	local old_selected = self.selected_frame
	self.selected_frame = inst or false

	if inst then
		if inst.frame_type == "window" then
			inst:bringWindowToFront()
		else -- frame_type == "workspace"
			self:sortG2()
		end

		if old_selected ~= inst then
			wcUIFrame.tryUnbankingThimble1(inst)

			if set_new_order then
				inst.order_id = self:rootCall_getFrameOrderID()
			end
		end
	end
end


-- Select the topmost active Window Frame, or the active Workspace, or nothing. Hidden Window Frames are excluded.
-- @param exclude Optionally provide one frame to exclude from the search. Use this when the current selected
--	UI Frame is in the process of being destroyed. (Modal/frame-blocking state should have been cleaned up before this
--	point.)
function def:selectTopFrame(exclude)
	--print("selectTopFrame: start")
	if #self.modals > 0 then
		--print("modals > 0")
		self:setSelectedFrame(self.modals[#self.modals], false)
		return
	end

	for i = #self.children, 1, -1 do
		--print("child #", i)
		local child = self.children[i]

		--print("frame_type", child.frame_type, "ref_block_next", child.ref_block_next, "~= exclude", child ~= exclude)
		if child.frame_type == "window"
		and child.frame_is_selectable
		and not child.frame_hidden
		and (not child.workspace or child.workspace == self.workspace)
		and not child.ref_block_next
		and child ~= exclude
		then
			--print("selected window: ", i, child, child.id, child.frame_is_selectable)
			self:setSelectedFrame(child, false)
			return
		end
	end

	if self.workspace and self.workspace.frame_is_selectable and not self.workspace.frame_hidden then
		--print("the active workspace was selected")
		self:setSelectedFrame(self.workspace)
		return
	end

	--print("no child was selected")
	self:setSelectedFrame(false)
end


local function _isActiveFrame(root, wid)
	return wid.frame_type == "window" and (not wid.workspace or wid.workspace == root.workspace)
		or wid.frame_type == "workspace" and root.workspace == wid
end


local function frameSearch(self, dir, v1, v2)
	local candidate = false

	for i, wid_g2 in ipairs(self.children) do
		if wid_g2.frame_type
		and wid_g2.frame_is_selectable
		and not wid_g2.frame_hidden
		and not wid_g2.ref_block_next
		and _isActiveFrame(self, wid_g2)
		and wid_g2.order_id > v1 and wid_g2.order_id < v2
		then
			if dir == 1 then
				v2 = wid_g2.order_id
				candidate = wid_g2
			else
				v1 = wid_g2.order_id
				candidate = wid_g2
			end
		end
	end

	return candidate
end


-- @param dir 1 or -1.
-- @return true if the step was successful, false if no step happened.
function def:stepSelectedFrame(dir)
	if dir ~= 1 and dir ~= -1 then
		error("argument #1: invalid direction.")
	end

	-- Don't step frames when any modal frame is active.
	if #self.modals > 0 then
		return false
	end

	--[[
	We need to keep the step-through order of frames separate from their position in the root's list of children.

	Traveling left-to-right: find the next-biggest order ID. If this is the biggest, search again for the smallest
	ID. Right-to-left is the opposite. Ignore widgets that are not frames, and frames which are being blocked by
	another frame.
	--]]

	local current = self.selected_frame
	local v1, v2 = 0, math.huge
	if current then
		if dir == 1 then
			v1 = current.order_id
		else
			v2 = current.order_id
		end
	end

	local candidate = frameSearch(self, dir, v1, v2)

	-- Success
	if candidate then
		self:setSelectedFrame(candidate, false)
		return true

	-- We are at the first or last selectable frame.
	-- Try one more time, from the first or last point.
	else
		v1, v2 = 0, math.huge
		candidate = frameSearch(self, dir, v1, v2)

		if candidate and candidate ~= current then
			self:setSelectedFrame(candidate, false)
			return true
		end
	end

	return false
end


--- Doctor the context 'current_pressed' field. Intended for use with pop-up menus in some special cases.
-- @param inst The invoking widget.
-- @param new_pressed The widget that will be assigned to 'current_pressed' if it meets the criteria.
-- @param press_busy_code If truthy, and we go through with the change, assign this value to 'new_pressed.press_busy'.
function def:rootCall_doctorCurrentPressed(inst, new_pressed, press_busy_code)
	--print("rootCall_doctorCurrentPressed", inst, new_pressed, press_busy_code, debug.traceback())

	-- If this was the result of a click action, doctor the current-pressed state
	-- to reference the menu, not the clicked widget.
	if self.context.current_pressed and new_pressed.allow_hover then
		--self.context.current_hover = new_pressed
		self.context.current_pressed = new_pressed

		if press_busy_code then
			new_pressed.press_busy = press_busy_code
		end
		return true
	end
end


--- Set a widget as the current pop-up, destroying any existing pop-up chain first.
-- @param inst The event invoker.
-- @param pop_up The widget to assign as a pop-up.
-- @return A reference to the new pop-up widget.
function def:rootCall_assignPopUp(inst, pop_up)
	--print("rootCall_assignPopUp", inst, pop_up, debug.traceback())

	-- Caller should create and initialize the widget before attaching it to the root here.

	-- Destroy any existing pop-up menu tree.
	if self.pop_up_menu then
		clearPopUp(self, "concluded")
	end

	-- If invoking widget is part of a selectable Window Frame, then bring it to the front.
	local frame = inst:findAscendingKeyValue("frame_type", "window")
	if frame and frame.frame_is_selectable then
		self:setSelectedFrame(frame, true)
	end

	self.pop_up_menu = pop_up

	-- If the calling function is a uiCall_pointerPress event, it should return true to block further propagation
	-- up. Otherwise, the window-frame and root pointerPress code may interfere with thimble and banking state.
end


function def:rootCall_destroyPopUp(inst, reason_code)
	--print("rootCall_destroyPopUp", inst, self.pop_up_menu, reason_code, debug.traceback())

	if self.pop_up_menu then
		clearPopUp(self, reason_code)
	end
end


function def:rootCall_setModalFrame(inst)
	uiAssert.type(1, inst, "table")

	if inst.frame_type ~= "window" then
		error("only Window Frames can be assigned as modal.")

	elseif inst.workspace then
		error("Window Frames that are associated with a Workspace cannot be assigned as modal.")
	end

	for i, child in ipairs(self.modals) do
		if child == inst then
			error("this frame is already in the stack of modals.")
		end
	end

	self.modals[#self.modals + 1] = inst
	self.context.mouse_start = inst
end


function def:rootCall_clearModalFrame(inst)
	uiAssert.type(1, inst, "table")

	if self.modals[#self.modals] ~= inst then
		error("tried to clear the modal status of a frame that is not at the top of the 'modals' stack.")
	end

	self.modals[#self.modals] = nil
	self.context.mouse_start = self.modals[#self.modals] or false
end


function def:rootCall_setDragAndDropState(inst, drop_state)
	uiAssert.type(1, inst, "table")
	uiAssert.type(2, drop_state, "table")

	self.drop_state = drop_state
end


local function resetToolTipState(self)
	self.tool_tip_hover = false
	self.tool_tip_time = 0.0
	self.tool_tip.visible = false
	self.tool_tip.alpha = 0.0
end


--[[
Use this instead of root:addChild("wimp/window_frame").
--]]
function def:newWindowFrame(skin_id, unselectable, view_level)
	view_level = view_level or "normal"

	local lane = wcUIFrame.view_levels[view_level]
	local pos = widShared.getSortLaneEdge(self.children, lane, "last")
	local w_frame = self:addChild("wimp/window_frame", skin_id, pos, unselectable, view_level)
	return w_frame
end


function def:newWorkspace()
	local w_space = self:addChild("wimp/workspace")

	self:sortG2()

	return w_space
end


local function _thimbleCheck(self, inst)
	local wid = inst
	while wid do
		if not wid.awake then
			error("instance is not within an awake part of the widget hierarchy.")
		end
		wid = wid.parent
	end
end


def.trickle.uiCall_thimble1Take = _thimbleCheck
def.trickle.uiCall_thimble2Take = _thimbleCheck


function def:uiCall_update(dt)
	local tool_tip = self.tool_tip
	local current_hover = self.context.current_hover

	-- Don't show tool-tips when:
	-- * Any pop-up menu is open
	-- * Mouse cursor is not hovering over anything
	-- * Current hover is not the same as the last-good hover
	-- * Any mouse button is held
	if self.pop_up_menu
	or not current_hover
	or current_hover ~= self.tool_tip_hover
	or self.context.mouse_pressed_button then
		resetToolTipState(self)
	end

	if current_hover then
		self.tool_tip_hover = current_hover
	end

	if not tool_tip.visible then
		local tip_hover = self.tool_tip_hover
		if tip_hover and tip_hover.str_tool_tip then
			self.tool_tip_time = self.tool_tip_time + dt
		end
		if self.tool_tip_time >= self.tool_tip_time_max then
			tool_tip:arrange(tip_hover.str_tool_tip, 0, 0)
			tool_tip.visible = true
		end
	else
		tool_tip.alpha = math.min(1, tool_tip.alpha + dt * tool_tip.alpha_dt_mul)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 1)
	-- Bubbled events from children
	else
		-- If the current selected window frame is being destroyed, then automatically select the next top frame.
		if inst.frame_type == "window" and self.selected_frame == inst then
			--_printUIFrames(self)
			self:selectTopFrame(inst)
		end
	end
end


function def:renderLast(os_x, os_y)
	if self.tool_tip.visible then
		local mx, my = self.context.mouse_x, self.context.mouse_y
		local xx, yy, ww, hh = self.x, self.y, self.w, self.h
		local tool_tip = self.tool_tip
		local tw, th = tool_tip.w, tool_tip.h
		local x = math.max(xx, math.min(mx + 16, ww - tw))
		local y = math.max(yy, math.min(my + 16, hh - th))
		self.tool_tip:draw(x, y)
	end

	if self.drop_state then
		local rr, gg, bb, aa = love.graphics.getColor()
		love.graphics.setColor(self.context.resources.info.misc.dropping_text_color)
		love.graphics.print("Dropping...", self.context.mouse_x - 20, self.context.mouse_y - 20)
		love.graphics.setColor(rr, gg, bb, aa)
	end

	-- DEBUG
	--[[
	love.graphics.setFont(self.context.resources.fonts.p)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("selected_frame: " .. tostring(self.selected_frame), 64, 64)
	--]]

	-- DEBUG: Draw click-sequence intersect.
	--[[
	local context = self.context
	if context.cseq_widget then
		love.graphics.setLineStyle("rough")
		love.graphics.setLineJoin("miter")
		love.graphics.setLineWidth(1)

		love.graphics.setColor(1, 0, 0, 1)
		local x, y, r = context.cseq_x, context.cseq_y, context.cseq_range
		love.graphics.rectangle("line", x - r, y - r, r * 2 - 1, r * 2 - 1)

		love.graphics.setColor(0, 1, 0, 1)
		local wid = context.cseq_widget
		local wx, wy = wid:getAbsolutePosition()
		love.graphics.rectangle("line", wx, wy, wid.w - 1, wid.h - 1)
	end
	--]]

	-- DEBUG: Draw mouse-press range (for drag-and-drop)
	--[[
	if context.mouse_pressed_button then
		love.graphics.setLineStyle("rough")
		love.graphics.setLineJoin("miter")
		love.graphics.setLineWidth(1)

		love.graphics.setColor(0, 0, 1, 1)
		local mpx, mpy, mpr = context.mouse_pressed_x, context.mouse_pressed_y, context.mouse_pressed_range
		love.graphics.rectangle("line", mpx - mpr, mpy - mpr, mpr * 2 - 1, mpr * 2 - 1)
	end
	--]]
end


return def
