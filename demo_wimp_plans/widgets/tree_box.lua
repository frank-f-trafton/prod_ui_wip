
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


local function _refreshTreeBox(self)
	self:orderItems()
	self:arrangeItems()
	self:cacheUpdate(true)
end


local rdo_item_align_h_action = function(self)
	local tb = self:findSiblingTag("demo_treebox")
	if tb then
		tb:setItemAlignment(self.usr_item_align_h)
		_refreshTreeBox(tb)
	end
end


function plan.make(panel)
	--title("TreeBox Test")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local tree_box = panel:addChild("wimp/tree_box")
	tree_box.skin_id = tree_box.skin_id .. "_DEMO"
	tree_box:initialize()
	demoShared.setStaticLayout(panel, tree_box, 0, 0, 224, 256)
	tree_box:setTag("demo_treebox")

	tree_box.wid_action = function(self, item, index)
		print("wid_action()", item, index)
	end
	tree_box.wid_action2 = function(self, item, index)
		print("wid_action2()", item, index)
	end
	tree_box.wid_action3 = function(self, item, index)
		print("wid_action3()", item, index)
	end
	tree_box.wid_select = function(self, item, index)
		print("wid_select()", item, index)
	end

	tree_box:setScrollBars(false, true)

	tree_box:reshape()

	tree_box:setIconsEnabled(true)
	tree_box:setExpandersActive(true)

	tree_box.MN_drag_scroll = true
	tree_box.MN_drag_select = true
	--tree_box.MN_drag_drop_mode = true

	-- (text, parent_node, tree_pos, icon_id)
	local node_top = tree_box:addNode("Top", nil, nil, "folder")
	node_top.expanded = true

	local node_mid = tree_box:addNode("Mid", node_top, nil, "folder")
	node_mid.expanded = true

	local node_bot = tree_box:addNode("Bottom", node_mid, nil, "folder")
	node_bot.expanded = false

	local back_to = tree_box:addNode("Back to top", nil, nil, "folder")
	back_to.expanded = false

	tree_box:orderItems()
	tree_box:arrangeItems()

	-- test marked item cleanup when toggling expanders
	--tree_box.MN_mark_mode = "toggle"

	local wx, wy, ww, wh = 256, 0, 256, 32

	demoShared.makeLabel(panel, wx, wy, ww, wh, "Item Horizontal Alignment", "single")

	wy = wy + wh

	local rdo_btn
	rdo_btn = panel:addChild("barebones/radio_button")
	rdo_btn:initialize()
	demoShared.setStaticLayout(panel, rdo_btn, wx, wy, ww, wh)
	rdo_btn.radio_group = "tb_item_h_align"
	rdo_btn:setLabel("left")
	rdo_btn.usr_item_align_h = "left"
	rdo_btn.wid_buttonAction = rdo_item_align_h_action

	wy = wy + wh

	rdo_btn = panel:addChild("barebones/radio_button")
	rdo_btn:initialize()
	demoShared.setStaticLayout(panel, rdo_btn, wx, wy, ww, wh)
	rdo_btn.radio_group = "tb_item_h_align"
	rdo_btn:setLabel("right")
	rdo_btn.usr_item_align_h = "right"
	rdo_btn.wid_buttonAction = rdo_item_align_h_action

	rdo_btn:setCheckedConditional("usr_item_align_h", tree_box.TR_item_align_h)

	wy = wy + wh
	wy = wy + wh

	local sld = panel:addChild("barebones/slider_bar")
	sld:initialize()
	demoShared.setStaticLayout(panel, sld, wx, wy, ww, wh)
	sld.trough_vertical = false
	sld:setLabel("Item Vertical Pad")
	sld.slider_pos = 0
	sld.slider_def = tree_box.skin.item_pad_v
	sld.slider_max = 64
	sld.wid_actionSliderChanged = function(self)
		local tb = self:findSiblingTag("demo_treebox")
		if tb then
			tb.skin.item_pad_v = math.floor(self.slider_pos)
			_refreshTreeBox(tb)
		end
	end

	wy = wy + wh

	local sld = panel:addChild("barebones/slider_bar")
	sld:initialize()
	demoShared.setStaticLayout(panel, sld, wx, wy, ww, wh)
	sld.trough_vertical = false
	sld:setLabel("Pipe width")
	sld.slider_pos = 0
	sld.slider_def = tree_box.skin.pipe_width
	sld.slider_max = 64
	sld.wid_actionSliderChanged = function(self)
		local tb = self:findSiblingTag("demo_treebox")
		if tb then
			tb.skin.pipe_width = math.floor(self.slider_pos)
			_refreshTreeBox(tb)
		end
	end

	wy = wy + wh
	wy = wy + wh


	local chk = panel:addChild("barebones/checkbox")
	chk:initialize()
	demoShared.setStaticLayout(panel, chk, wx, wy, ww, wh)
	chk:setLabel("Draw pipes")
	chk:setChecked(tree_box.skin.draw_pipes)
	chk.wid_buttonAction = function(self)
		local tb = self:findSiblingTag("demo_treebox")
		if tb then
			tb.skin.draw_pipes = not not self.checked
			_refreshTreeBox(tb)
		end
	end

	wy = wy + wh

	local chk = panel:addChild("barebones/checkbox")
	chk:initialize()
	demoShared.setStaticLayout(panel, chk, wx, wy, ww, wh)
	chk:setLabel("Draw icons")
	chk:setChecked(tree_box.TR_show_icons)
	chk.wid_buttonAction = function(self)
		local tb = self:findSiblingTag("demo_treebox")
		if tb then
			tb:setIconsEnabled(not not self.checked)
			_refreshTreeBox(tb)
		end
	end

	wy = wy + wh

	local chk = panel:addChild("barebones/checkbox")
	chk:initialize()
	demoShared.setStaticLayout(panel, chk, wx, wy, ww, wh)
	chk:setLabel("Expanders enabled")
	chk:setChecked(tree_box.TR_expanders_active)
	chk.wid_buttonAction = function(self)
		local tb = self:findSiblingTag("demo_treebox")
		if tb then
			tb:setExpandersActive(not not self.checked)
			_refreshTreeBox(tb)
		end
	end

	wy = wy + wh
end


return plan
