require("lib.test.strict")


local demoShared = require("demo_shared")
local inspect = require("lib.test.inspect")


print("Start WIMP Demo.")


-- The first panel to load.
local demo_panel_launch = {
	"demo_welcome",
	--"wimp_divider",
	--"text_box_single",
	--"number_box",
	--"demo_main",
	--"button_split",
	--"dial",
	--"properties_box",
	--"wimp_list_box",
	--"wimp_tree_box",
	--"wimp_workspaces",
}


-- Upon starting the demo, all of these Window Frame plans are instantiated.
local demo_window_launch = {
	--"window_frames.frame_unselectable",
	--"window_frames.wimp_frame",
	--"window_frames.wimp_menu_tab",
}


local demo_plan_list = {
	nodes = {
		{plan_id = "demo_welcome", label = "Welcome"},
		{plan_id = "widgets", label = "Widgets", nodes = {
			{label = "Controls", nodes = {
				{plan_id = "button_work", label = "Button work"},
				{plan_id = "button_split", label = "Split Button"},
				{plan_id = "slider_work", label = "Slider work"},
				{plan_id = "stepper", label = "Stepper"},
				{plan_id = "demo_main", label = "Main Demo Window"},
				{plan_id = "wimp_divider", label = "Dividers"},
				{plan_id = "number_box", label = "Number Box"},
				{plan_id = "properties_box", label = "Properties Box"},
				{plan_id = "combo_box", label = "Combo Box"},
				{plan_id = "dropdown_box", label = "Dropdown Box"},
				{plan_id = "text_box_single", label = "Textbox (Single-Line)"},
				{plan_id = "text_box_multi", label = "Textbox (Multi-Line)"},
				{plan_id = "button_skinners", label = "Button Skinners"},
				{plan_id = "barebones", label = "Barebones Widgets"},
				{plan_id = "wimp_tree_box", label = "Tree Box"},
				{plan_id = "wimp_list_box", label = "List Box"},
			}},
			{label = "Informational", nodes = {
				{plan_id = "progress_bar", label = "Progress Bar"},
				{plan_id = "label_test", label = "Label test"},
				-- text blocks
			}},
			{label = "Containers", nodes = {
				{plan_id = "root", label = "Root Widget"},
				{plan_id = "container_work", label = "Container work"},
			}},
		}},
		{label = "UI Frames", nodes = {
			{plan_id = "wimp_workspaces", label = "Workspace Frames"},
		}},
		{label = "Testing; Unfinished Work", nodes = {
			{plan_id = "drag_box", label = "Drag Box"},
			{plan_id = "dial", label = "Dials"},
			{plan_id = "menu_test", label = "Menu Test"},
		}},
	}
}



-- Setting up a ProdUI project:

--[[
1) LÖVE Text Input should start in a disabled state, and it should not be changed by user code while the ProdUI
context is active. Widgets will toggle this on and off as they take and release the thimble (the ProdUI keyboard focus).
If we leave it on all the time, there is a chance that keystrokes will generate conflicting keypressed and textinput
events. ProdUI discards any love.textinput events while love.keyboard.hasTextInput() is false, and we can prevent
conflicts by only turning on TextInput when it's needed.

Here is one example of a conflict: User selects a command in a menu by pressing the space bar. The keypressed event
callback processes the command, closes the menu, and moves keyboard focus to a text box. Then, the textinput event
callback sends " " to the text box. The second action is undesired. However, if TextInput wasn't on while the menu had
focus, then the " " textinput event wouldn't fire in the first place.
--]]


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


-- Libs: ProdUI
local commonMath = require("prod_ui.common.common_math")
local commonWimp = require("prod_ui.common.common_wimp")
local itemOps = require("prod_ui.common.item_ops")
local keyMgr = require("prod_ui.lib.key_mgr")
local uiContext = require("prod_ui.ui_context")
local uiGraphics = require("prod_ui.ui_graphics")
local uiRes = require("prod_ui.ui_res")


local _lerp = commonMath.lerp


-- Libs: QuickPrint / DebugPanel
local debugPanel = require("lib.debug_panel")


local dpanel = debugPanel.new(320, love.graphics.getFont()) -- the font will be updated later.
local dpanel_side_pad = 32
dpanel.x = dpanel_side_pad
dpanel.y = 40
local dpanel_left = true
local dpanel_cool = 0
local dpanel_cool_max = 0.33
local dpanel_tabs = {0, 24, 150}


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
	-- a buildup of rapidly-discarded fonts eating up RAM while pending
	-- release.
	if old_font then
		old_font:release()
		collectgarbage("collect")
		collectgarbage("collect")
	end

end
reloadFont()


-- / LÖVE Setup


local app_settings = require("prod_ui.default_settings")


local function newWimpContext()
	local context = uiContext.newContext("prod_ui", app_settings)

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

		-- outlines one widget's rectangular area in love.draw()
		dbg_outline = {
			active = false,
			wid = false,
			line_w = 2.0,
			line_style = "rough",
			-- line
			r = 0.9, g = 0.1, b = 0.1, a = 1.0,
			-- fill
			r2 = 1.0, g2 = 0.0, b2 = 0.0, a2 = 0.125
		},

		-- Shows the widget's viewport rectangles in love.draw()
		dbg_vp = {
			active = false,
			wid = false
		},

		-- Shows the widget's layout nodes in love.draw()
		dbg_ly = {
			active = false,
			wid = false
		}
	}

	-- Assign resources ASAP.
	local theme_module = uiRes.loadLuaFileWithPath("prod_ui/themes/vacuum/vacuum.lua", context)
	context.resources = theme_module.newInstance(1.0)

	context:loadSkinnersInDirectory("prod_ui/skinners", true, "")
	context:loadWidgetDefsInDirectory("prod_ui/widgets", true, "", false)
	context.resources:loadSkinDefs("prod_ui/themes/vacuum/skins", true)

	local wid_root = context:addRoot("wimp/root_wimp")
	wid_root.w, wid_root.h = love.graphics.getDimensions()
	wid_root:initialize()

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


do
	do
		-- Construct the application menu bar.
		local bar_menu = wimp_root:addChild("wimp/menu_bar")
		bar_menu:initialize()

		-- [[
		local node = wimp_root.layout_tree:newNode()
		node:setMode("slice", "px", "top", 32)
		wimp_root:setLayoutNode(bar_menu, node)
		--]]

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


		local def_demo = {
			{
				type = "command",
				text = "Demo Config",
				callback = function(client, item)
					local root = client:getRootWidget()
					if root then
						demoShared.launchWindowFrameFromPlan(root, "window_frames.demo_config", true)
					end
				end,
			},
			{
				type = "command",
				text = "Widget Tree View",
				callback = function(client, item)
					local root = client:getRootWidget()
					if root then
						demoShared.launchWindowFrameFromPlan(root, "window_frames.wimp_widget_tree", true)
					end
				end,
			},
			{
				type = "command",
				text = "Window Frame Selector",
				callback = function(client, item)
					local root = client:getRootWidget()
					if root then
						demoShared.launchWindowFrameFromPlan(root, "window_frames.window_frame_selector", true)
					end
				end,
			},
		}
		bar_menu:appendItem("category", {
			text = "Demo",
			pop_up_def = def_demo,
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

		bar_menu:arrangeItems()
		bar_menu:menuChangeCleanup()

		bar_menu.sort_id = 6

		-- Hook application-level shortcuts to WIMP root
		do
			local shortcuts = {
				["C+q"] = function(self, key, scancode, isrepeat) love.event.quit() end,
			}
			local hook_pressed = function(self, tbl, key, scancode, isrepeat)
				local key_mgr = self.context.key_mgr
				local mod = key_mgr.mod

				local input_str = keyMgr.getKeyString(mod["ctrl"], mod["shift"], mod["alt"], mod["gui"], false, key)
				if shortcuts[input_str] then
					shortcuts[input_str](self, key, scancode, isrepeat)
					return true
				end
			end

			table.insert(wimp_root.hooks_trickle_key_pressed, hook_pressed)
		end

		-- Hook menu bar key commands to WIMP root
		do
			table.insert(wimp_root.hooks_key_pressed, bar_menu.widHook_pressed)
			table.insert(wimp_root.hooks_key_released, bar_menu.widHook_released)
		end


		-- Test sneaking a button into a menu bar.
		--[[
		local bar_button = bar_menu:addChild("base/button")

		bar_button.w = bar_menu.h - 4
		bar_button.x = bar_menu.w - bar_button.w + 2
		bar_button.h = 2
		bar_button.h = bar_button.w

		bar_button.can_have_thimble = false

		bar_button:initialize()
		--]]
	end


	do
		local ws1 = wimp_root:newWorkspace()
		ws1:initialize()
		-- NOTE: Do not register Workspaces to the root layout. Internally, the root takes care of positioning and
		-- reshaping the current active Workspace.
		wimp_root:setActiveWorkspace(ws1)
		ws1.tag = "main_workspace"

		local demo_list = ws1:addChild("wimp/tree_box")
		demo_list:initialize()

		-- [[
		local node = ws1.layout_tree:newNode()
		node:setMode("slice", "px", "left", 300)
		ws1:setLayoutNode(demo_list, node)
		--]]

		-- XYZ: put a sash here.

		demo_list.tag = "plan_menu"


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
					wid:remove()
				end
			until not wid

			local plan_container = workspace:addChild("base/container")
			plan_container:initialize()
			workspace:setLayoutNode(plan_container, workspace.layout_tree)
			plan_container.tag = "plan_container"

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
		for i, item in ipairs(plan_list.items) do
			if item.plan_id == panel_id then
				plan_list:setSelection(item)
				break
			end
		end
	end

	for i, window_id in ipairs(demo_window_launch) do
		demoShared.launchWindowFrameFromPlan(wimp_root, window_id, true)
	end

	-- TODO: need to deal with initial sort state, so that Workspaces don't obscure Window Frames.
	wimp_root:sortG2()

	-- Start with the top-most window selected, if any.
	wimp_root:selectTopFrame()

	-- Refresh everything.
	wimp_root:reshape()
	--wimp_root:reshape()
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
	qp:down()
	collectgarbage("collect"); collectgarbage("collect")
	qp:write("Mem (MB): ", collectgarbage("count") / 1024)
	--]]

	qp:print("GPU Stats:")
	if not demo_perf or not next(demo_perf) then
		qp:print("", "(waiting for stats)")
	else
		qp:print("", "drawcallsbatched: ", demo_perf.drawcallsbatched)
		qp:print("", "shaderswitches: ", demo_perf.shaderswitches)
		qp:print("", "fonts: ", demo_perf.fonts)


		if love_major < 12 then
			qp:print("", "canvases: ", demo_perf.canvases)
			qp:print("", "images: ", demo_perf.images)
		else
			qp:print("", "textures: ", demo_perf.textures)
		end
		qp:print("", "drawcalls: ", demo_perf.drawcalls)
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

	-- Debug-outline
	local outline = context.app.dbg_outline
	if outline.active and outline.wid and not outline.wid._dead then
		local wid = outline.wid

		love.graphics.push("all")

		love.graphics.setColor(outline.r, outline.g, outline.b, outline.a)
		love.graphics.setLineStyle(outline.line_style)
		love.graphics.setLineWidth(outline.line_w)
		local wx, wy = wid:getAbsolutePosition()
		love.graphics.rectangle("line", wx + 0.5, wy + 0.5, wid.w - 1, wid.h - 1)
		love.graphics.setColor(outline.r2, outline.g2, outline.b2, outline.a2)
		love.graphics.rectangle("fill", wx, wy, wid.w, wid.h)

		love.graphics.pop()
	else
		outline.wid = false
	end
	local dbg_vp = context.app.dbg_vp
	if dbg_vp and dbg_vp.active and dbg_vp.wid and not dbg_vp.wid._dead then
		love.graphics.push("all")

		local widShared = context:getLua("core/wid_shared")
		local wid = dbg_vp.wid
		love.graphics.translate(wid:getAbsolutePosition())
		if dbg_vp.wid.vp_x then
			widShared.debug.debugDrawViewport(dbg_vp.wid, 1)
		end
		for i = 2, 8 do
			if dbg_vp.wid["vp" .. i .. "_x"] then
				widShared.debug.debugDrawViewport(dbg_vp.wid, i)
			end
		end

		love.graphics.pop()
	end

	local dbg_ly = context.app.dbg_ly
	if dbg_ly and dbg_ly.active and dbg_ly.wid and not dbg_ly.wid._dead and dbg_ly.wid.layout_tree then
		love.graphics.push("all")

		local widShared = context:getLua("core/wid_shared")
		local wid = dbg_ly.wid
		love.graphics.translate(wid:getAbsolutePosition())
		love.graphics.translate(-wid.scr_x, -wid.scr_y)
		widShared.debug.debugDrawLayoutNodes(dbg_ly.wid.layout_tree, 1)

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

	demo_perf = love.graphics.getStats(demo_perf)
end
