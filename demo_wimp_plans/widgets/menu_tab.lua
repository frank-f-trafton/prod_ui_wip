
local plan = {}


local function rngChr(n)
	local str = ""
	for i = 1, n do
		str = str .. string.char(love.math.random(33, 127))
	end

	return str
end


local function hof_sort1(a, b)
	return a.label1 < b.label1
end
local function hof_sort2(a, b)
	return (a.label2 == b.label2) and a.label1 < b.label1
		or a.label2 < b.label2
end
local function hof_sort3(a, b)
	return (a.label3 == b.label3) and a.label2 < b.label2
		or (a.label2 == b.label2) and a.label1 < b.label1
		or a.label3 < b.label3
end
local function hof_sort4(a, b)
	return (a.label4 == b.label4) and a.label3 < b.label3
		or (a.label3 == b.label3) and a.label2 < b.label2
		or (a.label2 == b.label2) and a.label1 < b.label1
		or a.label4 < b.label4
end
local sort_functions = {
	hof_sort1,
	hof_sort2,
	hof_sort3,
	hof_sort4
}


local function columnSortLabels(wid, column)
	local items = wid.MN_items
	print("column.id", column.id)
	table.sort(items, sort_functions[column.id])

	if not wid.column_sort_ascending then
		local wcTab = wid.context:getLua("shared/wc/wc_tab")
		wcTab.reverseSequence(items)
	end

	return true
end


function plan.make(panel)
	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local context = panel.context

	local menu_tab = panel:addChild("wimp/menu_tab")
		:geometrySetMode("static", 0, 0, 640, 480)

	--menu_tab:setReorderLimit(1)

	menu_tab.MN_drag_select = true
	menu_tab.MN_wrap_selection = false

	menu_tab:setScrollBars(true, true)

	menu_tab:newColumn(1)
		:setHeaderText("Column 1")
		--:setHeaderTextAlignment("right") -- test...
		:setLockedVisibility(true)
		:setSortFunction(columnSortLabels)

	menu_tab:newColumn(2)
		:setHeaderText("Column 2")
		:setSortFunction(columnSortLabels)

	menu_tab:newColumn(3)
		:setHeaderText("Column 3")
		--:setContentTextAlignment("center") -- test
		:setSortFunction(columnSortLabels)

	menu_tab:newColumn(4)
		:setHeaderText("Column 4")
		:setSortFunction(columnSortLabels)

	menu_tab.column_sort_ascending = true

	-- TODO: Word filter? Or just use a known-good random seed.
	for i = 1, 100 do
		local item = menu_tab:newRow()

		item.label1 = tostring(i)
		item.label2 = rngChr(3)
		item.label3 = rngChr(5)
		item.label4 = rngChr(8)

		local c1 = item:provisionCell(1)
		c1:setText(item.label1)

		local c2 = item:provisionCell(2)
		c2:setText(item.label2)

		local c3 = item:provisionCell(3)
		c3:setText(item.label3)

		local c4 = item:provisionCell(4)
		c4:setText(item.label4)
	end
end


return plan
