local uiGraphics = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local auxColor = require(REQ_PATH .. "graphics.aux_color")
uiGraphics.auxColor = auxColor
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
uiGraphics.quadSlice = quadSlice


-- * Color *


--[[
Wrapper for love.graphics.setColor() which sets a mix of RGBA values plus a table of colors.

Usage: uiGraphics.mixVT(r, g, b, a, color_table)

Note that this does not correctly handle premultiplied colors.
--]]
uiGraphics.mixVT = auxColor.mixVT


--[[
Wrapper for love.graphics.setColor() that handles premultiplying colors.

Notes:

* LÖVE text and shape primitives (love.graphics.rectangle, etc.) typically use alphamultiply mode.

* Canvases, when drawn to the screen or another canvas, typically use premultiplied mode.

* Some blend modes require the use of premultiplied mode.


More info:

https://love2d.org/wiki/love.graphics.setBlendMode
https://love2d.org/wiki/BlendMode
https://love2d.org/wiki/BlendAlphaMode
https://love2d.org/wiki/BlendMode_Formulas
--]]


uiGraphics.setColorCorrected = {}
uiGraphics.setColorCorrected["alphamultiply"] = love.graphics.setColor

uiGraphics.setColorCorrected["premultiplied"] = function(r, g, b, a)

	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
		r, g, b = love.math.gammaToLinear(r, g, b)
		r, g, b = r * a, g * a, b * a
		r, g, b = love.math.linearToGamma(r, g, b)

	else
		r, g, b = love.math.gammaToLinear(r, g, b)
		r, g, b = r * a, g * a, b * a
		r, g, b = love.math.linearToGamma(r, g, b)
	end
	love.graphics.setColor(r, g, b, a)
end


uiGraphics.setColorCorrectedV = {}
uiGraphics.setColorCorrectedV["alphamultiply"] = love.graphics.setColor

uiGraphics.setColorCorrectedV["premultiplied"] = function(r, g, b, a)

	r, g, b = love.math.gammaToLinear(r, g, b)
	r, g, b = r * a, g * a, b * a
	r, g, b = love.math.linearToGamma(r, g, b)

	love.graphics.setColor(r, g, b, a)
end


uiGraphics.setColorCorrectedT = {}
uiGraphics.setColorCorrectedT["alphamultiply"] = love.graphics.setColor

uiGraphics.setColorCorrectedT["premultiplied"] = function(t)

	local r, g, b, a = t[1], t[2], t[3], t[4]
	r, g, b = love.math.gammaToLinear(r, g, b)
	r, g, b = r * a, g * a, b * a
	r, g, b = love.math.linearToGamma(r, g, b)

	love.graphics.setColor(r, g, b, a)
end


uiGraphics.setColorUncorrected = {}
uiGraphics.setColorUncorrected["alphamultiply"] = love.graphics.setColor

uiGraphics.setColorUncorrected["premultiplied"] = function(r, g, b, a)

	if type(r) == "table" then
		local a = r[4]
		love.graphics.setColor(r[1] * a, r[2] * a, r[3] * a, a)

	else
		love.graphics.setColor(r * a, g * a, b * a, a)
	end
end


uiGraphics.setColorUncorrectedV = {}
uiGraphics.setColorUncorrectedV["alphamultiply"] = love.graphics.setColor

uiGraphics.setColorUncorrectedV["premultiplied"] = function(r, g, b, a)
	love.graphics.setColor(r * a, g * a, b * a, a)
end


uiGraphics.setColorUncorrectedT = {}
uiGraphics.setColorUncorrectedT["alphamultiply"] = love.graphics.setColor

uiGraphics.setColorUncorrectedT["premultiplied"] = function(t)

	local a = t[4]
	love.graphics.setColor(t[1] * a, t[2] * a, t[3] * a, a)
end


if love.graphics.isGammaCorrect() then
	uiGraphics.setColor = uiGraphics.setColorCorrected
	uiGraphics.setColorV = uiGraphics.setColorCorrectedV
	uiGraphics.setColorT = uiGraphics.setColorCorrectedT

else

	uiGraphics.setColor = uiGraphics.setColorUncorrected
	uiGraphics.setColorV = uiGraphics.setColorUncorrectedV
	uiGraphics.setColorT = uiGraphics.setColorUncorrectedT
end


-- * Drawing *


--- Draws a whole texture.
function uiGraphics.texture(tex_def, x, y, w, h)

	--print("uiGraphics.texture()", "blend_mode", love.graphics.getBlendMode())

	local texture = tex_def.texture
	love.graphics.draw(texture, x, y, 0, texture:getWidth() / w, texture:getHeight() / h)
end


--- Draws a whole texture. (Checks blend mode.)
function uiGraphics.textureB(tex_def, x, y, w, h)

	local blend_mode, alpha_mode = love.graphics.getBlendMode()
	love.graphics.setBlendMode(tex_def.blend_mode, tex_def.alpha_mode)
	--print("uiGraphics.textureB()", "blend_mode", love.graphics.getBlendMode())

	local texture = tex_def.texture
	love.graphics.draw(texture, x, y, 0, texture:getWidth() / w, texture:getHeight() / h)

	love.graphics.setBlendMode(blend_mode, alpha_mode)
end


--- Draws a textured 9-Slice.
function uiGraphics.drawSlice(tex_slice, x, y, w, h)

	--print("uiGraphics.drawSlice()", "blend_mode", love.graphics.getBlendMode())

	tex_slice.slice:draw(tex_slice.texture, x, y, w, h)
end


--- Draws a textured 9-Slice with offsetting. The slice must have the fields ox1, oy1, ox2, and oy2 configured.
function uiGraphics.drawSliceWithOffsets(tex_slice, x, y, w, h)

	--print("uiGraphics.drawSliceOffset()", "blend_mode", love.graphics.getBlendMode())
	local slice = tex_slice.slice

	slice:draw(
		tex_slice.texture,
		x - slice.ox1,
		y - slice.oy1,
		w + slice.ox1 + slice.ox2,
		h + slice.oy1 + slice.oy2
	)
end


--- Draws a textured 9-Slice. (Checks blend mode.)
function uiGraphics.drawSliceB(tex_slice, x, y, w, h)

	local blend_mode, alpha_mode = love.graphics.getBlendMode()
	love.graphics.setBlendMode(tex_slice.blend_mode, tex_slice.alpha_mode)
	--print("uiGraphics.drawSliceB()", "blend_mode", love.graphics.getBlendMode())

	tex_slice.slice:draw(tex_slice.texture, x, y, w, h)

	love.graphics.setBlendMode(blend_mode, alpha_mode)
end


--- Draws a textured quad.
function uiGraphics.quadXY(tex_quad, x, y)

	--print("uiGraphics.quadXY()", "blend_mode", love.graphics.getBlendMode())

	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y)
end


--- Draws a textured quad. (Checks blend mode.)
function uiGraphics.quadXYB(tex_quad, x, y)

	local blend_mode, alpha_mode = love.graphics.getBlendMode()
	love.graphics.setBlendMode(tex_quad.blend_mode, tex_quad.alpha_mode)
	--print("uiGraphics.quadXY()", "blend_mode", love.graphics.getBlendMode())

	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y)

	love.graphics.setBlendMode(blend_mode, alpha_mode)
end


--- Draws a textured quad, stretched to an arbitrary width and height.
function uiGraphics.quadXYWH(tex_quad, x, y, w, h)

	--print("uiGraphics.quadXYWH()", "blend_mode", love.graphics.getBlendMode())

	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y, 0, w / tex_quad.w, h / tex_quad.h)
end


--- Draws a textured quad, stretched to an arbitrary width and height. (Checks blend mode.)
function uiGraphics.quadXYWHB(tex_quad, x, y, w, h)

	local blend_mode, alpha_mode = love.graphics.getBlendMode()
	love.graphics.setBlendMode(tex_quad.blend_mode, tex_quad.alpha_mode)
	--print("uiGraphics.quadXYWH()", "blend_mode", love.graphics.getBlendMode())

	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y, 0, w / tex_quad.w, h / tex_quad.h)

	love.graphics.setBlendMode(blend_mode, alpha_mode)
end


--- Draws a textured quad. If the requested size is smaller than the quad, the image is reduced. If the size is greater, the image is centered.
function uiGraphics.quadShrinkOrCenterXYWH(tex_quad, x, y, w, h)

	local sx = math.max(0, math.min(1, w / tex_quad.w))
	local sy = math.max(0, math.min(1, h / tex_quad.h))

	local ox = math.floor((w - tex_quad.w * sx) * 0.5)
	local oy = math.floor((h - tex_quad.h * sy) * 0.5)

	love.graphics.draw(
		tex_quad.texture,
		tex_quad.quad,
		x + ox,
		y + oy,
		0,
		sx,
		sy
	)
end


--- Draws a textured quad, stretched to an arbitrary width and height. Assumes the quad is a 1x1 pixel.
function uiGraphics.quad1x1(tex_quad, x, y, w, h)

	--print("uiGraphics.quad1x1()", "blend_mode", love.graphics.getBlendMode())

	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y, 0, w, h)
end


--- Draws a textured quad, stretched to an arbitrary width and height. Assumes the quad is a 1x1 pixel. (Checks blend mode.)
function uiGraphics.quad1x1B(tex_quad, x, y, w, h)

	local blend_mode, alpha_mode = love.graphics.getBlendMode()
	love.graphics.setBlendMode(tex_quad.blend_mode, tex_quad.alpha_mode)
	--print("uiGraphics.quad1x1()", "blend_mode", love.graphics.getBlendMode())

	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y, 0, w, h)

	love.graphics.setBlendMode(blend_mode, alpha_mode)
end


--- Draws a simple rectangular frame. The coordinates specify the outer edge of the frame. Rounded corners are not
--	supported.
-- @param tex_quad The texture + quad def to use. Assumes the quad is a 1x1 pixel.
-- @param breadth The thickness of the frame outline. Avoid values that are less than 0 or greater than half the width
--	or height of the frame.
function uiGraphics.rectangleFrame(tex_quad, breadth, x, w, y, h)

	--[[
	-- Draw position and order:
	1112
	4  2
	4  2
	4333
	--]]

	--print("uiGraphics.rectangleFrame()", "blend_mode", love.graphics.getBlendMode())

	local tex, quad = tex_quad.texture, tex_quad.quad

	love.graphics.draw(tex, quad, x, y, 0, w - breadth, breadth)
	love.graphics.draw(tex, quad, x + w - breadth, y, 0, breadth, h - breadth)
	love.graphics.draw(tex, quad, x + breadth, y + h - breadth, 0, w - breadth, breadth)
	love.graphics.draw(tex, quad, x, y + breadth, 0, breadth, h - breadth)
end


--- Draws a simple rectangular frame. The coordinates specify the outer edge of the frame. Rounded corners are not
--	supported. (Checks blend mode.)
-- @param tex_quad The texture + quad def to use. Assumes the quad is a 1x1 pixel.
-- @param breadth The thickness of the frame outline. Avoid values that are less than 0 or greater than half the width
--	or height of the frame.
function uiGraphics.rectangleFrameB(tex_quad, breadth, x, w, y, h)

	--[[
	-- Draw position and order:
	1112
	4  2
	4  2
	4333
	--]]

	local blend_mode, alpha_mode = love.graphics.getBlendMode()
	love.graphics.setBlendMode(tex_quad.blend_mode, tex_quad.alpha_mode)
	--print("uiGraphics.rectangleFrame()", "blend_mode", love.graphics.getBlendMode())

	local tex, quad = tex_quad.texture, tex_quad.quad

	love.graphics.draw(tex, quad, x, y, 0, w - breadth, breadth)
	love.graphics.draw(tex, quad, x + w - breadth, y, 0, breadth, h - breadth)
	love.graphics.draw(tex, quad, x + breadth, y + h - breadth, 0, w - breadth, breadth)
	love.graphics.draw(tex, quad, x, y + breadth, 0, breadth, h - breadth)

	love.graphics.setBlendMode(blend_mode, alpha_mode)
end


-- * Sprite Objects


uiGraphics.astro_defs = {}
do
	local GFX_PATH = REQ_PATH .. "graphics."
	local defs = uiGraphics.astro_defs

	defs.anim = require(GFX_PATH .. "spr_anim")
	uiGraphics.newAnim = defs.anim.new -- (anim_def)

	defs.arc = require(GFX_PATH .. "spr_arc")
	uiGraphics.newArc = defs.arc.new -- (radius, angle1, angle2)

	defs.circle = require(GFX_PATH .. "spr_circle")
	uiGraphics.newCircle = defs.circle.new -- (radius)

	defs.ellipse = require(GFX_PATH .. "spr_ellipse")
	uiGraphics.newEllipse = defs.ellipse.new -- (radius_x, radius_y)

	defs.group = require(GFX_PATH .. "spr_group")
	uiGraphics.newGroup = defs.group.new -- ()

	defs.image = require(GFX_PATH .. "spr_image")
	uiGraphics.newImage = defs.image.new -- (image, [quad])

	defs.line = require(GFX_PATH .. "spr_line")
	uiGraphics.newLine = defs.line.new -- (points)

	defs.mesh = require(GFX_PATH .. "spr_mesh")
	uiGraphics.newMesh = defs.mesh.new -- (mesh)

	defs.points = require(GFX_PATH .. "spr_points")
	uiGraphics.newPoints = defs.points.new -- (points)

	defs.polygon = require(GFX_PATH .. "spr_polygon")
	uiGraphics.newPolygon = defs.polygon.new -- (points)

	defs.print = require(GFX_PATH .. "spr_print")
	uiGraphics.newPrint = defs.print.new -- (text, font)

	defs.rect = require(GFX_PATH .. "spr_rect")
	uiGraphics.newRect = defs.rect.new -- (w, h)

	defs.slice = require(GFX_PATH .. "spr_slice")
	uiGraphics.newSlice = defs.slice.new -- (image, slice)

	defs.sprite_batch = require(GFX_PATH .. "spr_sprite_batch")
	uiGraphics.newSpriteBatch = defs.sprite_batch.new -- (sprite_batch)

	defs.text_batch = require(GFX_PATH .. "spr_text_batch")
	uiGraphics.newTextBatch = defs.text_batch.new -- (text_batch)
end


return uiGraphics

