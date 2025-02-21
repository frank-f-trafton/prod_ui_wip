require("lib.test.strict")

print("Start WIMP Demo.")


-- Plans to launch upon starting the demo.
local demo_quick_launch = {
	--"plan_wimp_workspaces",
	--"plan_frame_unselectable",
	--"plan_dial",
	--"plan_wimp_menu_tab",
	--"plan_wimp_frame",
	--"plan_demo_main",
	--"plan_properties_box",
	--"plan_button_split",
	--"plan_wimp_tree_box",
	--"plan_wimp_list_box",
}


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


local love_major = love.getVersion()


--[[
local oldPrint = print
print = function(...)
	oldPrint(...)
	oldPrint(debug.traceback())
end
--]]


-- Libs: ProdUI
local commonWimp = require("prod_ui.common.common_wimp")
local itemOps = require("prod_ui.common.item_ops")
local keyMgr = require("prod_ui.lib.key_mgr")
local uiContext = require("prod_ui.ui_context")
local uiGraphics = require("prod_ui.ui_graphics")
local uiLayout = require("prod_ui.ui_layout")
local uiRes = require("prod_ui.ui_res")
local widDebug = require("prod_ui.common.wid_debug")
local widShared = require("prod_ui.common.wid_shared")

-- Libs: QuickPrint
local quickPrint = require("lib.quick_print") -- (Helps with debug-printing to the framebuffer.)
local qp = quickPrint.new()


-- * Demo State *


local demo_perf -- assigned at the end of love.draw


-- * / Demo State *


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


-- WIMP config/settings. Eventually, this will be placed in a separate file.
local wimp_settings = {
	wimp = {
		key_bindings = {
			close_window_frame = "C+w",
		},

		navigation = {
			-- Scroll animation parameters. See: widShared.scrollTargetUpdate()
			scroll_snap = 1,
			scroll_speed_min = 800,
			scroll_speed_mul = 8.0,

			-- How many pixels to scroll in WIMP widgets when pressing the arrow
			-- keys.
			key_scroll_h = 32,

			-- How many pixels to scroll per one discrete mouse-wheel motion event.
			-- XXX: SDL3 / LÖVE 12 is changing this to distance scrolled.
			-- XXX: for now, this is also used with horizontal wheel movement. As of
			-- this writing, I don't have a mouse with a horizontal wheel.
			mouse_wheel_move_size_v = 64,

			-- How much of a "page" to jump when pressing pageup or pagedown in a
			-- menu. 1.0 is one whole span of the viewport, 0.5 is half, etc.
			page_viewport_factor = 1.0,
		},

		pop_up_menu = {
			-- When clicking off of a pop-up menu, stops the user from clicking
			-- any other widget that is behind the base menu.
			-- May prevent accidental clicks, though some people (ahem) hate it.
			block_1st_click_out = false,
		}
	}
}


local function newWimpContext()
	local context = uiContext.newContext("prod_ui", wimp_settings)



	-- Config/settings specific to this demo.
	context.app = {
		show_details = true,
		show_perf = true,
		show_mouse_cross = false,

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
		-- widDebug.debugDrawViewport(self, v, r, g, b, a)
		dbg_vp = {
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
	local wid = commonWimp.getFrame(self)
	if not wid then
		print("Demo Error: couldn't locate ancestor frame")
	end

	return wid, header -- check the return values before accessing them
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


local function _launchSelector(root)
	local plan_name = "plan_demo_selection"
	local frame = root:findTag("FRAME:" .. plan_name)
	if not frame then
		local planDemoSelect = require(plan_name)
		frame = planDemoSelect.make(root)
		frame.tag = "FRAME:" .. plan_name
	end
	return frame
end


local function _launchWidgetTreeView(root)
	local plan_name = "plan_wimp_widget_tree"
	local frame = root:findTag("FRAME:" .. plan_name)
	if not frame then
		local planWidgetTreeView = require(plan_name)
		frame = planWidgetTreeView.make(root)
		frame.tag = "FRAME:" .. plan_name
	end

	return frame
end


do
	-- [[
	do
		local fr_demo_select = _launchSelector(wimp_root)
		-- Quick-launch frames here:
		for i, str in ipairs(demo_quick_launch) do
			local frame = fr_demo_select:launch(str)
			frame.x = 64 + (i-1) * 32
			frame.y = 64 + (i-1) * 32
		end
	end
	--]]


	do
		local bar_menu = wimp_root:addChild("wimp/menu_bar")
		bar_menu:initialize()

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
				text = "Open Selector",
				callback = function(client, item)
					local root = client:getRootWidget()
					if root then
						_launchSelector(root)
					end
				end,
			},
			{
				type = "command",
				text = "Widget Tree View",
				callback = function(client, item)
					local root = client:getRootWidget()
					if root then
						_launchWidgetTreeView(root)
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

		bar_menu.w = wimp_root.w
		bar_menu:resize()

		bar_menu:arrangeItems()
		bar_menu:reshape()
		bar_menu:menuChangeCleanup()

		bar_menu.sort_id = 6

		-- Hook application-level shortcuts to WIMP root
		do
			local shortcuts = {
				["KC q"] = function(self, key, scancode, isrepeat) love.event.quit() end,
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

		bar_button:initialize()
		bar_button:reshape()
		--]]
	end


	do
		local ws1 = wimp_root:newWorkspace()
		ws1:initialize()
		wimp_root:setActiveWorkspace(ws1)
		ws1.tag = "main_workspace"
	end


	--love.mouse.setGrabbed(true)
	--love.mouse.setRelativeMode(true)

	-- TODO: need to deal with initial sort state, so that Workspaces don't obscure Window Frames.
	wimp_root:sortG2()

	-- Start with the top-most window selected, if any.
	wimp_root:selectTopFrame()

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

	-- Crappy hack intended to demonstrate a toast system, without having yet
	-- written a proper toast system.
	local notif = context.app.notif
	notif.time = notif.time + dt
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

	context:draw(0, 0)

	love.graphics.setScissor()

	love.graphics.setColor(1, 1, 1, 1)

	local app = context.app

	if app.show_details then
		qp:reset()
		qp:setOrigin(PAD, love.graphics.getHeight() - 150)

		qp:print("current_hover:\t", context.current_hover)
		qp:print("current_pressed:\t", context.current_pressed)
		qp:print("thimble1:\t", context.thimble1)
		qp:print("thimble2:\t", context.thimble2)
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

	if app.show_perf then
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
		local text_h = notif.font:getHeight() * 6 -- Terrible.

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
		local wid = dbg_vp.wid
		love.graphics.translate(wid:getAbsolutePosition())
		if dbg_vp.wid.vp_x then
			widDebug.debugDrawViewport(dbg_vp.wid, 1)
		end
		for i = 2, 8 do
			if dbg_vp.wid["vp" .. i .. "_x"] then
				widDebug.debugDrawViewport(dbg_vp.wid, i)
			end
		end
	end
end
