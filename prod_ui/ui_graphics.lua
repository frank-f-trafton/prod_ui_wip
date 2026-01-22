local uiGraphics = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local auxColor = require(REQ_PATH .. "graphics.aux_color")
uiGraphics.auxColor = auxColor
local pMath = require(REQ_PATH .. "lib.pile_math")
local quadSlice = require(REQ_PATH .. "graphics.quad_slice")
uiGraphics.quadSlice = quadSlice


-- LÖVE 12 compatibility
local love_major, love_minor = love.getVersion()


uiGraphics.newTextBatch = (love_major <= 11) and love.graphics.newText or love.graphics.newTextBatch


-- * Scissor Wrappers *


-- LÖVE's scissorbox functions will raise an error if the width or height are less than zero.


local lg = love.graphics
local _draw, _setBlendMode, _getBlendMode = lg.draw, lg.setBlendMode, lg.getBlendMode
local _setScissor, _intersectScissor = lg.setScissor, lg.intersectScissor


function uiGraphics.setScissor(x, y, w, h)
	_setScissor(x, y, math.max(0, w), math.max(0, h))
end


function uiGraphics.intersectScissor(x, y, w, h)
	_intersectScissor(x, y, math.max(0, w), math.max(0, h))
end


-- * Drawing *


-- Quad at point:
function uiGraphics.quad(tex_quad, x, y)
	love.graphics.draw(tex_quad.texture, tex_quad.quad, x, y, 0, 1, 1, tex_quad.ox, tex_quad.oy)
end


function uiGraphics.quadXYWH(tex_quad, x, y, w, h)
	_draw(tex_quad.texture, tex_quad.quad, x, y, 0, w / tex_quad.w, h / tex_quad.h)
end


function uiGraphics.drawSlice(tex_slice, x, y, w, h)
	tex_slice.slice:draw(tex_slice.texture, x, y, w, h)
end


function uiGraphics.drawSliceWithOffsets(tex_slice, x, y, w, h)
	local slice = tex_slice.slice

	slice:draw(
		tex_slice.texture,
		x - slice.ox1,
		y - slice.oy1,
		w + slice.ox1 + slice.ox2,
		h + slice.oy1 + slice.oy2
	)
end


--- Draws a textured quad. If the requested size is smaller than the quad, the image is reduced. If the size is greater, the image is centered.
function uiGraphics.quadShrinkOrCenterXYWH(tex_quad, x, y, w, h)
	local sx = math.max(0, math.min(1, w / tex_quad.w))
	local sy = math.max(0, math.min(1, h / tex_quad.h))

	local ox = math.floor((w - tex_quad.w * sx) * 0.5)
	local oy = math.floor((h - tex_quad.h * sy) * 0.5)

	_draw(tex_quad.texture, tex_quad.quad, x + ox, y + oy, 0, sx, sy)
end


--- Draws a textured quad, stretched to an arbitrary width and height. Assumes the quad is a 1x1 pixel.
function uiGraphics.quad1x1(tex_quad, x, y, w, h)
	_draw(tex_quad.texture, tex_quad.quad, x, y, 0, w, h)
end


-- Draws a stretched quad as a line segment between two points. The quad def's Y offset is used for centering.
function uiGraphics.quadLine(tex_quad, cross_scale, x1, y1, x2, y2)
	-- (This may not scale well with many calls.)
	local r = math.atan2(y2 - y1, x2 - x1)
	local sx = pMath.dist(x1, y1, x2, y2) / tex_quad.w

	_draw(tex_quad.texture, tex_quad.quad, x1, y1, r, sx, cross_scale, 0, tex_quad.oy)
end


-- Draws a stretched quad as a horizontal line segment. The quad def's Y offset is used for vertical centering.
function uiGraphics.quadBarH(tex_quad, cross_scale, x, y, len)
	_draw(tex_quad.texture, tex_quad.quad, x, y, 0, len / tex_quad.w, cross_scale, 0, tex_quad.oy)
end


-- Draws a stretched quad as a vertical line segment. The quad def's X offset is used for horizontal centering.
function uiGraphics.quadBarV(tex_quad, cross_scale, x, y, len)
	_draw(tex_quad.texture, tex_quad.quad, x, y, 0, cross_scale, len / tex_quad.h, tex_quad.ox)
end


function uiGraphics.pipeHorizontal(ps, x, y, len)
	local pad_x = ps.pad_x

	uiGraphics.quadBarH(ps.l_h, 1, x + pad_x, y, len - pad_x*2)

	uiGraphics.quad(ps.t_l, x, y)
	uiGraphics.quad(ps.t_r, x + len, y)
end


function uiGraphics.pipeVertical(ps, x, y, len)
	local pad_y = ps.pad_y

	uiGraphics.quadBarV(ps.l_v, 1, x, y + pad_y, len - pad_y*2)

	uiGraphics.quad(ps.t_t, x, y)
	uiGraphics.quad(ps.t_b, x, y + len)
end


function uiGraphics.pipeRectangle(ps, x, y, w, h)
	local x2, y2 = x + w, y + h

	local pad_x, pad_y = ps.pad_x, ps.pad_y

	uiGraphics.quadBarH(ps.l_h, 1, x + pad_x,  y, w - pad_x*2)
	uiGraphics.quadBarH(ps.l_h, 1, x + pad_x, y2, w - pad_x*2)

	uiGraphics.quadBarV(ps.l_v, 1, x,  y + pad_y, h - pad_y*2)
	uiGraphics.quadBarV(ps.l_v, 1, x2, y + pad_y, h - pad_y*2)

	uiGraphics.quad(ps.j_tl,  x, y)
	uiGraphics.quad(ps.j_tr, x2, y)
	uiGraphics.quad(ps.j_bl,  x, y2)
	uiGraphics.quad(ps.j_br, x2, y2)
end


function uiGraphics.pipePointsV(ps, cap1, cap2, ...)
	local n_args = select("#", ...)

	if n_args < 2 then
		return

	elseif n_args % 2 ~= 0 then
		error("expected even number of variadic arguments")
	end

	-- start cap
	if cap1 then
		local x1, y1, x2, y2 = select(1, ...)
		if y1 == y2 then
			local id = (x1 < x2) and "t_l" or "t_r"
			uiGraphics.quad(ps[id], x1, y1)
		else
			local id = (y1 < y2) and "t_t" or "t_b"
			uiGraphics.quad(ps[id], x1, y1)
		end
	end

	local pad_x, pad_y = ps.pad_x, ps.pad_y

	-- legs
	for i = 1, n_args - 2, 2 do
		local x1, y1, x2, y2, x3, y3 = select(i, ...)

		-- horizontal
		if y1 == y2 then
			local xx1, xx2
			if x1 < x2 then
				xx1, xx2 = x1, x2
			else
				xx1, xx2 = x2, x1
			end

			uiGraphics.quadBarH(ps.l_h, 1, xx1 + pad_x, y1, (xx2-xx1) - pad_x*2)

			-- joints
			if x3 then
				if x2 > x1 then
					if y3 > y2 then
						uiGraphics.quad(ps.j_tr, x2, y2)
					else
						uiGraphics.quad(ps.j_br, x2, y2)
					end
				else
					if y3 > y2 then
						uiGraphics.quad(ps.j_tl, x2, y2)
					else
						uiGraphics.quad(ps.j_bl, x2, y2)
					end
				end
			end
		-- vertical
		else
			local yy1, yy2
			if y1 < y2 then
				yy1, yy2 = y1, y2
			else
				yy1, yy2 = y2, y1
			end

			uiGraphics.quadBarV(ps.l_v, 1, x1, yy1 + pad_y, (yy2-yy1) - pad_y*2)

			-- joints
			if y3 then
				if y2 > y1 then
					if x3 > x2 then
						uiGraphics.quad(ps.j_bl, x2, y2)
					else
						uiGraphics.quad(ps.j_br, x2, y2)
					end
				else
					if x3 > x2 then
						uiGraphics.quad(ps.j_tl, x2, y2)
					else
						uiGraphics.quad(ps.j_tr, x2, y2)
					end
				end
			end
		end
	end

	-- end cap
	if cap2 then
		local x1, y1, x2, y2 = select(n_args - 3, ...)
		if y1 == y2 then
			local id = (x1 < x2) and "t_r" or "t_l"
			uiGraphics.quad(ps[id], x2, y2)
		else
			local id = (y1 < y2) and "t_b" or "t_t"
			uiGraphics.quad(ps[id], x2, y2)
		end
	end
end


function uiGraphics.pipePointsT(ps, cap1, cap2, arr)
	local n_args = #arr
	if n_args < 2 then
		return

	elseif n_args % 2 ~= 0 then
		error("expected even number of variadic arguments")
	end

	-- start cap
	if cap1 then
		local x1, y1, x2, y2 = arr[1], arr[2], arr[3], arr[4]
		if y1 == y2 then
			local id = (x1 < x2) and "t_l" or "t_r"
			uiGraphics.quad(ps[id], x1, y1)
		else
			local id = (y1 < y2) and "t_t" or "t_b"
			uiGraphics.quad(ps[id], x1, y1)
		end
	end

	local pad_x, pad_y = ps.pad_x, ps.pad_y

	-- legs
	for i = 1, n_args - 2, 2 do
		local x1, y1, x2, y2, x3, y3 = arr[i], arr[i + 1], arr[i + 2], arr[i + 3], arr[i + 4], arr[i + 5]

		-- horizontal
		if y1 == y2 then
			local xx1, xx2
			if x1 < x2 then
				xx1, xx2 = x1, x2
			else
				xx1, xx2 = x2, x1
			end

			uiGraphics.quadBarH(ps.l_h, 1, xx1 + pad_x, y1, (xx2-xx1) - pad_x*2)

			-- joints
			if x3 then
				if x2 > x1 then
					if y3 > y2 then
						uiGraphics.quad(ps.j_tr, x2, y2)
					else
						uiGraphics.quad(ps.j_br, x2, y2)
					end
				else
					if y3 > y2 then
						uiGraphics.quad(ps.j_tl, x2, y2)
					else
						uiGraphics.quad(ps.j_bl, x2, y2)
					end
				end
			end
		-- vertical
		else
			local yy1, yy2
			if y1 < y2 then
				yy1, yy2 = y1, y2
			else
				yy1, yy2 = y2, y1
			end

			uiGraphics.quadBarV(ps.l_v, 1, x1, yy1 + pad_y, (yy2-yy1) - pad_y*2)

			-- joints
			if y3 then
				if y2 > y1 then
					if x3 > x2 then
						uiGraphics.quad(ps.j_bl, x2, y2)
					else
						uiGraphics.quad(ps.j_br, x2, y2)
					end
				else
					if x3 > x2 then
						uiGraphics.quad(ps.j_tl, x2, y2)
					else
						uiGraphics.quad(ps.j_tr, x2, y2)
					end
				end
			end
		end
	end

	-- end cap
	if cap2 then
		local x1, y1, x2, y2 = arr[n_args - 3], arr[n_args - 2], arr[n_args - 1], arr[n_args]
		if y1 == y2 then
			local id = (x1 < x2) and "t_r" or "t_l"
			uiGraphics.quad(ps[id], x2, y2)
		else
			local id = (y1 < y2) and "t_b" or "t_t"
			uiGraphics.quad(ps[id], x2, y2)
		end
	end
end


-- * Sprite Objects


uiGraphics.astro_defs = {}
do
	local GFX_PATH = REQ_PATH .. "graphics."
	local defs = uiGraphics.astro_defs

	defs.anim = require(GFX_PATH .. "spr_anim")
	--uiGraphics.newAnim = defs.anim.new -- (anim_def)

	defs.arc = require(GFX_PATH .. "spr_arc")
	--uiGraphics.newArc = defs.arc.new -- (radius, angle1, angle2)

	defs.circle = require(GFX_PATH .. "spr_circle")
	--uiGraphics.newCircle = defs.circle.new -- (radius)

	defs.ellipse = require(GFX_PATH .. "spr_ellipse")
	--uiGraphics.newEllipse = defs.ellipse.new -- (radius_x, radius_y)

	defs.group = require(GFX_PATH .. "spr_group")
	--uiGraphics.newGroup = defs.group.new -- ()

	defs.image = require(GFX_PATH .. "spr_image")
	--uiGraphics.newImage = defs.image.new -- (image, [quad])

	defs.line = require(GFX_PATH .. "spr_line")
	--uiGraphics.newLine = defs.line.new -- (points)

	defs.mesh = require(GFX_PATH .. "spr_mesh")
	--uiGraphics.newMesh = defs.mesh.new -- (mesh)

	defs.points = require(GFX_PATH .. "spr_points")
	--uiGraphics.newPoints = defs.points.new -- (points)

	defs.polygon = require(GFX_PATH .. "spr_polygon")
	--uiGraphics.newPolygon = defs.polygon.new -- (points)

	defs.print = require(GFX_PATH .. "spr_print")
	--uiGraphics.newPrint = defs.print.new -- (text, font)

	defs.rect = require(GFX_PATH .. "spr_rect")
	--uiGraphics.newRect = defs.rect.new -- (w, h)

	defs.slice = require(GFX_PATH .. "spr_slice")
	--uiGraphics.newSlice = defs.slice.new -- (image, slice)

	defs.sprite_batch = require(GFX_PATH .. "spr_sprite_batch")
	--uiGraphics.newSpriteBatch = defs.sprite_batch.new -- (sprite_batch)

	defs.text_batch = require(GFX_PATH .. "spr_text_batch")
	--uiGraphics.newTextBatch = defs.text_batch.new -- (text_batch) -- XXX: naming conflict
end


return uiGraphics
