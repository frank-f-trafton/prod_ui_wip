-- Shared container logic.


local context = select(1, ...)


local lgcContainer = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local widLayout = context:getLua("core/wid_layout")


local sash_styles = context.resources.sash_styles


local _enum_scr_rng = uiTable.makeLUTV("zero", "auto", "manual")


lgcContainer.methods = {}
local _methods = lgcContainer.methods


function lgcContainer.setupMethods(self)
	uiTable.patch(self, lgcContainer.methods, false)
end


function _methods:setScrollRangeMode(mode)
	uiAssert.enum(1, mode, "scrollRangeMode", _enum_scr_rng)

	self.scroll_range_mode = mode

	return self
end


function _methods:getScrollRangeMode()
	return self.scroll_range_mode
end


function lgcContainer.keepWidgetInView(self, wid, pad_x, pad_y)
	-- Get widget position relative to this container.
	local x, y = wid:getPositionInAncestor(self)
	local w, h = wid.w, wid.h

	-- [XXX 1] There should be an optional rectangle within the widget that gets priority for being in view.
	-- Examples include the caret in a text box, the selection in a menu, and the thumb in a slider bar.
	if wid.focal_x then -- [XXX 1] Untested
		x = x + wid.focal_x
		y = y + wid.focal_y
		w = wid.focal_w
		h = wid.focal_h
	end

	self:scrollRectInBounds(x - pad_x, y - pad_y, x + w + pad_x, y + h + pad_y, false)
end


function lgcContainer.setupSashState(self)
	self.SA_enabled = false
	self.SA_hover = false

	-- Mouse cursor position (absolute) at start of drag state
	self.SA_att_ax, self.SA_att_ay = 0, 0

	-- Segment "amount" at start of drag state.
	self.SA_click_amount = 0
end


function _methods:setSashesEnabled(enabled)
	self.SA_enabled = not not enabled

	if not self.SA_enabled then
		self.SA_hover = false
		if self.press_busy == "sash" then
			self.press_busy = false
		end
	end

	return self
end


function _methods:getSashesEnabled()
	return self.SA_enabled
end


function lgcContainer.getSashCursorID(edge, is_drag)
	if is_drag then
		return (edge == "left" or edge == "right") and "cursor_drag_h" or "cursor_drag_v"
	else
		return (edge == "left" or edge == "right") and "cursor_hover_h" or "cursor_hover_v"
	end
end


-- For widgets that support dragging sashes. Call in def.trickle:uiCall_pointerHover().
-- @return true if a sash hover action occurred.
function lgcContainer.sashHoverLogic(self, mouse_x, mouse_y)
	if not self.SA_enabled then
		return
	end

	local mxs, mys = self:getRelativePositionScrolled(mouse_x, mouse_y)
	if not self.SA_hover then
		-- check hover-on
		local wid, sash_style
		for i, child in ipairs(self.children) do
			-- GE_c == seg_sash
			if child.GE_mode == "segment" and child.GE_c then
				local style = widLayout.getSashStyleTable(child.GE_c)
				local con_x, con_y = style.contract_x, style.contract_y
				local sx, sy, sw, sh = child.GE_d, child.GE_e, child.GE_f, child.GE_g -- sash bounding box
				if mxs >= child.x + sx + con_x
				and mxs < child.x + sx + sw - con_x
				and mys >= child.y + sy + con_y
				and mys < child.y + sy + sh - con_y
				then
					wid, sash_style = child, style
				end
			end
		end

		if wid then
			self.SA_hover = wid
			local seg_edge = wid.GE_a
			local cursor_id = lgcContainer.getSashCursorID(seg_edge, false)
			self.cursor_hover = sash_style[cursor_id]
			return true
		else
			self.SA_hover = false
			self.cursor_hover = false
		end
		-- check hover-off
	else
		local wid = self.SA_hover
		-- widget is dead or no longer has a sash?
		if wid._dead or wid.GE_mode ~= "segment" or not wid.GE_c then
			self.SA_hover = false
			self.cursor_hover = false
		else
			local sash_style = widLayout.getSashStyleTable(wid.GE_c)
			local exp_x, exp_y = sash_style.expand_x, sash_style.expand_y
			local sx, sy, sw, sh = wid.GE_d, wid.GE_e, wid.GE_f, wid.GE_g -- sash bounding box

			-- no longer hovering?
			if not (mxs >= wid.x + sx - exp_x
			and mxs < wid.x + sx + sw + exp_x
			and mys >= wid.y + sy - exp_y
			and mys < wid.y + sy + sh + exp_y)
			then
				self.SA_hover = false
				self.cursor_hover = false
			end
		end
	end
end


-- For containers that support draggable sashes. Call in def.trickle:uiCall_pointerHoverOff().
function lgcContainer.sashHoverOffLogic(self)
	self.SA_hover = false
	self.cursor_hover = false
end


function lgcContainer.sashPressLogic(self, x, y, button)
	if button == 1
	and self.context.mouse_pressed_button == button
	and self.SA_enabled
	then
		local wid = self.SA_hover
		if wid
		and not wid._dead
		and wid.GE_mode == "segment"
		and wid.GE_c -- seg_sash
		then
			self.press_busy = "sash"
			self.SA_att_ax, self.SA_att_ay = x, y
			self.SA_click_amount = wid.GE_b
			local seg_edge = wid.GE_a
			local cursor_id = lgcContainer.getSashCursorID(seg_edge, true)
			local sash_style = widLayout.getSashStyleTable(wid.GE_c)
			self.cursor_press = sash_style[cursor_id]

			return true
		end
	end
end


function lgcContainer.sashDragLogic(self, x, y)
	if self.SA_enabled
	and self.press_busy == "sash"
	then
		local wid = self.SA_hover
		if wid
		and not wid._dead
		and wid.GE_mode == "segment"
		and wid.GE_c -- seg_sash
		then
			local old_amount = wid.GE_b
			local seg_edge = wid.GE_a
			-- wid.GE_b == seg_amount

			if seg_edge == "left" then
				local drag_amount = (x - self.SA_att_ax) * (1 / math.max(0.1, context.scale))
				wid.GE_b = math.max(0, self.SA_click_amount + drag_amount)

			elseif seg_edge == "right" then
				local drag_amount = (x - self.SA_att_ax) * (1 / math.max(0.1, context.scale))
				wid.GE_b = math.max(0, self.SA_click_amount - drag_amount)

			elseif seg_edge == "top" then
				local drag_amount = (y - self.SA_att_ay) * (1 / math.max(0.1, context.scale))
				wid.GE_b = math.max(0, self.SA_click_amount + drag_amount)

			elseif seg_edge == "bottom" then
				local drag_amount = (y - self.SA_att_ay) * (1 / math.max(0.1, context.scale))
				wid.GE_b = math.max(0, self.SA_click_amount - drag_amount)

			else
				error("invalid segment edge")
			end

			if wid.GE_b ~= old_amount then
				self:reshape()
			end
		end

		return true
	end
end


function lgcContainer.sashUnpressLogic(self)
	if self.press_busy == "sash" then
		self.press_busy = false
		self.cursor_press = false

		return true
	end
end


function lgcContainer.renderSashes(self)
	local scr_x, scr_y = self.scr_x, self.scr_y

	for i, child in ipairs(self.children) do
		-- GE_c == seg_sash
		if child.GE_mode == "segment" and child.GE_c then
			local style = widLayout.getSashStyleTable(child.GE_c)
			local res
			if not self.SA_enabled then
				res = style.res_disabled

			elseif self.SA_hover == child then
				if self.press_busy == "sash" then
					res = style.res_press
				else
					res = style.res_hover
				end
			else
				res = style.res_idle
			end

			love.graphics.setColor(res.col_body)
			local slc = (child.GE_a == "left" or child.GE_a == "right") and res.slc_tb or res.slc_lr
			local sx, sy, sw, sh = child.GE_d, child.GE_e, child.GE_f, child.GE_g
			uiGraphics.drawSlice(slc, -scr_x + child.x + sx, -scr_y + child.y + sy, sw, sh)

			-- Debug stuff
			--[[
			love.graphics.setColor(1, 0, 1, 0.25)
			love.graphics.rectangle("fill", -scr_x + child.x + sx, -scr_y + child.y + sy, sw, sh)

			love.graphics.setColor(1, 1, 1, 1.0)
			love.graphics.print(sx .. ", " .. sy .. ", " .. sw .. ", " .. sh, -scr_x + child.x + sx, -scr_y + child.y + sy)
			--]]
		end
	end
end


return lgcContainer
