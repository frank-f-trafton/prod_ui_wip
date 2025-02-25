local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local lgcContainer = context:getLua("shared/lgc_container")
local lgcKeyHooks = context:getLua("shared/lgc_key_hooks")
local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local lgcUIFrame = context:getLua("shared/lgc_ui_frame")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "workspace1"
}


def.trickle = {}


lgcUIFrame.definitionSetup(def)


widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


--- Override to make something happen when the user clicks on blank space (no widgets, no embedded controls) in the workspace.
function def:wid_pressed(x, y, button, istouch, presses)

end


function def:uiCall_initialize(unselectable)
	-- UI Frame
	self.frame_type = "workspace"
	lgcUIFrame.instanceSetup(self, unselectable)
	self.sort_id = 1

	self.visible = true
	self.allow_hover = true

	self.auto_doc_update = true
	self.auto_layout = false
	self.halt_reshape = false

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)
	widShared.setupMinMaxDimensions(self)
	uiLayout.initLayoutSequence(self)
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


function def:uiCall_reshape()
	local skin = self.skin
	local root = self.context.root

	self.x, self.y, self.w, self.h = root.vp2_x, root.vp2_y, root.vp2_w, root.vp2_h

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	commonScroll.arrangeScrollBars(self)

	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, skin.box.margin)

	widShared.setClipScissorToViewport(self, 2)
	widShared.setClipHoverToViewport(self, 2)

	if self.auto_layout then
		uiLayout.resetLayoutPort(self, 1)
		uiLayout.applyLayout(self)
	end

	if self.auto_doc_update then
		self.doc_w, self.doc_h = widShared.getCombinedChildrenDimensions(self)
	end

	self:scrollClampViewport()
	commonScroll.updateScrollBarShapes(self)
	commonScroll.updateScrollState(self)

	return self.halt_reshape
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		commonScroll.widgetProcessHover(self, mx, my)
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		commonScroll.widgetClearHover(self)
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if lgcUIFrame.partial_pointerPress(self) then
		return
	end

	local root = self:getRootWidget()

	if self == inst then
		local handled = false

		-- Check for pressing on scroll bar components.
		if button == 1 and button == self.context.mouse_pressed_button then
			local fixed_step = 24 -- [XXX 2] style/config
			handled = commonScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Scroll bars were not activated: take thimble1
		if not handled then
			if self.can_have_thimble then
				self:takeThimble1()
			end
			self:wid_pressed(x, y, button, istouch, presses)
		end
	end
end


def.uiCall_pointerPressRepeat = lgcUIFrame.logic_pointerPressRepeat


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 then
			commonScroll.widgetClearPress(self)

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
	if commonScroll.press_busy_codes[self.press_busy] then
		local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
		local button_step = 350 -- [XXX 6] style/config
		commonScroll.widgetDragLogic(self, mx, my, button_step*dt)
	end

	self:scrollUpdate(dt)
	commonScroll.updateScrollState(self)
	commonScroll.updateScrollBarShapes(self)
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Remove any Window Frames that are associated with this Workspace.
		local root = self.context.root
		for i, wid_g2 in ipairs(root.children) do
			if wid_g2.frame_type == "window" and wid_g2.workspace == self then
				wid_g2:remove()
			end
		end

		root:sortG2()
	end
end


def.default_skinner = {
	schema = {
		in_view_pad_x = "scaled-int",
		in_view_pad_y = "scaled-int"
	},


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)
	--render = function(self, ox, oy)


	renderLast = function(self, ox, oy)
		local skin = self.skin

		commonScroll.drawScrollBarsHV(self, self.skin.data_scroll)

		-- XXX Debug...
		--[=[
		love.graphics.push("all")

		love.graphics.setLineStyle("smooth")
		love.graphics.setLineWidth(2)
		love.graphics.setLineJoin("miter")

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("line", self.vp_x, self.vp_y, self.vp_w, self.vp_h)

		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.rectangle("line", self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)

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
