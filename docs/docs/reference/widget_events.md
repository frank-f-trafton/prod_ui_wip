# Widget Events

This page lists ProdUI's built-in widget events.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_gamepadReleased

A held gamepad button was released.


### Propagation Method

TODO


### Event Origin

[love.gamepadreleased](https://love2d.org/wiki/love.gamepadreleased)


### Signature

`def:uiCall_gamepadReleased(inst, joystick, button)`


#### Parameters

* `inst` (ui:Widget) The target widget instance.

* `joystick` (love:Joystick) The joystick associated with the event.

* `button` (love:GamepadButton) The ID of the released gamepad button.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_gamepadAxis

A gamepad axis moved.


### Propagation Method

TODO


### Event Origin

[love.gamepadaxis](https://love2d.org/wiki/love.gamepadaxis)


### Signature

`def:uiCall_gamepadAxis(inst, joystick, axis, value)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.

* `joystick`: (love:Joystick) The joystick associated with the event.

* `value`: (Number) The value of the axis.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_gamepadPressed

A gamepad button was pressed.


### Propagation Method

TODO


### Event Origin

[love.gamepadpressed](https://love2d.org/wiki/love.gamepadpressed)


### Signature

`def:uiCall_gamepadPressed(inst, joystick, button)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.

* `joystick`: (love:Joystick) The joystick associated with the event.

* `button`: (love:GamepadButton) The button ID.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_joystickHat

A joystick POV hat moved.


### Propagation Method

TODO


### Event Origin

[love.joystickhat](https://love2d.org/wiki/love.joystickhat)


### Signature

`def:uiCall_joystickHat(inst, joystick, hat, direction)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.

* `joystick`: (love:Joystick) The joystick associated with the event.

* `hat`: (Number) The hat index.

* `direction`: (love:JoystickHat) The hat direction.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_joystickAxis

A joystick axis moved.


### Propagation Method

TODO


### Event Origin

[love.joystickaxis](https://love2d.org/wiki/love.joystickaxis)


### Signature

`def:uiCall_joystickAxis(inst, joystick, axis, value)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.

* `joystick`: (love:Joystick) The joystick associated with the event.

* `axis`: (Number) The axis index.

* `value`: (Number) The axis value.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_joystickReleased

A joystick button was released.


### Propagation Method

TODO


### Event Origin

[love.joystickreleased](https://love2d.org/wiki/love.joystickreleased)


### Signature

`def:uiCall_joystickReleased(inst, joystick, button)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.

* `joystick`: (love:Joystick) The joystick associated with the event.

* `button`: (number) The button index.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_joystickPressed

A joystick button was pressed.


### Propagation Method

TODO


### Event Origin

[love.joystickpressed](https://love2d.org/wiki/love.joystickpressed)


### Signature

`def:uiCall_joystickPressed(inst, joystick, button)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.

* `joystick`: (love:Joystick) The joystick associated with the event.

* `button`: (number) The button index.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_windowVisible

The application window's visibility changed.


### Propagation Method

Sent to root.


### Event Origin

[love.visible](https://love2d.org/wiki/love.visible)


### Signature

`def:uiCall_windowVisible(visible)`


#### Parameters

* `visible`: (Boolean) True if the window is visible, false if not.


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_windowResize

The application window was resized.


### Propagation Method

Sent to root.


### Event Origin

[love.resize](https://love2d.org/wiki/love.resize)


### Signature

`def:uiCall_windowResize(w, h)`


#### Parameters

* `w`, `h`: (Number) The new window width and height.


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_joystickAdded

A joystick was connected.


### Propagation Method

Sent to root.


### Event Origin

[love.joystickadded](https://love2d.org/wiki/love.joystickadded)


### Signature

`def:uiCall_joystickAdded(joystick)`


#### Parameters

* `joystick`: (love:Joystick) The joystick associated with the event.


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_joystickRemoved

A joystick was disconnected.


### Propagation Method

Sent to root.


### Event Origin

[love.joystickremoved](https://love2d.org/wiki/love.joystickremoved)


### Signature

`def:uiCall_joystickRemoved(joystick)`


#### Parameters

* `joystick`: (love:Joystick) The joystick associated with the event.


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_update

A per-frame update callback for widgets.


### Propagation Method

Broadcast down.


### Event Origin

[love.update](https://love2d.org/wiki/love.update)


### Signature

def:uiCall_update(dt)


#### Parameters

* `dt`: (Number) This frame's delta time.


#### Returns

True to halt event propagation to this widget's children.


### Notes

This is run in `prodUI.love_update()`, starting with `context.root` and traversing its children depth-first.

Return true to explicitly prevent updating a widget's children. (If `uiCall_update` doesn't exist in the widget, children will be updated.)

There are many limitations in effect when the context is locked for updating. Anything that is likely to mess up tree traversal (remove or reorder widgets; change tree root) will raise an error. You can defer these actions to after the update loop using `context:appendAsyncAction()`.

Widgets may or may not have a built-in `uiCall_update` method. To run your own per-frame behavior, you can assign `self:userUpdate(dt)`, which is run before `uiCall_update`.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_windowFocus

The application window focus changed.


### Propagation Method

Sent to root.


### Event Origin

[love.focus](https://love2d.org/wiki/love.focus)


### Signature

`def:uiCall_windowFocus(focus)`


#### Parameters

* `focus`: (Boolean) True if the window has focus, false if not.


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_mouseFocus

The application window's mouse focus changed.


### Propagation Method

Sent to root.


### Event Origin

[love.mousefocus](https://love2d.org/wiki/love.mousefocus)


### Signature

`def:uiCall_mouseFocus(focus)`


#### Parameters

* `focus`: (Boolean) True if the window has mouse focus, false if not.


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_reshape

A widget called `self:reshape()` or `self:reshapeDescendants()`.


### Propagation Method

Broadcast down.


### Event Origin

* `widget:reshape()`
* `widget:reshapeDescendants()`


### Signature

`def:uiCall_reshape()`


#### Returns

True to halt event propagation.


### Notes

Be careful about calling `wid:reshape()` on children within `uiCall_reshape()`, since `wid:reshape()` itself can call descendants recursively.

Reshaping is intended to modify a widget's content (children, minor visual details etc.), and not its current dimensions and position within its parent. There are some exceptions:

1) The root widget doesn't have a parent, so it makes sense to update its dimensions to match the application window.

2) You have free-floating window frames which must be clamped to their parent container, and their positions and sizes do not affect their siblings.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_resize

(TODO: description.)


### Propagation Method

TODO


### Event Origin

`widget:resize()`


### Signature

TODO


#### Returns

TODO


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_initialize

A new widget is being initialized.


### Propagation Method

Sent to widget.


### Event Origin

`widget:initialize()`


### Signature

`def:uiCall_initialize(...)`


#### Parameters

* `...`: (Any) Arguments for the widget setup callback.


#### Returns

Nothing.


### Notes

In your documentation, please list:

* Mandatory ahead-of-time fields
* Optional ahead-of-time fields

Assume that all other fields are assigned defaults, and that the caller must set them after successful instance creation.

If present, `self:userInitialize()` is run after this. (It's incredibly redundant as you have to pass it in ahead of time, but it pairs with `self:userDestroy()`.)


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_destroy

A widget was removed from the context.


### Propagation Method

bubbleEvent.


### Event Origin

`widget:remove()`


### Signature

`def:uiCall_destroy(inst)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.


#### Returns

True to halt event propagation.


### Notes

If present, `widget:userDestroy()` is run before this.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerHoverOn

The mouse pointer entered a widget's bounding rectangle.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `mouse_x`, `mouse_y`: (Number) Mouse cursor position, relative to the application window.
* `mouse_dx`, `mouse_dy`: (Number) Relative mouse delta from its last position, if applicable.


#### Returns

True to halt event propagation.


### Notes

Hover events are postponed while any mouse button is held.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerHoverOff

The mouse pointer left a widget's bounding rectangle.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `mouse_x`, `mouse_y`: (Number) Mouse cursor position, relative to the application window.
* `mouse_dx`, `mouse_dy`: (Number) Relative mouse delta from its last position, if applicable.


#### Returns

True to halt event propagation.


### Notes

Hover events are postponed while any mouse button is held.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerHover

The mouse pointer is resting or moving over a widget.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `mouse_x`, `mouse_y`: (Number) Mouse cursor position, relative to the application window.
* `mouse_dx`, `mouse_dy`: (Number) Relative mouse delta from its last position, if applicable.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerPress

The mouse cursor pressed down on a widget.


### Propagation Method

cycleEvent.


### Event Origin

[love.mousepressed](https://love2d.org/wiki/love.mousepressed)


### Signature

`def:uiCall_pointerPress(inst, x, y, button, istouch, presses)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The mouse cursor position.
* `button`: (Number) The index of the the pressed mouse button.
* `istouch`: (Boolean) True if this is a touch event.
* `presses`: (Number) The number of consecutive presses, as determined by `love.mousepressed()`.


#### Returns

True to halt event propagation.


### Notes

This event does not trigger if no widget was clicked (ie the root disables mouse-hover, which in turn prevents clicking on it and all descendants).

If you want to consider only one pressed button at a time, use:

`if button == self.context.mouse_pressed_button then ...`


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerPressRepeat

Called periodically after the the mouse has remained pressed on a widget for some time.


### Propagation Method

cycleEvent.


### Event Origin

[love.update](https://love2d.org/wiki/love.update)


### Signature

`def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The mouse cursor position.
* `button`: (Number) The index of the the pressed mouse button.
* `istouch`: (Boolean) True if this is a touch event.
* `reps`: (Number) The number of consecutive repeat events emitted up to this point, starting at 1.


#### Returns

True to halt event propagation.


### Notes

This is a virtual event, with no equivalent LÖVE callback.

This event will emit even if the pointer leaves the pressed widget's area.

The initial delay and repeat-rate are controlled by the UI Context.

This event will only fire in relation to the button value held in `self.context.mouse_pressed_button`, so the check suggested in `uiCall_pointerPress()` is not necessary here (but including it would cause no harm).


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerRelease

The mouse cursor stopped pressing on a widget, and the cursor was within the widget's bounds.


### Propagation Method

cycleEvent.


### Event Origin

[love.mousereleased](https://love2d.org/wiki/love.mousereleased)


### Signature

`def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The mouse cursor position.
* `button`: (Number) The index of the the pressed mouse button.
* `istouch`: (Boolean) True if this is a touch event.
* `reps`: (Number) The number of consecutive repeat events emitted up to this point, starting at 1.


#### Returns

True to halt event propagation.


### Notes

This event only emits if the mouse cursor is over the widget that is designated as "currently-pressed" by the context.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerUnpress

The mouse stopped pressing on a widget.


### Propagation Method

cycleEvent.


### Event Origin

[love.mousereleased](https://love2d.org/wiki/love.mousereleased)


### Signature

`def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The mouse cursor position.
* `button`: (Number) The index of the the pressed mouse button.
* `istouch`: (Boolean) True if this is a touch event.
* `presses`: (Number) The number of consecutive presses, as determined by `love.mousepressed()`.


#### Returns

True to halt event propagation.


### Notes

This event will emit even if the mouse cursor has left the currently-pressed widget.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerDrag

The mouse cursor is pressing on this widget.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerDrag(inst, x, y, dx, dy)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The mouse cursor position.
* `dx`, `dy`: (Number) The mouse position's delta from the previous frame, if applicable.


#### Returns

True to halt event propagation.


### Notes

Called on every frame.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerWheel

The mouse wheel moved.


### Propagation Method

cycleEvent.


### Event Origin

[love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerWheel(x, y)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The wheel's movement vector.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerDragDestOn

The mouse cursor, while pressing, dragged itself onto this widget.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)

### Signature

`def:uiCall_pointerDragDestOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `mouse_x`, `mouse_y`: (Number) Mouse cursor position, relative to the application window.
* `mouse_dx`, `mouse_dy`: (Number) Relative mouse delta from its last position, if applicable.


#### Returns

True to halt event propagation.


### Notes

Drag-Dest events are intended to help with widget-to-widget drag-and-drop actions.

The instance here is a widget that the mouse is overlapping *while* some other widget is being pressed. Think of the instance as the destination, and the `current_pressed` widget as the source.


#### More Notes

* Source and destination can be the same widget.

* A reference to Source is not provided in the function arguments, but it can be found by reading `self.context.current_pressed`.

* Source could be destroyed before the drag-and-drop action is completed. Or, the circumstances could have changed. Unfortunately, you will have to do some extra work to ensure that the transaction is valid.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerDragDestOff

The mouse cursor, while pressing, moved off of this widget.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerDragDestOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `mouse_x`, `mouse_y`: (Number) Mouse cursor position, relative to the application window.
* `mouse_dx`, `mouse_dy`: (Number) Relative mouse delta from its last position, if applicable.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerDragDestMove

The mouse, while pressing, is currently over this widget.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerDragDestMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `mouse_x`, `mouse_y`: (Number) Mouse cursor position, relative to the application window.
* `mouse_dx`, `mouse_dy`: (Number) Relative mouse delta from its last position, if applicable.


#### Returns

True to halt event propagation.


### Notes

Like `uiCall_pointerHover`, this runs even if there is no mouse movement on a given frame. It should probably be renamed.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_pointerDragDestRelease

The mouse cursor released a button while over this widget.


### Propagation Method

cycleEvent.


### Event Origin

* [love.mousemoved](https://love2d.org/wiki/love.mousemoved)
* [love.mousepressed](https://love2d.org/wiki/love.mousepressed)
* [love.mousereleased](https://love2d.org/wiki/love.mousereleased)
* [love.update](https://love2d.org/wiki/love.update)
* [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)


### Signature

`def:uiCall_pointerDragDestRelease(inst, x, y, button, istouch, presses)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `x`, `y`: (Number) The mouse cursor position.
* `button`: (Number) The index of the the pressed mouse button.
* `istouch`: (Boolean) True if this is a touch event.
* `presses`: (Number) The number of consecutive presses, as determined by `love.mousepressed()`.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimble1Take

A widget took `thimble1`.


### Propagation Method

cycleEvent.


### Event Origin

`widget:takeThimble1()`


### Signature

`def:uiCall_thimble1Take(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimble2Take

A widget took `thimble2`.


### Propagation Method

cycleEvent.


### Event Origin

`widget:takeThimble2()`


### Signature

`def:uiCall_thimble1Take(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimble1Release

A widget released or lost `thimble1`.


### Propagation Method

cycleEvent.


### Event Origin

`widget:releaseThimble1()`


### Signature

`def:uiCall_thimble1Release(inst, a, b, c, d)`


#### Parameters{

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimble2Release

A widget released thimble2.


### Propagation Method

cycleEvent.


### Event Origin

* `widget:takeThimble2()`
* `widget:releaseThimble2()`


### Signature

`def:uiCall_thimble2Release(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimbleTopTake

A widget got the top thimble.


### Propagation Method

cycleEvent.


### Event Origin

* `widget:takeThimble1()`
* `widget:takeThimble2()`
* `widget:releaseThimble2()`


### Signature

`def:uiCall_thimbleTopTake(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimbleTopRelease

A widget lost the top thimble.


### Propagation Method

cycleEvent.


### Event Origin

* `widget:takeThimble2()`
* `widget:releaseThimble1()`
* `widget:releaseThimble2()`


### Signature

`def:uiCall_thimbleTopRelease(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimble1Changed

Emitted to the holder of `thimble2` when `thimble1` changes.


### Propagation Method

cycleEvent.


### Event Origin

* `widget:takeThimble1()`
* `widget:releaseThimble1()`


### Signature

`def:uiCall_thimble1Changed(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimble2Changed

Emitted to the holder of thimble1 when thimble2 changes.


### Propagation Method

cycleEvent.


### Event Origin

* `widget:takeThimble2()`
* `widget:releaseThimble2()`


### Signature

`def:uiCall_thimble2Changed(inst, a, b, c, d)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `a`, `b`, `c`, `d`: (Any) Generic arguments which are supplied through the method that initiated the thimble handover. Usage depends on the implementation.


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimbleAction

The user pressed enter/return or space while this widget had the thimble.


### Propagation Method

cycleEvent.


### Event Origin

WIMP Root.


### Signature

`def:uiCall_thimbleAction(inst, key, scancode, isrepeat)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `key`: (String) The key code.
* `scancode`: (String) The keyboard scancode (maps to the classic US QWERTY keyboard layout).
* `isrepeat`: (Boolean) True if this is a repeat key event.


#### Returns

True to halt event propagation.


### Notes

The enter key fires repeatedly, while space only fires once per press.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_thimbleAction2

The user pressed the Application key or Shift+F10 while a widget had the thimble.


### Propagation Method

cycleEvent.


### Event Origin

WIMP Root


### Signature

`def:uiCall_thimbleAction2(inst, key, scancode, isrepeat)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `key`: (String) The key code.
* `scancode`: (String) The keyboard scancode (maps to the classic US QWERTY keyboard layout).
* `isrepeat`: (Boolean) True if this is a repeat key event.


#### Returns

True to halt event propagation.


### Notes

Does not fire repeatedly.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_keyPressed

The user pressed a key while this widget had the thimble.


### Propagation Method

cycleEvent.


### Event Origin

[love.keypressed](https://love2d.org/wiki/love.keypressed)


### Signature

`def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `key`: (String) The key code.
* `scancode`: (String) The keyboard scancode (maps to the classic US QWERTY keyboard layout).
* `isrepeat`: (Boolean) True if this is a repeat key event.
* `hot_key`: (String) A hotkey string, as determined by the current pressed key combined with the state of modifier keys. This field is false when a valid hotkey string cannot be generated (the pressed key must not be a modifier).
* `hot_scan`: (String) A hotkey string, as determined by the current pressed scancode combined with the state of modifier keys. This field is false when a valid hotkey string cannot be generated (the pressed scancode must not be a modifier).


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_keyReleased

The user released a key while this widget had the thimble.


### Propagation Method

cycleEvent.


### Event Origin

[love.keyreleased](https://love2d.org/wiki/love.keyreleased)


### Signature

`def:uiCall_keyReleased(inst, key, scancode)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `key`: (String) The key code.
* `scancode`: (String) The keyboard scancode (maps to the classic US QWERTY keyboard layout).


#### Returns

True to halt event propagation.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_textInput

The user inputted text.


### Propagation Method

cycleEvent.


### Event Origin

[love.textinput](https://love2d.org/wiki/love.textinput)


### Signature

`def:uiCall_textInput(inst, text)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `text`: (String) The text.


#### Returns

True to halt event propagation.


### Notes

This event is independent of keyboard key-down and key-up events.

LÖVE text input must be enabled for this event to fire.

The context checks the UTF-8 encoding of the text before invoking the event.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_fileDropped

The user dropped a file onto the application window.


### Propagation Method

cycleEvent.


### Event Origin

[love.filedropped](https://love2d.org/wiki/love.filedropped)


### Signature

`def:uiCall_fileDropped(inst, file)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `file`: (love:DroppedFile) The file object.


#### Returns

True to halt event propagation.

### Notes

Refer to the [LÖVE Wiki](https://love2d.org/wiki/love.filedropped) for information on how to work with the `file` argument.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_directoryDropped

The user dropped a directory onto the application window.


### Propagation Method

cycleEvent.


### Event Origin

[love.directorydropped](https://love2d.org/wiki/love.directorydropped)


### Signature

`def:uiCall_directoryDropped(inst, path)`


#### Parameters

* `inst`: (ui:Widget) The target widget instance.
* `path`: (String) The directory path.


#### Returns

True to halt event propagation.


### Notes

Refer to the [LÖVE Wiki](https://love2d.org/wiki/love.directorydropped) for information on how to work with the `path` argument.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_capture

A widget started capturing events from the context.


### Propagation Method

sendEvent.


### Event Origin

`widget:captureFocus()`


### Signature

`def:uiCall_capture(inst)`


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_uncapture

A widget stopped capturing events from the context.


### Propagation Method

sendEvent.


### Event Origin

* `widget:captureFocus()`
* `widget:uncaptureFocus()`


### Signature

`def:uiCall_uncapture(inst)`


#### Returns

Nothing.


<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
## uiCall_captureTick

Runs on the start of every frame when the widget is capturing events from the context.


### Propagation Method

sendEvent.


### Event Origin

[love.update](https://love2d.org/wiki/love.update)


### Signature

`def:uiCall_captureTick(dt)`


#### Parameters

* `dt`: (Number) The delta time from `love.update()`.


#### Returns

False to prevent other widgets from updating on this frame.


<!-- TODO: format later


When a widget has captured the context/focus, the following callbacks, if present, are executed as
prodUI events occur. The capturing widget gets first dibs on the event, and can deny the main event
handler from acting on the event by returning a truthy value.

Some of these don't make much sense — why would a capturing widget need to hijack the window
resize event? — but are included for the sake of completeness.

function def:uiCap_windowResize(w, h) — (love.resize)

function def:uiCap_keyPressed(key, scancode, isrepeat, hot_kc, hot_sc)
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
-->
