--[[
	A container with support for sashes (draggable separators between widgets).

	Example diagram, with three widgets:

	┌┈┈┈┈┈┬┈┈┈┈┈┐
	│     │  B  │
	│  A  ├┈┈┈┈┈┤
	│     │  C  │
	└┈┈┈┈┈┴┈┈┈┈┈┘

	The tree structure:

	Node (Root) (Column split)
	├ Node <Ref: A>
	└ Node (Row split)
	  └ Node <Ref: B>
	  └ Node <Ref: C>

	Dividers do not support scrolling.
--]]


local context = select(1, ...)

local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")

local def = {
	skin_id = "divider1"
}


def.reshape = widShared.reshapers.branch


local _mt_node = {}
_mt_node.__index = _mt_node


_mt_node.placement = "remain" -- "left", "top", "right", "bottom", "remain"
_mt_node.active = true
_mt_node.pos_type = "unit" -- "dip" (density-independent pixels) or "unit" (value from 0-1)
_mt_node.pos = 0.5
_mt_node.wid_ref = false -- widget or false.
_mt_node.x = 0
_mt_node.y = 0
_mt_node.w = 0
_mt_node.h = 0
_mt_node.nodes = false -- array of child nodes or false


function _mt_node:newNode()
	self.nodes = self.nodes or {}
	local node = setmetatable({}, _mt_node)
	table.insert(self.nodes, node)
	return node
end


local function _partition(is_unit, pos, breadth)
	local cut
	if is_unit then
		cut = math.floor(breadth * pos)
	else
		cut = math.floor(math.max(0, breadth - pos))
	end
	return cut, breadth - cut
end


-- TODO: sash thickness


local function _splitter(n1, n2)
	if n2.placement == "left" then
		n2.y = n1.y
		n2.h = n1.h
		n2.w, n1.w = _partition(n2.pos_type == "unit", n2.pos, n1.w)
		n2.x = n1.x
		n1.x = n1.x + n2.w

	elseif n2.placement == "right" then
		n2.y = n1.y
		n2.h = n1.h
		n2.w, n1.w = _partition(n2.pos_type == "unit", n2.pos, n1.w)
		n2.x = n1.x + n1.w

	elseif n2.placement == "top" then
		n2.x = x
		n2.w = w
		n2.h, n1.h = _partition(n2.pos_type == "unit", n2.pos, n1.h)
		n2.y = n1.y
		n1.y = n1.y + n2.h

	elseif n2.placement == "bottom" then
		n2.x = n1.x
		n2.w = n1.w
		n2.h, n1.h = _partition(n2.pos_type == "unit", n2.pos, n1.h)
		n2.y = n1.y + n1.h

	else
		error("bad node placement enum: " .. tostring(n1.placement))
	end
end


local function _splitNode(n, _depth)
	print("_splitNode() " .. _depth .. ": start")
	print(n, "active:", n and n.active, "#nodes:", n and n.nodes and (#n.nodes))
	if n.active and n.nodes then
		print("old n XYWH", n.x, n.y, n.w, n.h)
		for i, nx in ipairs(n.nodes) do
			_splitter(n, nx)
			print("new n XYWH", n.x, n.y, n.w, n.h)
			print("new child " .. i .. " XYWH", nx.x, nx.y, nx.w, nx.h)
			_splitNode(nx, _depth + 1)
		end
	end
	print("_splitNode() " .. _depth .. ": end")
end


local function _setWidgetSizes(n, _depth)
	local wid = n.wid_ref
	if wid then
		wid.x, wid.y, wid.w, wid.h = n.x, n.y, n.w, n.h
	end
	if n.nodes then
		for i, nx in ipairs(n.nodes) do
			_setWidgetSizes(nx, _depth + 1)
		end
	end
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true

	widShared.setupViewports(self, 2)

	self.press_busy = false

	-- We're not using struct_tree.lua here because the nodes do not represent selectable menu items.
	self.node = setmetatable({}, _mt_node)

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
		_splitNode(n, 1)
		_setWidgetSizes(n, 1)
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


	--renderLast = function(self, ox, oy)
}


return def
