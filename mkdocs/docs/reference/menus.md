# Menus

Menu items are contained in the array `self.items`. Each item is a table, and the menu checks the following variables when making selections:

* `item.selectable` (boolean): This item can be selected by a menu cursor.
  * When moving the cursor, non-selectable items are skipped.
  * If no items are selectable, then the selection index is 0 (no selection).

* `self.default_deselect` (boolean): When true, the default menu item is nothing (index 0).

* `item.is_default_selection` (boolean): The item to select by default, if `self.default_deselect` is false.
  * When multiple items have this set, the first such item that is selectable is chosen.
  * If no item has this set, then the default is the first selectable item (or if there are no selectable items, then the cursor is set to no selection.)

The main selection is tracked in `self.index`. Additional indices can be used by passing in different `id` keys to menu methods. `self.index` gets "camera priority" by higher-level logic.

Arbitrary multiple selection is implemented by setting the field `marked` on a per-item basis. Not all menu widgets support multiple selection.

When creating a menu structure, the library user can provide an existing table of items (for example, a widget's array of child widgets).
