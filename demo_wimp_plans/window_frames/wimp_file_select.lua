
local plan = {}


local byte_size_classes = {
	{under = 1,      tag = " bytes", div = 1,      fmt = "%d",   },
	{under = 2,      tag = " byte",  div = 1,      fmt = "%d",   },
	{under = 1024,   tag = " bytes", div = 1,      fmt = "%d",   },
	{under = 1024^2, tag = " KiB",   div = 1024,   fmt = "%.2f", },
	{under = 1024^3, tag = " MiB",   div = 1024^2, fmt = "%.2f", },
	{under = 1024^4, tag = " GiB",   div = 1024^3, fmt = "%.2f", },
	{under = 1024^5, tag = " TiB",   div = 1024^4, fmt = "%.2f", },
	{under = 1024^6, tag = " PiB",   div = 1024^5, fmt = "%.2f", },
	{under = 1024^7, tag = " EiB",   div = 1024^6, fmt = "%.2f", },
	{under = 1024^8, tag = " ZiB",   div = 1024^7, fmt = "%.2f", },
	{under = 1024^9, tag = " YiB",   div = 1024^8, fmt = "%.2f", },
}


local function hof_sortName(a, b)
	return a.fs_name < b.fs_name
end


local function hof_sortSize(a, b)
	return a.fs_size == b.fs_size and a.fs_name < b.fs_name or a.fs_size < b.fs_size
end


local function hof_sortMod(a, b)
	return a.fs_mod == b.fs_mod and a.fs_name < b.fs_name or a.fs_mod < b.fs_mod
end


-- Reserved
--[[
local function hof_sortFileType(a, b)
	return a.file_type == b.file_type and a.fs_name < b.fs_name or a.file_type < b.file_type
end
--]]


local sort_functions = {
	hof_sortName,
	hof_sortSize,
	hof_sortMod,
	--hof_sortFileType, -- Reserved
}


local function columnSortFiles(wid, column)
	local items = wid.MN_items

	-- Sort directories + symlinks first, then all other files.
	local ord1, ord2 = {}, {}
	for i, item in ipairs(items) do
		if item.fs_type == "directory" or item.fs_type == "symlink" then
			table.insert(ord1, item)

		else
			table.insert(ord2, item)
		end
	end

	local lgcTab = wid.context:getLua("shared/lgc_tab")

	table.sort(ord1, hof_sortName)
	if not wid.column_sort_ascending then
		lgcTab.reverseSequence(ord1)
	end

	table.sort(ord2, sort_functions[column.id])
	if not wid.column_sort_ascending then
		lgcTab.reverseSequence(ord2)
	end

	for i, item in ipairs(ord1) do
		items[i] = ord1[i]
	end
	for i, item in ipairs(ord2) do
		items[#ord1 + i] = ord2[i]
	end

	return true
end


local function fileSelectorKeyNav(self, key, scancode, isrepeat)
	if scancode == "return" then
		-- Enter directory or symlink
		local selected_item = self.MN_items[self.MN_index]
		if selected_item then
			local fs_name = selected_item.fs_name
			local fs_type = selected_item.fs_type

			if fs_type == "directory" or fs_type == "symlink" then
				local path
				if #self.usr_path > 0 then
					path = self.usr_path .. "/" .. fs_name
				else
					path = fs_name
				end

				--love.system.openURL(path)
				self:trySetPath(path)
				self:reshape()
				self:selectionInView(true)

			elseif fs_type == "file" then
			-- Test opening a text file
			-- [[
				print("path", self.usr_path .. "/" .. fs_name)
				print(string.sub(fs_name, #fs_name - 3))
				if string.sub(fs_name, #fs_name - 3) == ".txt" then
					love.system.openURL(self.usr_path .. "/" .. fs_name)
				end
			--]]
			end
		end

	elseif scancode == "backspace" then
		-- Go up one directory
		local up = string.match(self.usr_path, "^(.+)/.*$") or ""
		print("up", up)
		if up then
			self:trySetPath(up)
			self:reshape()
			self:selectionInView(true)
		end
	end
end


local function setupMenuItem(self, source)
	local item = self:addRow()

	-- Maintain a separation between internal values and what is displayed to the end user.

	-- Internal:
	local fs_name = source.name
	local fs_type = source.type
	local fs_mod = source.modtime
	local fs_size = source.size

	-- External labels:
	local text_name = source.name

	-- Reserved
	--local text_type = "<missing feature>"

	local text_mod = os.date("%Y/%m/%d", source.modtime)

	local size_tag, size_div, size_fmt

	for i, size_class in ipairs(byte_size_classes) do
		if source.size < size_class.under or i == #byte_size_classes then
			size_tag = size_class.tag
			size_div = size_class.div
			size_fmt = size_class.fmt
			break
		end
	end

	-- Don't show sizes for directories and symlinks (it's always zero)
	local text_size = ""
	if source.type == "file" then
		text_size = string.format(size_fmt, source.size / size_div) .. size_tag
	end

	-- Now configure the item.

	item.fs_name = fs_name
	item.fs_type = fs_type
	item.fs_size = fs_size
	item.fs_mod = fs_mod

	-- Reserved
	--item.file_type = "<missing feature>"

	item.cells[1] = {text = text_name}
	item.cells[2] = {text = text_size}
	item.cells[3] = {text = text_mod}
	--item.cells[<?>] = {text = text_type} -- Reserved

	if source.type == "file" then
		item.cells[1].icon_id = "file"

	elseif source.type == "directory" or source.type == "symlink" then
		item.cells[1].icon_id = "folder"
	end

	local implTabCell = self.context:getLua("shared/impl_tab_cell")
	for j, cell in ipairs(item.cells) do
		cell.render = implTabCell.render
		cell.reshape = implTabCell.reshape

		cell:reshape(self)
	end

	return item
end


local function menu_trySetPath(self, path)
	-- Assertions
	-- [[
	-- XXX TODO
	--]]

	local info = love.filesystem.getInfo(path)
	if not info
	or (info.type == "symlink" and not love.filesystem.areSymlinksEnabled())
	or (info.type ~= "directory" and info.type ~= "symlink")
	then
		return false
	end

	self.usr_path = path
	self:getDirectoryItems()

	self:reshape()

	print("path: |" .. path .. "|")
	print("self.usr_path: |" .. self.usr_path .. "|")
end


local function enforceDefaultPrimaryColumn(self)
	if not self.column_primary then
		self.column_primary = self.columns[1] or false
		self.column_sort_ascending = true
	end
end


local function menu_getDirectoryItems(self, filter_type)
	-- Clear existing menu items.
	-- XXX might make sense to pool these, and maybe write a custom getDirectoryItemsInfo to reduce table churn.
	for i = #self.MN_items, 1, -1 do
		self.MN_items[i] = nil
	end

	self:menuSetDefaultSelection()

	print("self.usr_path", self.usr_path, "filter_type", filter_type)
	local items = love.filesystem.getDirectoryItems(self.usr_path)
	local base_path = #self.usr_path > 0 and (self.usr_path .. "/") or ""

	for i, fs_path in ipairs(items) do
		local v = love.filesystem.getInfo(base_path .. fs_path)
		print("i", base_path .. fs_path, v)
		if v then
			v.name = fs_path
			local item = setupMenuItem(self, v)
		end
	end

	enforceDefaultPrimaryColumn(self)
	self:sort()
end


function plan.makeWindowFrame(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:setFrameTitle("File Selector")

	frame:layoutSetBase("viewport")
	frame:setScrollRangeMode("zero")
	frame:setScrollBars(false, false)

	local menu_tab = frame:addChild("wimp/menu_tab")
		:geometrySetMode("remaining")

	menu_tab.renderThimble = function() end

	menu_tab.MN_drag_select = true
	menu_tab.MN_wrap_selection = false

	--[[
	menu_tab.x = 16
	menu_tab.y = 16
	menu_tab.w = 400
	menu_tab.h = 350
	--]]
	menu_tab:setScrollBars(true, true)

	enforceDefaultPrimaryColumn(menu_tab)

	local col_name = menu_tab:addColumn("Name", true, columnSortFiles) -- ID #1
	col_name.lock_visibility = true

	menu_tab:addColumn("Size", true, columnSortFiles) -- ID #2
	menu_tab:addColumn("ModTime", true, columnSortFiles) -- ID #3

	--[[
	-- Reserved for future use (determining types beyond just "directory", "file", etc.)
	menu_tab:addColumn("FileType", true, columnSortFiles) -- ID #?
	--]]

	menu_tab.reorder_limit = 1

	menu_tab:refreshColumnBar()
	menu_tab:sort()

	menu_tab.getDirectoryItems = menu_getDirectoryItems
	menu_tab.wid_keyPressed = fileSelectorKeyNav
	menu_tab.trySetPath = menu_trySetPath

	menu_tab:trySetPath("")

	menu_tab:reshape()

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
