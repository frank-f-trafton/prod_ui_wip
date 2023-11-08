
-- ProdUI
local commonMenu = require("lib.prod_ui.logic.common_menu")
local uiLayout = require("lib.prod_ui.ui_layout")
local widShared = require("lib.prod_ui.logic.wid_shared")


local plan = {}


local function getDisplayInfo()

	local count = love.window.getDisplayCount()

	local displays = {}
	for i = 1, count do
		local display = {}; displays[i] = display
		display.name = love.window.getDisplayName(i)
		display.desktop_w, display.desktop_h = love.window.getDesktopDimensions(i)
		display.modes = love.window.getFullscreenModes(i)
	end

	return displays
end


local function makeLabel(content, x, y, w, h, text, label_mode)

	label_mode = label_mode or "single"

	local label = content:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:setLabel(text, label_mode)

	return label
end


local function swapItems(menu, index_1, index_2)

	local items = menu.items

	if index_1 < 1 or index_1 > #items or index_2 < 1 or index_2 > #items then
		return false
	end

	items[index_1], items[index_2] = items[index_2], items[index_1]
	return true
end


local function keyPressed_swapItems(self, key, scancode, isrepeat)

	local mods = self.context.key_mgr.mod
	local menu = self.menu

	if mods["ctrl"] then
		local dest_i = (key == "up") and menu.index - 1 or (key == "down") and menu.index + 1 or nil
		if dest_i and dest_i >= 1 and dest_i <= #menu.items then
			if menu:canSelect(dest_i) and menu:canSelect(menu.index) then
				swapItems(menu, menu.index, dest_i)
				menu:setSelectedIndex(dest_i)
				self:arrange()

				return true
			end
		end
	end
end



local function transferItem(item, from, to)

	-- XXX: Need to work on a solution for transferring menu items between widgets.
	-- As written, this won't preserve additional user data tied to the item.
	local new_item = to:addItem(item.text, nil, item.bijou_id)

	from:removeItem(item)
	to:setSelection(new_item)

	from:reshape()
	to:reshape()
end


local function wid_dropped(self, drop_state)

	-- * Only accept drop events with ID "menu" from demo_listbox3a or demo_listbox3b.
	-- * For this example, do not allow the ListBoxes to drop onto themselves.

	local from = drop_state.from
	local item = drop_state.item

	if drop_state.id == "menu"
	and from
	and self ~= from
	and (self.tag == "demo_listbox4a" or self.tag == "demo_listbox4b")
	and (from.tag == "demo_listbox4a" or from.tag == "demo_listbox4b")
	and from.menu:hasItem(item)
	then
		transferItem(item, from, self)

		return true
	end
end


local function makeListBox1(content, x, y)

	-- Apply a SkinDef patch to this ListBox so that we can modify its skin settings.
	local resources = content.context.resources
	local patch = resources:newSkinDef("list_box1")
	resources:registerSkinDef(patch, patch, false)
	resources:refreshSkinDef(patch)

	local list_box = content:addChild("wimp/list_box", {skin_id = patch})
	list_box:setTag("demo_listbox")

	list_box.wid_action = function(self, item, index)
		print("wid_action()", item, index)
	end
	list_box.wid_action2 = function(self, item, index)
		print("wid_action2()", item, index)
	end
	list_box.wid_action3 = function(self, item, index)
		print("wid_action3()", item, index)
	end
	list_box.wid_select = function(self, item, index)
		print("wid_select()", item, index)
	end

	list_box.x = x
	list_box.y = y
	list_box.w = 224
	list_box.h = 256

	list_box.show_icons = true

	list_box.drag_scroll = true
	list_box.drag_select = true
	--list_box.drag_reorder = true
	--list_box.drag_drop_mode = true

	list_box:setScrollBars(false, true)

	local displays = getDisplayInfo()
	local display1 = displays[1]
	if display1 then
		for i, mode in ipairs(display1.modes) do
			local item = list_box:addItem(mode.width .. "x" .. mode.height, nil, "icon_file")
			--[[
			item.res_w = mode.width
			item.res_h = mode.height
			--]]
		end
	end

	-- Test vertical scrolling.
	list_box:addItem("Add", nil, "icon_folder")
	list_box:addItem("Some", nil, "icon_folder")
	list_box:addItem("More", nil, "icon_folder")
	list_box:addItem("Items", nil, "icon_folder")
	list_box:addItem("To", nil, "icon_folder")
	list_box:addItem("Activate", nil, "icon_folder")
	list_box:addItem("Vertical", nil, "icon_folder")
	list_box:addItem("Scrolling", nil, "icon_folder")

	-- Test items that are wider than the viewport.
	--[[
	for i = 1, 24 do
		list_box:addItem("foo", nil, "icon_file")
		list_box:addItem("bar", nil, "icon_folder")
		list_box:addItem("baz")
		list_box:addItem("|||bopbopbopbopbopbopbopbopbopbopbopbop")
	end
	--]]
	-- [[
	-- Test removeItem
	do
		local item1 = list_box:addItem("Remove me.", 1)
		list_box:setSelectionByIndex(4)
		list_box:removeItem(item1)
	end
	--]]
	list_box:reshape()

	local rdo_align_action = function(self)
		local lb = self:findSiblingTag("demo_listbox")
		if lb then
			lb.skin.text_align_h = self.usr_align
			lb:reshape()
		end
	end

	local wx, wy, ww, wh = x + 256, y + 0, 128, 32
	makeLabel(content, wx, wy, ww, wh, "Text Alignment", "single")

	wy = wy + wh

	local rdo_btn
	rdo_btn = content:addChild("barebones/radio_button")
	rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
	rdo_btn.radio_group = "lb_text_align"
	rdo_btn:setLabel("left")
	rdo_btn.usr_align = "left"
	rdo_btn.wid_buttonAction = rdo_align_action

	wy = wy + wh

	rdo_btn = content:addChild("barebones/radio_button")
	rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
	rdo_btn.radio_group = "lb_text_align"
	rdo_btn:setLabel("center")
	rdo_btn.usr_align = "center"
	rdo_btn.wid_buttonAction = rdo_align_action

	wy = wy + wh

	rdo_btn = content:addChild("barebones/radio_button")
	rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
	rdo_btn.radio_group = "lb_text_align"
	rdo_btn:setLabel("right")
	rdo_btn.usr_align = "right"
	rdo_btn.wid_buttonAction = rdo_align_action

	rdo_btn:setCheckedConditional("usr_align", list_box.skin.text_align_h)

	wy = wy + wh
	wy = wy + wh

	local chk = content:addChild("barebones/checkbox")
	chk.x, chk.y, chk.w, chk.h = wx, wy, ww, wh
	chk:setChecked(list_box.show_icons)
	chk:setLabel("Icons")
	chk.wid_buttonAction = function(self)
		local lb = self:findSiblingTag("demo_listbox")
		if lb then
			lb.skin["$pad_text_x"] = self.slider_pos
			lb.show_icons = not not self.checked
			lb:reshape()
		end
	end


	wy = wy + wh
	wy = wy + math.floor(wh/2)

	makeLabel(content, wx, wy, ww, wh, "Icon Side", "single")

	wy = wy + wh

	local rdo_icon_side_action = function(self)
		local lb = self:findSiblingTag("demo_listbox")
		if lb then
			lb.skin.icon_side = self.usr_icon_side
			lb:reshape()
		end
	end

	rdo_btn = content:addChild("barebones/radio_button")
	rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
	rdo_btn.radio_group = "lb_icon_side"
	rdo_btn:setLabel("left")
	rdo_btn.usr_icon_side = "left"
	rdo_btn.wid_buttonAction = rdo_icon_side_action

	wy = wy + wh

	rdo_btn = content:addChild("barebones/radio_button")
	rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
	rdo_btn.radio_group = "lb_icon_side"
	rdo_btn:setLabel("right")
	rdo_btn.usr_icon_side = "right"
	rdo_btn.wid_buttonAction = rdo_icon_side_action

	rdo_btn:setCheckedConditional("usr_icon_side", list_box.skin.icon_side)

	wy = wy + wh
	wy = wy + math.floor(wh/2)

	makeLabel(content, wx, wy, ww, wh, "skin.pad_text_x (left/right align)")
	local sld = content:addChild("base/slider_bar")

	wy = wy + wh

	sld.x, sld.y, sld.w, sld.h = wx, wy, ww, wh

	sld.slider_pos = 0
	sld.slider_max = 64

	sld.round_policy = "nearest"
	sld.count_reverse = false
	sld.wheel_dir = 1

	sld.wid_actionSliderChanged = function(self)
		local lb = self:findSiblingTag("demo_listbox")
		if lb then
			lb.skin["$pad_text_x"] = self.slider_pos
			self.context.resources:refreshSkinDef(lb.skin)
			lb:reshape()
		end
	end

	sld:setSliderPosition(list_box.skin["$pad_text_x"])

	sld:reshape()
end


local function makeListBox2(content, x, y)

	local list_box = content:addChild("wimp/list_box")
	list_box:setTag("demo_listbox2")

	list_box.wid_action = function(self, item, index) print("[2] wid_action()", item, index) end
	list_box.wid_action2 = function(self, item, index) print("[2] wid_action2()", item, index) end
	list_box.wid_action3 = function(self, item, index) print("[2] wid_action3()", item, index) end
	list_box.wid_select = function(self, item, index) print("[2] wid_select()", item, index) end

	list_box.x = x
	list_box.y = y
	list_box.w = 224
	list_box.h = 256

	list_box.show_icons = true

	list_box.drag_scroll = true
	--list_box.drag_select = true
	list_box.drag_reorder = true
	--list_box.drag_drop_mode = true

	list_box:setScrollBars(false, true)

	list_box:addItem("Drag / ctrl+arrows")
	list_box:addItem("to reorder items.")
	list_box:addItem("The")
	list_box:addItem("quick")
	list_box:addItem("brown")
	list_box:addItem("dog")
	list_box:addItem("jumps")
	list_box:addItem("over")
	list_box:addItem("the")
	list_box:addItem("lazy")
	list_box:addItem("fox")

	list_box.wid_keyPressed = keyPressed_swapItems
	list_box:reshape()
end


local function makeListBox3(content, x, y)

	local lb1 = content:addChild("wimp/list_box")
	lb1:setTag("demo_listbox3a")

	lb1.wid_action = function(self, item, index) print("[3a] wid_action()", item, index) end
	lb1.wid_action2 = function(self, item, index) print("[3a] wid_action2()", item, index) end
	lb1.wid_action3 = function(self, item, index) print("[3a] wid_action3()", item, index) end
	lb1.wid_select = function(self, item, index) print("[3a] wid_select()", item, index) end

	lb1.x = x
	lb1.y = y
	lb1.w = 224
	lb1.h = 256

	lb1.show_icons = true

	lb1.drag_scroll = true
	lb1.drag_select = true
	--lb1.drag_reorder = true
	--lb1.drag_drop_mode = true

	lb1:addItem("One (Mark test (Toggle))")
	lb1:addItem("Two")
	lb1:addItem("Three")
	lb1:addItem("Four")
	lb1:addItem("Five")

	lb1.mark_mode = "toggle" -- false, "toggle", "cursor"

	lb1:setScrollBars(false, true)

	lb1:reshape()


	local lb2 = content:addChild("wimp/list_box")
	lb2:setTag("demo_listbox3b")

	lb2.wid_action = function(self, item, index) print("[3b] wid_action()", item, index) end
	lb2.wid_action2 = function(self, item, index) print("[3b] wid_action2()", item, index) end
	lb2.wid_action3 = function(self, item, index) print("[3b] wid_action3()", item, index) end
	lb2.wid_select = function(self, item, index) print("[3b] wid_select()", item, index) end

	lb2.x = x + 320
	lb2.y = y
	lb2.w = 224
	lb2.h = 256

	lb2.show_icons = true

	lb2.drag_scroll = true
	lb2.drag_select = true
	--lb2.drag_reorder = true
	--lb2.drag_drop_mode = true

	lb2:addItem("One (Shift/Ctrl+Click)")
	lb2:addItem("Two")
	lb2:addItem("Three")
	lb2:addItem("Four")
	lb2:addItem("Five")

	lb2.mark_mode = "cursor" -- false, "toggle", "cursor"

	lb2:setScrollBars(false, true)

	lb2:reshape()
end


local function makeListBox4(content, x, y)

	local lb1 = content:addChild("wimp/list_box")
	lb1:setTag("demo_listbox4a")

	lb1.wid_action = function(self, item, index) print("[4a] wid_action()", item, index) end
	lb1.wid_action2 = function(self, item, index) print("[4a] wid_action2()", item, index) end
	lb1.wid_action3 = function(self, item, index) print("[4a] wid_action3()", item, index) end
	lb1.wid_select = function(self, item, index) print("[4a] wid_select()", item, index) end

	lb1.x = x
	lb1.y = y
	lb1.w = 224
	lb1.h = 256

	lb1.show_icons = true

	lb1.drag_scroll = true
	lb1.drag_select = true
	--lb1.drag_reorder = true
	lb1.drag_drop_mode = true
	lb1.wid_dropped = wid_dropped

	lb1:addItem("Drag (Left)")
	lb1:addItem("A")
	lb1:addItem("B")
	lb1:addItem("C")
	lb1:addItem("D")

	--lb1.mark_mode = "cursor" -- false, "toggle", "cursor"

	lb1:setScrollBars(false, true)

	lb1:reshape()

	local b1 = content:addChild("base/button")
	b1.x = lb1.x + lb1.w + 32
	b1.y = lb1.y
	b1.w = 32
	b1.h = 32

	b1:setLabel(">")

	b1.wid_buttonAction = function(self)

		local l1 = self:findSiblingTag("demo_listbox4a")
		local l2 = self:findSiblingTag("demo_listbox4b")

		if l1 and l2 then
			local item = l1.menu.items[l1.menu.index]
			if item then
				transferItem(item, l1, l2)
			end
		end
	end

	b1:reshape()


	local b2 = content:addChild("base/button")
	b2.x = lb1.x + lb1.w + 32
	b2.y = lb1.y + lb1.h - 32
	b2.w = 32
	b2.h = 32

	b2:setLabel("<")

	b2.wid_buttonAction = function(self)

		local l1 = self:findSiblingTag("demo_listbox4a")
		local l2 = self:findSiblingTag("demo_listbox4b")

		if l1 and l2 then
			local item = l2.menu.items[l2.menu.index]
			if item then
				transferItem(item, l2, l1)
			end
		end
	end

	b2:reshape()


	local lb2 = content:addChild("wimp/list_box")
	lb2:setTag("demo_listbox4b")

	lb2.wid_action = function(self, item, index) print("[4b] wid_action()", item, index) end
	lb2.wid_action2 = function(self, item, index) print("[4b] wid_action2()", item, index) end
	lb2.wid_action3 = function(self, item, index) print("[4b] wid_action3()", item, index) end
	lb2.wid_select = function(self, item, index) print("[4b] wid_select()", item, index) end

	lb2.x = x + 320
	lb2.y = y
	lb2.w = 224
	lb2.h = 256

	lb2.show_icons = true

	lb2.drag_scroll = true
	lb2.drag_select = true
	--lb2.drag_reorder = true
	lb2.drag_drop_mode = true
	lb2.wid_dropped = wid_dropped

	lb2:addItem("Drag (right)")
	lb2:addItem("E")
	lb2:addItem("F")
	lb2:addItem("G")
	lb2:addItem("H")

	--lb2.mark_mode = "cursor" -- false, "toggle", "cursor"

	lb2:setScrollBars(false, true)

	lb2:reshape()
end


function plan.make(parent)

	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("ListBox Test")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, true)

		makeListBox1(content, 0, 0)
		makeListBox2(content, 0, 320)
		makeListBox3(content, 0, 640)
		makeListBox4(content, 0, 960)
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan

