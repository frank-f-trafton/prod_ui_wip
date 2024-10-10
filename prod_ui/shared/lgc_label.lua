-- To load: local lib = context:getLua("shared/lib")

--[[
Shared code for handling "label text" in widgets.


Label modes:
"single": A single line of text.

"single-ul": A single line of text with an optional underline. The text to be underlined is marked
	by two underscores, like _this_.

"multi": Multi-line text.


Required skin fields:

skin.tq_px: A textured quad of a single white pixel. Used for drawing the underline.

skin.label_align_h: Horizontal text alignment.
skin.label_align_v: Vertical text alignment.

skin.label_style: The label style table, usually taken from the theme table.
skin.label_style.font: The font to use when measuring and rendering text.
skin.label_style.ul_color: Underline color table, or false to use the current text color.
skin.label_style.ul_h: Underline height (thickness).
skin.label_style.ul_oy: Underline Y offset from the top of text.


Required widget fields:

Viewport #1: vp_x, vp_y, vp_w, vp_h

--]]


local context = select(1, ...)


local lgcLabel = {}


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


local modes = {["single"] = true, ["single-ul"] = true, ["multi"] = true}


local function _assertLabelMode(n, mode)

	if not modes[mode] then
		error("argument #" .. n .. ": invalid label mode: " .. tostring(mode), 2)
	end
end


local function multiLineWrap(self, font)

	local _, lines = font:getWrap(self.label, self.vp_w)
	self.label_h = math.floor(0.5 + font:getHeight() * font:getLineHeight() * #lines)
	self.label_w_old = self.vp_w
end


--- Setup or change a widget's label state. The label text is reset to an empty string.
-- @param self The widget to update.
-- @param mode ("single") The label mode to use.
function lgcLabel.setup(self, mode)

	mode = mode or "single"

	-- Assertions
	-- [[
	_assertLabelMode(2, mode)
	--]]

	-- The label text to draw.
	self.label = ""

	-- Whether the label is single-line, single-with-underline, or multi-line.
	self.label_mode = mode or "single"

	if mode == "multi" then
		-- The old wrap-limit for the text. Indicates if the label is in need of an
		-- update while reshaping.
		self.label_w_old = false

		-- Height of the wrapped text. Used for vertical centering.
		self.label_h = 0

	else
		-- These settings are not used in the other modes.
		self.label_w_old = nil
		self.label_h = nil
	end

	if mode == "single-ul" then
		-- (not ul_x) means that the underline is not in use.
		self.label_ul_x = false
		-- The amount to offset the underline when "center" or "right" horizontal alignment are active.
		self.label_ul_ox = 0
		self.label_ul_w = 0
		-- Underline height is handled through theming.

	else
		-- These settings are not used in the other modes.
		self.label_ul_x = nil
		self.label_ul_ox = nil
		self.label_ul_w = nil
	end
end


--- Removes all label fields from the widget.
-- @param self The widget to modify.
function lgcLabel.remove(self)

	self.label_mode = nil
	self.label = nil
	self.label_w_old = nil
	self.label_h = nil
	self.label_ul_x = nil
	self.label_ul_ox = nil
	self.label_ul_w = nil
end


local function _calculateUnderlineOffset(self, font)

	-- Valid only for "single-ul" mode.
	local align_h = self.skin.label_align_h
	if align_h == "center" then
		self.label_ul_ox = math.floor((self.vp_w - font:getWidth(self.label)) / 2)

	elseif align_h == "right" then
		self.label_ul_ox = math.floor((self.vp_w - font:getWidth(self.label)))

	else -- "left"
		self.label_ul_ox = 0
	end
end


--- Plugin method for widgets to assign text to a widget label. The widget's viewport #1 must be configured.
--@param self The widget to update.
--@param text The text to assign to the label.
--@param mode (current) Optionally change the label mode.
function lgcLabel.widSetLabel(self, text, mode)

	mode = mode or self.label_mode

	-- Assertions
	-- [[
	uiShared.assertText(2, text)
	_assertLabelMode(3, mode)
	--]]

	-- Check for mode update.
	if mode ~= self.label_mode then
		lgcLabel.setup(self, mode)
	end

	self.label = text

	if self.label_mode == "single-ul" then
		-- Process underline.
		local font = self.skin.label_style.font
		local temp_str
		temp_str, self.label_ul_x, self.label_ul_w = textUtil.processUnderline(self.label, font)

		_calculateUnderlineOffset(self, font)

		self.label = temp_str or self.label

	elseif self.label_mode == "multi" then
		multiLineWrap(self, self.skin.label_style.font)
	end
end


--- Update a label during widget reshaping, if necessary.
function lgcLabel.reshapeLabel(self)

	if self.label_mode == "single-ul" then
		_calculateUnderlineOffset(self, self.skin.label_style.font)

	elseif self.label_mode == "multi" then
		-- Need to refresh wrapped dimensions?
		if self.vp_w ~= self.label_w_old then
			multiLineWrap(self, self.skin.label_style.font)
		end
	end

	-- Nothing to do for `single`.
end


--- Draws a widget's label text.
-- @param self The widget.
-- @param c_text The text color (table).
-- @param c_ul The underline color (table, or false/nil to use the text color).
-- @param label_ox Text X offset.
-- @param label_oy Text Y offset. (ie for inset button states)
-- @param ox Scissor X offset.
-- @param oy Scissor Y offset.
function lgcLabel.render(self, skin, font, c_text, c_ul, label_ox, label_oy, ox, oy)

	love.graphics.push("all")

	local label_style = skin.label_style

	-- Prevent text from spilling out of its allotted region (Viewport #1).
	uiGraphics.intersectScissor(
		ox + self.x + self.vp_x,
		oy + self.y + self.vp_y,
		self.vp_w,
		self.vp_h
	)

	local height = self.label_h or math.floor(0.5 + font:getHeight() * font:getLineHeight())
	local text_y
	if skin.label_align_v == "top" then
		text_y = math.floor(self.vp_y)

	elseif skin.label_align_v == "bottom" then
		text_y = math.floor(self.vp_y + self.vp_h - height)

	else -- "middle"
		text_y = math.floor(self.vp_y + ((self.vp_h - height) * 0.5))
	end

	-- Draw shortcut key underline, if applicable.
	if self.label_ul_x then
		local tq_px = skin.tq_px
		love.graphics.setColor(c_ul or c_text)
		uiGraphics.quadXYWH(
			tq_px,
			self.vp_x + label_ox + self.label_ul_x + self.label_ul_ox,
			text_y + label_oy + label_style.ul_oy,
			self.label_ul_w,
			label_style.ul_h
		)
	end

	-- Now, the text.
	love.graphics.setFont(font)
	love.graphics.setColor(c_text)
	love.graphics.printf(
		self.label,
		self.vp_x + label_ox,
		text_y + label_oy,
		self.vp_w,
		skin.label_align_h
	)

	love.graphics.pop()
end


return lgcLabel

