-- Handlers for some love.*() callbacks and virtual events, which may need to be called multiple
-- times from different source files.


local eventHandlers = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local hoverLogic = require(REQ_PATH .. "hover_logic")


function eventHandlers.mousemoved(context, x, y, dx, dy, istouch)

	-- Update mouse position
	context.mouse_x = x
	context.mouse_y = y

	-- Update click-sequence origin if the mouse is being held.
	if context.mouse_pressed_button then
		context.cseq_x = x
		context.cseq_y = y
	end

	-- Event capture
	local cap_cur = context.captured_focus
	if cap_cur and cap_cur.uiCap_mouseMoved and cap_cur:uiCap_mouseMoved(x, y, dx, dy, istouch) then
		return
	end

	hoverLogic.update(context, dx, dy)
end


return eventHandlers
