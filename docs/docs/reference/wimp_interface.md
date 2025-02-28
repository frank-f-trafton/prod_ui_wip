# WIMP Interface

## WIMP Root

The [WIMP Root](widgets/wimp/root_wimp.md) is the base of the widget tree. It manages state related to the WIMP interface, such as enforcing modal state.


## UI Frames

UI Frames are ProdUI's top-level containers. They are all second generation widgets, meaning that they are direct children of the Root widget.

Up to one UI Frame may be *selected* by the Root at any given time. Keyboard focus is typically routed to the selected UI Frame and its descendant widgets.

There are two kinds of UI Frame: **Workspaces** and **Window Frames**.


### Workspace Frames

A [Workspace](widgets/wimp/workspace.md) fills most (or all) of the application window. There can be up to one active (awake) workspace at a time, and any number of dormant workspaces.


### Window Frames

[Window Frames](widgets/wimp/window_frame.md) are movable rectangles that appear over the Workspace. There can be any number of Window Frames, and they support the following configurations:

* **Modal**: the topmost modal frame blocks interaction with all other frames until dismissed.

* **Frame-blocking**: a window frame can block interaction with one other frame until dismissed.

* **Sorting levels**: "low", "normal", and "high"

* **Workspace association**: When a Workspace is dormant, so too are any of its associated Window Frames. A Window Frame that is *unassociated* will appear even if no Workspace is active.

* **Hidden**: Active Window Frames can be placed out of sight while still running.

