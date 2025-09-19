-- Shared container logic.


local context = select(1, ...)


local lgcContainer = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local widLayout = context:getLua("core/wid_layout")


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


function _methods:configureSashWidget(w1, w2)
	if not uiTable.valueInArray(self.children, w1) then
		error("'w1' must be a direct child of the calling widget")

	elseif not uiTable.valueInArray(self.children, w2) then
		error("'w2' must be a direct child of the calling widget")

	elseif not w2.UI_is_sash then
		error("'w2' is not a sash widget")
	end

	local mode, _, slice_edge = w1:geometryGetMode()

	if mode ~= "slice" then
		error("argument #1: expected a widget configured for 'slice' layout mode")
	end

	w2:geometrySetMode("slice", "px", slice_edge, self.skin.sash_style.breadth, true, true)

	w2.tall = (slice_edge == "left" or slice_edge == "right") and true or false

	return self
end


local function _checkMouseOverSash(self, mx, my, con_x, con_y)
	for i, wid in ipairs(self.children) do
		if wid.UI_is_sash then
			if mx >= wid.x + con_x
			and mx < wid.x + wid.w - con_x
			and my >= wid.y + con_y
			and my < wid.y + wid.h - con_y
			then
				return wid
			end
		end
	end
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
	local sash_style = self.skin.sash_style
	if not self.sash_hover then
		local wid = _checkMouseOverSash(self, mxs, mys, sash_style.contract_x, sash_style.contract_y)
		if wid then
			self.sash_hover = wid
			local _, _, slice_edge = wid:geometryGetMode()
			local cursor_id = lgcContainer.getSashCursorID(slice_edge, false)
			self.cursor_hover = sash_style[cursor_id]
			return true
		else
			self.sash_hover = false
			self.cursor_hover = false
		end
	else
		local wid = self.sash_hover
		local expand_x = sash_style.expand_x
		local expand_y = sash_style.expand_y

		if not (mxs >= wid.x - expand_x
		and mxs < wid.x + wid.w + expand_x
		and mys >= wid.y - expand_y
		and mys < wid.y + wid.h + expand_y)
		then
			self.sash_hover = false
			self.cursor_hover = false
		end
	end
end


-- For widgets with draggable sashes, call in def.trickle:uiCall_pointerHoverOff().
function lgcContainer.sashHoverOffLogic(self)
	self.sash_hover = false
	self.cursor_hover = false
end


function lgcContainer.sashPressLogic(self, x, y, button)
	if self.sashes_enabled then
		local sash = self.sash_hover

		if sash
		and not sash._dead
		and button == 1
		and self.context.mouse_pressed_button == button
		then
			local cn = self.children[sash:getIndex() - 1] -- prev sibling
			if cn then
				local mode, slice_mode, slice_edge = cn:geometryGetMode()
				if mode == "slice" and slice_mode == "px" then
					self.press_busy = "sash"
					self.sash_att_ax, self.sash_att_ay = x, y
					if slice_edge == "right" or slice_edge == "left" then
						self.sash_att_len = cn.w
					else -- "top", "bottom"
						self.sash_att_len = cn.h
					end
					local cursor_id = lgcContainer.getSashCursorID(slice_edge, true)
					self.cursor_press = self.skin.sash_style[cursor_id]

					return true
				end
			end
		end
	end
end


function lgcContainer.sashDragLogic(self, x, y)
	if self.sashes_enabled
	and self.press_busy == "sash"
	then
		local sash = self.sash_hover
		if sash then
			local cn = self.children[sash:getIndex() - 1] -- prev sibling
			if cn then
				local mode, slice_mode, slice_edge, slice_amount, slice_scale = cn:geometryGetMode()
				if mode == "slice" then
					if slice_edge == "right" then
						slice_amount = math.min(slice_amount + self.w, self.sash_att_len - (x - self.sash_att_ax))

					elseif slice_edge == "left" then
						slice_amount = math.min(slice_amount + self.w, self.sash_att_len + (x - self.sash_att_ax))

					elseif slice_edge == "top" then
						slice_amount = math.min(slice_amount + self.h, self.sash_att_len - (y - self.sash_att_ay))

					elseif slice_edge == "bottom" then
						slice_amount = math.min(slice_amount + self.h, self.sash_att_len + (y - self.sash_att_ay))

					else
						error("invalid slice edge.")
					end

					cn:geometrySetMode("slice", slice_mode, slice_edge, slice_amount, slice_scale, true)
					self:reshape()
				end

				return true
			end
		end
	end
end


function lgcContainer.sashUnpressLogic(self)
	if self.press_busy == "sash" then
		self.press_busy = false
		self.cursor_press = false

		return true
	end
end


return lgcContainer