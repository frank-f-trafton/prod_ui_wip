--[[
A plain skinned label with an optional 9-slice body.
--]]


local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcLabel = context:getLua("shared/wc/wc_label")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "label1",
}


def.setLabel = wcLabel.widSetLabel


function def:uiCall_initialize()
	self.visible = true

	widShared.setupViewports(self, 1)

	wcLabel.setup(self)

	self:skinSetRefs()
	self:skinInstall()

	-- "enabled" affects visual style.
	self.enabled = true

	self:reshape()
end


function def:uiCall_reshapePre()
	local vp = self.vp

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(self.skin.box.border)

	wcLabel.reshapeLabel(self)

	return true
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 1)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	-- Optional body slice and color
	sl_body = themeAssert.sliceEval,
	color_body = uiAssert.loveColorTupleEval,

	color_label = uiAssert.loveColorTuple,

	label_ox = uiAssert.integer,
	label_oy = uiAssert.integer
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		label_style = themeAssert.labelStyle,
		tq_px = themeAssert.quad,

		-- Alignment of label text in Viewport #1.
		label_align_h = {uiAssert.namedMap, uiTheme.named_maps.label_align_h},
		label_align_v = {uiAssert.namedMap, uiTheme.named_maps.label_align_v},

		res_idle = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "label_ox")
			uiScale.fieldInteger(scale, res, "label_oy")
		end

		_changeRes(scale, skin.res_idle)
		_changeRes(scale, skin.res_disabled)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function (self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local res = (self.enabled) and skin.res_idle or skin.res_disabled

		local slc_body = res.sl_body
		if slc_body then
			love.graphics.setColor(res.color_body)
			uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)
		end

		if self.label_mode then
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
