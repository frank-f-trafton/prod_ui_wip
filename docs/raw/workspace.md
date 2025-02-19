wimp/workspace: A container that serves as one unit of "state" for WIMP applications.

This is similar to base/container, but with some additions and removals to better work as 2nd-gen WIMP widgets.


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
