
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Message Log")
	demoShared.makeParagraph(panel, nil, "\n***Under Construction***\n")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local msg_log = panel:addChild("status/message_log")
		:geometrySetMode("segment", "top", 480)
		:setTag("demo_message_log")
		:setScrollBars(false, true)
		--:setIconsEnabled(true)

	msg_log:userCallbackSet("cb_action", function(self, item, index)
		print("cb_action()", item, index)
	end)
	msg_log:userCallbackSet("cb_action2", function(self, item, index)
		print("cb_action2()", item, index)
	end)
	msg_log:userCallbackSet("cb_action3", function(self, item, index)
		print("cb_action3()", item, index)
	end)
	msg_log:userCallbackSet("cb_select", function(self, item, index)
		print("cb_select()", item, index)
	end)

	msg_log.MN_drag_scroll = true
	msg_log.MN_drag_select = true

	--[===[
	local uiAssert = require("prod_ui.ui_assert")

	local function newAnt(name, energy, speed, strength)
		uiAssert.type(1, name, "string")
		uiAssert.numberGE(2, energy, 0)
		uiAssert.numberGE(3, speed, 0)
		uiAssert.numberGE(4, strength, 0)

		return {
			name=name,
			energy=energy,
			speed=speed,
			strength=strength
		}
	end

	local function newBird(name, species, nocturnal, drop_chance)
		uiAssert.type(1, name, "string")
		uiAssert.type(2, species, "string")
		nocturnal = not not nocturnal
		uiAssert.numberGE(4, drop_chance, 0) -- (0:100)

		return {
			name=name,
			species=species,
			nocturnal=nocturnal,
			drop_chance=math.max(drop_chance, 100)
		}
	end

	-- Birds drop fruit; ants collect fruit
	local ants = {}
	local birds = {}
	--]===]

	local count_max = 1.0 -- count of time between turns
	local time = 0.0
	local count = count_max

	local function runTurn()
		msg_log:appendItem("Time: " .. tostring(time))
	end

	panel:userCallbackSet("cb_update", function(self, dt)
		time = time + dt
		count = count - dt
		if count <= 0.0 then
			count = count_max
			runTurn()
		end

		--print(time, count)
	end)
end


return plan
