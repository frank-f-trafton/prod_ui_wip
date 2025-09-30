-- Shared tabular cell code.


local context = select(1, ...)


local implTabCell = {}


local lgcMenu = context:getLua("shared/lgc_menu")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


function implTabCell.reshape(cell, widget)
	local skin = widget.skin
	local font = skin.cell_font

	cell.tq_icon = lgcMenu.getIconQuad(widget.icon_set_id, cell.icon_id)
	--print("ICON_ID", cell.icon_id, "TQ_ICON", cell.tq_icon)

	local tq_icon = cell.tq_icon
	if tq_icon then
		cell.icon_x = 0
		cell.icon_y = 0
		cell.icon_w = skin.item_h
		cell.icon_h = skin.item_h
	else
		cell.icon_x, cell.icon_y, cell.icon_w, cell.icon_h = 0, 0, 0, 0
	end

	cell.text_x = cell.icon_x + cell.icon_w + math.floor(font:getWidth("M") / 4)
	cell.text_y = math.floor((skin.item_h - font:getHeight()) / 2)
end


--- A default render function for cells.
function implTabCell.render(cell, item, column, widget, os_x, os_y)
	--[[
	So, at this point in rendering:
	* The LÖVE coordinate system is translated to 'column.x - x_scroll' and 'vp_y - y_scroll'.
	* A scissor box is applied to the column contents (header excluded)
	--]]

	local skin = widget.skin

	local tq_icon = cell.tq_icon
	if tq_icon then
		love.graphics.setColor(skin.color_cell_icon)
		uiGraphics.quadXYWH(
			tq_icon,
			cell.icon_x,
			item.y + cell.icon_y,
			cell.icon_w,
			cell.icon_h
		)
	end

	love.graphics.setColor(skin.color_cell_text)
	love.graphics.setFont(skin.cell_font)
	love.graphics.print(cell.text, cell.text_x, item.y + cell.text_y)
end


return implTabCell

