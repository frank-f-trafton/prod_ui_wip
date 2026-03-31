-- A simple (non-scrolling) container with a QuadSlice background.


local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local slices = context.resources.slices


local def = {
	skin_id = "container_panel1"
}


widLayout.setupContainerDef(def)


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true

	widShared.setupViewports(self, 2)
	widLayout.setupLayoutList(self)
	self:layoutSetBase("viewport-full")

	self.S_slc_id = false
	self.slc_id = false
	self.slc = false

	self:skinSetRefs()
	self:skinInstall()
end


local function _refreshReferences(self)
	local slc_id = self.slc_id
	local slc = slices[slc_id]

	if not slc then
		error("unprovisioned QuadSlice: " .. tostring(slc_id))
	end
	self.slc = slc
end


function def:setSliceId(id)
	uiAssert.typeEval(1, id, "string")
	if uiTable.setDouble(self, "S_slc_id", "slc_id", id, self.skin.default_slc_id) then
		_refreshReferences(self)
		self:reshape()
	end

	return self
end


function def:getSliceId()
	return self.slc_id
end


function def:evt_getGrowAxisLength(x_axis, cross_length)
	if not x_axis then
		local scale = context.scale

		local h = 0

		for i, child in ipairs(self.LO_list) do
			local len, do_scale = child:evt_getGrowAxisLength(x_axis, cross_length)
			if len then
				local this_scale = do_scale and scale or 1.0
				h = h + len * this_scale
			end
		end

		local my1, my2 = self.LO_margin_y1, self.LO_margin_y2
		h = h + my1 + my2

		return h, false
	end
end


function def:evt_reshapePre()
	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

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
		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,

		default_slc_id = themeAssert.sliceID,
		color_body = uiAssert.loveColorTuple,
	},


	--transform = function(scale, skin)


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		uiTable.updateDouble(self, "S_slc_id", "slc_id", skin.default_slc_id)
		_refreshReferences(self)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp = self.vp

		love.graphics.push("all")

		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(self.slc, vp.x, vp.y, vp.w, vp.h)

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy)
}


return def
