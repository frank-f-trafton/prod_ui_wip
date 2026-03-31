local plan = {}


-- ProdUI
local demoShared = require("demo_shared")


local _evt_quit = function(self)
	print("halt love.quit()")
	self.evt_quit = nil

	local cb = self:findTag("demo_quitter_blocker")
	if cb then
		cb:setChecked(false)
	end

	return true
end


local function cb_buttonAction(self)
	local root = self:nodeGetRoot()
	if self:getChecked() then
		root.evt_quit = _evt_quit
	else
		root.evt_quit = nil
	end
end


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "I Wish I Knew how to Quit you")

	panel:layoutSetBase("viewport")
	panel:containerSetScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	local chk = panel:addChild("base/checkbox")
		:geometrySetMode("relative", 16, 16, 300, 48)
		:setTag("demo_quitter_blocker")
		:setLabel("Interrupt love.quit() once", "single")
		:userCallbackSet("cb_buttonAction", cb_buttonAction)
end


return plan
