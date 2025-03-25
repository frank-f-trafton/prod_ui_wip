--[[
	A container with support for sashes (draggable separators between widgets).

	Dividers do not support scrolling.
--]]


local context = select(1, ...)


local layout = context:getLua("core/layout")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "divider1",
	trickle = {}
}


def.reshape = widShared.reshapers.branch


function def:getSashBreadth()
	return self.skin.sash_breadth
end


function def:configureSashNode(n1, n2)
	-- TODO: Assertions.
	if n1.mode ~= "slice" then
		error("argument #1: expected a slice node.")
	end
	if n2.nodes and #n2.nodes > 0 then
		error("argument #2: sashes are supposed to be leaf nodes.")
	end

	n2:setMode("slice", "px", n1.slice_edge, self.skin.sash_breadth, true)
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true

	widShared.setupViewports(self, 2)

	self.node = layout.newRootNode()

	self.sash_hover = false
	self.press_busy = false

	-- length of the attached widget at start of sash drag state
	self.att_len = 0

	-- mouse cursor position (absolute) at start of sash drag state
	self.att_ax, self.att_ay = 0, 0

	self:skinSetRefs()
	self:skinInstall()
end


--[[
Viewport #1 is the border.
--]]


function def:uiCall_reshapePre()
	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	local n = self.node
	if n then
		n.x, n.y, n.w, n.h = self.vp_x, self.vp_y, self.vp_w, self.vp_h
		layout.splitNode(n, 1)
		layout.setWidgetSizes(n, 1)
	end
end


local function _checkMouseOverSash(self, node, mx, my)
	if node.slice_sash then
		local contract_x = self.skin.sash_contract_x
		local contract_y = self.skin.sash_contract_y
		if mx >= node.x + contract_x
		and mx < node.x + node.w - contract_x
		and my >= node.y + contract_y
		and my < node.y + node.h - contract_y
		then
			return node
		end

	elseif node.nodes then
		for i, child in ipairs(node.nodes) do
			local rv = _checkMouseOverSash(self, child, mx, my)
			if rv then
				return rv
			end
		end
	end
end


local function _locatePreviousNode(n1)
	local parent = n1.parent
	if parent then
		for i, child in ipairs(parent.nodes) do
			if child == n1 then
				return i > 1 and parent.nodes[i - 1]
			end
		end
	end
end


local function _getCursorID(edge, is_drag)
	if is_drag then
		return (edge == "left" or edge == "right") and "cursor_sash_drag_h" or "cursor_sash_drag_v"
	else
		return (edge == "left" or edge == "right") and "cursor_sash_hover_h" or "cursor_sash_hover_v"
	end
end


function def.trickle:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	local mx, my = self:getRelativePosition(mouse_x, mouse_y)
	if not self.sash_hover then
		local node = _checkMouseOverSash(self, self.node, mx, my)
		if node then
			self.sash_hover = node
			local cursor_id = _getCursorID(node.slice_edge, false)
			self.cursor_hover = self.skin[cursor_id]
			return true
		else
			self.sash_hover = false
			self.cursor_hover = false
		end
	else
		local node = self.sash_hover
		local expand_x = self.skin.sash_expand_x
		local expand_y = self.skin.sash_expand_y

		if not (mx >= node.x - expand_x
		and mx < node.x + node.w + expand_x
		and my >= node.y - expand_y
		and my < node.y + node.h + expand_y)
		then
			self.sash_hover = false
			self.cursor_hover = false
		end
	end
end


function def.trickle:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	self.sash_hover = false
	self.cursor_hover = false
end


function def.trickle:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self.sash_hover
	and button == 1
	and self.context.mouse_pressed_button == button
	then
		local cn = _locatePreviousNode(self.sash_hover) -- change_node
		if cn and cn.mode == "slice" and cn.slice_mode == "px" then
			self.press_busy = "sash"
			self.att_ax, self.att_ay = x, y
			if cn.slice_edge == "right" or cn.slice_edge == "left" then
				self.att_len = cn.w
			else -- "top", "bottom"
				self.att_len = cn.h
			end
			local cursor_id = _getCursorID(cn.slice_edge, true)
			self.cursor_press = self.skin[cursor_id]

			return true
		end
	end
end


function def.trickle:uiCall_pointerDrag(inst, x, y, dx, dy)
	if self.press_busy then
		local cn = _locatePreviousNode(self.sash_hover) -- change_node
		if cn and cn.mode == "slice" then
			local parent = cn.parent
			if not parent then
				error("missing parent node (no original dimensions to resize against).")
			end

			local edge = cn.slice_edge
			if edge == "right" then
				cn.slice_amount = math.min(cn.slice_amount + parent.w, self.att_len - (x - self.att_ax))

			elseif edge == "left" then
				cn.slice_amount = math.min(cn.slice_amount + parent.w, self.att_len + (x - self.att_ax))

			elseif edge == "top" then
				cn.slice_amount = math.min(cn.slice_amount + parent.h, self.att_len - (y - self.att_ay))

			elseif edge == "bottom" then
				cn.slice_amount = math.min(cn.slice_amount + parent.h, self.att_len + (y - self.att_ay))

			else
				error("invalid slice edge.")
			end

			self:reshape()
		end
	end
end


function def.trickle:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self.press_busy then
		self.press_busy = false
		self.cursor_press = false

		return true
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		-- Try directing thimble1 to the container's UI Frame ancestor.
		if button <= 3 then
			local wid = self
			while wid do
				if wid.frame_type then
					break
				end
				wid = wid.parent
			end
			if wid then
				wid:tryTakeThimble1()
			end
		end
	end
end


local function _renderSash(node, wid, ox, oy)
	if node.slice_sash then
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("fill", node.x, node.y, node.w, node.h)
	end
end


def.default_skinner = {
	--schema = {},


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		if skin.slc_body then
			love.graphics.setColor(skin.color_body)
			uiGraphics.drawSlice(skin.slc_body, 0, 0, self.w, self.h)
		end
	end,


	renderLast = function(self, ox, oy)
		if self.sash_hover then
			_renderSash(self.sash_hover, self, ox, oy)
		end
	end
}


return def
