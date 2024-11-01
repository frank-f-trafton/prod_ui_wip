# ProdUI Road Map

# Stage 1

* Get the WIMP shell and core widgets up and running.
* Do not worry about layout, scaling and (re)-skinning at this point.

## Widgets

I am using a charitable definition of 'Working' here.

### Barebones

Basic, unskinned widgets that are intended for developer-facing tools and debugging.

| Widget | Status |
| - | - |
| barebones/button | Working |
| barebones/button_instant | Working |
| barebones/button_repeat | Working |
| barebones/button_sticky | Working |
| barebones/checkbox | Working |
| barebones/input_box | Working |
| barebones/label | Working |
| barebones/radio_button | Working |
| barebones/slider_bar | Working |


### Base

This category was planned to be used across all interfaces (WIMP, gamepad, touchscreen), but most of these widgets may be moved to the WIMP category in the future.

| Widget | Status |
| - | - |
| base/button | Working |
| base/button_double_click | Working |
| base/button_instant | Working |
| base/button_repeat | Working |
| base/button_sticky | Working |
| base/checkbox | Working |
| base/checkbox_multi | Working |
| base/container | Working |
| base/container_simple | Working |
| base/generic | Working (*1)|
| base/label | Working |
| base/log | **Unstarted** |
| base/map2d | **Unstarted** |
| base/menu | **Broken** |
| base/menu_simple | **Untested, likely broken** |
| base/radial | **Unstarted** |
| base/radio_button | Working |
| base/slider_bar | Working |
| base/stepper | Working |
| base/text | **Unskinned, probably outdated** |

(*1): Does nothing on its own.

(*2): Three-state checkbox.


### Input

Text input widgets.

| Widget | Status |
| - | - |
| input/text_box_multi | **Outdated and buggy** |
| input/text_box_single | Working |


### Status

Status display widgets.

| Widget | Status |
| - | - |
| status/progress_bar | Working |


### Test

Test widgets. These serve no practical purpose for the end user, and are not tracked here.


### WIMP

WIMP widgets.

| Widget | Status |
| - | - |
| wimp/button_split | Working |
| wimp/combo_box | Working |
| wimp/dropdown_box | Working |
| wimp/dropdown_pop | Working |
| wimp/frame_header | Working |
| wimp/group | **Barely started** |
| wimp/icon_box | **Barely started** |
| wimp/list_box | Working |
| wimp/menu_bar | Working |
| wimp/menu_pop | Working |
| wimp/menu_tab | **Buggy** |
| wimp/number_box | Working |
| wimp/properties_box | **Barely started** |
| wimp/root_wimp | Working |
| wimp/sash | **Partial** |
| wimp/tree_box | Working |
| wimp/window_frame | Working |


## Compound Objects

| Object | Status |
| - | - |
| Colour picker window | **Not Started** |
| File Selector | **Not Started** |


# Stage 2

**TBD**


# Future Concerns

* Scaling and rescaling
* "outpad" in layout arrangement code (similar to CSS margins)
* [NLay](https://github.com/MikuAuahDark/NPad93) integration?
* Theme changes
* Procedural texture generation
* Rich text integration:
	* Rich Text widget
	* Rich Text labels
* RTL text flow
* Animation
* Sound effects handling (?)
* Bilingual label support (?)
* Mac tailoring (expected hotkeys, etc.)
* Touchscreen support; mobile support in general
* Stencil support?
* Toast / notification system (see the ad hoc toast overlay in `demo_wimp.lua`)
* Documentation
  * Tutorials
* Demo, example and test programs
* Source code style
* Reducing file size bloat
* Split repositories: ProdUI, documentation, theme builder...
