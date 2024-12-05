--[[
A skinned progress bar.

XXX gradual update support via uiCall_update() and a target position.
--]]


local def = {
	skin_id = "progress_bar1",
}


local context = select(1, ...)


local lgcLabel = context:getLua("shared/lgc_label")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


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


def.setLabel = lgcLabel.widSetLabel


--- Sets the progress bar's current position, and optionally the maximum value.
-- @param pos The position value. Clamped between 0 and max.
-- @param max The maximum value. Clamped to 0 on the low end.
function def:setCounter(pos, max)
	uiShared.numberNotNaN(1, pos)
	uiShared.numberNotNaNEval(2, max)

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


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true

		-- Horizontal or vertical orientation.
		self.vertical = false

		-- true: start from the right/bottom side.
		self.far_end = false

		lgcLabel.setup(self)

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
end


function def:uiCall_reshape()
	-- Viewport #1 is the label bounding box.
	-- Viewport #2 is the progress bar drawing rectangle.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
	widShared.partitionViewport(self, 1, 2, skin.bar_spacing, skin.bar_placement, true)
	widShared.carveViewport(self, 1, "margin")
	lgcLabel.reshapeLabel(self)
end


def.skinners = {
	default = {
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
					pw = self.vp2_w
					px = self.vp2_x
					ph = math.max(0, math.floor(0.5 + (self.pos / self.max * (self.vp2_h))))
					py = self.far_end and self.vp2_y + self.vp2_h - ph or self.vp2_y
				else
					pw = math.max(0, math.floor(0.5 + (self.pos / self.max * (self.vp2_w))))
					px = self.far_end and self.vp2_x + self.vp2_w - pw or self.vp2_x
					ph = self.vp2_h
					py = self.vp2_y
				end

				local slc_ichor = skin.slc_ichor
				love.graphics.setColor(res.color_ichor)
				uiGraphics.drawSlice(slc_ichor, px, py, pw, ph)
			end

			if self.label_mode then
				lgcLabel.render(self, skin, skin.label_style.font, res.color_label, res.color_label_ul, res.label_ox, res.label_oy, ox, oy)
			end

			--widDebug.debugDrawViewport(self, 1)
			--widDebug.debugDrawViewport(self, 2)
		end,
	},
}


return def
