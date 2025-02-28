# Mouse Cursor State

The mouse cursor is set by assigning cursor IDs to these fields:

* `context.cursor_high`: (Priority: 1) Overrides all other cursor fields.

* `widget.cursor_press`: (Priority: 2) Used when the pointer is pressing on a widget. (Travels up the hierarchy until a cursor ID is found.)

* `widget.cursor_hover`: (Priority: 3) Used when the pointer hovers over a widget. (Travels up the hierarchy until a cursor ID is found.)

* `context.cursor_low`: (Priority: 4) Used when no other cursor fields are active.

The populated field with the lowest priority is selected.


## Cursor IDs

The default cursor IDs are pulled from LÖVE's [built-in hardware cursors](https://love2d.org/wiki/CursorType). ProdUI includes an invisible cursor with the ID `nothing`; this is easier to use within widget code, versus trying to control the application-wide mouse visibility state.

* `arrow`
* `crosshair`
* `ibeam`
* `hand`
* `no`
* `nothing`
* `sizeall`
* `sizenesw`
* `sizens`
* `sizenwse`
* `sizewe`
* `wait`
* `waitarrow`
