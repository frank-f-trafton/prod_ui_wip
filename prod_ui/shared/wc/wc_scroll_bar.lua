local context = select(1, ...)

--[[
	Common scroll bar state and functions.

	Notes:

	* This doesn't handle the actual scrolling action of widgets. For that, please see 'core/wid_shared.lua'
	  for shared functions. The default scroll bar drawing function is in shared/impl_scroll_bar1.lua.

	* Most functions here assume that the client widget has the following methods affixed:

	- self:scrollH()         -> widShared.scrollH
	- self:scrollDeltaH()    -> widShared.scrollDeltaH
	- self:scrollV()         -> widShared.scrollV
	- self:scrollDeltaV()    -> widShared.scrollDeltaV
--]]


local wcScrollBar = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")


local _mt_bar = {}
_mt_bar.__index = _mt_bar


-- A default scroll bar style table, used in cases where a style table is not provided.
wcScrollBar.default_scr_style = {
	has_buttons = true,
	trough_enabled = true,
	thumb_enabled = true,

	bar_size = 16,
	button_size = 16,
	thumb_size_min = 16,
	thumb_size_max = 2^16,

	v_near_side = true, -- true == left, false == right
	v_auto_hide = false,

	v_button1_enabled = true,
	v_button1_mode = "pend-cont",
	v_button2_enabled = true,
	v_button2_mode = "pend-cont",

	h_near_side = true, -- true == bottom, false == top
	h_auto_hide = false,

	h_button1_enabled = true,
	h_button1_mode = "pend-cont",
	h_button2_enabled = true,
	h_button2_mode = "pend-cont",
}


-- Widgets may implement other press_busy codes (ie for dragging the mouse cursor through a menu).
wcScrollBar.press_busy_codes = {
	["v"] = true, -- vertical thumb (or trough->thumb)
	["v1-pend"] = true, -- vertical button-less, pending repeat action
	["v1-cont"] = true, -- vertical button-less, continuous scroll in update()
	["v2-pend"] = true, -- vertical button-more, pending repeat action
	["v2-cont"] = true, -- vertical button-more, continuous scroll in update()

	["h"] = true, -- horizontal thumb (or trough->thumb)
	["h1-cont"] = true, -- horizontal button-less, pending repeat action
	["h1-pend"] = true, -- horizontal button-less, continuous scrollin update()
	["h2-cont"] = true, -- horizontal button-more, pending repeat action
	["h2-pend"] = true, -- horizontal button-more, continuous scrollin update()
}


--[[
	Scroll button modes:
	* "pend-pend": Initial fixed step, followed by repeated fixed steps
	* "pend-cont": Initial fixed step, followed by continuous scrolling
	* "cont": Continuous scrolling

	"cont" has two shortcomings:
	1) Mouse clicks and releases that occur within the same frame (ie low FPS) will not scroll.

	2) It won't interact well with clients that restrict scroll offsets to a low granularity. Given a large
	   enough step, the scroll buttons may not do anything.
--]]


local code_map_v = {}
code_map_v["pend-pend"] = {}
code_map_v["pend-pend"]["b1"] = "v1-pend"
code_map_v["pend-pend"]["b2"] = "v2-pend"

code_map_v["pend-cont"] = {}
code_map_v["pend-cont"]["b1"] = "v1-pend"
code_map_v["pend-cont"]["b2"] = "v2-pend"

code_map_v["cont"] = {}
code_map_v["cont"]["b1"] = "v1-cont"
code_map_v["cont"]["b2"] = "v2-cont"


local code_map_h = {}
code_map_h["pend-pend"] = {}
code_map_h["pend-pend"]["b1"] = "h1-pend"
code_map_h["pend-pend"]["b2"] = "h2-pend"

code_map_h["pend-cont"] = {}
code_map_h["pend-cont"]["b1"] = "h1-pend"
code_map_h["pend-cont"]["b2"] = "h2-pend"

code_map_h["cont"] = {}
code_map_h["cont"]["b1"] = "h1-cont"
code_map_h["cont"]["b2"] = "h2-cont"


--- Makes a scroll bar.
-- @param horizontal When true, the scroll bar is aligned horizontally. When false, it's vertical.
-- @param scr_style The scroll bar style table (options and measurements). If not provided, a default will be used.
-- @param [bar] An existing scroll bar table to update.
-- @return The scroll bar table.
function wcScrollBar.newBar(horizontal, scr_style, bar)
	-- XXX Assertions
	if bar and getmetatable(bar) ~= _mt_bar then
		error("invalid or corrupt scroll bar")
	end

	horizontal = not not horizontal
	scr_style = scr_style or wcScrollBar.default_scr_style

	local self = bar or setmetatable({}, _mt_bar)

	self.active = true
	self.horizontal = horizontal

	self.bar_size = scr_style.bar_size
	self.button_size = scr_style.button_size
	self.thumb_size_min = scr_style.thumb_size_min
	self.thumb_size_max = scr_style.thumb_size_max

	-- Broad scroll bar shape and position within the client widget.
	self.x = 0
	self.y = 0
	self.w = 1
	self.h = 1

	-- Trough shape and position (relative to the XYWH above).
	self.tr = scr_style.trough_enabled
	self.tr_x = 0
	self.tr_y = 0
	self.tr_w = 1
	self.tr_h = 1

	-- Is true when there is space to render the trough.
	self.trough_valid = false

	-- Thumb.
	self.th = scr_style.thumb_enabled
	self.th_x = 0
	self.th_y = 0
	self.th_w = 1
	self.th_h = 1

	-- Is false when the thumb is too big for the trough or when the document is >= the viewport.
	-- Click tests and rendering should only consider the thumb when this is true.
	self.thumb_valid = false

	if scr_style.has_buttons then
		-- Button 1 is left or up. Button 2 is right or down.

		self.b1_valid = false

		self.b1_x = 0
		self.b1_y = 0
		self.b1_w = 1
		self.b1_h = 1

		self.b2_valid = false

		self.b2_x = 0
		self.b2_y = 0
		self.b2_w = 1
		self.b2_h = 1

		if horizontal then
			self.b1 = scr_style.h_button1_enabled
			self.b1_mode = scr_style.h_button1_mode
			self.b2 = scr_style.h_button2_enabled
			self.b2_mode = scr_style.h_button2_mode

		else
			self.b1 = scr_style.v_button1_enabled
			self.b1_mode = scr_style.v_button1_mode
			self.b2 = scr_style.v_button2_enabled
			self.b2_mode = scr_style.v_button2_mode
		end
	end

	-- Internal registers used to position and shape the thumb within the trough.
	-- A max of 0 is shorthand for the thumb not currently being usable, either due to
	-- the document being 100% in view, or the smallest allowed thumb exceeding the trough
	-- length.
	self.pos = 0 -- First part of the viewport in the scrollable document.
	self.len = 0 -- Length of the viewport.
	self.max = 0 -- Length of the entire document.

	-- Offset of mouse pointer when clicking+dragging the thumb.
	self.drag_offset = 0

	-- Controls where the scroll bar appears (which side of the widget).
	self.near_side = horizontal and scr_style.h_near_side or scr_style.v_near_side

	-- When true, the scroll bar is hidden when the viewport is large enough to show the entire document.
	self.auto_hide = horizontal and scr_style.h_auto_hide or scr_style.v_auto_hide

	-- Hover and press states:
	self.hover = false -- false, "trough", "thumb", "b1", "b2"
	self.press = false -- false, "trough", "thumb", "b1", "b2"
	-- (press == "trough" is typically converted to press == "thumb".)

	return self
end


-- * Scroll bar methods *


function _mt_bar:testPoint(px, py)
	-- Broad check
	if px >= self.x and px < self.x + self.w and py >= self.y and py < self.y + self.h then

		-- Check buttons ('more' gets priority over 'less'), then thumb, then trough.
		if self.b2 and self.b2_valid
		and px >= self.x + self.b2_x and px < self.x + self.b2_x + self.b2_w
		and py >= self.y + self.b2_y and py < self.y + self.b2_y + self.b2_h
		then
			return "b2"

		elseif self.b1 and self.b1_valid
		and px >= self.x + self.b1_x and px < self.x + self.b1_x + self.b1_w
		and py >= self.y + self.b1_y and py < self.y + self.b1_y + self.b1_h
		then
			return "b1"

		elseif self.th and self.thumb_valid
		and px >= self.x + self.th_x and px < self.x + self.th_x + self.th_w
		and py >= self.y + self.th_y and py < self.y + self.th_y + self.th_h
		then
			return "thumb"

		elseif self.tr and self.trough_valid
		and px >= self.x + self.tr_x and px < self.x + self.tr_x + self.tr_w
		and py >= self.y + self.tr_y and py < self.y + self.tr_y + self.tr_h
		then
			return "trough"
		end
	end

	return false
end



local function updateShapesH(self)
	self.trough_valid = false
	self.thumb_valid = false

	-- Special case: Compress buttons if they are at least as long as the scroll bar shape.
	local button_check = (self.b1 and self.button_size or 0) + (self.b2 and self.button_size or 0)
	if button_check >= self.w then
		local shortened_length = math.floor(0.5 + self.w/2)
		if self.b1 then
			self.b1_x = 0
			self.b1_y = 0
			self.b1_w = shortened_length
			self.b1_h = self.h
		end

		if self.b2 then
			self.b2_x = self.w - shortened_length
			self.b2_y = 0
			self.b2_w = shortened_length
			self.b2_h = self.h
		end
	-- Normal positioning.
	else
		local measure = 0

		-- Button 1
		if self.b1 then
			self.b1_x = 0
			self.b1_y = 0
			self.b1_w = self.button_size
			self.b1_h = self.h

			measure = measure + self.button_size
		end

		-- Trough and thumb
		if self.tr then
			self.tr_x = measure
			self.tr_y = 0
			self.tr_w = self.w - measure
			if self.b2 then
				self.tr_w = self.tr_w - self.button_size
			end
			self.tr_h = self.h

			measure = measure + self.tr_w

			self.trough_valid = true

			self:updateThumb()
		end

		-- Button 2
		if self.b2 then
			self.b2_x = measure
			self.b2_y = 0
			self.b2_w = self.button_size
			self.b2_h = self.h
		end
	end

	self.b1_valid = false
	if self.len < self.max and self.b1 and self.b1_w > 0 then
		self.b1_valid = true
	end
	self.b2_valid = false
	if self.len < self.max and self.b2 and self.b2_w > 0 then
		self.b2_valid = true
	end
end


local function updateShapesV(self)
	self.trough_valid = false
	self.thumb_valid = false

	-- Special case: Compress buttons if they are at least as long as the scroll bar shape.
	local button_check = (self.b1 and self.button_size or 0) + (self.b2 and self.button_size or 0)
	if button_check >= self.h then
		local shortened_length = math.floor(0.5 + self.h/2)
		if self.b1 then
			self.b1_x = 0
			self.b1_y = 0
			self.b1_w = self.w
			self.b1_h = shortened_length
		end

		if self.b2 then
			self.b2_x = 0
			self.b2_y = self.h - shortened_length
			self.b2_w = self.w
			self.b2_h = shortened_length
		end
	-- Normal positioning.
	else
		local measure = 0

		-- Button 1
		if self.b1 then
			self.b1_x = 0
			self.b1_y = 0
			self.b1_w = self.w
			self.b1_h = self.button_size

			measure = measure + self.button_size
		end

		-- Trough and thumb
		if self.tr then
			self.tr_x = 0
			self.tr_y = measure
			self.tr_w = self.w
			self.tr_h = self.h - measure
			if self.b2 then
				self.tr_h = self.tr_h - self.button_size
			end

			measure = measure + self.tr_h

			self.trough_valid = true

			self:updateThumb()
		end

		-- Button 2
		if self.b2 then
			self.b2_x = 0
			self.b2_y = measure
			self.b2_w = self.w
			self.b2_h = self.button_size
		end
	end

	self.b1_valid = false
	if self.len < self.max and self.b1 and self.b1_h > 0 then
		self.b1_valid = true
	end
	self.b2_valid = false
	if self.len < self.max and self.b2 and self.b2_h > 0 then
		self.b2_valid = true
	end
end


--- Conditionally updates the boxes of buttons, trough and thumb based on the current scroll bar shape.
function _mt_bar:updateShapes()
	if self.horizontal then
		updateShapesH(self)
	else
		updateShapesV(self)
	end
end


--- Update the thumb size and position in a scroll bar.
function _mt_bar:updateThumb()
	-- Thumb measurement requires:
	-- * The trough to be active
	-- * The 'max' register to be greater than zero (shorthand for invalid state)

	self.thumb_valid = false

	if self.th and self.tr and self.trough_valid and self.max > 0 then
		if self.horizontal then
			self.th_w = wcScrollBar.getThumbLength(self.len, self.max, self.tr_w, self.thumb_size_min, self.thumb_size_max)
			self.th_x = self.tr_x + wcScrollBar.getThumbPosition(self.len, self.pos, self.max, self.tr_w, self.th_w)
			self.th_h = self.tr_h
			self.th_y = self.tr_y

			if self.max > 0 and self.th_w < self.tr_w then
				self.thumb_valid = true
			end
		-- Vertical
		else
			self.th_w = self.w
			self.th_x = self.tr_x
			self.th_h = wcScrollBar.getThumbLength(self.len, self.max, self.tr_h, self.thumb_size_min, self.thumb_size_max)
			self.th_y = self.tr_y + wcScrollBar.getThumbPosition(self.len, self.pos, self.max, self.tr_h, self.th_h)

			if self.max > 0 and self.th_h < self.tr_h then
				self.thumb_valid = true
			end
		end
	end
end


--- Method to make, remake or remove embedded scroll bars.
-- @param self The widget to modify.
-- @param hori Horizontal bar (self.scr_h)
-- @param vert Vertical bar (self.scr_v)
function wcScrollBar.setScrollBars(self, hori, vert)
	-- Scroll style priority: 1) Style in self, 2) Style in skin, 3) The application default style.
	local scr_style = self.scr_style or (self.skin and self.skin.scr_style) or nil

	self.scr_h = (hori) and wcScrollBar.newBar(true, scr_style, self.scr_h) or nil
	self.scr_v = (vert) and wcScrollBar.newBar(false, scr_style, self.scr_v) or nil

	-- If there was a state change, reshape the widget after calling.

	return self
end


--- Logic for the client's uiCall_pointerPress(). Detects clicks on embedded scroll bar components and initiates
-- the dragging state. It modifies 'self.press_busy', and state fields within the scroll bar tables.
-- @param self The widget to test and modify.
-- @param x Mouse X position in UI space.
-- @param y Mouse Y position in UI space.
-- @param fixed_step How much to scroll if a button in fixed-step mode is activated.
-- @return True if the scroll is considered activated by the click.
function wcScrollBar.widgetScrollPress(self, x, y, fixed_step)
	-- Don't override existing 'busy' state.
	if self.press_busy then
		return
	end

	-- Check for clicking on scroll bars, and initiate dragging states.
	local ax, ay = self:getAbsolutePosition()
	x = x - ax
	y = y - ay

	-- Give vertical bar priority in the event of overlap.
	local scr_v = self.scr_v

	if scr_v and scr_v.active then
		local test_code = scr_v:testPoint(x, y)

		if test_code then
			scr_v.hover = false
			scr_v.press = test_code

			if test_code == "thumb" then
				self.press_busy = "v"
				scr_v.drag_offset = math.floor(y - scr_v.th_y)
				--print("NEW DRAG OFFSET (A)", scr_v.drag_offset)
				return true

			elseif test_code == "b1" then
				self.press_busy = code_map_v[scr_v.b1_mode][test_code]
				if self.press_busy == "v1-pend" then
					self:scrollDeltaV(-fixed_step)
				end
				return true

			elseif test_code == "b2" then
				self.press_busy = code_map_v[scr_v.b2_mode][test_code]
				if self.press_busy == "v2-pend" then
					self:scrollDeltaV(fixed_step)
				end
				return true

			-- Trough
			elseif scr_v.trough_valid then
				-- hand over control to the thumb, but confirm it exists and is validated first.
				if scr_v.th and scr_v.thumb_valid then
					scr_v.press = "thumb"
					self.press_busy = "v"
					scr_v.drag_offset = math.floor(self.vp2.y + scr_v.th_h / 2)
					--print("NEW DRAG OFFSET (B)", scr_v.drag_offset)
				end

				-- Return positive regardless, to help the client widget with thimble handling.
				return true
			end
		end
	end

	local scr_h = self.scr_h

	if not self.press_busy and scr_h and scr_h.active then
		local test_code = scr_h:testPoint(x, y)
		if test_code then
			scr_h.hover = false
			scr_h.press = test_code

			if test_code == "thumb" then
				self.press_busy = "h"
				scr_h.drag_offset = math.floor(x - scr_h.th_x)
				return true

			elseif test_code == "b1" then
				--self.press_busy = "h1"
				self.press_busy = code_map_h[scr_h.b1_mode][test_code]
				if self.press_busy == "h1-pend" then
					self:scrollDeltaH(-fixed_step)
				end
				return true

			elseif test_code == "b2" then
				--self.press_busy = "h2"
				self.press_busy = code_map_h[scr_h.b2_mode][test_code]
				if self.press_busy == "h2-pend" then
					self:scrollDeltaH(fixed_step)
				end
				return true

			-- Trough
			elseif scr_h.trough_valid then
				-- hand over control to the thumb, but confirm it exists and is validated first.
				if scr_h.th and scr_h.thumb_valid then
					scr_h.press = "thumb"
					self.press_busy = "h"
					scr_h.drag_offset = math.floor(self.vp2.x + scr_h.th_w / 2)
				end

				-- Return positive regardless, to help the client widget with thimble handling.
				return true
			end
		end
	end
end


--- Logic for the client's uiCall_pointerPressRepeat(), which implements repeated 'pend' button motions.
function wcScrollBar.widgetScrollPressRepeat(self, x, y, fixed_step)
	local scr_h = self.scr_h
	local scr_v = self.scr_v

	local busy_code = self.press_busy

	if scr_v and scr_v.active then
		if busy_code == "v1-pend" then
			if scr_v.b1 then
				if scr_v.b1_mode == "pend-cont" then
					self.press_busy = "v1-cont"
				else
					self:scrollDeltaV(-fixed_step)
				end
			end

		elseif busy_code == "v2-pend" then
			if scr_v.b2 then
				if scr_v.b2_mode == "pend-cont" then
					self.press_busy = "v2-cont"
				else
					self:scrollDeltaV(fixed_step)
				end
			end
		end
	end

	if scr_h and scr_h.active then
		if busy_code == "h1-pend" then
			if scr_h.b1 then
				if scr_h.b1_mode == "pend-cont" then
					self.press_busy = "h1-cont"
				else
					self:scrollDeltaH(-fixed_step)
				end
			end

		elseif busy_code == "h2-pend" then
			if scr_h.b2 then
				if scr_h.b2_mode == "pend-cont" then
					self.press_busy = "h2-cont"
				else
					self:scrollDeltaH(fixed_step)
				end
			end
		end
	end
end


function wcScrollBar.widgetProcessHover(self, mx, my)
	local skip = false

	local scr_v = self.scr_v
	if scr_v then
		scr_v.hover = scr_v:testPoint(mx, my)

		if scr_v.hover then
			skip = true
		end
	end

	local scr_h = self.scr_h
	if not skip and scr_h then
		scr_h.hover = scr_h:testPoint(mx, my)
	end
end


--- Logic for 'uiCall_pointerHoverOff()', which just turns off the hover state.
-- @param self The client widget.
function wcScrollBar.widgetClearHover(self)
	local scr_h = self.scr_h
	if scr_h then
		scr_h.hover = false
	end

	local scr_v = self.scr_v
	if scr_v then
		scr_v.hover = false
	end
end


--- Logic for 'uiCall_pointerUnpress()', which just turns off the press state.
-- @param self The client widget.
function wcScrollBar.widgetClearPress(self)
	local scr_h = self.scr_h
	if scr_h then
		scr_h.press = false
	end

	local scr_v = self.scr_v
	if scr_v then
		scr_v.press = false
	end
end


--- Logic for 'uiCall_update()' that controls scrolling while the mouse presses and moves. Some methods and
--  variables for handling scrolling must be present in the widget for this to work.
-- @param self The client widget.
-- @param mx Mouse X, relative to widget top-left.
-- @param my Mouse Y, relative to widget top-left.
-- @param button_step If holding a less/more button, how far it should scroll on this frame.
-- @return true if an action was taken, false if not.
function wcScrollBar.widgetDragLogic(self, mx, my, button_step)
	local mode = self.press_busy

	if mode == "v" then
		local scr_v = self.scr_v
		if scr_v and scr_v.active then
			local scroll_y = wcScrollBar.getDocumentPosition(self.doc_h, scr_v.tr_h, my - scr_v.tr_y - scr_v.drag_offset, scr_v.th_h, self.vp.h)

			self:scrollV(scroll_y, true)
			return true
		end

	elseif mode == "h" then
		local scr_h = self.scr_h
		if scr_h and scr_h.active then
			local scroll_x = wcScrollBar.getDocumentPosition(self.doc_w, scr_h.tr_w, mx - scr_h.tr_x - scr_h.drag_offset, scr_h.th_w, self.vp.w)

			self:scrollH(scroll_x, true)
			return true
		end

	elseif mode == "v1-cont" then
		local scr_v = self.scr_v
		if scr_v and scr_v.active and scr_v.b1 then
			self:scrollDeltaV(-button_step)
			return true
		end

	elseif mode == "v2-cont" then
		local scr_v = self.scr_v
		if scr_v and scr_v.active and scr_v.b2 then
			self:scrollDeltaV(button_step)
			return true
		end

	elseif mode == "h1-cont" then
		local scr_h = self.scr_h
		if scr_h and scr_h.active and scr_h.b1 then
			self:scrollDeltaH(-button_step)
			return true
		end

	elseif mode == "h2-cont" then
		local scr_h = self.scr_h
		if scr_h and scr_h.active and scr_h.b2 then
			self:scrollDeltaH(button_step)
			return true
		end
	end
end


--- Logic for the client that positions scroll bars and implements auto-hide. The client's viewport #1 needs to be
--  set to a default size and position, from which the scroll bars will carve out space. Scroll bar shapes must then
--  be updated.
-- @param self The widget to modify.
function wcScrollBar.arrangeScrollBars(self)
	local vp = self.vp
	local scr_h = self.scr_h
	local scr_v = self.scr_v

	-- Determine auto-hide flags for scroll bars.
	-- as*1 -> Content exceeds view on this axis.
	-- as*2 -> Content exceeds reduced view (if the bar on the other axis would be present)
	local asv1, asv2, ash1, ash2

	if scr_v and scr_v.auto_hide then
		asv1 = (self.doc_h > vp.h) and true or false
		asv2 = (self.doc_h > vp.h - scr_v.bar_size) and true or false
	end
	if scr_h and scr_h.auto_hide then
		ash1 = (self.doc_w > vp.w) and true or false
		ash2 = (self.doc_w > vp.w - scr_h.bar_size) and true or false
	end

	if scr_v then
		if scr_v.auto_hide then
			if asv1 or (ash1 and asv2) then
				scr_v.active = true
			else
				scr_v.active = false
			end
		end

		scr_v.w = scr_v.bar_size
		scr_v.h = vp.h

		scr_v.x = scr_v.near_side and vp.x + vp.w - scr_v.w or vp.x
		scr_v.y = vp.y

		-- If active, reduce viewport
		if scr_v.active then
			vp.w = vp.w - scr_v.w
			if not scr_v.near_side then
				vp.x = vp.x + scr_v.w
			end
		end
	end

	if scr_h then
		if scr_h.auto_hide then
			if ash1 or (asv1 and ash2) then
				scr_h.active = true
			else
				scr_h.active = false
			end
		end

		scr_h.w = vp.w
		scr_h.h = scr_h.bar_size

		scr_h.x = vp.x
		scr_h.y = scr_h.near_side and vp.y + vp.h - scr_h.h or vp.y

		-- If active, reduce viewport
		if scr_h.active then
			vp.h = vp.h - scr_h.h
			if not scr_h.near_side then
				vp.y = vp.y + scr_h.h
			end
		end
	end

	-- Make some adjustments when both scroll bars are active.
	if scr_h and scr_h.active and scr_v and scr_v.active then
		scr_v.h = scr_v.h - scr_h.h
		if not scr_h.near_side then
			scr_v.y = scr_v.y + scr_h.h
		end
		-- (The horizontal bar should already be handled).

		--[[
		This leaves a small, non-functional rectangle in the corner where the two scroll bars touch.
		You can put a resize sensor here or another kind of control button. The hover clipping should
		prevent clicking through to child widgets in the content container.
		--]]
	end
end


--- Sets a scroll bar's internal registers: Unworkable numbers cause all values to be set to zero, which is a shorthand
-- for the thumb not being in a valid state.
-- @param scr The scroll bar table.
-- @param pos The first bit of the visible viewport.
-- @param len The length of the viewport on the scrolling axis.
-- @param max The document length, where the upper bound of pos is max - len.
function wcScrollBar.updateRegisters(scr, pos, len, max)
	-- Assertions -- XXX test
	uiAssert.type(2, pos, "number")
	uiAssert.type(3, len, "number")
	uiAssert.type(4, max, "number")

	-- This needs to happen after viewport + content resizing.
	if max <= 0 or pos + len > max then
		scr.pos = 0
		scr.len = 0
		scr.max = 0
	else
		scr.pos = pos
		scr.len = len
		scr.max = max
	end
end


--- Logic that updates scroll bar component shapes.
function wcScrollBar.updateScrollBarShapes(self)
	local scr_h, scr_v = self.scr_h, self.scr_v
	if scr_h then
		scr_h:updateShapes()
	end
	if scr_v then
		scr_v:updateShapes()
	end
end


--- Updates a widget's built-in scroll registers.
function wcScrollBar.updateScrollState(self)
	local scr_h, scr_v = self.scr_h, self.scr_v

	if scr_v then
		local vp = self.vp
		wcScrollBar.updateRegisters(scr_v, math.floor(0.5 + vp.y + self.scr_y), vp.h, self.doc_h)
	end
	if scr_h then
		local vp = self.vp
		wcScrollBar.updateRegisters(scr_h, math.floor(0.5 + vp.x + self.scr_x), vp.w, self.doc_w)
	end
end


-- * Common scroll bar render methods *


function wcScrollBar.drawScrollBarsHV(self, data_scroll)
	local scr_h = self.scr_h
	local scr_v = self.scr_v

	if scr_h and scr_h.active then
		self.impl_scroll_bar.draw(data_scroll, self.scr_h, 0, 0)
	end
	if scr_v and scr_v.active then
		self.impl_scroll_bar.draw(data_scroll, self.scr_v, 0, 0)
	end
end


function wcScrollBar.drawScrollBarsH(self, data_scroll)
	local scr_h = self.scr_h

	if scr_h and scr_h.active then
		self.impl_scroll_bar.draw(data_scroll, self.scr_h, 0, 0)
	end
end


function wcScrollBar.drawScrollBarsV(self, data_scroll)
	local scr_v = self.scr_v

	if scr_v and scr_v.active then
		self.impl_scroll_bar.draw(data_scroll, self.scr_v, 0, 0)
	end
end


-- * Standalone scroll bar calculations *


--[[
Terminology:

Thumb: the movable block that shows where the viewport is located within the document. On systems with mouse cursors,
you can typically (though not always) click and drag the thumb to scroll the viewport. There is usually a minimum
thumb size to ensure that it's easy to see and click, and in some games, it's always the same size. Therefore, don't
count on this being an accurate indication of the document size.

Trough: the area in which the thumb can be moved. For these functions, this excludes any additional buttons on the far
edges.

Document: An axis-aligned rectangle (format: XYWH) that represents the scrollable area, not including margins.
--]]


--- Gets the length of the scroll bar thumb.
-- @param viewport_len Length of the viewport.
-- @param doc_len Length of the scrollable document area. Must be greater than zero.
-- @param trough_len Length of the scroll bar trough.
-- @param thumb_min Minimum permitted thumb size.
-- @param thumb_max Maximum permitted thumb size.
function wcScrollBar.getThumbLength(viewport_len, doc_len, trough_len, thumb_min, thumb_max)
	return math.max(thumb_min, math.min(trough_len, math.min(thumb_max, math.floor(viewport_len / doc_len * trough_len))))
end


--- Gets the document scroll position from the thumb position (or any arbitrary location) within the trough, clamped from 0 to trough length minus thumb length. (If thumb length isn't applicable, pass in zero.)
-- @param doc_len Length of the document's scrollable area.
-- @param trough_len Length of the scroll bar trough.
-- @param pos Position of the thumb (or other arbitrary) position within the trough.
-- @param thumb_len Length of the scroll bar thumb.
-- @param viewport_len Length of the visible content viewport.
-- @return Floored and clamped scroll position in the document that corresponds to this position in the trough.
function wcScrollBar.getDocumentPosition(doc_len, trough_len, pos, thumb_len, viewport_len)
	local doc_shortened = doc_len - viewport_len
	local scroll_shortened = trough_len - thumb_len

	if scroll_shortened <= 0 then -- avoid div/0
		return 0
	end

	return math.max(0, math.min(doc_shortened, math.floor(pos / scroll_shortened * doc_shortened)))
end


--- Gets the scroll bar thumb position from the current scroll offset within the document.
-- @param scroll_pos Scroll offset of the viewport (left or top side) within the document, in the range of 0 to doc_len - thumb_len.
function wcScrollBar.getThumbPosition(viewport_len, scroll_pos, doc_len, trough_len, thumb_len)
	local doc_shortened = doc_len - viewport_len
	local scroll_shortened = trough_len - thumb_len

	if doc_shortened <= 0 then -- avoid div/0
		return 0
	end

	return math.floor(math.max(0, math.min(scroll_shortened, 0.5 + scroll_pos / doc_shortened * scroll_shortened)))
end


-- * Debug *


--- Debug-render code for built-in scroll bars. It assumes that (x0,y0) in the transformation state is the widget's
--  top-left point.
-- @param self The client widget.
function wcScrollBar.debugRender(self)
	local scr_h, scr_v = self.scr_h, self.scr_v

	if scr_h and scr_h.active then
		if scr_h.tr then
			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.rectangle("fill", scr_h.x + scr_h.tr_x, scr_h.y + scr_h.tr_y, scr_h.tr_w, scr_h.tr_h)
		end
		if scr_h.th then
			love.graphics.setColor(1, 0, 0, 0.5)
			love.graphics.rectangle("fill", scr_h.x + scr_h.th_x, scr_h.y + scr_h.th_y, scr_h.th_w, scr_h.th_h)
		end
		if scr_h.b1 then
			love.graphics.setColor(0, 1, 0, 0.5)
			love.graphics.rectangle("fill", scr_h.x + scr_h.b1_x, scr_h.y + scr_h.b1_y, scr_h.b1_w, scr_h.b1_h)
		end
		if scr_h.b2 then
			love.graphics.setColor(0, 0, 1, 0.5)
			love.graphics.rectangle("fill", scr_h.x + scr_h.b2_x, scr_h.y + scr_h.b2_y, scr_h.b2_w, scr_h.b2_h)
		end
	end

	if scr_v and scr_v.active then
		if scr_v.tr then
			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.rectangle("fill", scr_v.x + scr_v.tr_x, scr_v.y + scr_v.tr_y, scr_v.tr_w, scr_v.tr_h)
		end
		if scr_v.th then
			love.graphics.setColor(1, 0, 0, 0.5)
			love.graphics.rectangle("fill", scr_v.x + scr_v.th_x, scr_v.y + scr_v.th_y, scr_v.th_w, scr_v.th_h)
		end
		if scr_v.b1 then
			love.graphics.setColor(0, 1, 0, 0.5)
			love.graphics.rectangle("fill", scr_v.x + scr_v.b1_x, scr_v.y + scr_v.b1_y, scr_v.b1_w, scr_v.b1_h)
		end
		if scr_v.b2 then
			love.graphics.setColor(0, 0, 1, 0.5)
			love.graphics.rectangle("fill", scr_v.x + scr_v.b2_x, scr_v.y + scr_v.b2_y, scr_v.b2_w, scr_v.b2_h)
		end
	end
end


return wcScrollBar
