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


local lgcButtonBare = context:getLua("shared/lgc_button_bare")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


-- LÖVE Supplemental
local utf8 = require("utf8")


local def = {}


def.wid_action = uiShared.dummyFunc


local function updateTextWidth(self)

	local font = self.context.resources.fonts.internal
	self.text_w = font:getWidth(self.text)
end


function def:setText(text)

	-- Assertions
	-- [[
	if type(text) ~= "string" then uiShared.errBadType(1, text, "string") end
	--]]

	if self.max_code_points then
		-- Trim text if it exceeds the max code point count.
		local count_incoming = utf8.len(text)
		if count_incoming > self.max_code_points then
			text = textUtil.trimString(text, self.max_code_points)
		end
	end

	self.text = text
	updateTextWidth(self)
end


-- @param max The maximum number of code points. Pass false or nil to effectively disable the limit.
function def:setMaxCodePoints(max)

	-- Assertions
	-- [[
	if max and type(max) ~= "number" then uiShared.errBadType(1, max, "false/nil/number") end
	--]]

	if max then
		max = math.floor(math.max(0, max))
	end

	self.max_code_points = max or false

	if self.max_code_points then
		-- Re-trim any existing text.
		local copo_count = utf8.len(self.text)

		if copo_count > self.max_code_points then
			self.text = textUtil.trimString(self.text, self.max_code_points)
			updateTextWidth(self)
		end
	end
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		self.text = ""
		self.text_w = 0

		self.max_code_points = false

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

	if self == inst then
		if self.enabled then
			self:wid_action()
		end
	end
end


function def:uiCall_textInput(inst, text)

	if self == inst then
		-- Input validation happens in the context before this event is called.

		if self.max_code_points then
			-- Trim incoming text if the total would exceed the max code point count.
			local count_incoming = utf8.len(text)
			if count_incoming > self.max_code_points - utf8.len(self.text) then
				text = textUtil.trimString(text, self.max_code_points - utf8.len(self.text))
			end
		end

		self.text = self.text .. text

		updateTextWidth(self)
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

	if self == inst then
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

		-- Paste (overwrites all existing text)
		elseif scancode == "v" and mod["ctrl"] then -- XXX config
			local clipboard_text = love.system.getClipboardText()

			if clipboard_text and utf8Tools.check(clipboard_text) then

				if self.max_code_points then
					-- Trim text if it exceeds the max code point count.
					local count_incoming = utf8.len(clipboard_text)
					if count_incoming > self.max_code_points then
						clipboard_text = textUtil.trimString(clipboard_text, self.max_code_points)
					end
				end

				self.text = clipboard_text
				updateTextWidth(self)
				return true
			end
		end
	end
end


def.render = function(self, ox, oy)

	love.graphics.push("all")

	local scale = self.context.resources.scale
	local font = self.context.resources.fonts.internal

	local line_w = math.floor(1.0 * scale)
	local caret_w = math.floor(2.0 * scale)
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

	uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

	-- Horizontal scroll offset. The caret should always be in view.
	local offset_x = -math.max(0, self.text_w + caret_w + margin_w*2 - self.w)

	-- Center text vertically.
	local font_h = math.floor(font:getHeight() * font:getLineHeight())
	local offset_y = math.floor(0.5 + (self.h - font_h) / 2)

	-- Text.
	love.graphics.setFont(font)
	love.graphics.print(self.text, margin_w + offset_x, offset_y) -- Alignment

	-- Caret.
	if self.context.current_thimble == self then
		love.graphics.rectangle("fill", margin_w + offset_x + self.text_w, offset_y, caret_w, font_h)
	end

	love.graphics.pop()
end


return def
