
--[[
XXX: Under construction.

A list of properties.

Multiple categories:

              Drag to resize columns
                        |
Optional icons (bijoux) |
     |                  |
     | Labels           |   Controls
     |   |              |      |
     V   V              V      V
+----------------------------------------+-+
| v [B] Category                         |^|  <-- Click '>'/'v' or press right/left to expand or collapse
| +---------------------+--------------+ +-+
| | [B] Foo             |     [x]      | | |
| |:[B]:Bar:::::::::::::|:::[    0.02]:| | |
| | [B] Baz             |   [ "Twist"] | | |
| | [B] Bop             | [dir/ectory] | | |
| +---------------------+--------------+ | |
|                                        | |
| > Collapsed Category                   +-+
| -------------------------------------- |v|
+----------------------------------------+-+


Single category:

+---------------------+--------------+-+
| [B] Foo             |     [x]      |^|
|:[B]:Bar:::::::::::::|:::[    0.02]:+-+
| [B] Baz             |   [ "Twist"] | |
| [B] Bop             | [dir/ectory] | |
|                     |              +-+
|                     |              |v|
+---------------------+--------------+-+


In single category mode:
	* Only items from `self.category` are shown.
	* `category.expanded` has no effect.


category = {
	text = "Foobar",
	<icon_id>,
	items = {
		{
			_type = "checkbox",
			text = "Bazbop",
			<icon_id>,
			enabled = true,
			-- (checkbox-specific state)
		},
	},
}

--]]


local context = select(1, ...)


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonScroll = require(context.conf.prod_ui_req .. "logic.common_scroll")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "logic.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "properties_box1",
	click_repeat_oob = true, -- Helps with integrated scroll bar buttons
}


widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


-- XXX: function def:arrange()


-- * Scroll helpers *


def.getInBounds = commonMenu.getItemInBoundsY
def.selectionInView = commonMenu.selectionInView


-- * Spatial selection *


def.getItemAtPoint = commonMenu.widgetGetItemAtPoint -- (self, px, py, first, last)
def.trySelectItemAtPoint = commonMenu.widgetTrySelectItemAtPoint -- (self, x, y, first, last)


-- * Selection movement *


def.movePrev = commonMenu.widgetMovePrev
def.moveNext = commonMenu.widgetMoveNext
def.moveFirst = commonMenu.widgetMoveFirst
def.moveLast = commonMenu.widgetMoveLast


-- XXX: wid_action*()
-- XXX: wid_select()
-- XXX: wid_dropped()
-- XXX: wid_defaultKeyNav()


function def:setMultipleCategories(enabled)
	self.multi_categories = not not enabled
end


local function updateItemDimensions(self, skin, item)

	local font = skin.font

	item.w = self.control_w
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)
end


function def:addCategory(text, category_pos, bijou_id)

	-- XXX: Assertions.

	category_pos = category_pos or #self.categories + 1

	print("add category", text, category_pos, bijou_id)

	local skin = self.skin
	local font = skin.font

	-- Categories are a kind of menu item that holds one level of other items.
	local item = {}

	item._type = "category"
	item.items = {}

	item.selectable = true
	item.expanded = true

	item.text = text
	item.bijou_id = bijou_id
	item.tq_bijou = self.context.resources.tex_quads[bijou_id]

	item.x, item.y = 0, 0
	updateItemDimensions(self, skin, item)

	table.insert(self.categories, category_pos, item)

	return item
end


-- XXX: removeCategory


function def:addProperty(category, text, property_type, property_pos, bijou_id)

	-- XXX: Assertions.

	property_pos = property_pos or #category.items + 1

	print("add property", category, property_pos, text, bijou_id)

	local skin = self.skin
	local font = skin.font

	local item = {}

	item.selectable = true

	item.text = text
	item.bijou_id = bijou_id
	item.tq_bijou = self.context.resources.tex_quads[bijou_id]
	item.property_type = property_type

	-- XXX: Property-Type initialization.

	item.x, item.y = 0, 0
	updateItemDimensions(self, skin, item)

	table.insert(category.items, property_pos, item)

	return item
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupDoc(self)
		widShared.setupScroll(self)
		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		self.press_busy = false

		commonMenu.instanceSetup(self)

		-- When true, the menu items list is populated with the contents of `self.categories`.
		-- When false, `self.category` is used instead.
		self.multi_categories = false

		self.category = false
		self.categories = {}
		self.menu = commonMenu.new()

		self.wrap_selection = false

		-- X positions and widths of columns and other widget components.
		-- XXX: skin, scale
		self.label_w = 200
		self.label_x = 0

		self.control_w = 0
		self.control_x = 0

		self.icon_x = 0
		self.icon_w = 0

		self.text_x = 0

		-- State flags.
		self.enabled = true

		-- When true, allows the user to select categories and expand/compress them.
		self.expanders_active = false

		-- Shows item icons.
		self.show_icons = false

		self:skinSetRefs()
		self:skinInstall()
	end
end


function def:uiCall_reshape()

	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars) from the content.

	local skin = self.skin

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	widShared.carveViewport(self, 1, "border")
	commonScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, "margin")

	self.label_x = self.vp_x
	-- XXX: label width is changed by dragging the sash component.
	self.control_w = self.vp_w - self.label_w
	self.control_x = self.label_x + self.label_w

	self:scrollClampViewport()
	commonScroll.updateScrollState(self)

	self:cacheUpdate(true)
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)

	local menu = self.menu
	local skin = self.skin

	if refresh_dimensions then
		self.doc_w, self.doc_h = 0, 0

		-- Document height is based on the last item in the menu.
		local last_item = menu.items[#menu.items]
		if last_item then
			self.doc_h = last_item.y + last_item.h
		end

		-- Document width is the viewport width.
		self.doc_w = self.vp_w

		-- XXX
	end

	-- Set the draw ranges for items.
	commonMenu.widgetAutoRangeV(self)
end


function def:orderItems()

	-- Clear the existing menu item layout.
	local items = self.menu.items
	for i = #items, 1, -1 do
		items[i] = nil
	end

	-- Repopulate the menu with open categories and their sub-items.
	if not self.multi_categories then
		if self.category then
			for j, item in ipairs(self.category.items) do
				items[#items + 1] = item
			end
		end

	else
		for i, category in ipairs(self.categories) do
			if category.expanded then
				items[#items + 1] = category
				for j, item in ipairs(category.items) do
					items[#items + 1] = item
				end
			end
		end
	end
end


def.skinners = {
	default = {

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
			local menu = self.menu
			local items = menu.items

			local font = skin.font

			love.graphics.push("all")

			-- [[
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle("line", 0, 0, self.w - 1, self.h - 1)
			--]]

			-- [[
			love.graphics.setColor(1, 1, 0, 1)
			love.graphics.print("Labels", self.label_x, 32)
			love.graphics.rectangle("line", self.label_x, 0, self.label_w - 1, self.h - 1)
			--]]

			-- [[
			love.graphics.setColor(1, 0, 1, 1)
			love.graphics.print("Controls", self.control_x, 32)
			love.graphics.rectangle("line", self.control_x, 0, self.control_w - 1, self.h - 1)
			--]]

			print("categories", #self.categories, "#items", #items)

			for i = 1, #items do
				local item = items[i]
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.rectangle("line", item.x, item.y, item.w - 1, item.h - 1)
				love.graphics.print(item.text, item.x, item.y)
			end

			love.graphics.pop()

			--widDebug.debugDrawViewport(self, 1)
			--widDebug.debugDrawViewport(self, 2)
		end,

		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy) end,
	},
}


return def
