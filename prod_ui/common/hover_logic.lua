local hoverLogic = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local commonMath = require(REQ_PATH .. "common_math")


--- Recursive loop for determining hover-over state for widgets.
-- @param x, y Mouse X and Y positions in UI space.
-- @param os_x, os_y X and Y offsets for this widget in UI space, such that (x - os_x) and (y - os_y) are the top-left side of the widget body.
-- @param widget The widget being considered.
-- @param x1, y1, x2, y2 Left, top, right and bottom clipping boundaries.
-- @return The widget that the mouse is hovering over, or nil if no match was found.
local function _hoverLoop(x, y, os_x, os_y, widget, x1, y1, x2, y2)
	if widget.allow_hover
	and x >= x1 and y >= y1 and x < x2 and y < y2
	and widget:ui_evaluateHover(x, y, os_x, os_y)
	then
		-- Evaluate descendants front-to-back, depth-first.
		if #widget.children > 0 then
			-- Update the hover clipping rectangle for recursive calls
			if widget.clip_hover == true then
				x1 = math.max(x1, os_x + widget.x)
				y1 = math.max(y1, os_y + widget.y)
				x2 = math.min(x2, os_x + widget.x + widget.w)
				y2 = math.min(y2, os_y + widget.y + widget.h)

			elseif widget.clip_hover == "manual" then
				x1 = math.max(x1, os_x + widget.x + widget.clip_hover_x)
				y1 = math.max(y1, os_y + widget.y + widget.clip_hover_y)
				x2 = math.min(x2, os_x + widget.x + widget.clip_hover_x + widget.clip_hover_w)
				y2 = math.min(y2, os_y + widget.y + widget.clip_hover_y + widget.clip_hover_h)
			end

			local children = widget.children
			for i = #children, 1, -1 do
				local wid = children[i]
				local sub = _hoverLoop(x, y, os_x + widget.x - widget.scr_x, os_y + widget.y - widget.scr_y, wid, x1, y1, x2, y2)
				if sub then
					return sub
				end
			end
		end
		return widget
	end
end


--- Check for the mouse pressing on a widget.
local function _pressLoop(x, y, os_x, os_y, widget, x1, y1, x2, y2, button, istouch, presses)
	--[[
	Press detection used to piggy-back off of the hover code: only the current-hovered widget could be
	pressed. It's now split into a separate function, and called for every press. While not as efficient,
	it allows the user to click through some widgets in special cases.

	All widgets in the hierarchy must still have the 'allow_hover' field set, and the method
	'ui_evaluatePress' must evaluate to true.
	--]]

	if widget.allow_hover
	and x >= x1 and y >= y1 and x < x2 and y < y2
	and widget:ui_evaluatePress(x, y, os_x, os_y, button, istouch, presses)
	then
		-- Evaluate descendants front-to-back, depth-first.
		if #widget.children > 0 then
			-- Update the press clipping rectangle for recursive calls
			if widget.clip_hover == true then
				x1 = math.max(x1, os_x + widget.x)
				y1 = math.max(y1, os_y + widget.y)
				x2 = math.min(x2, os_x + widget.x + widget.w)
				y2 = math.min(y2, os_y + widget.y + widget.h)

			elseif widget.clip_hover == "manual" then
				x1 = math.max(x1, os_x + widget.x + widget.clip_hover_x)
				y1 = math.max(y1, os_y + widget.y + widget.clip_hover_y)
				x2 = math.min(x2, os_x + widget.x + widget.clip_hover_x + widget.clip_hover_w)
				y2 = math.min(y2, os_y + widget.y + widget.clip_hover_y + widget.clip_hover_h)
			end

			local children = widget.children
			for i = #children, 1, -1 do
				local wid = children[i]
				local sub = _pressLoop(x, y, os_x + widget.x - widget.scr_x, os_y + widget.y - widget.scr_y, wid,
					x1, y1, x2, y2, button, istouch, presses
				)
				if sub then
					return sub
				end
			end
		end
		return widget
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
					old_drag_dest:cycleEvent("uiCall_pointerDragDestOff", old_drag_dest, context.mouse_x, context.mouse_y, dx, dy)
				end
			end

			if wid then
				if wid ~= old_drag_dest then
					context.current_drag_dest = wid
					wid:cycleEvent("uiCall_pointerDragDestOn", context.current_drag_dest, context.mouse_x, context.mouse_y, dx, dy)
				end
				wid:cycleEvent("uiCall_pointerDragDestMove", context.current_drag_dest, context.mouse_x, context.mouse_y, dx, dy)
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
					old_hover:cycleEvent("uiCall_pointerHoverOff", old_hover, context.mouse_x, context.mouse_y, dx, dy)
				end
			else
				local old_hover = context.current_hover
				wid = _hoverLoop(context.mouse_x, context.mouse_y, 0, 0, context.tree, -2^53, -2^53, 2^53, 2^53)

				if not wid or wid ~= old_hover then
					if old_hover then
						context.current_hover = false
						old_hover:cycleEvent("uiCall_pointerHoverOff", old_hover, context.mouse_x, context.mouse_y, dx, dy)
					end
				end

				if wid then
					if wid ~= old_hover then
						context.current_hover = wid
						wid:cycleEvent("uiCall_pointerHoverOn", context.current_hover, context.mouse_x, context.mouse_y, dx, dy)
					end
					wid:cycleEvent("uiCall_pointerHoverMove", context.current_hover, context.mouse_x, context.mouse_y, dx, dy)
				end
			end
		end

		-- Handle pointer drag statement.
		wid = context.current_pressed
		if wid then
			wid:cycleEvent("uiCall_pointerDrag", wid, context.mouse_x, context.mouse_y, dx, dy)
		end
	end
end


return hoverLogic
