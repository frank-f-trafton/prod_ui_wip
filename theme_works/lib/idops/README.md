**NOTE:** This is a beta. Version: 0.0.5

# idops.lua

Idops (ImageData Operations) contains some utility functions for working with LÖVE ImageData objects, particularly those intended to be used as ImageFonts.


## Functions

### idops.pasteScaled

Pastes the contents of one ImageData into another, with some basic scaling support (nearest neighbor only). The paste region is always at least 1x1 in size.

`idops.pasteScaled(src, dst, scale_x, scale_y, src_x, src_y, src_w, src_h, dst_x, dst_y)`

* `src`: The source ImageData.

* `dst`: The destination ImageData.

* `scale_x`: *(1)* The pasted X scale.

* `scale_y`: *(1)* The pasted Y scale.

* `src_x`: *(0)* Top-left X position in the source ImageData.

* `src_y`: *(0)* Top-left Y position in the source ImageData.

* `src_w`: *(src:getWidth())* How many pixels to copy from src_x.

* `src_h`: *(src:getHeight())* How many pixels to copy from src_y.

* `dst_x`: *(0)* Top-left X position in the destination ImageData.

* `dst_y`: *(0)* Top-left Y position in the destination ImageData.


### idops.scaleIntegral

Returns a scaled copy of ImageData `src` by integral amounts (2x, 3x, etc.)

`idops.scaleIntegral(src, sw, sh)`

* `src`: The source ImageData to use.

* `sw`: The new horizontal scale. Must be an integer >= 1.

* `sh`: The new vertical scale. Must be an integer >= 1.


**Returns:** The scaled ImageData.


### idops.replaceRGBA

Replaces pixels containing one RGBA color with a different color.

`idops.replaceRGBA(src, r1, g1, b1, a1, r2, g2, b2, a2)`

* `src`: The ImageData to modify.

* `r1`, `g1`, `b1`, `a1`: The target RGBA value. Color components are in the range of 0.0 to 1.0.

* `r2`, `g2`, `b2`, `a2`: The replacement RGBA value.


### idops.replaceRGB

Like `idops.replaceRGBA()`, but does not check or modify the alpha channel.

`idops.replaceRGB(src, r1, g1, b1, r2, g2, b2)`

* `src`: The ImageData to modify.

* `r1`, `g1`, `b1`: The target RGB value to check. Color components are in the range of 0.0 to 1.0.

* `r2`, `g2`, `b2`: The replacement RGB value.


### idops.addDropShadow

Adds a basic drop shadow to an ImageData. Intended for ImageFonts.

`idops.addDropShadow(src, ox, oy, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)`

* `src`:  The ImageData to modify.

* `ox`, `oy`: Shadow X and Y pixel offsets.

* `tr`, `tg`, `tb`, `ta`: Transparency color key. Shadows will be applied to pixels with this color only.

* `sr`, `sg`, `sb`, `sa`: Shadow color.

* `ignore_t`: *(Optional)* Table of tables (ie `{{1, 0, 0, 1}, {0, 1, 0, 1}, etc.}`), specifying colors which should not be treated as casting shadows. In an ImageFont graphic, you'd pass the separator color here. Note that it's a linear search, so adding several color tables could slow down the procedure.


### idops.addOutline4

Adds a basic outline by running `idops.addDropShadow()` to the top, bottom, left, and right neighbors of each eligible pixel.

`idops.addOutline4(src, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)`

* `src`: The ImageData to modify.

* `tr`, `tg`, `tb`, `ta`: Transparency color key. The outline will be applied to these pixels only.

* `sr`, `sg`, `sb`, `sa`: Outline color.

* `ignore_t`: *(Optional)* Table of tables (ie `{{1, 0, 0, 1}, {0, 1, 0, 1}, etc.}`), specifying colors which should not be treated as possible outline contours. Note that it's a linear search, so adding several color tables could slow down the procedure.


### idops.addOutline8

Like `idops.addOutline4()`, but applies the drop-shadow function to all eight neighbors of every eligible pixel.

`idops.addOutline8(src, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)`

* `src`: The ImageData to modify.

* `tr`, `tg`, `tb`, `ta`: Transparency color key. The outline will be applied to these pixels only.

* `sr`, `sg`, `sb`, `sa`: Outline color.

* `ignore_t`: *(Optional)* Table of tables (ie `{{1, 0, 0, 1}, {0, 1, 0, 1}, etc.}`), specifying colors which should not be treated as possible outline contours. Note that it's a linear search, so adding several color tables could slow down the procedure.


### idops.glyphsAddSpacing

Given an ImageData [formatted for use as an ImageFont](https://love2d.org/wiki/ImageFontFormat), copy each glyph to a new ImageData with additional spacing.

`idops.glyphsAddSpacing(src, pad_left, pad_right, pad_top, pad_bottom, sr, sg, sb, sa)`

* `src`: The source ImageData.

* `pad_left`: How many pixel columns to add to the left of each glyph. Must be >= 0.

* `pad_right`: Columns to add to the right of each glyph. Must be >= 0.

* `pad_top`: Rows to add to the top of the entire ImageData. Must be >= 0.

* `pad_bottom`: Rows to add to the bottom of the entire ImageData. Must be >= 0.

* `sr`, `sg`, `sb`, `sa`: Spacer color key. If not provided, the function will use the RGBA value of the top-left pixel of `src`.


**Returns:** A new ImageData with padded glyphs.


### idops.glyphsCropHorizontal

Given an ImageData [formatted for use as an ImageFont](https://love2d.org/wiki/ImageFontFormat), return a new ImageData with empty horizontal columns trimmed out of glyphs which contain at least one non-background pixel. (Glyphs containing only background pixels, for example "space", are not trimmed.)

`idops.glyphsCropHorizontal(src, sr, sg, sb, sa, tr, tg, tb, ta)`

* `src`: The source ImageData.

* `sr`, `sg`, `sb`, `sa`: (Optional) Color key of the spacer that separates glyphs. If `sr` is not provided, the color in the top-left pixel of `src` will be used instead.

* `tr`, `tg`, `tb`, `ta`: Color key of the cut-out transparency (or "background").


**Returns:** A new ImageData with glyphs cropped horizontally.


### idops.extrude

Extrudes a rectangular portion of an ImageData by copying its edge colors outward by one pixel.

`idops.extrude(src, x, y, w, h)`

* `src`: The ImageData to modify.

* `x`, `y`, `w`, `h`: The rectangular area to extrude.


### idops.premultiply

Premultiplies the RGB values in an ImageData with the alpha channel.

`idops.premultiply(src, gamma_correct, x, y, w, h)`

* `src`: The ImageData to modify.

* `gamma_correct`: *(false)* When `true`, applies gamma correction when multiplying colors. When `false` or `nil`, does not apply gamma correction.

* `x`, `y`, `w`, `h`: *(full image)* The rectangular region of pixels to premultiply. If `x` is not specified, defaults to the whole ImageData.


### idops.predivide

Predivides ("unpremultiplies") the RGB values in an ImageData with the alpha channel.

`idops.predivide(src, gamma_correct, x, y, w, h)`

* `src`: The ImageData to modify.

* `gamma_correct`: *(false)* When `true`, applies gamma correction when dividing colors. When `false` or `nil`, does not apply gamma correction.

* `x`, `y`, `w`, `h`: *(full image)* The rectangular region of pixels to predivide. If `x` is not specified, defaults to the whole ImageData.


### idops.bleedRGBToZeroAlpha

Copies RGB values from visible pixels into neighboring pixels with zero alpha. Intended to prevent the perception of *alpha bleeding* artifacts when scaling or stretching textures with unassociated (not premultiplied) alpha.

`idops.bleedRGBToZeroAlpha(src, iter, x, y, w, h)`

* `src`: The ImageData to modify.

* `iter`: *(1)* The number of iterations to run.

* `x`, `y`, `w`, `h`: *(full image)* The pixel region of the image to modify. If *x* is not specified, the full image will be used.


**Notes:**

* For each iteration, RGB values from visible pixels are smeared right-to-left, then left-to-right, then bottom-to-top, and finally top-to-bottom. The function is cut short if no pixels were modified during an iteration.

* Calling this function multiple times on the same image and pixel zones will not result in cumulative bleeding. Instead, it will just repeat the same work from the previous call.

* This function is not currently optimized. It will struggle with large images and many iterations.


### idops.forceAlpha

Sets a specific alpha value for pixels in an ImageData. Does not affect RGB values.

`idops.forceAlpha(src, a, x, y, w, h)`

* `src`: The ImageData to modify.

* `a`: The new alpha to set. (Range: 0.0 - 1.0)

* `x`, `y`, `w`, `h`: *(full image)* Optional range arguments for [ImageData:mapPixel](https://love2d.org/wiki/ImageData:mapPixel).


## License

Copyright (c) 2022, 2023 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


