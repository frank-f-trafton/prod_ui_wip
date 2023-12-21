# ProdUI Work List

A rough list of development tasks for ProdUI. (Subject to change!)


# Functionality

* Scaling and rescaling
* "outpad" in layout arrangement code (similar to CSS margins)
* [NLay](https://github.com/MikuAuahDark/NPad93) integration?
* Theme changes
* Procedural texture generation
* Rich text integration:
	* Rich Text widget
	* Rich Text labels
* RTL text flow (wait and see what happens with LÖVE 12)
* Animation
* Sound effects handling (?)
* Bilingual label support (?)
* Mac tailoring (expected hotkeys, etc.) (need hardware)
* Touchscreen support; mobile support in general (need hardware)
* Stencil support?


# Documentation

* Tutorials, etc.


# Demo and Test Programs


# Example Programs


## Widget Roots

* wimp (Window, Icon, Menu, Pointer)
* fend (gamepad-centric Front-End)
* touch (mobile / touchscreen)


# Widgets

* `wimp/properties_box` (#1): A two-column list of properties, with labels in one column and controls in the other.
* `base/sash` (#2): A drag-sensor that resizes two adjacent containers.
* `wimp/group` (#3): A labelled container of widgets.
* `wimp/combo_box` (#4): A Dropdown box with built-in text input.
* `wimp/icon_box` (#5): A list or menu of selectable, labelled icons.
* `base/radial` (#6): A dial, or radial slider.
* (#7) Tri-state support for `base/checkbox`.
* `base/button_split` (#8): A button with main and auxiliary sides. Clicking the auxiliary side activates different callbacks (typical use case is to open a menu).
* `base/map2d` (#9): A box with a crosshair that is repositioned by clicking and dragging. (Use case: colour picker.)
* (#10) (WIMP compound object) Colour picker.


# Style

* Source code style
* Reducing file size bloat


# Repositories

* Split repos: ProdUI, documentation, theme builder...
* All dependency licenses should be in one easy-to-find text file.
