
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Dropdown Boxes")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	demoShared.makeParagraphSpacer(panel, "p", 1.0)


	local function _selection(self, index, tbl)
		print("Dropdown: New chosen selection: #" .. index .. ", Text: " .. tostring(tbl.text))
	end


	local xx, yy, ww, hh = 0, 0, 256, 32
	local y_pad = 8


	do
		local c_label = demoShared.makeControlLabel(panel, xx, yy, ww, hh, true, "No items:")

		yy = yy + hh

		local dropdown = panel:addChild("wimp/dropdown_box")
			:geometrySetMode("relative", xx, yy, ww, hh)

		yy = yy + hh + y_pad
	end


	do
		local c_label = demoShared.makeControlLabel(panel, xx, yy, ww, hh, true, "A few items:")

		yy = yy + hh

		local dropdown = panel:addChild("wimp/dropdown_box")
			:geometrySetMode("relative", xx, yy, ww, hh)

		dropdown:addItem("foo")
		dropdown:addItem("bar")
		dropdown:addItem("baz")
		dropdown:addItem("bop")

		dropdown:userCallbackSet("cb_chosenSelection", _selection)

		yy = yy + hh + y_pad
	end


	do
		local c_label = demoShared.makeControlLabel(panel, xx, yy, ww, hh, true, "Wide item text:")

		yy = yy + hh

		local dropdown = panel:addChild("wimp/dropdown_box")
			:geometrySetMode("relative", xx, yy, ww, hh)

		dropdown:addItem("One, two, three, four, five, six, seven, eight")
		dropdown:addItem("Un, deux, trois, quatre, cinq, six, sept, huit")
		dropdown:addItem("Uno, dos, tres, cuatro, cinco, seis, siete, ocho")

		dropdown:userCallbackSet("cb_chosenSelection", _selection)

		yy = yy + hh + y_pad
	end


	do
		local c_label = demoShared.makeControlLabel(panel, xx, yy, ww, hh, true, "With icons:")

		yy = yy + hh

		local dropdown = panel:addChild("wimp/dropdown_box")
		dropdown:geometrySetMode("relative", xx, yy, ww, hh)
		dropdown:writeSetting("show_icons", true)

		dropdown:addItem("foo", nil, "file")
		dropdown:addItem("bar", nil, "folder")
		dropdown:addItem("baz")
		dropdown:addItem("bop")

		dropdown:userCallbackSet("cb_chosenSelection", _selection)

		yy = yy + hh + y_pad
	end


	do
		local c_label = demoShared.makeControlLabel(panel, xx, yy, ww, hh, true, "One hundred items:")

		yy = yy + hh

		local dropdown = panel:addChild("wimp/dropdown_box")
		dropdown:geometrySetMode("relative", xx, yy, ww, hh)

		for i = 1, 100 do
			dropdown:addItem(tostring(i))
		end

		dropdown:userCallbackSet("cb_chosenSelection", _selection)

		yy = yy + hh + y_pad
	end
end


return plan
