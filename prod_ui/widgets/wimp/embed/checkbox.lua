-- WIP

--[[
	Embedded checkbox.
--]]


local context = select(1, ...)


local lgcButton = context:getLua("shared/lgc_button")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "checkbox_emb1",
}


def.wid_buttonAction = lgcButton.wid_buttonAction
def.wid_buttonAction2 = lgcButton.wid_buttonAction2
def.wid_buttonAction3 = lgcButton.wid_buttonAction3


def.setEnabled = lgcButton.setEnabled
def.setChecked = lgcButton.setChecked


def.uiCall_pointerHoverOn = lgcButton.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = lgcButton.uiCall_pointerHoverOff
def.uiCall_pointerPress = lgcButton.uiCall_pointerPress
def.uiCall_pointerRelease = lgcButton.uiCall_pointerReleaseCheck
def.uiCall_pointerUnpress = lgcButton.uiCall_pointerUnpress


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = false

		widShared.setupViewports(self, 1)

		-- Checkbox state.
		self.checked = false

		-- State flags
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:reshape()
	end
end


function def:uiCall_reshape()
	-- Viewport #1 is the checkbox rectangle.
	widShared.resetViewport(self, 1)
end


function def:render(ox, oy)
	love.graphics.push("all")
	love.graphics.setColor(1, 1, 1, 1)
	local rect_mode = self.checked and "fill" or "line"
	love.graphics.rectangle(rect_mode, 0, 0, self.w - 1, self.h - 1)
	love.graphics.pop()
end


return def
