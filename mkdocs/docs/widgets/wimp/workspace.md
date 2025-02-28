# wimp/workspace

A container that serves as one program state for WIMP applications.

This is similar to base/container, but with some additions and removals to better work as a G2 WIMP widget.


```
┌┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┬┈┐
│`````````````````````│^│    [`] == Viewport 2
│`:::::::::::::::::::`├┈┤    [:] == Viewport 1
│`:                 :`│ │
│`:                 :`│ │
│`:                 :`│ │
│`:::::::::::::::::::`├┈┤
│`````````````````````│v│
├┈┬┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┬┈┼┈┤
│<│                 │>│ │    <- Optional scroll bars
└┈┴┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┴┈┴┈┘
```
