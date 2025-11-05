--[[
Shared code for handling "label text" in widgets.


Label modes:
"single": A single line of text.

"single-ul": A single line of text with an optional underline. The text to be underlined is marked
	by two underscores, like `_this_`.

"multi": Multi-line text.


Required skin fields:

skin.tq_px: A textured quad of a single white pixel. Used for drawing the underline.

skin.label_align_h: Horizontal text alignment.
skin.label_align_v: Vertical text alignment.

skin.label_style: The label style table, usually taken from the theme table.
skin.label_style.font: The font to use when measuring and rendering text.
skin.label_style.ul_color: Underline color table, or false to use the current text color.
skin.label_style.ul_h: Underline height (thickness).


Required widget fields:

Viewport #1: self.vp
--]]


local context = select(1, ...)


local wcLabel = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


local _nm_modes = uiTable.newNamedMapV("LabelMode", "single", "single-ul", "multi")


-- Numeric values from 0-1 that correspond to font rendering alignment constants.
local align_h_num = {left=0.0, center=0.5, right=1.0, justify=0.0}


local function _multiLineWrap(self, vp, font)
	local _, lines = font:getWrap(self.label, vp.w)
	self.label_h = math.floor(0.5 + font:getHeight() * font:getLineHeight() * #lines)
	self.label_w_old = vp.w
end


--- Setup or change a widget's label state. The label text is reset to an empty string.
-- @param self The widget to update.
-- @param mode ("single") The label mode to use.
function wcLabel.setup(self, mode)
	mode = mode or "single"

	uiAssert.namedMap(2, mode, _nm_modes)

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
function wcLabel.remove(self)
	self.label_mode = nil
	self.label = nil
	self.label_w_old = nil
	self.label_h = nil
	self.label_ul_x = nil
	self.label_ul_ox = nil
	self.label_ul_w = nil
end


local function _calculateUnderlineOffset(self, vp, font)
	-- Valid only for "single-ul" mode.
	local align_h = self.skin.label_align_h
	self.label_ul_ox = math.floor((vp.w - font:getWidth(self.label)) * align_h_num[align_h])
end


--- Plugin method for widgets to assign text to a widget label. The widget's viewport #1 must be configured.
--@param self The widget to update.
--@param text The text to assign to the label.
--@param mode (current) Optionally change the label mode.
function wcLabel.widSetLabel(self, text, mode)
	mode = mode or self.label_mode

	uiAssert.loveStringOrColoredText(2, text)
	uiAssert.namedMap(3, mode, _nm_modes)

	-- Check for mode update.
	if mode ~= self.label_mode then
		wcLabel.setup(self, mode)
	end

	self.label = text

	if self.label_mode == "single-ul" then
		-- Process underline.
		local font = self.skin.label_style.font
		local temp_str
		temp_str, self.label_ul_x, self.label_ul_w = textUtil.processUnderline(self.label, font)

		_calculateUnderlineOffset(self, self.vp, font)

		self.label = temp_str or self.label

	elseif self.label_mode == "multi" then
		_multiLineWrap(self, self.vp, self.skin.label_style.font)
	end
end


--- Update a label during widget reshaping, if necessary.
function wcLabel.reshapeLabel(self)
	if self.label_mode == "single-ul" then
		_calculateUnderlineOffset(self, self.vp, self.skin.label_style.font)

	elseif self.label_mode == "multi" then
		-- Need to refresh wrapped dimensions?
		local vp = self.vp
		if vp.w ~= self.label_w_old then
			_multiLineWrap(self, vp, self.skin.label_style.font)
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
function wcLabel.render(self, skin, font, c_text, c_ul, label_ox, label_oy, ox, oy)
	love.graphics.push("all")

	local vp = self.vp
	local label_style = skin.label_style

	-- Prevent text from spilling out of its allotted region (Viewport #1).
	uiGraphics.intersectScissor(
		ox + self.x + vp.x,
		oy + self.y + vp.y,
		vp.w,
		vp.h
	)

	local font_height = font:getHeight()
	local font_line_height = font:getLineHeight()

	local height = self.label_h or math.floor(0.5 + font_height * font_line_height)
	local text_y
	if skin.label_align_v == "top" then
		text_y = math.floor(vp.y)

	elseif skin.label_align_v == "bottom" then
		text_y = math.floor(vp.y + vp.h - height)

	else -- "middle"
		text_y = math.floor(vp.y + ((vp.h - height) * 0.5))
	end

	-- Draw shortcut key underline, if applicable.
	if self.label_ul_x then
		local tq_px = skin.tq_px
		love.graphics.setColor(c_ul or c_text)
		uiGraphics.quadXYWH(
			tq_px,
			vp.x + label_ox + self.label_ul_x + self.label_ul_ox,
			text_y + font_height + label_oy,
			self.label_ul_w,
			label_style.ul_h
		)
	end

	-- Now, the text.
	love.graphics.setFont(font)
	love.graphics.setColor(c_text)
	love.graphics.printf(
		self.label,
		vp.x + label_ox,
		text_y + label_oy,
		vp.w,
		skin.label_align_h
	)

	love.graphics.pop()
end


return wcLabel
