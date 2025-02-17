
--[[
	A window frame with a text widget that is updated at intervals to show the current widget tree.
--]]


-- ProdUI
local commonWimp = require("prod_ui.common.common_wimp")
local dbg = require("prod_ui.debug.dbg")
--local itemOps = require("prod_ui.common.item_ops")
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


local function _widgetToString(wid, n, thimble1, thimble2)
	return "[" .. n .. "] " .. wid.id .. " (" .. tostring(wid) .. ")"
		.. (wid == thimble1 and "(*)" or "")
		.. (wid == thimble2 and "(**)" or "")
end


local function _buildLoop(tree_box, node, root, thimble1, thimble2, _collapsed)
	for i, child in ipairs(root.children) do
		if not tree_box.parent.usr_exclude
		or tree_box.parent.usr_exclude and tree_box.parent.parent ~= child
		then
			local n1 = tree_box:addNode(_widgetToString(child, i, thimble1, thimble2), node)
			n1.usr_wid = child
			if _collapsed[child] then
				n1.expanded = false
			end
			_buildLoop(tree_box, n1, child, thimble1, thimble2, _collapsed)
		end
	end
end


local function _buildTree(tree_box, root)
	assert(type(root) == "table" and not root._dead, "root widget is dead or corrupt")

	-- TODO: Try preserving existing node tables at update intervals.

	-- Note the last selection and the UI thimbles.
	local context = tree_box.context
	local item_selected = tree_box:menuGetSelectedItem()
	local wid_selected = item_selected and item_selected.usr_wid

	tree_box.tree.usr_wid = root
	tree_box.tree.text = _widgetToString(root, 1, context.thimble1, context.thimble2)
	local _collapsed = {}
	_deleteLoop(tree_box.tree, _collapsed)
	_buildLoop(tree_box, tree_box.tree, root, context.thimble1, context.thimble2, _collapsed)

	tree_box:orderItems()
	tree_box:arrangeItems()

	-- Restore the selection, if any.
	local restored
	if wid_selected then
		for i, item in ipairs(tree_box.items) do
			if item.usr_wid == wid_selected then
				tree_box:menuSetSelectedIndex(i)
				restored = true
				break
			end
		end
	end
	if not restored then
		tree_box:menuSetSelectedIndex(0)
	end
end


local function tree_userUpdate(self, dt)
	local context = self.context
	local root = self:getRootWidget()

	if root then
		self.usr_timer = self.usr_timer - dt
		if self.usr_timer <= 0 then
			self.usr_timer = self.usr_timer_max
			_buildTree(self, root)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:reshape(true)
			end

			-- Debug view stuff for the demo.
			local selected = self:menuGetSelectedItem()
			local selected_wid = selected and selected.usr_wid or false

			local outline = context.app.dbg_outline
			if outline then
				outline.wid = selected_wid
			end
			local dbg_vp = context.app.dbg_vp
			if dbg_vp then
				dbg_vp.wid = selected_wid
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
	local dbg_vp = self.context.app.dbg_vp
	if dbg_vp then
		dbg_vp.wid = false
	end
end


function plan.make(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w = 400
	frame.h = 384
	frame:initialize()
	frame:setHeaderSize("small")
	frame:setFrameTitle("Widget Tree")

	frame.auto_layout = true
	frame:setScrollBars(false, false)

	local tree_box = frame:addChild("wimp/tree_box")
	tree_box:initialize()
	local chk_vp = frame:addChild("base/checkbox")
	chk_vp:initialize()
	local chk_highlight = frame:addChild("base/checkbox")
	chk_highlight:initialize()
	local chk_exclude = frame:addChild("base/checkbox")
	chk_exclude:initialize()

	chk_vp:setLabel("Show Viewports")
	chk_vp:setChecked(frame.context.app.dbg_vp.active)

	chk_vp.wid_buttonAction = function(self)
		local vp = self.context.app.dbg_vp
		vp.active = not not self.checked
	end

	chk_vp.h = 32
	chk_vp.lc_func = uiLayout.fitBottom


	chk_highlight:setLabel("Highlight Selected")
	chk_highlight:setChecked(frame.context.app.dbg_outline.active)

	chk_highlight.wid_buttonAction = function(self)
		local outline = self.context.app.dbg_outline
		outline.active = not not self.checked
	end

	chk_highlight.h = 32
	chk_highlight.lc_func = uiLayout.fitBottom


	chk_exclude:setLabel("Exclude this window frame")
	frame.usr_exclude = true
	chk_exclude:setChecked(frame.usr_exclude)

	chk_exclude.wid_buttonAction = function(self)
		self.parent.usr_exclude = not self.parent.usr_exclude
	end

	chk_exclude.h = 32
	chk_exclude.lc_func = uiLayout.fitBottom


	tree_box:setExpandersActive(true)

	tree_box.lc_func = uiLayout.fitRemaining

	uiLayout.register(frame, chk_exclude)
	uiLayout.register(frame, chk_highlight)
	uiLayout.register(frame, chk_vp)
	uiLayout.register(frame, tree_box)

	tree_box.x = 0
	tree_box.y = 0
	tree_box.w = 224
	tree_box.h = 256

	tree_box:setScrollBars(false, true)

	tree_box:reshape()

	tree_box.MN_drag_scroll = true
	tree_box.MN_drag_select = true

	-- User code
	tree_box.usr_timer_max = 0.5
	tree_box.usr_timer = tree_box.usr_timer_max
	tree_box.userUpdate = tree_userUpdate
	tree_box.userDestroy = tree_userDestroy
	-- Also reads 'self.parent.usr_exclude'

	frame:reshape(true)

	return frame
end


return plan
