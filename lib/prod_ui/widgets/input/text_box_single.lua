--[[

A single-line text input box.

         Viewport #1
  +-------------------------+
  |                         |

+-----------------------------+
| The quick brown fox jumps   |
+-----------------------------+

--]]


-- LÖVE 12 compatibility
local love_major, love_minor = love.getVersion()


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "text_box_s1",
}


widShared.scroll2SetMethods(def)
-- No integrated scroll bars for single-line text boxes.


local function updateTextWidth(self)
	self.text_w = self.skin.font:getWidth(self.text)
end


-- TODO: Pop-up menu definition.




function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		widShared.setupScroll2(self)
		widShared.setupDoc(self)

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		self.press_busy = false

		-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
		self.caret_extend_x = 0
		self.caret_extend_y = 0

		-- State flags.
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin


		self:reshape()
	end
end


function def:uiCall_reshape()

	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the scissor-box boundary.

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, "margin")
end


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

			local skin = self.skin
			local font = skin.font

			local res = self.disabled and skin.res_disabled or self.hovered and skin.res_hover or skin.res_idle

			-- Body.
			love.graphics.setColor(res.color_body)
			uiGraphics.drawSlice(res.slice, 0, 0, self.w, self.h)

			love.graphics.push("all")

			love.graphics.intersectScissor(
				ox + self.x + self.vp2_x,
				oy + self.y + self.vp2_y,
				math.max(0, self.vp2_w),
				math.max(0, self.vp2_h)
			)

			-- The caret is always in view.
			local offset_x = -math.max(0, self.text_w + skin.caret_w - self.vp_w)

			-- Center text vertically.
			local font_h = math.floor(font:getHeight() * font:getLineHeight())
			local offset_y = math.floor(0.5 + (self.vp_h - font_h) / 2)

			-- Text.
			if self.text then
				love.graphics.setColor(res.color_text)
				love.graphics.setFont(font)
				love.graphics.print(self.text, self.vp_x + offset_x, self.vp_y + offset_y) -- Alignment
			end

			-- Caret.
			if self.context.current_thimble == self then
				love.graphics.setColor(skin.color_cursor)
				love.graphics.rectangle("fill", self.vp_x + offset_x + self.text_w, self.vp_y + offset_y, skin.caret_w, font_h)
			end

			love.graphics.pop()
		end,
	},
}


return def
