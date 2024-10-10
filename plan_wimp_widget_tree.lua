
--[[
	A window frame with a text widget that is updated at intervals to show the current widget tree.
--]]


-- ProdUI
local dbg = require("prod_ui.debug.dbg")
--local itemOps = require("prod_ui.logic.item_ops")
--local keyCombo = require("prod_ui.lib.key_combo")
--local uiLayout = require("prod_ui.ui_layout")


local plan = {}


local function refreshWidTextDimensions(self)

	self:refreshText()

	local font = self.font

	self.w = self.margin_l + self.text_w + self.margin_r
	self.h = self.margin_t + self.text_h + self.margin_b
end


local function text_userUpdate(self, dt)

	local context = self.context
	local root = self:getTopWidgetInstance()

	if root then
		self.usr_timer = self.usr_timer - dt
		if self.usr_timer <= 0 then
			self.usr_timer = self.usr_timer_max
			self.text = dbg.widStringHierarchy(root, context.current_thimble)
			refreshWidTextDimensions(self)

			local parent = self.parent
			if parent then -- XXX assumes it's the content container for now.
				local font = self.font
				parent.doc_w = self.w
				parent.doc_h = self.h
				parent:scrollClampViewport()
			end
		end
	end
end


function plan.make(root)

	local context = root.context

	local frame_b = root:addChild("wimp/window_frame")

	frame_b.w = 400--640
	frame_b.h = 384--500

	frame_b:setFrameTitle("Widget Tree")

	local header_b = frame_b:findTag("frame_header")
	if header_b then
		header_b.condensed = true
	end

	local content_b = frame_b:findTag("frame_content")

	if content_b then

		content_b.w = 640
		content_b.h = 1200

		local text_b = content_b:addChild("base/text", {font = context.resources.fonts.p})
		text_b.margin_l = 16
		text_b.margin_r = 16
		text_b.margin_t = 16
		text_b.margin_b = 16

		text_b.text = "Initializing..."

		refreshWidTextDimensions(text_b)

		-- User code
		text_b.usr_timer_max = 0.5
		text_b.usr_timer = text_b.usr_timer_max
		text_b.userUpdate = text_userUpdate
	end

	frame_b:reshape(true)
end


return plan

