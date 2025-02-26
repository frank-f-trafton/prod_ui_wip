# Widgets

ProdUI uses a basic form of inheritance to provide methods to widgets. When an instance calls a method, it checks:

* Itself
* Its widget definition
* _mt_widget, the base table for all widgets

This is implemented with Lua's built-in `__index` metamethod. Further subclassing is not supported.

All widgets are axis aligned rectangles, even if they are invisible and appear formless in UI space.


## Event Dispatch

ProdUI supports four forms of event dispatch:
  * `self:sendEvent()`: Just query `self`.
  * `self:bubbleEvent()`: Ascend from the target widget to the root.
  * `self:trickleEvent()`: Descend from the root to the target widget.
  * `self:cycleEvent()`: Trickle down, then bubble up.

The main event callbacks are attached to its indexed metatable, like this:

```lua
function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
```

These are used in `direct`, `bubble`, and the direct and bubble phases of `cycle`.

Trickle callbacks are used less frequently, and are stored in a subtable in order to keep the two separated:

```lua
function def.trickle:uiCall_keyPressed(inst, key, scancode, isrepeat)
```

Note that the colon syntax is misleading here: we always call the function on the widget table directly, never on `wid.trickle`. Colon syntax is used only to maintain argument parity with the main callbacks in the source code (so that we don't have to add or remove 'self' when moving code snippets back and forth).

Typically, the first argument after `self` is the original calling instance. Widgets that do not have the relevant field are ignored.

Propagation is halted as soon as a widget returns a value that evaluates to true.

You can use `if self == inst then...` to differentiate between events acting on `self`, or events bubbled up from a descendant. Trickle event callbacks never run directly on targets.


## The UI Thimble

"Thimble" is an arbitrary term for which widget currently has focus. The name is unlikely to be mistaken for other kinds of focus: OS window focus, in-application frame focus, mouse hover + press state, selections within menus, and so on. Generally, the widget which has the thimble is also the target for keyboard input.

Lamentably, there are two thimbles: `thimble1` and `thimble2`. The first is for "concrete" widgets, while the second is for "ephemeral" components like pop-up menus. The *Top Thimble* is the highest one that is currently assigned to a widget:

```
+--------------------------------------------+
| thimble1 | thimble2 | Top Thimble is...    |
+----------+----------+----------------------+
|          |          | Neither              |
|    x     |          | thimble1             |
|          |    x     | thimble2             |
|    x     |    x     | thimble2             |
+--------------------------------------------+
```

This system, confusing as it is, allows a concrete widget to know that it is still selected, even if key events are temporarily directed to an ephemeral widget.


## A Note on "Capturing"

A widget can "capture" the UI context. When this happens, all prodUI events are passed to the widget first, and it has the option to deny the event from being handled further by the context. This can be used to implement custom behaviors without interference from the context or other widgets.

While this enables some nice widget behaviors, be warned that capturing is prone to subtle input bugs. By default, if a capturing widget does not have a capture callback for an event type, then it is always passed on to the main event handler. You may need to capture events that have nothing to do with the desired behavior, and handle them appropriately or discard them. Consolidating similar capture behavior into shared functions is recommended.


## Reserved Field prefixes

These fields are reserved by ProdUI in widget tables.

`lo_*`: Layout system

`ly_*`: Canvas layering

`sk_*`: Skinner and skin data

`usr_*`: Arbitrary user (application developer) variables

`vp_*`: Viewport data (See: Widget Viewports)


### Fields with base widget metatable dummy values

`tag` (empty string) A string you can use to help locate widgets.

`scr_x, scr_y`: Scroll registers, applicable to a widget's children.

`awake`: When false, the widget and its descendants are skipped when updating.

`can_have_thimble`: When true, widget can obtain the thimble (the UI cursor). As a prerequisite, `awake` must also be true.

`allow_hover`: When true, widget is eligible for the 'current_hover' context state. When false, it and all of its descendants are skipped.


### Fields with per-instance metatable dummy values

`id`: The identifier value for the widget, as set when the widget def was loaded. Typically a string. Do not modify.


### Fields with defaults in the widget metatable

`x, y`: (0, 0) Position of the widget relative to its parent's upper-left corner.

`w, h`: (0, 0) Size of the widget body, in pixels. Must be at least zero.


### Fields set during instance creation (before uiCall_initialize())

`context`: a link to the UI Context that this widget belongs to. Do not modify.

`parent`: a link to the widget's parent, or false if there is no parent. Do not modify.

`children`: table of child widgets and further descendants. This table may be a dummy reference if '_no_descendants' was set in the def. Do not modify directly.


### Fields set during instance destruction

`_dead`: Identifies widgets that are being removed or have already been removed. Can be read, but do not modify.
  * nil: the widget is still part of the context.
  * "dying": the widget is in the process of being removed from the context.
  * "dead": The widget has been removed from the context.


### Fields applicable to widgets with children

`hide_children`: When truthy, children are not rendered.

`clip_scissor`: When true, rendering of children is clipped to the widget's body. When "manual", the scissor region is specified in 'clip_scissor_x', 'clip_scissor_y', 'clip_scissor_w', and 'clip_scissor_h', relative to the top-left of the widget.

NOTE: don't use math.huge with setScissor or intersectScissor. It will become zero. -2^16 and 2^17 seem OK.

`clip_hover`: When true, mouse hover and click detection against children is clipped to the widget's body. When "manual", the clipping region is specified in 'clip_hover_x', 'clip_hover_y', 'clip_hover_w' and 'clip_hover_h'.

`_no_descendants`: When true, upon widget creation, a special shared table is assigned to self.children. This table raises an error if self:addChild() is used, or if anything assigns a new field via __newindex.

Use with care: it cannot catch every instance of messing with the table. For example, rawset() and table.insert() do not invoke __newindex.


### Skin fields

`skin_id`: Used when assigning the widget's skin. Skins allow the appearance of widgets to be customized. Not all widgets support skins, and most skins are designed for one or a few specific widgets or skinners (implementations).

Once set, skin_id should not be modified except as part of a skinner/skin replacement action.

`skinner`, `skin`: The skinning implementation and data package, respectively. They are assigned to skinned widgets by self:skinSetRefs(). Avoid modifying these tables from the widget instance code, as the changes will affect all other widgets with the same skinner / skin.


### Widget Viewports

Viewports are rectangles that widgets can use for placement of their internals, and as the basis for built-in mouse sensors.

`Viewport #1: self.vp_x, self.vp_y, self.vp_w, self.vp_h`

`Viewport #2: self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h`

Up to eight viewports per widget are permitted by the support code that manages them.
