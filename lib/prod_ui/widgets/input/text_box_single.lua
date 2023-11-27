--[[

A single-line text input box.

         Viewport #1
  +-------------------------+
  |                         |

+-----------------------------+
| The quick brown fox jumps   |
+-----------------------------+

--]]


--[[
-- XXX Orphaned command (ie virtual CLI) stuff
-- Invoke a function as a result of hitting enter, clicking a linked button, etc.
function editAct.runCommand(self, line_ed)
	local ret1, ret2 = self:uiFunc_commandAction()

	return ret1, ret2
end

local dummyFunc = function() end

-- A function to be called when runCommand() is invoked.
def_wid.uiFunc_commandAction = dummyFunc
--]]
-- DEBUG: Test command configuration
--[[
--editBind["return"] = editAct.runCommand
--editBind["kpenter"] = editAct.runCommand
--]]


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)

local editHistSingle = context:getLua("shared/line_ed/single/edit_hist_single")
local editMethodsSingle = context:getLua("shared/line_ed/single/edit_methods_single")
local lineEdSingle = context:getLua("shared/line_ed/single/line_ed_single")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local utf8Tools = require(context.conf.prod_ui_req .. "lib.utf8_tools")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "text_box_s1",
}


-- Override to make something happen when the user presses 'return' or 'kpenter' while the
-- widget is active and has keyboard focus.
def.wid_action = uiShared.dummyFunc -- args: (self)


widShared.scroll2SetMethods(def)
-- No integrated scroll bars for single-line text boxes.


-- TODO: Pop-up menu definition.


-- Attach editing methods to def.
for k, v in pairs(editMethodsSingle) do

	if def[k] then
		error("meta field already populated: " .. tostring(k))
	end

	def[k] = v
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		widShared.setupScroll2(self)
		widShared.setupDoc(self)

		self.press_busy = false

		-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
		self.caret_extend_x = 0
		self.caret_extend_y = 0

		-- Used to update viewport scrolling as a result of dragging the mouse in update().
		self.mouse_drag_x = 0
		self.mouse_drag_y = 0

		-- Position offset when clicking the mouse.
		-- This is only valid when a mouse action is in progress.
		self.click_byte = 1

		-- State flags.
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin

		self.line_ed = lineEdSingle.new(skin.font)

		self:reshape()
	end
end


function def:updateDocumentDimensions()

	local line_ed = self.line_ed
	local font = line_ed.font

	self.doc_w = font:getWidth(line_ed.disp_text)
	self.doc_h = math.floor(font:getHeight() * font:getLineHeight())

	-- self:updateAlignOffset()
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

	if self == inst then
		if self.enabled then
			self:wid_action()
		end
	end
end


function def:uiCall_textInput(inst, text)

	if self == inst then
		local line_ed = self.line_ed

		if line_ed.allow_input then

			local hist = line_ed.hist

			line_ed:resetCaretBlink()

			local old_byte, old_h_byte = line_ed:getCaretOffsets()

			local suppress_replace = false
			if line_ed.replace_mode then
				-- Replace mode should force a new history entry, unless the caret is adding to the very end of the line.
				if line_ed.car_byte < #line_ed.line + 1 then
					line_ed.input_category = false
				end
			end

			local written = self:writeText(text, suppress_replace)
			self.update_flag = true

			local no_ws = string.find(written, "%S")
			local entry = hist:getCurrentEntry()
			local do_advance = true

			if (entry and entry.car_byte == old_byte)
			and ((line_ed.input_category == "typing" and no_ws) or (line_ed.input_category == "typing-ws"))
			then
				do_advance = false
			end

			if do_advance then
				editHistSingle.doctorCurrentCaretOffsets(line_ed.hist, old_byte, old_h_byte)
			end
			editHistSingle.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "typing" or "typing-ws"

			self:updateDocumentDimensions()
			-- self:scrollGetCaretInBounds(true)
		end
	end
end



function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

	if self == inst then

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
			local res = uiTheme.pickButtonResource(self, skin)
			local line_ed = self.line_ed

			love.graphics.push("all")

			-- Body.
			local slc_body = res.slice
			love.graphics.setColor(res.color_body)
			uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

			-- Highlight selection.
			-- XXX

			-- Text.
			love.graphics.setColor(res.color_text)
			love.graphics.print(line_ed.disp_text)
			love.graphics.print(line_ed.line, 0, 32)

			-- Caret.
			-- XXX
			love.graphics.pop()
		end,
	},
}


return def
