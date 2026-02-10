--[[
A basic styled container, intended to hold control widgets.
Does not scroll, handle direct user input, or accept thimble focus.

┌──── Group Name ────┐
│ ( ) Radio 1        │
│ (x) Radio 2        │
│ ( ) Radio Red      │
│ ( ) Radio Blue     │
└────────────────────┘
--]]


local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcPipe = context:getLua("shared/wc/wc_pipe")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "group1"
}


local _nm_group_label_side = uiTable.newNamedMapV("GroupLabelSide", "left", "center", "right")


local _nm_group_deco_style = uiTable.newNamedMapV("GroupDecorationStyle",
	"none",
	"outline",
	"outline-label",
	"header",
	"header-label",
	"underline-label",
	"underline-label-wide",
	"label"
)


wcPipe.attachMethods(def)


widLayout.setupContainerDef(def)


function def:setDecorationStyle(style)
	uiAssert.namedMapEval(1, style, _nm_group_deco_style)

	self.S_deco_style = style or false
	self.deco_style = self.S_deco_style or self.skin.default_deco_style

	self:reshape()

	return self
end


function def:getDecorationStyle()
	return self.S_deco_style
end


function def:setLabelSide(side)
	uiAssert.namedMapEval(1, side, _nm_group_label_side)

	self.S_label_side = side or false
	self.label_side = self.S_label_side or self.skin.default_label_side

	self:reshape()

	return self
end


function def:getLabelSide()
	return self.S_label_side
end


function def:setText(text)
	uiAssert.type(1, text, "string")

	self.text = text

	self:reshape()

	return self
end


function def:getText()
	return self.text
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true

	widShared.setupViewports(self, 3)
	widLayout.setupLayoutList(self)

	wcPipe.setupInstance(self) -- S_PIPE_id, PIPE_id, PIPE_style

	self.S_deco_style = false
	self.S_label_side = false

	self.text = ""
	self.enabled = true -- TODO

	self.deco_style = "outline-label"
	self.label_side = "center"

	self.text_x, self.text_w = 0, 0

	self:layoutSetBase("viewport-full")

	self:skinSetRefs()
	self:skinInstall()
end


function def:evt_reshapePre()
	-- Viewport #1 is for widget controls.
	-- Viewport #2 represents the outline of the graphical border.
	-- Viewport #3 represents the edges of the border against the label text,
	-- plus the text Y position.

	local skin = self.skin
	local box = skin.box
	local vp, vp2, vp3 = self.vp, self.vp2, self.vp3
	local font = skin.font

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(box.border)
	vp:copy(vp2)
	vp:split(vp3, "top", font:getHeight())
	vp:reduceTop(skin.label_pad_y)
	vp2:reduceTop(math.floor(font:getHeight() / 2))
	vp3:expandBottom(skin.label_pad_y)
	vp:reduceT(box.margin)

	self.text_w = font:getWidth(self.text)

	local label_side = self.label_side
	if label_side == "left" then
		self.text_x = vp2.x + skin.label_pad_far

	elseif label_side == "right" then
		self.text_x = vp2.x + vp2.w - self.text_w - skin.label_pad_far

	else -- "center"
		self.text_x = math.floor(vp2.x + ((vp2.w - self.text_w) / 2))
	end

	vp3.x, vp3.w = self.text_x - skin.label_pad_x1, self.text_w + skin.label_pad_x1 + skin.label_pad_x2

	widLayout.resetLayoutSpace(self)
end


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ then
		-- Try directing thimble1 to the container's UI Frame ancestor.
		if button <= 3 then
			local wid = self
			while wid do
				if wid.frame_type then
					break
				end
				wid = wid.parent
			end
			if wid then
				wid:tryTakeThimble1()
			end
		end
	end
end


function def:evt_destroy(targ)
	if self == targ then
		widShared.removeViewports(self, 3)
	end
end


-- args: (self, ox, oy)
local _style_renderers = {
	["none"] = function()
		-- n/a
	end,

	["outline"] = function(self)
		local skin, vp2 = self.skin, self.vp2

		love.graphics.setColor(skin.color_pipe)

		local p_st = self.PIPE_style
		uiGraphics.pipeRectangle(p_st, vp2.x, vp2.y, vp2.w, vp2.h)
	end,

	["outline-label"] = function(self)
		local skin, vp2, vp3 = self.skin, self.vp2, self.vp3

		love.graphics.setColor(skin.color_pipe)

		local x1, y1, w, h = vp2.x, vp2.y, vp2.w, vp2.h
		local x2, y2 = x1 + w, y1 + h

		local p_st = self.PIPE_style
		uiGraphics.pipePointsV(p_st, true, true,
			vp3.x, y1,
			x1, y1,
			x1, y2,
			x2, y2,
			x2, y1,
			vp3.x + vp3.w, y1
		)

		love.graphics.setFont(skin.font)
		love.graphics.setColor(skin.color_text)
		love.graphics.print(self.text, self.text_x, vp3.y)
	end,

	["header"] = function(self)
		local skin, vp2, vp3 = self.skin, self.vp2, self.vp3

		love.graphics.setColor(skin.color_pipe)

		local x, y, w = vp2.x, vp2.y, vp2.w

		local p_st = self.PIPE_style
		uiGraphics.pipeHorizontal(p_st, x, y, w)
	end,

	["header-label"] = function(self)
		local skin, vp2, vp3 = self.skin, self.vp2, self.vp3

		love.graphics.setColor(skin.color_pipe)

		local y = vp2.y
		local w2 = vp2.x + vp2.w - (vp3.x + vp3.w)

		local p_st = self.PIPE_style
		uiGraphics.pipeHorizontal(p_st, vp2.x, y, vp3.x - vp2.x)
		uiGraphics.pipeHorizontal(p_st, vp3.x + vp3.w, y, w2)

		love.graphics.setFont(skin.font)
		love.graphics.setColor(skin.color_text)
		love.graphics.print(self.text, self.text_x, vp3.y)
	end,

	["underline-label"] = function(self)
		local skin, vp2, vp3 = self.skin, self.vp2, self.vp3

		love.graphics.setColor(skin.color_pipe)

		local x, y, w = self.text_x, vp3.y + vp3.h, self.text_w

		local p_st = self.PIPE_style
		uiGraphics.pipeHorizontal(p_st, x, y, w)

		love.graphics.setFont(skin.font)
		love.graphics.setColor(skin.color_text)
		love.graphics.print(self.text, self.text_x, vp3.y)
	end,

	["underline-label-wide"] = function(self)
		local skin, vp2, vp3 = self.skin, self.vp2, self.vp3

		love.graphics.setColor(skin.color_pipe)

		local x, y, w = vp2.x, vp3.y + vp3.h, vp2.w

		local p_st = self.PIPE_style
		uiGraphics.pipeHorizontal(p_st, x, y, w)

		love.graphics.setFont(skin.font)
		love.graphics.setColor(skin.color_text)
		love.graphics.print(self.text, self.text_x, vp3.y)
	end,

	["label"] = function(self)
		local skin, vp3 = self.skin, self.vp3

		love.graphics.setFont(skin.font)
		love.graphics.setColor(skin.color_text)
		love.graphics.print(self.text, self.text_x, vp3.y)
	end
}


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		font = themeAssert.font,

		PIPE_default_id = themeAssert.pipeStyleID,
		default_deco_style = {uiAssert.namedMap, _nm_group_deco_style},
		default_label_side = {uiAssert.namedMap, _nm_group_label_side},

		-- Padding when label_side is "left" or "right".
		-- Not used with "center"
		label_pad_far = {uiAssert.numberGE, 0},

		label_pad_x1 = {uiAssert.numberGE, 0},
		label_pad_x2 = {uiAssert.numberGE, 0},
		label_pad_y = {uiAssert.numberGE, 0},

		color_text = uiAssert.loveColorTuple,
		color_pipe = uiAssert.loveColorTuple,
	},


	--transform = function(scale, skin)


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		-- wcPipe
		uiTheme.checkDefault(self, "S_PIPE_id", "PIPE_id", skin.PIPE_default_id)
		wcPipe.refreshReferences(self)

		uiTheme.checkDefault(self, "S_deco_style", "deco_style", skin.default_deco_style)
		uiTheme.checkDefault(self, "S_label_side", "label_side", skin.default_label_side)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		love.graphics.push("all")

		_style_renderers[self.deco_style](self, ox, oy)

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy)
}


return def
