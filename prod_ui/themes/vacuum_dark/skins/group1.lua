--[[
QuadSlice layout:
Slice B       Slice C
  3x1           3x1
┌─┬─┬─┐       ┌─┬─┬─┐
│1│2│3│ Label │1│2│3│
└─┴─┴─┘       └─┴─┴─┘
┌─┐               ┌─┐
│4│       5       │6│
│ │    (hollow)   │ │
├─┼───────────────┼─┤
│7│      8        │9│
└─┴───────────────┴─┘
       Slice A
         3x2
(TODO: move this diagram somewhere more appropriate.)
--]]
return {
	skinner_id = "wimp/group",

	box = "*boxes/wimp_group",
	font = "*fonts/p",

	show_perimeter = true,

	slc_perimeter_a = "*slices/atlas/group_perimeter_a",
	slc_perimeter_b = "*slices/atlas/group_perimeter_b",
	slc_perimeter_c = "*slices/atlas/group_perimeter_c",

	color_text = {1, 1, 1, 1},
	color_perimeter = {1, 1, 1, 1},
}
