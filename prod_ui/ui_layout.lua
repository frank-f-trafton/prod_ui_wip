-- ProdUI: Layout system.


--[[
	Variable prefixes:
	lo_ -- General layout variable, or something internal to uiLayout.
	lp_ -- Layout variable associated with parent (bindable) widget
	lc_ -- Layout variable associated with a child of a bound widget

	Widgets can both be bound, and children of bound widgets at different times.

	All functions in the 'Layout Binding API' section require that a widget is
	bound to the layout system.
--]]


local uiLayout = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local widShared = require(REQ_PATH .. "common.wid_shared")


-- Stack of layout rectangles
-- Push to work on a subsection of a layout, pop to return to the rest of the layout.
local lo_stack = {}

-- Current stack index
local lo_stack_i = 0

-- Remove (set nil) tables when popping if greater than this index. Set to 0 to always remove.
local lo_stack_upper = 6

-- Crash if stack exceeds this value
local lo_stack_max = 2^16

-- Only one widget may be bound at a time.
local lo_bind = false


-- * Getter-assertion combos *


local function getBoundWidget()
	if not lo_bind then
		error("no widget is currently bound to the layout system.", 2)
	else
		return lo_bind
	end
end


local function incrementStackPointer()
	lo_stack_i = lo_stack_i + 1
	if lo_stack_i > lo_stack_max then
		error("layout stack overflow.", 2)
	end

	lo_stack[lo_stack_i] = lo_stack[lo_stack_i] or {}
	return lo_stack[lo_stack_i]
end


local function decrementStackPointer()
	if lo_stack_i < 1 then
		error("attempt to pop empty stack. (More pops than pushes?)")
	end

	local retval = lo_stack[lo_stack_i]
	if not retval then
		error("no layout table at stack index: " .. tostring(lo_stack_i))
	end

	-- If applicable, remove table from stack
	if lo_stack_i > lo_stack_upper then
		lo_stack[lo_stack_i] = nil
	end
	lo_stack_i = lo_stack_i - 1

	return retval
end


local function getLayoutTable(self) -- (For parent widgets)
	local lp_seq = self.lp_seq
	if not lp_seq then
		error("missing layout table.", 2)
	else
		return lp_seq
	end
end


-- * Layout Binding API *


--- Bind a widget to the layout system. Only one widget may be bound at a time.
-- @param wid The widget to bind.
-- @return Nothing.
function uiLayout.bindWidget(wid)
	if type(wid) ~= "table" then
		error("argument #1 bad type: expected table, got " .. type(wid))

	elseif lo_bind then
		error("a widget is already bound to the layout system.")
	end

	lo_bind = wid
end


--- Unbind a widget previously bound to the layout system. The layout stack must be empty at time of call, and the widget
-- must be currently bound.
-- @param wid The widget to unbind.
-- @return Nothing.
function uiLayout.unbindWidget(wid)
	if type(wid) ~= "table" then
		error("argument #1 bad type: expected table, got " .. type(wid))

	elseif not lo_bind then
		error("no widget is currently bound to the layout system.")

	elseif lo_bind ~= wid then
		error("this widget is not currently bound to the layout system.")

	elseif lo_stack_i > 0 then
		error("layout stack isn't empty. (More pushes than pops?)")
	end

	lo_bind = false
end


--- Clear all layout state. For use in scenarios where the entire layout procedure is abandoned, like cleaning
-- up after an error.
-- @return Nothing.
function uiLayout.unwindAll()
	lo_bind = false
	lo_stack_i = 0
	for i = #lo_stack, 1, -1 do
		lo_stack[i] = nil
	end
end


--- Push an arbitrary rectangle onto the layout stack, without affecting the bound widget's layout rectangle.
-- @param x Layout X position.
-- @param y Layout Y position.
-- @param w Layout width.
-- @param h Layout height.
-- @return Nothing.
function uiLayout.push(x, y, w, h)
	if not lo_bind then
		error("no widget is bound to the layout system.")
	end

	local rect = incrementStackPointer()

	rect.x = x
	rect.y = y
	rect.w = w
	rect.h = h
end


--- Pop the layout stack, applying its layout rectangle to the bound widget.
-- @return Nothing. Bound rectangle is modified in-place.
function uiLayout.pop()
	local wid = getBoundWidget()
	local rect = decrementStackPointer()

	-- Restore bound widget's layout rectangle
	wid.x = rect.x
	wid.y = rect.y
	wid.w = rect.w
	wid.h = rect.h
end


--[[
	uiLayout.push<Left|Right|Top|Buttom>(): Take a slice of the bound widget's layout rectangle, apply it to the
	widget, and push the remaining layout rectangle onto the layout stack. Later on, pop the stack rectangle
	back onto the widget.
--]]


-- Push left slice onto the stack.
-- @param w Width of the slice.
-- @return Nothing.
function uiLayout.pushLeft(w)
	local wid = getBoundWidget()

	w = math.max(0, w)

	uiLayout.push(wid.x + w, wid.y, math.max(0, wid.w - w), wid.h)

	--wid.x
	--wid.y
	wid.w = w
	--wid.h
end


--- Push right slice onto the stack.
-- @param w Width of the slice.
-- @return Nothing.
function uiLayout.pushRight(w)
	local wid = getBoundWidget()

	w = math.max(0, w)

	uiLayout.push(wid.x + wid.w - w, wid.y, math.max(0, wid.w - w), wid.h)

	wid.x = wid.x + wid.w - w
	--wid.y
	wid.w = w
	--wid.h
end


--- Push top slice onto the stack.
-- @param h Height of the slice.
-- @return Nothing.
function uiLayout.pushTop(h)
	local wid = getBoundWidget()

	h = math.max(0, h)

	uiLayout.push(wid.x, wid.y + h, wid.w, math.max(0, wid.h - h))

	--wid.x
	--wid.y
	--wid.w
	wid.h = h
end


--- Push bottom slice onto the stack.
-- @param h Height of the slice.
-- @return Nothing.
function uiLayout.pushBottom(h)
	local wid = getBoundWidget()

	h = math.max(0, h)

	uiLayout.push(wid.x, wid.y + wid.h - h, wid.w, math.max(0, wid.h - h))

	--wid.x
	wid.y = wid.y + wid.h - h
	--wid.w
	wid.h = h
end


-- * Standalone Functions *


--- Reset a widget's layout rectangle to match its dimensions.
-- @param wid The widget to reset.
-- @return Nothing.
function uiLayout.resetLayout(wid)
	wid.lp_x = 0
	wid.lp_y = 0
	wid.lp_w = wid.w
	wid.lp_h = wid.h
end


--- Reset a widget's layout rectangle to match one of its viewports. The rectangle top-left is (0,0).
-- @param wid The widget to reset.
-- @param v The Viewport ID.
-- @return Nothing.
function uiLayout.resetLayoutPort(wid, v)
	v = widShared.vp_keys[v]

	wid.lp_x = 0
	wid.lp_y = 0
	wid.lp_w = wid[v.w]
	wid.lp_h = wid[v.h]
end


--- Reset a widget's layout rectangle to match one of its viewports. The rectangle top-left is the Viewport's top-left.
-- @param wid The widget to reset.
-- @param v The Viewport ID.
-- @return Nothing.
function uiLayout.resetLayoutPortFull(wid, v)
	v = widShared.vp_keys[v]

	wid.lp_x = wid[v.x]
	wid.lp_y = wid[v.y]
	wid.lp_w = wid[v.w]
	wid.lp_h = wid[v.h]
end


--- Carve the edges of a widget's layout rectangle by a number of pixels on each side.
-- @param wid The widget whose layout will be reduced.
-- @param x_left Pixels to carve on the left side.
-- @param y_top Pixels to carve on the top side.
-- @param x_right Pixels to carve on the right side.
-- @param y_bottom Pixels to carve on the bottom side.
-- @return Nothing.
function uiLayout.edgeCarvePixels(wid, x_left, y_top, x_right, y_bottom)
	wid.lp_w = math.max(0, wid.lp_w - x_left - x_right)
	wid.lp_h = math.max(0, wid.lp_h - y_top - y_bottom)
	wid.lp_x = wid.lp_x + x_left
	wid.lp_y = wid.lp_y + y_top
end


--- Carve the edges of a widget's layout rectangle by a percentage (0.0 - 1.0) on each side.
-- @param wid The widget whose layout will be reduced.
-- @param x_left Percentage (0.0 - 1.0) of width to carve on the left side.
-- @param y_top Percentage (0.0 - 1.0) of height to carve on the top side.
-- @param x_right Percentage (0.0 - 1.0) of width to carve on the right side.
-- @param y_bottom Percentage (0.0 - 1.0) of height to carve on the bottom side.
-- @return Nothing.
function uiLayout.edgeCarveNorm(wid, x_left, y_top, x_right, y_bottom)
	x_left = math.max(0.0, math.min(x_left, 1.0))
	y_top = math.max(0.0, math.min(y_top, 1.0))
	x_right = math.max(0.0, math.min(x_right, 1.0))
	y_bottom = math.max(0.0, math.min(y_bottom, 1.0))

	x_left = math.floor(0.5 + x_left * wid.lp_w)
	y_top = math.floor(0.5 + y_top * wid.lp_h)
	x_right = math.floor(0.5 + x_right * wid.lp_w)
	y_bottom = math.floor(0.5 + y_bottom * wid.lp_h)

	uiLayout.edgeCarvePixels(wid, x_left, y_top, x_right, y_bottom)
end


--[[
uiLayout.discard<Left|Top|Right|Bottom>(): Like the fit functions, but just removes the slice from the parent instead
of assigning a widget to it.
--]]


--- Discard a slice from the left of the parent's layout rectangle.
-- @param parent The parent widget.
-- @param w Width of the discarded area.
-- @return X, Y, width and height of the discarded area.
function uiLayout.discardLeft(parent, w)
	w = math.max(0, w)
	local dx, dy, dw, dh = parent.lp_x, parent.lp_y, w, parent.lp_h

	parent.lp_x = parent.lp_x + w
	parent.lp_w = math.max(0, parent.lp_w - w)

	return dx, dy, dw, dh
end


--- Discard a slice from the right of the parent's layout rectangle.
-- @param parent The parent widget.
-- @param w Width of the discarded area.
-- @return X, Y, width and height of the discarded area.
function uiLayout.discardRight(parent, w)
	w = math.max(0, w)
	local dx, dy, dw, dh = parent.lp_x + parent.lp_w - w, parent.lp_y, w, parent.lp_h

	parent.lp_w = math.max(0, parent.lp_w - w)

	return dx, dy, dw, dh
end


--- Discard a slice from the top of the parent's layout rectangle.
-- @param parent The parent widget.
-- @param h Height of the discarded area.
-- @return X, Y, width and height of the discarded area.
function uiLayout.discardTop(parent, h)
	h = math.max(0, h)
	local dx, dy, dw, dh = parent.lp_x, parent.lp_y, parent.lp_w, h

	parent.lp_y = parent.lp_y + h
	parent.lp_h = math.max(0, parent.lp_h - h)

	return dx, dy, dw, dh
end


--- Discard a slice from the bottom of the parent's layout rectangle.
-- @param parent The parent widget.
-- @param h Height of the discarded area.
-- @return X, Y, width and height of the discarded area.
function uiLayout.discardBottom(parent, h)
	h = math.max(0, h)
	local dx, dy, dw, dh = parent.lp_x, parent.lp_y + parent.lp_h - h, parent.lp_w, h

	parent.lp_h = math.max(0, parent.lp_h - h)

	return dx, dy, dw, dh
end


--[[
uiLayout.fit<Left|Top|Right|Bottom>(): Fit a widget on one side of its parent's layout rectangle, reducing the layout size in the process. The child widget's lateral size is set to that of its parent (so with left or right, the child's height is modified, and with top or bottom, its width is changed).
--]]


--- Fit a widget to the left.
-- @param parent The parent widget.
-- @param wid One of the parent's direct children.
-- @return Nothing.
function uiLayout.fitLeft(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardLeft(parent, wid.w)
end


--- Fit a widget to the Right.
-- @param parent The parent widget.
-- @param wid One of the parent's direct children.
-- @return Nothing.
function uiLayout.fitRight(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardRight(parent, wid.w)
end


--- Fit a widget to the top.
-- @param parent The parent widget.
-- @param wid One of the parent's direct children.
-- @return Nothing.
function uiLayout.fitTop(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardTop(parent, wid.h)
end


--- Fit a widget to the bottom.
-- @param parent The parent widget.
-- @param wid One of the parent's direct children.
-- @return Nothing.
function uiLayout.fitBottom(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardBottom(parent, wid.h)
end


--- Fit a widget to its parent's remaining layout rectangle.
-- @param parent The parent widget.
-- @param wid One of the parent's direct children.
-- @return Nothing.
function uiLayout.fitRemaining(parent, wid)
	wid.x = parent.lp_x
	wid.y = parent.lp_y
	wid.w = math.max(0, parent.lp_w)
	wid.h = math.max(0, parent.lp_h)

	parent.lp_w = 0
	parent.lp_h = 0
end


--- Place a widget based on an absolute position (and optional width and height) stored in the widget. 'Absolute'
-- in this case means without regard for the layout rectangle.
-- @param parent The parent widget (technically unused).
-- @param wid The widget to position.
-- @return Nothing.
function uiLayout.placeAbsolute(parent, wid)
	wid.x = wid.lc_pos_x
	wid.y = wid.lc_pos_y
	wid.w = wid.lc_pos_w or wid.w
	wid.h = wid.lc_pos_h or wid.h
end


--- Place a widget based on a position (and optional width and height) stored in the widget, relative to the top-left
-- corner of the parent's layout rectangle.
-- @param parent The parent widget.
-- @param wid The widget to position.
-- @return Nothing.
function uiLayout.placeRelative(parent, wid)
	wid.x = parent.lp_x + wid.lc_pos_x
	wid.y = parent.lp_y + wid.lc_pos_y
	wid.w = wid.lc_pos_w or wid.w
	wid.h = wid.lc_pos_h or wid.h
end


--- Place a widget based on a rectangle table stored in the parent widget and indexed by a value in the child. The
-- fields 'w' and 'h' are optional, and the widget will keep its existing values if those are not present.
-- @param parent The parent widget.
-- @param wid The widget to position.
-- @return Nothing.
function uiLayout.placeIndex(parent, wid)
	local rect = parent.lp_rects[wid.lc_index]

	if not rect then
		error("no layout rectangle in parent at index: " .. tostring(wid.lc_index))
	end

	wid.x = rect.x
	wid.y = rect.y
	wid.w = rect.w or wid.w
	wid.h = rect.h or wid.h
end


--- Place a widget based on the parent's current layout rectangle, a count of rows and columns, and cell positions
-- in the child. The child widget will be resized to fit the cell.
-- @param parent The parent widget.
-- @param wid The child widget.
-- @return Nothing.
function uiLayout.placeGrid(parent, wid)
	local cols = parent.lp_grid_cols
	local rows = parent.lp_grid_rows

	local c = wid.lc_grid_x
	local r = wid.lc_grid_y

	if cols <= 0 then
		error("parent grid columns must be > 0.")

	elseif rows <= 0 then
		error("parent grid rows must be > 0.")

	elseif c < 1 or c > cols then
		error("widget X cell is out of range (0 - " .. tostring(cols))

	elseif r < 1 or r > rows then
		error("widget Y cell is out of range (0 - " .. tostring(rows))
	end

	local cell_w = math.floor(parent.lp_w / cols)
	local cell_h = math.floor(parent.lp_h / rows)

	wid.x = parent.lp_x + (c-1) * cell_w
	wid.y = parent.lp_y + (r-1) * cell_h
	wid.w = cell_w
	wid.h = cell_h
end


-- * Layout Sequence *


--[[
Layout sequences are stored in widgets at 'self.lp_seq'. Entries in this table are either references to direct
children of the widget, with layout commands ready to be applied, or arbitrary tables with a function at 'lo_command'
which mutate the parent.

applyLayout() binds the current widget to the layout system, and then unbinds it before ending. Layout sequences do not
touch deeper descendants, but you can include calls to applyLayout() in the reshape callbacks of descendants.

The built-in widget remove() method automatically removes any instances of a widget from its parent's layout table.

Code running from applyLayout() should not:
	* Add or remove widgets
	* Add to, or delete from lp_seq
--]]


--- Create a layout sequence table and rectangle in a widget. (You can really just assign a new table to self.lp_seq,
-- but this forces the widget def to require uiLayout, which might be helpful for organizational purposes / grepping.)
-- @param self The widget which will hold the layout sequence.
-- @return Nothing.
function uiLayout.initLayoutSequence(self)
	self.lp_seq = {}

	self.lp_x = 0
	self.lp_y = 0
	self.lp_w = 0
	self.lp_h = 0
end


--- Like initLayoutSequence(), but assigns just the layout rectangle fields to a widget.
-- @param self The widget which will hold the layout rectangle.
-- @return Nothing.
function uiLayout.initLayoutRectangle(self)
	self.lp_x = 0
	self.lp_y = 0
	self.lp_w = 0
	self.lp_h = 0
end


--- Register a child table to its parent layout sequence. The widget must be one of the parent's direct children, and
-- it should only appear once in the list.
-- @param parent The parent widget.
-- @param wid The child widget.
-- @return Nothing.
function uiLayout.register(parent, wid)
	local lp_seq = getLayoutTable(parent)

	if not parent:hasThisChild(wid) then
		error("attempt to register widget that isn't a direct child of the parent.")
	end

	-- Confirm widget doesn't already appear in the parent's layout sequence
	for i = 1, #lp_seq do
		if lp_seq[i] == wid then
			error("widget is already in the parent's layout sequence.")
		end
	end

	table.insert(lp_seq, wid)
end


--- Unregister a widget from its parent layout sequence. The widget must be one of the parent's direct children, and it
-- must currently be in the list.
-- @param parent The parent widget.
-- @param wid The child widget to remove.
-- @return Nothing.
function uiLayout.unregister(parent, wid)
	local lp_seq = getLayoutTable(parent)

	if not parent:hasThisChild(wid) then
		error("attempt to unregister widget that isn't a direct child of the parent.")
	end

	for i = #lp_seq, 1, -1 do
		if lp_seq[i] == wid then
			table.remove(lp_seq, i)
			return
		end
	end

	error("widget not found in layout sequence.")
end


--[[
Use table.insert() and table.remove() to add or delete arbitrary command tables from lp_seq (maybe write some
wrappers with error checking appropriate to your use case).
--]]


--- Apply a widget's layout by looping through its layout sequence.
-- @param parent The widget whose children will be arranged.
-- @return Nothing.
function uiLayout.applyLayout(parent)
	uiLayout.bindWidget(parent)

	local lp_seq = getLayoutTable(parent)

	for i, wid in ipairs(lp_seq) do
		-- lo_command is present: this is not a widget, but an arbitrary table with a command + optional data to run.
		if wid.lo_command then
			wid.lo_command(parent, wid)
		-- Otherwise, treat as a widget.
		else
			if wid._dead == "dead" then
				error("dead widget reference in layout sequence. It should have been cleaned up when removed.")

			elseif not wid.lc_func then
				error("widget has no layout callback function.")
			end

			wid.lc_func(parent, wid, wid.lc_info)
		end
	end

	uiLayout.unbindWidget(parent)
end


return uiLayout
