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


local viewport_keys = require(REQ_PATH .. "common.viewport_keys")


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
	v = viewport_keys[v]

	wid.lp_x = 0
	wid.lp_y = 0
	wid.lp_w = wid[v.w]
	wid.lp_h = wid[v.h]
end


--- Reset a widget's layout rectangle to match one of its viewports. The rectangle top-left is the Viewport's top-left.
-- @param wid The widget to reset.
-- @param v The Viewport ID.
function uiLayout.resetLayoutPortFull(wid, v)
	v = viewport_keys[v]

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
	wid:uiCall_relayoutPre(true, wid.w, parent.lp_h)

	wid.x, wid.y, wid.w, wid.h = uiLayout.discardLeft(parent, math.max(wid.min_w, math.min(wid.max_w, wid.w)))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["fit-right"] = function(parent, wid)
	wid:uiCall_relayoutPre(true, wid.w, parent.lp_h)

	wid.x, wid.y, wid.w, wid.h = uiLayout.discardRight(parent, math.max(wid.min_w, math.min(wid.max_w, wid.w)))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["fit-top"] = function(parent, wid)
	wid:uiCall_relayoutPre(false, parent.lp_w, wid.h)

	wid.x, wid.y, wid.w, wid.h = uiLayout.discardTop(parent, math.max(wid.min_h, math.min(wid.max_h, wid.h)))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["fit-bottom"] = function(parent, wid)
	wid:uiCall_relayoutPre(false, parent.lp_w, wid.h)

	wid.x, wid.y, wid.w, wid.h = uiLayout.discardBottom(parent, math.max(wid.min_h, math.min(wid.max_h, wid.h)))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["fit-remaining"] = function(parent, wid)
	wid:uiCall_relayoutPre(nil, parent.lp_w, parent.lp_h)

	wid.x = parent.lp_x
	wid.y = parent.lp_y
	wid.w = math.max(wid.min_w, math.min(wid.max_w, parent.lp_w))
	wid.h = math.max(wid.min_h, math.min(wid.max_h, parent.lp_h))

	parent.lp_w = 0
	parent.lp_h = 0

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["overlay-remaining"] = function(parent, wid)
	wid:uiCall_relayoutPre(nil, parent.lp_w, parent.lp_h)

	wid.x = parent.lp_x
	wid.y = parent.lp_y
	wid.w = math.max(wid.min_w, math.min(wid.max_w, parent.lp_w))
	wid.h = math.max(wid.min_h, math.min(wid.max_h, parent.lp_h))

	wid:uiCall_relayoutPost()
end


--[[
static

No effect. Use to register a widget to the layout system so that it still gets attention
with respect to clamping and reshaping.
--]]


uiLayout.handlers["static"] = function(parent, wid)
	wid:uiCall_relayoutPre(nil, wid.w, wid.h)
	wid:uiCall_relayoutPost()
end


--[[
('scaled' variants are affected by the context UI scale.)

place-absolute
place-absolute-scaled

Places a widget based on an absolute position (and optional width and height) stored in the widget. 'Absolute'
in this case means without regard for the layout rectangle.


place-relative
place-relative-scaled

Places a widget based on a position (and optional width and height) stored in the widget, relative to the top-left
corner of the parent's layout rectangle.


place-index
place-index-scaled

Places a widget based on a rectangle table stored in the parent widget and indexed by a value in the child. The
fields 'w' and 'h' are optional, and the widget will keep its existing values if those are not present.


place-grid

Places a widget based on the parent's current layout rectangle, a count of rows and columns, and cell positions
in the child. The child widget will be resized to fit the cell.
--]]


uiLayout.handlers["place-absolute"] = function(parent, wid)
	local ww, hh = wid.lc_pos_w or wid.w, wid.lc_pos_h or wid.h

	wid:uiCall_relayoutPre(nil, ww, hh)

	wid.x = wid.lc_pos_x
	wid.y = wid.lc_pos_y
	wid.w = math.max(wid.min_w, math.min(wid.max_w, ww))
	wid.h = math.max(wid.min_h, math.min(wid.max_h, hh))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["place-absolute-scaled"] = function(parent, wid)
	local ww, hh = wid.lc_pos_w or wid.w, wid.lc_pos_h or wid.h

	wid:uiCall_relayoutPre(nil, ww, hh)

	local scale = wid.context.scale

	wid.x = math.floor(wid.lc_pos_x * scale)
	wid.y = math.floor(wid.lc_pos_y * scale)
	wid.w = math.floor(math.max(wid.min_w, math.min(wid.max_w, ww)) * scale)
	wid.h = math.floor(math.max(wid.min_h, math.min(wid.max_h, hh)) * scale)

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["place-relative"] = function(parent, wid)
	local ww, hh = wid.lc_pos_w or wid.w, wid.lc_pos_h or wid.h

	wid:uiCall_relayoutPre(nil, ww, hh)

	wid.x = parent.lp_x + wid.lc_pos_x
	wid.y = parent.lp_y + wid.lc_pos_y
	wid.w = math.max(wid.min_w, math.min(wid.max_w, ww))
	wid.h = math.max(wid.min_h, math.min(wid.max_h, hh))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["place-relative-scaled"] = function(parent, wid)
	local ww, hh = wid.lc_pos_w or wid.w, wid.lc_pos_h or wid.h

	wid:uiCall_relayoutPre(nil, ww, hh)

	local scale = wid.context.scale

	wid.x = math.floor((parent.lp_x + wid.lc_pos_x) * scale)
	wid.y = math.floor((parent.lp_y + wid.lc_pos_y) * scale)
	wid.w = math.floor(math.max(wid.min_w, math.min(wid.max_w, ww)) * scale)
	wid.h = math.floor(math.max(wid.min_h, math.min(wid.max_h, hh)) * scale)

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["place-index"] = function(parent, wid)
	local rect = parent.lp_rects[wid.lc_index]

	if not rect then
		error("no layout rectangle in parent at index: " .. tostring(wid.lc_index))
	end

	local ww, hh = rect.w or wid.w, rect.h or wid.h

	wid:uiCall_relayoutPre(nil, ww, hh)

	wid.x = rect.x
	wid.y = rect.y
	wid.w = math.max(wid.min_w, math.min(wid.max_w, ww))
	wid.h = math.max(wid.min_h, math.min(wid.max_h, hh))

	wid:uiCall_relayoutPost()
end


uiLayout.handlers["place-index-scaled"] = function(parent, wid)
	local rect = parent.lp_rects[wid.lc_index]

	if not rect then
		error("no layout rectangle in parent at index: " .. tostring(wid.lc_index))
	end

	local ww, hh = rect.w or wid.w, rect.h or wid.h

	wid:uiCall_relayoutPre(nil, ww, hh)

	local scale = wid.context.scale

	wid.x = math.floor(rect.x * scale)
	wid.y = math.floor(rect.y * scale)
	wid.w = math.floor(math.max(wid.min_w, math.min(wid.max_w, ww)) * scale)
	wid.h = math.floor(math.max(wid.min_h, math.min(wid.max_h, hh)) * scale)

	wid:uiCall_relayoutPost()
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

	wid:uiCall_relayoutPre(nil, cell_w, cell_h)

	wid.x = parent.lp_x + (c-1) * cell_w
	wid.y = parent.lp_y + (r-1) * cell_h
	wid.w = math.max(wid.min_w, math.min(wid.max_w, cell_w))
	wid.h = math.max(wid.min_h, math.min(wid.max_h, cell_h))

	wid:uiCall_relayoutPost()
end


-- * Layout Sequence *


--[[
Layout sequences are stored in widgets at 'self.lay_seq'. Entries in this table are either references to direct
children of the widget, with layout commands ready to be applied, or arbitrary tables with a function at 'lo_command'
which mutate the parent.

The built-in widget remove() method automatically removes any instances of a widget from its parent's layout table.

Code running from reshape() should not:
	* Add or remove widgets
	* Add to, or delete from lay_seq
--]]


--- Create a layout sequence table and rectangle in a widget.
-- @param self The widget which will hold the layout sequence.
function uiLayout.initLayoutSequence(self)
	self.lay_seq = {}

	self.lp_x = 0
	self.lp_y = 0
	self.lp_w = 0
	self.lp_h = 0
end


return uiLayout
