# Labels

The Label widget component provides code for configuring and drawing a text label.


## lgc\_label

The main label implementation.


### Location

`prod_ui/shared/lgc_label.lua`


### Label modes

* `single`: A single line of text.

* `single-ul`: A single line of text with an optional underline. The text to be underlined is marked by two underscores, like `_this_`.

* `multi`: Multi-line text.


### Required Widget Fields

* Labels are hard-coded for placement within Viewport #1:
  * `vp_x`, `vp_y`, `vp_w`, `vp_h`


### Required Skin Fields

* `skin.tq_px`: A textured quad of a single white pixel. Used for drawing the underline.

* `skin.label_align_h`: Horizontal text alignment.

* `skin.label_align_v`: Vertical text alignment.

* `skin.label_style`: The label style table, usually taken from the theme table.

  * `.font`: The font to use when measuring and rendering text.

  * `.ul_color`: Underline color table, or false to use the current text color.

  * `.ul_h`: Underline height (thickness).

  * `.ul_oy`: Underline Y offset from the top of text.


### Methods


#### lgcLabel.setup

Sets up the Label component in a widget or changes the existing label state.

```lua
lgcLabel.setup(self, mode)
```

##### Arguments

* `self`: The widget.

* `mode`: The label mode to use.


##### Notes

This function always overwrites the label text with an empty string. If you call it on a widget that already had Label state, then you will have to update the label text.


#### lgcLabel.remove

Removes any Label component from a widget.

```lua
lgcLabel.remove(self)
```

##### Arguments

* `self`: The widget.


#### lgcLabel.widSetLabel

Sets the Label text and mode.

```lua
lgcLabel.widSetLabel(self, text, [mode])
```


##### Arguments

* `self`: The widget.

* `text`: The text to use.

* `[mode]`: *(self.mode)* Optionally change the Label mode.


#### lgcLabel.reshapeLabel

Reshapes the Label, applying alignment offsets and wrapping where applicable. Intended for `uiCall_reshape` callbacks.

```lua
lgcLabel.reshapeLabel(self)
```

##### Arguments

* `self`: The widget.


#### lgcLabel.render

Draws a widget's label text. Intended for `render` callbacks.

```lua
lgcLabel.render(self, skin, font, c_text, c_ul, label_ox, label_oy, ox, oy)
```

##### Arguments

* `self`: The widget.

* `c_text`: The text color (table).

* `c_ul`: The underline color (table, or false/nil to use the text color).

* `label_ox`: Text X offset.

* `label_oy`: Text Y offset.

* `ox`: Scissor X offset.

* `oy`: Scissor Y offset.


### lgc\_label\_bare

A label implementation for barebones widgets.


### Location

`prod_ui/shared/lgc_label.lua`


### Barebones Label Modes

Barebones labels are single-line only and do not have explicit `mode` state.


### Required Widget Fields

* *None.*


### Required Skin Fields

* **N/A**


### Methods


#### lgcLabelBare.setup

Sets up a barebones label component in a widget.

```lua
lgcLabelBare.setup(self)
```


##### Arguments

* `self`: The widget.


#### lgcLabelBare.remove

Removes a barebones label component from a widget.

```lua
lgcLabelBare.remove(self)
```


##### Arguments

* `self`: The widget.


#### lgcLabelBare.widSetLabel

Sets the text of a barebones label.

```lua
lgcLabelBare.widSetLabel(self, text)
```

##### Arguments

* `self`: The widget.

* `text`: The text to assign.


#### lgcLabelBare.render

Draws the barebones label text. Intended for `render` callbacks.

```lua
lgcLabelBare.render(self, font, r, g, b, a)
```

##### Arguments

* `self`: The widget.

* `font`: The font to use.

* `r`, `g`, `b`, `a`: The text color.


