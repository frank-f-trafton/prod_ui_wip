local context = select(1, ...)


local wcToolTip = {}


local themeAssert = context:getLua("core/res/theme_assert")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")


local _mt_tool_tip = {}
_mt_tool_tip.__index = _mt_tool_tip


local fonts = context.resources.fonts


function wcToolTip.newToolTip(font_id)
	font_id = font_id or "p"
	themeAssert.fontId(1, font_id)

	local self = setmetatable({}, _mt_tool_tip)

	self.visible = false

	self.w = 0
	self.h = 0

	self.min_w = 0
	self.min_h = 0
	self.max_w = 2^16
	self.max_h = 2^16

	self.margin_x = 8
	self.margin_y = 8

	-- The min, max, and margin values are scaled on demand.

	self.font_id = font_id
	self.line_height = 0

	self.alpha = 1.0
	self.alpha_dt_mul = 4.0

	self.color_body = {0.0, 0.0, 0.0, 1.0}
	self.color_outline = {0.8, 0.8, 0.8, 1.0}
	self.color_text = {1.0, 1.0, 1.0, 1.0}

	self.str = ""

	-- Is false, or a table populated by self:arrange().
	self.lines = false

	self.line_style = "smooth"
	self.line_join = "miter"
	self.line_width = 1.0

	return self
end


function _mt_tool_tip:setMinMaxDimensions(min_w, min_h, max_w, max_h)
	uiAssert.numberGe(1, min_w, 0)
	uiAssert.numberGe(1, min_h, 0)
	uiAssert.numberGe(1, max_w, 0)
	uiAssert.numberGe(1, max_h, 0)

	self.min_w = min_w
	self.min_h = min_h
	self.max_w = max_w
	self.max_h = max_h
end


function _mt_tool_tip:setFont(font_id)
	themeAssert.fontId(1, font_id)

	self.font_id = font_id or "p"
	local font = fonts[font_id]
end
-- TODO: etc.


function _mt_tool_tip:arrange(str)
	local scale = context.scale
	local font = fonts[self.font_id]

	local sl, fl = self, math.floor
	local min_w, min_h = fl(sl.min_w * scale), fl(sl.min_h * scale)
	local max_w, max_h = fl(sl.max_w * scale), fl(sl.max_h * scale)
	local margin_x, margin_y = fl(sl.margin_x * scale), fl(sl.margin_y * scale)

	local width, wrapped = font:getWrap(str, self.max_w)

	self.line_height = font:getHeight() * font:getLineHeight()

	self.w = math.max(min_w, width + margin_x*2)
	self.h = math.max(min_h, math.min(max_h, #wrapped * self.line_height + margin_y*2))

	self.lines = wrapped

	return self
end


function _mt_tool_tip:draw(x, y)
	if self.lines then
		local scale = context.scale
		local font = fonts[self.font_id]

		local sl, fl = self, math.floor
		local m_width = font:getWidth("M")
		local margin_x, margin_y = fl(sl.margin_x * scale), fl(sl.margin_y * scale)

		love.graphics.push("all")

		-- Temp color variables. Needed to mix two alpha values together.
		local r, g, b, a

		-- Body
		r, g, b, a = self.color_body[1], self.color_body[2], self.color_body[3], self.color_body[4] * self.alpha
		love.graphics.setColor(r, g, b, a)

		love.graphics.rectangle("fill", x + 0.5, y + 0.5, self.w - 1, self.h - 1)

		-- Outline
		r, g, b, a = self.color_outline[1], self.color_outline[2], self.color_outline[3], self.color_outline[4] * self.alpha
		love.graphics.setColor(r, g, b, a)

		love.graphics.setLineStyle(self.line_style)
		love.graphics.setLineJoin(self.line_join)
		love.graphics.setLineWidth(self.line_width)
		love.graphics.rectangle("line", x + 0.5, y + 0.5, self.w - 1, self.h - 1)

		-- Text
		r, g, b, a = self.color_text[1], self.color_text[2], self.color_text[3], self.color_text[4] * self.alpha
		love.graphics.setColor(r, g, b, a)
		love.graphics.setFont(font)

		love.graphics.intersectScissor(x, y, math.max(0, self.w), math.max(0, self.h))

		for i, line in ipairs(self.lines) do
			love.graphics.print(line, x + margin_x, y + margin_y + (i-1) * self.line_height)
		end

		love.graphics.pop()
	end
end


return wcToolTip
