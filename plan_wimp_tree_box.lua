
-- ProdUI
--local uiLayout = require("prod_ui.ui_layout")
--local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(content, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = content:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:setLabel(text, label_mode)

	return label
end


local function _refreshTreeBox(self)
	self:orderItems()
	self:arrange()
	self:cacheUpdate(true)
end


local rdo_item_align_h_action = function(self)
	local tb = self:findSiblingTag("demo_treebox")
	if tb then
		tb.skin.item_align_h = self.usr_item_align_h
		_refreshTreeBox(tb)
	end
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("TreeBox Test")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, true)

		-- SkinDef clone
		local resources = content.context.resources
		local skin_defs = resources.skin_defs
		local clone = pTable.deepCopy(skin_defs["tree_box1"])
		resources:registerSkinDef(clone, clone)

		local function _userDestroy(self)
			self.context.resources:removeSkinDef(clone)
		end

		local tree_box = content:addChild("wimp/tree_box", {skin_id = clone, userDestroy = _userDestroy})
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

		tree_box.x = 0
		tree_box.y = 0
		tree_box.w = 224
		tree_box.h = 256

		tree_box:setScrollBars(false, true)

		tree_box:reshape()

		tree_box:setIconsEnabled(true)
		tree_box:setExpandersActive(true)

		tree_box.MN_drag_scroll = true
		tree_box.MN_drag_select = true
		--tree_box.MN_drag_drop_mode = true

		-- (text, parent_node, tree_pos, bijou_id)
		local node_top = tree_box:addNode("Top", nil, nil, "icon_folder")
		node_top.expanded = true

		local node_mid = tree_box:addNode("Mid", node_top, nil, "icon_folder")
		node_mid.expanded = true

		local node_bot = tree_box:addNode("Bottom", node_mid, nil, "icon_folder")
		node_bot.expanded = false

		local back_to = tree_box:addNode("Back to top", nil, nil, "icon_folder")
		back_to.expanded = false

		tree_box:orderItems()
		tree_box:arrange()

		-- test marked item cleanup when toggling expanders
		--tree_box.MN_mark_mode = "toggle"

		local wx, wy, ww, wh = 256, 0, 256, 32

		makeLabel(content, wx, wy, ww, wh, "Item Horizontal Alignment", "single")

		wy = wy + wh

		local rdo_btn
		rdo_btn = content:addChild("barebones/radio_button")
		rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
		rdo_btn.radio_group = "tb_item_h_align"
		rdo_btn:setLabel("left")
		rdo_btn.usr_item_align_h = "left"
		rdo_btn.wid_buttonAction = rdo_item_align_h_action

		wy = wy + wh

		rdo_btn = content:addChild("barebones/radio_button")
		rdo_btn.x, rdo_btn.y, rdo_btn.w, rdo_btn.h = wx, wy, ww, wh
		rdo_btn.radio_group = "tb_item_h_align"
		rdo_btn:setLabel("right")
		rdo_btn.usr_item_align_h = "right"
		rdo_btn.wid_buttonAction = rdo_item_align_h_action

		wy = wy + wh
		wy = wy + wh

		local sld = content:addChild("barebones/slider_bar", {x=wx, y=wy, w=ww, h=wh})
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

		local sld = content:addChild("barebones/slider_bar", {x=wx, y=wy, w=ww, h=wh})
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


		local chk = content:addChild("barebones/checkbox")
		chk.x, chk.y, chk.w, chk.h = wx, wy, ww, wh
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

		local chk = content:addChild("barebones/checkbox")
		chk.x, chk.y, chk.w, chk.h = wx, wy, ww, wh
		chk:setLabel("Draw icons")
		chk:setChecked(tree_box.TR_show_icons)
		chk.wid_buttonAction = function(self)
			local tb = self:findSiblingTag("demo_treebox")
			if tb then
				tb.TR_show_icons = not not self.checked
				_refreshTreeBox(tb)
			end
		end

		wy = wy + wh

		local chk = content:addChild("barebones/checkbox")
		chk.x, chk.y, chk.w, chk.h = wx, wy, ww, wh
		chk:setLabel("Expanders enabled")
		chk:setChecked(tree_box.TR_expanders_active)
		chk.wid_buttonAction = function(self)
			local tb = self:findSiblingTag("demo_treebox")
			if tb then
				tb.TR_expanders_active = not not self.checked
				_refreshTreeBox(tb)
			end
		end

		wy = wy + wh
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
