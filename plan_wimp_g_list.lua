-- As seen in the Love Frames demo.


-- ProdUI
local commonMenu = require("lib.prod_ui.logic.common_menu")
local commonTab = require("lib.prod_ui.logic.common_tab")
local uiLayout = require("lib.prod_ui.ui_layout")
local widShared = require("lib.prod_ui.logic.wid_shared")


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

	local items = wid.menu.items

	table.sort(items, sort_functions[column.id])

	if not wid.column_sort_ascending then
		commonTab.reverseSequence(items)
	end

	return true
end


function plan.make(parent)

	local context = parent.context

	local implTabCell = context:getLua("shared/impl_tab_cell")

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Snapshot of '_G'")

	-- XXX Canvas layering test
	frame.ly_enabled = true

	frame.ly_r = 1
	frame.ly_g = 1
	frame.ly_b = 1
	frame.ly_a = 0.5

	frame.ly_x = 0
	frame.ly_y = 0
	frame.ly_angle = 0
	frame.ly_sx = 1
	frame.ly_sy = 1
	frame.ly_ox = 0
	frame.ly_oy = 0
	frame.ly_kx = 0
	frame.ly_ky = 0

	--[[
	frame.ly_use_quad = true
	frame.ly_qx = 32
	frame.ly_qy = 32
	frame.ly_qw = 256
	frame.ly_qh = 256
	--]]

	frame.ly_blend_mode = "alpha"

	frame.usr_time = 0.0

	frame.userUpdate = function(self, dt)

		--[[
		self.ly_x = self.w/2
		self.ly_y = self.h/2
		self.ly_ox = self.w/2
		self.ly_oy = self.h/2
		self.ly_angle = self.ly_angle + dt
		--]]
		self.usr_time = self.usr_time + dt
		self.ly_a = 0.5 + math.sin(self.usr_time) / 2
		--self.ly_sx = self.usr_time / 10
	end


	local content = frame:findTag("frame_content")
	if content then

		content.layout_mode = "resize"

		content:setScrollBars(false, false)

		local menu_tab = content:addChild("wimp/menu_tab")
		commonTab.setDefaultMeasurements(menu_tab)

		menu_tab.renderThimble = widShared.dummy

		menu_tab.drag_select = true
		menu_tab.menu.wrap_selection = false

		menu_tab:setScrollBars(true, true)

		menu_tab:reshape()

		menu_tab.lc_func = uiLayout.fitRemaining
		uiLayout.register(content, menu_tab)

		local col_key = menu_tab:addColumn("Key", true, columnSortGlobals) -- ID #1
		col_key.lock_visibility = true

		menu_tab:addColumn("Value", true, columnSortGlobals) -- ID #2

		menu_tab.column_sort_ascending = true

		-- Use the initial arbitrary lookups of hash keys to stabilize sorting.
		local secret_sort = 1

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
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan

