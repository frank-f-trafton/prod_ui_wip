-- ProdUI: Layout system.


--[[
	Variable prefixes:
	lo_ -- General layout variable, or something internal to uiLayout.
	lp_ -- Layout variable associated with parent widget
	lc_ -- Layout variable associated with a child widget
--]]


local uiLayout = {}


uiLayout.handlers = {}


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


-- * Getter-assertion combos *


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


--- Clear all layout state. For use in scenarios where the entire layout procedure is abandoned, like cleaning
-- up after an error.
function uiLayout.unwindAll()
	lo_stack_i = 0
	for i = #lo_stack, 1, -1 do
		lo_stack[i] = nil
	end
end


--- Push an arbitrary rectangle onto the layout stack.
-- @param x Layout X position.
-- @param y Layout Y position.
-- @param w Layout width.
-- @param h Layout height.
function uiLayout.push(x, y, w, h)
	local rect = incrementStackPointer()

	rect.x = x
	rect.y = y
	rect.w = w
	rect.h = h
end


--- Pop the layout stack.
function uiLayout.pop()
	local rect = decrementStackPointer()

	return rect.x, rect.y, rect.w, rect.h
end


-- * Standalone Functions *


--- Reset a widget's layout rectangle to match its dimensions.
-- @param wid The widget to reset.
function uiLayout.resetLayout(wid)
	wid.lp_x = 0
	wid.lp_y = 0
	wid.lp_w = wid.w
	wid.lp_h = wid.h
end


--- Reset a widget's layout rectangle to match one of its viewports. Because scrolling is assumed, the
--	rectangle top-left is (0,0).
-- @param wid The widget to reset.
-- @param v The Viewport ID.
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
fit-left
fit-top
fit-right
fit-bottom

Fits a widget on one side of its parent's layout rectangle, reducing the layout size in the process. The child widget's lateral size is set to that of its parent (so with left or right, the child's height is modified, and with top or bottom, its width is changed).


fit-remaining

Fits a widget to its parent's remaining layout rectangle.


overlay-remaining

Places a widget over its parent's remaining layout rectangle, without subtracting its width and height.
--]]


uiLayout.handlers["fit-left"] = function(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardLeft(parent, wid.w)
end


uiLayout.handlers["fit-right"] = function(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardRight(parent, wid.w)
end


uiLayout.handlers["fit-top"] = function(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardTop(parent, wid.h)
end


uiLayout.handlers["fit-bottom"] = function(parent, wid)
	wid.x, wid.y, wid.w, wid.h = uiLayout.discardBottom(parent, wid.h)
end


uiLayout.handlers["fit-remaining"] = function(parent, wid)
	wid.x = parent.lp_x
	wid.y = parent.lp_y
	wid.w = math.max(0, parent.lp_w)
	wid.h = math.max(0, parent.lp_h)

	parent.lp_w = 0
	parent.lp_h = 0
end


uiLayout.handlers["overlay-remaining"] = function(parent, wid)
	wid.x = parent.lp_x
	wid.y = parent.lp_y
	wid.w = math.max(0, parent.lp_w)
	wid.h = math.max(0, parent.lp_h)
end


--[[
static

No effect. Use to register a widget to the layout system so that it still gets attention
with respect to clamping and reshaping.
--]]


uiLayout.handlers["static"] = function() end


--[[
place-absolute

Places a widget based on an absolute position (and optional width and height) stored in the widget. 'Absolute'
in this case means without regard for the layout rectangle.


place-relative

Places a widget based on a position (and optional width and height) stored in the widget, relative to the top-left
corner of the parent's layout rectangle.


place-index

Places a widget based on a rectangle table stored in the parent widget and indexed by a value in the child. The
fields 'w' and 'h' are optional, and the widget will keep its existing values if those are not present.


place-grid

Places a widget based on the parent's current layout rectangle, a count of rows and columns, and cell positions
in the child. The child widget will be resized to fit the cell.
--]]


uiLayout.handlers["place-absolute"] = function(parent, wid)
	wid.x = wid.lc_pos_x
	wid.y = wid.lc_pos_y
	wid.w = wid.lc_pos_w or wid.w
	wid.h = wid.lc_pos_h or wid.h
end


uiLayout.handlers["place-relative"] = function(parent, wid)
	wid.x = parent.lp_x + wid.lc_pos_x
	wid.y = parent.lp_y + wid.lc_pos_y
	wid.w = wid.lc_pos_w or wid.w
	wid.h = wid.lc_pos_h or wid.h
end


uiLayout.handlers["place-index"] = function(parent, wid)
	local rect = parent.lp_rects[wid.lc_index]

	if not rect then
		error("no layout rectangle in parent at index: " .. tostring(wid.lc_index))
	end

	wid.x = rect.x
	wid.y = rect.y
	wid.w = rect.w or wid.w
	wid.h = rect.h or wid.h
end


uiLayout.handlers["place-grid"] = function(parent, wid)
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

The built-in widget remove() method automatically removes any instances of a widget from its parent's layout table.

Code running from reshape() should not:
	* Add or remove widgets
	* Add to, or delete from lp_seq
--]]


--- Create a layout sequence table and rectangle in a widget.
-- @param self The widget which will hold the layout sequence.
function uiLayout.initLayoutSequence(self)
	self.lp_seq = {}

	self.lp_x = 0
	self.lp_y = 0
	self.lp_w = 0
	self.lp_h = 0
end


return uiLayout
