--[[
	input/input_field: A simple text box.
--]]


local context = select(1, ...)


local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)




local def = {
	skin_id = "input_field1",
}


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true

		self.allow_hover = true
		self.can_have_thimble = true
		self.allow_focus_capture = false

		self.text = ""

		-- Skin flags
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()
	end
end


--[[
function def:uiCall_destroy(inst)

	if self == inst then
		-- 
	end
end
--]]


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		if self.enabled then
			self.hovered = true
			self:setCursorLow(self.skin.cursor_on)
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		if self.enabled then
			self.hovered = false
			self:setCursorLow()
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


--function def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)


--function def:uiCall_pointerDrag(inst, x, y, dx, dy)


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

	-- Delete all
	elseif key == "delete" and mod["shift"] then
		self.text = ""

	-- Cut
	elseif scancode == "x" and mod["ctrl"] then -- XXX config
		if self.text ~= "" then
			love.system.setClipboardText(self.text)
		end
		self.text = ""

	-- Copy
	elseif scancode == "c" and mod["ctrl"] then -- XXX config
		love.system.setClipboardText(self.text)

	-- Paste
	elseif scancode == "v" and mod["ctrl"] then -- XXX config
		local clipboard_text = love.system.getClipboardText()
		if clipboard_text and utf8.len(clipboard_text) then
			self.text = self.text .. clipboard_text
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


		--refresh = function(self, skinner, skin)
		--update = function(self, skinner, skin, dt)


		render = function(self, ox, oy)

			-- Temporary stand-in code...
			love.graphics.setColor(0, 0, 0, 0.90)
			love.graphics.rectangle("fill", 0, 0, self.w, self.h)

			love.graphics.setColor(0.1, 0.1, 0.1, 1.0)
			love.graphics.print(self.text, 16, 16)

			-- From the old skin file. Untested, not sure if it works now.
			--[[
			local skin = self.skin
			local font = skin.font

			-- Body
			love.graphics.setColor(0, 0, 0, 1) -- XXX
			love.graphics.rectangle("fill", 0.5, 0.5, self.w - 1, self.h - 1, self.rx, self.ry, self.segments)

			-- Outline
			love.graphics.setLineWidth(skin.line_width)
			love.graphics.setLineJoin(skin.line_join)
			love.graphics.setLineStyle(skin.line_style)

			love.graphics.setColor(1, 1, 1, 1) -- XXX
			love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1, self.rx, self.ry, self.segments)

			-- Text
			if self.text then
				love.graphics.setColor(1, 1, 1, 1) -- XXX
				love.graphics.setFont(font)
				love.graphics.print(self.text, 0, 0)
			end

			-- Cursor
			if self.context.current_thimble == self then
				love.graphics.setColor(1, 0, 0, 1) -- XXX
				love.graphics.rectangle("fill", -16, -16, 16, 16) -- XXX
			end
		--]]
		end,
	},
}


return def
