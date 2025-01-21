
--[[

wimp/frame_header: Displays the window title, contains control buttons, and serves as a
dragging sensor for the window as a whole.

                                      Control buttons
                                             V
┌───────────────────────────────────────────────┐
│                 Frame Title             [#][X]│
└───────────────────────────────────────────────┘

--]]


local context = select(1, ...)


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local _lerp = commonMath.lerp


local def = {
	skin_id = "wimp_header",

	default_settings = {
		text = "Untitled Frame",
		text_align_h = 0.5, -- From 0 (left) to 1 (right)
		text_align_v = 0.5, -- From 0 (top) to 1 (bottom)

		condensed = false,

		button_side = "right", -- "left", "right"
	}
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

		widShared.setupViewports(self, 2)

		self:skinSetRefs()
		self:skinInstall()
		self:applyAllSettings()

		self.tag = "frame_header"

		-- Potentially shortened version of 'text' for display.
		self.text_disp = ""

		-- Text offsetting
		self.text_ox = 0
		self.text_oy = 0

		self.needs_update = true

		-- Close button
		local button_close = self:addChild("base/button", {
			skin_id = "wimp_frame_button",
			graphic = self.context.resources.tex_quads["window_graphic_close"],
		})
		button_close.tag = "header_close"
		button_close.wid_buttonAction = button_wid_close
		button_close.can_have_thimble = false


		-- Maximize/restore button
		local button_max = self:addChild("base/button", {
			skin_id = "wimp_frame_button",
			graphic = self.context.resources.tex_quads["window_graphic_maximize"],
			graphic_max = self.context.resources.tex_quads["window_graphic_maximize"],
			graphic_unmax = self.context.resources.tex_quads["window_graphic_unmaximize"],
		})
		button_max.tag = "header_max"
		button_max.wid_buttonAction = button_wid_maximize
		button_max.can_have_thimble = false
	end
end


local function _placeButtonShortenPort(self, button, right, w, h)
	local res = self.condensed and self.skin.res_cond or self.skin.res_norm

	button.y = self.vp2_y
	button.w = w
	button.h = h
	if right then
		button.x = self.vp2_x + self.vp2_w - w
	else -- left
		button.x = self.vp2_x
		self.vp2_x = self.vp2_x + w + res.button_pad_w
	end
	self.vp2_w = math.max(0, self.vp2_w - w - res.button_pad_w)
end


function def:uiCall_reshape()
	-- Viewport #1 is the area for text and buttons.
	-- Viewport #2 is a subset of #1, just for text.

	local skin = self.skin
	local res = self.condensed and skin.res_cond or skin.res_norm

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, res.header_box.border)
	widShared.copyViewport(self, 1, 2)

	local button_h = math.min(res.button_h, self.vp2_h)
	local right = self.button_side == "right"

	local button_close = self:findTag("header_close")
	if button_close then
		_placeButtonShortenPort(self, button_close, right, res.button_w, button_h)
	end

	local button_max = self:findTag("header_max")
	if button_max then
		_placeButtonShortenPort(self, button_max, right, res.button_w, button_h)

		local frame = self:findAncestorByField("is_frame", true)
		if frame then
			button_max.graphic = frame.maximized and button_max.graphic_unmax or button_max.graphic_max
		else
			button_max.graphic = button_max.graphic_max
		end
	end

	self.needs_update = true
end


function def:uiCall_update(dt)
	if self.needs_update then
		local skin = self.skin
		local res = self.condensed and skin.res_cond or skin.res_norm
		local font = res.header_font

		-- Refresh the text string. Shorten to the first line feed, if applicable.
		self.text_disp = self.text and string.match(self.text, "^([^\n]*)\n*") or ""

		-- align text
		-- [XXX 12] Centered text can be cut off by the control buttons.
		local text_w = font:getWidth(self.text_disp)
		local text_h = font:getHeight()

		self.text_ox = math.floor(0.5 + _lerp(self.vp_x, self.vp_x + self.vp_w - text_w, self.text_align_h))
		if self.text_ox + text_w > self.vp2_w then
			self.text_ox = self.vp2_w - text_w
		end
		self.text_ox = math.max(0, self.text_ox)

		self.text_oy = math.floor(0.5 + _lerp(self.vp2_y, self.vp2_y + self.vp2_h - text_h, self.text_align_v))

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
				local root = self:getTopWidgetInstance()
				if root:sendEvent("rootCall_doctorCurrentPressed", self, frame) then
					frame.press_busy = "drag"

					local a_x, a_y = frame:getAbsolutePosition()
					frame.drag_ox = a_x - x
					frame.drag_oy = a_y - y

					frame.adjust_mouse_orig_a_x = x
					frame.adjust_mouse_orig_a_y = y

					frame.drag_dc_fix_x = x
					frame.drag_dc_fix_y = y
				end
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
			local res = self.condensed and skin.res_cond or skin.res_norm
			local res2 = self.selected and res.res_selected or res.res_unselected

			local slc_body = res.header_slc_body
			love.graphics.setColor(res2.col_header_fill)
			uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

			if self.text then
				local font = res.header_font

				love.graphics.setColor(res2.col_header_text)
				love.graphics.setFont(font)

				local sx, sy, sw, sh = love.graphics.getScissor()
				uiGraphics.intersectScissor(ox + self.x + self.vp2_x, oy + self.y + self.vp2_y, self.vp2_w, self.vp2_h)

				love.graphics.print(self.text_disp, self.text_ox, self.text_oy)

				love.graphics.setScissor(sx, sy, sw, sh)
			end
		end,

		-- Don't highlight when holding the UI thimble.
		renderThimble = widShared.dummy
	},
}


return def
