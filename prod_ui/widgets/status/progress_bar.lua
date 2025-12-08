--[[
A skinned progress bar.

XXX gradual update support via evt_update() and a target position.
--]]


local def = {
	skin_id = "progress_bar1",
}


local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcLabel = context:getLua("shared/wc/wc_label")
local widShared = context:getLua("core/wid_shared")


-- Called when the internal progress counter or maximum value change.
function def:wid_barChanged(old_pos, old_max, new_pos, new_max)
	-- Warning: Do not call self:setCounter() or self:setCounterMax() from within this function.
	-- It will overflow the stack.
end


--- Sets the progress bar's active state.
-- @param active True to be active, false/nil to be inactive.
function def:setActive(active)
	self.active = not not active
end


def.setLabel = wcLabel.widSetLabel


--- Sets the progress bar's current position, and optionally the maximum value.
-- @param pos The position value. Clamped between 0 and max.
-- @param max The maximum value. Clamped to 0 on the low end.
function def:setCounter(pos, max)
	uiAssert.numberNotNaN(1, pos)
	uiAssert.numberNotNaNEval(2, max)

	local old_pos = self.pos
	local old_max = self.max

	if max then
		self.max = math.max(0, max)
	end

	self.pos = math.max(0, math.min(pos, self.max))

	if old_pos ~= self.pos or old_max ~= self.max then
		self:wid_barChanged(self.pos, self.max, old_pos, old_max)
	end
end


function def:getCounter()
	return self.pos, self.max
end


function def:evt_initialize()
	self.visible = true

	widShared.setupViewports(self, 2)

	-- Horizontal or vertical orientation.
	self.vertical = false

	-- true: start from the right/bottom side.
	self.far_end = false

	wcLabel.setup(self)

	-- Should appear greyed out when not active.
	self.active = false

	-- Internal position and max values.
	self.pos = 0
	self.max = 0

	-- Appearance of progress in pixels per second. Set it to a very high number
	-- to make it look instantaneous.
	--self.slide_speed = 2^16

	self:skinSetRefs()
	self:skinInstall()

	self:reshape()
end


function def:evt_reshapePre()
	-- Viewport #1 is the label bounding box.
	-- Viewport #2 is the progress bar drawing rectangle.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)
	vp:splitOrOverlay(vp2, skin.bar_placement, skin.bar_spacing)
	vp:reduceT(skin.box.margin)

	wcLabel.reshapeLabel(self)

	return true
end


function def:evt_destroy(targ)
	if self == targ then
		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	color_back = uiAssert.loveColorTuple,
	color_ichor = uiAssert.loveColorTuple,
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

		-- Placement of the progress bar in relation to text labels.
		bar_placement = {uiAssert.oneOf, "left", "right", "top", "bottom", "overlay"},

		-- How much space to assign the progress bar when not using "overlay" placement.
		bar_spacing = uiAssert.integer,

		slc_back = themeAssert.slice,
		slc_ichor = themeAssert.slice,

		res_active = md_res,
		res_inactive = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "bar_spacing")

		local function _changeRes(scale, res)
			uiScale.fieldInteger(scale, res, "label_ox")
			uiScale.fieldInteger(scale, res, "label_oy")
		end

		_changeRes(scale, skin.res_active)
		_changeRes(scale, skin.res_inactive)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp2 = self.vp2
		local res = (self.active) and skin.res_active or skin.res_inactive

		-- Progress bar back-panel.
		local slc_back = skin.slc_back
		love.graphics.setColor(res.color_back)
		uiGraphics.drawSlice(skin.slc_back, 0, 0, self.w, self.h)

		-- Progress bar ichor.
		if self.pos > 0 and self.max > 0 then
			-- Orientation.
			local px, py, pw, ph
			if self.vertical then
				pw = vp2.w
				px = vp2.x
				ph = math.max(0, math.floor(0.5 + (self.pos / self.max * (vp2.h))))
				py = self.far_end and vp2.y + vp2.h - ph or vp2.y
			else
				pw = math.max(0, math.floor(0.5 + (self.pos / self.max * (vp2.w))))
				px = self.far_end and vp2.x + vp2.w - pw or vp2.x
				ph = vp2.h
				py = vp2.y
			end

			local slc_ichor = skin.slc_ichor
			love.graphics.setColor(res.color_ichor)
			uiGraphics.drawSlice(slc_ichor, px, py, pw, ph)
		end

		if self.label_mode then
			wcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
		end
	end,
}


return def
