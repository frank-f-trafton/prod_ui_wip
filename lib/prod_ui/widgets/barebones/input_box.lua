--[[
A barebones text input box. Internal use (troubleshooting skinned widgets, etc.)

* Controls:

Backspace: delete last character
Shift + Delete: delete all text
Ctrl + X: Cut text
Ctrl + C: Copy text
Ctrl + V: Paste text

* No navigation controls (back, forward) are provided.

* Multi-line text is not supported.
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


-- LÖVE Supplemental
local utf8 = require("utf8")


local def = {}


local function updateTextWidth(self)

	local font = self.context.resources.fonts.internal
	self.text_w = font:getWidth(self.text)
end


function def:setText(text)

	-- XXX: Assertions
	self.text = text
	updateTextWidth(self)
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		self.text = ""
		self.text_w = 0

		-- State flags.
		self.enabled = true
		self.hovered = false
		self.pressed = false
	end
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		if self.enabled then
			self.hovered = true
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		if self.enabled then
			self.hovered = false
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble()
				end
			end
		end
	end

	return true
end


function def:uiCall_thimbleTake(inst)

	if self == inst then
		love.keyboard.setTextInput(true)
	end
end


function def:uiCall_thimbleRelease(inst)

	if self == inst then
		love.keyboard.setTextInput(false)
	end
end


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
	-- XXX should be capable of binding the user hitting "enter" or "confirm" to a function call.
end


function def:uiCall_textInput(inst, text)

	if self == inst then
		-- Input validation: The context checks the UTF-8 encoding before calling this event.
		self.text = self.text .. text

		updateTextWidth(self)
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

	-- XXX max text limit

	local mod = self.context.key_mgr.mod

	-- Backspace
	if key == "backspace" then
		-- Taken from: https://love2d.org/wiki/love.textinput
		local byteoffset = utf8.offset(self.text, -1)
		if byteoffset then
			self.text = string.sub(self.text, 1, byteoffset - 1)
		end
		updateTextWidth(self)
		return true

	-- Delete all
	elseif key == "delete" and mod["shift"] then
		self.text = ""
		updateTextWidth(self)
		return true

	-- Cut
	elseif scancode == "x" and mod["ctrl"] then -- XXX config
		if self.text ~= "" then
			love.system.setClipboardText(self.text)
		end
		self.text = ""
		updateTextWidth(self)
		return true

	-- Copy
	elseif scancode == "c" and mod["ctrl"] then -- XXX config
		love.system.setClipboardText(self.text)
		return true

	-- Paste
	elseif scancode == "v" and mod["ctrl"] then -- XXX config
		local clipboard_text = love.system.getClipboardText()
		if clipboard_text and utf8Tools.check(clipboard_text) then
			self.text = self.text .. clipboard_text
			updateTextWidth(self)
			return true
		end
	end
end


def.render = function(self, ox, oy)

	love.graphics.push("all")

	local scale = self.context.resources.scale
	local font = self.context.resources.fonts.internal

	local line_w = math.floor(1.0 * scale)
	local caret_w = math.floor(4.0 * scale)
	local margin_w = math.floor(8.0 * scale)

	if not self.enabled then
		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)

	elseif self.pressed then
		love.graphics.setColor(0.25, 0.25, 0.25, 1.0)

	elseif self.hover then
		love.graphics.setColor(0.9, 0.9, 0.9, 1.0)

	else -- enabled
		love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
	end

	-- Body.
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(line_w)
	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)

	love.graphics.intersectScissor(
		ox + self.x,
		oy + self.y,
		math.max(0, self.w),
		math.max(0, self.h)
	)

	-- The caret is always in view.
	local offset_x = -math.max(0, self.text_w + caret_w + margin_w*2 - self.w)

	-- Center text vertically.
	local font_h = math.floor(font:getHeight() * font:getLineHeight())
	local offset_y = math.floor(0.5 + (self.h - font_h) / 2)

	-- Text.
	if self.text then
		love.graphics.setFont(font)
		love.graphics.print(self.text, margin_w + offset_x, offset_y) -- Alignment
	end

	-- Caret.
	if self.context.current_thimble == self then
		love.graphics.rectangle("fill", margin_w + offset_x + self.text_w, offset_y, caret_w, font_h)
	end

	love.graphics.pop()
end


return def
