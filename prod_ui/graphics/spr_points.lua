-- Sprite Def: Points
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local temp_transform = love.math.newTransform()


local style = aCore.newSpriteStyle()
def.style = style

style.__index = style
style._type = "points"

style.point_size = 1


function def.new(points)

	-- Assertions
	-- [[
	if type(points) ~= "table" then aCore.errBadType(1, points, "table") end
	--]]

	local self = setmetatable({}, style)

	-- Can be a sequence of XY coords, or a sequence of tables containing {x, y, r, g, b, a}.
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

	love.graphics.setPointSize(self.point_size)

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

	love.graphics.points(self.points)

	love.graphics.pop()
end


return def
