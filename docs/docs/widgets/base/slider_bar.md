# base/slider_bar

A horizontal or vertical slider bar.

This widget supports an optional text label, but a customized skin is required for correct placement.


## Methods


### self:setSliderPosition
### self:setSliderMax
### self:setSliderDefault
### self:setSliderHome
### self:setSliderAxis
### self:setSliderAllowChanges


### self:setEnabled

Enables or disables the widget's controls.


```lua
self:setEnabled(enabled)
```


#### Arguments

* `enabled`: `true` to enable interaction with the widget, `false` to disable.


### self:setLabel

Sets the slider bar's text label.


```lua
self:setLabel(text, mode)
```

#### Arguments

* `text`: The text to assign to the label.

* `mode`: The label mode.
