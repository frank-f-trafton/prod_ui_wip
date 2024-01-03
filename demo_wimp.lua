require("lib.test.strict")

print("Start WIMP Demo.")

-- Setting up a ProdUI project:

--[[
1) LÖVE Text Input should start in a disabled state, and it should not be changed by user code while the ProdUI
context is active. Widgets will toggle this on and off as they take and release the thimble (the ProdUI keyboard focus).
If we leave it on all the time, there is a chance that keystrokes will generate conflicting keypressed and textinput
events. ProdUI discards any love.textinput events while love.keyboard.hasTextInput() is false, and by only turning on
TextInput when it's needed, this should hopefully curb most instances of conflicts.

Here is one example of a conflict: User selects a command in a menu by pressing the space bar. The keypressed event
callback processes the command, closes the menu, and moves keyboard focus to a text box. Then, the textinput event
callback sends " " to the text box. The second action is undesired. However, if TextInput wasn't on while the menu had
focus, then the " " textinput event wouldn't fire in the first place.
--]]


love.keyboard.setTextInput(false)


local MOUSE_CROSS
--MOUSE_CROSS = true


local love_major = love.getVersion()


--[[
local oldPrint = print
print = function(...)
	oldPrint(...)
	oldPrint(debug.traceback())
end
--]]


-- Libs: ProdUI
local itemOps = require("lib.prod_ui.logic.item_ops")
local keyCombo = require("lib.prod_ui.lib.key_combo")
local uiContext = require("lib.prod_ui.ui_context")
local uiDraw = require("lib.prod_ui.ui_draw")
local uiGraphics = require("lib.prod_ui.ui_graphics")
local uiLayout = require("lib.prod_ui.ui_layout")
local uiRes = require("lib.prod_ui.ui_res")
local widShared = require("lib.prod_ui.logic.wid_shared")

-- Libs: QuickPrint
local quickPrint = require("lib.quick_print") -- (Helps with debug-printing to the framebuffer.)
local qp = quickPrint.new()


-- * Demo State *


local demo_show_details = true
local demo_show_perf = true
local demo_perf -- assigned at the end of love.draw


-- * / Demo State *


-- XXX: Replace this with a notification / toast system at some point.
local notif_text = ""
local notif_max = 10.0
local notif_time = notif_max
local notif_font = love.graphics.newFont(20)


-- LÖVE Setup

love.graphics.setDefaultFilter("nearest", "nearest")

love.keyboard.setKeyRepeat(true)
--love.keyboard.setTextInput(true) -- Enabled by default on desktop platforms.

love.filesystem.setSymlinksEnabled(true)

--love.graphics.setLineStyle("rough")
--love.window.setVSync(0)

local font_sz = 12
local function reloadFont(sz)
	return love.graphics.newFont(sz)
end
local font_test = reloadFont(font_sz)
love.graphics.setFont(font_test)

-- / LÖVE Setup


-- * ProdUI Menu-Item defs *


-- Menu item defs
local idef_sep = {}

--idef_sep.initInstance = -- ...

idef_sep.render = function(self, client, ox, oy)
		love.graphics.setLineWidth(1)
		love.graphics.line(self.x + 0.5, self.y + math.floor(self.h/2) + 0.5, self.w - 1, self.h - 1)
	end
itemOps.initDef(idef_sep)

local idef_text = {}
idef_text.initInstance = function(def, client, self)
	self.text = ""
	self.text_x = 0
	self.text_y = 0
end
idef_text.reshape = function(self, client)
	local font = client.skin.font_item
	self.text_x = math.floor(0.5 + self.w/2 - font:getWidth(self.text)/2)
	self.text_y = math.floor(0.5 + self.h/2 - font:getHeight()/2)
end
idef_text.render = function(self, client, ox, oy)
	if self.multi_select then -- test...
		love.graphics.push("all")

		love.graphics.setColor(0.2, 0.2, 0.5, 1.0)
		love.graphics.setLineWidth(3)
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineJoin("miter")
		love.graphics.rectangle("line", self.x + 0.5, self.y + 0.5, self.w - 1, self.h - 1)

		love.graphics.pop()
	end
	-- (font is set by client widget ahead of time)
	love.graphics.print(self.text, self.x + self.text_x, self.y + self.text_y)
end
itemOps.initDef(idef_text)


local function testMultiSelect(self, client) -- XXX test
	self.multi_select = not self.multi_select

	print("self.multi_select", self.multi_select)
end


local function testMultiSelectClick(self, client, button, multi_presses)
	print("testMultiSelectClick", self, client, button, multi_presses)
	testMultiSelect(self, client)
end


local function testMultiSelectKey(self, client, kc, sc, isrep)
	testMultiSelect(self, client)
end


local function testMenuKeyPressed(self, key, scancode, isrepeat)
	-- Debug
	if scancode == "insert" then
		local new_item = itemOps.newItem(idef_text, self)

		new_item.x = 0
		new_item.y = 0
		new_item.w = 48--192
		new_item.h = 48

		new_item.text = "#" .. #self.menu.items + 1--"filler entry #" .. #self.menu.items + 1
		new_item.selectable = true
		new_item.type = "press_action"

		new_item.itemAction_use = testMultiSelectClick

		self:addItem(new_item, math.max(1, self.menu.index))
		self:menuChangeCleanup()

		return true

	-- Debug
	elseif scancode == "delete" then
		if self.menu.index > 0 then
			self:removeItem(self.menu.index)
			self:menuChangeCleanup()
		end

		return true
	end

	return false
end


-- * / ProdUI Menu-Item defs *


local function newWimpContext()

	local context = uiContext.newContext("lib/prod_ui", 0, 0, love.graphics.getDimensions())

	-- Assign resources ASAP.
	local theme_main_path = "lib/prod_ui/themes/vacuum/vacuum.lua"
	local theme_module = uiRes.loadLuaFile(theme_main_path, context)
	local theme_instance = theme_module.newInstance(1.0)

	context.resources = theme_instance

	context:loadWidgetDefsInDirectory("lib/prod_ui/widgets", true, "", false)

	local wid_root = context:addWidget("wimp/root_wimp")
	wid_root.tag = "wimp_workspace"

	wid_root.w, wid_root.h = love.graphics.getDimensions()

	return context, wid_root
end

local context = newWimpContext()


local app_scale_x = 1.0
local app_scale_y = 1.0
local app_base_w = 800
local app_base_h = 600


local app_w = app_base_w * app_scale_x
local app_h = app_base_h * app_scale_y

local function _assertNonZero(val)
	if val == 0 then
		error("Value cannot be zero.")
	end
end


-- Demo helper functions

local function demo_digUpFrameAndHeader(self)
	-- Travel up until we reach the frame
	local wid = self
	while wid do
		if wid.is_frame then
			break
		end
		wid = wid.parent
	end

	if not wid then
		print("Demo Error: couldn't locate ancestor frame.")
		return
	end

	local header = wid:findTag("frame_header")
	if not header then
		print("Demo Warning: no header widget found.")
	end

	return wid, header -- calling code must check return values before using them. (Though if the header is okay, then so is the frame.)
end


function love.resize(w, h)

	-- Assertions
	-- [[
	_assertNonZero(app_base_w)
	_assertNonZero(app_base_h)
	--]]

	--[=[
	print("app_base_w / w", app_base_w / w)
	print("app_base_h / h", app_base_h / h)

	local fit_scale = math.min(w / app_base_w, h / app_base_h)

	app_w = w * fit_scale
	app_h = h * fit_scale

	app_scale_x = app_w / app_base_w
	app_scale_y = app_h / app_base_h
	--]=]

	context:love_resize(w, h)
end


function love.visible(visible)
	context:love_visible(visible)
end


function love.mousefocus(focus)
	--print("love.mousefocus()", focus)
	context:love_mousefocus(focus)
end


function love.focus(focus)
	--print("love.focus()", focus)
	context:love_focus(focus)
end


function love.mousemoved(x, y, dx, dy, istouch)

	x = x / app_scale_x
	y = y / app_scale_y

	dx = dx / app_scale_x
	dy = dy / app_scale_y

	context:love_mousemoved(x, y, dx, dy, istouch)
end


function love.mousepressed(x, y, button, istouch, presses)

	x = x / app_scale_x
	y = y / app_scale_y

	context:love_mousepressed(x, y, button, istouch, presses)
end


function love.mousereleased(x, y, button, istouch, presses)

	x = x / app_scale_x
	y = y / app_scale_y

	context:love_mousereleased(x, y, button, istouch, presses)
end


function love.wheelmoved(x, y)
	context:love_wheelmoved(x, y)
end


function love.keypressed(kc, sc, rep)
	context:love_keypressed(kc, sc, rep)
end


function love.keyreleased(kc, sc)
	context:love_keyreleased(kc, sc)
end


function love.textinput(text)
	context:love_textinput(text)
end


--function love.load(arguments, arguments_unfiltered)
do
	local wimp_root = context:findTag("wimp_workspace")
	context:setRoot(wimp_root)

	-- Generic text label
	--[[
	do
		local txt = wimp_root:addChild("base/text", {font = love.graphics.newFont(20)})
		txt.x = 32
		txt.y = 0
		txt.text = "Foo Unto Bar"
		txt:refreshText()
	end
	--]]

	-- Bare window frame test
	--[[
	do
		local frame = wimp_root:addChild("wimp/window_frame")

		frame:setFrameTitle("WIMP Demo")

		local content = frame:findTag("frame_content")

		local header = frame:findTag("frame_header")

		if header then
			header.selected = true
		end

		frame.w = 400
		frame.h = 384
		frame:reshape(true)

		frame.x = 100
		frame:center(false, true)
	end
	--]]

	--[[
	do
		local planWidgetTree = require("plan_wimp_widget_tree")
		local frame = planWidgetTree.make(wimp_root)
	end
	--]]

	-- The main demo window.
	do
		local frame = wimp_root:addChild("wimp/window_frame")

		frame:setFrameTitle("WIMP Demo")

		--print("frame", frame)
		local content = frame:findTag("frame_content")
		content.DEBUG = "dimensions"

		--local inspect = require("lib.test.inspect.inspect")
		--print("inspect frame:", inspect(frame))

		-- Light up the front window.
		-- XXX handle this properly (I guess by routing window creation through a root WIMP widget?)
		do
			local header = frame:findTag("frame_header")

			if header then
				header.selected = true
			end
		end

		frame.w = 400--640
		frame.h = 384--550

		frame:reshape(true)

		frame.x = 100
		frame.y = 200
		--frame:center(false, true)

		local button

		button = content:addChild("base/button")
		button.x = 64
		button.y = 64
		button.w = 96
		button.h = 24
		button:setLabel("Prompt")

		button.wid_buttonAction = function(self)
			-- Test pushing a new instance onto the stack
			--[=[
			local root2 = context:addWidget("wimp/root_wimp")
			--context:pushRoot(root2)
			context:setRoot(root2)
			local dialog = root2:addChild("wimp/window_frame")
			dialog.userDestroy = function(self)
				--self.context:popRoot()
				self.context:setRoot(wimp_root)
			end
			--]=]

			-- [==[
			local frame, header = demo_digUpFrameAndHeader(self)
			local dialog = wimp_root:addChild("wimp/window_frame")

			if frame then

				--[=[
				-- Test frame-modal state.
				dialog:setModal(frame)
				--]=]

				-- Test root-modal state.
				-- [=[
				--dialog.sort_id = 4
				local root = self:getTopWidgetInstance()
				root:runStatement("rootCall_setModalFrame", dialog)
				--]=]
			end
			--]==]

			dialog.w = 320--640
			dialog.h = 224--320
			dialog:reshape(true)

			dialog:setFrameTitle("Sure about that?")

			local d_content = dialog:findTag("frame_content")
			if d_content then
				if d_content.scr_h then
					d_content.scr_h.auto_hide = true
				end
				if d_content.scr_v then
					d_content.scr_v.auto_hide = true
				end

				local text = dialog:addChild("base/text", {font = context.resources.fonts.p})

				text.x = 0
				text.y = 32
				text.w = d_content.w
				text.h = 64

				text.align = "center"
				text.text = "Are you sure?"
				text:refreshText()

				local button_y = d_content:addChild("base/button")
				button_y.x = 32
				button_y.y = d_content.h - 48
				button_y.w = 96
				button_y.h = 32

				button_y:setLabel("Sure")

				local button_n = d_content:addChild("base/button")
				button_n.x = 256
				button_n.y = d_content.h - 48
				button_n.w = 96
				button_n.h = 32

				button_n:setLabel("Unsure")
			end

			dialog:center(true, true)
			local root = dialog:getTopWidgetInstance()
			root:setSelectedFrame(dialog)

			local try_host = dialog:getOpenThimbleDepthFirst()
			if try_host then
				try_host:takeThimble()
			end
		end

		local button_close = content:addChild("base/button")
		button_close.x = 192
		button_close.y = 64
		button_close.w = 96
		button_close.h = 24
		button_close:setLabel("Close")

		button_close.wid_buttonAction = function(self)
			self:bubbleStatement("frameCall_close")
		end

		local button_close = content:addChild("base/button")
		button_close.x = 0
		button_close.y = 0
		button_close.w = 96
		button_close.h = 24
		button_close:setLabel("Inspiration")
		button_close.str_tool_tip = "Click for an inspiring quote."

		button_close.wid_buttonAction = function(self)
			-- XXX hook up to an actual toast system at some point.
			notif_text = [[
A person who doubts himself is like a man who would enlist in the
ranks of his enemies and bear arms against himself. He makes his
failure certain by himself being the first person to be convinced
of it.

-Alexandre Dumas]]
			notif_time = 0.0
		end

		local checkbox

		checkbox = content:addChild("base/checkbox")
		checkbox.checked = false
		checkbox.bijou_side = "right"

		checkbox.x = 64
		checkbox.y = 128
		checkbox.w = 192
		checkbox.h = 32
		checkbox:setLabel("S_h_ow resize sensors", "single-ul")

		checkbox.wid_buttonAction = function(self)
			print("uiCall_controlAction", self, self.id)

			local par = self.parent
			while par do
				if par.is_frame then
					break
				end
				par = par.parent
			end

			print("self.checked", self.checked)

			if par then
				par:debugVisibleSensors(self.checked)
			end
		end

		checkbox:reshape()

		checkbox = content:addChild("base/checkbox")
		checkbox.checked = true
		checkbox.bijou_side = "right"

		checkbox.x = 64
		checkbox.y = 160
		checkbox.w = 192
		checkbox.h = 32
		checkbox:setLabel("Show state details")

		checkbox.wid_buttonAction = function(self)
			demo_show_details = not not self.checked
			print("demo_show_details", demo_show_details)
		end


		checkbox = content:addChild("base/checkbox")
		checkbox.checked = true
		checkbox.bijou_side = "right"

		checkbox.x = 64
		checkbox.y = 192
		checkbox.w = 192
		checkbox.h = 32
		checkbox:setLabel("Show perf info")

		checkbox.wid_buttonAction = function(self)
			demo_show_perf = not not self.checked
			print("demo_show_perf", demo_show_perf)
		end


		do
			-- Note on VSync: adaptive (-1) and per-frame (2+) may not be supported by graphics drivers.
			-- Additionally, it's possible for the user to override VSync settings.
			local current_vsync = love.window.getVSync()

			local py = 244
			local py_plus = 32

			local text_vsync = content:addChild("base/text", {font = context.resources.fonts.p})
			text_vsync.text = "VSync Mode"
			text_vsync.x = 64 + 9 -- XXX work on syncing padding with embedded widget labels
			text_vsync.y = py
			text_vsync:refreshText()

			local r_action = function(self)
				-- https://love2d.org/wiki/love.window.setVSync
				love.window.setVSync(self.user_vsync_mode)
			end

			local radio_button

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = 64
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_vsync"
			radio_button:setLabel("On")
			radio_button.user_vsync_mode = 1
			radio_button.wid_buttonAction = r_action
			if current_vsync == radio_button.user_vsync_mode then
				radio_button:setChecked(true)
			end

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = 64
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_vsync"
			radio_button:setLabel("Adaptive")
			radio_button.user_vsync_mode = -1
			radio_button.wid_buttonAction = r_action
			if current_vsync == radio_button.user_vsync_mode then
				radio_button:setChecked(true)
			end

			-- 2 or larger will wait that many frames before syncing.
			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = 64
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_vsync"
			radio_button:setLabel("Half")
			radio_button.user_vsync_mode = 2
			radio_button.wid_buttonAction = r_action
			if current_vsync == radio_button.user_vsync_mode then
				radio_button:setChecked(true)
			end

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = 64
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_vsync"
			radio_button:setLabel("Third")
			radio_button.user_vsync_mode = 3
			radio_button.wid_buttonAction = r_action
			if current_vsync == radio_button.user_vsync_mode then
				radio_button:setChecked(true)
			end

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = 64
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_vsync"
			radio_button:setLabel("Off")
			radio_button.user_vsync_mode = 0
			radio_button.wid_buttonAction = r_action
			if current_vsync == radio_button.user_vsync_mode then
				radio_button:setChecked(true)
			end
		end

		do
			local checkbox

			checkbox = content:addChild("base/checkbox")
			checkbox.checked = false
			checkbox.bijou_side = "right"

			checkbox.x = 300
			checkbox.y = 128
			checkbox.w = 192
			checkbox.h = 32
			checkbox:setLabel("Condensed Header")

			checkbox.wid_buttonAction = function(self)
				local frame, header = demo_digUpFrameAndHeader(self)

				if header then
					header.condensed = not not self.checked
					frame:reshape(true)
				end
			end
		end


		do
			local header = frame:findTag("frame_header")

			local px = 312
			local py = 244
			local py_plus = 32

			local text_vsync = content:addChild("base/text", {font = context.resources.fonts.p})
			text_vsync.text = "Control Placement"
			text_vsync.x = px + 9 -- XXX work on syncing padding with embedded widget labels
			text_vsync.y = py
			text_vsync:refreshText()

			local r_action = function(self)
				local frame, header = demo_digUpFrameAndHeader(self)
				if header then
					header.button_side = self.user_button_side
					frame:reshape(true)
				end
			end

			local radio_button

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = px
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_control_side"
			radio_button:setLabel("Left")
			radio_button.user_button_side = "left"
			radio_button.wid_buttonAction = r_action
			if header and header.button_side == radio_button.user_button_side then
				radio_button:setChecked(true)
			end

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = px
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_control_side"
			radio_button:setLabel("Right")
			radio_button.user_button_side = "right"
			radio_button.wid_buttonAction = r_action
			if header and header.button_side == radio_button.user_button_side then
				radio_button:setChecked(true)
			end
		end


		do
			local header = frame:findTag("frame_header")

			local px = 312
			local py = 384
			local py_plus = 32

			local text_vsync = content:addChild("base/text", {font = context.resources.fonts.p})
			text_vsync.text = "Header Text Align"
			text_vsync.x = px + 9 -- XXX work on syncing padding with embedded widget labels
			text_vsync.y = py
			text_vsync:refreshText()

			local r_action = function(self)
				local frame, header = demo_digUpFrameAndHeader(self)
				if header then
					header.text_align = self.usr_text_align
					frame:reshape(true)
				end
			end

			local radio_button

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = px
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_header_text_align"
			radio_button:setLabel("Left")
			radio_button.usr_text_align = "left"
			radio_button.wid_buttonAction = r_action
			if header and header.text_align == radio_button.usr_text_align then
				radio_button:setChecked(true)
			end

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = px
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_header_text_align"
			radio_button:setLabel("Center")
			radio_button.usr_text_align = "center"
			radio_button.wid_buttonAction = r_action
			if header and header.text_align == radio_button.usr_text_align then
				radio_button:setChecked(true)
			end

			py=py+py_plus
			radio_button = content:addChild("base/radio_button")
			radio_button.checked = false
			radio_button.bijou_side = "right"

			radio_button.x = px
			radio_button.y = py
			radio_button.w = 192
			radio_button.h = py_plus
			radio_button.radio_group = "rg_header_text_align"
			radio_button:setLabel("Right")
			radio_button.usr_text_align = "right"
			radio_button.wid_buttonAction = r_action
			if header and header.text_align == radio_button.usr_text_align then
				radio_button:setChecked(true)
			end
		end

		content.w, content.h = widShared.getChildrenPerimeter(content)
		content.doc_w, content.doc_h = content.w, content.h
	end

	--[[
	do
		local frame_d
		local header_d
		local content_d

		frame_d = wimp_root:addChild("wimp/window_frame")

		frame_d.w = 640
		frame_d.h = 480

		frame_d:setFrameTitle("Menu Test")

		header_d = frame_d:findTag("frame_header")
		if header_d then
			--header_d.condensed = true
		end

		content_d = frame_d:findTag("frame_content")
		if content_d then

			content_d.w = 640
			content_d.h = 480

			local menu1 = content_d:addChild("base/menu")
			menu1.x = 16
			menu1.y = 16
			menu1.w = 400
			menu1.h = 350

			menu1.wid_keyPressed = testMenuKeyPressed

			menu1.drag_select = true

			menu1:setScrollBars(true, true)

			menu1:reshape()
		end

		frame_d:reshape(true)
		frame_d:center(true, true)
	end
	--]]

	--[[
	do
		local planTabularMenu = require("plan_wimp_menu_tab")
		local frame_fc = planTabularMenu.make(wimp_root)

		local planFileSelect = require("plan_wimp_file_select")
		local frame_fs = planFileSelect.make(wimp_root)

		--[=[
		local plan_G = require("plan_wimp_g_list")
		local frame_G = plan_G.make(wimp_root)
		--]=]
	end
	--]]

	do
		local planSliderWork = require("plan_slider_work")
		local frame_b = planSliderWork.make(wimp_root)
	end

	do
		local planContainerWork = require("plan_container_work")
		local frame_b = planContainerWork.make(wimp_root)
	end

	--[[
	do
		local planDragBox = require("plan_drag_box")
		local frame_b = planDragBox.make(wimp_root)
	end
	--]]

	do
		local planLabelTest = require("plan_label_test")
		local frame_b = planLabelTest.make(wimp_root)
	end

	do
		local planStepper = require("plan_stepper")
		local frame_b = planStepper.make(wimp_root)
	end

	do
		local planProgressBar = require("plan_progress_bar")
		local frame_b = planProgressBar.make(wimp_root)
	end

	do
		local planButtonWork = require("plan_button_work")
		local frame_b = planButtonWork.make(wimp_root)
	end

	-- [[
	do
		local planListBox = require("plan_wimp_list_box")
		local frame_lb = planListBox.make(wimp_root)
	end
	--]]

	-- [[
	do
		local planTreeBox = require("plan_wimp_tree_box")
		local frame_lb = planTreeBox.make(wimp_root)
	end
	--]]

	-- [[
	do
		local planBarebones = require("plan_barebones")
		local frame_lb = planBarebones.make(wimp_root)
	end
	--]]

	do
		local planButtonSkinners = require("plan_button_skinners")
		local frame_b = planButtonSkinners.make(wimp_root)
	end

	-- [=[
	do
		local frame_ef
		local planTextEditTest = require("plan_text_edit_test")
		frame_ef = planTextEditTest.make(wimp_root)
		--]=]

		-- Test destroying window frame from userUpdate. XXX: move this somewhere more appropriate.
		--[[
		frame_ef.userUpdate = function(self, dt)
			self.DBG_TIME = self.DBG_TIME or 0
			self.DBG_TIME = self.DBG_TIME + dt
			if self.DBG_TIME >= 4 then
				local commonWimp = require(context.conf.prod_ui_req .. "logic.common_wimp")
				commonWimp.closeWindowFrame(self)
				return true
			end
		end
		--]]
	end

	-- [[
	do
		local planInputBox = require("plan_input_box")
		local frame_lb = planInputBox.make(wimp_root)
	end
	--]]

	-- [[
	do
		local planPropertiesBox = require("plan_properties_box")
		local frame_lb = planPropertiesBox.make(wimp_root)
	end
	--]]

	-- [[
	do
		local planDropdownBox = require("plan_dropdown_box")
		local frame_lb = planDropdownBox.make(wimp_root)
	end
	--]]

	-- [[
	do
		local planComboBox = require("plan_combo_box")
		local frame_lb = planComboBox.make(wimp_root)
	end
	--]]

	do
		local bar_menu = wimp_root:addChild("wimp/menu_bar")

		bar_menu.tag = "root_menu_bar"

		-- Test the (normally commented out) debug render user event.
		--[[
		bar_menu.userDebugRender = function(self, os_x, os_y)
			love.graphics.setScissor()
			love.graphics.setColor(1,1,1,1)
			love.graphics.print("Hello world!")
		end
		--]]

		local def_sub2 = {
			{
				type = "command",
				text = "Sub",
				callback = function(client, item) print("1") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			}, {
				type = "command",
				text = "Blurp",
				callback = function(client, item) print("2") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			},
		}

		local def_recent = {
			{
				type = "command",
				text = "One",
				callback = function(client, item) print("1") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			}, {
				type = "group",
				text = "Two",
				group_def = def_sub2,
				callback = function(client, item) print("2") end,
				--key_mnemonic = ,
			}, {
				type = "command",
				text = "Three",
				callback = function(client, item) print("3") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			},
		}

		local def_file = {
			{
				type = "command",
				text = "_N_ew",
				text_shortcut = "Ctrl+N",
				key_mnemonic = "n",
				key_shortcut = "KC n",
				callback = function(client, item) print("NEW!") end,
			}, {
				type = "command",
				text = "_O_pen",
				text_shortcut = "Ctrl+O",
				key_mnemonic = "o",
				key_shortcut = "KC o",
				callback = function(client, item) print("OPEN!") end,
			},
			itemOps.def_separator,
			{
				type = "group",
				text = "_R_ecent",
				group_def = def_recent,
				key_mnemonic = "r",
			},
			itemOps.def_separator,
			{
				type = "command",
				text = "_Q_uit",
				text_shortcut = "Ctrl+Q",
				--callback = function() print("QUIT!") end,
				callback = function(client, item) love.event.quit() end,
				key_mnemonic = "q",
				key_shortcut = "KC q",
			},
		}
		bar_menu:appendItem("category", {
			text = "_F_ile",
			key_mnemonic = "f",
			pop_up_def = def_file,
		})


		local def_edit = {
			{
				type = "command",
				text = "Foo",
				callback = function(client, item) print("FOO") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			}, {
				type = "command",
				text = "Bar",
				callback = function(client, item) print("BAR") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			}, 
			itemOps.def_separator,
			{
				type = "command",
				text = "Baz",
				callback = function(client, item) print("BAZ") end,
				--key_mnemonic = ,
				--key_shortcut = ,
			},
		}
		bar_menu:appendItem("category", {
			text = "_E_dit",
			key_mnemonic = "e",
			pop_up_def = def_edit,
		})


		local def_help = {
			{
				type = "command",
				text = "_C_ontents...",
				text_shortcut = "F1",
				callback = function(client, item) print("HELP") end,
				key_mnemonic = "c",
				key_shortcut = "K f1",
			},
			itemOps.def_separator,
			{
				type = "command",
				text = "_A_bout...",
				callback = function(client, item) print("BAR") end,
				key_mnemonic = "a",
				--key_shortcut = ,
			}, 
		}
		bar_menu:appendItem("category", {
			text = "_H_elp",
			key_mnemonic = "h",
			pop_up_def = def_help,
		})

		bar_menu.w = wimp_root.w
		bar_menu:resize()

		bar_menu:arrange()
		bar_menu:reshape()
		bar_menu:menuChangeCleanup()

		bar_menu.sort_id = 5

		-- Hook application-level shortcuts to WIMP root
		do
			local shortcuts = {
				["KC q"] = function(self, key, scancode, isrepeat) love.event.quit() end,
			}
			local hook_pressed = {
				wid = wimp_root,
				func = function(self, tbl, key, scancode, isrepeat)
					local key_mgr = self.context.key_mgr
					local mod = key_mgr.mod

					local input_str = keyCombo.getKeyString(false, mod["ctrl"], mod["shift"], mod["alt"], mod["gui"], key)
					if shortcuts[input_str] then
						shortcuts[input_str](self, key, scancode, isrepeat)
						return true
					end
				end,
			}

			table.insert(wimp_root.hooks_key_pressed, hook_pressed)
		end

		-- Hook menu bar key commands to WIMP root
		do
			local hook_pressed = {
				wid = bar_menu,
				func = bar_menu.widHook_pressed,
			}
			local hook_released = {
				wid = bar_menu,
				func = bar_menu.widHook_released,
			}

			table.insert(wimp_root.hooks_key_pressed, hook_pressed)
			table.insert(wimp_root.hooks_key_released, hook_released)
		end

		-- Add menu bar to root layout
		bar_menu.lc_func = uiLayout.fitTop
		uiLayout.register(wimp_root, bar_menu)

		-- Test sneaking a button into a menu bar.
		--[[
		local bar_button = bar_menu:addChild("base/button")

		bar_button.w = bar_menu.h - 4
		bar_button.x = bar_menu.w - bar_button.w + 2
		bar_button.h = 2
		bar_button.h = bar_button.w

		bar_button.can_have_thimble = false

		bar_button:reshape()
		--]]
	end

	--love.mouse.setGrabbed(true)
	--love.mouse.setRelativeMode(true)

	-- Start with the top-most window selected, if any.
	print("uh?", wimp_root:selectTopWindowFrame())

	-- Refresh everything.
	wimp_root:reshape(true)
end


function love.update(dt)

	-- XXX Debug
	--love.timer.sleep(1.0)

	context:love_update(dt)

	--[[
	if love.keyboard.isDown("lctrl") then
		local sz_old = font_sz
		if love.keyboard.isDown("down") then
			font_sz = font_sz + 1

		elseif love.keyboard.isDown("up") then
			font_sz = font_sz - 1
		end

		font_sz = math.max(1, font_sz)
		if sz_old ~= font_sz then
			-- Release the old font object and collect garbage twice to prevent
			-- a buildup of rapidly-discarded fonts eating up RAM while pending
			-- release.
			font_test:release()
			font_test = reloadFont(font_sz)
			love.graphics.setFont(font_test)
			collectgarbage("collect")
			collectgarbage("collect")
		end
	end
	--]]

	--print(collectgarbage("count"))

	notif_time = notif_time + dt
end


function love.draw()
	
	-- NOTE: Any persistent canvas work (draw once, display multiple times) needs to be handled
	-- in love.update() or before this clause.
	if not context.window_visible then
		return
	end

	love.graphics.scale(app_scale_x, app_scale_y)

	-- Set the printing region to the window dimensions,
	-- minus 16 pixels of padding on each side.
	local PAD = 16
	qp:setOrigin(PAD, PAD)
	qp:setReferenceDimensions(love.graphics.getWidth() - PAD*2, love.graphics.getHeight() - PAD*2)

	-- XXX right... setScissor() won't work if the display is scaled, and especially if it has sub-pixel rendering precision.
	love.graphics.setScissor()

	uiDraw.drawContext(context, 0, 0)

	love.graphics.setScissor()

	love.graphics.setColor(1, 1, 1, 1)

	if demo_show_details then
		qp:reset()
		qp:setOrigin(PAD, love.graphics.getHeight() - 150)

		qp:print("current_hover:\t", context.current_hover)
		qp:print("current_pressed:\t", context.current_pressed)
		qp:print("current_thimble:\t", context.current_thimble)
		qp:print("captured_focus:\t", context.captured_focus)

		qp:down()

		qp:print("mouse_pressed_button: ", context.mouse_pressed_button)
		qp:print("mouse_pressed_dt_acc: ", context.mouse_pressed_dt_acc)
		qp:print("mouse_pressed_ticks: ", context.mouse_pressed_ticks)
		qp:print("mouse_pressed_rep_n: ", context.mouse_pressed_rep_n)

		qp:reset()
		qp:moveOrigin(400, 0)

		qp:print("cseq_button: ", context.cseq_button)
		qp:print("cseq_presses: ", context.cseq_presses)
		qp:print("cseq_time: ", context.cseq_time)
		qp:print("cseq_timeout: ", context.cseq_timeout)
		qp:print("cseq_widget: ", context.cseq_widget)
		qp:print("cseq_x: ", context.cseq_x)
		qp:print("cseq_y: ", context.cseq_x)
		qp:print("cseq_range: ", context.cseq_range)

		--[[
		qp:down()

		qp:print("love.keyboard.hasTextInput(): ", love.keyboard.hasTextInput())
		--]]
	end

	--print([[collectgarbage("count")*1024]], collectgarbage("count")*1024)

	if demo_show_perf then
		qp:reset()
		qp:setOrigin(love.graphics.getWidth() - 224, love.graphics.getHeight() - 160)
		qp:print("FPS: ", love.timer.getFPS())
		qp:print("avg.dt: ", love.timer.getAverageDelta())

		demo_perf = love.graphics.getStats(demo_perf)
		qp:print("drawcalls: ", demo_perf.drawcalls)
		if love_major < 12 then
			qp:print("images: ", demo_perf.images)
			qp:print("canvases: ", demo_perf.canvases)

		else
			qp:print("textures: ", demo_perf.textures)
		end

		qp:print("fonts: ", demo_perf.fonts)
		qp:print("shaderswitches: ", demo_perf.shaderswitches)
		qp:print("drawcallsbatched: ", demo_perf.drawcallsbatched)

		-- Uncomment to estimate the demo's current Lua memory usage.
		-- NOTE: This will degrade performance. JIT compilation should also be disabled (in conf.lua).
		--[[
		qp:down()
		collectgarbage("collect"); collectgarbage("collect")
		qp:print("Mem (MB): ", collectgarbage("count") / 1024)
		--]]
	end

	if MOUSE_CROSS then
		love.graphics.push("all")

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.setLineWidth(1)
		love.graphics.setLineStyle("rough")

		local mx, my = love.mouse.getPosition()
		local ww, wh = love.graphics.getDimensions()

		love.graphics.line(mx + 0.5, 0.5, mx + 0.5, wh + 0.5)
		love.graphics.line(0.5, my + 0.5, ww + 0.5, my + 0.5)

		love.graphics.points(love.mouse.getPosition())

		love.graphics.pop()
	end

	-- XXX: need an actual notification system.
	if notif_time < notif_max then
		love.graphics.push("all")

		local text_w = notif_font:getWidth(notif_text)
		local text_h = notif_font:getHeight() * 6 -- Terrible.

		love.graphics.origin()
		love.graphics.translate(
			math.floor((love.graphics.getWidth() - text_w) / 2),
			math.floor((love.graphics.getHeight() - text_h) / 2)
		)

		love.graphics.setColor(0, 0, 0.2, 0.75 * math.sin((notif_time / notif_max) * 4.0))
		love.graphics.rectangle(
			"fill",
			-2^16,
			-(text_h * 0.25),
			2^17,
			text_h * 1.50
		)
		love.graphics.setColor(1, 1, 1, math.sin((notif_time / notif_max) * 4.0))

		love.graphics.setFont(notif_font)
		love.graphics.print(notif_text)

		love.graphics.pop()
	end
end


