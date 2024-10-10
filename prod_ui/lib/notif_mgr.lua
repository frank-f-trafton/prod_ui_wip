-- ProdUI: Tooltip and toast notification manager.


local notifMgr = {}


local _mt_mgr = {}
_mt_mgr.__index = _mt_mgr


local _mt_tool_tip = {}
_mt_tool_tip.__index = _mt_tool_tip


function notifMgr.newManager(font, colors)

	local self = setmetatable({}, _mt_mgr)

	self.font = font
	self.colors = colors

	self.objects = {}

	return self
end


function notifMgr.newToolTip(start_font)

	local self = {}
	setmetatable(self, _mt_tool_tip)

	self.visible = false

	self.x = 0
	self.y = 0
	self.w = 0
	self.h = 0

	self.min_w = 0
	self.min_h = 0
	self.max_w = 2^16
	self.max_h = 2^16

	-- Set these proportional to the font size.
	self.margin_x = 8
	self.margin_y = 8

	self.font = start_font
	self.line_height = self.font:getHeight() * self.font:getLineHeight()

	self.alpha = 1.0
	self.alpha_dt_mul = 4.0

	self.color_body = {0.0, 0.0, 0.0, 1.0}
	self.color_outline = {0.8, 0.8, 0.8, 1.0}
	self.color_text = {1.0, 1.0, 1.0, 1.0}

	self.str = ""

	-- Populated by self:arrange()
	-- self.lines

	self.line_style = "smooth"
	self.line_join = "miter"
	self.line_width = 1.0
	-- Optional: self.rx
	-- Optional: self.ry
	-- Optional: self.segments

	return self
end


function _mt_tool_tip:setMinMaxDimensions(min_w, min_h, max_w, max_h)

	-- XXX assertions

	self.min_w = min_w
	self.min_h = min_h
	self.max_w = max_w
	self.max_h = max_h
end


function _mt_tool_tip:setFont(font)

	-- XXX assertions

	self.font = font
	self.line_height = font:getHeight() * font:getLineHeight()
end
-- XXX etc.


function _mt_tool_tip:arrange(str, x, y)

	local font = self.font

	if x then
		self.x = x
	end
	if y then
		self.y = y
	end

	local width, wrapped = self.font:getWrap(str, self.max_w)
	self.w = math.max(self.min_w, width + self.margin_x*2)
	self.h = math.max(self.min_h, math.min(self.max_h, #wrapped * self.line_height + self.margin_y*2))

	self.lines = wrapped

	return self
end


function _mt_tool_tip:draw(x, y)

	if self.lines then
		love.graphics.push("all")

		x = x or self.x
		y = y or self.y

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
		love.graphics.setFont(self.font)

		love.graphics.intersectScissor(
			x,
			y,
			math.max(0, self.w),
			math.max(0, self.h)
		)

		for i, line in ipairs(self.lines) do
			love.graphics.print(line, x + self.margin_x, y + self.margin_y + (i-1) * self.line_height)
		end

		love.graphics.pop()
	end
end


return notifMgr

