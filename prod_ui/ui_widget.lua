-- ProdUI: Widget implementation.


local uiWidget = {}


-- For loading widget defs, see the UI Context source.


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiShared = require(REQ_PATH .. "ui_shared")
local utilTable = require(REQ_PATH .. "common.util_table")
local widShared = require(REQ_PATH .. "common.wid_shared")


local dummyFunc = function() end
local dummy_table = {}


local _mt_widget = {}
_mt_widget.__index = _mt_widget
uiWidget._mt_widget = _mt_widget


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


-- Scroll offsets. These apply to a widget's children (a `scr_x` of 50 would offset all of a widget's
-- children to the left by 50 pixels). They may also be used for offsetting built-in components.
_mt_widget.scr_x = 0
_mt_widget.scr_y = 0


-- Draw range for children
_mt_widget.draw_child_first = -math.huge
_mt_widget.draw_child_last = math.huge


-- Sorting variables.


-- Number of sorting IDs for a widget's children. Larger numbers require more memory allocation when sorting.
-- 0 == do not sort children.
_mt_widget.sort_max = 0


-- Default sorting ID / lane for widgets. Ranges from 1 to parent.sort_max (or n/a if sort_max is 0).
-- Sorting is performed at the sibling level. This value is unused for top-level widgets.
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


function _mt_widget:ui_evaluateHover(mx, my, os_x, os_y)
	local wx, wy = self.x + os_x, self.y + os_y
	return mx >= wx and my >= wy and mx < wx + self.w and my < wy + self.h
end


function _mt_widget:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)
	local wx, wy = self.x + os_x, self.y + os_y
	return mx >= wx and my >= wy and mx < wx + self.w and my < wy + self.h
end


--- Sets up a new widget instance table. Internal use.
function uiWidget._initWidgetInstance(instance, def, context, parent)
	-- Uncomment to assert that instance tables are not being reused.
	-- [[
	if not uiWidget._assert_dupe_tables then
		uiWidget._assert_dupe_tables = {}
		-- Use weak keys so that we don't prevent tables from being garbage-collected.
		setmetatable(uiWidget._assert_dupe_tables, {__mode = "k"})
	end
	if uiWidget._assert_dupe_tables[instance] then
		error("duplicate instance table!")
	end
	uiWidget._assert_dupe_tables[instance] = true
	--]]

	instance.x = instance.x or 0
	instance.y = instance.y or 0
	instance.w = instance.w or 0
	instance.h = instance.h or 0

	-- Back-links
	instance.context = context
	instance.parent = parent

	setmetatable(instance, def._inst_mt)

	if not instance._no_descendants then
		instance.children = {}
	end
end


--- Check for and run user events attached to a widget. Internal use.
-- @param wid The widget to check.
-- @param id The User Event string ID to run.
-- @param a, b, c, d Generic arguments. Usage depends on the ID.
-- @return Nothing.
function uiWidget._runUserEvent(wid, id, a, b, c, d)
	local user_event = wid[id]

	if user_event == nil then
		-- Do nothing.

	elseif type(user_event) == "function" then
		user_event(wid, a, b, c, d)

	elseif type(user_event) == "table" then
		for i, func in ipairs(user_event) do
			func(wid, a, b, c, d)
		end

	else
		error("bad type for user event (expected function, table or nil, got: " .. type(user_event))
	end
end


--- Check if the mouse pointer is hovering over the widget's contact box.
function _mt_widget:checkHovered()
	return self.context.current_hover == self
end


--- Check if the mouse pointer is currently pressing the widget.
function _mt_widget:checkPressed()
	return self.context.current_pressed == self
end


local function _assertCanHaveThimble(self)
	if not self.can_have_thimble then
		error("this widget isn't allowed to have cursor focus.", 2)
	end
end


--- Check if this widget currently has top thimble focus.
-- @return True if it has the thimble, false if not.
function _mt_widget:hasTopThimble()
	local context = self.context
	return context.thimble2 and context.thimble2 == self or context.thimble1 == self
end


--- Check if the widget has either thimble1 or thimble2.
-- @return 1 for thimble1, 2 for thimble2, otherwise `nil`.
function _mt_widget:hasAnyThimble()
	local context = self.context
	return context.thimble2 == self and 2 or context.thimble1 == self and 1
end


function _mt_widget:hasThimble1()
	return self.context.thimble1 == self
end


function _mt_widget:hasThimble2()
	return self.context.thimble2 == self
end


--- Assigns thimble1 to this widget. The current thimble1 widget, if present, is replaced. This widget must have
--	'can_have_thimble' set to true, and the context must not be captured by any other widget. If the widget is
--	already thimble1, nothing happens.
-- @param a, b, c, d Generic arguments which are passed to the bubbled callbacks. These args are implementation-dependent.
-- @return Nothing.
function _mt_widget:takeThimble1(a, b, c, d)
	--print("takeThimble1", debug.traceback())
	_assertCanHaveThimble(self)

	local context = self.context
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


--- Assigns thimble2 to this widget. The current thimble2 widget, if present, is replaced. This widget must have
--	'can_have_thimble' set to true, and the context must not be captured by any other widget. If the widget is
--	already thimble2, nothing happens.
-- @param a, b, c, d Generic arguments which are passed to the bubbled callbacks. These args are implementation-dependent.
-- @return Nothing.
function _mt_widget:takeThimble2(a, b, c, d)
	--print("takeThimble2", debug.traceback())
	_assertCanHaveThimble(self)

	local context = self.context
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


--- Like takeThimble1(), but doesn't error out if the widget is missing 'can_have_thimble'. It may still fail if the context is in captured mode.
-- @param a, b, c, d Generic arguments (same as takeThimble()).
-- @return True if takeThimble() was called, nil if not.
function _mt_widget:tryTakeThimble1(a, b, c, d)
	if self.can_have_thimble then
		self:takeThimble1(a, b, c, d)
		return true
	end
end


function _mt_widget:tryTakeThimble2(a, b, c, d)
	if self.can_have_thimble then
		self:takeThimble2(a, b, c, d)
		return true
	end
end


function _mt_widget:releaseThimble1(a, b, c, d)
	local context = self.context
	local thimble2 = context.thimble2

	if context.thimble1 ~= self then
		error("this widget doesn't have cursor focus.")
	end

	context.thimble1 = false
	if not thimble2 then
		self:cycleEvent("uiCall_thimbleTopRelease", self, a, b, c, d)
	end
	self:cycleEvent("uiCall_thimble1Release", self, a, b, c, d)
	if thimble2 then
		thimble2:cycleEvent("uiCall_thimble1Changed", self, a, b, c, d)
	end
end


function _mt_widget:releaseThimble2(a, b, c, d)
	local context = self.context
	local thimble1 = context.thimble1

	if context.thimble2 ~= self then
		error("this widget doesn't have cursor focus.")
	end

	context.thimble2 = false
	self:cycleEvent("uiCall_thimble2Release", self, a, b, c, d)
	self:cycleEvent("uiCall_thimbleTopRelease", self, a, b, c, d)
	if thimble1 then
		thimble1:cycleEvent("uiCall_thimbleTopTake", thimble1, a, b, c, d)
		thimble1:cycleEvent("uiCall_thimble2Changed", thimble1, a, b, c, d)
	end
end


function _mt_widget:tryReleaseThimble1(a, b, c, d)
	if self.can_have_thimble and self.context.thimble1 == self then
		self:releaseThimble1(a, b, c, d)
	end
end


function _mt_widget:tryReleaseThimble2(a, b, c, d)
	if self.can_have_thimble and self.context.thimble2 == self then
		self:releaseThimble2(a, b, c, d)
	end
end


--- Gets the top-level widget instance. In widget code, prefer this over referencing 'self.context.tree' because it can work outside of the current root (unless you really do want to interact with the current root).
-- @return The root widget.
function _mt_widget:getTopWidgetInstance()
	-- This is safe for the root itself to run.

	local wid = self
	local failsafe = 2^16

	for i = 1, failsafe do
		if not wid.parent then
			return wid

		else
			wid = wid.parent
		end
	end

	-- Catch cycles in the tree?
	error("failed to get top-level widget instance after " .. failsafe .. " iterations.")
end


--- Depth-first search for the first widget which can take the thimble.
-- @return The found widget, or nil if the search was unsuccessful.
function _mt_widget:getOpenThimbleDepthFirst()
	if self.can_have_thimble then
		return self
	else
		for i, child in ipairs(self.children) do
			if child:getOpenThimbleDepthFirst() then
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

	if self.context.captured_focus then
		self.context.captured_focus:sendEvent("uiCall_uncapture", self)
	end

	self.context.captured_focus = self

	self:sendEvent("uiCall_capture", self)
end


--- Release the captured focus. The focus must currently be captured by this widget.
function _mt_widget:uncaptureFocus()
	if self.context.captured_focus ~= self then
		error("can't release focus as widget isn't currently capturing it.")
	end

	self:sendEvent("uiCall_uncapture", self)

	self.context.captured_focus = false
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


--- Add a new child widget instance. Note that sorting is left to the caller.
--  Locked during update: yes (self)
--	Callbacks:
--	* uiCall_create (bubble)
-- @param id The widget def ID.
-- @param init_t An optional table the caller may provide as the basis for the instance table. This may be necessary in
-- cases where resources must be provided to the widget before uiCall_create() is called. If no table is provided, a
-- fresh table will be used instead. Note that uiCall_create() may overwrite certain fields depending on how the widget
-- def is written. Do not share this among multiple instances.
-- @param pos (default: #self.children + 1) Where to place the new widget in the children table.
-- @return New instance table. An error is raised if there is a problem.
function _mt_widget:addChild(id, init_t, pos)
	uiShared.notNilNotFalseNotNaN(1, id)
	uiShared.typeEval1(2, init_t, "table")
	uiShared.numberNotNaNEval(3, pos)

	if self.context.locks[self] then
		uiShared.errLocked("add child")

	elseif self.children == _mt_no_descendants then
		errNoDescendants()
	end

	pos = pos or #self.children + 1
	if pos < 1 or pos > #self.children + 1 then
		error("position is out of range.")
	end

	local def = self.context.widget_defs[id]

	-- Unsupported type. (Corrupt widget defs collection?)
	if type(def) ~= "table" then
		error("unregistered ID or unsupported type for widget def (id: " .. tostring(id) .. ", type: " .. type(def) .. ")")
	else
		init_t = init_t or {}
		uiWidget._initWidgetInstance(init_t, def, self.context, self)

		table.insert(self.children, pos, init_t)

		init_t:bubbleEvent("uiCall_create", init_t)
		uiWidget._runUserEvent(init_t, "userCreate")

		return init_t
	end
end


--- Remove a widget instance and all of its children from the context tree. This is an immediate action, so calling it while iterating through the tree may mess up the loop. The deepest descendants are removed first. If applicable, the widget is removed from its parent layout sequence.
--  Locked during update: yes (parent)
--	Callbacks:
--	* Bubble: uiCall_destroy()
function _mt_widget:remove()
	if self._dead then
		error("attempted to remove widget that is already " .. tostring(self._dead) .. ".")
	end

	local context = self.context

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

	uiWidget._runUserEvent(self, "userDestroy")
	self:bubbleEvent("uiCall_destroy", self)

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

		-- Remove from parent layout, if applicable.
		local lp_seq = parent.lp_seq
		if lp_seq then
			for i = #lp_seq, 1, -1 do
				if lp_seq[i] == self then
					table.remove(lp_seq, i)
					break
				end
			end
		end

		self.parent = false
	-- No parent: top-level widget special handling
	else
		-- IMPORTANT: Removing a top-level widget will not automatically trigger uiCall_rootPop().
		-- Delete from 'instances' table
		local seq = context.instances
		for i = #seq, 1, -1 do
			local instance = seq[i]
			if self == instance then
				table.remove(seq, i)
				break
			end
		end

		-- Delete from instance stack, if applicable
		for i = #context.stack, 1, -1 do
			if context.stack[i] == self then
				table.remove(context.stack, i)
				break
			end
		end

		-- If applicable, refresh the instance tree (stack top) reference.
		if context.tree == self then
			context.tree = context.stack[#context.stack] or false
		end
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

	-- If this widget is part of a Click-Sequence, remove it.
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
	self.context:appendAsyncAction(self, _removeAsync)
end
--]]


local function errEventBadType(field, var)
	error("widget event handler '" .. tostring(field) .. "': unsupported type: " .. type(var), 2)
end


--- Try to execute 'self[field](self, a,b,c,d,e,f)'. The field can be a function or nil (in which case, nothing
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

	elseif var ~= nil then
		errEventBadType(field, var)
	end
end


local function _bubbleEvent(self, field, a,b,c,d,e,f)
	local wid = self
	while wid do
		if wid[field] then
			local var = wid[field]
			if type(var) == "function" then
				local retval = var(wid, a,b,c,d,e,f)
				if retval then
					return retval
				end

			elseif var ~= nil then
				errEventBadType(field, var)
			end
		end
		wid = wid.parent
	end
end


--- Try to execute 'self[field](self, a,b,c,d,e,f)' on this widget and its ancestors, until one returns a success value
--	or all widgets are exhausted.
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

	elseif var ~= nil then
		errEventBadType(field, var)
	end
end


--- Try to execute 'self.trickle[field](self, a,b,c,d,e,f)' from the root widget to this widget, until one returns a success
--	value or all widgets are exhausted.
_mt_widget.trickleEvent = _trickleEvent -- _mt_widget:trickleEvent(field, a,b,c,d,e,f)


--- Trickle, then bubble an event.
function _mt_widget:cycleEvent(field, a,b,c,d,e,f)
	if self.parent then
		local retval = _trickleEvent(self.parent, field, a,b,c,d,e,f)
		if retval then
			return retval
		end
	end
	local var = self[field]
	if type(var) == "function" then
		local retval = var(self, a,b,c,d,e,f)
		if retval then
			return retval
		end

	elseif var ~= nil then
		errEventBadType(field, var)
	end

	if self.parent then
		return _bubbleEvent(self.parent, field, a,b,c,d,e,f)
	end
end


function _mt_widget:getIndex(seq)
	seq = seq or (self.parent and self.parent.children) or (self.context.instances)

	for i, child in ipairs(seq) do
		if self == child then
			return i
		end
	end

	error("couldn't find self in provided list of widgets.")
end


local function getSiblingDelta(self, delta, wrap)
	if not self.parent then
		error("can't get siblings for top-level (root) widget instances.")
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
-- @return Nothing. Children are sorted in-place.
function _mt_widget:sortChildren(recurse)
	-- More info on counting sort: https://en.wikipedia.org/wiki/Counting_sort

	--[[
	Library users who require different algorithms can replace this method in widgets or their metatables as
	needed. The replacement method doesn't need to use sort_id, but it should skip sorting if the parent's sort_max
	is 0, and it should respect the 'recurse' argument as well.
	--]]

	if self.context.locks[self] then
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

	-- Optionally run on all children, depth-first.
	if recurse then
		for i, child in ipairs(seq) do
			child:sortChildren(true)
		end
	end
end


--- Reorder a widget among its siblings. Do not call while iterating through widgets. Note that sorting is left to the caller.
--  Locked during update: yes (parent)
-- @param var "first" to move to the beginning of the list, "last" to move to the end, or a number to move by a relative number of steps (clamped to the list boundaries.)
function _mt_widget:reorder(var)
	if self.context.locks[self.parent] then
		uiShared.errLockedParent("reorder")
	end

	local seq = (self.parent and self.parent.children) or (self.context.instances)

	local self_i = self:getIndex(seq)
	local dest_i

	if var == "first" then
		dest_i = 1

	elseif var == "last" then
		dest_i = #seq

	-- Relative
	elseif type(var) == "number" then
		dest_i = math.max(1, math.min(self_i + var, #seq))

	else
		error("unknown reorder variable: " .. tostring(var))
	end

	if self_i == dest_i then
		return
	end

	local temp = table.remove(seq, self_i)

	table.insert(seq, dest_i, temp)
end


--- Sets the widget's tag string.
-- @param tag (string) The tag to assign.
function _mt_widget:setTag(tag)
	uiShared.type1(1, tag, "string")

	self.tag = tag
end


-- Depth-first tag search among descendants. Does not include self.
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

	-- return nil
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

	-- return nil
end


-- Flat search of siblings for a specific string tag.
function _mt_widget:findSiblingTag(str, i)
	i = i or 1
	local seq = (self.parent and self.parent.children) or (self.context.instances)
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


--- Run the 'reshape' UI callback on a widget, and optionally on its descendants.
-- @param recursive When true, recursively reshapes children, grandchildren, etc. Return a truthy value
-- in the callback to halt the reshaping of descendants.
-- @return Nothing.
function _mt_widget:reshape(recursive)
	recursive = not not recursive
	local result = self:sendEvent("uiCall_reshape", self, recursive)

	-- Reshape children only if 'recursive' is truthy and the above statement returned falsy.
	if recursive and not result then
		for _, child in ipairs(self.children) do
			child:reshape(recursive)
		end
	end
end


--- Convenience wrapper for reshape() which skips the calling widget and starts with its children.
-- @param recursive When true, the caller's grandchildren and onwards are recursively reshaped.
-- @return Nothing.
function _mt_widget:reshapeChildren(recursive)
	recursive = not not recursive
	for i, child in ipairs(self.children) do
		child:reshape(recursive)
	end
end


function _mt_widget:setPosition(x, y) -- XXX under consideration
	self.x = x
	self.y = y

	self:sendEvent("uiCall_reposition", self, x, y)
end

--[=[
function _mt_widget:setDimensions(w, h) -- XXX under consideration
	-- maybe disallow <0 width or height.
	self.w = w
	self.h = h

	self:sendEvent("uiCall_resize", self, w, h)
end
--]=]
--[=[
function _mt_widget:setXYWH(x, y, w, h) -- XXX under consideration
	self.x = x
	self.y = y

	self:sendEvent("uiCall_reposition", self, x, y)

	self.w = w
	self.h = h

	self:sendEvent("uiCall_resize", self, w, h)
end
--]=]


--- Run a widget's resize callback, if it exists. This allows widgets to update their dimensions without the caller
--  having to know internal details about the widget. For example, a bar containing one line of text would probably
--  have a static height that is based on the size of the font used (plus maybe some padding).
function _mt_widget:resize()
	if self.uiCall_resize then
		return self:uiCall_resize()
	end
end


--[[
--- Applies fixed width and/or height to widgets.
function _mt_widget:applyFixedSize()
	if self.w_fixed then
		self.w = self.w_fixed
	end

	if self.h_fixed then
		self.h = self.h_fixed
	end
end
--]]


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
uiWidget.thimble_info = {
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
	local thimble_t = self.thimble_info or uiWidget.thimble_info

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


function _mt_widget:findAncestorByField(field, value)
	--print("findAncestorByField: start: ", field, value)
	local par = self.parent
	while par do
		--print("findAncestorByField: ancestor: ", par.id, par[field], par[value])
		if par[field] == value then
			--print("^ MATCH")
			return par
		end
		par = par.parent
	end

	return nil
end


--- Set the high-priority cursor for widgets.
function _mt_widget:setCursorHigh(id)
	local context = self.context

	if context.cursor_mgr then
		context.cursor_mgr:assignCursor(id, 3)
	end
end


--- Get the current high-priority cursor ID, or false if none is set.
function _mt_widget:getCursorHigh()
	local context = self.context

	if context.cursor_mgr then
		return context.cursor_mgr:getCursorID(3)
	else
		return false
	end
end


--- Set the low-priority cursor for widgets.
function _mt_widget:setCursorLow(id)
	local context = self.context

	if context.cursor_mgr then
		context.cursor_mgr:assignCursor(id, 4)
	end
end


--- Get the current low-priority cursor ID, or false if none is set.
function _mt_widget:getCursorLow()
	local context = self.context

	if context.cursor_mgr then
		return context.cursor_mgr:getCursorID(4)
	else
		return false
	end
end


--- Check if a widget is currently locked by the context (for the update loop).
function _mt_widget:isLocked()
	return not not self.context.locks[self]
end


--- Check if a widget's parent is currently locked by the context (for the update loop).
function _mt_widget:isParentLocked()
	return not not self.context.locks[self.parent]
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
--@return The skinner (implementation) and skin (data) tables.
function _mt_widget:skinSetRefs()
	if not self.skin_id then
		error("no skin ID assigned to widget.")
	end

	local skin = self.context.resources.skins[self.skin_id]
	if not skin then
		error("widget skin (the data) is not loaded or is invalid: " .. tostring(self.skin_id))
	end

	if not skin.skinner_id then
		error("widget skin is missing a skinner ID.")
	end

	local skinner = self.skinners[skin.skinner_id]

	if not skinner then
		error("widget skinner (the implementation) is not loaded or is invalid: " .. tostring(skin.skinner_id))
	end

	self.skinner = skinner
	self.skin = skin

	return skinner, skin
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


function _mt_widget:getHierarchical(field)
	local wid = self

	while wid do
		local ret = wid[field]
		if ret ~= nil then
			return ret

		else
			wid = wid.parent
		end
	end

	error("hierarchical look-up failed. Field: " .. tostring(field))
end


function _mt_widget:drillHierarchical(...)
	local wid = self

	while wid do
		local ret = utilTable.tryDrillV(self, ...)
		if ret ~= nil then
			return ret
		else
			wid = wid.parent
		end
	end

	error("hierarchical drill failed. Fields: " .. utilTable.concatVarargs(...))
end


--- Load or refresh a resource at self.<id> using a drill-string stored in self[<"*id">].
-- @param id String ID of the field to load or refresh (with the leading symbol).
function _mt_widget:applyResource(id)
	self.context.resources:applyResource(self, id)
end


--- Get a widget's parent, throwing an error if there is no reference (it's the root widget, or data corruption).
function _mt_widget:getParent()
	local parent = self.parent
	if not parent then
		error("missing parent reference in widget.")
	end

	return parent
end


return uiWidget
