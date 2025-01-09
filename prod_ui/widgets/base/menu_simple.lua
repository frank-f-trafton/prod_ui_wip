
--[[
	A simple menu widget with a minimal scrolling implementation.
	All menu items are the same size. Supports vertical (default) and horizontal layout modes.

	Menu items can be any data type. You can provide per-type render functions if so desired.

	For more flexible layouts, check out the standard menu widget (base/menu).
--]]


local context = select(1, ...)


local lgcMenu = context:getLua("shared/lgc_menu")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "menu_simple1",
}


widShared.scrollSetMethods(def)


-- XXX WIP
local function defaultRendererString(self, item, x, y, w, h)
	-- This also handles numbers, due to Lua coercing them into strings.
	love.graphics.print(item, x, y)
end



-- * Internal *


local function getPageJumpSize(self)
	local len = self.horizontal and self.w or self.h

	return math.max(1, math.floor(len / self.item_len) / 2)
end


local function getItemAtPoint(self, px, py)
	-- NOTES:
	-- * Does not check if the item is selectable.

	local menu = self.menu

	-- Empty list
	if #menu.items == 0 then
		return nil
	end

	-- Out of range: return nothing
	if px < 0 or px >= self.w or py < 0 or py >= self.h then
		return nil
	end

	local mouse_pos = self.horizontal and px or py

	return math.max(1, math.min(#menu.items, math.floor(mouse_pos / self.item_len) + self.scroll_i + 1))
end


local function clampScroll(self)
	local len = self.horizontal and self.w or self.h

	self.scroll_i = math.max(0, math.min(self.scroll_i, #self.menu.items - math.floor(len / self.item_len)))
end


-- * / Internal *


-- * Scroll helpers *


--- Get the number of items that can be displayed (not the current count)
function def:getMaxVisibleSlots()
	local len = self.horizontal and self.w or self.h

	return math.floor(len / self.item_len)
end


function def:scrollTo(i)
	self.scroll_i = i
	if self.scroll_clamp then
		clampScroll(self)
	end
end


function def:selectionInView()
	local menu = self.menu

	-- No selection: nothing to do.
	if menu.index == 0 then
		return

	-- Empty list: scroll to top
	elseif #menu.items == 0 then
		self:scrollTo(0)

	else
		local len = self.horizontal and self.w or self.h

		local max_vis = math.floor(len / self.item_len)

		-- Viewport is smaller than item length + padding*2: just scroll so that the current
		-- selection is at the beginning of the visible area.
		if max_vis*len < self.item_len + (self.scroll_i_pad * self.item_len) * 2 then
			self.scroll_i = menu.index - 1
			if self.scroll_clamp then
				clampScroll(self)
			end
		-- Normal circumstances
		else
			if menu.index < self.scroll_i + self.scroll_i_pad then
				self:scrollTo(menu.index - self.scroll_i_pad)
			end

			if menu.index > self.scroll_i + max_vis - self.scroll_i_pad then
				self:scrollTo(menu.index + self.scroll_i_pad - 1 - max_vis)
			end
		end
	end
end


-- * / Scroll helpers *


-- * Selection movement *


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast


-- * / Selection movement *


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true
		self.allow_focus_capture = true
		self.clip_scissor = true

		-- Changes orientation to left/right.
		self.horizontal = false

		-- Size of each item in the menu on the primary axis.
		self.item_len = 24 -- must be greater than zero

		-- Scrolling offset. Zero corresponds to the first visible item in the list.
		self.scroll_i = 0

		-- Begin scrolling the list when selector is within this number of items to the edge.
		-- To center the selection, ensure there are an odd number of items visible and set
		-- this to floor(n_vis/2) - 1. (Ex: 9 items -> padding of 4.)
		self.scroll_i_pad = 3 -- XXX I think there's an off-by-one error here. I want to rewrite this
		-- so that the number of visible item slots is specified explicitly, independent of the
		-- widget dimensions.

		-- Lateral padding for items. (Vertical: right + left padding. Horizontal: top + bottom padding.)
		self.item_pad = 16

		-- Show a non-interactive scrolling indication, pegged to the current selection.
		-- true: peg to current scroll offset (clamped even if scrolling itself is clamped).
		-- "selection": peg to current selection.
		self.show_scroll_ind = true

		-- When true, clamp scrolling to the first and last menu items.
		self.scroll_clamp = true

		-- XXX WIP: Assign a function here to serve as the default item renderer.
		-- Allows menus to contain primitive types like strings, which may reduce
		-- overhead in some use cases.
		-- self.item_render

		self.menu = self.menu or lgcMenu.new()

		self:skinSetRefs()
		self:skinInstall()
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		if self.horizontal and scancode == "left"
		or not self.horizontal and scancode == "up" then
			self:movePrev(1)

		elseif self.horizontal and scancode == "right"
		or not self.horizontal and scancode == "down" then
			self:moveNext(1)

		elseif scancode == "home" then
			self:moveFirst()

		elseif scancode == "end" then
			self:moveLast()

		elseif scancode == "pageup" then
			self:movePrev(getPageJumpSize(self))

		elseif scancode == "pagedown" then
			self:moveNext(getPageJumpSize(self))

		-- Debug
		elseif scancode == "insert" then
			table.insert(self.menu.items, math.max(1, self.menu.index), {text = "filler entry #" .. #self.menu.items + 1, selectable = true, type = "press_action"})
			self.menu:setSelectionStep(0)
			if self.scroll_clamp then
				clampScroll(self)
			end
			self:selectionInView()

		-- Debug
		elseif scancode == "delete" then
			table.remove(self.menu.items, self.menu.index)
			self.menu:setSelectionStep(0)
			if self.scroll_clamp then
				clampScroll(self)
			end
			self:selectionInView()
		end
	end
end


--function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
--function def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)


-- @param x Mouse X position, relative to widget top-left.
-- @param y Mouse Y position, relative to widget top-left.
function def:trySelectItemAtPoint(x, y)
	local i = getItemAtPoint(self, x, y)

	if i then
		local item = self.menu.items[i]
		if item and item.selectable then
			self.menu:setSelectedIndex(i)
			self:selectionInView()
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			if button <= 3 then
				self:tryTakeThimble1()
			end

			if button == 1 then
				local ax, ay = self:getAbsolutePosition()
				x = x - ax
				y = y - ay

				-- Check for click-able items.
				self:trySelectItemAtPoint(x, y)
			end
		end
	end
end


--function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		-- (Positive Y == rolling wheel upward.)

		self.menu:setSelectionStep(4 * -y, self.MN_wrap_selection)
		self:selectionInView()

		-- Block bubbling if event was handled.
		return true
	end
end


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
	if self == inst then
		-- ...
	end
end


-- TODO: uiCall_thimbleAction2()


--function def:uiCall_update(dt)
--function def:uiCall_reshape()
--function def:renderThimble(os_x, os_y)


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

			local body_len = self.horizontal and self.w or self.h

			local font = skin.font
			local font_h = font:getHeight()
			local sep_offset = math.floor(self.item_len / 2)

			local max_vis = math.floor(body_len / self.item_len)
			--print(body_len / self.item_len, math.floor(body_len / self.item_len))

			-- Back panel body
			love.graphics.setColor(skin.color_background)
			love.graphics.rectangle("fill", 0, 0, self.w, self.h)

			-- Don't draw menu contents outside of the widget bounding box.
			love.graphics.push("all")
			uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

			-- Draw selection glow, if applicable
			if menu.index > 0 then
				local is_active = self:hasAnyThimble()
				local col = is_active and skin.color_active_glow or skin.color_select_glow
				love.graphics.setColor(col)

				local sel_pos = (menu.index-1 - self.scroll_i) * self.item_len
				if self.horizontal then
					love.graphics.rectangle("fill", sel_pos + 0.5, 0.5, self.item_len, self.w)
				else
					love.graphics.rectangle("fill", 0.5, sel_pos + 0.5, self.w, self.item_len)
				end
			end

			-- Draw each menu item
			love.graphics.setColor(skin.color_item_text)
			love.graphics.setFont(font)


			local vis_item_bot = math.min(#menu.items, self.scroll_i + max_vis)
			local work_pos = 0

			--print("vis_item_bot", vis_item_bot)

			for i = self.scroll_i + 1, vis_item_bot do
				local item = menu.items[i]

				if item then
					local px = self.item_pad
					local py = work_pos
					local pw = self.w - self.item_pad
					local ph = work_pos

					if self.horizontal then
						px, py = py, px
						pw, ph = ph, pw
					end

					if item.type == "separator" then
						love.graphics.setLineWidth(1)
						if self.horizontal then
							love.graphics.line(px + sep_offset + 0.5, py + 0.5, px + sep_offset, py + ph + 0.5)
						else
							love.graphics.line(px + 0.5, py + sep_offset + 0.5, px + pw + 0.5, py + sep_offset)
						end
					else
						if self.horizontal then
							love.graphics.print(item.text, work_pos, self.item_pad)
						else
							love.graphics.print(item.text, self.item_pad, work_pos + math.floor(self.item_len/2 - font_h/2))
						end
					end
				end
				work_pos = work_pos + self.item_len
			end

			love.graphics.pop()

			-- Outline for the back panel
			love.graphics.setColor(skin.color_outline)
			love.graphics.setLineWidth(skin.outline_width)
			love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)

			-- Draw a scrolling indicator, if applicable.
			-- XXX maybe just an up-arrow and down-arrow would be better in some cases.
			if self.show_scroll_ind then
				local circ_r = 6 -- XXX style
				local shortened = #menu.items - max_vis
				if shortened > 0 then
					local circ_pos = 0

					-- Peg to current scroll offset
					if self.show_scroll_ind == true then
						circ_pos = math.floor(circ_r + (self.scroll_i) / shortened * (body_len - circ_r*2))
						-- Clamp the indicator, in case scrolling itself is not clamped.
						-- It looks bad, but it's better than the indicator flying off the widget or being scissored out.
						circ_pos = math.max(circ_r, math.min(circ_pos, body_len - circ_r*2))

					-- Peg to current selection
					elseif self.show_scroll_ind == "selection" then
						circ_pos = math.floor(circ_r + ((menu.index-1) / math.max(1, #menu.items-1) * (body_len - circ_r*2)))
					end

					love.graphics.setColor(skin.color_scroll_ind)
					if self.horizontal then
						love.graphics.circle("fill", circ_pos, self.h - circ_r, circ_r)
					else
						love.graphics.circle("fill", self.w - circ_r, circ_pos, circ_r)
					end
				end
			end
		end,
	},
}


return def
