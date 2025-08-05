-- To load: local lib = context:getLua("shared/lib")


--[[
Shared UI Frame logic.
--]]


local context = select(1, ...)


local lgcUIFrame = {}


local lgcContainer = context:getLua("shared/lgc_container")
local lgcScroll = context:getLua("shared/lgc_scroll")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = context:getLua("core/wid_shared")


lgcUIFrame._enum_types = uiShared.makeLUTV("workspace", "window")


-- View levels for Window Frames. Both Window Frames and the WIMP Root need access to this.
lgcUIFrame.view_levels = {low=3, normal=4, high=5}


lgcUIFrame.methods = {}
local _methods = lgcUIFrame.methods


function lgcUIFrame.definitionSetup(def)
	uiShared.patchTable(def, lgcUIFrame.methods, false)
end


function _methods:setFrameSelectable(enabled)
	if not enabled and self.context.root.selected_frame == self then
		self.context.root:setSelectedFrame(false)
	end

	self.frame_is_selectable = not not enabled
	self.thimble_mode = self.frame_is_selectable and 1 or 0
end


function _methods:getFrameSelectable()
	return self.frame_is_selectable
end


function _methods:setFrameHidden(enabled)
	self.frame_hidden = not not enabled

	if self.frame_type == "workspace"
	or (self.frame_type == "window" and not self.workspace or self.workspace == self.context.root.workspace)
	then
		self.visible = not enabled
		self.allow_hover = not enabled
	else
		self.visible = false
		self.allow_hover = false
	end

	if self.frame_hidden and self.context.root.selected_frame == self then
		self.context.root:stepSelectedFrame(-1)
	end
end


function _methods:getFrameHidden()
	return self.frame_hidden
end


function lgcUIFrame.instanceSetup(self, unselectable)
	-- When false:
	-- * No widget in the frame should be capable of taking the thimble.
	--   (Otherwise, why not just make it selectable?)
	-- * The frame should never be made modal, or be part of a frame-blocking chain.
	self.frame_is_selectable = not unselectable

	self.thimble_mode = self.frame_is_selectable and 1 or 0

	-- Link to the last widget within this tree that held thimble1.
	-- The link may become stale, so confirm the widget is still alive and within the tree before using.
	self.banked_thimble1 = self

	-- "Hidden" UI Frames are invisible and cannot be interacted with.
	-- It can still tick in the background if:
	-- * It's the active Workspace
	-- * It's a Window Frame whose associated Workspace is active, or which is unassociated
	--
	-- Hidden UI Frames cannot be selected. If they are selected at the time of being hidden,
	-- the UI Frame selection will automatically step backwards by one index.
	self.frame_hidden = false

	-- Helps with ctrl+tabbing through UI Frames.
	self.order_id = self.context.root:rootCall_getFrameOrderID()
end


--[====[
function lgcUIFrame.assertModalNoWorkspace(self)
	local modals = self.context.root.modals
	for i, g2 in ipairs(modals) do
		if g2 == self then
			error("Modal Window Frames cannot be associated with any Workspace.")
		end
	end
end
--]====]


function lgcUIFrame.assertFrameBlockWorkspaces(self)
	local workspace = self.workspace
	local wid = self

	-- check back-to-front
	while wid.ref_block_next do
		wid = wid.ref_block_next
	end
	while wid do
		if wid.frame_type == "window" and workspace ~= wid.workspace then
			error("all blocking Window Frames in a sequence must share the same Workspace (or all be unassociated).")
		end

		wid = self.ref_block_prev
	end
end


function lgcUIFrame.getLastBlockingFrame(self)
	if not self.ref_block_next then
		return
	end
	local wid = self
	while wid.ref_block_next do
		wid = wid.ref_block_next
	end
	return wid
end


function lgcUIFrame.tryUnbankingThimble1(self)
	-- Check modal/frame-blocking state before calling.

	local wid_banked = self.banked_thimble1

	if wid_banked and wid_banked:isInLineage(self) then
		wid_banked:tryTakeThimble1()
	end
end


-- @param keep_in_view When true, the container scrolls to ensure that the widget is visible within the viewport.
function lgcUIFrame.logic_thimble1Take(self, inst, keep_in_view)
	--print("thimbleTake", self.id, inst.id)
	self.banked_thimble1 = inst

	if inst ~= self then -- don't try to center the UI Frame itself
		if keep_in_view == "widget_in_view" then
			local skin = self.skin
			lgcContainer.keepWidgetInView(self, inst, skin.in_view_pad_x, skin.in_view_pad_y)
			lgcScroll.updateScrollBarShapes(self)
		end
	end
end


function lgcUIFrame.logic_keyPressed(self, inst, key, scancode, isrepeat)
	if self.ref_block_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_key_pressed, key, scancode, isrepeat) then
		return true
	end
end


function lgcUIFrame.logic_trickleKeyPressed(self, inst, key, scancode, isrepeat)
	if self.ref_block_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_trickle_key_pressed, key, scancode, isrepeat) then
		return true
	end
end


function lgcUIFrame.logic_keyReleased(self, inst, key, scancode)
	if self.ref_block_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_key_released, key, scancode) then
		return true
	end
end


function lgcUIFrame.logic_trickleKeyReleased(self, inst, key, scancode)
	if self.ref_block_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_trickle_key_released, key, scancode) then
		return true
	end
end


function lgcUIFrame.logic_trickleTextInput(self, inst, text)
	if self.ref_block_next then
		return
	end
end


function lgcUIFrame.logic_tricklePointerHoverOn(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self.ref_block_next then
		self.context.current_hover = false
		return true
	end
end


function lgcUIFrame.logic_tricklePointerPress(self, inst, x, y, button, istouch, presses)
	if self.ref_block_next then
		local block_last = lgcUIFrame.getLastBlockingFrame(self)

		if block_last then
			self.context.root:setSelectedFrame(block_last, true)
		end
		self.context.current_pressed = false
		return true
	end

	if lgcContainer.sashPressLogic(self, x, y, button) then
		return true
	end
end


function lgcUIFrame.pointerPressLogicFirst(self)
	-- Press events that create a pop-up menu should block propagation (return truthy)
	-- so that this and the WIMP root do not cause interference.

	local root = self:getRootWidget()

	if self.frame_is_selectable then
		root:setSelectedFrame(self, true)

		-- If thimble1 is not in this widget tree, move it to the Window Frame.
		local thimble1 = self.context.thimble1
		if not thimble1 or not thimble1:isInLineage(self) then
			lgcUIFrame.tryUnbankingThimble1(self)
		end
	end
end


function lgcUIFrame.logic_pointerPressRepeat(self, inst, x, y, button, istouch, reps)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config

			lgcScroll.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function lgcUIFrame.logic_tricklePointerWheel(self, inst, x, y)
	if self.ref_block_next then
		return
	end
end


function lgcUIFrame.logic_pointerWheel(self, inst, x, y)
	if self.ref_block_next then
		return
	end

	-- Catch wheel events from descendants that did not block it.
	local caught = widShared.checkScrollWheelScroll(self, x, y)
	lgcScroll.updateScrollBarShapes(self)

	-- Stop bubbling if the view scrolled.
	return caught
end


return lgcUIFrame