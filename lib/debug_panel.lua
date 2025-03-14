-- Draws a non-interactive panel of text with QuickPrint.

--[[

1) Create the Debug Panel object:

	local dpanel = debugPanel.new(300, love.graphics.newFont(14))
	-- See function for changing colors


2) Write the text to QuickPrint in love.update() or love.draw():

	qp:reset()
	qp.text_object:clear()
	qp:print("abc")
	qp:down()
	qp:print("def")


3) Draw the Debug Panel in love.draw():

	dpanel:draw(32, 32)


Notes:

If you must change the TextBatch font (dpanel.text_object:setFont()), do so before qp:reset().

Avoid resetting or changing the origin while writing, as it will mess up the debug panel's method of
determining the height of the panel to draw.
--]]


local debugPanel = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local quickPrint = require(REQ_PATH .. "quick_print")


local love_major, love_minor = love.getVersion()


local _mt_debug_panel = {}
_mt_debug_panel.__index = _mt_debug_panel


function debugPanel.new(w, font)
	assert(type(w) == "number", "arg #1: expected number.")
	assert(type(font) == "userdata", "arg #2: expected userdata (LÖVE Font).")

	local self = setmetatable({
		x = 0, y = 0,
		w = w,
		last_h = 0,
		x_pad = 16, y_pad = 16,
		corner_radius = 8,

		-- Background color
		r1 = 0, g1 = 0, b1 = 0, a1 = 0.8,

		-- Text color
		r2 = 1, g2 = 1, b2 = 1, a2 = 1,

		qp = quickPrint.new(),
	}, _mt_debug_panel)

	local text_object = love_major >= 12 and love.graphics.newTextBatch(font) or love.graphics.newText(font)
	self.qp:setTextObject(text_object)

	return self
end


function _mt_debug_panel:draw()
	local qp = self.qp
	self.last_h = qp.y2

	love.graphics.push("all")

	love.graphics.setScissor(self.x, self.y, self.w + self.x_pad*2, self.last_h + self.y_pad*2)

	love.graphics.setColor(self.r1, self.g1, self.b1, self.a1)
	love.graphics.rectangle("fill", self.x, self.y, self.w + self.x_pad*2, self.last_h + self.y_pad*2, self.corner_radius, self.corner_radius)

	love.graphics.setColor(self.r2, self.g2, self.b2, self.a2)
	love.graphics.draw(self.qp.text_object, self.x + self.x_pad, self.y + self.y_pad)

	love.graphics.pop()
end


return debugPanel