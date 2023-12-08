-- XXX: Unfinished.

--[[
The main body of a dropdown box.

Closed:

+-----------+-+
| Foobar    |v| --- To open, click anywhere or press space/enter.
+-----------+-+     Press up/down to change the selection without opening.


Opened:

+-----------+-+
| Foobar    |v|
+-----------+-+
| Bazbop    |^| --\
| Foobar    +-+   |
|:Jingle::::| |   |
| Bingo     | |   |--- Pop-up widget with list of selections.
| Pogo      +-+   |
| Stove     |v|   |
+-----------+-+ --/
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "dropdown_box1",
}


def.wid_buttonAction = uiShared.dummyFunc
def.wid_buttonAction2 = uiShared.dummyFunc
def.wid_buttonAction3 = uiShared.dummyFunc


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		-- XXX: dropdown button icon.

		-- State flags
		self.enabled = true
		self.hovered = false
		self.pressed = false

		self:skinSetRefs()
		self:skinInstall()

		self:reshape()
	end
end


function def:uiCall_reshape()

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
end


--def.uiCall_pointerHoverOn
--def.uiCall_pointerHoverOff
--def.uiCall_pointerPress
--def.uiCall_thimbleAction
--def.uiCall_thimbleAction2


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

			love.graphics.push("all")

			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print("WIP Dropdown Box")

			love.graphics.rectangle("line", 0, 0, self.w - 1, self.h - 1)

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
