-- Shared tabular cell code.


local context = select(1, ...)


local implTabCell = {}


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


--- A default render function for cells.
function implTabCell.default_renderCell(item, widget, column, cell, os_x, os_y)

	local skin = widget.skin

	local tq_bijou = cell.tq_bijou
	local x_offset = 0

	if tq_bijou then
		love.graphics.setColor(skin.color_cell_bijou)
		uiGraphics.quadXYWH(
			tq_bijou,
			item.x + widget.default_item_bijou_x,
			item.y + widget.default_item_bijou_y,
			widget.default_item_bijou_w,
			widget.default_item_bijou_h
		)
		x_offset = x_offset + widget.default_item_bijou_x + widget.default_item_bijou_w
	end

	love.graphics.setColor(skin.color_cell_text)
	love.graphics.setFont(skin.cell_font)
	love.graphics.print(cell.text, x_offset + widget.default_item_text_x, item.y + widget.default_item_text_y)
end


return implTabCell

