-- Shared container logic.


local context = select(1, ...)


local lgcContainer = {}


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local widLayout = context:getLua("core/wid_layout")


local sash_styles = context.resources.sash_styles


local _enum_scr_rng = uiTable.newEnumV("ScrollRangeMode", "zero", "auto", "manual")


lgcContainer.methods = {}
local _methods = lgcContainer.methods


function lgcContainer.setupMethods(self)
	uiTable.patch(self, lgcContainer.methods, false)
end


function _methods:setScrollRangeMode(mode)
	uiAssert.enum(1, mode, _enum_scr_rng)

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

	-- Segment "len" at start of drag state.
	self.SA_click_len = 0

	-- Max allowed dragging for this drag event.
	-- Based on the remaining layout space at click-down time.
	self.SA_drag_max = 0
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
			local GE = child.GE
			if GE.mode == "segment" and GE.sash_style then
				local style = widLayout.getSashStyleTable(GE.sash_style)
				local con_x, con_y = style.contract_x, style.contract_y
				local sx, sy, sw, sh = GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h
				if mxs >= child.x + sx + con_x
				and mxs < child.x + sx + sw - con_x
				and mys >= child.y + sy + con_y
				and mys < child.y + sy + sh - con_y
				then
					wid, sash_style = child, style
					break
				end
			end
		end

		if wid then
			self.SA_hover = wid
			local cursor_id = lgcContainer.getSashCursorID(wid.GE.edge, false)
			self.cursor_hover = sash_style[cursor_id]
			return true
		else
			self.SA_hover = false
			self.cursor_hover = false
		end
		-- check hover-off
	else
		local wid = self.SA_hover
		local GE = wid.GE
		-- widget is dead or no longer has a sash?
		if wid._dead or GE.mode ~= "segment" or not GE.sash_style then
			self.SA_hover = false
			self.cursor_hover = false
		else
			local sash_style = widLayout.getSashStyleTable(GE.sash_style)
			local exp_x, exp_y = sash_style.expand_x, sash_style.expand_y
			local sx, sy, sw, sh = GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h

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
		if wid and not wid._dead then
			local GE = wid.GE
			if GE.mode == "segment" and GE.sash_style then
				self.press_busy = "sash"
				self.SA_att_ax, self.SA_att_ay = x, y
				self.SA_click_len = GE.len

				if GE.edge == "left" or GE.edge == "right" then
					self.SA_drag_max = self.LO_w

				else -- GE.edge == "top" or GE.edge == "bottom"
					self.SA_drag_max = self.LO_h
				end

				local cursor_id = lgcContainer.getSashCursorID(GE.edge, true)
				local sash_style = widLayout.getSashStyleTable(GE.sash_style)
				self.cursor_press = sash_style[cursor_id]

				return true
			end
		end
	end
end


function lgcContainer.sashDragLogic(self, x, y)
	if self.SA_enabled
	and self.press_busy == "sash"
	then
		local wid = self.SA_hover
		if wid and not wid._dead then
			local GE = wid.GE
			if GE.mode == "segment" and GE.sash_style then
				local old_len = GE.len
				local edge = GE.edge

				if edge == "left" then
					local drag_amount = math.min(self.SA_drag_max, x - self.SA_att_ax) * (1 / math.max(0.1, context.scale))
					GE.len = math.max(0, self.SA_click_len + drag_amount)

				elseif edge == "right" then
					local drag_amount = math.max(-self.SA_drag_max, x - self.SA_att_ax) * (1 / math.max(0.1, context.scale))
					GE.len = math.max(0, self.SA_click_len - drag_amount)

				elseif edge == "top" then
					local drag_amount = math.min(self.SA_drag_max, y - self.SA_att_ay) * (1 / math.max(0.1, context.scale))
					GE.len = math.max(0, self.SA_click_len + drag_amount)

				elseif edge == "bottom" then
					local drag_amount = math.max(-self.SA_drag_max, y - self.SA_att_ay) * (1 / math.max(0.1, context.scale))
					GE.len = math.max(0, self.SA_click_len - drag_amount)

				else
					error("invalid segment edge")
				end

				-- Enforce preferred min+max length
				GE.len = pMath.roundInf(GE.len)
				GE.len = math.max(GE.len_min, math.min(GE.len, GE.len_max))

				if GE.len ~= old_len then
					self:reshape()
				end
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
		local GE = child.GE
		if GE.mode == "segment" and GE.sash_style then
			local style = widLayout.getSashStyleTable(GE.sash_style)
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
			local slc = (GE.edge == "left" or GE.edge == "right") and res.slc_tb or res.slc_lr
			local sx, sy, sw, sh = GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h
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
