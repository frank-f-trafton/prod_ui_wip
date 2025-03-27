-- As seen in the Love Frames demo.

-- ProdUI
local commonTab = require("prod_ui.common.common_tab")


local plan = {}


local function hof_columnSortGlobalsKeyValue(a, b)
	return (a.g_key == b.g_key) and a.g_val < b.g_val or a.g_key < b.g_key
end


local function hof_columnSortGlobalsValueKey(a, b)
	return (a.g_val == b.g_val) and a.g_key < b.g_key or a.g_val < b.g_val
end


local sort_functions = {
	hof_columnSortGlobalsKeyValue,
	hof_columnSortGlobalsValueKey,
}


local function columnSortGlobals(wid, column)
	local items = wid.items

	table.sort(items, sort_functions[column.id])

	if not wid.column_sort_ascending then
		commonTab.reverseSequence(items)
	end

	return true
end


function plan.makeWindowFrame(root)
	local context = root.context

	local implTabCell = context:getLua("shared/impl_tab_cell")

	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("Snapshot of '_G'")
	frame:setScrollBars(false, false)

	local menu_tab = frame:addChild("wimp/menu_tab")
	menu_tab:initialize()

	frame:setLayoutNode(menu_tab, frame.layout_tree)

	commonTab.setDefaultMeasurements(menu_tab)

	menu_tab.renderThimble = function() end

	menu_tab.MN_drag_select = true
	menu_tab.MN_wrap_selection = false

	menu_tab:setScrollBars(true, true)

	local col_key = menu_tab:addColumn("Key", true, columnSortGlobals) -- ID #1
	col_key.lock_visibility = true

	menu_tab:addColumn("Value", true, columnSortGlobals) -- ID #2

	menu_tab.column_sort_ascending = true

	for k, v in pairs(_G) do
		local item = menu_tab:addRow()

		item.g_key = tostring(k)
		item.g_val = tostring(v)

		item.cells[1] = {text = tostring(k)}
		item.cells[2] = {text = tostring(v)}

		item.render = implTabCell.default_renderCell
	end

	local font = menu_tab.skin.cell_font
	menu_tab.default_item_h = math.floor(font:getHeight() * 1.25)
	menu_tab.default_item_text_x = math.floor(font:getWidth("M") / 16)
	menu_tab.default_item_text_y = math.floor((menu_tab.default_item_h - font:getHeight()) / 2)

	menu_tab:refreshRows()

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
