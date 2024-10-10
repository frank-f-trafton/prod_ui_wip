-- Sprite Def: Group
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local temp_transform = aCore.temp_transform


local style = aCore.newSpriteStyle()
def.style = style


style.__index = style
style._type = "group"


-- Optional range of sprites to draw.
style.range1 = 1
style.range2 = math.huge


function def.new(sprites)

	-- Assertions
	-- [[
	if sprites and type(sprites) ~= "table" then aCore.errBadType(1, sprites, "nil/false/table") end
	--]]

	local self = {}

	self.sprites = sprites or {}

	setmetatable(self, style)

	return self
end


function style:draw(x, y)

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

	local sprites = self.sprites
	for i = math.max(self.range1, 1), math.min(self.range2, #sprites) do
		sprites[i]:draw(0, 0)
	end

	love.graphics.pop()
end


return def
