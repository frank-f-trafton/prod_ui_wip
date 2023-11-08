-- To load: local lib = context:getLua("shared/lib")

--[[
Barebones version of lgcLabel. Supports only single-line text (no underlines) with one default font.
--]]


local context = select(1, ...)


local lgcLabelBare = {}


local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


function lgcLabelBare.setup(self)
	self.label = ""
end


function lgcLabelBare.remove(self)
	self.label = nil
end


function lgcLabelBare.widSetLabel(self, text)

	-- Assertions
	-- [[
	uiShared.assertText(2, text)
	--]]

	self.label = text
end


--- Draws a widget's label text.
function lgcLabelBare.render(self, font, r, g, b, a)

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


return lgcLabelBare
