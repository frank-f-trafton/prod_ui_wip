-- To load: local lib = context:getLua("shared/lib")


-- ProdUI: Widget implementation.


local context = select(1, ...)


local _mt_widget = {}
_mt_widget.__index = _mt_widget
_mt_widget.context = context


-- For loading widget defs, see the UI Context source.


local widLayout = context:getLua("core/wid_layout")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local viewport_keys = context:getLua("core/viewport_keys")
local widShared = context:getLua("core/wid_shared")


local dummyFunc = function() end
local dummy_table = {}


local function errNoDescendants()
	error("widget is not configured to have descendants.", 2)
end


local _mt_no_descendants = {}
-- Unfortunately, table.insert() does not trigger __newindex, so this only handles part of the issue.
_mt_no_descendants.__newindex = function()
	errNoDescendants()
end
setmetatable(_mt_no_descendants, _mt_no_descendants)


-- ID and tag strings
_mt_widget.id = "_ui_unknown"
_mt_widget.tag = ""


-- Dummy children table
_mt_widget.children = _mt_no_descendants


_mt_widget.x = 0
_mt_widget.y = 0
_mt_widget.w = 0
_mt_widget.h = 0


_mt_widget.min_w = 0
_mt_widget.min_h = 0
_mt_widget.max_w = math.huge
_mt_widget.max_h = math.huge

_mt_widget.pref_w = false
_mt_widget.pref_h = false


-- Scroll offsets. These apply to a widget's children (a `scr_x` of 50 would offset all of a widget's
-- children to the left by 50 pixels). They may also be used for offsetting built-in components.
_mt_widget.scr_x = 0
_mt_widget.scr_y = 0


_mt_widget.thimble_mode = 0


-- Affects ticking (uiCall_update, userUpdate), mouse events, and various kinds of selection (ie thimble handoff).
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
_mt_widget.ly_fn_start = dummyFunc -- XXX untested
_mt_widget.ly_fn_end = dummyFunc -- XXX untested


function _mt_widget:uiCall_initialize(...)

end


function _mt_widget:uiCall_reshapePre()

end


--- Called when the layout system requests a slice length from a widget.
-- @param x_axis True if the slice is horizontal, false if vertical.
-- @param cross_length The length of available space on the other axis.
-- @return 1) the length and 2) true/false/nil, indicating whether the value should be scaled or not, or nothing.
function _mt_widget:uiCall_getSliceLength(x_axis, cross_length)

end


function _mt_widget:uiCall_reshapePost()

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
function _mt_widget:checkHovered()
	return context.current_hover == self
end


--- Check if the mouse pointer is currently pressing the widget.
function _mt_widget:checkPressed()
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
		self:cycleEvent("uiCall_thimble1Take", self, a, b, c, d)
		if not thimble2 then
			self:cycleEvent("uiCall_thimbleTopTake", self, a, b, c, d)
		end

		if thimble2 then
			thimble2:cycleEvent("uiCall_thimble1Changed", thimble2, a, b, c, d)
		end
	end
end


local function _takeThimble2(self, a, b, c, d)
	local thimble1, thimble2 = context.thimble1, context.thimble2

	if thimble2 ~= self then
		if thimble1 and not thimble2 then
			thimble1:cycleEvent("uiCall_thimbleTopRelease", thimble1, a, b, c, d)
		end
		context.thimble2 = false
		if thimble2 then
			thimble2:cycleEvent("uiCall_thimbleTopRelease", thimble2, a, b, c, d)
			thimble2:cycleEvent("uiCall_thimble2Release", thimble2, a, b, c, d)
		end
		context.thimble2 = self
		self:cycleEvent("uiCall_thimble2Take", self, a, b, c, d)
		self:cycleEvent("uiCall_thimbleTopTake", self, a, b, c, d)

		if thimble1 then
			thimble1:cycleEvent("uiCall_thimble2Changed", thimble1, a, b, c, d)
		end
	end
end


--- Assigns thimble1 to this widget. The current thimble1 widget, if present, is replaced. This widget must have
--	'thimble_mode' set to 1, and the context must not be captured by any other widget. If the widget already has
--	thimble1, nothing happens.
-- @param a, b, c, d Generic arguments which are passed to the bubbled callbacks. These args are implementation-dependent.
function _mt_widget:takeThimble1(a, b, c, d)
	--print("takeThimble1", debug.traceback())
	_assertCanHaveThimble(self, 1)
	_takeThimble1(self, a, b, c, d)
end


--- Assigns thimble2 to this widget. The current thimble2 widget, if present, is replaced. This widget must have
--	'thimble_mode' set to 2, and the context must not be captured by any other widget. If the widget already has
--	thimble2, nothing happens.
-- @param a, b, c, d Generic arguments which are passed to the bubbled callbacks. These args are implementation-dependent.
function _mt_widget:takeThimble2(a, b, c, d)
	--print("takeThimble2", debug.traceback())
	_assertCanHaveThimble(self, 2)
	_takeThimble2(self, a, b, c, d)
end


--- Like takeThimble1(), but doesn't error out if the widget's 'thimble_mode' doesn't match. It may still fail if the
--	context is in captured mode.
-- @param a, b, c, d Generic arguments (same as takeThimble()).
-- @return True if takeThimble() was called, nil if not.
function _mt_widget:tryTakeThimble1(a, b, c, d)
	if self:canTakeThimble(1) then
		_takeThimble1(self, a, b, c, d)
		return true
	end
end


function _mt_widget:tryTakeThimble2(a, b, c, d)
	if self:canTakeThimble(2) then
		_takeThimble2(self, a, b, c, d)
		return true
	end
end


function _mt_widget:releaseThimble1(a, b, c, d)
	local thimble2 = context.thimble2

	if context.thimble1 == self then
		context.thimble1 = false
		if not thimble2 then
			self:cycleEvent("uiCall_thimbleTopRelease", self, a, b, c, d)
		end
		self:cycleEvent("uiCall_thimble1Release", self, a, b, c, d)
		if thimble2 then
			thimble2:cycleEvent("uiCall_thimble1Changed", self, a, b, c, d)
		end
	end
end


function _mt_widget:releaseThimble2(a, b, c, d)
	local thimble1 = context.thimble1

	if context.thimble2 == self then
		context.thimble2 = false
		self:cycleEvent("uiCall_thimble2Release", self, a, b, c, d)
		self:cycleEvent("uiCall_thimbleTopRelease", self, a, b, c, d)
		if thimble1 then
			thimble1:cycleEvent("uiCall_thimbleTopTake", thimble1, a, b, c, d)
			thimble1:cycleEvent("uiCall_thimble2Changed", thimble1, a, b, c, d)
		end
	end
end


--- Gets the root widget instance.
-- @return The root widget.
function _mt_widget:getRootWidget()
	return context.root
end


--- Depth-first search for the first widget which can take the thimble.
-- @return The found widget, or nil if the search was unsuccessful.
function _mt_widget:getOpenThimble1DepthFirst()
	if self:canTakeThimble(1) then
		return self
	else
		for i, child in ipairs(self.children) do
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
		context.captured_focus:sendEvent("uiCall_uncapture", self)
	end

	context.captured_focus = self

	self:sendEvent("uiCall_capture")
end


--- Release the captured focus. The focus must currently be captured by this widget.
function _mt_widget:uncaptureFocus()
	if context.captured_focus ~= self then
		error("can't release focus as widget isn't currently capturing it.")
	end

	self:sendEvent("uiCall_uncapture")

	context.captured_focus = false
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


function _mt_widget:initialize()
	error("Delete this call!")
end


--- Adds a new child widget instance.
--  Locked during update: yes (self)
-- @param id The widget def ID.
-- @param [pos] (default: #self.children + 1) Where to place the new widget in the table of children.
-- @param [skin_id] The starting Skin ID, if applicable.
-- @param [...] Additional arguments for the widget's uiCall_initialize() callback.
-- @return New instance table. An error is raised if there is a problem.
function _mt_widget:addChild(id, pos, skin_id, ...)
	uiShared.notNilNotFalseNotNaN(1, id)
	uiShared.numberNotNaNEval(2, pos)
	uiShared.typeEval1(3, skin_id, "string")

	local children = self.children
	pos = pos or #children + 1
	if pos < 1 or pos > #children + 1 then
		error("position is out of range")
	end

	if context.locks[self] then
		uiShared.errLocked("add child")

	elseif children == _mt_no_descendants then
		errNoDescendants()
	end

	local child = context:_prepareWidgetInstance(id, self, skin_id)
	table.insert(children, pos, child)

	child:uiCall_initialize(...)
	child:_runUserEvent("userInitialize")

	return child
end


--- Remove a widget instance and all of its children from the context tree. This is an immediate action, so calling it while iterating through the tree may mess up the loop. The deepest descendants are removed first. If applicable, the widget is removed from its layout node, though the node itself is not destroyed.
--  Locked during update: yes (parent)
--	Callbacks:
--	* Bubble: uiCall_destroy()
function _mt_widget:remove()
	if self._dead then
		error("attempted to remove widget that is already " .. tostring(self._dead) .. ".")
	end

	self._dead = "dying"

	local locks = context.locks
	if locks[self.parent] then
		uiShared.errLockedParent("remove")

	elseif locks[self] then
		uiShared.errLocked("remove")
	end

	-- Handle children, grandchildren, etc.
	if self.children then
		for i = #self.children, 1, -1 do
			self.children[i]:remove()
			-- Removal from 'children' list is handled below.
		end
	end

	if context.captured_focus == self then
		-- XXX not sure if this should be an error or handled implicitly.
		--error("cannot remove a widget that currently has the context focus captured.")
		self:uncaptureFocus()
	end

	self:_runUserEvent("userDestroy")
	self:bubbleEvent("uiCall_destroy", self)

	-- Remove from parent layout node, if applicable
	if self.layout_ref then
		if not self.parent then
			error("the root widget should not have a layout node.")
		end

		self.layout_ref.wid_ref = false
		self.layout_ref = false
	end

	-- If parent exists, find and remove self from parent's list of children
	if self.parent then
		local parent = self.parent
		local ok = false

		for i = #parent.children, 1, -1 do
			if parent.children[i] == self then
				table.remove(parent.children, i)
				ok = true
				break
			end
		end

		if not ok then
			error("widget can't find itself in parent's list of children.")
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
end


--[[
local function _removeAsync(self)
	self:remove()
end
function _mt_widget:removeAsync()
	context:appendAsyncAction(self, _removeAsync)
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
function _mt_widget:sendEvent(field, a,b,c,d,e,f)
	-- Debug
	--[[
	if wid._dead then
		error("attempt to run a statement on a dead widget.")
	end
	--]]
	local var = self[field]
	if type(var) == "function" then
		return var(self, a,b,c,d,e,f)

	elseif var then
		errEventBadType(field, var)
	end
end


local function _bubbleEvent(wid, field, a,b,c,d,e,f)
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
_mt_widget.bubbleEvent = _bubbleEvent -- _mt_widget:bubbleEvent(field, a,b,c,d,e,f)


local function _trickleEvent(self, field, a,b,c,d,e,f)
	if self.parent then
		local retval = _trickleEvent(self.parent, field, a,b,c,d,e,f)
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
_mt_widget.trickleEvent = _trickleEvent -- _mt_widget:trickleEvent(field, a,b,c,d,e,f)


--- Trickle, then bubble an event.
function _mt_widget:cycleEvent(field, a,b,c,d,e,f)
	local retval = _trickleEvent(self, field, a,b,c,d,e,f)
	if retval then
		return retval
	end
	local var = self[field]
	if type(var) == "function" then
		retval = var(self, a,b,c,d,e,f)
		if retval then
			return retval
		end

	elseif var then
		errEventBadType(field, var)
	end

	if self.parent then
		return _bubbleEvent(self.parent, field, a,b,c,d,e,f)
	end
end


function _mt_widget:getIndex(seq)
	seq = seq or (self.parent and self.parent.children)

	for i, child in ipairs(seq) do
		if self == child then
			return i
		end
	end

	error("couldn't find self in provided list of widgets.")
end


local function getSiblingDelta(self, delta, wrap)
	if not self.parent then
		error("can't get siblings for the root widget.")
	end

	local siblings = self.parent.children
	local index = self:getIndex(siblings)
	local retval = siblings[index + delta]
	if not retval and wrap then
		local wrap_i = delta > 0 and 1 or #siblings
		retval = siblings[wrap_i]
	end

	return retval
end


function _mt_widget:getSiblingNext(wrap)
	return getSiblingDelta(self, 1, wrap)
end


function _mt_widget:getSiblingPrevious(wrap)
	return getSiblingDelta(self, -1, wrap)
end


local sort_work = {} -- sortChildren
local sort_count = {} -- sortChildren


--- The default sorting method, which is a counting sort applied to the widget's children. Sorting is skipped if the
-- widget has a sort_max of 0 or fewer than two children. Otherwise, all children must have 'sort_id' set with integers
-- between 1 and the parent widget's 'sort_max', inclusive.
-- @param recurse If true, recursively sort children with the same function.
function _mt_widget:sortChildren(recurse)
	-- More info on counting sort: https://en.wikipedia.org/wiki/Counting_sort

	--[[
	Library users who require different algorithms can replace this method in widgets or their metatables as
	needed. The replacement method doesn't need to use sort_id, but it should skip sorting if the parent's sort_max
	is 0, and it should respect the 'recurse' argument as well.
	--]]

	if context.locks[self] then
		uiShared.errLocked("sort children")
	end

	local seq = self.children

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
			-- ^ Weak tables are another option, but could add gaps to the sequence and flag the table as sparse.
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
end


--- Reorder a widget among its siblings. Do not call while iterating through widgets. Note that sorting is left to the caller.
--  Locked during update: yes (parent)
-- @param var The new position. This value is clamped, so you may pass 0 for the first position and math.huge for the last.
function _mt_widget:reorder(var)
	uiShared.numberNotNaN(1, var)

	if context.locks[self.parent] then
		uiShared.errLockedParent("reorder")
	end

	if not self.parent then
		error("cannot reorder the root widget.")
	end

	local seq = self.parent.children

	local self_i = self:getIndex(seq)
	local dest_i = math.max(1, math.min(var, #seq))

	if self_i == dest_i then
		return
	end

	table.insert(seq, dest_i, table.remove(seq, self_i))
end


--- Sets the widget's tag string.
-- @param tag (string) The tag to assign.
function _mt_widget:setTag(tag)
	uiShared.type1(1, tag, "string")

	self.tag = tag
end


-- Depth-first tag search among descendants. Does not include self.
-- @param str The string to find.
-- @return The widget, plus its sibling index, or nil if there was no match.
function _mt_widget:findTag(str)
	for i, child in ipairs(self.children) do
		--print("findTag", self.id, i, child.id, child.tag)
		if child.tag == str then
			--print("findTag: MATCH")
			return child, i
		else
			local ret1, ret2 = child:findTag(str)
			if ret1 then
				return ret1, ret2
			end
		end
	end
end


-- Shallow tag search among descendants.
function _mt_widget:findTagFlat(str, pos)
	pos = pos or 1
	local children = self.children

	for i = pos, #children do
		local child = children[i]
		if child.tag == str then
			return child, i
		end
	end
end


-- Flat search of siblings for a specific string tag.
function _mt_widget:findSiblingTag(str, i)
	if not self.parent then
		error("the root widget does not have siblings.")
	end

	i = i or 1

	local seq = self.parent.children
	local instance = seq[i]

	while instance do
		if instance.tag == str then
			return instance, i
		end
		i = i + 1
		instance = seq[i]
	end
end


function _mt_widget:hasThisAncestor(wid)
	local ancestor = self.parent
	while ancestor do
		if ancestor == wid then
			return true
		end
		ancestor = ancestor.parent
	end

	return false
end


function _mt_widget:isInLineage(wid)
	local w2 = self
	while w2 do
		if w2 == wid then
			return true
		end
		w2 = w2.parent
	end

	return false
end


function _mt_widget:hasDirectChild(wid)
	for i, child in ipairs(self.children) do
		if wid == child then
			return true
		end
	end

	return false
end


function _mt_widget:reshape()
	if self:uiCall_reshapePre() then
		return
	end

	local n = self.layout_tree
	if n then
		widLayout.splitNode(n, 1)
		widLayout.setWidgetSizes(n, 1)
	end

	for i, child in ipairs(self.children) do
		child:reshape()
	end

	self:uiCall_reshapePost()
end


--- Convenience wrapper for reshape() which skips the calling widget and starts with its children.
function _mt_widget:reshapeDescendants()
	for i, child in ipairs(self.children) do
		child:reshape()
	end
end


function _mt_widget:setPreferredDimensions(w, h)
	uiShared.typeEval1(1, w, "number")
	uiShared.typeEval1(2, h, "number")

	self.pref_w = w and math.max(0, w) or false
	self.pref_h = h and math.max(0, h) or false
end


function _mt_widget:applyPreferredDimensions()
	local scale = context.scale
	if type(self.pref_w) == "number" then
		self.w = math.floor(self.pref_w * scale)
	end
	if type(self.pref_h) == "number" then
		self.h = math.floor(self.pref_h * scale)
	end
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


-- @returns the first widget where wid[key] has a non-nil value, plus the value.
function _mt_widget:findAscendingKey(key)
	local wid = self
	while wid do
		if wid[key] ~= nil then
			return wid, wid[key]
		end
		wid = wid.parent
	end
end


-- @returns the first widget where wid[key] == value.
function _mt_widget:findAscendingKeyValue(key, value)
	--print("findAscendingKeyValue: start: ", key, value)
	local wid = self
	while wid do
		--print("findAscendingKeyValue: ancestor: ", wid.id, wid[key], wid[value])
		if wid[key] == value then
			--print("^ MATCH")
			return wid
		end
		wid = wid.parent
	end
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
end


function _mt_widget:skinRemove()
	if self.skinner.remove then
		self.skinner.remove(self, self.skinner, self.skin)
	end
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
end


function _mt_widget:skinRefresh()
	if self.skinner.refresh then
		self.skinner.refresh(self, self.skinner, self.skin)
	end
end


function _mt_widget:skinUpdate(dt)
	if self.skinner.update then
		self.skinner.update(self, self.skinner, self.skin, dt)
	end
end


--- Get a widget's parent, throwing an error if there is no reference (it's the root widget, or data corruption).
function _mt_widget:getParent()
	local parent = self.parent
	if not parent then
		error("missing parent reference in widget.")
	end

	return parent
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
end


function _mt_widget:applyAllSettings()
	local settings, skin, default_settings = self.settings, self.skin, self.default_settings

	for k, v in pairs(default_settings) do
		_applySetting(self, k, default_settings, skin, settings)
	end
end


function _mt_widget:writeSetting(key, val)
	local settings, skin, default_settings = self.settings, self.skin, self.default_settings

	if default_settings[key] == nil then
		error("invalid setting.")
	end

	settings[key] = val
	_applySetting(self, key, default_settings, skin, settings)
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


function _mt_widget:nextWidget()
	if self.children[1] then
		return self.children[1]
	else
		local wid = self
		while wid do
			if not wid.parent then
				break
			end
			local siblings = wid.parent.children
			local i = wid:getIndex(siblings)
			if i < #siblings then
				return siblings[i + 1]
			else
				wid = wid.parent
			end
		end
	end
end


function _mt_widget:forEach(callback, ...)
	callback(self, ...)
	for i, child in ipairs(self.children) do
		local a, b, c, d = child:forEach(callback, ...)
		if a then
			return a, b, c, d
		end
	end
end


function _mt_widget:forEachDescendant(callback, ...)
	for i, child in ipairs(self.children) do
		local a, b, c, d = child:forEach(callback, ...)
		if a then
			return a, b, c, d
		end
	end
end


function _mt_widget:setLayoutNode(wid, node)
	if not self.layout_tree then
		error("this widget does not have a layout tree.")

	elseif not self:hasDirectChild(wid) then
		error("'wid' is not a direct child of this widget.")

	elseif wid._dead then
		error("attempted to attach a dead or dying widget to the layout node.")

	elseif node and not widLayout.nodeInTree(self.layout_tree, node) then
		error("'node' is not part of this widget's layout tree.")
	end

	if node then
		if node.wid_ref then
			node.wid_ref.layout_ref = false
		end
		node.wid_ref = wid
		wid.layout_ref = node
	else
		wid.layout_ref = false
	end
end


return _mt_widget
