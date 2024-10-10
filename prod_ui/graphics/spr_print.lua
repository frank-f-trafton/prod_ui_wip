-- Sprite Def: Print (text drawn with love.graphics.print / printf).
-- See README.md for version and license info.

local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local style = aCore.newSpriteStyle()
def.style = style


style.__index = style
style._type = "print"


function def.new(text, font)

	-- Assertions
	-- [[
	if not aCore.type_text[type(text)] then aCore.errBadType(1, text, "string/number/table")
	elseif type(font) ~= "userdata" then aCore.errBadType(2, font, "userdata (LÖVE Font)") end
	--]]

	local self = setmetatable({}, style)

	self.font = font
	self.text = text

	-- Set true to use LÖVE's printf function.
	self.formatted = false

	-- Parameters for printf.
	self.limit = math.huge
	self.align = "left"

	return self
end


function style:draw(x, y)

	if not self.visible then
		return
	end

	love.graphics.push("all")

	self:setColor()
	love.graphics.setBlendMode(self.blend_mode, self.alpha_mode)

	if not self.formatted then
		love.graphics.print(
			self.text,
			self.font,
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

	else
		love.graphics.printf(
			self.text,
			self.font,
			x + self.x,
			y + self.y,
			self.limit,
			self.align,
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
