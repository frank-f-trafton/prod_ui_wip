-- Sprite Def: Animated Image
-- See README.md for version and license info.

local def = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""

local aCore = require(REQ_PATH .. "astro_core")


local style = aCore.newSpriteStyle()
def.style = style

style.__index = style
style._type = "anim"

style.image = false
style.quad = false


-- Animation playback state
style.animate = false
style.anim_timer = 0
style.anim_speed_scale = 1.0
style.anim_frame_i = 1


function def.new(anim_def)

	-- Assertions
	-- [[
	if type(anim_def) ~= "table" then aCore.errBadType(1, anim_def, "table") end
	--]]

	local self = setmetatable({}, style)

	self.anim_def = anim_def

	self:refreshAnimation()
	-- Sets:
	-- * self.image
	-- * self.quad

	-- For animations to work, 'updateAnimation' must be called somewhere in your update code.

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


function style:updateAnimation(time)

	local def = self.anim_def

	if not self.animate then
		return
	end

	local changed = false

	self.anim_timer = self.anim_timer + time * self.anim_speed_scale

	local frames = def.frames

	-- Animations may go out of sync if passing in large deltas from low framerate.
	for safety = 1, 32 do
		local frame = frames[self.anim_frame_i]
		local frame_time = frame.time

		if self.anim_timer > frame_time then
			self.anim_timer = self.anim_timer - frame_time
			self.anim_frame_i = self.anim_frame_i + 1
			if self.anim_frame_i > #frames then
				self.anim_frame_i = 1
			end
			changed = true

		elseif self.anim_timer < 0 then
			self.anim_timer = self.anim_timer + frame_time
			self.anim_frame_i = self.anim_frame_i - 1
			if self.anim_frame_i < 1 then
				self.anim_frame_i = #frames
			end
			changed = true

		else
			break
		end
	end

	if changed then
		self:refreshAnimation()
	end
end


-- Configures the sprite to display the correct current frame.
function style:refreshAnimation()

	local def = self.anim_def

	self.image = def.image
	self.quad = def.frames[self.anim_frame_i].quad
end


return def
