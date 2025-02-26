# Widget Callbacks

## render

Draws the widget (before its children).

### Call site

`context:draw()`

### Signature

`def:render(os_x, os_y)`

#### Parameters

* `os_x`, `os_y`: (Number) X and Y offsets, in screen pixels.

#### Returns

Nothing.

### Notes

The graphics state is already translated so that 0,0 is the top-left corner of the widget. The parameters `os_x` and `os_y` typically aren't needed, unless the widget needs to adjust the current scissor box.


## renderLast

Draws the widget (after its children).

### Call site

`context:draw()`

### Signature

`def:renderLast(os_x, os_y)`

#### Parameters

* `os_x`, `os_y`: (Number) X and Y offsets, in screen pixels.

#### Returns

Nothing.

### Notes

See `render` for applicable notes.


## renderThimble

Draws the visual representation of keyboard focus for a widget.

### Call site

`context:draw()`

### Signature

`def:renderThimble(os_x, os_y)`

#### Parameters

* `os_x`, `os_y`: (Number) X and Y offsets, in screen pixels.

#### Returns

Nothing.


## ui_evaluateHover

Determines if the mouse cursor is hovering over this widget.

### Call site

`mouseLogic.checkHover`

### Signature

`def:ui_evaluateHover(mx, my, os_x, os_y)`

#### Parameters

* `mx`, `my`: (Number) The mouse cursor position in UI space.

* `os_x`, `os_y`: (Number) Position offsets, such that `mx + os_x` and `my + os_y` give the widget's top-left position in UI space.

#### Returns

True to indicate that this widget can be considered hovered, false if not. When returning true, this widget will be chosen only if none of its children also return true.


## ui_evaluatePress

Determines if the mouse is pressing this widget.

### Call site

`mouseLogic.checkPressed`


### Signature

`def:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)`


#### Parameters

* `mx`, `my`: (Number) The mouse cursor position in UI space.

* `os_x`, `os_y`: (Number) Position offsets, such that `mx + os_x` and `my + os_y` give the widget's top-left position in UI space.

* `button`: (Number) The pressed mouse button index.

* `istouch`: (Boolean) True if this is a touch event.

* `presses`: (Number) The number of consecutive presses, as determined by love.mousepressed().

#### Returns

True to indicate that this widget can be considered pressed, false if not. When returning true, this widget will be chosen only if none of its children also return true.
