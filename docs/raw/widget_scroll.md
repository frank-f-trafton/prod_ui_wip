# Widget Scroll Registers

`scr_x`, `scr_y`: Public scroll values. Rounded to integer.

`scr_fx`, `scr_fy`: Private scroll value. Double.

`scr_tx`, `scr_ty`: Target scroll values. Double.

The public values are provided just so that other code doesn't constantly have to round them when drawing or performing intersection tests.

In widgets that use the viewport system, The scroll values are offset by Viewport #1's position. The plug-in scroll methods take this into account, but if you read the registers directly, you may find that the scroll values for the top-left position go into the negative. To get the expected value, add viewport 1's position.
