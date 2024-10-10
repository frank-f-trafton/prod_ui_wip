-- Sprite Def: Line (Polyline)
-- See README.md for version and license info.

local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local temp_transform = love.math.newTransform()


local style = aCore.newSpriteStyle()
def.style = style


style.__index = style
style._type = "line"

style.line_style = "smooth"
style.line_width = 1.0
style.line_join = "miter"


function def.new(points)

	-- Assertions
	-- [[
	if type(points) ~= "table" then aCore.errBadType(1, points, "table") end
	--]]

	local self = setmetatable({}, style)

	-- Sequence of points (x1,y1, x2,y2, ...)
	self.points = points

	return self
end


function style:draw(x, y)

	if not self.visible then
		return
	end

	love.graphics.push("all")

	self:setColor()
	love.graphics.setBlendMode(self.blend_mode, self.alpha_mode)

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

	love.graphics.setLineWidth(self.line_width)
	love.graphics.setLineStyle(self.line_style)
	love.graphics.setLineJoin(self.line_join)

	love.graphics.line(self.points)

	love.graphics.pop()
end


return def
