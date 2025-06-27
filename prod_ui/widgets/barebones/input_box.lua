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
local pUTF8 = require(context.conf.prod_ui_req .. "lib.pile_utf8")


-- LÖVE Supplemental
local utf8 = require("utf8")


local def = {}


def.wid_action = uiShared.dummyFunc


local function updateTextWidth(self)
	local font = self.context.resources.fonts.internal
	self.text_w = font:getWidth(self.text)
end


function def:setText(text)
	uiShared.type1(1, text, "string")

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
	uiShared.numberNotNaNEval(1, max)

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


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	self.text = ""
	self.text_w = 0

	self.max_code_points = false

	-- State flags.
	self.enabled = true
	self.hovered = false
	self.pressed = false
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
					self:tryTakeThimble1()
				end
			end
		end
	end

	return true
end


function def:uiCall_thimble1Take(inst)
	if self == inst then
		love.keyboard.setTextInput(true)
	end
end


function def:uiCall_thimble1Release(inst)
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

			if clipboard_text and pUTF8.check(clipboard_text) then

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


def.render = context:getLua("shared/render_button_bare").inputBox


return def
