--[[
The main body of a dropdown box.

Closed:

 ┌─────────────┬─┐
 │ [I] Foobar  │v│ --- To open, click anywhere or press space/enter.
 └─────────────┴─┘     Press up/down or mouse-wheel to change the selection without opening.
   ^
   |
 Optional
 item icon

Opened:

┌─────────────┬─┐
│ [I] Foobar  │v│
├─────────────┼─┤
│ [I] Bazbop  │^│ ══╗
│ [I] Foobar  ├─┤   ║
│:[I]:Jingle::│ │   ║
│ [I] Bingo   │ │   ╠═══ "Drawer" with list of selections.
│ [I] Pogo    ├─┤   ║
│ [I] Stove   │v│   ║
└─────────────┴─┘ ══╝

The main widget and the drawer have separate menus, the latter being populated upon creation.
Changing the dropdown's menu while the drawer is open does not affect the drawer's menu, and
vice versa.

TODO: pressing keys to jump to the next item beginning with the key cap label.
^ Probably need a text-input field for additional code points... same for ListBoxes.
Not sure about TreeBoxes.

TODO: right-click and thimble actions on the dropdown body. Note that context menus will not be supported from
the dropdown drawer, since the drawer uses the same "pop-up menu slot" in the WIMP root as context menus. They
should still work when clicking on the body, however.
--]]


local context = select(1, ...)


local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcMenu = context:getLua("shared/wc/wc_menu")
local wcPopUp = context:getLua("shared/wc/wc_pop_up")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "dropdown_box1",

	default_settings = {
		icon_side = "left", -- "left", "right"
		show_icons = false,
		text_align_h = "left", -- "left", "center", "right"
		icon_set_id = false, -- lookup for 'resources.icons[icon_set_id]'
	}
}


wcMenu.attachMenuMethods(def)


local _arrange_tb = wcMenu.arrangers["list-tb"]
function def:arrangeItems(first, last)
	_arrange_tb(self, self.vp, true, first, last)
end


def.movePrev = wcMenu.widgetMovePrev
def.moveNext = wcMenu.widgetMoveNext
def.moveFirst = wcMenu.widgetMoveFirst
def.moveLast = wcMenu.widgetMoveLast
def.movePageUp = wcMenu.widgetMovePageUp
def.movePageDown = wcMenu.widgetMovePageDown


def.wid_buttonAction = uiDummy.func
def.wid_buttonAction2 = uiDummy.func
def.wid_buttonAction3 = uiDummy.func


--def.evt_thimbleAction
--def.evt_thimbleAction2


--- Callback for a change in the item choice.
function def:wid_chosenSelection(index, tbl)
	-- ...
end

--- Callback for when the drawer selection changes.
function def:wid_drawerSelection(drawer, index, tbl)
	-- ...
end


local function _updateTextWidth(self)
	local item = self.MN_items[self.MN_index]

	self.chosen_text_w = item and self.skin.font:getWidth(item.text) or 0
end


local _mt_item = {selectable=true, x=0, y=0, w=0, h=0}
_mt_item.__index = _mt_item


function def:addItem(text, pos, icon_id)
	local skin = self.skin
	local font = skin.font
	local items = self.MN_items

	uiAssert.type(1, text, "string")
	uiAssert.integerRangeEval(2, pos, 1, #items + 1)
	uiAssert.typeEval(3, icon_id, "string")

	pos = pos or #items + 1

	local item = setmetatable({}, _mt_item)

	item.text = text
	item.icon_id = icon_id
	item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id)

	table.insert(items, pos, item)

	wcMenu.trySelectIfNothingSelected(self)

	-- TODO: maybe destroy any open drawer, as a precaution, when this menu changes?

	return item
end


function def:removeItem(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeItemByIndex(item_i)
	uiAssert.integerGE(1, item_i, 0)

	local items = self.MN_items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	local removed = table.remove(items, item_i)

	wcMenu.removeItemIndexCleanup(self, item_i, "MN_index")
	_updateTextWidth(self)

	return removed_item
end


function def:setSelection(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)
	uiAssert.integerGE(1, item_i, 0)

	local index_old = self.MN_index

	self:menuSetSelectedIndex(item_i)

	_updateTextWidth(self)

	if index_old ~= self.MN_index then
		self:wid_chosenSelection(self.MN_index, self.MN_items[self.MN_index])
	end
end


def.setIconSetID = wcMenu.setIconSetID
def.getIconSetID = wcMenu.getIconSetID


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 5)

	wcMenu.setup(self)
	self.MN_page_jump_size = 4
	self.MN_wrap_selection = false

	-- When opened, this holds a reference to the pop-up widget.
	self.wid_drawer = false

	self.chosen_text_w = 0

	-- State flags
	self.enabled = true

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:evt_reshapePre()
	-- Viewport #1 is the main content area.
	-- Viewport #2 is the item area.
	-- Viewport #3 is for the item text.
	-- Viewport #4 is for the item icon.
	-- Viewport #5 is the decorative button which indicates that this widget is clickable.

	local skin = self.skin
	local vp, vp2, vp3, vp4, vp5 = self.vp, self.vp2, self.vp3, self.vp4, self.vp5

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)
	vp:copy(vp2)

	local button_spacing = (skin.button_spacing == "auto") and self.vp.h or skin.button_spacing

	vp2:splitOrOverlay(vp5, skin.button_placement, button_spacing)

	vp2:copy(vp3)

	local icon_spacing = self.show_icons and skin.icon_spacing or 0

	vp3:splitOrOverlay(vp4, skin.icon_side, icon_spacing)

	-- Additional text padding
	vp3:reduceT(skin.box.margin)

	_updateTextWidth(self)

	return true
end


function def:_openPopUpMenu()
	if not self.wid_drawer then
		local skin = self.skin
		local root = self:nodeGetRoot()

		local ax, ay = self:getAbsolutePosition()

		local drawer = root:addChild("wimp/dropdown_pop", skin.skin_id_pop, nil, self)
		drawer.x = ax
		drawer.y = ay + self.h
		self.wid_drawer = drawer
		self["next"] = drawer
		drawer["prev"] = self
		drawer:writeSetting("show_icons", self.show_icons)
		drawer:setIconSetID(self.icon_set_id)

		for i, item in ipairs(self.MN_items) do
			local new_item = drawer:addItem(item.text, nil, item.icon_id, true)
			new_item.source_item = item
		end

		local wcWimp = context:getLua("shared/wc/wc_wimp")
		wcWimp.assignPopUp(self, drawer)

		drawer:setSelectionByIndex(self.MN_index)

		drawer:reshape()
		drawer:centerSelectedItem(true)

		wcPopUp.checkBlocking(drawer)

		drawer:tryTakeThimble2()
	end
end


function def:_closePopUpMenu(update_chosen)
	local wid_drawer = self.wid_drawer
	if wid_drawer and not wid_drawer._dead then
		self.wid_drawer:_closeSelf(update_chosen)
		self["next"] = false
	end
end


function def:_togglePopUpMenu(update_chosen)
	if self.wid_drawer then
		self:_closePopUpMenu(update_chosen)
	else
		self:_openPopUpMenu()
	end
end


function def:wid_popUpCleanup(reason_code)
	-- Prevent instantly creating the drawer again when clicking on the dropdown body (with the intention of closing it).
	if self.context.current_pressed == self then
		self.context.current_pressed = false
	end

	self.wid_drawer = false
end


--- Called in evt_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function def:wid_defaultKeyNav(key, scancode, isrepeat)
	local check_chosen = false
	local index_old = self.MN_index

	if scancode == "up" then
		self:movePrev(1, true, isrepeat)
		check_chosen = true

	elseif scancode == "down" then
		self:moveNext(1, true, isrepeat)
		check_chosen = true

	elseif scancode == "home" then
		self:moveFirst(true)
		check_chosen = true

	elseif scancode == "end" then
		self:moveLast(true)
		check_chosen = true

	elseif scancode == "pageup" then
		self:movePrev(self.MN_page_jump_size, true, false)
		check_chosen = true

	elseif scancode == "pagedown" then
		self:moveNext(self.MN_page_jump_size, true)
		check_chosen = true
	end

	if check_chosen then
		if index_old ~= self.MN_index then
			self:wid_chosenSelection(self.MN_index, self.MN_items[self.MN_index])
		end
		return true
	end
end


function def:evt_thimble1Release(inst)
	if self == inst then
		if self.wid_drawer then
			-- The pop-up menu should not exist if the dropdown body does not have thimble1.
			self:_closePopUpMenu(false)
			return true
		end
	end
end


function def:evt_destroy(inst)
	if self == inst then
		self:_closePopUpMenu(false)

		widShared.removeViewports(self, 5)
	end
end


function def:evt_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if not self.wid_drawer then
			local items = self.MN_items
			local old_index = self.MN_index
			local old_item = items[old_index]

			-- Space opens, but does not close the pop-up.
			if key == "space" then
				self:_openPopUpMenu()
				return true

			-- Enter toggles the pop-up, opening it here and closing it in the drawer.
			elseif key == "return" or key == "kpenter" then
				self:_openPopUpMenu()
				return true

			elseif self:wid_defaultKeyNav(key, scancode, isrepeat) then
				return true
			end
		end
	end
end


--function def:evt_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:evt_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)


function def:evt_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble1()
		end

		if button == 1 then
			-- Drawer is already opened: close it.
			if self.wid_drawer then
				self:_closePopUpMenu(false)
			-- Open it.
			else
				self:_openPopUpMenu()

				return true
			end
		end
	end
end


function def:evt_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	-- If the cursor overlaps the pop-up drawer while not overlapping the body,
	-- transfer context pressed state.
	local wid_drawer = self.wid_drawer
	if wid_drawer then
		local ax1, ay1 = self:getAbsolutePosition()
		local ax2, ay2 = wid_drawer:getAbsolutePosition()

		if not (mouse_x >= ax1 and mouse_x < ax1 + self.w and mouse_y >= ay1 and mouse_y < ay1 + self.h)
		and (mouse_x >= ax2 and mouse_x < ax2 + wid_drawer.w and mouse_y >= ay2 and mouse_y < ay2 + wid_drawer.h)
		then
			self.context:transferPressedState(wid_drawer)

			wid_drawer.press_busy = "menu-drag"
			wid_drawer:cacheUpdate(true)
		end
	end
end


function def:evt_pointerWheel(inst, x, y)
	if self == inst then
		-- Cycle menu options if the drawer is closed and this widget has top thimble focus.
		if not self.wid_drawer and self:hasTopThimble() then
			local check_chosen = false
			local index_old = self.MN_index

			if y > 0 then
				self:movePrev(y, true)
				check_chosen = true

			elseif y < 0 then
				self:moveNext(math.abs(y), true)
				check_chosen = true
			end

			if check_chosen then
				if index_old ~= self.MN_index then
					self:wid_chosenSelection(self.MN_index, self.MN_items[self.MN_index])
				end
				return true
			end
		end
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	slice = themeAssert.slice,
	slc_deco_button = themeAssert.slice,

	color_body = uiAssert.loveColorTuple,
	color_text = uiAssert.loveColorTuple,
	color_icon = uiAssert.loveColorTuple,
	color_highlight = uiAssert.loveColorTuple,

	deco_ox = uiAssert.integer,
	deco_oy = uiAssert.integer
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		-- settings
		icon_set_id = {uiAssert.types, "nil", "string"},
		show_icons = {uiAssert.types, "nil", "boolean"},
		-- /settings

		-- The SkinDef ID for pop-ups made by this widget.
		skin_id_pop = {uiAssert.type, "string"},

		box = themeAssert.box,
		font = themeAssert.font,

		-- Horizontal size of the decorative button.
		-- "auto": use Viewport #2's height.
		button_spacing = {uiAssert.numberGEOrOneOf, 0, "auto"},

		-- Placement of the decorative button.
		button_placement = {uiAssert.oneOf, "left", "right"},

		icon_side = {uiAssert.oneOf, "left", "right"},
		icon_spacing = {uiAssert.numberGE, 0},

		text_align = {uiAssert.oneOf, "left", "center", "right"},

		tq_deco_glyph = themeAssert.quad,

		res_idle = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "button_spacing")
		uiScale.fieldInteger(scale, skin, "icon_spacing")

		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "deco_ox")
			uiScale.fieldInteger(scale, res, "deco_oy")
		end

		_changeRes(scale, skin.res_idle)
		_changeRes(scale, skin.res_pressed)
		_changeRes(scale, skin.res_disabled)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		-- Update the icons of any existing items.
		for i, item in ipairs(self.MN_items) do
			item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id)
		end
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp2, vp3, vp4, vp5 = self.vp2, self.vp3, self.vp4, self.vp5
		local font = skin.font

		local res
		if self.enabled then
			res = (self.wid_drawer) and skin.res_pressed or skin.res_idle
		else
			res = skin.res_disabled
		end

		local rr, gg, bb, aa = love.graphics.getColor()
		love.graphics.push("all")

		-- Back panel body.
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(res.slice, 0, 0, self.w, self.h)

		-- Decorative button.
		love.graphics.setColor(rr, gg, bb, aa)
		uiGraphics.drawSlice(res.slc_deco_button, vp5.x, vp5.y, vp5.w, vp5.h)
		uiGraphics.quadShrinkOrCenterXYWH(skin.tq_deco_glyph, vp5.x + res.deco_ox, vp5.y + res.deco_oy, vp5.w, vp5.h)

		-- Crop item text + icon.
		uiGraphics.intersectScissor(
			ox + self.x + vp2.x,
			oy + self.y + vp2.y,
			vp2.w,
			vp2.h
		)

		-- Draw a highlight rectangle if this widget has the thimble and there is no drawer.
		if not self.wid_drawer and self.context.thimble1 == self then
			love.graphics.setColor(res.color_highlight)
			love.graphics.setScissor()
			love.graphics.rectangle("fill", vp2.x, vp2.y, vp2.w, vp2.h)
		end

		local chosen = self.MN_items[self.MN_index]
		if chosen then
			-- Chosen item icon.
			if self.show_icons then
				local tq_icon = chosen.tq_icon
				if tq_icon then
					love.graphics.setColor(res.color_icon)
					uiGraphics.quadShrinkOrCenterXYWH(tq_icon, vp4.x, vp4.y, vp4.w, vp4.h)
				end
			end

			-- Chosen item text.
			love.graphics.setFont(font)
			love.graphics.setColor(res.color_text)
			local xx = vp3.x + textUtil.getAlignmentOffset(chosen.text, font, skin.text_align, vp3.w)
			local yy = math.floor(0.5 + vp3.y + (vp3.h - font:getHeight()) / 2)
			love.graphics.print(chosen.text, xx, yy)
		end

		-- Debug
		--[[
		love.graphics.setScissor()
		love.graphics.print("self.wid_drawer: " .. tostring(self.wid_drawer), 288, 0)
		--]]

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
