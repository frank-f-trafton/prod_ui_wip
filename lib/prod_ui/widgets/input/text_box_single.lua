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
--editBindS["return"] = editAct.runCommand
--editBindS["kpenter"] = editAct.runCommand
--]]


-- LÖVE 12 compatibility
local love_major, love_minor = love.getVersion()


local context = select(1, ...)


-- LÖVE Supplemental
local utf8 = require("utf8") -- (Lua 5.3+)

local editBindS= context:getLua("shared/line_ed/s/edit_bind_s")
local editHistS = context:getLua("shared/line_ed/s/edit_hist_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local keyCombo = require(context.conf.prod_ui_req .. "lib.key_combo")
local keyMgr = require(context.conf.prod_ui_req .. "lib.key_mgr")
local lineEdSingle = context:getLua("shared/line_ed/s/line_ed_s")
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
for k, v in pairs(editMethodsS) do

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

		-- How far to offset the line X position depending on the alignment.
		self.align_offset = 0

		-- string: display this text when the input box is empty.
		-- false: disabled.
		self.ghost_text = false

		-- false: use content text alignment.
		-- "left", "center", "right", "justify"
		self.ghost_text_align = false

		self.press_busy = false

		-- Caret position and dimensions. Based on 'line_ed.caret_box_*'.
		self.caret_x = 0
		self.caret_y = 0
		self.caret_w = 0
		self.caret_h = 0

		self.caret_fill = "line"

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


function def:scrollGetCaretInBounds(immediate)

	local line_ed = self.line_ed

	--print("scrollGetCaretInBounds() BEFORE", self.scr2_tx, self.scr2_ty)

	-- Get the extended caret rectangle.
	local car_x1 = self.align_offset + line_ed.caret_box_x - self.caret_extend_x
	local car_y1 = line_ed.caret_box_y - self.caret_extend_y
	local car_x2 = self.align_offset + line_ed.caret_box_x + line_ed.caret_box_w + self.caret_extend_x
	local car_y2 = line_ed.caret_box_y + line_ed.caret_box_h + self.caret_extend_y

	-- Clamp the scroll target.
	self.scr2_tx = math.max(car_x2 - self.vp_w, math.min(self.scr2_tx, car_x1))
	self.scr2_ty = math.max(car_y2 - self.vp_h, math.min(self.scr2_ty, car_y1))

	if immediate then
		self.scr2_fx = self.scr2_tx
		self.scr2_fy = self.scr2_ty
		self.scr2_x = math.floor(0.5 + self.scr2_fx)
		self.scr2_y = math.floor(0.5 + self.scr2_fy)
	end

	--print("car_x1", car_x1, "car_y1", car_y1, "car_x2", car_x2, "car_y2", car_y2)
	--print("scr2 tx ty", self.scr2_tx, self.scr2_ty)

--[[
	print("BEFORE",
		"scr2_x", self.scr2_x, "scr2_y", self.scr2_y, "scr2_tx", self.scr2_tx, "scr2_ty", self.scr2_ty,
		"vp_x", self.vp_x, "vp_y", self.vp_y, "vp_w", self.vp_w, "vp_h", self.vp_h,
		"vp2_x", self.vp2_x, "vp2_y", self.vp2_y, "vp2_w", self.vp2_w, "vp2_h", self.vp2_h)
--]]
	self:scrollClampViewport()

--[[
	print("AFTER",
		"scr2_x", self.scr2_x, "scr2_y", self.scr2_y, "scr2_tx", self.scr2_tx, "scr2_ty", self.scr2_ty,
		"vp_x", self.vp_x, "vp_y", self.vp_y, "vp_w", self.vp_w, "vp_h", self.vp_h,
		"vp2_x", self.vp2_x, "vp2_y", self.vp2_y, "vp2_w", self.vp2_w, "vp2_h", self.vp2_h)
--]]
	--print("scrollGetCaretInBounds() AFTER", self.scr2_tx, self.scr2_ty)
	--print("doc_w", self.doc_w, "doc_h", self.doc_h)
	--print("vp xywh", self.vp_x, self.vp_y, self.vp_w, self.vp_h)
end


function def:updateDocumentDimensions()

	local line_ed = self.line_ed
	local font = line_ed.font

	self.doc_w = font:getWidth(line_ed.disp_text)
	self.doc_h = math.floor(font:getHeight() * font:getLineHeight())

	self:updateAlignOffset()
end


--- Call after changing alignment, then update the alignment of all sub-lines.
function def:updateAlignOffset()

	local align = self.line_ed.align

	if align == "left" then
		self.align_offset = 0

	elseif align == "center" then
		self.align_offset = (self.doc_w < self.vp_w) and math.floor(0.5 + self.vp_w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.align_offset = (self.doc_w < self.vp_w) and self.vp_w or self.doc_w
	end
end


function def:uiCall_reshape()

	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the scissor-box boundary.

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, "margin")

	self:scrollClampViewport()

	self.update_flag = true
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
				editHistS.doctorCurrentCaretOffsets(line_ed.hist, old_byte, old_h_byte)
			end
			editHistS.writeEntry(line_ed, do_advance)
			line_ed.input_category = no_ws and "typing" or "typing-ws"

			self:updateDocumentDimensions()
			self:scrollGetCaretInBounds(true)
		end
	end
end



function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

	if self == inst then
		local line_ed = self.line_ed
		local hist = line_ed.hist

		line_ed:resetCaretBlink()

		local input_intercepted = false

		if scancode == "application" then
			-- XXX: context menu

		elseif scancode == "f6" then
			-- XXX: debug: left align

		elseif scancode == "f7" then
			-- XXX: debug: center align

		elseif scancode == "f8" then
			-- XXX: debug: right align

		elseif scancode == "f9" then
			-- XXX: masking (for passwords)

		elseif scancode == "f10" then
			-- XXX: debug: colorization test
		end

		if input_intercepted then
			return true
		end

		local ctrl_down, shift_down, alt_down, gui_down = self.context.key_mgr:getModState()

		-- (LÖVE 12) if this key should behave differently when NumLock is disabled, swap out the scancode and key constant.
		if love_major >= 12 and keyMgr.scan_numlock[scancode] and not love.keyboard.isModifierActive("numlock") then
			scancode = keyMgr.scan_numlock[scancode]
			key = love.keyboard.getKeyFromScancode(scancode)
		end

		local key_string = keyCombo.getKeyString(true, ctrl_down, shift_down, alt_down, gui_down, scancode)
		local bind_action = editBindS[key_string]

		if bind_action then
			-- NOTE: most history ledger changes are handled in executeBoundAction().
			local res_1, res_2, res_3 = self:executeBoundAction(bind_action)
			if res_1 then
				self.update_flag = true
			end

			self:updateDocumentDimensions()
			self:scrollGetCaretInBounds(true)

			-- Stop event propagation
			return true
		end
	end
end


function def:uiCall_update(dt)

	local line_ed = self.line_ed

	line_ed:updateCaretBlink(dt)

	if self.update_flag then

		-- Update caret shape.
		self.caret_x = line_ed.caret_box_x
		self.caret_y = line_ed.caret_box_y
		self.caret_w = line_ed.caret_box_w
		self.caret_h = line_ed.caret_box_h

		if line_ed.replace_mode then
			self.caret_fill = "line"

		else
			self.caret_fill = "fill"
			self.caret_w = line_ed.caret_line_width
		end

		self.update_flag = false
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

			love.graphics.intersectScissor(
				ox + self.x + self.vp2_x,
				oy + self.y + self.vp2_y,
				math.max(0, self.vp2_w),
				math.max(0, self.vp2_h)
			)

			love.graphics.translate(
				self.vp_x + self.align_offset - self.scr2_x,
				self.vp_y - self.scr2_y
			)

			-- Highlighted selection.
			if line_ed.disp_highlighted then
				love.graphics.setColor(res.color_highlight)
				love.graphics.rectangle(
					"fill",
					line_ed.highlight_x,
					line_ed.highlight_y,
					line_ed.highlight_w,
					line_ed.highlight_h
				)
			end

			-- Ghost text. XXX: alignment
			if self.ghost_text and #line_ed.line == 0 then
				love.graphics.setFont(skin.font_ghost)
				love.graphics.print(self.ghost_text, 0, 0)
			end

			-- Display Text.
			love.graphics.setColor(res.color_text)
			love.graphics.setFont(line_ed.font)
			love.graphics.print(line_ed.disp_text)

			-- Caret.
			if self == self.context.current_thimble and line_ed.caret_is_showing then
				love.graphics.setColor(skin.color_insert) -- XXX: color_replace
				love.graphics.rectangle(
					self.caret_fill,
					self.caret_x,
					self.caret_y,
					self.caret_w,
					self.caret_h
				)
			end

			love.graphics.pop()

			-- Debug renderer.
			-- [[
			love.graphics.print(
				"line: " .. line_ed.line
				.. "\n#line: " .. #line_ed.line
				.. "\ncar_byte: " .. line_ed.car_byte
				.. "\nh_byte: " .. line_ed.h_byte
				.. "\ncaret_is_showing: " .. tostring(line_ed.caret_is_showing)
				.. "\ncaret_blink_time: " .. tostring(line_ed.caret_blink_time)
				.. "\ncaret box: " .. line_ed.caret_box_x .. ", " .. line_ed.caret_box_y .. ", " .. line_ed.caret_box_w .. ", " .. line_ed.caret_box_h
				,
				0, 64
			)

			local yy, hh = 240, line_ed.font:getHeight()
			love.graphics.print("History state:", 0, 216)

			for i, entry in ipairs(line_ed.hist.ledger) do
				love.graphics.print(i .. " c: " .. entry.car_byte .. " h: " .. entry.h_byte .. "line: " .. entry.line, 0, yy)
				yy = yy + hh
			end
			--]]
		end,
	},
}


return def
