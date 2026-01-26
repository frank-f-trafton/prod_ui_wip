
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Message Log")
	demoShared.makeParagraph(panel, nil, "")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, false)

	local msg_log = panel:addChild("status/message_log")
		:geometrySetMode("segment", "top", 480)
		:setTag("d_msg_log")
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

	-- button: removeAllItems


	local xx, yy, ww, hh = 0, 0, 200, 40
	local h_space = 8

	yy = yy + h_space

	local function _removeAllItems(self)
		local msg_log = self:findSiblingTag("d_msg_log")
		if msg_log then
			msg_log:removeAllItems()
		end
	end

	local c_remove_all = panel:addChild("base/button")
		:setTag("d_msg_log_remove_all")
		:geometrySetMode("relative", xx, yy, ww, hh)
		:setLabel("Remove All Items", "single")
		:userCallbackSet("cb_buttonAction", _removeAllItems)

	yy = yy + hh + h_space

	local function _replaceLastText(self)
		local msg_log = self:findSiblingTag("d_msg_log")
		if msg_log then
			msg_log:replaceLastItem(self:getText(), false)
		end
	end

	local c_replace_last = panel:addChild("input/text_box_single")
		:geometrySetMode("relative", xx, yy, ww*2, hh)
		:setTag("d_msg_log_replace_last")
		:setClearHistoryOnDeselect(true)
		:setGhostText("Replace the last item's text")
		:userCallbackSet("cb_action", _replaceLastText)

	yy = yy + hh + h_space

	local count_max = 1.0 -- count of time between turns
	local time = 0.0
	local count = 0.0

	local time_of_day = {"this morning", "at noon", "this afternoon", "in the evening", "all day"}
	local last_msg = false

	local r = function(n)
		return love.math.random() <= n
	end

	local function timeOfDay()
		return time_of_day[love.math.random(1, #time_of_day)]
	end

	local function runTurn()
		local windy, rainy = r(1/3), r(1/12)
		local roasting = not rainy and r(1/10)
		local lightning = rainy and r(1/20)
		local ufo = not (windy or rainy) and r(1/365)

		local ins = table.insert

		local msg = {}

		if lightning then
			ins(msg, r(1/2) and "Lightning storms expected" or "Intermittent showers with a chance of thunder")

		elseif rainy then
			ins(msg, r(1/2) and "Heavy rainfall" or "Occasional light showers expected")

		elseif roasting then
			ins(msg, r(1/2) and "High temperatures expected" or "Sunshine with elevated UV")

		else
			ins(msg, r(1/2) and "Mild temperatures" or "Sunny conditions")
		end

		ins(msg, timeOfDay() .. ".")

		if windy then
			ins(msg, r(1/2) and "Strong gusts exceeding 90 KM/h." or "Tornado warning.")
		end

		if ufo then
			ins(msg, r(1/2) and "Citizens report a strange, gleaming object, moving erratically in the sky." or "Govt denies reports of flying saucer.")
		end

		if r(1/505) then
			ins(msg, "How about that.")
		end

		if r(1/3) then
			ins(msg, "Today's lucky number is " .. love.math.random(1, 9) .. ".")
		end

		local str = table.concat(msg, " ")

		local again = str == last_msg
		last_msg = str

		msg_log:appendItem("Time: " .. tostring(time) .. ": " .. str .. (again and " (Again!)" or ""))
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
