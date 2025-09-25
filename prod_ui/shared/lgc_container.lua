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
	self.sashes_enabled = false
	self.sash_hover = false

	-- Length of the node to resize at start of drag state
	self.sash_att_len = 0

	-- Mouse cursor position (absolute) at start of drag state
	self.sash_att_ax, self.sash_att_ay = 0, 0
end


function _methods:setSashesEnabled(enabled)
	self.sashes_enabled = not not enabled

	if not self.sashes_enabled then
		self.sash_hover = false
		if self.press_busy == "sash" then
			self.press_busy = false
		end
	end

	return self
end


function _methods:getSashesEnabled()
	return self.sashes_enabled
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
	if not self.sashes_enabled then
		return
	end

	local mxs, mys = self:getRelativePositionScrolled(mouse_x, mouse_y)
	if not self.sash_hover then
		-- check hover-on
		local wid, sash_style
		for i, child in ipairs(self.children) do
			-- ge_c == seg_sash
			if child.ge_mode == "segment" and child.ge_c then
				local style = widLayout.getSashStyleTable(child.ge_c)
				local con_x, con_y = style.contract_x, style.contract_y
				local sx, sy, sw, sh = child.ge_d, child.ge_e, child.ge_f, child.ge_g -- sash bounding box
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
			self.sash_hover = wid
			local seg_edge = wid.ge_a
			local cursor_id = lgcContainer.getSashCursorID(seg_edge, false)
			self.cursor_hover = sash_style[cursor_id]
			return true
		else
			self.sash_hover = false
			self.cursor_hover = false
		end
		-- check hover-off
	else
		local wid = self.sash_hover
		-- widget is dead or no longer has a sash?
		if wid._dead or wid.ge_mode ~= "segment" or not wid.ge_c then
			self.sash_hover = false
			self.cursor_hover = false
		else
			local sash_style = widLayout.getSashStyleTable(wid.ge_c)
			local exp_x, exp_y = sash_style.expand_x, sash_style.expand_y
			local sx, sy, sw, sh = wid.ge_d, wid.ge_e, wid.ge_f, wid.ge_g -- sash bounding box

			-- no longer hovering?
			if not (mxs >= wid.x + sx - exp_x
			and mxs < wid.x + sx + sw + exp_x
			and mys >= wid.y + sy - exp_y
			and mys < wid.y + sy + sh + exp_y)
			then
				self.sash_hover = false
				self.cursor_hover = false
			end
		end
	end
end


-- For containers that support draggable sashes. Call in def.trickle:uiCall_pointerHoverOff().
function lgcContainer.sashHoverOffLogic(self)
	self.sash_hover = false
	self.cursor_hover = false
end


function lgcContainer.sashPressLogic(self, x, y, button)
	if button == 1
	and self.context.mouse_pressed_button == button
	and self.sashes_enabled
	then
		local wid = self.sash_hover
		if wid
		and not wid._dead
		and wid.ge_mode == "segment"
		and wid.ge_c -- seg_sash
		then
			self.press_busy = "sash"
			self.sash_att_ax, self.sash_att_ay = x, y
			local seg_edge = wid.ge_a
			if seg_edge == "right" or seg_edge == "left" then
				self.sash_att_len = wid.w
			else -- "top", "bottom"
				self.sash_att_len = wid.h
			end
			local cursor_id = lgcContainer.getSashCursorID(seg_edge, true)
			local sash_style = widLayout.getSashStyleTable(wid.ge_c)
			self.cursor_press = sash_style[cursor_id]

			return true
		end
	end
end


function lgcContainer.sashDragLogic(self, x, y)
	if self.sashes_enabled
	and self.press_busy == "sash"
	then
		local wid = self.sash_hover
		if wid
		and not wid._dead
		and wid.ge_mode == "segment"
		and wid.ge_c -- seg_sash
		then
			local old_amount = wid.ge_b
			local seg_edge = wid.ge_a
			-- wid.ge_b == seg_amount

			if seg_edge == "right" then
				wid.ge_b = math.max(0, self.sash_att_len - (x - self.sash_att_ax))

			elseif seg_edge == "left" then
				wid.ge_b = math.max(0, self.sash_att_len + (x - self.sash_att_ax))

			elseif seg_edge == "top" then
				wid.ge_b = math.max(0, self.sash_att_len - (y - self.sash_att_ay))

			elseif seg_edge == "bottom" then
				wid.ge_b = math.max(0, self.sash_att_len + (y - self.sash_att_ay))

			else
				error("invalid segment edge")
			end

			if wid.ge_b ~= old_amount then
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
	for i, child in ipairs(self.children) do
		-- ge_c == seg_sash
		if child.ge_mode == "segment" and child.ge_c then
			local style = widLayout.getSashStyleTable(child.ge_c)
			local res
			if not self.sashes_enabled then
				res = style.res_disabled

			elseif self.sash_hover == child then
				if self.press_busy == "sash" then
					res = style.res_press
				else
					res = style.res_hover
				end
			else
				res = style.res_idle
			end

			love.graphics.setColor(res.col_body)
			local slc = (child.ge_a == "left" or child.ge_a == "right") and res.slc_tb or res.slc_lr
			local sx, sy, sw, sh = child.ge_d, child.ge_e, child.ge_f, child.ge_g
			uiGraphics.drawSlice(slc, child.x + sx, child.y + sy, sw, sh)

			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("fill", child.x + sx, child.y + sy, sw, sh)
		end
	end
end


return lgcContainer
