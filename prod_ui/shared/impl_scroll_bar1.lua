-- ProdUI: Scroll Bar implementation #1.


local implScrollBar1 = {}


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")



function implScrollBar1.draw(t_data, scr, x, y)
	local shared = t_data.shared

	local tbl_idle = shared.idle
	local tbl_hover = shared.hover
	local tbl_press = shared.press
	local tbl_disabled = shared.disabled

	local xx, yy = x + scr.x, y + scr.y

	local tquad_pixel = t_data.tquad_pixel

	-- Optional body fill. May be useful if there are gaps between the trough and buttons.
	if t_data.render_body then
		love.graphics.setColor(t_data.body_color)
		uiGraphics.quad1x1(tquad_pixel, xx, yy, scr.w, scr.h)
	end

	-- Trough
	if scr.tr and scr.trough_valid then
		love.graphics.setColor(t_data.col_trough)
		uiGraphics.quad1x1(tquad_pixel, xx + scr.tr_x, yy + scr.tr_y, scr.tr_w, scr.tr_h)
	end

	-- Thumb
	if scr.th and scr.thumb_valid then
		local tbl = (scr.press == "thumb") and tbl_press or (scr.hover == "thumb") and tbl_hover or tbl_idle

		local slc_thumb = tbl.slice
		love.graphics.setColor(tbl.col_body)
		uiGraphics.drawSlice(slc_thumb, xx + scr.th_x, yy + scr.th_y, scr.th_w, scr.th_h)
	end

	-- Buttons
	if scr.b1 then
		local tbl = (not scr.b1_valid) and tbl_disabled
			or (scr.press == "b1") and tbl_press
			or (scr.hover == "b1") and tbl_hover
			or tbl_idle

		local slc_button = tbl.slice
		love.graphics.setColor(tbl.col_body)
		uiGraphics.drawSlice(slc_button, xx + scr.b1_x, yy + scr.b1_y, scr.b1_w, scr.b1_h)

		local tq_arrow = scr.horizontal and t_data.tq_arrow_left or t_data.tq_arrow_up
		local breadth = scr.horizontal and scr.b1_h or scr.b1_w
		local pad = math.floor(0.5 + breadth * 0.25)

		love.graphics.setColor(tbl.col_symbol)
		uiGraphics.quadXYWH(
			tq_arrow,
			xx + scr.b1_x + pad,
			yy + scr.b1_y + pad,
			math.max(0, scr.b1_w - pad*2),
			math.max(0, scr.b1_h - pad*2)
		)
	end

	if scr.b2 then
		local tbl = (not scr.b1_valid) and tbl_disabled
			or (scr.press == "b2") and tbl_press
			or (scr.hover == "b2") and tbl_hover
			or tbl_idle

		local slc_button = tbl.slice
		love.graphics.setColor(tbl.col_body)
		uiGraphics.drawSlice(slc_button, xx + scr.b2_x, yy + scr.b2_y, scr.b2_w, scr.b2_h)

		local tq_arrow = scr.horizontal and t_data.tq_arrow_right or t_data.tq_arrow_down
		local breadth = scr.horizontal and scr.b2_h or scr.b2_w
		local pad = math.floor(0.5 + breadth * 0.25)

		love.graphics.setColor(tbl.col_symbol)
		uiGraphics.quadXYWH(
			tq_arrow,
			xx + scr.b2_x + pad,
			yy + scr.b2_y + pad,
			math.max(0, scr.b2_w - pad*2),
			math.max(0, scr.b2_h - pad*2)
		)
	end
end


return implScrollBar1
