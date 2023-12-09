

-- ProdUI
local commonMenu = require("lib.prod_ui.logic.common_menu")
local commonTab = require("lib.prod_ui.logic.common_tab")
local commonWimp = require("lib.prod_ui.logic.common_wimp")
local itemOps = require("lib.prod_ui.logic.item_ops")
local keyCombo = require("lib.prod_ui.lib.key_combo")
local uiLayout = require("lib.prod_ui.ui_layout")
local widShared = require("lib.prod_ui.logic.wid_shared")


local plan = {}


local function rngChr(n)

	local str = ""
	for i = 1, n do
		str = str .. string.char(love.math.random(33, 127))
	end

	return str
end


function plan.make(parent)

	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Tabular Menu Test")

	local header = frame:findTag("frame_header")
	if header then
		--header.condensed = true
	end

	local content = frame:findTag("frame_content")
	if content then

		content.layout_mode = "resize"

		content:setScrollBars(false, false)

		local menu_tab = content:addChild("wimp/menu_tab")
		commonTab.setDefaultMeasurements(menu_tab)

		menu_tab.renderThimble = widShared.dummy

		menu_tab.drag_select = true
		menu_tab.wrap_selection = false

		menu_tab:setScrollBars(true, true)

		menu_tab:reshape()

		menu_tab.lc_func = uiLayout.fitRemaining
		uiLayout.register(content, menu_tab)

		menu_tab:addColumn("Column 1", true, commonTab.columnSortGeneric) -- ID #1
		menu_tab:addColumn("Column 2", true, commonTab.columnSortGeneric) -- ID #2
		menu_tab:addColumn("Column 3", true, commonTab.columnSortGeneric) -- ID #3
		menu_tab:addColumn("Column 4", true, commonTab.columnSortGeneric) -- ID #4

		menu_tab.column_sort_ascending = true

		local rnd = love.math.random
		local chr = string.char
		local function rndChr(n)
			local str = ""
			for i = 1, n do
				str = str .. chr(rnd(32, 126))
			end
			return str
		end

		for i = 1, 100 do
			local item = menu_tab:addRow()

			item.cells[1] = {text = tostring(i)}
			item.cells[2] = {text = rngChr(3)}
			item.cells[3] = {text = rndChr(5)}
			item.cells[4] = {text = rndChr(8)}

			local implTabCell = context:getLua("shared/impl_tab_cell")
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

