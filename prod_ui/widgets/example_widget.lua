-- This is a commented example widget. It should load without errors, but it doesn't do anything useful at run time.


-- The loader provides the UI context and an arbitrary config table (if provided). The context table
-- includes paths and methods that help with loading and caching ProdUI source files.
local context, def_conf = select("#", ...)


-- Values placed in 'def' will be accessible from instances through the __index metamethod. (We
-- will 'return def' at the end of this source file.)
local def = {}


-- If the widget is skinned, a default 'skin_id' can go here.
--def.skin_id = "foobar"


-- If the widget is skinned, place the built-in skinner implementations here.
-- The default built-in skinner should be named: "default"
--[[
def.skinners = {
	default = {
		-- Installs the skin into the widget.
		-- Called by wid:skinInstall().
		install = function() end,

		-- Removes the skin from the widget.
		-- Called by wid:skinRemove().
		remove = function() end,

		-- Updates the skin state (after a state change to the widget).
		-- Called by wid:skinRefresh()
		refresh = function() end,

		-- Per-frame update callback for the skin.
		-- Called by wid:skinUpdate()
		update = function(dt) end,

		-- Copied to: wid.render
		render = function() end,

		-- Copied to: wid.renderLast
		renderLast = function() end,

		-- Copied to: wid.renderThimble
		renderThimble = function() end,
	},
}
--]]


--function def:uiCall_create(inst)
--function def:uiCall_destroy(inst)
--function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:ui_evaluateHover(mx, my, os_x, os_y)
--function def:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)
--function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
--function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
--function def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)
--function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
--function def:uiCall_pointerDrag(inst, x, y, dx, dy)
--function def:uiCall_pointerWheel(x, y)
--function def:uiCall_pointerDragDestOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerDragDestOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerDragDestMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerDragDestRelease(inst, x, y, button, istouch, presses)
--function def:uiCall_thimble1Take(inst, a, b, c, d)
--function def:uiCall_thimble2Take(inst, a, b, c, d)
--function def:uiCall_thimble1Release(inst, a, b, c, d)
--function def:uiCall_thimble2Release(inst, a, b, c, d)
--function def:uiCall_thimbleTopTake(inst, a, b, c, d)
--function def:uiCall_thimbleTopRelease(inst, a, b, c, d)
--function def:uiCall_thimble1Changed(inst, a, b, c, d)
--function def:uiCall_thimble2Changed(inst, a, b, c, d)
--function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
--function def:uiCall_thimbleAction2(inst, key, scancode, isrepeat)
--function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
--function def:uiCall_keyReleased(inst, key, scancode)
--function def:uiCall_textInput(inst, text)
--function def:uiCall_capture(inst)
--function def:uiCall_uncapture(inst)
--function def:uiCall_captureTick(dt)
--function def:uiCall_reshape(recursive)
--function def:uiCall_resize()
--function def:render(os_x, os_y)
--function def:renderLast(os_x, os_y)
--function def:renderThimble()
--function def:uiCall_update(dt)
--function def:uiCall_windowFocus(focus)
--function def:uiCall_mouseFocus(focus)
--function def:uiCall_windowVisible(visible)
--function def:uiCall_windowResize(w, h)
--function def:uiCall_joystickAdded(joystick)
--function def:uiCall_joystickRemoved(joystick)
--function def:uiCall_joystickPressed(inst, joystick, button)
--function def:uiCall_joystickPressed(inst, joystick, button)
--function def:uiCall_joystickAxis(inst, joystick, axis, value)
--function def:uiCall_joystickHat(inst, joystick, hat, direction)
--function def:uiCall_gamepadPressed(inst, joystick, button)
--function def:uiCall_gamepadReleased(inst, joystick, button)
--function def:uiCall_gamepadAxis(inst, joystick, axis, value)


--[[
function def:uiCap_windowResize(w, h) -- (love.resize)

function def:uiCap_keyPressed(key, scancode, isrepeat)
function def:uiCap_keyReleased(key, scancode)

function def:uiCap_textEdited(text, start, length)
function def:uiCap_textInput(text)

function def:uiCap_mouseFocus(focus)
function def:uiCap_wheelMoved(x, y)

function def:uiCap_mouseMoved(x, y, dx, dy, istouch)
^ Warning: mouse hover state is not updated automatically when this is in effect.

function def:uiCap_mousePressed(x, y, button, istouch, presses)
function def:uiCap_mouseReleased(x, y, button, istouch, presses)

function def:uiCap_virtualMouseRepeat(x, y, button, istouch, reps)

function def:uiCap_windowFocus(focus)
function def:uiCap_mouseFocus(focus)

function def:uiCap_windowVisible(visible)

function def:uiCap_joystickAdded(joystick)
function def:uiCap_joystickRemoved(joystick)
function def:uiCap_joystickPressed(joystick, button)
function def:uiCap_joystickReleased(joystick, button)
function def:uiCap_joystickAxis(joystick, axis, value)
function def:uiCap_joystickHat(joystick, hat, direction)

function def:uiCap_gamepadPressed(joystick, button)
function def:uiCap_gamepadReleased(joystick, button)
function def:uiCap_gamepadAxis(joystick, axis, value)
--]]


return def
