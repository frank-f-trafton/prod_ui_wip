--[[
A barebones checkbox. Internal use (troubleshooting skinned widgets, etc.)
--]]


local context = select(1, ...)


local wcButtonBare = context:getLua("shared/wc/wc_button_bare")
local wcLabelBare = context:getLua("shared/wc/wc_label_bare")


local def = {}


def.wid_buttonAction = wcButtonBare.wid_buttonAction
def.wid_buttonAction2 = wcButtonBare.wid_buttonAction2
def.wid_buttonAction3 = wcButtonBare.wid_buttonAction3


def.setEnabled = wcButtonBare.setEnabled
def.setLabel = wcLabelBare.widSetLabel
def.setChecked = wcButtonBare.setChecked


def.uiCall_pointerHoverOn = wcButtonBare.uiCall_pointerHoverOn
def.uiCall_pointerHoverOff = wcButtonBare.uiCall_pointerHoverOff
def.uiCall_pointerPress = wcButtonBare.uiCall_pointerPress
def.uiCall_pointerRelease = wcButtonBare.uiCall_pointerReleaseCheck
def.uiCall_pointerUnpress = wcButtonBare.uiCall_pointerUnpress
def.uiCall_thimbleAction = wcButtonBare.uiCall_thimbleActionCheck
def.uiCall_thimbleAction2 = wcButtonBare.uiCall_thimbleAction2


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	wcLabelBare.setup(self)

	-- Checkbox state.
	self.checked = false

	-- State flags
	self.enabled = true
	self.hovered = false
	self.pressed = false
end


def.render = context:getLua("shared/render_button_bare").buttons


return def
