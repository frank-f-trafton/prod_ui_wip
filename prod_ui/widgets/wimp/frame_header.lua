
--[[

wimp/frame_header: Displays the window title, contains control buttons, and serves as a
dragging sensor for the window as a whole.

                     Title            Control buttons
                       v                     V
┌───────────────────────────────────────────────┐
│             The Name Of The Frame       [#][X]│
└───────────────────────────────────────────────┘

--]]


local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "wimp_frame_header",
}


local function button_wid_maximize(self)
	local frame = self:findAncestorByField("is_frame", true)

	if frame then
		if frame.wid_maximize and frame.wid_unmaximize then
			if not frame.maximized then
				frame:wid_maximize()

			else
				frame:wid_unmaximize()
			end

			frame:reshape(true)
		end
	end
end


local function button_wid_close(self)
	self:bubbleEvent("frameCall_close", self)
end


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = false
		self.allow_focus_capture = true

		--self.sort_id =

		--[[
		-- Content and frame controls are within this rectangle, while the frame border is outside.
		self.vp_x = 0
		self.vp_y = 0
		self.vp_w = 1
		self.vp_h = 1

		-- Layout rectangle
		self.lp_x = 0
		self.lp_y = 0
		self.lp_w = 1
		self.lp_h = 1
		--]]

		self:skinSetRefs()
		self:skinInstall()

		-- Layout sequence
		--uiLayout.initLayoutSequence(self)

		-- Don't highlight when holding the UI thimble.
		self.renderThimble = widShared.dummy

		-- Controls bar height, font and the size of buttons.
		self.condensed = false

		self.tag = "frame_header"

		-- Which side control buttons should be added to: "left" or "right".
		self.button_side = "right"

		-- Alignment of header text: "left", "center" or "right".
		-- [XXX 12] Centered text can be cut off by the control buttons.
		self.text_align = "center"

		self.text = "Window Title"

		-- Safe display space for frame header title (excludes control buttons), set during reshape.
		self.text_safe_x = 0
		self.text_safe_y = 0
		self.text_safe_w = self.w
		self.text_safe_h = self.h

		-- Potentially shortened version of 'text' for display.
		self.text_disp = ""

		self.needs_update = true

		-- Text offsetting
		self.text_ox = 0
		self.text_oy = 0

		-- Add a close button in the upper-right
		local button_close = self:addChild("base/button", {
			skin_id = "wimp_frame_button",
			graphic = self.context.resources.tex_quads["window_graphic_close"],
		})
		button_close.tag = "header_close"

		--button_close.alt_text = "Close window"

		button_close.wid_buttonAction = button_wid_close

		button_close.can_have_thimble = false


		-- Add a maximize/restore button next to the close button.
		local button_max = self:addChild("base/button", {
			skin_id = "wimp_frame_button",
			graphic = self.context.resources.tex_quads["window_graphic_maximize"],
			graphic_max = self.context.resources.tex_quads["window_graphic_maximize"],
			graphic_unmax = self.context.resources.tex_quads["window_graphic_unmaximize"],
		})
		button_max.tag = "header_max"

		--button_max.alt_text = "Maximize or restore window size" -- XXX tooltip

		button_max.wid_buttonAction = button_wid_maximize

		button_max.can_have_thimble = false
	end
end


function def:uiCall_reshape()
	local button_pad = 2 -- XXX style/theme integration
	local button_w = 32 - button_pad*2 -- XXX style/theme integration
	local button_h = self.h - button_pad*2

	local safe_pad = 4 -- XXX style/theme integration, maybe proportional to the font size?
	-- XXX and probably decouple the padding from the scissor box.

	local pos_x = self.w

	-- Start left-to-right, and reverse the measurements if buttons are supposed to be on the right side.

	local measure = button_pad

	local button_close = self:findTag("header_close");
	if button_close then
		button_close.w = button_w
		button_close.h = button_h
		button_close.x = measure
		button_close.y = math.floor(0.5 + (self.h/2 - button_h/2 + button_pad))

		measure = measure + button_close.w + button_pad
	end

	local button_max = self:findTag("header_max")
	if button_max then
		button_max.w = button_w
		button_max.h = button_h
		button_max.x = measure
		button_max.y = math.floor(0.5 + (self.h/2 - button_h/2 + button_pad))

		measure = measure + button_max.w + button_pad

		local frame = self:findAncestorByField("is_frame", true)
		if frame then
			button_max.graphic = frame.maximized and button_max.graphic_unmax or button_max.graphic_max
		else
			button_max.graphic = button_max.graphic_max
		end
	end

	-- The remaining space is the safe rendering zone for header title text.
	self.text_safe_x = math.max(0, measure + safe_pad)
	self.text_safe_y = 0
	self.text_safe_w = math.max(0, self.w - self.text_safe_x - safe_pad)
	self.text_safe_h = math.max(0, self.h)

	if self.button_side == "right" then
		if button_close then button_close.x = self.w - button_close.x - button_max.w end
		if button_max then button_max.x = self.w - button_max.x - button_max.w end

		self.text_safe_x = self.w - self.text_safe_x - self.text_safe_w
	end

	self.needs_update = true
end


function def:uiCall_update(dt)
	if self.needs_update then
		local skin = self.skin
		local font = self.condensed and skin.font_cond or skin.font_norm

		-- Refresh the text string. Shorten to the first line feed, if applicable.
		self.text_disp = self.text and string.match(self.text, "^([^\n]*)\n*") or ""

		-- Some very basic alignment code.
		local text_w = font:getWidth(self.text_disp)
		if self.text_align == "center" then
			self.text_ox = math.floor(0.5 + self.w*0.5 - text_w*0.5)

		elseif self.text_align == "right" then
			self.text_ox = math.floor(0.5 + math.max(self.text_safe_x, self.text_safe_x + self.text_safe_w - text_w))

		else -- "left"
			self.text_ox = self.text_safe_x
		end

		-- Center vertically in the header bar.
		self.text_oy = math.floor(self.h*0.5 - font:getHeight()*0.5)

		self.needs_update = false
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	-- Implements dragging and double-click-to-maximize/restore
	if self == inst then
		if button == 1 and self.context.mouse_pressed_button == button then
			local frame = self.parent
			if not frame or not frame.is_frame then
				error("no frame parent to drag.")
			end

			if self.context.cseq_button == 1 and self.context.cseq_presses % 2 == 0 then
				if frame.wid_maximize and frame.wid_unmaximize then
					if not frame.maximized then
						frame:wid_maximize()
					else
						frame:wid_unmaximize()
					end

					frame:reshape(true)
				end
			else
				-- Drag (reposition) action
				frame.cap_mode = "drag"

				local a_x, a_y = frame:getAbsolutePosition()
				frame.drag_ox = a_x - x
				frame.drag_oy = a_y - y

				frame.cap_mouse_orig_a_x = x
				frame.cap_mouse_orig_a_y = y

				frame.drag_dc_fix_x = x
				frame.drag_dc_fix_y = y

				frame:captureFocus()
			end
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
			local res = self.selected and skin.res_selected or skin.res_unselected

			local slc_body = skin.slc_body
			love.graphics.setColor(res.col_fill)
			uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

			if self.text then
				local font = self.condensed and skin.font_cond or skin.font_norm

				love.graphics.setColor(res.col_text)
				love.graphics.setFont(font)

				local sx, sy, sw, sh = love.graphics.getScissor()

				uiGraphics.intersectScissor(ox + self.text_safe_x, oy + self.text_safe_y, self.text_safe_w, self.text_safe_h)

				love.graphics.print(self.text_disp, self.text_ox, self.text_oy)

				love.graphics.setScissor(sx, sy, sw, sh)
			end
		end,
	},
}


return def
