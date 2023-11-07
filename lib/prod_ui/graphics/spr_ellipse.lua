-- Sprite Def: Ellipse
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")
local auxColor = require(REQ_PATH .. "aux_color")


local temp_transform = love.math.newTransform()


local style = aCore.newSpriteStyle()
def.style = style

style.__index = style
style._type = "ellipse"

style.mode = "line"

-- Optional:
-- style.segments

style.line_style = "smooth"
style.line_width = 1.0
style.line_join = "miter" -- visible with a large width and small number of segments

-- DrawB params:
-- Stroke color
style.r2 = 0.0
style.g2 = 0.0
style.b2 = 0.0
style.a2 = 1.0

-- Stroke blend mode
style.blend_mode2 = "alpha"
style.alpha_mode2 = "alphamultiply"


function def.new(radius_x, radius_y)

	-- Assertions
	-- [[
	if type(radius_x) ~= "number" then aCore.errBadType(1, radius_x, "number")
	elseif type(radius_y) ~= "number" then aCore.errBadType(2, radius_y, "number") end
	--]]

	local self = setmetatable({}, style)

	self.radius_x = radius_x
	self.radius_y = radius_y

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

	love.graphics.ellipse(self.mode, 0, 0, self.radius_x, self.radius_y, self.segments)

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

	love.graphics.ellipse("fill", 0, 0, self.radius_x, self.radius_y, self.segments)

	-- Handle stroke
	auxColor.mixVV(rr, gg, bb, aa, self.r2, self.g2, self.b2, self.a2)
	love.graphics.setBlendMode(self.blend_mode2, self.alpha_mode2)

	love.graphics.setLineStyle(self.line_style)
	love.graphics.setLineWidth(self.line_width)
	love.graphics.setLineJoin(self.line_join)

	love.graphics.ellipse("line", 0, 0, self.radius_x, self.radius_y, self.segments)

	love.graphics.pop()
end


style.draw = def.drawA


return def
