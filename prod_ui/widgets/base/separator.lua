local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcPipe = context:getLua("shared/wc/wc_pipe")


local pipe_styles = context.resources.pipe_styles


local def = {
	skin_id = "separator1",
}


wcPipe.attachMethods(def)


local _nm_axis2d = uiTheme.named_maps.axis_2d


function def:setAxis(axis)
	uiAssert.namedMap(1, axis, _nm_axis2d)

	self.axis = axis

	self:reshape()
end


function def:getAxis()
	return self.axis
end


function def:evt_initialize()
	self.visible = true

	self.axis = "x"

	-- Updated during reshape:
	self.x1 = 0
	self.y1 = 0
	self.len = 0

	self:skinSetRefs()
	self:skinInstall()

	self.PIPE_id = self.skin.default_pipe_id
end


function def:evt_reshapePre()
	local skin = self.skin
	local p_st = pipe_styles[self.PIPE_id]

	if p_st then
		if self.axis == "x" then
			self.x1 = p_st.sep_l
			self.y1 = math.floor(self.h / 2)
			self.len = math.floor(self.w - p_st.sep_l - p_st.sep_r)
		else -- axis == "y"
			self.x1 = math.floor(self.w / 2)
			self.y1 = p_st.sep_t
			self.len = math.floor(self.h - p_st.sep_t - p_st.sep_b)
		end
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		default_pipe_id = themeAssert.pipeStyleID,
		pipe_color = uiAssert.loveColorTuple
	},


	--transform = function(scale, skin)


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local pipe_id = self.PIPE_id
		if pipe_id then
			local skin = self.skin
			local p_st = pipe_styles[pipe_id]
			if not p_st then
				error("missing or invalid PipeStyle: " .. tostring(pipe_id))
			end

			local r, g, b, a  = love.graphics.getColor()
			love.graphics.setColor(skin.pipe_color)

			if self.axis == "x" then
				uiGraphics.pipeHorizontal(p_st, self.x1, self.y1, self.len)
			else -- axis == "y"
				uiGraphics.pipeVertical(p_st, self.x1, self.y1, self.len)
			end

			love.graphics.setColor(r, g, b, a)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
