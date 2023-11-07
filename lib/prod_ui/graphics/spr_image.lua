-- Sprite Def: Image (Image + Quad)
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local style = aCore.newSpriteStyle()
def.style = style


style.__index = style
style._type = "image"

style.image = false
style.quad = false


function def.new(image, quad)

	quad = quad or false

	-- Assertions
	-- [[
	if type(image) ~= "userdata" then aCore.errBadType(1, image, "userdata (LÖVE Image)")
	elseif quad and type(quad) ~= "userdata" then aCore.errBadType(2, quad, "userdata (LÖVE Quad)") end
	--]]

	local self = {}

	self.image = image
	self.quad = quad

	setmetatable(self, style)

	return self
end


function style:draw(x, y)

	if not self.visible then
		return
	end

	love.graphics.push("all")

	self:setColor()
	love.graphics.setBlendMode(self.blend_mode, self.alpha_mode)

	if self.quad then
		love.graphics.draw(
			self.image,
			self.quad,
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

	-- Without quad
	else
		love.graphics.draw(
			self.image,
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
	end

	love.graphics.pop()
end


return def
