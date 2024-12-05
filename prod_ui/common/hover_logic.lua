local hoverLogic = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local intersect = require(REQ_PATH .. "intersect")


--- Recursive loop for determining hover-over state for widgets.
-- @param x Mouse X position in UI space.
-- @param y Mouse Y position in UI space.
-- @param os_x X offset for this widget in UI space, such that (x - os_x) is the left side of the widget body.
-- @param os_y Y offset for this widget in UI space, such that (y - os_y) is the top side of the widget body.
-- @param widget The widget being considered.
-- @param x1 Left clipping boundary.
-- @param y1 Top clipping boundary.
-- @param x2 Right clipping boundary.
-- @param y2 Bottom clipping boundary.
-- @return A widget that the mouse is hovering over, or nil if no match was found.
local function _hoverLoop(x, y, os_x, os_y, widget, x1, y1, x2, y2)
	if widget.allow_hover then
		-- Evaluate children first, front-to-back.
		if widget.allow_hover == true and #widget.children > 0 then

			-- Prevents clicking on descendant rectangle areas that are out of bounds of the parent.
			local xx1, yy1, xx2, yy2 = x1, y1, x2, y2

			if widget.clip_hover == true then
				xx1 = math.max(xx1, os_x + widget.x)
				yy1 = math.max(yy1, os_y + widget.y)
				xx2 = math.min(xx2, os_x + widget.x + widget.w)
				yy2 = math.min(yy2, os_y + widget.y + widget.h)

			elseif widget.clip_hover == "manual" then
				xx1 = math.max(xx1, os_x + widget.x + widget.clip_hover_x)
				yy1 = math.max(yy1, os_y + widget.y + widget.clip_hover_y)
				xx2 = math.min(xx2, os_x + widget.x + widget.clip_hover_x + widget.clip_hover_w)
				yy2 = math.min(yy2, os_y + widget.y + widget.clip_hover_y + widget.clip_hover_h)
			end

			local children = widget.children
			for i = #children, 1, -1 do
				local wid = children[i]
				local sub = _hoverLoop(x, y, os_x + widget.x - widget.scr_x, os_y + widget.y - widget.scr_y, wid, xx1, yy1, xx2, yy2)
				if sub then
					return sub
				end
			end
		end

		-- No child responded, children are excluded, or widget has no children.
		if (x >= x1 and y >= y1 and x < x2 and y < y2)
		and intersect.pointToRect(x, y, os_x + widget.x, os_y + widget.y, os_x + widget.x + widget.w, os_y + widget.y + widget.h)
		and widget:ui_evaluateHover(x, y) -- XXX untested. Maybe would be better to pass XY relative to parent?
		then
			return widget
		end
	end
end


--- Check for the mouse pressing on a widget.
local function _pressLoop(x, y, os_x, os_y, widget, x1, y1, x2, y2, button, istouch, presses)
	--[[
	Press detection used to piggy-back off of the hover code: only the current-hovered widget could be
	pressed. It's now split into a separate function and called for every press. While not as efficient,
	it allows the user to click through some widgets in special cases.

	All widgets down the lineage chain must still have the 'allow_hover' field set, and the method
	'ui_evaluatePress' must evaluate to true.
	--]]

	if widget.allow_hover then
		-- Evaluate children first, front-to-back.
		if widget.allow_hover == true and #widget.children > 0 then
			local xx1, yy1, xx2, yy2 = x1, y1, x2, y2

			if widget.clip_hover == true then
				xx1 = math.max(xx1, os_x + widget.x)
				yy1 = math.max(yy1, os_y + widget.y)
				xx2 = math.min(xx2, os_x + widget.x + widget.w)
				yy2 = math.min(yy2, os_y + widget.y + widget.h)

			elseif widget.clip_hover == "manual" then
				xx1 = math.max(xx1, os_x + widget.x + widget.clip_hover_x)
				yy1 = math.max(yy1, os_y + widget.y + widget.clip_hover_y)
				xx2 = math.min(xx2, os_x + widget.x + widget.clip_hover_x + widget.clip_hover_w)
				yy2 = math.min(yy2, os_y + widget.y + widget.clip_hover_y + widget.clip_hover_h)
			end

			local children = widget.children
			for i = #children, 1, -1 do
				local wid = children[i]
				local sub = _pressLoop(x, y, os_x + widget.x - widget.scr_x, os_y + widget.y - widget.scr_y, wid, xx1, yy1, xx2, yy2, button, istouch, presses)
				if sub then
					return sub
				end
			end
		end

		-- No child responded, children are excluded, or widget has no children.
		if (x >= x1 and y >= y1 and x < x2 and y < y2)
		and intersect.pointToRect(x, y, os_x + widget.x, os_y + widget.y, os_x + widget.x + widget.w, os_y + widget.y + widget.h)
		and widget:ui_evaluatePress(x, y, button, istouch, presses)
		then
			return widget
		end
	end
end


function hoverLogic.checkPressed(context, button, istouch, presses)
	if context.tree then
		return _pressLoop(context.mouse_x, context.mouse_y, 0, 0, context.tree, -2^53, -2^53, 2^53, 2^53, button, istouch, presses)
	end
end


function hoverLogic.update(context, dx, dy)
	if context.tree then
		-- Hover state

		--[[
		I couldn't think of a good way to separate 'hover on' and 'hover off' from 'entered bounds' and 'left bounds'.
		The problem is that the hover-off callback will fire for a container if a mouse pointer wanders into the shape
		of one of its children.

		The workaround is to bubble up the hover-off callback, and check if the originating widget is part of the
		widget's lineage (children, grandchildren, etc.). If it is, false alarm. If not, then the pointer is considered
		to have exited.

		Note that on some operating systems (Fedora 36), even if the root widget is as large as the window, the user
		can still generate mouse-moved events outside of the window by holding down a mouse button and then moving the
		cursor. (XXX: mouse positions are being clamped in LÖVE 11.5 or 12.)
		--]]

		local wid

		-- A mouse button is being held down: update drag-dest reference.
		if context.mouse_pressed_button then
			local old_drag_dest = context.current_drag_dest
			wid = _hoverLoop(context.mouse_x, context.mouse_y, 0, 0, context.tree, -2^53, -2^53, 2^53, 2^53)

			if not wid or wid ~= old_drag_dest then
				if old_drag_dest then
					context.current_drag_dest = false
					old_drag_dest:bubbleStatement("uiCall_pointerDragDestOff", old_drag_dest, context.mouse_x, context.mouse_y, dx, dy)
				end
			end

			if wid then
				if wid ~= old_drag_dest then
					context.current_drag_dest = wid
					wid:bubbleStatement("uiCall_pointerDragDestOn", context.current_drag_dest, context.mouse_x, context.mouse_y, dx, dy)
				end
				wid:bubbleStatement("uiCall_pointerDragDestMove", context.current_drag_dest, context.mouse_x, context.mouse_y, dx, dy)
			end
		-- No mouse buttons are active: update hover state.
		else
			-- Must have both window and mouse focus for hover state. If either is not true,
			-- remove any existing hover.
			if not (context.window_focus and context.mouse_focus) then -- XXX needs testing across different operating systems.
				-- Remove any existing hover state.
				local old_hover = context.current_hover
				context.current_hover = false
				if old_hover then
					old_hover:bubbleStatement("uiCall_pointerHoverOff", old_hover, context.mouse_x, context.mouse_y, dx, dy)
				end
			else
				local old_hover = context.current_hover
				wid = _hoverLoop(context.mouse_x, context.mouse_y, 0, 0, context.tree, -2^53, -2^53, 2^53, 2^53)

				if not wid or wid ~= old_hover then
					if old_hover then
						context.current_hover = false
						old_hover:bubbleStatement("uiCall_pointerHoverOff", old_hover, context.mouse_x, context.mouse_y, dx, dy)
					end
				end

				if wid then
					if wid ~= old_hover then
						context.current_hover = wid
						wid:bubbleStatement("uiCall_pointerHoverOn", context.current_hover, context.mouse_x, context.mouse_y, dx, dy)
					end
					wid:bubbleStatement("uiCall_pointerHoverMove", context.current_hover, context.mouse_x, context.mouse_y, dx, dy)
				end
			end
		end

		-- Handle pointer drag statement.
		wid = context.current_pressed
		if wid then
			wid:bubbleStatement("uiCall_pointerDrag", wid, context.mouse_x, context.mouse_y, dx, dy)
		end
	end
end


return hoverLogic
