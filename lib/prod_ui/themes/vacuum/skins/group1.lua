-- WIMP group container.

--[[
Slice B       Slice C
  3x1           3x1
+-+-+-+       +-+-+-+
|1|2|3| Label |1|2|3|
+-+-+-+       +-+-+-+
+-+               +-+
|4|       5       |6|
| |    (hollow)   | |
+-+---------------+-+
|7|      8        |9|
+-+---------------+-+
       Slice A
         3x2
--]]

return {

	skinner_id = "default",

	["*box"] = "style/boxes/wimp_group",
	["*font"] = "fonts/p",

	show_perimeter = true,

	["*slc_perimeter_a"] = "tex_slices/group_perimeter_a",
	["*slc_perimeter_b"] = "tex_slices/group_perimeter_b",
	["*slc_perimeter_c"] = "tex_slices/group_perimeter_c",

	color_text = {1, 1, 1, 1},
	color_perimeter = {1, 1, 1, 1},
}
