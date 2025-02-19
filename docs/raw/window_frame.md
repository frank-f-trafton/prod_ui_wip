wimp/window_frame: A WIMP-style window frame.

```
........................  <─ Resize sensor
.┌────────────────────┐.
.│      Window  [o][x]│.  <─ Window frame header, drag sensor and control buttons
.├────────────────────┤.
.│'''''''''''''''''''^│.  <- ': Viewport #1
.│'                 '║│.
.│'                 '║│.
.│'                 '║│.
.│'                 '║│.
.│'''''''''''''''''''v│.
.│<═════════════════> │.  <─ Optional scroll bars
.└────────────────────┘.
........................
```

Window Frames support modal relationships: Frame A can be blocked until Frame B is dismissed. Compare with root-modal state, where only the one Window Frame (and pop-ups) can be interacted with.

Frame-modals are harder to manage than root-modals, and should only be used when really necessary (ie the user needs to open a prompt in one frame, while looking up information in another frame).
