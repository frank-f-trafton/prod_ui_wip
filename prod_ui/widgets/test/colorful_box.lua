-- A non-interactive box with some color options. Used for testing layout code.


local def = {}


local context = select(1, ...)


local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


-- For convenience...
def.colors = {
	transparent  = {0.00, 0.00, 0.00, 0.00},

	black        = {0.00, 0.00, 0.00, 1.00},
	darkgrey     = {0.18, 0.18, 0.18, 1.00},
	grey         = {0.55, 0.55, 0.55, 1.00},
	lightgrey    = {0.81, 0.81, 0.81, 1.00},
	white        = {1.00, 1.00, 1.00, 1.00},

	lightred     = {0.90, 0.40, 0.40, 1.00},
	lightgreen   = {0.40, 0.90, 0.40, 1.00},
	lightblue    = {0.40, 0.40, 0.90, 1.00},
	lightcyan    = {0.40, 0.78, 0.78, 1.00},
	lightmagenta = {0.78, 0.40, 0.78, 1.00},
	lightyellow  = {0.78, 0.78, 0.40, 1.00},

	red          = {0.90, 0.10, 0.10, 1.00},
	green        = {0.10, 0.90, 0.10, 1.00},
	blue         = {0.10, 0.10, 0.90, 1.00},
	cyan         = {0.10, 0.78, 0.78, 1.00},
	magenta      = {0.78, 0.10, 0.78, 1.00},
	yellow       = {0.78, 0.78, 0.10, 1.00},

	darkred      = {0.60, 0.05, 0.05, 1.00},
	darkgreen    = {0.05, 0.60, 0.05, 1.00},
	darkblue     = {0.05, 0.05, 0.60, 1.00},
	darkcyan     = {0.05, 0.53, 0.53, 1.00},
	darkmagenta  = {0.53, 0.05, 0.05, 1.00},
	darkyellow   = {0.53, 0.53, 0.05, 1.00},
}


function def:uiCall_initialize()
	self.visible = true

	self.fill = self.colors.darkcyan
	self.outline = self.colors.yellow
	self.text = false -- false, string, table (LÖVE coloredtext)
	self.text_lines = 0
	self.text_color = self.colors.black
end


local err_str_col = "invalid color ID."


function def:setColor(fill, outline, text_color)
	if fill then
		self.fill = self.colors[fill] or error(err_str_col)
	end
	if outline then
		self.outline = self.colors[outline] or error(err_str_col)
	end
	if text_color then
		self.text_color = self.colors[text_color] or error(err_str_col)
	end
end


function def:setText(text)
	uiAssert.typesEval(1, text, "string", "table")

	self.text = text or false

	if text then
		self.text_lines = textUtil.countStringPatterns(text, "\n", true) + 1
	end
end


function def:render(ox, oy)
	love.graphics.push("all")

	uiGraphics.intersectScissor(self.x + ox, self.y + oy, self.w, self.h)

	love.graphics.setColor(self.fill)
	love.graphics.rectangle("fill", 0, 0, self.w, self.h)

	love.graphics.setColor(self.outline)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineJoin("miter")
	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)

	if self.text then
		local font = context.resources.fonts.internal
		love.graphics.setFont(font)
		love.graphics.setColor(self.text_color)
		local h = font:getHeight() * self.text_lines
		love.graphics.printf(self.text, 0, math.floor((self.h - h) / 2), self.w, "center")
	end

	love.graphics.pop()
end


return def
