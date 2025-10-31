local context = select(1, ...)


local debug = context:getLua("core/wid/debug")
local lgcContainer = context:getLua("shared/lgc_container")
local lgcKeyHooks = context:getLua("shared/lgc_key_hooks")
local lgcScroll = context:getLua("shared/lgc_scroll")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local lgcUIFrame = context:getLua("shared/lgc_ui_frame")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "workspace1",
	trickle = {}
}


def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


widLayout.setupContainerDef(def)
widShared.scrollSetMethods(def)
lgcUIFrame.definitionSetup(def)
lgcContainer.setupMethods(def)


function def:uiCall_initialize(unselectable)
	-- UI Frame
	self.frame_type = "workspace"
	lgcUIFrame.instanceSetup(self, unselectable)
	self.sort_id = 1

	self.visible = true
	self.allow_hover = true

	self.scroll_range_mode = "zero"
	self.halt_reshape = false

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)

	widLayout.setupLayoutList(self)
	self:layoutSetBase("viewport")

	lgcContainer.setupSashState(self)
	lgcKeyHooks.setupInstance(self)

	self.press_busy = false

	-- Frame-blocking widget link.
	-- Workspaces can be blocked by Window Frames, but they themselves cannot block
	-- other UI Frames.
	self.ref_block_next = false

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


--[[
Viewport #1 is the scrolling area.
Viewport #2 is an outer border.
--]]


function def:uiCall_reshapePre()
	print("workspace: uiCall_reshapePre")

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2
	local root = context.root
	local rvp = root.vp

	self.x, self.y, self.w, self.h = rvp.x, rvp.y, rvp.w, rvp.h

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	lgcScroll.arrangeScrollBars(self)

	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	widShared.setClipScissorToViewport(self, vp2)
	widShared.setClipHoverToViewport(self, vp2)

	widLayout.resetLayoutSpace(self)

	return self.halt_reshape
end


function def:uiCall_reshapePost()
	print("workspace: uiCall_reshapePost")

	widShared.updateDoc(self)

	self:scrollClampViewport()
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)
end


def.trickle.uiCall_pointerHoverOn = lgcUIFrame.logic_tricklePointerHoverOn


function def.trickle:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	local skin = self.skin
	return lgcContainer.sashHoverLogic(self, mouse_x, mouse_y)
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		lgcScroll.widgetProcessHover(self, mx, my)
	end
end


function def.trickle:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	lgcContainer.sashHoverOffLogic(self)
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		lgcScroll.widgetClearHover(self)
	end
end


function def.trickle:uiCall_pointerDrag(inst, x, y, dx, dy)
	if lgcContainer.sashDragLogic(self, x, y) then
		return true
	end
end


function def.trickle:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if lgcContainer.sashUnpressLogic(self) then
		return true
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if lgcUIFrame.pointerPressLogicFirst(self) then
		return
	end

	local root = self:getRootWidget()

	if self == inst then
		local handled = false

		-- Check for pressing on scroll bar components.
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config
			handled = lgcScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Scroll bars were not activated: take thimble1
		if not handled then
			self:tryTakeThimble1()
		end
	end
end


def.uiCall_pointerPressRepeat = lgcUIFrame.logic_pointerPressRepeat


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 then
			lgcScroll.widgetClearPress(self)

			self.press_busy = false
		end
	end
end


def.trickle.uiCall_pointerWheel = lgcUIFrame.logic_tricklePointerWheel
def.uiCall_pointerWheel = lgcUIFrame.logic_pointerWheel
def.uiCall_thimble1Take = lgcUIFrame.logic_thimble1Take
def.trickle.uiCall_keyPressed = lgcUIFrame.logic_trickleKeyPressed
def.uiCall_keyPressed = lgcUIFrame.logic_keyPressed
def.trickle.uiCall_keyReleased = lgcUIFrame.logic_trickleKeyReleased
def.uiCall_keyReleased = lgcUIFrame.logic_keyReleased
def.trickle.uiCall_textInput = lgcUIFrame.logic_trickleTextInput
def.trickle.uiCall_pointerPress = lgcUIFrame.logic_tricklePointerPress


function def:uiCall_update(dt)
	dt = math.min(dt, 1.0)
	if lgcScroll.press_busy_codes[self.press_busy] then
		local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
		local button_step = 350 -- [XXX 6] style/config
		lgcScroll.widgetDragLogic(self, mx, my, button_step*dt)
	end

	self:scrollUpdate(dt)
	lgcScroll.updateScrollState(self)
	lgcScroll.updateScrollBarShapes(self)
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Destroy any Window Frames that are associated with this Workspace.
		local root = self.context.root
		for i, wid_g2 in ipairs(root.children) do
			if wid_g2.frame_type == "window" and wid_g2.workspace == self then
				wid_g2:destroy()
			end
		end

		root:sortG2()

		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		data_scroll = themeAssert.scrollBarData,
		scr_style = themeAssert.scrollBarStyle,

		background_color = uiAssert.loveColorTupleEval,

		-- Padding when scrolling to put a widget into view.
		in_view_pad_x = {uiAssert.intGE, 0},
		in_view_pad_y = {uiAssert.intGE, 0}
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "in_view_pad_x")
		uiScale.fieldInteger(scale, skin, "in_view_pad_y")
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		if skin.background_color then
			love.graphics.push("all")

			love.graphics.setColor(skin.background_color)
			love.graphics.rectangle("fill", 0, 0, self.w, self.h)

			love.graphics.pop()
		end

		if self.userRender then
			self:userRender(ox, oy)
		end
	end,


	renderLast = function(self, ox, oy)
		love.graphics.push("all")

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		lgcContainer.renderSashes(self)

		lgcScroll.drawScrollBarsHV(self, self.skin.data_scroll)

		love.graphics.pop()

		-- XXX Debug...
		--[=[
		love.graphics.push("all")

		love.graphics.setLineStyle("smooth")
		love.graphics.setLineWidth(2)
		love.graphics.setLineJoin("miter")

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("line", self.vp.x, self.vp.y, self.vp.w, self.vp.h)

		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.rectangle("line", self.vp2.x, self.vp2.y, self.vp2.w, self.vp2.h)

		love.graphics.setColor(0, 0, 1, 1)
		love.graphics.rectangle("line", -self.scr_x, -self.scr_y, self.doc_w, self.doc_h)

		if self.DEBUG == "dimensions" then -- XXX debug cleanup
			love.graphics.setColor(0,0,0,0.6)
			love.graphics.rectangle("fill", 0, 0, 160, 256)
			love.graphics.setColor(1,1,1,1)
			love.graphics.print(
				"scr_x: " .. self.scr_x .. "\nscr_y: " .. self.scr_y
				.. "\nscr_fx: " .. self.scr_fx .. "\nscr_fy: " .. self.scr_fy
				.. "\nscr_tx: " .. self.scr_tx .. "\nscr_ty: " .. self.scr_ty
				.. "\ndoc_w: " .. self.doc_w .. "\ndoc_h: " .. self.doc_h
				.. "\nw: " .. self.w .. "\nh: " .. self.h
				--.. "\nscr_v.pos: " .. self.scr_v.pos .. "\n^len: " .. self.scr_v.len .. "\n^max: " .. self.scr_v.max
			)
		end

		love.graphics.pop("all")
		--]=]
	end,


	-- Don't highlight when holding the UI thimble.
	renderThimble = widShared.dummy,
}


return def
