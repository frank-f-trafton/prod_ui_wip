-- Sprite Def: Mesh
-- See README.md for version and license info.


local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local style = aCore.newSpriteStyle()
def.style = style

style.__index = style
style._type = "mesh"


function def.new(mesh)

	-- Assertions
	-- [[
	if type(mesh) ~= "userdata" then aCore.errBadType(1, mesh, "userdata (LÖVE Mesh)") end
	--]]

	local self = setmetatable({}, style)

	self.mesh = mesh

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
		self.mesh,
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
