# base/button_repeat

A skinned repeat-action button.


## User Interaction

* **Mouse**: Press to activate immediately. Hold to continuously activate.

* **Keyboard**: Press `return` or `kpenter` to activate.


## Methods


### self:setEnabled

Enables or disables the widget's controls.


```lua
self:setEnabled(enabled)
```


#### Arguments

* `enabled`: `true` to enable interaction with the widget, `false` to disable.


### self:setLabel

Sets the button's text label.


```lua
self:setLabel(text, mode)
```

#### Arguments

* `text`: The text to assign to the label.

* `mode`: The label mode.


## Callbacks


### self.wid_buttonAction

Called when the button is activated.

```lua
inst.wid_buttonAction = function(self)
	print("I've been clicked!")
end
```

