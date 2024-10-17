
--[[
	A window frame with a text widget that is updated at intervals to show the current widget tree.
--]]


-- ProdUI
local commonWimp = require("prod_ui.logic.common_wimp")
local dbg = require("prod_ui.debug.dbg")
--local itemOps = require("prod_ui.logic.item_ops")
--local keyCombo = require("prod_ui.lib.key_combo")
local uiLayout = require("prod_ui.ui_layout")


local plan = {}


local function _deleteLoop(node)
	print("_deleteLoop() start", node)
	for i = #node.nodes, 1, -1 do
		local child_node = node.nodes[i]
		child_node.usr_wid = nil
		_deleteLoop(child_node)
		node:removeNode(i)
	end
	print("_deleteLoop() end", node)
end


local function _widgetToString(wid, n, thimble)
	return "[" .. n .. "] " .. wid.id .. " (" .. tostring(wid) .. ")" .. (wid == thimble and "*" or "")
end


local function _buildLoop(tree_box, node, root, thimble)
	print("_buildLoop() start", tree_box, root, thimble)
	print(#root.children)
	for i, child in ipairs(root.children) do
		local n1 = tree_box:addNode(_widgetToString(child, i, thimble), node)
		n1.usr_wid = child
		_buildLoop(tree_box, n1, child, thimble)
	end
	print("_buildLoop() end")
end


local function _buildTree(tree_box, root)
	print("_buildTree() start")
	assert(type(root) == "table" and not root._dead, "root widget is dead or corrupt")

	-- TODO: Try preserving existing node tables at update intervals.

	-- Note the last selection and the UI thimble.
	local item_selected = tree_box.menu:getSelectedItem()
	local wid_selected = item_selected and item_selected.usr_wid
	item_selected = nil
	local thimble = tree_box.context.current_thimble

	print(wid_selected, thimble)

	tree_box.tree.usr_wid = root
	tree_box.tree.text = _widgetToString(root, 1, thimble)
	_deleteLoop(tree_box.tree)
	_buildLoop(tree_box, tree_box.tree, root, thimble)

	tree_box:orderItems()
	tree_box:arrange()

	-- Restore the selection, if any.
	if wid_selected then
		for i, item in ipairs(tree_box.menu.items) do
			if item.usr_wid == wid_selected then
				tree_box.menu:setSelectedIndex(i)
				break
			end
		end
	end
	print("_buildTree() end")
end


local function tree_userUpdate(self, dt)
	local context = self.context
	local root = self:getTopWidgetInstance()

	if root then
		self.usr_timer = self.usr_timer - dt
		if self.usr_timer <= 0 then
			self.usr_timer = self.usr_timer_max
			_buildTree(self, root)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:reshape(true)
			end

			local outline = context.app.dbg_outline
			if outline then
				outline.wid = false
				local selected = self.menu:getSelectedItem()
				if selected and selected.usr_wid then
					outline.wid = selected.usr_wid
				end
			end
		end
	end
end


function plan.make(root)
	local context = root.context

	local frame = root:addChild("wimp/window_frame")

	frame.w = 400--640
	frame.h = 384--500

	frame:setFrameTitle("Widget Tree")

	local header_b = frame:findTag("frame_header")
	if header_b then
		header_b.condensed = true
	end

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		local tree_box = content:addChild("wimp/tree_box")

		tree_box:setExpandersActive(true)

		tree_box.lc_func = uiLayout.fitRemaining
		uiLayout.register(content, tree_box)

		tree_box.x = 0
		tree_box.y = 0
		tree_box.w = 224
		tree_box.h = 256

		tree_box:setScrollBars(false, true)

		tree_box:reshape()

		--tree_box:setIconsEnabled(true)
		--tree_box:setExpandersActive(true)

		tree_box.drag_scroll = true
		tree_box.drag_select = true
		--tree_box.drag_reorder = true
		--tree_box.drag_drop_mode = true

		-- User code
		tree_box.usr_timer_max = 0.5
		tree_box.usr_timer = tree_box.usr_timer_max
		tree_box.userUpdate = tree_userUpdate
	end

	frame:reshape(true)

	return frame
end


return plan
