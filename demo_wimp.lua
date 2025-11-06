require("lib.test.strict")


local demoShared = require("demo_shared")
local inspect = require("lib.test.inspect")
local uiPopUpMenu = require("prod_ui.ui_pop_up_menu")


print("Start WIMP Demo.")


local demo_default_theme
--demo_default_theme = "vacuum_light"
demo_default_theme = "vacuum_dark"


-- The first panel to load.
local demo_panel_launch = {
	"widgets.dropdown_box",
	"widgets.list_box",
	"widgets.button_work",
	"widgets.number_box",
	"ui_frames.workspaces",
	"widgets.menu_tab",
	"widgets.properties_box",
	"layouts.layout_unit",
	"layouts.layout_sashes",
	"layouts.layout",
	"layouts.layout_static",
	"widgets.text_box_multi",
	"widgets.text_box_single",
	"widgets.button_split",
	"themes_and_scale",
	"demo_welcome",
	"widgets.progress_bar",
	"widgets.slider_work",
}


-- Upon starting the demo, all of these Window Frame plans are instantiated.
local demo_window_launch = {
	--"window_frames.wimp_file_select",
	--"window_frames.frame_unselectable",
	--"window_frames.wimp_frame",
	--"window_frames.window_frame_selector",
}


local demo_plan_list = {
	nodes = {
		{plan_id = "demo_welcome", label = "Welcome"},
		{plan_id = "widgets.button_work", label = "Button work"},
		{plan_id = "theming_skinning.button_skinners", label = "Button Skinners"},
		{plan_id = "widgets.button_split", label = "Split Button"},
		{plan_id = "widgets.slider_work", label = "Slider work"},
		{plan_id = "widgets.stepper", label = "Stepper"},
		{plan_id = "widgets.text_box_single", label = "Textbox (Single-Line)"},
		{plan_id = "widgets.text_box_multi", label = "Textbox (Multi-Line)"},
		-- Working on it...
		--{plan_id = "widgets.text_box_script", label = "Script Editor"},
		{plan_id = "widgets.number_box", label = "Number Box"},
		{plan_id = "widgets.properties_box", label = "Properties Box"},
		{plan_id = "widgets.combo_box", label = "Combo Box"},
		{plan_id = "widgets.dropdown_box", label = "Dropdown Box"},
		{plan_id = "widgets.barebones", label = "Barebones Widgets"},
		{plan_id = "widgets.tree_box", label = "Tree Box"},
		{plan_id = "widgets.list_box", label = "List Box"},
		{plan_id = "widgets.menu_tab", label = "Tabular Menu"},
		{plan_id = "widgets.progress_bar", label = "Progress Bar"},
		-- TODO: text blocks
		{plan_id = "ui_frames.dialogs_notifs", label = "Dialogs and Notifications"},
		{plan_id = "ui_frames.workspaces", label = "Workspace Frames"},
		{plan_id = "themes_and_scale", label = "Themes and Scale"},
		{plan_id = "layouts.layout", label = "Layout"},
		{plan_id = "layouts.layout_static", label = "Layout (Static)"},
		{plan_id = "layouts.layout_sashes", label = "Layout (Sashes)"},
		{plan_id = "layouts.layout_unit", label = "Layout (Unit Segments)"},
		--[[
		{plan_id = "unfinished", label = "Unfinished Stuff", nodes = {
			{plan_id = "unfinished.drag_box", label = "Drag Box"},
			{plan_id = "unfinished.dial", label = "Dials"},
			{plan_id = "unfinished.container_work", label = "Container work"},

			{plan_id = "unfinished.label_test", label = "Label test"},
		}},
		--]]
	}
}


-- ProdUI programs should start with text input disabled.
love.keyboard.setTextInput(false)


local love_major = love.getVersion()


--[[
-- Finds the origin of printed console text.
local oldPrint = print
print = function(...)
	oldPrint(...)
	oldPrint(debug.traceback())
end
--]]


-- ProdUI
local ui = require("prod_ui")


-- Libs: QuickPrint / DebugPanel
local debugPanel = require("lib.debug_panel")


local dpanel = debugPanel.new(320, love.graphics.getFont()) -- the font will be updated later.
local dpanel_side_pad = 32
dpanel.x = dpanel_side_pad
dpanel.y = 40
local dpanel_left = true
local dpanel_cool = 0
local dpanel_cool_max = 0.33
local dpanel_tabs = {0, 24, 160}


-- * Demo State *


local demo_perf -- assigned near love.draw


local demo_zoom = 1.0
local demo_canvas


-- * / Demo State *


-- LÖVE Setup

love.graphics.setDefaultFilter("nearest", "nearest")

love.keyboard.setKeyRepeat(true)

love.filesystem.setSymlinksEnabled(true)

--love.graphics.setLineStyle("rough")

--love.window.setVSync(0)

local font_sz = 14
local font_test
local function reloadFont()
	local old_font = font_test
	font_test = love.graphics.newFont(font_sz)
	dpanel.qp.text_object:setFont(font_test)

	-- Release the old font object and collect garbage twice to prevent
	-- a buildup of rapidly-discarded fonts.
	if old_font then
		old_font:release()
		collectgarbage("collect")
		collectgarbage("collect")
	end

end
reloadFont()


-- / LÖVE Setup


local app_settings = require("prod_ui.data.default_settings")
--app_settings.wimp.pop_up_menu.block_1st_click_out = true


local function newWimpContext()
	local context = ui.context.newContext("prod_ui", app_settings)

	context:setScale(1.0)
	context:setDPI(96)

	-- Config/settings specific to this demo.
	context.app = {
		show_details = false,
		show_perf = false,
		show_mouse_cross = false,
		enable_zoom = false,

		-- A crappy toast / notification system.
		-- XXX Write a proper one sometime.
		notif = {
			text = "",
			max = 10.0,
			time = 10.0,
			font = love.graphics.newFont(20)
		},

		-- Highlights one widget's bounding rectangle in love.draw().
		dbg_highlight = {
			active = false,
			wid = false,
			-- fill
			r = 0.9, g = 0.1, b = 0.1, a = 0.5,
		},

		-- Shows the widget's viewport rectangles in love.draw()
		dbg_vp = {
			active = false,
			wid = false
		},

		-- Shows the widget's layout nodes in love.draw()
		dbg_lo = {
			active = false,
			wid = false
		}
	}

	-- Assign resources ASAP.
	context:loadSkinnersInDirectory("prod_ui/skinners", true, "")
	context:loadWidgetDefsInDirectory("prod_ui/widgets", true, "", false)

	local theme = demoShared.loadThemeDuplicateSkins(context, demo_default_theme)
	context:applyTheme(theme)

	local wid_root = context:addRoot("wimp/root_wimp")
	wid_root.w, wid_root.h = love.graphics.getDimensions()

	-- Test...
	--[[
	local counter = 0

	wid_root.uiCall_quit = function(self)
		counter = counter + 1
		print("counter (allow quitting at 3):", counter)
		if counter >= 3 then
			return false
		end

		return true
	end
	--]]

	return context, wid_root
end


local context, wimp_root = newWimpContext()


local function updateDPanelX(dpanel)
	if dpanel_left then
		dpanel.x = dpanel_side_pad
	else
		dpanel.x = love.graphics.getWidth() - dpanel.w - dpanel.x_pad*2 - dpanel_side_pad
	end
end


function love.resize(w, h)
	context:love_resize(w, h)

	updateDPanelX(dpanel)
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
	context:love_mousemoved(x, y, dx, dy, istouch)
end


function love.mousepressed(x, y, button, istouch, presses)
	context:love_mousepressed(x, y, button, istouch, presses)
end


function love.mousereleased(x, y, button, istouch, presses)
	context:love_mousereleased(x, y, button, istouch, presses)
end


function love.wheelmoved(x, y)
	context:love_wheelmoved(x, y)
end


local function cb_updateDebugControls(self)
	if self.tag == "wimp-demo-show-state-details" then
		self:setChecked(context.app.show_details)

	elseif self.tag == "wimp-demo-show-perf" then
		self:setChecked(context.app.show_perf)

	elseif self.tag == "wimp-demo-mouse-cross" then
		self:setChecked(context.app.show_mouse_cross)
	end
	-- There is no control for toggling demo zoom yet.
end


function love.keypressed(kc, sc, rep)
	-- Debug stuff, specific to this demo.
	-- [====[
	if love.keyboard.isDown("lctrl", "rctrl") and kc == "`" then
		if context:getScale() > 1 then
			demoShared.executeThemeUpdate(context, 1.0, context:getDPI(), context:getThemeID())
		else
			--demoShared.executeThemeUpdate(context, 1.5, 192)
			demoShared.executeThemeUpdate(context, 1.5, context:getDPI(), context:getThemeID())
		end
	end

	if love.keyboard.isDown("lshift", "rshift") and love.keyboard.isDown("lctrl", "rctrl") then
		if kc == "1" or kc == "kp1" then
			context.app.show_details = not context.app.show_details
			context.root:forEach(cb_updateDebugControls)

		elseif kc == "2" or kc == "kp2" then
			context.app.show_perf = not context.app.show_perf
			context.root:forEach(cb_updateDebugControls)

		elseif kc == "3" or kc == "kp3" then
			context.app.show_mouse_cross = not context.app.show_mouse_cross
			context.root:forEach(cb_updateDebugControls)

		elseif kc == "4" or kc == "kp4" then
			context.app.enable_zoom = not context.app.enable_zoom
			context.root:forEach(cb_updateDebugControls)
		end
	end
	--]====]

	context:love_keypressed(kc, sc, rep)
end


function love.keyreleased(kc, sc)
	context:love_keyreleased(kc, sc)
end


function love.textinput(text)
	context:love_textinput(text)
end


function love.quit()
	return context:love_quit()
end


do
	do
		-- Construct the application menu bar.
		local menu_bar = wimp_root:addChild("wimp/menu_bar")
			:setTag("root_menu_bar")
			:geometrySetMode("segment", "top", 32)

		-- Test the (normally commented out) debug render user event.
		--[[
		menu_bar.userDebugRender = function(self, os_x, os_y)
			love.graphics.setScissor()
			love.graphics.setColor(1,1,1,1)
			love.graphics.print("Hello world!")
		end
		--]]


		local function cb_hide_menu(client, item)
			local root = client:getRootWidget()
			if root then
				local menu_bar = root:findTag("root_menu_bar")
				if menu_bar then
					menu_bar:setHidden(not menu_bar:getHidden())
					root:reshape()
				end
			end
		end


		local function cb_quit(client, item)
			love.event.quit()
		end


		local function _tryLaunchFrame(self, plan_id)
			local root = self:getRootWidget()
			if root then
				demoShared.launchWindowFrameFromPlan(root, plan_id, true)
			end
		end


		local P = uiPopUpMenu.P


		local proto_demo = P.prototype {
			P.command()
				:setText("Video Settings")
				:setCallback(function(client, item) _tryLaunchFrame(client, "window_frames.video_settings") end),

			P.command()
				:setText("Widget Tree View")
				:setCallback(function(client, item) _tryLaunchFrame(client, "window_frames.wimp_widget_tree") end),

			P.command()
				:setText("Window Frame Selector")
				:setCallback(function(client, item) _tryLaunchFrame(client, "window_frames.window_frame_selector") end),

			P.separator(),

			P.command()
				:setText("Hide Menu")
				:setTextShortcut("F8")
				:setCallback(cb_hide_menu),

			P.separator(),

			P.command()
				:setText("_Q_uit")
				:setTextShortcut("Ctrl+Q")
				:setCallback(cb_quit)
		}

		menu_bar:addCategory("_D_emo", "d", nil, proto_demo)
		-- Test menu category icons:
		--menu_bar:addCategory("", "d", "file", proto_demo)

		local proto_sub2 = P.prototype {
			P.command()
				:setText("Sub")
				:setCallback(function(client, item) print("1") end),

			P.command()
				:setText("Blurp")
				:setCallback(function(client, item) print("2") end)
		}

		local proto_recent = P.prototype {
			P.command()
				:setText("One")
				:setCallback(function(client, item) print("1") end),

			P.group()
				:setText("Two")
				:setGroupPrototype(proto_sub2),

			P.command()
				:setText("Three"),
		}

		local proto_file = P.prototype {
			P.command()
				:setText("_N_ew")
				:setTextShortcut("Ctrl+N")
				:setKeyMnemonic("n")
				:setKeyShortcut("KC n")
				:setCallback(function(client, item) print("NEW!") end),

			P.command()
				:setText("_O_pen")
				:setTextShortcut("Ctrl+O")
				:setKeyMnemonic("o")
				:setKeyShortcut("KC o")
				:setCallback(function(client, item) print("OPEN!") end),

			P.separator(),

			P.group()
				:setText("_R_ecent")
				:setGroupPrototype(proto_recent)
				:setKeyMnemonic("r")
		}

		menu_bar:addCategory("_M_enu Example", "m", nil, proto_file)

		--[==[
		local proto_edit = P.prototype {
			P.command()
				:setText("Foo")
				:setCallback(function(client, item) print("FOO") end),

			P.command()
				:setText("Bar")
				:setCallback(function(client, item) print("BAR") end),

			P.separator(),

			P.command()
				:setText("Baz")
				:setCallback(function(client, item) print("BAZ") end),
		}

		menu_bar:addCategory("_E_dit", "e", nil, proto_edit)
		--]==]

		--[==[
		local proto_help = P.prototype {
			P.command()
				:setText("_C_ontents...")
				:setTextShortcut("F1")
				:setCallback(function(client, item) print("HELP") end)
				:setKeyMnemonic("c")
				:setKeyShortcut("K f1"),

			P.separator(),

			P.command()
				:setText("_A_bout...")
				:setCallback(function(client, item) print("BAR") end)
				:setKeyMnemonic("a")
		}

		menu_bar:addCategory("_H_elp", "h", nil¸ proto_help)
		--]==]

		menu_bar:arrangeItems()
		menu_bar:menuChangeCleanup()

		menu_bar.sort_id = 6

		-- Hook application-level shortcuts to WIMP root
		do
			local shortcuts = {
				["C+q"] = function(self, key, scancode, isrepeat) love.event.quit() end,
				["+f8"] = function(self, key, scancode, isrepeat)
					local root = self:getRootWidget()
					if root then
						local menu_bar = root:findTag("root_menu_bar")
						if menu_bar then
							menu_bar:setHidden(not menu_bar:getHidden())
							root:reshape()
						end
					end
				end,
			}
			local hook_pressed = function(self, tbl, key, scancode, isrepeat)
				local key_mgr = self.context.key_mgr
				local mod = key_mgr.mod

				local input_str = ui.keyboard.getKeyString(mod["ctrl"], mod["shift"], mod["alt"], mod["gui"], false, key)
				if shortcuts[input_str] then
					shortcuts[input_str](self, key, scancode, isrepeat)
					return true
				end
			end

			table.insert(wimp_root.KH_trickle_key_pressed, hook_pressed)
		end

		-- Hook menu bar key commands to WIMP root
		do
			table.insert(wimp_root.KH_key_pressed, menu_bar.widHook_pressed)
			table.insert(wimp_root.KH_key_released, menu_bar.widHook_released)
		end
	end


	do
		local ws1 = wimp_root:newWorkspace()

		ws1:layoutSetBase("viewport")
		ws1:containerSetScrollRangeMode("zero")
		ws1:setSashesEnabled(true)

		-- NOTE: Do not register Workspaces to the root layout. Internally, the root takes care of positioning and
		-- reshaping the current active Workspace.
		wimp_root:setActiveWorkspace(ws1)
		ws1.tag = "main_workspace"

		local demo_list = ws1:addChild("wimp/tree_box")
			:geometrySetMode("segment", "left", 300, "norm")
			:setTag("plan_menu")

		demo_list.MN_wrap_selection = "no-rep"


		-- Uncomment this to continuously select menu items as you scrub the mouse cursor
		-- over the ListBox.
		--demo_list.MN_drag_select = true

		demo_list:setScrollBars(false, true)

		local function _addPlans(tree_box, parent, src_node)
			--print("parent", parent, "src_node.nodes", src_node.nodes)
			--print(inspect(src_node))
			local item
			if parent then
				item = tree_box:addNode(src_node.label, parent)
				item.plan_id = src_node.plan_id
			end

			if src_node.nodes then
				item = item or tree_box.tree
				for _, node in ipairs(src_node.nodes) do
					_addPlans(tree_box, item, node)
				end
			end
		end

		_addPlans(demo_list, nil, demo_plan_list)
		demo_list:orderItems()
		demo_list:arrangeItems()

		--print(inspect(demo_list.tree))

		local function _instantiateDemoContainer(workspace)
			-- First, destroy any existing containers with the same tag.
			local wid
			repeat
				wid = context.root:findTag("plan_container")
				if wid then
					wid:destroy()
				end
			until not wid

			local plan_container = workspace:addChild("base/container")
			plan_container:setTag("plan_container")
			plan_container:geometrySetMode("remaining")

			return plan_container
		end

		demo_list.wid_select = function(self, item, item_i)
			local workspace = self.context.root:findTag("main_workspace")
			if workspace and item.plan_id then
				local plan = require("demo_wimp_plans." .. item.plan_id)
				local container = _instantiateDemoContainer(workspace)

				plan.make(container)
				workspace:reshape()
			end
		end
	end

	--love.mouse.setGrabbed(true)
	--love.mouse.setRelativeMode(true)

	-- Quick-launch windows and up to one panel (see top of file for the lists).
	local panel_id = demo_panel_launch[1]
	local plan_list = wimp_root:findTag("plan_menu")
	if panel_id and plan_list then
		for i, item in ipairs(plan_list.MN_items) do
			if item.plan_id == panel_id then
				plan_list:setSelection(item)
				break
			end
		end
	end

	-- TODO: need to deal with initial sort state, so that Workspaces don't obscure Window Frames.
	wimp_root:sortG2()

	-- Start with the top-most window selected, if any.
	wimp_root:selectTopFrame()

	-- If no Window Frames were created, hand the thimble to the main demo list.
	local demo_list = wimp_root:findTag("plan_menu")
	if demo_list then
		demo_list:tryTakeThimble1()
	end

	-- Refresh everything.
	wimp_root:reshape()

	for i, window_id in ipairs(demo_window_launch) do
		demoShared.launchWindowFrameFromPlan(wimp_root, window_id, true)
	end
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

		local old_sz = font_sz
		font_sz = math.max(1, font_sz)
		if old_sz ~= font_sz then
			reloadFont()
		end
	end
	--]]

	--print(collectgarbage("count"))

	-- Crappy hack intended to demonstrate a toast system, without having yet
	-- written a proper toast system.
	local notif = context.app.notif
	notif.time = notif.time + dt

	dpanel_cool = math.max(0, dpanel_cool - dt)

	if love.keyboard.isDown("-") then
		demo_zoom = demo_zoom - dt * 5

	elseif love.keyboard.isDown("=") then
		demo_zoom = demo_zoom + dt * 5
	end

	if not context.app.enable_zoom then
		demo_zoom = 1.0
	end

	demo_zoom = math.max(1.0, demo_zoom)

	-- debug
	--[[
	if context.root then
		context.root:forEach(function(self)
			-- etc.
		end
		)
	end
	--]]
end


local function _printDetails1(dpanel)
	local qp = dpanel.qp

	qp:print("Context State:")
	qp:print("", "current_hover: ", context.current_hover)
	qp:print("", "current_pressed: ", context.current_pressed)
	qp:print("", "thimble1: ", context.thimble1)
	qp:print("", "thimble2: ", context.thimble2)
	qp:print("", "captured_focus: ", context.captured_focus)

	qp:down()

	qp:print("mouse_pressed_...")
	qp:print("", "button: ", context.mouse_pressed_button)
	qp:print("", "ticks: ", context.mouse_pressed_ticks)
	qp:print("", "dt_acc: ", context.mouse_pressed_dt_acc)
	qp:print("", "rep_n: ", context.mouse_pressed_rep_n)

	qp:down()

	qp:print("cseq_...")
	qp:print("", "button: ", context.cseq_button)
	qp:print("", "presses: ", context.cseq_presses)
	qp:print("", "time: ", context.cseq_time)
	qp:print("", "timeout: ", context.cseq_timeout)
	qp:print("", "widget: ", context.cseq_widget)
	qp:print("", "x: ", context.cseq_x)
	qp:print("", "y: ", context.cseq_x)
	qp:print("", "range: ", context.cseq_range)

	qp:down()

	qp:print("love.keyboard...")
	qp:print("", ".hasTextInput(): ", love.keyboard.hasTextInput())

	qp:down()
end


local function _printPerf1(dpanel)
	local qp = dpanel.qp

	-- Uncomment to estimate the demo's current Lua memory usage.
	-- NOTE: This will degrade performance. JIT compilation should also be disabled (in conf.lua).
	--[[
	collectgarbage("collect")
	collectgarbage("collect")
	--]]
	qp:print("Lua Memory (KB): ", "", math.floor(collectgarbage("count")))
	qp:down()

	qp:print("GPU Stats:")
	if not demo_perf or not next(demo_perf) then
		qp:print("", "(waiting for stats)")
	else
		qp:print("", "drawcalls: ", demo_perf.drawcalls)
		qp:print("", "canvasswitches: ", demo_perf.canvasswitches)
		qp:print("", "texturememory: ", demo_perf.texturememory)

		if love_major < 12 then
			qp:print("", "canvases: ", demo_perf.canvases)
			qp:print("", "images: ", demo_perf.images)
		else
			qp:print("", "textures: ", demo_perf.textures)
		end

		qp:print("", "fonts: ", demo_perf.fonts)
		qp:print("", "shaderswitches: ", demo_perf.shaderswitches)
		qp:print("", "drawcallsbatched: ", demo_perf.drawcallsbatched)
	end

	qp:down()
	qp:print("Video Stats:")
	qp:print("", "avg.dt: ", love.timer.getAverageDelta())
	qp:print("", "FPS: ", love.timer.getFPS())
end


function love.draw()
	-- NOTE: Any persistent canvas work (draw once, display multiple times) needs to be handled
	-- in love.update() or before this clause.
	if not context.window_visible then
		return
	end

	if demo_zoom ~= 1.0 then
		if not demo_canvas or demo_canvas:getWidth() ~= love.graphics.getWidth() or demo_canvas:getHeight() ~= love.graphics.getHeight() then
			demo_canvas = love.graphics.newCanvas()
			collectgarbage("collect")
			collectgarbage("collect")
		end

		love.graphics.setCanvas(demo_canvas)
		love.graphics.clear(0, 0, 0, 0)
	end

	love.graphics.push("all")

	context:draw(0, 0)

	love.graphics.pop()

	local app = context.app

	local qp = dpanel.qp
	local draw_panel = app.show_details or app.show_perf

	if draw_panel then
		qp:reset()
		qp:setTabs(dpanel_tabs)
		qp.text_object:clear()
	end

	if app.show_details then
		_printDetails1(dpanel)
	end

	--print([[collectgarbage("count")*1024]], collectgarbage("count")*1024)

	if app.show_perf then
		_printPerf1(dpanel)
	end

	if app.show_mouse_cross then
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

	-- XXX: really need an actual toast / notification system.
	local notif = context.app.notif
	if notif.time < notif.max then
		love.graphics.push("all")

		local text_w = notif.font:getWidth(notif.text)
		local text_h = notif.font:getHeight() * 8 -- Terrible.

		love.graphics.origin()
		love.graphics.translate(
			math.floor((love.graphics.getWidth() - text_w) / 2),
			math.floor((love.graphics.getHeight() - text_h) / 2)
		)

		love.graphics.setColor(0, 0, 0.2, 0.75 * math.sin((notif.time / notif.max) * 4.0))
		love.graphics.rectangle(
			"fill",
			-2^16,
			-(text_h * 0.25),
			2^17,
			text_h * 1.50
		)
		love.graphics.setColor(1, 1, 1, math.sin((notif.time / notif.max) * 4.0))

		love.graphics.setFont(notif.font)
		love.graphics.print(notif.text)

		love.graphics.pop()
	end

	-- Debug-highlight
	local highlight = context.app.dbg_highlight
	if highlight.active and highlight.wid and not highlight.wid._dead then
		local wid = highlight.wid

		love.graphics.push("all")

		love.graphics.setColor(highlight.r, highlight.g, highlight.b, highlight.a)
		local wx, wy = wid:getAbsolutePosition()
		love.graphics.rectangle("fill", wx, wy, wid.w, wid.h)

		love.graphics.pop()
	else
		highlight.wid = false
	end
	local dbg_vp = context.app.dbg_vp
	if dbg_vp and dbg_vp.active and dbg_vp.wid and not dbg_vp.wid._dead then
		love.graphics.push("all")

		local widShared = context:getLua("core/wid_shared")
		local wid = dbg_vp.wid
		love.graphics.translate(wid:getAbsolutePosition())
		if dbg_vp.wid.vp then
			widShared.debug.debugDrawViewport(dbg_vp.wid, 1)
		end
		for i = 2, 8 do
			local key = "vp" .. i
			if dbg_vp.wid[key] then
				widShared.debug.debugDrawViewport(dbg_vp.wid, i)
			end
		end

		love.graphics.pop()
	end

	local dbg_lo = context.app.dbg_lo
	if dbg_lo and dbg_lo.active and dbg_lo.wid and not dbg_lo.wid._dead then
		love.graphics.push("all")

		local widShared = context:getLua("core/wid_shared")
		local wid = dbg_lo.wid
		love.graphics.translate(wid:getAbsolutePosition())
		love.graphics.translate(-wid.scr_x, -wid.scr_y)
		widShared.debug.debugDrawLayoutNodes(dbg_lo.wid)

		love.graphics.pop()
	end

	if demo_zoom ~= 1.0 then
		love.graphics.setCanvas()

		love.graphics.push("all")

		love.graphics.translate(demo_canvas:getWidth() / 2, demo_canvas:getHeight() / 2)
		love.graphics.scale(demo_zoom, demo_zoom)
		love.graphics.translate(-context.mouse_x, -context.mouse_y)

		love.graphics.setBlendMode("alpha", "premultiplied")
		love.graphics.draw(demo_canvas, 0, 0)

		love.graphics.pop()
	end

	if draw_panel then
		dpanel:draw()

		local mx, my = love.mouse.getPosition()
		if dpanel_cool == 0 and dpanel.w < love.graphics.getWidth() and my > dpanel.y and my <= dpanel.y + dpanel.last_h + dpanel.y_pad*2 then
			if (dpanel_left and mx < dpanel.x + dpanel.w + dpanel.x_pad*2)
			or (not dpanel_left and mx >= dpanel.x)
			then
				dpanel_left = not dpanel_left
				dpanel_cool = dpanel_cool_max
				updateDPanelX(dpanel)
			end
		end
	end

	--[=[
	-- Debug: testing pooled resources
	local pools = context:getLua("core/res/pools")
	local aa, bb = pools.children:getCounters()
	love.graphics.print(aa .. ", " .. bb, 32, 600)
	--]=]

	demo_perf = love.graphics.getStats(demo_perf)
end
