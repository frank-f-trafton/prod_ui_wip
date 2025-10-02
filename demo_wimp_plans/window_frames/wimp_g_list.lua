-- A chart of Lua global variables, as seen in the Love Frames demo.


local plan = {}


local function hof_columnSortGlobalsKeyValue(a, b)
	return (a.g_key == b.g_key) and a.g_val < b.g_val or a.g_key < b.g_key
end


local function hof_columnSortGlobalsValueKey(a, b)
	return (a.g_val == b.g_val) and a.g_key < b.g_key or a.g_val < b.g_val
end


local sort_functions = {
	key = hof_columnSortGlobalsKeyValue,
	value = hof_columnSortGlobalsValueKey
}


local function columnSortGlobals(wid, column)
	local items = wid.MN_items

	table.sort(items, sort_functions[column.id])

	if not wid.column_sort_ascending then
		local lgcTab = wid.context:getLua("shared/lgc_tab")
		lgcTab.reverseSequence(items)
	end

	return true
end


function plan.makeWindowFrame(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:setFrameTitle("Snapshot of '_G'")

	frame:layoutSetBase("viewport")
	frame:setScrollRangeMode("zero")
	frame:setScrollBars(false, false)

	local menu_tab = frame:addChild("wimp/menu_tab")
		:geometrySetMode("remaining")

	menu_tab.MN_drag_select = true
	menu_tab.MN_wrap_selection = false

	menu_tab:setScrollBars(true, true)

	menu_tab:newColumn("key")
		:setText("Key")
		:setLockedVisibility(true)
		:setSortFunction(columnSortGlobals)

	menu_tab:newColumn("value")
		:setText("Value")
		:setSortFunction(columnSortGlobals)

	menu_tab.column_sort_ascending = true

	for k, v in pairs(_G) do
		local item = menu_tab:newRow()

		item.g_key = tostring(k)
		item.g_val = tostring(v)

		local c_key = item:provisionCell("key")
		c_key:setText(tostring(k))

		local c_value = item:provisionCell("value")
		c_value:setText(tostring(v))
	end

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
