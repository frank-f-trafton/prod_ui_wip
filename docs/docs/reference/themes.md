# Themes

## Skins

Widgets can be customized with the skinning system.

Skinners provide the rendering implementation; skins provide skinners with data.


## Resource Management

Skinners are stored in the context and skins are kept in the theme instance. The library user is responsible for removing unneeded ad hoc skins so that they can be deleted by the garbage collector.


## Marking resources for transformation

Skinners include a schema table which controls which values in a skin are scaled, floored, clamped, and so on.

```lua
schema = {
	foo = "scaled-int", -- scale and floor the value
	bar = "unit-interval" -- clamp the value from 0.0 to 1.0
}
```

Skin values can be references to data in the main resources table. They are pulled in whenever the skin is refreshed.

```lua
	foobar = "*path/to/foo" -- pulls in the value at 'resources.path.to.foo'
```


## Box Styles

Fields:

* `sl_body_id`: The ID of a 9-Slice texture which should be rendered with the box. Used to unify the look of panels and context menus. Not all boxes include this field.

* `outpad {x1, y1, x2, y2}`: The intended amount of outer padding around the box. Sometimes used by the layout system. Does not affect the widget's width and height directly. Similar to "margin" in HTML/CSS.

* `border {x1, y1, x2, y2}`: A border that starts at the widget's edge and grows inward. Usually precludes scroll bars, and may be used to designate a widget's draggable edges. Similar to "border" in HTML/CSS.

* `margin {x1, y1, x2, y2}`: Inner padding which begins at the border and grows inward. Similar to "padding" in HTML/CSS.
