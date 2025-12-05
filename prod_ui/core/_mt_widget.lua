-- ProdUI: Widget implementation.


local context = select(1, ...)


local _mt_widget = {}
_mt_widget.__index = _mt_widget
_mt_widget.context = context


-- For loading widget defs, see the UI Context source.


local coreErr = require(context.conf.prod_ui_req .. "core.core_err")
--local pools = context:getLua("core/res/pools")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local pTree = require(context.conf.prod_ui_req .. "lib.pile_tree")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


-- Pull in some methods from PILE Tree.
_mt_widget.nodeGetIndex = pTree.nodeGetIndex
_mt_widget.nodeAssertIndex = pTree.nodeAssertIndex
_mt_widget.nodeGetDepth = pTree.nodeGetDepth
_mt_widget._nodeAssertNoCycles = pTree.nodeAssertNoCycles
_mt_widget.nodeGetNext = pTree.nodeGetNext
_mt_widget.nodeGetPrevious = pTree.nodeGetPrevious
_mt_widget.nodeGetNextSibling = pTree.nodeGetNextSibling
_mt_widget.nodeGetPreviousSibling = pTree.nodeGetPreviousSibling
_mt_widget.nodeAssertParent = pTree.nodeAssertParent


-- In this case, we have a shortcut that isn't available to the generic tree code.
function _mt_widget:nodeGetRoot()
	return context.root
end


_mt_widget.nodeGetVeryLast = pTree.nodeGetVeryLast
_mt_widget.nodeForEach = pTree.nodeForEach
_mt_widget.nodeForEachBack = pTree.nodeForEachBack
_mt_widget.nodeHasThisAncestor = pTree.nodeHasThisAncestor
_mt_widget.nodeIsInLineage = pTree.nodeIsInLineage
_mt_widget.nodeFindKeyInChildren = pTree.nodeFindKeyInChildren
_mt_widget.nodeFindKeyDescending = pTree.nodeFindKeyDescending
_mt_widget.nodeFindKeyAscending = pTree.nodeFindKeyAscending


local function _errNoDescendants()
	error("widget is not configured to have descendants.", 2)
end


local _mt_no_descendants = {}
-- Unfortunately, table.insert() does not trigger __newindex in Lua 5.1, so this only handles part of the issue.
_mt_no_descendants.__newindex = function()
	_errNoDescendants()
end
setmetatable(_mt_no_descendants, _mt_no_descendants)


-- ID and tag strings
_mt_widget.id = "_ui_unknown"
_mt_widget.tag = ""


-- Dummy children table
_mt_widget.nodes = _mt_no_descendants


_mt_widget.x = 0
_mt_widget.y = 0
_mt_widget.w = 0
_mt_widget.h = 0


-- Scroll offsets. These apply to a widget's children (a `scr_x` of 50 would offset all of a widget's
-- children to the left by 50 pixels). They may also be used for offsetting built-in components (menu items, etc.).
_mt_widget.scr_x = 0
_mt_widget.scr_y = 0


-- Which thimble (if any) this widget is allowed to hold. 0: none, 1: thimble1, 2: thimble2.
_mt_widget.thimble_mode = 0


-- Affects ticking (evt_update, userUpdate), mouse events, and various kinds of selection (ie thimble handoff).
_mt_widget.awake = true


-- Affects drawing.
_mt_widget.draw_first = -math.huge
_mt_widget.draw_last = math.huge


-- Cursor codes
_mt_widget.cursor_hover = false
_mt_widget.cursor_press = false


-- Sorting variables.


-- Number of sorting IDs for a widget's children. Larger numbers require more memory allocation when sorting.
-- 0 == do not sort children.
_mt_widget.sort_max = 0


-- Default sorting ID / lane for widgets. Ranges from 1 to parent.sort_max (or n/a if sort_max is 0).
-- Sorting is performed at the sibling level. This value is unused for the root widget.
_mt_widget.sort_id = 1


-- Geometry fields.
-- For more info, see: core/wid_layout.lua


-- Default to "null" geometry mode.
_mt_widget.GE = widLayout.geo_null


--[[
The sorting order for a widget in a layout. Can be any number (besides NaN).

The default 'GE_order' is the widget's number of siblings plus one at its time of creation. This
default is sufficient for the common case of widgets being arranged in the same order in which they
were made. For more complicated situations, widgets can be ordered at the beginning or end of the
list by using negative numbers or very big numbers (bigger than the plausible number of siblings),
respectively.

If you specify custom 'GE_order' values at all in a layout, you must call 'wid:sortLayout()' in the
parent container afterwards.

The sorting order of widgets with the same 'GE_order' values is undefined.
--]]
_mt_widget.GE_order = 0


-- Outer padding for children in a layout.
_mt_widget.GE_outpad_x1, _mt_widget.GE_outpad_y1, _mt_widget.GE_outpad_x2, _mt_widget.GE_outpad_y2 = 0, 0, 0, 0


--[[
These fields are set in widLayout.setupLayoutList(). They apply to parents.

.LO_list: When a table, this specifies the order in which the widget's children should be laid out.
	All entries in this list must be direct children of the widget.

.LO_base: Enum that controls how a parent's layout space is reset.

.LO_x, .LO_y, .LO_w, .LO_h: Temporary layout space for parents.

.LO_margin_x1, .LO_margin_y1, .LO_margin_x2, .LO_margin_y2: Layout margin for parents.

.LO_grid_rows, .LO_grid_cols: The number of columns and rows in a parent's grid.
--]]


-- Default canvas stack parameters. (See: ui_draw.lua)


-- Activates layering for this widget and its descendants.
_mt_widget.ly_enabled = false


-- RGBA tinting for the layer canvas.
_mt_widget.ly_r = 1.0
_mt_widget.ly_g = 1.0
_mt_widget.ly_b = 1.0
_mt_widget.ly_a = 1.0


-- Layer canvas blend mode. The blend alpha mode is always premultiplied.
_mt_widget.ly_blend_mode = "alpha"


-- Layer canvas transform parameters.
_mt_widget.ly_x = 0
_mt_widget.ly_y = 0
_mt_widget.ly_angle = 0
_mt_widget.ly_sx = 1.0
_mt_widget.ly_sy = 1.0
_mt_widget.ly_ox = 0
_mt_widget.ly_oy = 0
_mt_widget.ly_kx = 0
_mt_widget.ly_ky = 0


-- Layer canvas quad. Restricts drawing of the canvas to a subsection of the screen.
_mt_widget.ly_use_quad = false
_mt_widget.ly_qx = 0
_mt_widget.ly_qy = 0
_mt_widget.ly_qw = 0
_mt_widget.ly_qh = 0


-- Functions called before and after drawing the canvas. Can be used to set up shaders.
_mt_widget.ly_fn_start = uiDummy.func -- XXX untested
_mt_widget.ly_fn_end = uiDummy.func -- XXX untested


function _mt_widget:evt_initialize(...)

end


function _mt_widget:evt_reshapePre()

end


--- Called when the layout system requests a segment length from a widget.
-- @param x_axis True if the segment is horizontal, false if vertical.
-- @param cross_length The length of available space on the other axis.
-- @return 1) the length and 2) true/false/nil, indicating whether the value should be scaled or not, or nothing.
function _mt_widget:evt_getSegmentLength(x_axis, cross_length)

end


function _mt_widget:evt_reshapePost()

end


function _mt_widget:ui_evaluateHover(mx, my, os_x, os_y)
	local wx, wy = self.x + os_x, self.y + os_y
	return mx >= wx and my >= wy and mx < wx + self.w and my < wy + self.h
end


function _mt_widget:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)
	local wx, wy = self.x + os_x, self.y + os_y
	return mx >= wx and my >= wy and mx < wx + self.w and my < wy + self.h
end


--- Check for and run user events attached to a widget. Internal use.
-- @param wid The widget to check.
-- @param id The User Event string ID to run.
-- @param a, b, c, d Generic arguments. Usage depends on the ID.
function _mt_widget:_runUserEvent(id, a, b, c, d)
	local user_event = self[id]

	if user_event == nil then
		-- Do nothing.

	elseif type(user_event) == "function" then
		user_event(self, a, b, c, d)

	elseif type(user_event) == "table" then
		for i, func in ipairs(user_event) do
			func(self, a, b, c, d)
		end

	else
		error("bad type for user event (expected function, table or nil, got: " .. type(user_event) .. ")")
	end
end


--- Check if the mouse pointer is hovering over the widget's contact box.
function _mt_widget:isMouseHovering()
	return context.current_hover == self
end


--- Check if the mouse pointer is currently pressing the widget.
function _mt_widget:isMousePressed()
	return context.current_pressed == self
end


function _mt_widget:canTakeThimble(n)
	return self.thimble_mode == n and self:isAwake()
end


local function _assertCanHaveThimble(self, n)
	if not self:isAwake() then
		error("this widget is not in an awake branch of the widget hierarchy.", 2)

	elseif self.thimble_mode ~= n then
		error("this widget is not allowed to have cursor focus (thimble #" .. tostring(n) .. ").", 2)
	end
end


--- Check if this widget currently has top thimble focus.
-- @return True if it has the thimble, false if not.
function _mt_widget:hasTopThimble()
	local thim = context.thimble2 or context.thimble1
	return thim == self
end


--- Check if the widget has either thimble1 or thimble2.
-- @return 1 for thimble1, 2 for thimble2, otherwise `nil`.
function _mt_widget:hasAnyThimble()
	return context.thimble2 == self and 2 or context.thimble1 == self and 1
end


function _mt_widget:hasThimble1()
	return context.thimble1 == self
end


function _mt_widget:hasThimble2()
	return context.thimble2 == self
end


local function _takeThimble1(self, a, b, c, d)
	local thimble1, thimble2 = context.thimble1, context.thimble2

	if thimble1 ~= self then
		if thimble1 then
			thimble1:releaseThimble1(a, b, c, d)
		end
		context.thimble1 = self
		self:eventCycle("evt_thimble1Take", self, a, b, c, d)
		if not thimble2 then
			self:eventCycle("evt_thimbleTopTake", self, a, b, c, d)
		end

		if thimble2 then
			thimble2:eventCycle("evt_thimble1Changed", thimble2, a, b, c, d)
		end
	end
end


local function _takeThimble2(self, a, b, c, d)
	local thimble1, thimble2 = context.thimble1, context.thimble2

	if thimble2 ~= self then
		if thimble1 and not thimble2 then
			thimble1:eventCycle("evt_thimbleTopRelease", thimble1, a, b, c, d)
		end
		context.thimble2 = false
		if thimble2 then
			thimble2:eventCycle("evt_thimbleTopRelease", thimble2, a, b, c, d)
			thimble2:eventCycle("evt_thimble2Release", thimble2, a, b, c, d)
		end
		context.thimble2 = self
		self:eventCycle("evt_thimble2Take", self, a, b, c, d)
		self:eventCycle("evt_thimbleTopTake", self, a, b, c, d)

		if thimble1 then
			thimble1:eventCycle("evt_thimble2Changed", thimble1, a, b, c, d)
		end
	end
end


--- Assigns thimble1 to this widget. The current thimble1 widget, if present, is replaced. This widget must have
--	'thimble_mode' set to 1, and the context must not be captured by any other widget. If the widget already has
--	thimble1, nothing happens.
-- @param a, b, c, d Generic arguments which are passed to the bubbled callbacks. These args are implementation-dependent.
-- @return self (for chaining).
function _mt_widget:takeThimble1(a, b, c, d)
	--print("takeThimble1", debug.traceback())
	_assertCanHaveThimble(self, 1)
	_takeThimble1(self, a, b, c, d)

	return self
end


--- Assigns thimble2 to this widget. The current thimble2 widget, if present, is replaced. This widget must have
--	'thimble_mode' set to 2, and the context must not be captured by any other widget. If the widget already has
--	thimble2, nothing happens.
-- @param a, b, c, d Generic arguments which are passed to the bubbled callbacks. These args are implementation-dependent.
-- @return self (for chaining).
function _mt_widget:takeThimble2(a, b, c, d)
	--print("takeThimble2", debug.traceback())
	_assertCanHaveThimble(self, 2)
	_takeThimble2(self, a, b, c, d)

	return self
end


--- Like takeThimble1(), but doesn't error out if the widget's 'thimble_mode' doesn't match. It may still fail if the
--	context is in captured mode.
-- @param a, b, c, d Generic arguments (same as takeThimble()).
-- @return self (for chaining).
function _mt_widget:tryTakeThimble1(a, b, c, d)
	if self:canTakeThimble(1) then
		_takeThimble1(self, a, b, c, d)
	end

	return self
end


function _mt_widget:tryTakeThimble2(a, b, c, d)
	if self:canTakeThimble(2) then
		_takeThimble2(self, a, b, c, d)
	end

	return self
end


function _mt_widget:releaseThimble1(a, b, c, d)
	local thimble2 = context.thimble2

	if context.thimble1 == self then
		context.thimble1 = false
		if not thimble2 then
			self:eventCycle("evt_thimbleTopRelease", self, a, b, c, d)
		end
		self:eventCycle("evt_thimble1Release", self, a, b, c, d)
		if thimble2 then
			thimble2:eventCycle("evt_thimble1Changed", self, a, b, c, d)
		end
	end

	return self
end


function _mt_widget:releaseThimble2(a, b, c, d)
	local thimble1 = context.thimble1

	if context.thimble2 == self then
		context.thimble2 = false
		self:eventCycle("evt_thimble2Release", self, a, b, c, d)
		self:eventCycle("evt_thimbleTopRelease", self, a, b, c, d)
		if thimble1 then
			thimble1:eventCycle("evt_thimbleTopTake", thimble1, a, b, c, d)
			thimble1:eventCycle("evt_thimble2Changed", thimble1, a, b, c, d)
		end
	end

	return self
end


--- Depth-first search for the first widget which can take the thimble.
-- @return The found widget, or nil if the search was unsuccessful.
function _mt_widget:getOpenThimble1DepthFirst()
	if self:canTakeThimble(1) then
		return self
	else
		for i, child in ipairs(self.nodes) do
			if child:getOpenThimble1DepthFirst() then
				return child
			end
		end
	end
end


--- Capture the focus. 'allow_focus_capture' must be true.
function _mt_widget:captureFocus()
	if not self.allow_focus_capture then
		error("widget isn't allowed to capture the focus.")
	end

	if context.captured_focus then
		context.captured_focus:eventSend("evt_uncapture", self)
	end

	context.captured_focus = self

	self:eventSend("evt_capture")

	return self
end


--- Release the captured focus. The focus must currently be captured by this widget.
function _mt_widget:uncaptureFocus()
	if context.captured_focus ~= self then
		error("can't release focus as widget isn't currently capturing it.")
	end

	self:eventSend("evt_uncapture")

	context.captured_focus = false

	return self
end


--- Get the widget's absolute position by adding the coordinates of itself with those of its ancestors.
-- @return X, Y position in the state's space.
function _mt_widget:getAbsolutePosition()
	local x, y, wid = self.x, self.y, self.parent

	while wid do
		x = x + wid.x - wid.scr_x
		y = y + wid.y - wid.scr_y
		wid = wid.parent
	end

	return x, y
end


--- Get a widget's position relative to a specific ancestor.
-- @param ancestor A parent, grandparent, great-grandparent, etc., of this widget. This is required (it won't default to
-- the tree root) and it must be in the widget's lineage. As a result, the root widget cannot use this method.
-- @return X, Y position relative to the ancestor.
function _mt_widget:getPositionInAncestor(ancestor)
	local x, y, wid = self.x, self.y, self.parent

	while wid do
		if wid == ancestor then
			return x, y
		end

		x = x + wid.x - wid.scr_x
		y = y + wid.y - wid.scr_y

		wid = wid.parent
	end

	error("ancestor not found in the widget's lineage.")
end


--- Converts an absolute position to one that is relative to a widget's top-left corner. Does not include the widget's
--	scroll offsets. Also returns the widget's absolute position.
-- @param x The input absolute X position.
-- @param y The input absolute Y position.
-- @return X and Y positions relative to the widget's top-left, and the widget's absolute X and Y positions.
function _mt_widget:getRelativePosition(x, y)
	local ax, ay = self:getAbsolutePosition()
	return x - ax, y - ay, ax, ay
end


--- Converts an absolute position to one that is relative to a widget's top-left corner. Includes the widget's scroll
--	offsets. Also returns the widget's absolute position.
-- @param x The input absolute X position.
-- @param y The input absolute Y position.
-- @return X and Y positions relative to the widget's top-left, with scrolling, and the widget's absolute X and Y positions.
function _mt_widget:getRelativePositionScrolled(x, y)
	local ax, ay = self:getAbsolutePosition()
	return x - ax + self.scr_x, y - ay + self.scr_y, ax, ay
end


--- Adds a new child widget instance.
--  Locked during update: yes (self)
-- @param id The widget def ID.
-- @param [skin_id] The starting Skin ID, if applicable.
-- @param [pos] (default: #self.nodes + 1) Where to place the new widget in the table of children.
-- @param [...] Additional arguments for the widget's evt_initialize() callback.
-- @return New instance table. An error is raised if there is a problem.
function _mt_widget:addChild(id, skin_id, pos, ...)
	uiAssert.notNilNotFalseNotNaN(1, id)
	uiAssert.typeEval(2, skin_id, "string")
	uiAssert.numberNotNaNEval(3, pos)

	local children = self.nodes
	pos = pos or #children + 1
	if pos < 1 or pos > #children + 1 then
		error("position is out of range")
	end

	if context.locks[self] then
		coreErr.errLocked("add child")

	elseif children == _mt_no_descendants then
		_errNoDescendants()
	end

	local child = context:_prepareWidgetInstance(id, self, skin_id)
	table.insert(children, pos, child)

	child.GE_order = #children

	local LO_list = self.LO_list
	if LO_list then
		LO_list[#LO_list + 1] = child
	end

	child:evt_initialize(...)
	child:_runUserEvent("userInitialize")

	return child
end


--- Removes a widget instance and all of its children from the context tree. This is an immediate action, so calling
--	it while iterating through the tree may mess up the loop. The deepest descendants are removed first. If applicable,
--	the widget is removed from the parent's layout list.
--  Locked during update: yes (parent)
--	Callbacks:
--	* Bubble: evt_destroy()
function _mt_widget:destroy()
	local parent = self.parent

	self._dead = "dying"

	local locks = context.locks
	if locks[parent] then
		coreErr.errLockedParent("destroy")

	elseif locks[self] then
		coreErr.errLocked("destroy")
	end

	-- Handle children, grandchildren, etc.
	local children = self.nodes
	if children then
		for i = #children, 1, -1 do
			children[i]:destroy()
			-- Removal from 'children' list is handled below.
		end

		self.nodes = nil
		--[[
		if children == _mt_no_descendants then
			self.nodes = nil
		else
			self.nodes = pools.nodes:push(children)
		end
		--]]
	end

	if context.captured_focus == self then
		-- XXX not sure if this should be an error or handled implicitly.
		--error("cannot destroy a widget that currently has the context focus captured.")
		self:uncaptureFocus()
	end

	self:_runUserEvent("userDestroy")
	self:eventBubble("evt_destroy", self)

	-- If parent exists, find and destroy self from parent's 1) children and 2) layout
	if parent then
		if uiTable.removeElement(parent.nodes, self) == 0 then
			error("widget can't find itself in parent's list of children.")
		end

		if parent.LO_list then
			uiTable.removeElement(parent.LO_list, self)
		end

		self.parent = false
	-- No parent: special handling for the root widget.
	else
		context.root = false
	end

	-- Release thimbles, if applicable
	if context.thimble2 == self then
		self:releaseThimble2()
	end
	if context.thimble1 == self then
		self:releaseThimble1()
	end

	-- Purge this widget from the async actions list.
	local async = context.async
	for i = 1, #async, 3 do
		if async[i] == self then
			async[i] = false
			async[i + 1] = false
			async[i + 2] = false
		end
	end

	-- Remove widget from any other context fields.
	-- XXX: emit the appropriate events. This stuff may need to happen earlier.
	if context.current_hover == self then
		context.current_hover = false
	end
	if context.current_pressed == self then
		context.current_pressed = false
	end
	if context.current_drag_dest == self then
		context.current_drag_dest = false
	end
	if context.cseq_widget == self then
		context:clearClickSequence()
	end

	self._dead = "dead"
	setmetatable(self, nil)
end


--[[
local function _destroyAsync(self)
	self:destroy()
end
function _mt_widget:destroyAsync()
	context:appendAsyncAction(self, _destroyAsync)
	return self
end
--]]


local function errEventBadType(field, var)
	error("widget event handler '" .. tostring(field) .. "': unsupported type: " .. type(var), 2)
end


--- Try to execute 'self[field](self, a,b,c,d,e,f)'. The field can be a function or false/nil (in which case, nothing
--	happens).
-- @param field The field in 'self' to try executing.
-- @param a,b,c,d,e,f Additional arguments to pass.
-- @return the return results of the called function, or nil if nothing was called.
function _mt_widget:eventSend(field, a,b,c,d,e,f)
	local var = self[field]
	if type(var) == "function" then
		return var(self, a,b,c,d,e,f)

	elseif var then
		errEventBadType(field, var)
	end
end


local function _eventBubble(wid, field, a,b,c,d,e,f)
	while wid do
		if wid[field] then
			local var = wid[field]
			if type(var) == "function" then
				local retval = var(wid, a,b,c,d,e,f)
				if retval then
					return retval
				end

			elseif var then
				errEventBadType(field, var)
			end
		end
		wid = wid.parent
	end
end


--- Try to execute 'self[field](self, a,b,c,d,e,f)' on this widget and its ancestors, until one returns a non-false
--	value or all widgets are exhausted.
-- @param field The field in each widget to try executing.
-- @param a,b,c,d,e,f Additional arguments to pass.
-- @return the first return value that evaluates to true, or nil if that doesn't happen.
_mt_widget.eventBubble = _eventBubble -- _mt_widget:eventBubble(field, a,b,c,d,e,f)


local function _eventTrickle(self, field, a,b,c,d,e,f)
	--print("eventTrickle", self, field, a,b,c,d,e,f)

	if self.parent then
		local retval = _eventTrickle(self.parent, field, a,b,c,d,e,f)
		if retval then
			return retval
		end
	end
	local trickle = self.trickle
	local var = trickle and trickle[field]
	if type(var) == "function" then
		local retval = var(self, a,b,c,d,e,f)
		if retval then
			return retval
		end

	elseif var then
		errEventBadType(field, var)
	end
end


--- Try to execute 'self.trickle[field](self, a,b,c,d,e,f)' from the root widget to this widget, until one returns a
--	success value or all widgets are exhausted.
_mt_widget.eventTrickle = _eventTrickle -- _mt_widget:eventTrickle(field, a,b,c,d,e,f)


function _mt_widget:eventCycle(field, a,b,c,d,e,f)
	--print("eventCycle", self, field, a,b,c,d,e,f)

	return _eventTrickle(self, field, a,b,c,d,e,f) or _eventBubble(self, field, a,b,c,d,e,f)
end


local sort_work = {} -- sortChildren
local sort_count = {} -- sortChildren


--- The default sorting method, which is a counting sort applied to the widget's children. Sorting is skipped if the
-- widget has a sort_max of 0 or if it has only one child. Otherwise, all children must have 'sort_id' set with integers
-- between 1 and the parent widget's 'sort_max', inclusive.
-- @param recurse If true, recursively sort children with the same function.
-- @return self (for chaining).
function _mt_widget:sortChildren(recurse)
	-- More info on counting sort: https://en.wikipedia.org/wiki/Counting_sort

	--[[
	Library users who require different algorithms can replace this method in widgets or their metatables as
	needed. The replacement method doesn't need to use sort_id, but it should skip sorting if the parent's sort_max
	is 0, and it should respect the 'recurse' argument as well.
	--]]

	if context.locks[self] then
		coreErr.errLocked("sort children")
	end

	local seq = self.nodes

	if self.sort_max > 0 and #seq > 1 then
		-- All in-use fields in 'count' default to 0.
		for i = 1, self.sort_max do
			sort_count[i] = 0
		end

		-- Pre-fill any empty fields in 'work' so that it doesn't get marked as a sparse table.
		for i = #sort_work + 1, #seq do
			sort_work[i] = false
		end

		-- Count all key appearances.
		for i = 1, #seq do
			-- "attempt to perform arithmetic on a nil value" -> ensure the child's sort_id is in
			-- the range of 1 to 'parent.sort_max'.
			local c = seq[i].sort_id
			sort_count[c] = sort_count[c] + 1
		end

		-- Prefix sum the count array.
		for i = 2, self.sort_max do
			sort_count[i] = sort_count[i] + sort_count[i - 1]
		end

		-- Sort children in workspace array.
		for i = #seq, 1, -1 do
			local c = seq[i].sort_id
			sort_work[sort_count[c]] = seq[i]
			sort_count[c] = sort_count[c] - 1
		end

		-- Write sorted contents back to children table
		for i = 1, #seq do
			seq[i] = sort_work[i]

			-- Overwrite workspace entries with 'false' so that it doesn't interfere with garbage collection.
			sort_work[i] = false
		end

		-- 'sort_work' will grow to be as large as the largest set of children sorted, and 'sort_count'
		-- will grow to the largest sort_max encountered. If this becomes a problem, we can shave them
		-- down to a sensible maximum, or replace them with fresh tables.
	end

	-- Optionally run on all descendants, depth-first.
	if recurse then
		for i, child in ipairs(seq) do
			child:sortChildren(true)
		end
	end

	return self
end


--- Reorder a widget among its siblings. Do not call while iterating through widgets. Note that sorting is left to the caller.
--  Locked during update: yes (parent)
-- @param var The new position. This value is clamped, so you may pass 0 for the first position and math.huge for the last.
-- @return self (for chaining).
function _mt_widget:reorder(var)
	uiAssert.numberNotNaN(1, var)

	if context.locks[self.parent] then
		coreErr.errLockedParent("reorder")
	end

	if not self.parent then
		error("cannot reorder the root widget.")
	end

	local seq = self.parent.nodes

	local self_i = self:nodeAssertIndex(seq)
	local dest_i = math.max(1, math.min(var, #seq))

	if self_i == dest_i then
		return
	end

	table.insert(seq, dest_i, table.remove(seq, self_i))

	return self
end


--- Sets the widget's tag string.
-- @param tag (string) The tag to assign.
-- @return self (for chaining).
function _mt_widget:setTag(tag)
	uiAssert.type(1, tag, "string")

	self.tag = tag

	return self
end


function _mt_widget:getTag()
	return self.tag
end


function _mt_widget:findTag(tag, inclusive)
	uiAssert.type(1, tag, "string")

	return self:nodeFindKeyDescending(inclusive, "tag", tag)
end


function _mt_widget:findChildTag(tag, i)
	uiAssert.type(1, tag, "string")

	return self:nodeFindKeyInChildren(i, "tag", tag)
end


function _mt_widget:findSiblingTag(tag, i)
	uiAssert.type(1, tag, "string")

	return self:nodeAssertParent():nodeFindKeyInChildren(i, "tag", tag)
end


function _mt_widget:_getHierarchy()
	local t = {self.id}
	local wid = self.parent
	while wid do
		table.insert(t, wid.id)
		wid = wid.parent
	end
	pTable.reverseArray(t)
	return table.concat(t, " > ")
end


function _mt_widget:reshape()
	--print("Reshape! " .. self:_getHierarchy())

	if self:evt_reshapePre() then
		return
	end

	if self.LO_list then
		widLayout.applyLayout(self, 1)
	end

	for i, child in ipairs(self.nodes) do
		child:reshape()
	end

	self:evt_reshapePost()

	return self
end


--- The default widget renderer.
function _mt_widget:render(os_x, os_y)
	-- Uncomment to draw a white rectangle for every widget that does not have a render method
	-- assigned. (This won't affect widgets with a dummy render() attached.)
	--[[
	love.graphics.push("all")

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)

	love.graphics.pop()
	--]]
end


--- Renders after children, and before the focus cursor (assuming it is hosted by this widget).
function _mt_widget:renderLast(os_x, os_y)

end


-- Info for the default thimble render function.
local _thimble_info = {
	mode = "line",
	color = {0.2, 0.2, 1.0, 1.0},
	line_style = "smooth",
	line_width = 2,
	line_join = "miter",
	corner_rx = 1,
	corner_ry = 1,
	outline_pad = 0,
	segments = nil,
}


--- The default renderer for when widgets have the thimble.
function _mt_widget:renderThimble()
	local thimble_t = self.thimble_info or context.resources.info.thimble_info or _thimble_info

	love.graphics.setColor(thimble_t.color)

	if thimble_t.mode == "line" then
		love.graphics.setLineStyle(thimble_t.line_style)
		love.graphics.setLineWidth(thimble_t.line_width)
		love.graphics.setLineJoin(thimble_t.line_join)
	end

	local x, y, w, h
	if self.thimble_x then
		x = self.thimble_x
		y = self.thimble_y
		w = self.thimble_w
		h = self.thimble_h

	else
		x = -thimble_t.outline_pad
		y = -thimble_t.outline_pad
		w = self.w + thimble_t.outline_pad
		h = self.h + thimble_t.outline_pad
	end

	love.graphics.rectangle(thimble_t.mode, 0.5 + x, 0.5 + y, w - 1, h - 1, thimble_t.corner_rx, thimble_t.corner_ry, thimble_t.segments)
end


--- Check if a widget is currently locked by the context (for the update loop).
function _mt_widget:isLocked()
	return not not context.locks[self]
end


--- Check if a widget's parent is currently locked by the context (for the update loop).
function _mt_widget:isParentLocked()
	return not not context.locks[self.parent]
end


function _mt_widget:skinInstall()
	if self.skinner.install then
		self.skinner.install(self, self.skinner, self.skin)
	end

	return self
end


function _mt_widget:skinRemove()
	if self.skinner.remove then
		self.skinner.remove(self, self.skinner, self.skin)
	end

	return self
end


--- Updates the widget's skinner and skin tables based on its `skin_id`. Raises an error if the named
--	skin or its dependent skinner cannot be found. Returns the skinner and skin tables for convenience.
--	Intended uses: during widget instance creation; when reloading resources.
function _mt_widget:skinSetRefs()
	if not self.skin_id then
		error("no skin ID assigned to widget.")
	end

	local resources = context.resources
	local skin_inst = resources.skins[self.skin_id]
	if not skin_inst then
		error("widget skin (the data) is not loaded or is invalid: " .. tostring(self.skin_id))
	end

	if not skin_inst.skinner_id then
		error("widget skin (" .. tostring(self.skin_id) .. ") is missing a skinner ID.")
	end

	local skinner = context.skinners[skin_inst.skinner_id]
	if not skinner then
		error("widget skinner (the implementation) is not loaded or is invalid: " .. tostring(skin_inst.skinner_id))
	end

	self.skinner = skinner
	self.skin = skin_inst

	return self
end


function _mt_widget:skinRefresh()
	if self.skinner.refresh then
		self.skinner.refresh(self, self.skinner, self.skin)
	end

	return self
end


function _mt_widget:skinUpdate(dt)
	if self.skinner.update then
		self.skinner.update(self, self.skinner, self.skin, dt)
	end

	return self
end


local function _applySetting(self, k, default_settings, skin, settings)
	if settings[k] ~= nil then
		self[k] = settings[k]

	elseif skin and skin[k] ~= nil then
		self[k] = skin[k]

	else
		self[k] = default_settings[k]
	end
end


function _mt_widget:applySetting(key)
	if self.default_settings[key] == nil then
		error("invalid setting.")
	end

	_applySetting(self, key, self.default_settings, self.skin, self.settings)

	return self
end


function _mt_widget:applyAllSettings()
	local settings, skin, default_settings = self.settings, self.skin, self.default_settings

	for k, v in pairs(default_settings) do
		_applySetting(self, k, default_settings, skin, settings)
	end

	return self
end


function _mt_widget:writeSetting(key, val)
	local settings, skin, default_settings = self.settings, self.skin, self.default_settings

	if default_settings[key] == nil then
		error("invalid setting.")
	end

	settings[key] = val
	_applySetting(self, key, default_settings, skin, settings)

	return self
end


function _mt_widget:isAwake()
	local wid = self
	while wid do
		if not wid.awake then
			return false
		end
		wid = wid.parent
	end
	return true
end


function _mt_widget:geometrySetMode(mode, ...)
	local setter = widLayout.mode_setters[mode]
	if setter then
		setter(self, ...)
	else
		error("invalid geometry mode: " .. tostring(mode))
	end

	return self
end


function _mt_widget:geometryGetMode()
	return self.GE.mode, self.GE
end


function _mt_widget:geometrySetPadding(x1, y1, x2, y2)
	uiAssert.numberNotNaN(1, x1)

	if y1 then
		uiAssert.numberNotNaN(2, y1)
		uiAssert.numberNotNaN(3, x2)
		uiAssert.numberNotNaN(4, y2)

		self.GE_outpad_x1 = math.max(0, x1)
		self.GE_outpad_y1 = math.max(0, y1)
		self.GE_outpad_x2 = math.max(0, x2)
		self.GE_outpad_y2 = math.max(0, y2)
	else
		self.GE_outpad_x1 = math.max(0, x1)
		self.GE_outpad_y1 = math.max(0, x1)
		self.GE_outpad_x2 = math.max(0, x1)
		self.GE_outpad_y2 = math.max(0, x1)
	end

	return self
end


function _mt_widget:geometryGetPadding()
	return self.GE_outpad_x1, self.GE_outpad_y1, self.GE_outpad_x2, self.GE_outpad_y2
end


function _mt_widget:geometrySetOrder(n)
	uiAssert.numberNotNaN(1, n)

	self.GE_order = n

	return self
end


function _mt_widget:geometryGetOrder()
	return self.GE_order
end


return _mt_widget
