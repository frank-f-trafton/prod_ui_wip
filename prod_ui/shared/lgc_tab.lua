local context = select(1, ...)


-- Common functions and data for tabular menus.

--[[
Column fields:
	id: associates the column (which can be reordered) with a specific cell index. For
		example, if the column in the fourth slot is moved to the first slot, it still
		references cells at index #4 internally.

	x, y, w, h: Position and dimensions of the column box. X and Y should just be set to
		0,0 as they will be overwritten automatically.

	visible: (bool) The column is displayed when true, and hidden when false.

	lock_visibility: (bool) When true, user-facing controls to toggle the column's
		visibility should be locked / disabled.

	text: String of text to display to the user.

	cb_sort: A sorting function to use when the user clicks on the column box. When false/nil,
		sorting will not be performed, though the "order" triangle bijou will still be adjusted.
		The function 'lgcTab.columnSortGeneric' can be used here.
--]]


local lgcTab = {}


function lgcTab._sortTempItemsAscending(a, b)
	for i = 2, math.max(#a, #b) do
		if a[i] ~= b[i] then
			return a[i] < b[i]
		end
	end

	return false
end


function lgcTab._sortTempItemsDescending(a, b)
	for i = 2, math.max(#a, #b) do
		if a[i] ~= b[i] then
			return a[i] > b[i]
		end
	end

	return false
end


function lgcTab.columnSortGeneric(wid, column)
	local items = wid.MN_items
	local sort_order = column.sort_order

	local temp = {}
	for i, item in ipairs(wid.MN_items) do
		local entry = {item}
		if not sort_order then
			entry[#entry + 1] = item.cells[column.id][column.sort_cell_field]
		else
			for j, order_id in ipairs(sort_order) do
				local this_col = wid.columns[order_id]
				local this_cell = item.cells[this_col.id]
				entry[#entry + 1] = this_cell[this_col.sort_cell_field]
			end
		end
		temp[i] = entry
	end

	local sort_func = (wid.column_sort_ascending) and lgcTab._sortTempItemsAscending or lgcTab._sortTempItemsDescending
	table.sort(temp, sort_func)

	for i, tbl in ipairs(temp) do
		wid.MN_items[i] = tbl[1]
	end

	return true
end


function lgcTab.getWidestColumnText(self, column_id)
	local font = self.skin.cell_font
	local w = 0
	local index

	for i, row in ipairs(self.MN_items) do
		local cell = row.cells[column_id]
		local new_w = font:getWidth(cell.text)
		if new_w > w then
			index = i
			w = new_w
		end
	end

	return w, index
end


function lgcTab.reverseSequence(seq)
	local last = #seq
	local i, j = 1, last
	while i <= math.floor(last/2) do
		seq[i], seq[j] = seq[j], seq[i]
		i, j = i + 1, j - 1
	end
end


return lgcTab
