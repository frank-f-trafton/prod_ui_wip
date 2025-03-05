--[[
	Generic text widget. Unskinned.
--]]


local context = select(1, ...)


local def = {}


local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")


function def:uiCall_initialize()
	-- Required:
	if not self.font then
		error("missing field: self.font")
	end

	-- Defaults:
	self.visible = true

	self.text = ""

	-- These are set automatically by refreshText().
	self.text_y = 0
	self.text_w = 0
	self.text_h = 0

	self.align = "left"
	self.align_v = "top" -- unformatted only

	self.formatted = false

	self.margin_l = 0
	self.margin_r = 0
	self.margin_t = 0
	self.margin_b = 0

	self.r = 1
	self.g = 1
	self.b = 1
	self.a = 1

	self:refreshText()
end


function def:refreshText()
	local text_h

	if self.formatted then
		local lines
		self.text_w, lines = font:getWrap(self.text)
		text_h = self.font:getHeight() * #lines
	else
		text_h = self.font:getHeight() * (1 + textUtil.countStringPatterns(self.text, "\n", true))
		self.text_w = self.font:getWidth(self.text)
	end

	if self.align_v == "top" then
		self.text_y = self.margin_t

	elseif self.align_v == "center" then
		self.text_y = self.margin_t + math.floor((self.h - self.margin_t - self.margin_b - text_h) * 0.5)

	elseif self.align_v == "bottom" then
		self.text_y = self.h - self.margin_b - text_h

	else
		error("invalid align_v value.")
	end
end


function def:setFont(font)
	-- XXX Assertions
	self.font = font

	self:refreshText()
end


function def:setText(text)
	-- XXX Assertions
	self.text = text

	self:refreshText()
end


function def:setFormatted(formatted)
	-- XXX Assertions
	self.formatted = formatted

	self:refreshText()
end


function def:setMargins(l, r, t, b)
	-- XXX Assertions
	self.margin_l = l
	self.margin_r = r
	self.margin_t = t
	self.margin_b = b

	self:refreshText()
end


function def:setAlign(align)
	-- XXX Assertions
	self.align = align

	self:refreshText()
end


function def:setVerticalAlign(align_v)
	-- XXX Assertions
	self.align_v = align_v

	self:refreshText()
end


function def:setColor(r, g, b, a)
	-- XXX Assertions
	self.r = r
	self.g = g
	self.b = b
	self.a = a
end


function def:render()
	love.graphics.setFont(self.font)
	love.graphics.setColor(self.r, self.g, self.b, self.a)

	if self.formatted then
		love.graphics.printf(self.text, self.margin_l, self.text_y, self.w - self.margin_l - self.margin_r, self.align)
	else
		love.graphics.print(self.text, self.margin_l, self.text_y)
	end
end


return def
