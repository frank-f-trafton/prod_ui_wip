
-- ProdUI
local commonMenu = require("prod_ui.logic.common_menu")
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.logic.wid_shared")


local plan = {}


local function makeLabel(content, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = content:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:setLabel(text, label_mode)

	return label
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


		-- Apply a SkinDef patch to this TreeBox so that we can modify its skin settings.
		local resources = content.context.resources
		local patch = resources:newSkinDef("tree_box1")
		resources:registerSkinDef(patch, patch, false)
		resources:refreshSkinDef(patch)

		local tree_box = content:addChild("wimp/tree_box", {skin_id = patch})
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

		tree_box.drag_scroll = true
		tree_box.drag_select = true
		--tree_box.drag_reorder = true
		--tree_box.drag_drop_mode = true

		--(text, parent_node, tree_pos, bijou_id)
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
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
