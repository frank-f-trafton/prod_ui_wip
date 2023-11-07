-- Sprite Def: 9-Slice
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")
local quadSlice = require(REQ_PATH .. "quad_slice")


local temp_transform = aCore.temp_transform


local style = aCore.newSpriteStyle()
def.style = style


style.__index = style
style._type = "slice"


-- 9-Slices Will not render by default if width or height are <= 0.
style.w = 0
style.h = 0

style.image = false
style.slice = false


function def.new(image, slice)

	-- Assertions
	-- [[
	if type(image) ~= "userdata" then aCore.errBadType(1, image, "userdata (LÖVE Image)")
	elseif type(slice) ~= "table" then aCore.errBadType(2, slice, "table") end
	--]]

	local self = setmetatable({}, style)

	self.image = image
	self.slice = slice

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

	self.slice:draw(self.image, 0, 0, self.w, self.h)

	love.graphics.pop()
end


return def
