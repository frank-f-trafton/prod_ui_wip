-- Sprite Def: Arc
-- See README.md for version and license info.

local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")
local auxColor = require(REQ_PATH .. "aux_color")


local temp_transform = love.math.newTransform()


local style = aCore.newSpriteStyle()
def.style = style

style.__index = style
style._type = "arc"

style.mode = "line"
style.arctype = "pie" -- "pie", "open", "closed"

-- Optional:
-- style.segments

style.line_style = "smooth"
style.line_width = 1.0
style.line_join = "miter" -- visible with a large width and small number of segments


-- Stroke color
style.r2 = 0.0
style.g2 = 0.0
style.b2 = 0.0
style.a2 = 1.0

-- Stroke blend mode
style.blend_mode2 = "alpha"
style.alpha_mode2 = "alphamultiply"


function def.new(radius, angle1, angle2)

	-- Assertions
	-- [[
	if type(radius) ~= "number" then aCore.errBadType(1, radius, "number")
	elseif type(angle1) ~= "number" then aCore.errBadType(2, angle1, "number")
	elseif type(angle2) ~= "number" then aCore.errBadType(3, angle2, "number") end
	--]]

	local self = setmetatable({}, style)

	self.arctype = "pie"
	self.radius = radius
	self.angle1 = angle1
	self.angle2 = angle2

	return self
end


function def.drawA(self, x, y)

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

	if self.mode == "line" then
		love.graphics.setLineStyle(self.line_style)
		love.graphics.setLineWidth(self.line_width)
		love.graphics.setLineJoin(self.line_join)
	end

	love.graphics.arc(self.mode, self.arctype, 0, 0, self.radius, self.angle1, self.angle2, self.segments)

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

	love.graphics.arc("fill", self.arctype, 0, 0, self.radius, self.angle1, self.angle2, self.segments)

	-- Handle stroke
	auxColor.mixVV(rr, gg, bb, aa, self.r2, self.g2, self.b2, self.a2)
	love.graphics.setBlendMode(self.blend_mode2, self.alpha_mode2)

	love.graphics.setLineStyle(self.line_style)
	love.graphics.setLineWidth(self.line_width)
	love.graphics.setLineJoin(self.line_join)

	love.graphics.arc("line", self.arctype, 0, 0, self.radius, self.angle1, self.angle2, self.segments)

	love.graphics.pop()
end


style.draw = def.drawA


return def
