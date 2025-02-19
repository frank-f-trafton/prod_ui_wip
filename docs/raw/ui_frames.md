# UI Frames

UI Frames are the main unit of state in ProdUI. All UI Frames are direct children of the root widget.

There are two kinds of UI Frame:

* Workspace Frame: Fills most (or all) of the application window. There can be up to one active workspace at a time, and any number of inactive workspaces.

* Window Frame: A floating box that renders on top of the Workspace. There can be any number of window frames, and they support the following configurations:
  * Modal: they block interaction with other parts of the application until dismissed.
  * Three sorting levels: "low", "normal", and "high"
  * Workspace association: When tied to a Workspace, Window Frames are only active and visible when the Workspace is also active. Unassociated Window Frames are always active.

Up to one UI Frame may be "selected" by the Root at any given time.
