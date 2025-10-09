--[[
A plain skinned label with an optional 9-slice body.
--]]


local context = select(1, ...)


local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "label1",
}


def.setLabel = lgcLabel.widSetLabel


function def:uiCall_initialize()
	self.visible = true

	widShared.setupViewports(self, 1)

	lgcLabel.setup(self)

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

	lgcLabel.reshapeLabel(self)

	return true
end


function def:uiCall_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 1)
	end
end


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)

	-- Optional body slice and color
	if res.sl_body ~= nil then
		check.slice(res, "sl_body")
	end
	if res.color_body ~= nil then
		check.colorTuple(res, "color_body")
	end

	check.colorTuple(res, "color_label")
	check.integer(res, "label_ox")
	check.integer(res, "label_oy")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "label_ox", scale)
	change.integerScaled(res, "label_oy", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.labelStyle(skin, "label_style")
		check.quad(skin, "tq_px")

		-- Alignment of label text in Viewport #1.
		check.enum(skin, "label_align_h")
		check.enum(skin, "label_align_v")

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		_changeRes(skin, "res_idle", scale)
		_changeRes(skin, "res_disabled", scale)
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
			lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
