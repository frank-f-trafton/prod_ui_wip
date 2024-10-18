
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


local function _deleteLoop(node, _collapsed)
	for i = #node.nodes, 1, -1 do
		local child_node = node.nodes[i]
		if not child_node.expanded then
			_collapsed[child_node.usr_wid] = child_node
		end
		_deleteLoop(child_node, _collapsed)
		node.nodes[i] = nil
	end
end


local function _widgetToString(wid, n, thimble)
	return "[" .. n .. "] " .. wid.id .. " (" .. tostring(wid) .. ")" .. (wid == thimble and "*" or "")
end


local function _buildLoop(tree_box, node, root, thimble, _collapsed)
	for i, child in ipairs(root.children) do
		local n1 = tree_box:addNode(_widgetToString(child, i, thimble), node)
		n1.usr_wid = child
		if _collapsed[child] then
			n1.expanded = false
		end
		_buildLoop(tree_box, n1, child, thimble, _collapsed)
	end
end


local function _buildTree(tree_box, root)
	assert(type(root) == "table" and not root._dead, "root widget is dead or corrupt")

	-- TODO: Try preserving existing node tables at update intervals.

	-- Note the last selection and the UI thimble.
	local item_selected = tree_box.menu:getSelectedItem()
	local wid_selected = item_selected and item_selected.usr_wid
	item_selected = nil
	local thimble = tree_box.context.current_thimble

	tree_box.tree.usr_wid = root
	tree_box.tree.text = _widgetToString(root, 1, thimble)
	local _collapsed = {}
	_deleteLoop(tree_box.tree, _collapsed)
	_buildLoop(tree_box, tree_box.tree, root, thimble, _collapsed)

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


local function tree_userDestroy(self)
	-- unsets the debug-outline reference
	local outline = self.context.app.dbg_outline
	if outline then
		outline.wid = false
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

		local chk_highlight = content:addChild("base/checkbox")
		chk_highlight:setLabel("Highlight Selected")
		chk_highlight:setChecked(content.context.app.dbg_outline.active)

		chk_highlight.wid_buttonAction = function(self)
			local outline = self.context.app.dbg_outline
			outline.active = not not self.checked
		end

		chk_highlight.h = 32
		chk_highlight.lc_func = uiLayout.fitBottom
		uiLayout.register(content, chk_highlight)


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

		tree_box.drag_scroll = true
		tree_box.drag_select = true

		-- User code
		tree_box.usr_timer_max = 0.5
		tree_box.usr_timer = tree_box.usr_timer_max
		tree_box.userUpdate = tree_userUpdate
		tree_box.userDestroy = tree_userDestroy
	end

	frame:reshape(true)

	return frame
end


return plan
