# Reshaping

## Widget Reshape Events

* `uiCall_reshapePre`: The first event. The widget can halt further reshaping by returning true.

* `uiCall_relayoutPre`: Emitted before a child widget's layout is applied.

* `uiCall_relayoutPost`: Emitted after a child widget's layout is applied.

* `uiCall_reshapePost`: The last event, emitted after all of a widget's descendants have been handled.


## Widget Reshaper Methods

These are various implementations of the `Widget:reshape()` method. The default method is **reshapers.null**.

* `reshapers.null`: Does nothing, besides clamp dimensions.

* `reshapers.pre`: Emits `uiCall_reshapePre` only.

* `reshapers.post`: Emits `uiCall_reshapePost` only.

* `reshapers.prePost`: Emits `uiCall_reshapePre` and `uiCall_reshapePost`.

* `reshapers.branch`: Emits `uiCall_reshapePre` and `uiCall_reshapePost`, and calls the reshape method on all of its children.

* `reshapers.layout`: Emits `uiCall_reshapePre` and `uiCall_reshapePost` on itself. For each child in the layout table, emits `uiCall_relayoutPre` and `uiCall_relayoutPost`, and also calls the reshape method.


| Name | reshapePre | reshapePost | relayoutPre | relayoutPost | Recursive |
| --- | :---: | :---: | :---: | :---: | :---: |
| null | N | N | N | N | N |
| pre | **Y** | N | N | N | N |
| post | N | **Y** | N | N | N |
| prePost | **Y** | **Y** | N | N | N |
| branch | **Y** | **Y** | N | N | **Children** |
| layout | **Y** | **Y** | **Y** | **Y** | **Layout Sequence** |


## Remarks

From the perspective of a child widget that is part of a layout system, `uiCall_relayoutPre`, `uiCall_relayoutPost` and the layout function are fired *before* `reshapePre` and `reshapePost`.

`uiCall_relayoutPre` and `uiCall_relayoutPost` cannot be directly emitted by a widget, because they depend on temporary information that only exists while a parent is in the act of applying its layout.

For `reshapers.layout`, only children in the layout are reshaped. It is *very important* that all relevant children are registered to the layout.

