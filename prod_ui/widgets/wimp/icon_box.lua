
--[[

XXX: Under construction.

A box of icons.

Multi category, vertical secondary flow:

┌─────────────────────────────┬─┐
│ [v] Category                │^│
│ ┌─────────────────────────┐ ├─┤
│ │ ╭───╮ ╭───╮ ╭───╮ ╭───╮ │ │ │
│ │ │[B]│ │[B]│ │[B]│ │[B]│ │ │ │
│ │ │Foo│ │Bar│ │Baz│ │Bop│ │ │ │
│ │ ╰───╯ ╰───╯ ╰───╯ ╰───╯ │ │ │
│ │ ╭───╮ ╭───╮             │ │ │
│ │ │[B]│ │[B]│             │ │ │
│ │ │Zip│ │Pop│             │ │ │
│ │ ╰───╯ ╰───╯             │ │ │
│ └─────────────────────────┘ │ │
│                             │ │
│ [>] Collapsed category      ├─┤
│ ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ │v│
└─────────────────────────────┴─┘


Multi category, horizontal secondary flow:

┌─────────────────────────────┐
│ [>] ┌─────────────────────┐ │
│  C  │ ╭───╮ ╭───╮ ╭───╮   │ │
│  a  │ │[B]│ │[B]│ │[B]│   │ │
│  t  │ │Foo│ │Baz│ │Zip│   │ │
│  e  │ ╰───╯ ╰───╯ ╰───╯   │ │
│  g  │ ╭───╮ ╭───╮ ╭───╮   │ │
│  o  │ │[B]│ │[B]│ │[B]│   │ │
│  r  │ │Bar│ │Bop│ │Pop│   │ │
│  y  │ ╰───╯ ╰───╯ ╰───╯   │ │
│     └─────────────────────┘ │
├─┬─────────────────────────┬─┤
│<│                         │>│
└─┴─────────────────────────┴─┘


Single category:

┌─────────────────────────┬─┐
│ ╭───╮ ╭───╮ ╭───╮ ╭───╮ │^│
│ │[B]│ │[B]│ │[B]│ │[B]│ ├─┤
│ │Foo│ │Bar│ │Baz│ │Bop│ │ │
│ ╰───╯ ╰───╯ ╰───╯ ╰───╯ │ │
│ ╭───╮ ╭───╮             │ │
│ │[B]│ │[B]│             │ │
│ │Zip│ │Pop│             ├─┤
│ ╰───╯ ╰───╯             │v│
└─────────────────────────┴─┘


Icon flows:

L2R: Left to right
R2L: Right to left
T2B: Top to bottom
B2T: Bottom to top

L2R_T2B: Left to right, top to bottom
R2L_T2B: Right to left, top to bottom
L2R_B2T: Left to right, bottom to top
R2L_B2T: Right to left, bottom to top

T2B_L2R: Top to bottom, left to right
B2T_L2R: Bottom to top, left to right
T2B_R2L: Top to bottom, right to left
B2T_R2L: Bottom to top, right to left

--]]


local context = select(1, ...)


local lgcScroll = context:getLua("shared/lgc_scroll")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "icon_box1"
}


widShared.scrollSetMethods(def)
def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


function def:uiCall_initialize()
	-- ...
end


def.default_skinner = {
	--validate = uiSchema.newKeysX {} -- TODO
	--transform = function(scale, skin) -- TODO


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
		love.graphics.push("all")

		-- [[
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("line", 0, 0, self.w - 1, self.h - 1)
		love.graphics.print("<WIP Icon Box>", 0, 0)
		--]]

		love.graphics.pop()
	end,

	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
