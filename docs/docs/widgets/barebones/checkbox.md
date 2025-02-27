# barebones/checkbox

A barebones checkbox.


## User Interaction

* **Mouse**: Press and release with the cursor overlapping the widget to activate.

* **Keyboard**: Press `return` or `kpenter` to activate.


## Callbacks


### wid_buttonAction

Called when the checkbox is activated (whether on or off).

```lua
inst.wid_buttonAction = function(self)
	print("Current checked status: " .. tostring(self.checked))
end
```


#### Arguments

* `self`: The widget.

