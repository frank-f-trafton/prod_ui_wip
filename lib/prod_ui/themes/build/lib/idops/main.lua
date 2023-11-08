-- idops demo.
-- See 'README.md' for documentation and license info.

require("demo_libs.test.strict")

--[[
	This demo loads and prepares an ImageData for use as an ImageFont:
		* Assign cut-out transparency to a predetermined color-key
		* Remove optional padding from the separator columns
		* Create three upscaled versions (2x, 3x, 4x), one double-wide, and one double-tall version.

	idops is not complete and not thoroughly tested. I have a few projects in the works that depend on it,
	and I want to keep track of the most recent version, so that's why I've made a repo. You are free to
	use it, but just be aware that the functions may change around when I update it.
--]]


local idops = require("idops")

-- Demo state container
local demo = {}


function love.load(arguments)

	demo.font = love.graphics.newFont(14)

	-- Temporary ImageData
	local i_data = love.image.newImageData("demo_resources/term_thin_var.png")

	-- Grab a few magic pixels from the left column, then overwrite them with the separator color.
	-- x0 y0: Cut-out transparency
	-- (There's at least one image editor that assumes the top-left pixel of PNGs is a transparency key.)
	local t_r, t_g, t_b, t_a = i_data:getPixel(0, 0)

	-- x0 y1: Separator
	local s_r, s_g, s_b, s_a = i_data:getPixel(0, 1)

	-- x0 y2: Optional padding
	local p_r, p_g, p_b, p_a = i_data:getPixel(0, 2)

	-- Overwrite them.
	for y = 0, 2 do
		i_data:setPixel(0, y, s_r, s_g, s_b, s_a)
	end

	-- Replace transparency key with transparent white
	local TR, TG, TB, TA = 1, 1, 1, 0
	idops.replaceRGBA(i_data, t_r, t_g, t_b, t_a, TR, TG, TB, TA)

	-- The optional padding could be converted to transparency to make room for
	-- stuff like drop shadows. For now, let's just convert it to separator columns. 
	idops.replaceRGBA(i_data, p_r, p_g, p_b, p_a, s_r, s_g, s_b, s_a)	

	-- (v0.0.2: Test horizontal crop)
	--i_data = idops.glyphsCropHorizontal(i_data, TR, TG, TB, TA, s_r, s_g, s_b, s_a)
	--i_data = idops.glyphsAddSpacing(i_data, 1, 1, 0, 0, s_r, s_g, s_b, s_a)

	-- Make the ImageFont.
	demo.glyphs = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
	demo.extraspacing = 0
	demo.i_fonts = {}
	demo.i_fonts[1] = love.graphics.newImageFont(i_data, demo.glyphs, demo.extraspacing)

	-- Make some scaled versions of the ImageFont.
	for scale = 2, 4 do
		local scaled = idops.scaleIntegral(i_data, scale, scale)
		demo.i_fonts[scale] = love.graphics.newImageFont(scaled, demo.glyphs, demo.extraspacing * scale)
	end

	-- Make double-wide and double-tall versions, just for the heck of it.
	do
		local scaled = idops.scaleIntegral(i_data, 4, 2)
		demo.i_fonts[5] = love.graphics.newImageFont(scaled, demo.glyphs, demo.extraspacing * 4)
	end
	do
		local scaled = idops.scaleIntegral(i_data, 2, 4)
		demo.i_fonts[6] = love.graphics.newImageFont(scaled, demo.glyphs, demo.extraspacing * 2)
	end

	demo.text = "The quick brown fox jumps over the lazy dog"

	-- We can drop the temp ImageData now.
	i_data:release()
	i_data = nil

	-- Extrude test
	demo.id_ext = love.image.newImageData("demo_resources/extrude!.png")
	for i = 0, 15 do
		idops.extrude(demo.id_ext, 20 - i, 43 - i, 57 + i*2, 11 + i*2)
	end
	demo.img_ext = love.graphics.newImage(demo.id_ext)

	-- Unassociated alpha color bleed test.
	-- No treatment. Shown with nearest neighbor and bilinear filtering to demonstrate the bleeding issue in the latter.
	demo.id_bleed = love.image.newImageData("demo_resources/bleed!.png")
	demo.img_bleed = love.graphics.newImage(demo.id_bleed)
	demo.img_bleed:setFilter("linear", "linear")

	-- The treated image.
	demo.id_bleed2 = love.image.newImageData("demo_resources/bleed!.png")
	idops.bleedRGBToZeroAlpha(demo.id_bleed2, 1)
	demo.img_bleed2 = love.graphics.newImage(demo.id_bleed2)
	demo.img_bleed2:setFilter("linear", "linear")

	-- Visualization of the treated image with alpha forced to 1 on all pixels.
	demo.id_bleed3 = demo.id_bleed2:clone()
	idops.forceAlpha(demo.id_bleed3, 1.0)
	demo.img_bleed3 = love.graphics.newImage(demo.id_bleed3)
	demo.img_bleed3:setFilter("nearest", "nearest")

	-- Visualization of the untreated image with alpha forced to 1.
	demo.id_bleed4 = demo.id_bleed:clone()
	idops.forceAlpha(demo.id_bleed4, 1.0)
	demo.img_bleed4 = love.graphics.newImage(demo.id_bleed4)
	demo.img_bleed4:setFilter("nearest", "nearest")
end


function love.keypressed(kc, sc)
	if sc == "escape" then
		love.event.quit()
	end
end


local bl_sx = 1
local bl_sy = 1
local time = 0


function love.update(dt)

	time = time + dt
	bl_sx = math.abs(math.sin(time)) * 2
	bl_sy = bl_sx
end


function love.draw()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.translate(16, 16)

	for i = 1, #demo.i_fonts do
		local fnt = demo.i_fonts[i]
		love.graphics.setFont(fnt)
		love.graphics.print(demo.text, 0, 0)
		love.graphics.translate(0, fnt:getHeight() + 16)
	end

	love.graphics.origin()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(demo.img_ext, love.graphics.getWidth() - demo.img_ext:getWidth(), love.graphics.getHeight() - demo.img_ext:getHeight())

	local x_offset = 0
	local y_offset = love.graphics.getHeight() - demo.img_bleed:getHeight()
	local y_offset_labels = y_offset - demo.img_bleed:getHeight() - demo.font:getHeight()

	love.graphics.setFont(demo.font)

	love.graphics.print("* Alpha bleed tests:", 0, y_offset_labels - demo.font:getHeight()*2)

	love.graphics.print("Untreated; bilinear", x_offset, y_offset_labels)
	demo.img_bleed:setFilter("linear", "linear")
	love.graphics.draw(
		demo.img_bleed,
		x_offset + demo.img_bleed:getWidth(),
		y_offset,
		0,
		bl_sx,
		bl_sy,
		demo.img_bleed:getWidth()/2,
		demo.img_bleed:getHeight()/2
	)

	x_offset = x_offset + demo.img_bleed:getWidth() * 2

	love.graphics.print("Untreated; nearest", x_offset, y_offset_labels)
	demo.img_bleed:setFilter("nearest", "nearest")
	love.graphics.draw(
		demo.img_bleed,
		x_offset + demo.img_bleed:getWidth(),
		y_offset,
		0,
		bl_sx,
		bl_sy,
		demo.img_bleed:getWidth()/2,
		demo.img_bleed:getHeight()/2
	)

	x_offset = x_offset + demo.img_bleed:getWidth() * 2

	love.graphics.print("Treated; bilinear", x_offset, y_offset_labels)
	love.graphics.draw(
		demo.img_bleed2,
		x_offset + demo.img_bleed2:getWidth(),
		y_offset,
		0,
		bl_sx,
		bl_sy,
		demo.img_bleed2:getWidth()/2,
		demo.img_bleed2:getHeight()/2
	)

	x_offset = x_offset + demo.img_bleed3:getWidth() * 2

	love.graphics.print("Treated vs untreated", x_offset, y_offset_labels)

	-- Alternate between treated and untreated visualizations.
	local img = demo.img_bleed3
	if time % 2 <= 1 then
		img = demo.img_bleed4
	end
	love.graphics.draw(
		img,
		x_offset + demo.img_bleed3:getWidth(),
		y_offset,
		0,
		2,
		2,
		demo.img_bleed3:getWidth()/2,
		demo.img_bleed3:getHeight()/2
	)
end

