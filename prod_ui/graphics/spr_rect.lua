-- Sprite Def: Rectangle
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")
local auxColor = require(REQ_PATH .. "aux_color")


local temp_transform = aCore.temp_transform


local style = aCore.newSpriteStyle()
def.style = style


style.__index = style
style._type = "rect"

-- Optional:
-- style.rx
-- style.ry
-- style.segments

style.mode = "line"

style.line_style = "smooth"
style.line_width = 1.0
style.line_join = "miter"


-- DrawB params:
-- Stroke color
style.r2 = 0.0
style.g2 = 0.0
style.b2 = 0.0
style.a2 = 1.0

-- Stroke blend mode
style.blend_mode2 = "alpha"
style.alpha_mode2 = "alphamultiply"


function def.new(w, h)

	-- Assertions
	-- [[
	if type(w) ~= "number" then aCore.errBadType(1, w, "number")
	elseif type(h) ~= "number" then aCore.errBadType(2, h, "number") end
	--]]

	local self = setmetatable({}, style)

	self.w = w
	self.h = h

	return self
end


function def.drawA(self, x, y)

	if not self.visible then
		return
	end

	love.graphics.push("all")

	temp_transform:setTransformation(
		x + self.x,
		y + self.y,
		self.rad,
		self.sx,
		self.sy,
		self.ox,
		self.oy,
		self.kx,
		self.ky
	)
	love.graphics.applyTransform(temp_transform)

	self:setColor()
	love.graphics.setBlendMode(self.blend_mode, self.alpha_mode)

	if self.mode == "line" then
		love.graphics.setLineStyle(self.line_style)
		love.graphics.setLineWidth(self.line_width)
		love.graphics.setLineJoin(self.line_join)
	end

	love.graphics.rectangle(self.mode, 0, 0, self.w, self.h, self.rx, self.ry, self.segments)

	love.graphics.pop()
end


function def.drawB(self, x, y)

	if not self.visible then
		return
	end

	love.graphics.push("all")

	temp_transform:setTransformation(
		x + self.x,
		y + self.y,
		self.rad,
		self.sx,
		self.sy,
		self.ox,
		self.oy,
		self.kx,
		self.ky
	)
	love.graphics.applyTransform(temp_transform)

	-- Handle fill
	local rr, gg, bb, aa = love.graphics.getColor()
	auxColor.mixVV(rr, gg, bb, aa, self.r, self.g, self.b, self.a)
	love.graphics.setBlendMode(self.blend_mode, self.alpha_mode)

	love.graphics.rectangle("fill", 0, 0, self.w, self.h, self.rx, self.ry, self.segments)

	-- Handle stroke
	auxColor.mixVV(rr, gg, bb, aa, self.r2, self.g2, self.b2, self.a2)
	love.graphics.setBlendMode(self.blend_mode2, self.alpha_mode2)

	love.graphics.setLineStyle(self.line_style)
	love.graphics.setLineWidth(self.line_width)
	love.graphics.setLineJoin(self.line_join)

	love.graphics.rectangle("line", 0, 0, self.w, self.h, self.rx, self.ry, self.segments)

	love.graphics.pop()
end


style.draw = def.drawA


return def
