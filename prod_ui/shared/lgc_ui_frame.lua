-- To load: local lib = context:getLua("shared/lib")

--[[
Shared UI Frame logic.
--]]


local context = select(1, ...)


local lgcUIFrame = {}


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local lgcContainer = context:getLua("shared/lgc_container")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


-- View levels for Window Frames. Both Window Frames and the WIMP Root need access to this.
lgcUIFrame.view_levels = {low=3, normal=4, high=5}


function lgcUIFrame.tryUnbankingThimble1(self)
	-- Check modal state before calling.

	local wid_banked = self.banked_thimble1

	if wid_banked and wid_banked.can_have_thimble and wid_banked:isInLineage(self) then
		wid_banked:takeThimble1()
	end
end


function lgcUIFrame.setFrameSelectable(self, enabled)
	if not enabled and self.context.root.selected_frame == self then
		self.context.root:setSelectedFrame(false)
	end

	self.frame_is_selectable = not not enabled
	self.can_have_thimble = self.frame_is_selectable
end


function lgcUIFrame.getFrameSelectable(self)
	return self.frame_is_selectable
end


-- @param keep_in_view When true, viewport scrolls to ensure the widget is visible within the viewport.
function lgcUIFrame.logic_thimble1Take(self, inst, keep_in_view)
	--print("thimbleTake", self.id, inst.id)
	self.banked_thimble1 = inst

	if inst ~= self then -- don't try to center the UI Frame itself
		if keep_in_view == "widget_in_view" then
			local skin = self.skin
			lgcContainer.keepWidgetInView(self, inst, skin.in_view_pad_x, skin.in_view_pad_y)
			commonScroll.updateScrollBarShapes(self)
		end
	end
end


function lgcUIFrame.logic_keyPressed(self, inst, key, scancode, isrepeat)
	-- Frame-modal check
	if self.ref_modal_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_key_pressed, key, scancode, isrepeat) then
		return true
	end
end


function lgcUIFrame.logic_trickleKeyPressed(self, inst, key, scancode, isrepeat)
	if widShared.evaluateKeyhooks(self, self.hooks_trickle_key_pressed, key, scancode, isrepeat) then
		return true
	end
end


function lgcUIFrame.logic_keyReleased(self, inst, key, scancode)
	-- Frame-modal check
	if self.ref_modal_next then
		return
	end

	if widShared.evaluateKeyhooks(self, self.hooks_key_released, key, scancode) then
		return true
	end
end


function lgcUIFrame.logic_trickleKeyReleased(self, inst, key, scancode)
	if widShared.evaluateKeyhooks(self, self.hooks_key_released, key, scancode) then
		return true
	end
end


function lgcUIFrame.logic_textInput(self, inst, text)
	-- Frame-modal check
	if self.ref_modal_next then
		return
	end
end


function lgcUIFrame.logic_tricklePointerPress(self, inst, x, y, button, istouch, presses)
	if self.ref_modal_next then
		self.context.current_pressed = false
		return true
	end
end


function lgcUIFrame.partial_pointerPress(self)
	-- Press events that create a pop-up menu should block propagation (return truthy)
	-- so that this and the WIMP root do not cause interference.

	local root = self:getRootWidget()

	-- Frame-modal check
	local modal_next = self.ref_modal_next
	if modal_next then
		root:setSelectedFrame(modal_next, true)
		return true
	end

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

			commonScroll.widgetScrollPressRepeat(self, x, y, fixed_step)
		end
	end
end


function lgcUIFrame.logic_pointerWheel(self, inst, x, y)
	-- Catch wheel events from descendants that did not block it.
	local caught = widShared.checkScrollWheelScroll(self, x, y)
	commonScroll.updateScrollBarShapes(self)

	-- Stop bubbling if the view scrolled.
	return caught
end


function lgcUIFrame.definitionSetup(def)
	def.setFrameSelectable = lgcUIFrame.setFrameSelectable
	def.getFrameSelectable = lgcUIFrame.getFrameSelectable
end


function lgcUIFrame.instanceSetup(self, unselectable)
	-- When false:
	-- * No widget in the frame should be capable of taking the thimble.
	--   (Otherwise, why not just make it selectable?)
	-- * The frame should never be made modal, or be part of a modal chain.
	self.frame_is_selectable = not unselectable

	self.can_have_thimble = self.frame_is_selectable

	-- Link to the last widget within this tree that held thimble1.
	-- The link may become stale, so confirm the widget is still alive and within the tree before using.
	self.banked_thimble1 = self

	-- Helps with ctrl+tabbing through UI Frames.
	self.order_id = self.context.root:rootCall_getFrameOrderID()
end


return lgcUIFrame