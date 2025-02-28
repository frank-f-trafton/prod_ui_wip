# base/stepper

A stepper button.

Step through options by clicking on the edge buttons, or by pressing the arrow keys on the keyboard.

Steppers are more common in controller-centric game menus. In a WIMP UI, they may be useful in situations where space is limited.


## User Interaction

* **Mouse**: Press the *next* or *prev* buttons to increment or decrement the option index.

* **Keyboard**: Press `left` or `right` to increment or decrement the option index.


## Methods

### self:setEnabled

Enables or disables the widget's controls.

```lua
self:setEnabled(enabled)
```

#### Arguments

* `enabled`: `true` to enable user interaction with the widget, `false` to disable.


### self:insertOption

Inserts an option to the stepper. If the stepper options array is empty, then this option is selected.

```lua
self:insertOption(option, i)
```

#### Arguments

* `option` The option value to use. Can either be a string (which will be used as the label text when selected) or a table (where `tbl.text` is used for the label text).

* `i` *(#self.options + 1)* Where to insert the option in the array. Must be between 1 and `#options + 1`. If not specified, the option will be added to the end of the array.


### self:removeOption

Removes an option from the stepper. If the removed option was the only one in the array, then the index is set to zero.

```lua
self:removeOption(i)
```

#### Arguments

* `i`: *(#self.options)* Index of the option to remove in the array. Must be between 1 and `#options`. If not specified, the last option in the array will be removed.


#### Returns

The removed option value.


## Callbacks


### wid_stepperChanged

Called when the stepper value changes.

```lua
self.wid_stepperChanged = function(self, old_index, new_index)
```

#### Arguments

* `self` The widget.

* `index` The new index.


### wid_buttonAction

Called by pressing `enter` or `kpenter` on the keyboard.

There is no built-in mouse command for the primary action.

```lua
self.wid_buttonAction = function(self)
```

#### Arguments

* `self`: The widget.


### wid_buttonAction2

Called by right-clicking on the widget, or by pressing `application` or `shift+f10` on the keyboard.

```lua
self.wid_buttonAction2 = function(self)
```

#### Arguments

* `self` The widget.


### wid_buttonAction3

* **wid_buttonAction3**: Middle-click on the widget. There is no built-in keyboard command for the tertiary action.

```lua
self.wid_buttonAction2 = function(self)
```

#### Arguments

* `self`: The widget.



## Notes

The concept for this widget is taken from the [LUIGI](http://airstruck.github.io/luigi/doc/widgets/stepper.html) UI library.

