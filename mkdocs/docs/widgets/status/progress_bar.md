# status/progress_bar

A progress bar.


## User Interaction

* *None.*


## Methods

### self:setActive

Sets the progress bar's active state.

`self:setActive(active)`

* `active`: `true` to set the progress bar to active state, `false` / `nil` / nothing to set it to inactive.

#### Notes

Active state only affects the visual appearance of the progress bar. It does not change its internal behavior, nor does it prevent the bar from being updated.


### self:setCounter

Sets the progress bar's current position and maximum value.

`self:setCounter(pos, max)`

* `pos`: The new position. Clamped between `0` and the new `max` value.

* `max`: *(self.max)* An optional new maximum value. Clamped on the low end to `0`.


#### Events

* Calls `wid_barChanged` if the position or maximum value changed.


### self:setLabel


See `wid:setLabel()`.



## Callbacks


### wid\_barChanged

Called when the progress bar's position or maximum value changed.

`function def:wid_barChanged(old_pos, old_max, new_pos, new_max)`

* `old_pos`: The old position.

* `old_max`: The old maximum value.

* `new_pos`: The new position.

* `new_max`: The new maximum value.


#### Notes

Do not call `self:setCounter()` from within this callback. It can overflow the stack.

