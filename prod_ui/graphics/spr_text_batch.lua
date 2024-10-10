-- Sprite Def: TextBatch
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local style = aCore.newSpriteStyle()
def.style = style

style.__index = style
style._type = "text_batch"


function def.new(text_batch)

	-- Assertions
	-- [[
	if type(text_batch) ~= "userdata" then aCore.errBadType(1, text_batch, "userdata (LÖVE TextBatch)") end
	--]]

	local self = setmetatable({}, style)

	self.text_batch = text_batch

	return self
end


function style:draw(x, y)

	if not self.visible then
		return
	end

	love.graphics.push("all")

	self:setColor()
	love.graphics.setBlendMode(self.blend_mode, self.alpha_mode)

	love.graphics.draw(
		self.text_batch,
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

	love.graphics.pop()
end


return def
