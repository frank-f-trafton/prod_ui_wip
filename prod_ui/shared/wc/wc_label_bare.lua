-- To load: local lib = context:getLua("shared/lib")

--[[
Barebones version of wcLabel. Supports only single-line text (no underlines) with one default font.
--]]


local context = select(1, ...)


local wcLabelBare = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")


function wcLabelBare.setup(self)
	self.label = ""
end


function wcLabelBare.remove(self)
	self.label = nil
end


function wcLabelBare.widSetLabel(self, text)
	uiAssert.loveStringOrColoredText(2, text)

	self.label = text

	return self
end


--- Draws a widget's label text.
function wcLabelBare.render(self, font, r, g, b, a)
	love.graphics.push("all")

	if self.label then
		love.graphics.setColor(r, g, b, a)
		love.graphics.setFont(font)
		love.graphics.printf(
			self.label,
			0,
			math.floor((self.h - font:getHeight() * font:getLineHeight()) * 0.5),
			self.w,
			"center"
		)
	end

	love.graphics.pop()
end


return wcLabelBare
