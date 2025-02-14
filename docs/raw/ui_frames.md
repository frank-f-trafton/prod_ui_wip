# UI Frames

UI Frames are the main unit of state in ProdUI. All UI Frames are direct children of the root widget.

There are two kinds of UI Frame:

* Workspace Frame: Fills most (or all) of the application window's space. There can be 0-1 active workspaces, and any number of inactive workspaces.

* Window Frame: A floating box that renders on top of the Workspace. There can be any number of window frames, and they can be configured to be modal (meaning they can block interaction with other frames, or all other 2nd-gen widgets, until they are dismissed).

One UI Frame may have root focus at any given time.
